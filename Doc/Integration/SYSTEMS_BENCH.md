# AMXT_M REV07 — integração e bancada

## Estado e escopo

**BANCADA, 17/09/2026 UTC. Não validado em missão DCS.**
O candidato integra o posto dianteiro do **AMXT_M** ao AMXDENIS original.
A aprovação visual anterior do REV07 pelo usuário continua limitada à aparência
no ModelViewer; não foi reutilizada como aprovação funcional.

As montagens independentes **H e I** contêm 392 arquivos de conteúdo, mais o
manifesto, e são idênticas byte a byte. Os 423 insumos são identificados por hash.

- BuildId: `952FB0BAE7527A0FB744CCEDB6BDE3919BCB92A8DC1136F2809821DFA95B1A34`
- Manifesto: `2541822FA61C4996D58D8CF66B1EB9E94ECE698A2F441F7C270E54D887D1FD5D`
- Insumos: `8973E1543CABC3674FC729B4D0470129D98D27DE7FAB4113D34480D6996B3EB8`
- Conteúdo: 621.028.065 bytes por candidato, antes do manifesto.
- Evidência: [bancada H](Evidence/Systems-REV07/bench-H.json),
  [bancada I](Evidence/Systems-REV07/bench-I.json) e
  [reprodutibilidade](Evidence/Systems-REV07/reproducibility.json).

O resultado mede contratos e execução Lua com sensores/renderer de teste
explicitamente simulados. Não mede fidelidade do AMX real, renderização,
licenciamento nativo, voo, precisão de alinhamento nem resposta física do DCS.

## O que foi implementado

| Área | Implementação deste candidato | Limite preservado |
| --- | --- | --- |
| Modelo e texturas | REV07 integral, 102 texturas verificadas, cinco indicadores: LEFT, RIGHT, HUD, AUX/EFI e ICP | Nenhum byte do EDM alterado; três referências de textura continuam sem arquivo local |
| Comandos | 105 ações lógicas atribuíveis no teclado; 34 zonas com conector/argumento medidos; 71 ações somente por teclado | Nenhum atalho ou dispositivo físico atribuído automaticamente; mouse/HOTAS ainda não testados no DCS |
| Roteamento | Mesmo comando e proprietário para teclado/clique, bordas de pressão/soltura, rejeição de valores inválidos, eixos de brilho normalizados | Retorno significa aceitação do pedido pelo script, não atuação física comprovada |
| Energia | Bateria, dois geradores associados ao RPM genérico do único motor, seletores e falhas independentes, retorno de alimentação | Modelo de barramentos simplificado; não representa capacidade da bateria nem rede elétrica calibrada |
| Partida | START, neutro, cancelamento e corte de combustível solicitam os comandos nativos; pressão mantida não repete partida | Não simula pneumaticamente APU, ar de partida ou DECU; resposta nativa pendente |
| Hidráulica | Dois canais simplificados, dependentes da disponibilidade do RPM e de falhas, validade separada | Indicação herdada 0/206 bar acima do limiar 53%; não aplica forças/superfícies e não é calibração AMX |
| EICAS/combustível | Total de combustível, vazão com unidades explícitas e estados válidos/indisponíveis; BINGO configurável no ICP e reconhecimento de alarme | Não inventa NL/NH, TGT, óleo, segundo motor ou quantidades por tanque |
| Voo/HUD/EFI | Dados de voo nativos com validação, conversões de unidades, brilho, modos e supressão quando a fonte de voo fica inválida | Sem piloto automático ou modificação do SFM; validade não prova precisão física |
| MFD/ICP | Páginas e edição herdadas adaptadas; alimentação/brilho independentes, edição de BINGO e preservação após entrada inválida | Dados e estados de navegação modelados não são validação de um EGI real |
| Mecanismos | Pedidos nativos de trem, flap UP/DOWN e canopy; impedimento de recolher trem com WoW conhecido no solo | Meio flap não presumido; sem escritores de argumentos externos; curso físico não testado |
| SMS | Leitura de inventário das sete estações, com validade e indisponibilidade explícitas | Sem integração de seleção/disparo/alijamento; `Pylon8` original na estação 7 não foi renomeado |
| Rádio e sensores | Edição de páginas COM; telas de funções não integradas indicam indisponibilidade | Sem RX/TX nativo, radar/RWR, FLIR, HMD ou datalink registrados neste marco |

O [mapa de comandos gerado](Evidence/Systems-REV07/controls.csv) contém nome,
ID de entrada, proprietário, comando de destino e conector quando existente.
Ele não é uma lista de atalhos já ligados a teclas. Os perfis novos preservam
os comandos nativos da base; somente a entrada `CustomKeybinds.FireWeaponOn/Off`
sem definição no cockpit original foi retirada da **cópia AMXT_M gerada**.
Isso não constitui uma garantia de desarmamento global dos comandos nativos DCS.

O painel repete os valores dos parâmetros internos a cada atualização para
evitar depender da interpolação de uma publicação única. Argumento presente
na ancestralidade do conector não comprova zona clicável, direção do movimento,
curso, conforto ou leitura no simulador.

## Preservação e arquitetura

- Os **84 arquivos originais** do baseline continuam idênticos, inclusive
  [entry.lua](../../entry.lua), descritores, exterior, colisão incorporada,
  LOD, pinturas, texturas, Input e o REV07 fornecido pelo usuário.
- As quatro declarações completas `AMX`, `AMXT`, `AMX_M`, `AMXT_M` são comparadas
  em Lua contra [fixtures congeladas](../../ci/fixtures/original). As massas,
  sete estações, um motor e a ligação SFM `nil` não foram substituídos pela origem.
- O [carregador do candidato](../../Avionics/AMXDENIS/patches.lua) é uma
  transformação literal e restrita do original. Só a montagem gerada seleciona
  o cockpit moderno para `AMXT_M`; a árvore de trabalho não ativa a suíte.
- As outras três variantes retêm o caminho de cockpit original, que já estava
  ausente no baseline. A preservação de seus descritores não aprova sua flyability.
- [Entry/Views.lua](../../Entry/Views.lua) acrescenta a configuração dianteira
  antes referenciada mas ausente. Offset e limites de visão são valores iniciais;
  não criam um posto traseiro funcional nem aprovação do eyebox.
- Foram importados **190 arquivos selecionados**, sem executar entry do doador,
  sem DLLs e sem exterior da origem. O [manifesto imutável](../../Avionics/Reference/AMX-A1M/import-manifest.json)
  identifica o snapshot da revisão `c60fab3ce11e273e76995ff95494fd2be1db2109`.
  Essa revisão já havia avançado externamente antes do checkpoint desta etapa.
- Os **2.243 arquivos de trabalho da origem** presentes no snapshot foram
  conferidos novamente, sem diferença. A alteração preexistente em seu teste
  de display não foi restaurada, removida nem atribuída a esta tarefa.
- Atribuição MIT/F-5EM/A-29 e declaração de autorização local são preservadas.
  Não há autorização de redistribuição, mudança de identidade, bypass de licença,
  commit/push ou instalação no perfil normal.

## Testes realmente executados

| Verificação | Resultado |
| --- | ---: |
| Parser PowerShell | 12/12 arquivos |
| Guardas de integração | 35/35 |
| Guardas de texturas | 36/36 |
| Guardas do viewer isolado | 27/27 |
| Guardas de medidas/âncoras | 12/12 |
| Inspetor Python | 8 testes |
| Construtor Python | 14 testes |
| Sintaxe Lua 5.1 do candidato | 219/219 arquivos |
| Registro/descritores | 171/171 verificações em H e I |
| Dispositivos e comandos | 1.596/1.596 em H e I |
| Indicadores | 22.008/22.008; 69 carregamentos de páginas; seis caminhos de recursos usados/preload verificados |
| Reconstrução independente | 392 arquivos de conteúdo e manifesto idênticos entre H e I |

[Log completo de CI](Evidence/Systems-REV07/ci-H.log). A contagem de recursos
inclui dependências comuns explicitamente identificadas; não significa seis
texturas externas importadas, nem resolução de todas as declarações dormentes
do doador. A bancada não executa o carregador gráfico/VFS nativo.

Regressões reproduzidas e corrigidas sem alterar a referência congelada:

1. Escala de brilho invertida do HUD: atualização, inicialização e incremento/
   decremento adaptados juntos a 0 apagado / 1 máximo. A primeira tentativa D
   falhou no teste de inicialização; E e as versões posteriores passaram.
2. Caminho curto Windows `ALEXAN~1` versus nome expandido: raiz e filho agora
   são canonicalizados antes da verificação de contenção, mantendo os negativos.
3. Comando recusado marcava o botão como mantido: a reprodução negativa foi
   [arquivada](Evidence/Systems-REV07/router-recovery-before.log). O estado só
   é gravado depois da aceitação; soltura de pressão aceita atravessa perda de
   energia, mas não se inventa soltura para uma pressão recusada.
4. Provas de indicadores usam os contratos reais `CMFDNu` e brilho de cada lado;
   o fixture gráfico separa rótulos estáticos de texto dinâmico. As correções
   anteriores do fixture não são falhas do renderer DCS, que não foi executado.

## Reconstruir e verificar

Requisitos: Python 3.12+ (testado com 3.14.6) e Lua 5.1 do DCS (hash registrado
em cada resultado). Não são necessários o workspace antigo nem seus testes para
reconstruir depois da importação; os arquivos grandes locais devem estar presentes.

1. [Tools/build_amxdenis.py](../../Tools/build_amxdenis.py), subcomando `build`,
   recebe `--candidate` e `--lua`. Use um **nome novo** imediatamente abaixo
   da área `%LOCALAPPDATA%/AMXDENIS-Integration/Candidates`.
2. [ci/run_tests.ps1](../../ci/run_tests.ps1) recebe `-Python`, `-Lua`,
   `-CandidateRoot` e `-ReportRoot`. O relatório deve ser novo e ficar abaixo
   da área `%LOCALAPPDATA%/AMXDENIS-Integration/Runs`.
3. [Tools/Test-AMXDENISCandidate.ps1](../../Tools/Test-AMXDENISCandidate.ps1)
   pode repetir somente a bancada do candidato, sempre com outro relatório.
   Recusa alteração dos arquivos, insumos ou interpretador após a montagem.
4. Para repetir a prova de reprodução, faça duas montagens novas sem mudar os
   insumos e compare os manifestos e todos os hashes, como registrado na evidência.

Construção e bancada **não instalam nem iniciam o DCS**. Pastas existentes,
perfis Saved Games, instalações, caminhos ligados, traversal e referência
imutável alterada são recusados. O registro de cockpit ainda exige um perfil
isolado cujo nome comece com `DCS.AMXDENIS-`; isso não é um instalador nem uma
autorização automática para criar tal perfil nesta etapa.

## Pendências nativas e reversão

O [preflight final](Evidence/Systems-REV07/preflight.json) continua bloqueado:
três texturas não resolvidas localmente e validação REV07 pendente. Os três nomes
HUD duplicados continuam no EDM. O binding não os usa diretamente: usa a tripla
única esquerda e deslocamentos medidos; orientação e máscaras ainda precisam de
prova nativa. Nenhum conector foi renomeado, nenhum placeholder de textura criado.

Próxima etapa, **separadamente autorizada**: cockpit READY em perfil isolado,
cinco displays visíveis, orientação/eyebox, cliques reais e entradas físicas,
perda/retorno de energia e resposta dos pedidos nativos, sem tocar no SFM original.
Este documento não afirma que rádio/sensores/armamento nativos foram concluídos.

Snapshot pré-etapa: `Systems-REV07-20260917T224209Z-da29bfd4` na área local de
backups. O recibo da etapa fica no run correspondente. O executor
[Restore-AMXDENISIntegration.ps1](../../Tools/Restore-AMXDENISIntegration.ps1)
oferece `Preview` sem alterações e `Apply` somente quando todos os hashes
pós-alteração ainda coincidem. Edições posteriores bloqueiam a reversão.
Não restaurar snapshots antigos da origem nem o perfil normal do DCS.
Os candidatos A–I e os resultados históricos foram mantidos; o perfil antigo
do ModelViewer não foi limpo ou reaberto nesta etapa.