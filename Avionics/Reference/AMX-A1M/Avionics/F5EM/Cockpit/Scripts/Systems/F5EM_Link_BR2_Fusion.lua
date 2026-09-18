local M = {
    VERSION = 1,
    KINEMATIC_VERSION = 2,
    MAX_FRAME_BYTES = 2048,
    LEGACY_MAX_FRAME_BYTES = 1024,
    MAX_VELOCITY_MPS = 2000,
    MAX_TRACKS_PER_FRAME = 16,
    MAX_TRACK_ID = 2147483647,
    DEFAULT_PEER_TTL_S = 12,
    DEFAULT_TRACK_LIMIT = 8,
    DEFAULT_MERGE_NM = 1.0,
}

local EARTH_RADIUS_M = 6371000
local M_TO_NM = 0.000539956803

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge then
        return nil
    end
    return value
end

local function split_plain(value, delimiter)
    local fields = {}
    local start_at = 1
    while true do
        local found = string.find(value, delimiter, start_at, true)
        if not found then
            fields[#fields + 1] = string.sub(value, start_at)
            return fields
        end
        fields[#fields + 1] = string.sub(value, start_at, found - 1)
        start_at = found + #delimiter
    end
end

local function sanitize_sender(value)
    value = tostring(value or ""):gsub("[^%w_.%-]", "_")
    if #value > 32 then value = value:sub(1, 32) end
    if value == "" then return nil end
    return value
end

function M.is_awacs_sender(sender)
    return type(sender) == "string" and (sender:match("^E99[_%-][%w_.%-]+$") ~= nil
        or sender:match("^AW_E3A_%d+$") ~= nil)
end

local function integer(value, low, high)
    value = finite(value)
    if not value or value ~= math.floor(value) or value < low or value > high then
        return nil
    end
    return value
end

local function valid_coordinate(lat, lon)
    return lat and lon and lat >= -90 and lat <= 90 and lon >= -180 and lon <= 180
end

local function valid_velocity(vx, vy, vz)
    return finite(vx) ~= nil and finite(vy) ~= nil and finite(vz) ~= nil
        and vx * vx + vy * vy + vz * vz <= M.MAX_VELOCITY_MPS * M.MAX_VELOCITY_MPS
end
M.valid_velocity = valid_velocity

local function copy_track(track)
    local source_kind = track.source_kind
    if source_kind == nil then source_kind = track.remote and 1 or 0 end
    return {
        id = track.id,
        lat = track.lat,
        lon = track.lon,
        alt = track.alt,
        hdg = track.hdg,
        velocity_valid = track.velocity_valid == true,
        measurement_time = track.measurement_time,
        vx = track.velocity_valid and track.vx or nil,
        vy = track.velocity_valid and track.vy or nil,
        vz = track.velocity_valid and track.vz or nil,
        side = track.side,
        raid = track.raid,
        sender = track.sender,
        session = track.session,
        affil_conflict = track.affil_conflict == true,
        age = track.age or 0,
        sources = track.sources or 1,
        remote = track.remote and true or false,
        source_kind = source_kind,
        has_peer = track.has_peer == true or source_kind == 1,
        has_awacs = track.has_awacs == true or source_kind == 2,
    }
end

function M.parse_frame(frame)
    if type(frame) ~= "string" then return nil, "NOT_STRING" end
    if #frame == 0 or #frame > M.MAX_FRAME_BYTES then return nil, "BAD_SIZE" end
    if frame:find("[\r\n]") then return nil, "CONTROL_CHAR" end

    local fields = split_plain(frame, "|")
    if #fields < 9 or fields[1] ~= "F5EM_LBR2" then return nil, "BAD_PREFIX" end
    local version = integer(fields[2], 1, 99)
    if version ~= M.VERSION and version ~= M.KINEMATIC_VERSION then return nil, "BAD_VERSION" end
    if version == M.VERSION and #frame > M.LEGACY_MAX_FRAME_BYTES then return nil, "BAD_SIZE" end
    local sender = sanitize_sender(fields[3])
    if not sender then return nil, "BAD_SENDER" end

    local own_lat = finite(fields[4])
    local own_lon = finite(fields[5])
    local own_alt = finite(fields[6])
    local own_hdg = finite(fields[7])
    local timestamp = finite(fields[8])
    local count = integer(fields[9], 0, M.MAX_TRACKS_PER_FRAME)
    if not valid_coordinate(own_lat, own_lon) then return nil, "BAD_OWN_COORD" end
    if not own_alt or own_alt < -1000 or own_alt > 100000 then return nil, "BAD_OWN_ALT" end
    if not own_hdg or not timestamp or timestamp < 0 then return nil, "BAD_OWN_STATE" end
    if not count or #fields ~= 9 + count then return nil, "BAD_COUNT" end

    local tracks = {}
    for index = 1, count do
        local parts = split_plain(fields[9 + index], ",")
        if #parts ~= (version == M.KINEMATIC_VERSION and 10 or 7) then return nil, "BAD_TRACK_FIELDS" end
        local track = {
            id = integer(parts[1], 1, M.MAX_TRACK_ID),
            lat = finite(parts[2]),
            lon = finite(parts[3]),
            alt = finite(parts[4]),
            hdg = finite(parts[5]),
            side = integer(parts[6], 0, 2),
            raid = integer(parts[7], 1, 99),
            sender = sender,
            remote = true,
            sources = 1,
            velocity_valid = false,
            measurement_time = timestamp,
        }
        if not track.id or not valid_coordinate(track.lat, track.lon)
            or not track.alt or track.alt < -1000 or track.alt > 100000
            or not track.hdg or not track.side or not track.raid then
            return nil, "BAD_TRACK_VALUE"
        end
        if version == M.KINEMATIC_VERSION and not (parts[8] == "NA" and parts[9] == "NA" and parts[10] == "NA") then
            track.vx, track.vy, track.vz = finite(parts[8]), finite(parts[9]), finite(parts[10])
            if not valid_velocity(track.vx, track.vy, track.vz) then return nil, "BAD_TRACK_VELOCITY" end
            track.velocity_valid = true
        end
        tracks[#tracks + 1] = track
    end

    return {
        version = version,
        sender = sender,
        own_lat = own_lat,
        own_lon = own_lon,
        own_alt = own_alt,
        own_hdg = own_hdg,
        timestamp = timestamp,
        tracks = tracks,
        raw = frame,
    }
end

local function encode_number(value, format)
    return string.format(format, finite(value) or 0)
end

function M.serialize_frame(frame)
    if type(frame) ~= "table" then return "" end
    local version = frame.version or M.VERSION
    if version ~= M.VERSION and version ~= M.KINEMATIC_VERSION then return "" end
    local sender = sanitize_sender(frame.sender or frame.own_id)
    if not sender then return "" end
    local tracks = type(frame.tracks) == "table" and frame.tracks or {}
    local count = math.min(#tracks, M.MAX_TRACKS_PER_FRAME)
    local fields = {
        "F5EM_LBR2",
        tostring(version),
        sender,
        encode_number(frame.own_lat, "%.5f"),
        encode_number(frame.own_lon, "%.5f"),
        encode_number(frame.own_alt, "%.1f"),
        encode_number(frame.own_hdg, "%.3f"),
        encode_number(frame.timestamp, "%.2f"),
        tostring(count),
    }
    for index = 1, count do
        local track = tracks[index]
        local encoded = string.format("%d,%.5f,%.5f,%.1f,%.3f,%d,%d",
            integer(track.id, 1, M.MAX_TRACK_ID) or index,
            finite(track.lat) or 0,
            finite(track.lon) or 0,
            finite(track.alt) or 0,
            finite(track.hdg) or 0,
            integer(track.side, 0, 2) or 0,
            integer(track.raid, 1, 99) or 1)
        if version == M.KINEMATIC_VERSION then
            if track.velocity_valid == true then
                if not valid_velocity(track.vx, track.vy, track.vz) then return "" end
                encoded = encoded .. string.format(",%.2f,%.2f,%.2f", track.vx, track.vy, track.vz)
            else
                encoded = encoded .. ",NA,NA,NA"
            end
        end
        fields[#fields + 1] = encoded
    end
    local result = table.concat(fields, "|")
    if #result > (version == M.VERSION and M.LEGACY_MAX_FRAME_BYTES or M.MAX_FRAME_BYTES) then return "" end
    return result
end

function M.rewrite_sender(frame, sender)
    local parsed, err = M.parse_frame(frame)
    if not parsed then return nil, err end
    parsed.sender = sanitize_sender(sender)
    if not parsed.sender then return nil, "BAD_SENDER" end
    local result = M.serialize_frame(parsed)
    if result == "" then return nil, "ENCODE_FAILED" end
    return result
end

function M.server_frame(session, sequence, side, timestamp, payload)
    local parsed = M.parse_frame(payload)
    if type(session) ~= "string" or #session < 1 or #session > 48
        or session:find("[^%w_%-]") or not integer(sequence, 1, 2147483647)
        or not integer(side, 1, 2) or not finite(timestamp) or timestamp < 0
        or not parsed or not M.is_awacs_sender(parsed.sender) then return nil end
    return table.concat({"F5EM_LBR2_SERVER", "1", session, tostring(sequence), tostring(side),
        string.format("%.3f", timestamp), "3", payload}, "|")
end

function M.server_receiver(host, port)
    local receiver = {host = host, port = port, retired = {}, retired_count = 0}
    function receiver:ingest(packet, now, source_host, source_port, own_side)
        if type(self.host) ~= "string" or source_host ~= self.host or source_port ~= self.port
            or not integer(self.port, 1024, 65535) then return nil, "UNTRUSTED_SOURCE" end
        if type(packet) ~= "string" or #packet > M.MAX_FRAME_BYTES + 256
            or packet:find("[\r\n]") then return nil, "BAD_PACKET" end
        local session, sequence, side, timestamp, ttl, payload = packet:match(
            "^F5EM_LBR2_SERVER|1|([%w_%-]+)|(%d+)|([12])|([%d.]+)|([%d.]+)|(.+)$")
        sequence, side, timestamp, ttl, now = integer(sequence, 1, 2147483647), tonumber(side),
            finite(timestamp), finite(ttl), finite(now)
        if not session or #session > 48 or not sequence or not timestamp or not ttl
            or ttl <= 0 or ttl > 3 or not now or now < 0 then return nil, "BAD_ENVELOPE" end
        if side ~= own_side then return nil, "WRONG_COALITION" end
        if timestamp > now + 0.5 or now - timestamp > ttl then return nil, "EXPIRED" end
        local parsed = M.parse_frame(payload)
        if not parsed or not M.is_awacs_sender(parsed.sender) then return nil, "BAD_PAYLOAD" end
        if self.retired[session] then return nil, "OLD_SESSION" end
        local new_session = self.session ~= session
        if not new_session and (sequence <= self.sequence or timestamp < self.timestamp) then
            return nil, "REPLAY"
        end
        if new_session and self.session then
            if self.retired_count >= 32 then return nil, "SESSION_LIMIT" end
            self.retired[self.session] = true
            self.retired_count = self.retired_count + 1
        end
        local changed = new_session or self.side ~= side
        self.session, self.sequence, self.timestamp, self.side = session, sequence, timestamp, side
        return payload, changed
    end
    return receiver
end

local function distance_nm(a, b)
    local lat1, lat2 = math.rad(a.lat), math.rad(b.lat)
    local dlat = lat2 - lat1
    local dlon = math.rad(b.lon - a.lon)
    local x = dlon * math.cos((lat1 + lat2) * 0.5)
    return math.sqrt(x * x + dlat * dlat) * EARTH_RADIUS_M * M_TO_NM
end

local function merge_side(a, b)
    if a == b then return a end
    if a == 0 then return b end
    if b == 0 then return a end
    return 0
end

local function cue_key(track)
    return "awacs:" .. tostring(track.session or "legacy") .. ":"
        .. tostring(track.sender or "link") .. ":" .. tostring(track.id)
end

function M.fuse(local_tracks, remote_tracks, options)
    options = options or {}
    local limit = options.limit or M.DEFAULT_TRACK_LIMIT
    local merge_nm = options.merge_nm or M.DEFAULT_MERGE_NM
    local output = {}

    for _, track in ipairs(type(local_tracks) == "table" and local_tracks or {}) do
        if #output >= limit then break end
        local copy = copy_track(track)
        copy.remote = false
        copy.sources = math.max(1, copy.sources)
        output[#output + 1] = copy
    end

    for _, track in ipairs(type(remote_tracks) == "table" and remote_tracks or {}) do
        local duplicate = nil
        for _, candidate in ipairs(output) do
            local distinct_awacs = candidate.source_kind == 2 and track.source_kind == 2
                and (candidate.id ~= track.id or candidate.session ~= track.session)
            if not distinct_awacs and distance_nm(candidate, track) <= merge_nm then
                duplicate = candidate
                break
            end
        end
        if duplicate then
            duplicate.sources = math.max(1, duplicate.sources or 1) + math.max(1, track.sources or 1)
            duplicate.raid = math.max(duplicate.raid or 1, track.raid or 1)
            duplicate.affil_conflict = duplicate.affil_conflict or track.affil_conflict == true
                or ((duplicate.side or 0) > 0 and (track.side or 0) > 0 and duplicate.side ~= track.side)
            duplicate.side = merge_side(duplicate.side or 0, track.side or 0)
            duplicate.has_peer = duplicate.has_peer or track.has_peer
                or track.source_kind == 1
            duplicate.has_awacs = duplicate.has_awacs or track.has_awacs
                or track.source_kind == 2
            if duplicate.remote and cue_key(duplicate) ~= options.preferred_key
                and ((track.source_kind or 1) > (duplicate.source_kind or 1)
                or ((track.source_kind or 1) == (duplicate.source_kind or 1)
                    and (track.age or 0) < (duplicate.age or math.huge))) then
                duplicate.lat, duplicate.lon = track.lat, track.lon
                duplicate.alt, duplicate.hdg = track.alt, track.hdg
                duplicate.velocity_valid = track.velocity_valid == true
                duplicate.measurement_time = track.measurement_time
                duplicate.vx = track.velocity_valid and track.vx or nil
                duplicate.vy = track.velocity_valid and track.vy or nil
                duplicate.vz = track.velocity_valid and track.vz or nil
                duplicate.age, duplicate.sender, duplicate.id = track.age, track.sender, track.id
                duplicate.session, duplicate.source_kind = track.session, track.source_kind or 1
            end
        elseif #output < limit then
            output[#output + 1] = copy_track(track)
        end
    end
    return output
end

function M.new(options)
    options = options or {}
    local state = {
        peer_ttl = options.peer_ttl or M.DEFAULT_PEER_TTL_S,
        peers = {},
        last_error = nil,
    }

    function state:ingest(frame, received_at, self_id, session)
        received_at = finite(received_at)
        if not received_at or received_at < 0 then return false, "BAD_RECEIVE_TIME" end
        local parsed, err = M.parse_frame(frame)
        if not parsed then self.last_error = err; return false, err end
        local own = sanitize_sender(self_id)
        if own and parsed.sender == own then return false, "SELF" end

        local previous = self.peers[parsed.sender]
        if previous and parsed.timestamp < previous.frame.timestamp then
            return false, "REPLAY"
        end
        if previous and parsed.raw == previous.frame.raw then
            return false, "DUPLICATE"
        end
        if previous and parsed.timestamp == previous.frame.timestamp then
            return false, "REPLAY"
        end
        for _, track in ipairs(parsed.tracks) do
            track.age = 0
            track.session = session
        end
        self.peers[parsed.sender] = {frame = parsed, received_at = received_at}
        self.last_error = nil
        return true, parsed
    end

    function state:collect(now, preferred_key)
        now = finite(now) or 0
        local senders = {}
        for sender in pairs(self.peers) do senders[#senders + 1] = sender end
        table.sort(senders)
        local tracks_by_sender = {}
        for _, sender in ipairs(senders) do
            local peer = self.peers[sender]
            local age = math.max(0, now - peer.received_at)
            if age > self.peer_ttl then
                self.peers[sender] = nil
            else
                local sender_tracks = {}
                for _, track in ipairs(peer.frame.tracks) do
                    local copy = copy_track(track)
                    copy.age = age
                    copy.source_kind = M.is_awacs_sender(sender) and 2 or 1
                    copy.has_peer = copy.source_kind == 1
                    copy.has_awacs = copy.source_kind == 2
                    sender_tracks[#sender_tracks + 1] = copy
                end
                tracks_by_sender[#tracks_by_sender + 1] = sender_tracks
            end
        end
        local remote = {}
        local track_index = 1
        while true do
            local added = false
            for _, sender_tracks in ipairs(tracks_by_sender) do
                local track = sender_tracks[track_index]
                if track then
                    remote[#remote + 1] = track
                    added = true
                end
            end
            if not added then break end
            track_index = track_index + 1
        end
        if preferred_key then
            for index, track in ipairs(remote) do
                if track.source_kind == 2 and track.age < 2 and cue_key(track) == preferred_key then
                    table.remove(remote, index)
                    table.insert(remote, 1, track)
                    break
                end
            end
        end
        return M.fuse({}, remote, {
            limit = options.limit or M.DEFAULT_TRACK_LIMIT,
            merge_nm = options.merge_nm or M.DEFAULT_MERGE_NM,
            preferred_key = preferred_key,
        })
    end

    return state
end

M._internal = {
    finite = finite,
    sanitize_sender = sanitize_sender,
    distance_nm = distance_nm,
}

return M