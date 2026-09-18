local M = {}

M.STATE = {IDLE = 0, LS_READY = 1, AUTO_STT_PENDING = 2, STT_ACK = 3,
    RELEASE_AUTH = 4, SUPPORT = 5, HANDOFF_DROP = 6, DT2_REACQUIRE = 7, FAILED = 8}
M.REASON = {NONE = 0, NO_LS = 1, NO_ACK = 2, CANCELLED = 3, STATION_CHANGED = 4,
    FRIEND = 5, LOCK_LOST = 6, NO_DT2 = 7, DROP_TIMEOUT = 8, NOT_READY = 9,
    MODE = 10, TARGET_CHANGED = 11, NO_RELEASE = 12}
M.CUE_TEXT = {"ACQ", "SUPPORT", "HANDOFF", "NO L&S", "NO ACK", "CANCEL",
    "STATION", "FRIEND", "LOCK LOST", "NO DT2", "DROP FAIL", "NOT RDY", "NO RELEASE"}

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function M.eligible(contact)
    return type(contact) == "table" and type(contact.track_key) == "string"
    and contact.track_key ~= "" and contact.source == 0
    and contact.fresh == true and contact.coast ~= true
        and contact.lockable == true and finite(contact.az) and finite(contact.el)
        and finite(contact.range) and contact.range > 0
end

function M.correlated(target, stt)
    return type(target) == "table" and finite(target.az) and finite(target.el)
        and finite(target.range) and target.range > 0
        and type(stt) == "table" and stt.valid == true
        and finite(stt.az) and finite(stt.el) and finite(stt.range) and stt.range > 0
        and math.abs(stt.az - target.az) <= math.rad(2)
        and math.abs(stt.el - target.el) <= math.rad(2)
        and math.abs(stt.range - target.range) <= 1500
end

function M.continuation(target, contacts)
    if not target or type(target.track_key) ~= "string" or not target.track_key:match("^geo:") then return nil end
    local match
    for _, candidate in ipairs(contacts) do
        if M.eligible(candidate) and candidate.track_key:match("^geo:")
            and M.correlated(target, {valid = true, az = candidate.az, el = candidate.el, range = candidate.range}) then
            if match then return nil end
            match = candidate
        end
    end
    return match
end

local function snapshot(contact)
    return {track_key = contact.track_key, source = contact.source, friend = contact.friend,
        az = contact.az, el = contact.el, range = contact.range,
        fresh = true, coast = false, lockable = true}
end

local function transition(machine, state, now, reason)
    machine.state, machine.entered_at = state, now
    machine.reason = reason or M.REASON.NONE
    machine.auth_seq = 0
end

function M.new()
    return {state = M.STATE.IDLE, request_seq = 0, auth_seq = 0,
        reason = M.REASON.NONE, entered_at = 0, acquire_timeout = 12, drop_timeout = 2}
end

function M.handles(factory)
    local handles = {}
    for _, name in ipairs({"REQUEST_SEQ", "HELD", "REQUEST_STATION", "STATION", "SELECTED",
        "READY", "AUTH_SEQ", "SHOT_SEQ", "RELEASED_SEQ", "STATE", "REASON", "HEARTBEAT",
        "AUTH_AZ", "AUTH_EL", "AUTH_RANGE", "ENABLED", "CUE"}) do
        handles[name] = factory("F5EM_DERBY_" .. name)
    end
    return handles
end

function M.publish(handles, machine, now)
    handles.STATE:set(machine.state)
    handles.REASON:set(machine.reason)
    handles.AUTH_SEQ:set(machine.auth_seq)
    handles.HEARTBEAT:set(now + 1)
    local target = machine.target
    handles.AUTH_AZ:set(target and target.az or 0)
    handles.AUTH_EL:set(target and target.el or 0)
    handles.AUTH_RANGE:set(target and target.range or 0)
    local cue = 0
    if machine.state >= M.STATE.LS_READY and machine.state <= M.STATE.RELEASE_AUTH then cue = 1
    elseif machine.state == M.STATE.SUPPORT then cue = machine.reason == M.REASON.NO_DT2 and 10 or 2
    elseif machine.state == M.STATE.HANDOFF_DROP or machine.state == M.STATE.DT2_REACQUIRE then cue = 3
    elseif machine.state == M.STATE.FAILED and now - machine.entered_at <= 3 then
        cue = ({[M.REASON.NO_LS] = 4, [M.REASON.NO_ACK] = 5, [M.REASON.CANCELLED] = 6,
            [M.REASON.STATION_CHANGED] = 7, [M.REASON.FRIEND] = 8, [M.REASON.LOCK_LOST] = 9,
            [M.REASON.NO_DT2] = 10, [M.REASON.DROP_TIMEOUT] = 11, [M.REASON.NOT_READY] = 12,
            [M.REASON.TARGET_CHANGED] = 9, [M.REASON.NO_RELEASE] = 13})[machine.reason] or 0
    end
    handles.CUE:set(cue)
end

function M.release_new()
    return {pressed = false, sequence = 0}
end

function M.release_request(state, value, input, now)
    if value == 0 then
        state.pressed = false
        if state.pending and not state.pending.invoked then state.pending = nil end
        return false
    end
    if value ~= 1 or state.pressed then return false end
    state.pressed = true
    if state.pending or not input.is_derby or not input.ready or not finite(now)
        or not finite(input.station) or input.station % 1 ~= 0 or input.station < 1 or input.station > 7
        or not finite(input.count) or input.count < 1 then return false end
    state.sequence = state.sequence + 1
    state.pending = {sequence = state.sequence, station = input.station, clsid = input.clsid,
        count = input.count, at = now, invoked = false}
    return true
end

function M.release_due(state, input, grant, now)
    local pending = state.pending
    if not pending or pending.invoked then return false end
    if not finite(now) or now < pending.at or not state.pressed or not input.is_derby or not input.ready
        or input.station ~= pending.station or input.clsid ~= pending.clsid
        or input.count ~= pending.count or now - pending.at > 13 then
        state.pending = nil
        return false
    end
    if grant.sequence ~= pending.sequence or not finite(grant.at) or now < grant.at
        or now - grant.at > 0.35 or not M.correlated(grant.target, input.stt) then return false end
    pending.invoked = true
    pending.invoked_at = now
    return true, pending.station
end

function M.release_confirm(state, count, clsid, now)
    local pending = state.pending
    if not pending or not pending.invoked or not finite(now) or now < pending.invoked_at then return nil end
    if finite(count) and count >= 0 and count < pending.count and clsid == pending.clsid then
        state.pending = nil
        return pending.sequence
    end
    if clsid ~= pending.clsid or now - pending.invoked_at > 2 then state.pending = nil end
    return nil
end

function M.cancel(machine, now, reason)
    machine.target, machine.next_target = nil, nil
    transition(machine, M.STATE.FAILED, now, reason or M.REASON.CANCELLED)
end

function M.update(machine, input, now)
    local action = {}
    if not finite(now) then M.cancel(machine, 0, M.REASON.MODE); return action end
    local requested = finite(input.request_seq) and input.request_seq > machine.request_seq
        and input.request_seq % 1 == 0
    if not input.aa or not input.radar_active then
        if machine.state ~= M.STATE.IDLE then M.cancel(machine, now, M.REASON.MODE) end
        if requested then machine.request_seq = input.request_seq end
        return action
    end
    if machine.state == M.STATE.RELEASE_AUTH and input.shot_seq == machine.request_seq then
        transition(machine, M.STATE.SUPPORT, now)
        return action
    end
    if machine.state == M.STATE.RELEASE_AUTH and input.released_seq == machine.request_seq then
        machine.auth_seq = 0
        if now - machine.entered_at >= 2 then M.cancel(machine, now, M.REASON.NO_RELEASE) end
        return action
    end
    if requested then
        machine.request_seq = input.request_seq
        if machine.state == M.STATE.HANDOFF_DROP or machine.state == M.STATE.DT2_REACQUIRE then
            return action
        end
        if not input.held or not input.ready or not input.derby then
            M.cancel(machine, now, M.REASON.NOT_READY)
        elseif not finite(input.station) or input.station % 1 ~= 0 or input.station < 1 or input.station > 7
            or input.request_station ~= input.station then
            M.cancel(machine, now, M.REASON.STATION_CHANGED)
        elseif not M.eligible(input.ls) then
            M.cancel(machine, now, M.REASON.NO_LS)
        else
            machine.station = input.station
            machine.target = snapshot(input.ls)
            transition(machine, M.STATE.LS_READY, now)
        end
        return action
    end
    if machine.state == M.STATE.SUPPORT then
        if not M.correlated(machine.target, input.stt) then
            M.cancel(machine, now, M.REASON.LOCK_LOST)
            return action
        end
        machine.target.az, machine.target.el, machine.target.range = input.stt.az, input.stt.el, input.stt.range
        if input.cycle then
            if M.eligible(input.dt2) and input.dt2.track_key ~= machine.target.track_key then
                machine.next_target = snapshot(input.dt2)
                transition(machine, M.STATE.HANDOFF_DROP, now)
                action.drop = true
            else
                machine.reason = M.REASON.NO_DT2
            end
        end
        return action
    end
    if machine.state == M.STATE.HANDOFF_DROP then
        if input.drop_verified == true then
            machine.target = snapshot(machine.next_target)
            machine.next_target = nil
            machine.acquire_at = now
            transition(machine, M.STATE.DT2_REACQUIRE, now)
            action.cycle = true
            action.acquire = snapshot(machine.target)
        elseif now - machine.entered_at >= machine.drop_timeout then
            M.cancel(machine, now, M.REASON.DROP_TIMEOUT)
        end
        return action
    end
    local acquiring = machine.state == M.STATE.LS_READY or machine.state == M.STATE.AUTO_STT_PENDING
        or machine.state == M.STATE.STT_ACK or machine.state == M.STATE.RELEASE_AUTH
        or machine.state == M.STATE.DT2_REACQUIRE
    if not acquiring then return action end
    local handoff = machine.state == M.STATE.DT2_REACQUIRE
    if not handoff and (not input.held or not input.ready or not input.derby
        or input.station ~= machine.station) then
        M.cancel(machine, now, not input.held and M.REASON.CANCELLED
            or input.station ~= machine.station and M.REASON.STATION_CHANGED or M.REASON.NOT_READY)
        action.cancel_acquire = true
        return action
    end
    if M.eligible(input.ls) then
        if input.ls.track_key ~= machine.target.track_key then
            M.cancel(machine, now, M.REASON.TARGET_CHANGED)
            action.cancel_acquire = true
            return action
        end
        machine.target = snapshot(input.ls)
    end
    local acknowledged = M.correlated(machine.target, input.stt)
    if machine.state == M.STATE.LS_READY then
        machine.acquire_at = now
        if acknowledged then
            transition(machine, M.STATE.STT_ACK, now)
        else
            transition(machine, M.STATE.AUTO_STT_PENDING, now)
            action.acquire = snapshot(machine.target)
        end
    elseif machine.state == M.STATE.AUTO_STT_PENDING or handoff then
        if acknowledged then
            transition(machine, handoff and M.STATE.IDLE or M.STATE.STT_ACK, now)
        elseif now - machine.acquire_at >= machine.acquire_timeout then
            M.cancel(machine, now, M.REASON.NO_ACK)
            action.cancel_acquire = true
        elseif not M.eligible(input.ls) then
            M.cancel(machine, now, M.REASON.LOCK_LOST)
            action.cancel_acquire = true
        end
    elseif machine.state == M.STATE.STT_ACK or machine.state == M.STATE.RELEASE_AUTH then
        if not acknowledged then
            M.cancel(machine, now, M.REASON.LOCK_LOST)
        elseif machine.state == M.STATE.RELEASE_AUTH and now - machine.entered_at >= 2 then
            M.cancel(machine, now, M.REASON.NO_RELEASE)
        else
            if machine.state ~= M.STATE.RELEASE_AUTH then transition(machine, M.STATE.RELEASE_AUTH, now) end
            machine.auth_seq = machine.request_seq
        end
    end
    return action
end

return M