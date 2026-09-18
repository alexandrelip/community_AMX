# REV07: teste nativo e encaixe dianteiro

Complemento posterior: [inspeção e correção da leitura dos visores](DISPLAY_ALIGNMENT.md).
Os resultados abaixo permanecem como registro do encaixe e da primeira campanha.

## Resultado atual

Em 17/09/2026 local (18/09 UTC), o usuario pediu teste em jogo e depois
ajuste de encaixe. Apos a comparacao no DCS, confirmou: **"funcionou"**.
Este e um aceite do **encaixe visual dianteiro**, nao uma aprovacao de todos
os aviônicos, entradas fisicas ou do modelo de voo.

O candidato aceito visualmente e **AMXT_M-REV07-Align-L**:

- BuildId: `5D41C50ED61EDA5940AE588AF78ED807ED0A2AB2368BC0ED8AFB547028652039`.
- Runtime e perfil: `Native-REV07-K-AlignMeasured-20260918`.
- Ponto do cockpit: `{2.9698572158813477, 1.3359999656677246, 0}`.
- Origem da medida: translacao do `hide_cockpit_114`, TransformNode 91 do
  exterior original, SHA256 `3372D5598EF82B76C23E35B87D583C728E639DE2B19F154163952EB21B101B16`.
- Os EDMs, descritores, contatos, pilones, massas e coeficientes SFM nao foram editados.

O deslocamento anterior `{2.731,0,0}` vinha de `Cockpit_AJET`, do outro mod.
Um teste reversivel com `{0,0,0}` colocou a camera dentro da fuselagem e foi
rejeitado. A altura medida removeu a grande sobreposicao externa na vista
superior direita. A alca preta superior permaneceu nas tres posicoes: nao foi
removida ou ocultada para fabricar um resultado visual.

[Antes](Evidence/Native-REV07/before.png),
[comparacao rejeitada](Evidence/Native-REV07/zero-offset-rejected.png),
[encaixe aceito](Evidence/Native-REV07/alignment-accepted.png) e
[registro de aceite](Evidence/Native-REV07/visual-acceptance.json).

## O que foi realmente observado

| Verificacao | Resultado e limite |
| --- | --- |
| Missao solo no Caucaso, AMXT_M dianteiro | READY nativo e cockpit visivel, com inicializacao de HUD/MFD/EFI/ICP; nao e validacao de voo |
| Encaixe visual | Aceito pelo usuario no candidato L; outros angulos/VR/eyebox completo nao certificados |
| MFD esquerdo | Desligamento observado por `performClickableAction` diagnostico, com parametro e imagem; nao contado como teclado |
| Input nativo | Layer ativo observado: `Unit AMX`. Mapeamento do candidato corrigido para esse layer, mantendo as teclas/eixos nativos originais |
| Teclado integrado | Binding nativo valido, mas as tentativas automatizadas nao produziram a transicao esperada; **nao aprovado** |
| Mouse do ICP | Tentativas enviadas e tentativas bloqueadas separadas; sem transicao funcional comprovada; **nao aprovado** |
| HOTAS X56 | Dispositivos detectados, sem exercicio fisico controlado concluido; **nao aprovado** |
| Texturas | As tres referencias locais ausentes permanecem; nenhuma substituicao criada |
| Radio/sensores/disparo | RX/TX, radar, RWR, FLIR, HMD e disparo continuam fora desta aprovacao |

A consulta inicial `profile=nil` ocorreu antes da inicializacao da base da
interface de controles e foi inconclusiva. A auditoria posterior registrou os
perfis e os bindings reais sem salvar ou recarregar o input. A correcao de layer
nao foi transformada em PASS de teclado: o resultado negativo posterior foi mantido.
Um clique enviado com menu pausado nao vale como teste do cockpit; o helper agora
exige telemetria recente antes das entradas. Um cursor deslocado bloqueia o clique.

## Falhas e preservacao

- As execucoes A/B em `bin-mt` registraram access violation em `amdxc64.dll`
  durante a inicializacao grafica, e o observador rejeitou a espera. A execucao
  A depois registrou READY e 88 amostras, mas nao foi aprovada; B, repetida com
  upscaling privado OFF, nao registrou READY. Nao houve edicao de driver, proxy
  grafico ou OptiScaler. A pasta padrao `bin` permitiu continuar os testes.
- A execucao H terminou com `0xc0000374` em `ntdll.dll`. A repeticao I com
  o mesmo candidato carregou. A causa do erro de heap nao foi estabelecida.
- Os logs registram o modelo de dano original como corrompido, alem de erros
  de modulos instalados, missao e recursos. Nao se alega log nativo limpo;
  nenhum modelo de dano/exterior foi trocado para contornar esses registros.
- No encerramento da execucao de alinhamento, o arquivo de opcoes do DCS normal
  havia mudado: quatro campos de dificuldade foram adicionados. A versao atual
  foi preservada, sem atribuir autoria nem restaurar o backup. O resultado bruto
  `IntegrityPassed=false` continua em [finalization.json](Evidence/Native-REV07/finalization.json).
  O aceite visual nao elimina essa ressalva de ambiente.
- As copias temporarias de autenticacao foram removidas ao finalizar os perfis;
  elas nao fazem parte do repositorio. Os perfis de teste e logs brutos locais
  foram retidos. Somente processos identificados como pertencentes ao teste foram encerrados.

Os registros brutos estao em `%LOCALAPPDATA%/AMXDENIS-Integration/Runs/Native-REV07-*`.
O checkpoint pre-teste e `Backups/Native-REV07-20260917T235608Z-9d877ab2`.
Snapshots e recibos da bancada anterior continuam historicos; nao restaurar uma
versao antiga da origem ou do perfil normal sobre mudancas posteriores.

## Bancada final e reproducao

[CI final](Evidence/Native-REV07/ci-final.log): 15 arquivos PowerShell analisados;
35/36/27/12 guardas de integracao/texturas/viewer/ancoras; 8 testes Python do
inspetor, 14 do construtor e 16 verificacoes do observador; 219 scripts Lua,
527 verificacoes de registro/inputs, 1.599 de runtime e 22.008 dos indicadores
(69 paginas). [Resultado do candidato](Evidence/Native-REV07/bench-final.json).

[Test-AMXDENISNative.ps1](../../Tools/Test-AMXDENISNative.ps1) separa Prepare,
Start, Await, Inspect, Command, Stop e Verify. Cada nova execucao exige um run
novo, candidato verificado e perfil `DCS.AMXDENIS-*`. Para este ambiente, usar
`-EngineDirectory bin`; a preparacao desativa VR/upscaling apenas no perfil
privado. `Command` e diagnostico, nunca prova de tecla, clique ou HOTAS.

O pedido posterior de commit/sincronizacao usa autor **Alexandre Lippi**,
com o email ja configurado no Git. Creditos, identidade do plugin e historico
original sao preservados. A confirmacao visual nao altera os limites tecnicos
documentados acima, nem concede aprovacao nativa integral.