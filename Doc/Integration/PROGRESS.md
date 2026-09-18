# AMXDENIS M1 — integração interna REV07

## Checkpoint atual — encaixe em missão aceito pelo usuário

O cockpit dianteiro REV07 foi aberto em missão isolada e reposicionado para
`{2.9698572158813477, 1.3359999656677246, 0}`, usando o ponto medido do exterior
original. Após a comparação, o usuário confirmou **“funcionou”**.
Os modelos, os descritores e o SFM permanecem intactos.

O [relatório nativo](NATIVE_TESTS.md) identifica as capturas e o candidato L.
**O aceite é do encaixe visual:** teclado, mouse/HOTAS, três texturas ausentes
e os sistemas nativos fora do escopo não foram promovidos a PASS. A alteração
observada nas opções normais foi preservada; o alerta de integridade permanece
registrado sem atribuição de autoria ou restauração automática.

CI final: 219 scripts Lua, 527 verificações de registro/inputs, 1.599 de runtime,
22.008 dos indicadores e 16 do observador, além das guardas existentes.
Commit/sincronização solicitados com autor Alexandre Lippi; créditos originais mantidos.

## Histórico — integração e bancada, 17/09/2026 UTC

**BANCADA concluída para o candidato AMXT_M dianteiro; aprovação nativa falsa.**
O [relatório da integração](SYSTEMS_BENCH.md) detalha escopo, comandos,
limitações, reconstrução e reversão. As montagens independentes H/I contêm
392 arquivos mais manifesto, idênticos byte a byte, gerados de 423 insumos locais.

- 190 referências seletivas importadas; nenhum exterior, descritor doador ou DLL.
- 105 ações atribuíveis pelo teclado; 34 zonas com conector/argumento medidos,
  71 ações somente por teclado. Sem atalhos pessoais alterados; mouse/HOTAS nativos pendentes.
- Cinco indicadores e sistemas de energia/partida/hidráulica simplificada,
  EICAS/combustível/BINGO, modos e inventário somente leitura das sete estações.
- Em cada montagem: 219 scripts Lua analisados, 171 verificações de registro,
  1.596 de dispositivos/comandos e 22.008 de indicadores, em 69 páginas.
- Os 84 arquivos originais, inclusive carregador e modelos, continuam idênticos.
  O carregador moderno só é aplicado dentro do candidato gerado.
- `RuntimeState=BANCADA`, `BindingsState=REVALIDAR`, suíte desabilitada na árvore
  de trabalho. As três texturas ausentes e os bloqueios nativos permanecem.
- Sem missão DCS, instalação normal, interferência em processos, commit ou push.

Evidências atuais: [CI](Evidence/Systems-REV07/ci-H.log),
[bancada H](Evidence/Systems-REV07/bench-H.json),
[reprodutibilidade](Evidence/Systems-REV07/reproducibility.json) e
[preflight](Evidence/Systems-REV07/preflight.json).

## Histórico — texturas e aceite visual anteriores

Atualizado em 17/09/2026. Variante: **AMXT_M, piloto dianteiro**.
O registro histórico abaixo reúne a importação das texturas, a autorização local e o aceite
visual no ModelViewer. **Não é o primeiro candidato funcional, nem uma
montagem de runtime ou aprovação do cockpit em missão DCS.**

## Aprovação visual do usuário — 17/09/2026

**ACEITO NO ESCOPO VISUAL:** após abrir o REV07 com as texturas no ModelViewer2,
o usuário confirmou: **“validado esta perfeito”**.
O [registro de aceite](Evidence/REV07-user-visual-acceptance.json) identifica
modelo, manifesto de texturas, perfil privado e hashes da evidência correspondente.
O aceite é da aparência observada pelo usuário, não uma medição visual automatizada.

As 102 texturas e o modelo preparados permaneceram idênticos na conferência dos
107 arquivos do perfil de visualização. As três referências ainda não resolvidas
localmente continuam no inventário; a aprovação visual não comprova sua resolução
no pacote, nem substitui os testes de instrumentos, controles, vistas e voo.
Os estados `BindingsState=REVALIDAR` e `RuntimeState=PLANEJADO` foram preservados.

O observador anterior registrou corretamente o perfil e o retorno de `LoadModel`,
mas sua verificação de processo ficou inconclusiva. Esse resultado bruto e os
61 registros de erro enumerados no log não foram reescritos como PASS ou log limpo.
Na conferência após o aceite, o viewer estava fechado e seu perfil foi mantido;
não houve reabertura nem limpeza automática.

Foi observada também alteração nas opções normais do DCS, incluindo uma gravação
posterior ao fechamento do log do viewer. As versões observadas foram registradas
no arquivo local de ambiente, sem atribuir autoria nem restaurar uma versão antiga.
Por isso, não há declaração de encerramento integral da auditoria de ambiente.

**Próximo marco:** integração funcional do cockpit na variante AMXT_M dianteira,
preservando o exterior e o SFM originais. O aceite visual não encerra o M1 funcional.

## Resultado desta entrega

- Modelo interno preservado: [REV07](../../Shapes/AMX_COCKPIT_REV07_184.edm),
  48.056.855 bytes, SHA-256
  `7C2F1DE3C8AF4F8684C0C892A24EEFA4497C438CB85CAD0D09A177445B1D3342`.
- Exterior preservado: [modelo AMX](../../Shapes/AMX.edm), SHA-256
  `3372D5598EF82B76C23E35B87D583C728E639DE2B19F154163952EB21B101B16`.
- O inspetor leu o REV07 inteiro sem recuperação parcial: 101 conectores,
  114 materiais e 105 nomes de textura. São registros estáticos, não evidência
  de aparência, posição ou controles no simulador.
- **102 texturas, 325.782.571 bytes**, copiadas sem conversão ou renomeação para
  [a área interna](../../Cockpit/AMX-A1M/Textures).
- 101 arquivos vieram da pasta fornecida pelo usuário,
  `D:/Desenvolvimento/manual amx/Textura/Textura`. Somente o mapa normal
  `F5EM_INTR_1_nml.png` veio do snapshot F-5EM já identificado na origem.
- Para os nomes `paineis console amx pedestal` e `ufcp`, havia bytes diferentes
  na origem antiga: foi selecionada explicitamente a versão da pasta REV07
  fornecida, conforme a prioridade registrada no plano.
- A inspeção usando **somente a pasta interna do destino** resolveu os mesmos
  102 nomes. Nenhum cache `.tx` ou recurso não referenciado foi importado.
- O [manifesto local](../../Config/AMXDENIS_TEXTURES.json) contém origem relativa,
  destinos, tamanhos e hashes. Sua verificação não lê o workspace antigo.
- Não foram alterados carregador, descritores, SFM, contatos, pilones, Input,
  modelos, LODs, texturas ou pinturas externas. As texturas novas ainda não
  foram montadas por um carregador de cockpit integrado.

## Autorização e atribuição

A resposta explícita do usuário — “Sim 100% autorizado eu estou no
desenvolvimento conjunto” — está registrada em [PERMISSIONS.json](PERMISSIONS.json).
Abrange, para este candidato local, REV07, suas texturas/recursos, dependências
Lua F-5EM/A-29 e a DLL avSimplestWeaponSystem. O [aviso F-5EM](Notices/F5EM-NOTICE.txt)
foi preservado byte a byte para o componente do snapshot utilizado.

Isso remove o bloqueio de falta de confirmação do usuário, mas não representa
verificação jurídica independente, relicenciamento, autorização de publicação,
instalação normal ou contorno de verificações de licença. `Embraer AMX` e `BR`
permanecem a identidade original. Nenhum script doador ou DLL foi importado
nesta entrega de texturas.

## Bloqueios restantes

| Item | Estado observado | Próxima condição necessária |
| --- | --- | --- |
| `f18c_cpt-naces1` | Sem arquivo correspondente nas fontes consultadas | Arquivo autorizado com correspondência exata, ou decisão explícita sobre adaptação interna |
| `f18c_cpt-tex12` | Sem arquivo correspondente nas fontes consultadas | Mesma condição; não copiar automaticamente recurso comercial |
| `mb339_glass` | Sem arquivo correspondente nas fontes consultadas | Mesma condição; não renomear outro vidro para mascarar a ausência |
| `PTR-HUD-CENTER`, `PTR-HUD-DOWN`, `PTR-HUD-RIGHT` | Duas ocorrências por nome no REV07 | Mapear ambos os conjuntos; qualquer derivado interno deve preservar o REV07 fonte |
| Bindings do REV07 | REVALIDAR | Conferir posição, medidas, argumentos, materiais e controles deste hash; não aplicar automaticamente os bindings/gerador do cockpit antigo |
| Runtime integrado | PLANEJADO | Construção seletiva, adaptação ao original e testes próprios antes do smoke nativo |

A nova pasta resolveu **14 das 17 ausências anteriores**, não todas elas.
Nenhuma textura substituta foi criada. A [configuração](../../Config/AMXDENIS_INTEGRATION.json)
continua com suíte desabilitada na árvore de trabalho, FLIR/HMD/rádio experimental
OFF e exterior/física imutáveis. O [diagnóstico atual](Evidence/REV07-preflight.json)
registra `ImportedFiles=102`, `CandidateReady=false` e `NativeValidated=false`.

## Verificações executadas

- [Importação](Evidence/REV07-texture-import.json): 102 cópias conferidas por
  SHA-256; fontes copiadas e baseline protegido preservados.
- [Verificação local](Evidence/REV07-texture-verify.json): 102 recursos e seus
  tamanhos/hashes, sem consultar as fontes externas.
- [Bancada](Evidence/REV07-infrastructure-tests.log): 7 arquivos PowerShell
  analisados, 35/35 guardas de integração, 36/36 guardas de texturas e 8 testes
  Python do inspetor aprovados. Isso não inclui runtime Lua ou missão DCS.
- Os testes incluem prioridade da fonte, arquivos ausentes, duplicidade,
  conflito externo, mudança concorrente, sobrescrita recusada, verificação
  sem os arquivos originais e reversão preservando arquivos alheios.

As contagens não medem fidelidade. Nenhum DCS foi iniciado ou encerrado,
nenhum perfil normal foi gravado e nenhum commit/push foi feito nesta entrega.

## Reconstrução e reversão

[Import-AMXDENISCockpitTextures.ps1](../../Tools/Import-AMXDENISCockpitTextures.ps1)
separa `Plan`, `Import` e `Verify`. A cópia incompleta exige `AllowIncomplete`
explicitamente, registra as ausências e nunca aprova cockpit ou voo. `Verify`
usa só o manifesto e os arquivos no destino. Planos e relatórios existentes
não são sobrescritos; não executar nova importação sobre recursos já presentes.

Arquivo de trabalho desta execução, sob `%LOCALAPPDATA%/AMXDENIS-Integration`:

- `Runs/REV07-Textures-20260917T192222Z-196f1eaa`: inventários completos, plano,
  intenção de importação, logs, resultados e recibo `integration-receipt.json`.
- `Backups/REV07-Textures-20260917T192536Z-4a6c13ba`: checkpoint dos **92 arquivos
  do destino antes desta entrega**, preservando a infraestrutura anterior.
- `Backups/M1-20260917T185749Z-fcc3bdc3`: snapshot completo original, não alterado.

A reversão usa [Restore-AMXDENISIntegration.ps1](../../Tools/Restore-AMXDENISIntegration.ps1)
com o checkpoint pré-texturas e o recibo desta execução. `Preview` não grava;
`Apply` só restaura/remove os arquivos com hash pós-alteração ainda idêntico.
O REV07 não é arquivo novo pertencente a esta importação e não será removido.
Arquivos de outra sessão ou edições posteriores interrompem a reversão em vez
de serem substituídos por um backup antigo. Nenhuma reversão foi aplicada ao
repositório real; o percurso destrutivo foi testado apenas em fixtures próprias.