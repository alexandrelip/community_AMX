# AMXT_M: plano para as areas abaixo de 7/10

Data: 18/09/2026. Escopo: AMXT_M, posto dianteiro, cockpit REV07.
Estado: EM EXECUCAO. R01 aprovado no escopo de reconstrucao; R02 com bloqueio nativo nao resolvido.
R03 tem tres subconjuntos repetidos no DCS, mas ainda nao cumpriu o aceite geral.
As demais etapas conservam seus bloqueios e criterios de aprovacao.

## Prioridade atual: quatro metas solicitadas

Pedido atualizado de 18/09: teclado 10/10, hidraulica 7/10, mouse 9/10 e X56
9/10. Estas metas substituem o alvo 7 anterior de R03/R04/R05; nao sao notas
alcancadas. Permanecem as restricoes de arquivos originais, EDM, SFM e perfil
normal. A aprovacao de um seletor nao aprova o sistema que ele deveria comandar.
Confirmacoes posteriores do usuario: movimentacao fisica do X56 fica para depois;
esta autorizada uma dinamica hidraulica de projeto, identificada como tal, sem
alegar calibracao ao AMX real. Essa decisao nao autoriza alterar SFM ou EDM.

1. R03: completar a matriz das 105 acoes e seus contextos. Exercitar primeiro
   os sete controles ICP/EGI pendentes e ACK/navegacao; separar pressionamento
   curto/longo dos OSS antes de testar os demais. Corrigir apenas o caminho
   decisorio responsavel por cada falha, com regressao e repeticao nativa.
2. R04: resolver a entrega de clique em COM1/COM2 no baseline. Registrar pose,
   cursor, tecla/modo clicavel, argumento e efeito; depois expandir para as 34
   zonas. Nenhuma zona recebe PASS por existir no EDM ou por contador de entrada.
3. R05: ampliar a leitura alem dos limites WinMM quando necessario e conferir
   o mapa privado do X56. Capturar curso, retorno ao centro, botoes/hats/modos
   com operador; verificar no DCS e repetir depois de reconectar. Nao substituir
   essa prova por injecao Windows, dispositivo virtual ou checklist preenchido.
4. R08: conferir as fontes hidraulicas e implementar dois circuitos somente
   com parametros sustentados por dados ou hipoteses de projeto explicitamente
   aprovadas. Testar tempo de pressurizacao/queda, falha isolada/total, demanda,
   invalidade e recuperacao. Preservar a separacao entre indicacao e atuacao.

Os testes DCS sao seriais, em perfis privados, com finalizacao garantida e
janela em primeiro plano. O operador nao deve usar controles durante testes
automatizados; as etapas fisicas X56 serao anunciadas separadamente. Cada
subitem concluido recebe evidencia, commit, sync da branch verificada e
comentario com hash. Dependencias sem dados, API ou operador ficam abertas,
sem atribuir a nota-alvo para encerrar o pedido.

## Objetivo e base

Levar cada uma das 11 areas avaliadas abaixo de 7 a pelo menos 7/10, mediante
implementacao e evidencia repetivel. As notas sao avaliacoes qualitativas de
funcionamento comprovado, nao percentuais de conclusao ou fidelidade certificada.
O marco 7 nao equivale a modulo completo, release publica ou aprovacao em VR.
Escala: 1 = sem funcao validada; 10 = completo e validado de forma repetivel
no escopo previsto. Nenhuma nota sobe apenas por quantidade de testes.

Referencia versionada: commit `08d5a8e` na branch `Sub-Dev`.
Candidato de acompanhamento: `AMXT_M-REV07-BB-VerifiedBaseline`, BuildId
`777D2B2B3C7DDFCC577A3E16DC597EC6FAD245D73A3F923E0ABCEC99321639DF`.
O ultimo ensaio especifico do layout/hidraulica permanece o candidato AM.
O commit registra resultados anteriores; nao significa que tudo esteja validado.

Fontes: [progresso](PROGRESS.md), [validacao operacional](OPERATIONAL_VALIDATION.md),
[EICAS e comparacao com F-5EM](EICAS_PROPOSAL.md) e
[evidencias da continuidade](Evidence/Operational-REV07/mechanisms-followup.json).

Visores (7/10) e texturas (9/10) ficam fora dos pacotes de melhoria deste plano.
Devem passar nas regressoes pertinentes. VR e as tres texturas ausentes nao
serao considerados resolvidos por essa exclusao; continuam limitacoes do pacote.

## Quadro de trabalho

| ID | Area | Nota inicial | Meta | Prioridade | Dependencia principal | Estado |
| --- | --- | ---: | ---: | --- | --- | --- |
| R01 | Reconstrucao/build | 3 | 7 | P0 | Nenhuma | Aprovado no escopo: 7/10 |
| R02 | Mecanismos | 2 | 7 | P0 | R01 | Bloqueado: atuacao nativa sem causa isolada |
| R03 | Teclado | 5 | 10 | P1 | R01; R02 para aprovar atuacao | Em execucao: 54 acoes em contextos selecionados; permanece 5/10 |
| R04 | Mouse | 3 | 9 | P1 | R01 e rotas verificadas em R03 | Helper de clique preparado; prova nativa bloqueada pela sessao Windows |
| R05 | X56 | 3 | 9 | P1 | R03 e operador fisico | Inventario HID e 67 exercicios preparados; teste fisico adiado |
| R06 | Voo completo | 2 | 7 | P1 | R02 e controles essenciais aprovados em R03 | Planejado |
| R07 | EICAS | 4 | 7 | P2 | R01 e fontes/modelos AMX validos | Bloqueado por fontes |
| R08 | Hidraulica | 4 | 7 | P2 | Modelo de projeto autorizado; R02 para consumo integrado | 6/10: dinamica repetida, consumo nativo bloqueado |
| R09 | Estabilidade | 4 | 7 | P2 | R06; repetir depois de R07/R08 | Planejado |
| R10 | Instalacao | 3 | 7 | P3 | R01-R09 aprovados e autorizacao de perfil normal | Bloqueado por marcos anteriores |
| R11 | Sistemas avancados | 1 | 7 | P4 | Base operacional e autorizacao especifica | Bloqueado por escopo |

P0 desbloqueia o trabalho; P1 estabelece operacao; P2 completa dados e
confiabilidade; P3 prepara uso local; P4 amplia sistemas. Esta ordem nao
autoriza mudancas fora do escopo ja combinado.

## Sequencia de execucao

1. Fechar R01 e produzir duas montagens normais identicas, com guardas ativas.
2. Resolver R02 por mecanismo. Validar em R03 as entradas essenciais antes de voo.
3. Ampliar teclado e mouse; executar R05 quando houver movimentacao fisica.
4. Fechar o circuito completo R06 com o escopo de sensores disponivel, sem
   declarar fidelidade dos canais ausentes do EICAS.
5. Implementar R07/R08 conforme fontes confirmadas. Repetir o circuito apos
   qualquer alteracao que afete indicacoes, mecanismos ou operacao.
6. Executar R09 sobre o candidato final dessas etapas; preparar e validar R10.
7. Abrir R11 por sistema, com aceite proprio. Repetir estabilidade e instalacao
   para cada nova versao integrada; aprovacao anterior nao se transfere sozinha.

Nao ha estimativa de horas confiavel enquanto a causa dos mecanismos e as
fontes dos sensores permanecerem desconhecidas. A cada marco concluido,
reavaliar prazo e escopo usando os bloqueios realmente removidos.

## R01 - Reconstrucao/build

Problema: a atualizacao autorizada do [README.md](../../README.md) difere do
hash historico em [AMXDENIS_ORIGINAL.json](../../Config/AMXDENIS_ORIGINAL.json).
A guarda de [build_amxdenis.py](../../Tools/build_amxdenis.py) rejeita essa
divergencia antes de montar um novo candidato. O baseline BB existente nao
prova que o checkout atual possa ser reconstruido.

1. Reproduzir a rejeicao em destino novo e preservar a mensagem exata.
2. Separar explicitamente a documentacao editavel dos recursos imutaveis, ou
   registrar uma excecao versionada restrita ao README autorizado. Registrar
   o hash corrente como insumo da montagem, mantendo o baseline historico.
3. Acrescentar regressao positiva para a documentacao autorizada e negativas
   para mudanca de EDM, descritor, SFM, referencia congelada e insumo durante
   a montagem. Nao atualizar todos os hashes nem desativar a guarda global.
4. Construir duas pastas novas com os mesmos insumos e comparar conteudo,
   manifesto e BuildId. Rodar a CI completa sobre o candidato exato.

Aceite para 7: duas montagens identicas; README atual incluido; testes negativos
continuam recusando alteracoes protegidas; nenhuma excecao generica por extensao.

Resultado de 18/09: [evidencia R01](Evidence/R01-build.json). A rejeicao foi
reproduzida antes de criar o destino. A correcao admite somente a revisao
exata do README do commit `08d5a8e`, mantendo os 84 hashes historicos; 83
arquivos continuam identicos e o README autorizado entra nos hashes de insumo
e de saida. Regressao cobre revisao nao autorizada, excecao para outros caminhos,
mudanca fisica e alteracao entre verificacao e copia.

Candidatos `AMXT_M-REV07-BC-R01-A` e `AMXT_M-REV07-BD-R01-B`: 394 arquivos
conferidos e manifestos identicos, BuildId
`06EAF4EFC87361799E03FEA36786BC1E2E458F39FA042701DC4133749DFAF2E2`.
CI completa: 20 PowerShell, 43/36/27/12 guardas, 8+21 Python, 473 observador,
221 Lua, 529 registro, 1793 runtime e 22743 indicadores em 69 paginas.
Nota R01 atualizada para 7/10 apenas nesse escopo; nao aprova cockpit ou voo.

Revalidacao final apos as ferramentas de R02: candidatos BH/BI com o mesmo
BuildId acima, 394 arquivos conferidos e manifestos identicos entre si. A CI
foi repetida integralmente e passou, agora com 48 guardas de integracao. Os
hashes e o resultado final estao em `FinalRevalidation` da mesma evidencia R01;
o primeiro resultado BC/BD permanece como historico, com seus insumos originais.

## R02 - Mecanismos

Comecar em [mechanisms.lua](../../Avionics/AMXDENIS/Scripts/Host/mechanisms.lua),
no observador e nos relatorios existentes. IDs corretos, status de comando e
mudanca de seletor nao provam movimento de trem, flaps ou canopy.

1. Montar matriz por mecanismo: entrada, recebimento, pedido, seletor, posicao
   nativa, argumento externo, indicacao interna, energia, velocidade e WOW.
2. Investigar o controlador que efetivamente atualiza o mecanismo. Testar uma
   hipotese por candidato; registrar previsao e condicao que a refutaria.
3. Tratar `Corrupt damage model` como hipotese a isolar, nao como causa provada.
   Comparar contratos de descritor com exemplos nativos sem importar valores
   fisicos do F-5. Alteracoes de descritor ficam somente no experimental.
4. Separar canopy fechada de travada, flaps selecionados de posicao real e
   alavanca de trem de pernas recolhidas/baixadas. Cobrir retornos e bloqueios
   documentados, inclusive pedido de recolhimento no solo.
5. Depois da bancada, repetir ciclos em solo e no ar nas condicoes pertinentes,
   dentro dos limites aplicaveis. Arquivar capturas e telemetria concordantes.

Nao repetir sem nova evidencia: retirada de `mechanimations`, duplicacao de
Door1, gauge de canopy e troca simples de payload 0/1 ja nao resolveram o caso.
Escrever uma animacao externa por Lua nao sera aceito como prova de fisica.

Aceite para 7: tres ciclos completos de cada mecanismo, distribuidos em pelo
menos duas sessoes novas, com posicoes reais esperadas, indicacoes coerentes e
negativos aprovados. Os numeros de repeticoes sao metas do projeto, nao do manual.
Se a solucao exigir mudar SFM, geometria ou restricoes, pedir autorizacao antes.

R02 permanece 2/10. Os diagnosticos anteriores constam das
[evidencias de mecanismos](Evidence/Operational-REV07/mechanisms-followup.json).
Experiencias locais adicionais de descritor continuam fora deste commit; nao
ha correcao de atuacao aprovada. Alterar geometria ou SFM exige autorizacao
separada, nao implicita nas metas de controles e hidraulica.

## R03 - Teclado

1. Usar o catalogo de [controls.lua](../../Avionics/AMXDENIS/controls.lua) para
   classificar as 105 acoes: implementada, indisponivel ou bloqueada por sistema.
2. Priorizar energia, partida/parada, freios, comandos de voo, mecanismos,
   selecao de MFD/ICP, brilho e reconhecimento. Preservar atalhos pessoais.
3. Para cada acao implementada, conferir recebimento e efeito no dispositivo,
   incluindo pressao/soltura, repeticao, limites e perda/retorno de energia.
4. Usar entrada Windows para provar teclado; `performClickableAction` via
   Export continua diagnostico. Acao bloqueada nao recebe PASS por catalogacao.

Aceite para 10: as 105 acoes e seus contextos previstos estao implementados e
testados nativamente com efeito no sistema, incluindo limites, repeticao,
pressao/soltura, curto/longo quando distinto e perda/retorno de energia. Repetir
a matriz em duas sessoes novas, sem falhas abertas no escopo. Listar acoes
indisponiveis como bloqueios, sem remover do denominador. Mecanismos e seletores
sem sistema integrado impedem 10; abrir pagina nao comprova capacidade do sensor.

Subitem basico concluido e sincronizado em `ecdee0e`: 93 transicoes de 13
controles em BN/BO, mais o negativo COM1 sem energia. A
[evidencia basica](Evidence/Operational-REV07/keyboard-core-results.json)
permanece historica, sem substituir seus hashes pelos da versao posterior.

Subitem navegacao/edicao: BU/BV repetiram a versao final em duas sessoes,
92 etapas de navegacao e 31 de regressao basica por sessao. Sao 246 transicoes
e 50 acoes distintas entre as duas suites. O
[resumo verificavel](Evidence/Operational-REV07/keyboard-navigation-results.json)
registra modos, dez digitos, BINGO ativo/inativo, rejeicao de 9999, CLR,
gravacao curta por ENTR e oito selecoes de pagina em cada MFD. Pagina selecionada
nao aprova sensor, radio ou armamento; os testes nao alteram os limites BINGO.

O helper agora solta a tecla principal antes dos modificadores e aguarda
telemetria nova entre as etapas, mantendo a liberacao em caso de erro. Alt+F4
foi excluido dos atalhos temporarios, sem tocar nos atalhos pessoais. BQ ficou
preservado como falha de soltura com BINGO correto; BR/BS/BT permanecem
incompletos. O usuario confirmou interacao externa durante essas interrupcoes,
sem atribuicao individual de cada evento. BU/BV terminaram com integridade
verdadeira, zero erros/rejeicoes do observador e 159 erros de severidade
ERROR/ERROR_ONCE no DCS em cada sessao; nao sao logs limpos.

Navegacao/soltura sincronizadas em `80eb2e8`. Layout sincronizado em `47538c6`.
O subitem seguinte,
[layout dos MFDs](Evidence/Operational-REV07/keyboard-layout-results.json),
passou em BX/BY: 18 etapas por sessao, 36 transicoes de FULL, troca entre
telas e retencao das selecoes ao desligar/religar. Quatro acoes adicionais
foram exercitadas, totalizando 54 entre Core/Navigation/DisplayLayout.
Esta e prova de estado funcional, nao de pixels ou legibilidade. As duas
finalizacoes tiveram integridade verdadeira; os erros nativos foram preservados.

R03 permanece 5/10. Faltam as 51 acoes fora das tres suites,
os demais contextos das acoes exercitadas e a atuacao dos mecanismos.
As 51 se distribuem em 10 acoes de energia/partida/mecanismos/navegacao/ACK,
7 acoes ICP/EGI e 17 botoes OSS por MFD. Essa contagem nao declara que todas
tenham funcionalidade integrada; a classificacao por contexto permanece pendente.

Continuidade ICP: corrigido o indice usado ao diminuir COM2 na pagina principal
(commit `8f121f8`), com regressao negativa no candidato anterior e positiva no
novo. A referencia congelada foi preservada. A suite `IcpControls` acrescenta
42 etapas para os sete controles ICP/EGI, waypoint e ACK; os estados observados
sao do produtor, nao ecos do roteador. A selecao/presets sao publicados quando
a pagina MAIN esta ativa; a chave EGI e separada de seu estado de alinhamento.

As [tentativas CE ate CI](Evidence/Operational-REV07/input-preparation-results.json)
nao concluiram essa suite. CE parou antes da primeira tecla por uma premissa
fria do teste; CF esperava waypoint 1, mas a rota de um ponto salta corretamente
para o aerodromo 90; CG recusou o alerta BINGO criado somente na primeira causa.
Essas verificacoes foram corrigidas sem regravar os resultados antigos. Um
parametro novo pode confirmar o resultado, mas nao basta para provar transicao:
pelo menos um produtor previamente observado ainda precisa mudar.

CH confirmou 34 etapas e foi interrompido por SendInput negado, no mesmo momento
em que o DCS registrou desconexao dos dispositivos RDP de entrada e video.
O usuario informou nao ter interagido. CI foi bloqueado por foco antes da
primeira tecla. Nove acoes adicionais foram observadas em execucoes incompletas;
nao foram somadas ao marco anterior de 54 acoes repetidas. EGI temporizado passou
na bancada, mas sua sequencia nativa permanece pendente. R03 continua 5/10.

## R04 - Mouse

1. Reproduzir COM1/COM2 no candidato normal com pose, viewport e modo clicavel
   registrados. Distinguir clique bloqueado, enviado e recebido.
2. Comparar centro/borda das zonas e verificar coordenadas, foco, cursor,
   conector, argumento e OBB. Alterar uma variavel por vez.
3. Cobrir as 34 zonas mapeadas, incluindo botoes, seletores reversiveis e knobs;
   testar soltura, limites, cliques vizinhos e perda de energia.
4. Revalidar nas vistas central e proxima. Nao remover guardas ou ampliar
   volumes indiscriminadamente para fazer os testes passarem.

Aceite para 9: todas as 34 zonas previstas apresentam efeito funcional correto,
sem acionar vizinhas, travar botoes ou inverter seletores/knobs, em tres ciclos
nas vistas central e proxima e em duas sessoes novas. Cobrir centro/bordas,
negativos fora da zona, soltura e perda/retorno de energia. Registrar limites
residuais de ergonomia; nenhuma falha funcional conhecida nas zonas previstas.
As 71 acoes somente de teclado nao viram zonas clicaveis por esse aceite.

Preparacao implementada no [Invoke-Input.ps1](../../Tools/Native/Invoke-Input.ps1):
`-Mouse -ClickX <x> -ClickY <y>` e `-RightButton` opcional, com
`-ExpectedParameters` obrigatorio. Verifica hash do catalogo, comando e conector,
recusa acoes keyboard-only, separa Move/Click e mantem foco, cursor exato e
telemetria recente. `-ResolveOnly` nao envia entrada. As coordenadas dependem
da vista e janela efetivamente medidas; os zeros do teste de resolucao nao sao
pontos de clique aprovados.

O resultado exige efeito no produtor, recebimento e soltura quando aplicavel.
Falhas de envio guardam fase/erro/antes/depois com aprovacao funcional falsa.
As 34 zonas constam do catalogo; 33 podem ser encaminhadas como clique por este
helper, mas nenhuma recebeu nova aprovacao nativa. `IcpBrightness` requer
arraste de eixo e e recusado, nao simulado por um clique. Depois de estabilizar
a sessao interativa, repetir COM1/COM2 no baseline antes de ampliar a cobertura.
Nao foram alterados OBB, conectores, geometria ou guardas para forcar sucesso.
R04 permanece 3/10; preparacao nao significa 9/10.

## R05 - X56

1. Manter a identificacao VID/PID e a leitura passiva por
   [Read-Hotas.ps1](../../Tools/Native/Read-Hotas.ps1) como evidencia de comunicacao.
2. Conferir o perfil DCS efetivo, duplicidade de eixos, inversao, centro, faixa,
   zonas mortas e curvas. Nao alterar configuracoes pessoais sem aceite.
3. Com o operador, exercitar os eixos de extremo a extremo e todos os botoes,
   hats e modos a incluir no perfil. Correlacionar sinal fisico, entrada DCS e
   resposta do cockpit; repetir apos reconectar o dispositivo.
4. Onde WinMM nao expuser controles, usar leitura HID/DirectInput apropriada.
   A ausencia de POV anunciado no manete nao significa ausencia de hats fisicos.

Aceite para 9: inventario HID completo e mapa documentado de todos os controles
previstos; eixos, botoes, hats e modos exercitados fisicamente e correlacionados
ao efeito no DCS, sem eixos conflitantes, sinal invertido ou acao presa. Verificar
centro, extremos, retorno e repeticao em duas sessoes, uma apos reconexao.
Campo nao exposto pela API nao conta como botao testado. Sem operador ou efeito
nativo integrado, permanece bloqueado; simulacao de entrada nao eleva a nota.

Preparacao executada: [inventario HID X56](Evidence/Operational-REV07/x56-hid-inventory.json)
obtido pelo parser HID do Windows, sem abrir dispositivos para escrita ou
alterar configuracoes. O manche declara 5 eixos, 17 botoes e um POV de oito
direcoes com neutro; o manete declara 8 eixos e 36 botoes, sem POV separado.
Os limites de 6 eixos/32 botoes do WinMM ocultavam dois eixos e quatro botoes
do manete. Interfaces HID de fabricante nao foram contadas como controles.

[Read-Hotas.ps1](../../Tools/Native/Read-Hotas.ps1) com `-IncludeHid` agora
produz a lista de 67 exercicios: 53 botoes, 13 eixos e um POV, todos PENDING.
A funcao fisica de cada usage ainda precisa ser identificada pelo operador;
um eixo declarado nao e automaticamente pitch, roll ou manete. Exige duas
sessoes, reconexao e efeito DCS, sem usar somente a leitura de um botao para
aprovar o conjunto. O leitor consulta descritores; captura completa de reports
HID ainda falta. X56 permanece 3/10; o usuario adiou a parte fisica.

## R06 - Voo completo

1. Preparar missao vazia com aerodromo/pista, estacionamento, clima, massa e
   combustivel conferidos. Instrumentar criterios de aborto antes de iniciar.
2. Validar comando, sinal e resposta de pitch, roll, rudder, manete, freios e
   trim. Nomes dos getters nao comprovam eixos corretos; hold solicitado nao
   comprova piloto automatico funcionando.
3. Executar partida, taxi, alinhamento, decolagem, subida, cruzeiro, curvas,
   descida, configuracao de pouso, pouso, taxi final e desligamento na mesma missao.
4. Registrar origem dos comandos: piloto, teclado automatizado ou sequenciador.
   Interromper por perda de controle, mecanismo incoerente, janela excedida ou
   telemetria invalida; nao usar teleport, reinicio no ar ou atuacao visual falsa.

Aceite para 7: dois circuitos completos consecutivos em sessoes novas do mesmo
candidato, sem dano involuntario nem abortos, com fases e posicoes comprovadas.
Isso valida o percurso no escopo testado, nao calibra o SFM nem certifica X56.

## R07 - EICAS

1. Completar a matriz parametro -> manual/variante -> unidade/limite -> fonte
   no mod -> validade -> consumidores. Usar o manual para semantica; F-5EM
   apenas para arquitetura de atualizacao, apresentacao e reconhecimento.
2. Obter fontes independentes ou modelo de sistemas AMX sustentado por dados
   para NL, NH e TGT compensada. Dois motores do F-5 nao representam os dois
   eixos do Spey; RPM/TIT genericos nao podem ser simplesmente renomeados.
3. Definir o significado do sinotico com fonte legivel ou nova decisao de projeto.
   Sem essa definicao, manter o contorno neutro, sem estados funcionais inventados.
4. Priorizar detectores de motor/oleo, eletrica, hidraulica, canopy e combustivel.
   Planejar separadamente os demais dos 15 grupos, mantendo causas e severidades.
5. Testar fontes ausentes/invalidas, limites por regime, causas simultaneas,
   ACK, perda/retorno de energia e igualdade entre principal, central e dividido.

Aceite para 7: NL/NH/TGT e monitoramento essencial possuem fontes/modelos
documentados e testados; sinotico definido e coerente; nenhuma falsa normalidade.
Publicar cobertura dos 15 grupos e lacunas restantes. Se faltarem dados para
validar um canal essencial, manter `---` e nota abaixo da meta, sem fabricar curvas.

## R08 - Hidraulica

1. Levantar dados de pressao/tempo, bombas, reservatorios, consumo por atuador,
   acumuladores e falhas. 207 bar nominal, 93 bar de baixa e 105 graus C de
   sobretemperatura, isoladamente, nao definem um modelo dinamico.
2. Definir modelo independente dos dois circuitos, com transicao de pressao,
   perda e recuperacao. Distinguir pressao modelada de fonte nativa real.
3. Definir o contrato com os mecanismos depois de R02. Indicar pressao nao
   comprova que o circuito alimenta um atuador; nao alterar o SFM implicitamente.
4. Cobrir falha de um circuito, perda total, recuperacao, demanda e dados
   invalidos. So incluir temperatura, vazamento ou acumuladores com fundamento.

Aceite para 7, com a autorizacao posterior: dinamica de projeto documentada,
circuitos independentes, negativos, consumo integrado e recuperacao observados
no DCS, com repeticao. A nota nao certifica fidelidade ao AMX; sem consumo
comprovado ou fonte valida, o criterio permanece aberto.

### Modelo de projeto AMXDENIS_PROJECT_HYD_1

O usuario aceitou hipoteses identificadas. A implementacao em
[hydraulics.lua](../../Avionics/AMXDENIS/Scripts/Host/hydraulics.lua) integra
pressao, nao uma simulacao volumetrica completa. Dois estados independentes,
sem fluxo entre circuitos; nenhum comando de atuacao, escrita de argumento ou
forca externa. `CALIBRATED=0` e `CONSUMERS_COMPLETE=0` permanecem publicados.

| Parametro | Valor | Origem/limite |
| --- | --- | --- |
| Pressao nominal e baixa | 207 bar / <=93 bar | Manual AMX-T; nao fornece curvas dinamicas |
| Fracao de bomba | clamp((RPM generico - 53)/7, 0, 1) | Escolha de projeto, nao NH real |
| Constante de carga | 2,5 s | Escolha de projeto |
| Constante de descarga da reserva | 40 s | Escolha de projeto; nao volume de acumulador real |
| Constante de perda em falha | 1,5 s | Falha modelada; nao dano nativo do DCS |
| Demanda do circuito 1 | 18 bar por transicao completa do indicador de trem; 12 bar por curso de flaps | Escolha de projeto; trem usa indicador de fim de curso, nao sensor continuo |
| Demanda do circuito 2 | 8 bar por curso de aerofreio | Escolha de projeto, nao distribuicao real certificada |

Com fracao de bomba `u`, taxa de carga `a=u/2,5`, taxa de descarga
`b=(1-u)/40` (ou `1/1,5` em falha, bomba desligada) e demanda `q` calculada
da variacao absoluta da posicao observada por segundo, a regra e
`dP/dt = a*(207-P) - b*P - q`. Integracao exponencial exata por intervalo para
entradas constantes, limitada a 0..207 bar; atualizacao nominal de 0,1 s.
Nao ha consumo por mero pedido de comando ou por atuador parado.

Estado inicial frio e zero; inicio quente com motor acima de 53 RPM generico
assume reserva carregada. Fonte de RPM/consumidor ausente, nao finita ou fora
da faixa invalida o circuito afetado. Tempo negativo ou salto >1 s invalida a
observacao e congela o estado interno; nao inventa consumo durante a lacuna.
Na recuperacao, a referencia do consumidor e reestabelecida sem carga ficticia.
Temperatura, reservatorio/volume, prioridade, vazamentos independentes e comandos
de voo nao foram implementados nem declarados completos.

As [evidencias CA/CB](Evidence/Operational-REV07/hydraulic-dynamics-results.json)
registram carga, falhas isoladas/total e recuperacoes no DCS; CB confirmou
descarga e desligamento. CA aprovou 9/10 etapas executadas; CB 12/14. Ambos
reprovados no conjunto: aerofreio nativo permaneceu zero por tecla e comando
direto, impedindo provar carga no circuito 2. Os negativos e a ausencia de
movimento permanecem na evidencia. A bancada exercita demanda e invalidade,
mas nao substitui o consumidor nativo. R08 reavaliado em 6/10, meta 7 aberta.

## R09 - Estabilidade

1. Classificar erros por candidato, fase e gravidade; separar falhas do AMX,
   recursos ausentes e problemas de outros modulos. Investigar o modelo de dano
   sem presumir que explique todos os defeitos.
2. Executar duas sessoes de pelo menos 45 minutos no candidato final: partida
   fria e quente, voo, trocas de pagina, entradas e ciclos de energia aplicaveis.
3. Monitorar crashes, travamentos, callbacks, perda de telemetria, tempo de quadro
   e memoria com cenario comparavel. Definir antes os limites de aborto/performance;
   nao atribuir a causa a GPU/driver sem evidencia.
4. Conferir encerramento, processos, credenciais temporarias e hashes dos
   recursos protegidos, preservando mudancas posteriores feitas pelo usuario.

Aceite para 7: as duas janelas e R06 concluidos sem falha critica atribuivel ao
candidato; erros restantes classificados, impacto documentado e nenhum bloqueio
de seguranca/integridade aberto. 45 minutos e criterio proposto, nao teste ja feito.

## R10 - Instalacao

1. Preparar pacote com manifesto, versao, dependencias, escopo AMXT_M dianteiro
   e limitacoes visiveis. Conferir permissao de distribuicao por componente;
   autorizacao local nao equivale a autorizacao de release publica.
2. Ensaiar instalar, atualizar e remover em um perfil descartavel limpo. Incluir
   backup e dry-run; rollback restaura apenas arquivos ainda correspondentes
   aos hashes registrados, nunca sobre mudancas posteriores do usuario.
3. Tratar explicitamente a guarda atual que limita o cockpit a perfis privados.
   Nao remove-la silenciosamente para instalar no perfil normal.
4. Depois de R01-R09 e do aceite do usuario, instalar no perfil normal sem
   sobrescrever opcoes/input/Export alheios e repetir smoke, entradas e voo.

Aceite para 7: instalacao/atualizacao/remocao repetiveis, rollback comprovado e
funcionamento no perfil normal autorizado. Sem esse teste, pacote apenas preparado
nao recebe 7. Limites de visores/texturas/VR continuam declarados.

## R11 - Sistemas avancados

Estes sistemas estavam fora da aprovacao operacional anterior. O plano os
inclui por estarem abaixo de 7, mas sua implementacao exige escopo e autorizacao
proprios. Nao copiar binarios, sensores ou comportamento do F-5 para simular AMX.

| Ordem | Sistema | Entrega planejada | Prova minima para o subitem |
| --- | --- | --- | --- |
| 1 | Radio RX/TX | Frequencia/modulacao, selecao, energia e PTT ligados ao radio nativo | Transmissao e recepcao verificadas; silencioso sem energia; editar COM nao basta |
| 2 | RWR | Receptor nativo, identificacao e apresentacao coerentes | Cenarios conhecidos com e sem emissor, mudanca de estado e perda de energia |
| 3 | Radar | Deteccao, modos, selecao e acompanhamento sustentados pelo backend autorizado | Contato real em cenario controlado e negativo sem contato; sem dados de verdade da missao injetados |
| 4 | FLIR | Sensor/render target, comandos e display ligados de ponta a ponta | Video com detalhe, slew oposto, apagamento e retorno; tela preta nao e video aprovado |
| 5 | HMD | Referencial de cabeca, simbologia e selecao suportados | Alinhamento e movimento coerentes; avaliacao com operador/head tracking quando necessaria |
| 6 | Disparo | Comandos, selecao e segurancas integrados ao sistema de armas nativo | Missao DCS isolada e autorizada, resposta nativa e negativos de seguranca; inventario nao basta |
| 7 | Alijamento | Selecao e remocao nativa das estacoes previstas | Inventario e estado externo coerentes, isolamentos e nenhuma remocao de estacao nao selecionada |

Aceite para 7 da area: todos os sete subitens do escopo acima implementados e
testados, sem aprovar o conjunto por um unico sensor. Sistemas indisponiveis por
API, dados ou direitos ficam bloqueados; qualquer reducao de escopo exige aceite.
Depois de cada integracao, repetir as regressoes afetadas, R09 e o pacote R10.

## Evidencias e controle

- Reutilizar testes e helpers existentes. Rodar primeiro o teste mais restrito
  capaz de refutar a mudanca; depois as verificacoes exigidas da bancada.
- Cada ensaio registra candidato/BuildId, insumos, cenario, origem da entrada,
  antes/depois, criterio, resultado, arquivos e hashes. Wait por tempo, READY,
  comando aceito ou finalizacao integra nao equivalem a funcao aprovada.
- Manter falhas e tentativas rejeitadas; comparar ROIs fixas quando houver
  prova visual. Nao editar evidencia antiga para representar um novo resultado.
- Candidatos/run roots sao sempre novos; manter originais, EDMs, SFM, projeto
  F-5 e perfil normal protegidos. Mudancas de escopo precisam de nova autorizacao.
- Atualizar neste quadro estado, evidencia e nota proposta ao fechar cada marco.
  Usar Planejado, Em andamento, Bloqueado, Em validacao ou Aprovado no escopo.
  Aprovacao so apos satisfazer os criterios, nunca por quantidade de testes.

Responsabilidade tecnica: implementacao, testes de bancada, diagnostico e
documentacao pelo assistente. Responsabilidade compartilhada: decidir escopo,
aceitar mudancas de modelo e operacao normal. Responsabilidade do operador:
movimentar hardware e confirmar o uso fisico; o assistente pode instrumentar,
observar e correlacionar esses testes, mas nao substituir o movimento fisico.

## Primeiro marco

R01 concluido com duas montagens reprodutiveis e as guardas intactas. R03 avanca
na cobertura funcional independente dos mecanismos; os tres subconjuntos
concluidos nao aprovam o catalogo inteiro. R02 precisa de evidencia nova sobre
o controlador de atuacao antes de outra experiencia. As demais notas nao foram
promovidas.