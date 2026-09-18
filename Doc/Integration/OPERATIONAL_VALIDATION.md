# Campanha operacional AMXT_M

## Escopo autorizado

Comandos reais, partida/desligamento, voo completo, instrumentos em movimento,
sistemas ja integrados e estabilidade. Manual AMX-T local e F-5EM usados como
referencias; o F-5EM nao e autoridade para a fisica do AMX. Exterior, SFM,
descritores, perfis normais e fontes permanecem protegidos. Radio nativo,
radar/RWR/FLIR/HMD, disparo, VR e novas geometrias nao foram incluidos.

Na continuidade de 18/09, o usuario autorizou comparar mecanimacoes/descritores
somente em candidatos experimentais, preservando os arquivos originais, EDMs
e SFM. Esses candidatos recebem `DescriptorProbe` e `ExperimentalOnly`, com
aceite explicito na preparacao. Nenhuma dessas experiencias foi promovida.

Estado inicial: branch `Sub-Dev`, HEAD `fab5757`, sem alteracoes pendentes.
Checkpoint: `Backups/Operational-20260918T024848Z`, com 511 arquivos e a prova
reversivel inicial dos IDs explicitamente identificada. Nenhum commit/push novo.

## Progresso e criterios

| Etapa | Estado | Criterio de conclusao |
| --- | --- | --- |
| Teclado | BU/BV e BX/BY: 282 transicoes funcionais, 54 acoes em contextos selecionados; basico BN/BO preservado | Cobrir as 51 acoes fora das suites e demais contextos; nota 5/10, sem aprovar atuacao de mecanismos por recebimento |
| Mouse | AQ confirmou COM1/COM2 em prova experimental; controle AR nao concluiu resultado equivalente | Prova OBB de COM1 retirada; repetir no baseline em vistas controladas e cobrir seletores/knobs e demais zonas |
| X56 fisico | Ambos detectados e lidos por WinMM: manche 5 eixos/17 botoes, manete 6 eixos/32 botoes expostos | WinMM limita a 32 botoes; curso completo, todos os botoes e mapeamento nativo continuam sem aprovacao fisica |
| Partida/desligamento | Confirmados por comandos diagnosticos em AF, missao corrigida | Negativos sem energia/combustivel; RPM nativo de marcha lenta; parada com RPM/fluxo zero. Nao certifica NH/TGT ou HOTAS |
| Voo completo | Nao aprovado; V sem decolagem concluida; AY/AZ partiram no ar e nao completaram a janela de teste do trem | Requer taxi, decolagem, subida, cruzeiro/curvas, descida e pouso; AirHot nao substitui decolagem |
| Instrumentos | Comparados em movimento; sem calibracao fisica aprovada | IAS/proa concordam entre APIs; altitude e outras diferencas permanecem documentadas |
| Sistemas | Eletrica/BINGO e HYD modelado confirmados anteriormente; AN/AP/AV/BA nao resolveram flaps/canopy | Trem segue sem aprovacao; comandos/estados nao equivalem a movimento. Causa da atuacao nativa ainda nao estabelecida |
| Estabilidade | Integridade de fechamento confirmada; estabilidade de voo prolongado nao aprovada | Repeticoes e janela prolongada com erros classificados; sem alegar logs limpos |
| EICAS AMX pelas referencias visuais | Layout e barras HYD 1/2 implementados; AI/AJ/AK/AM testados | Fontes NL/NH/TGT, sinotico e detectores ausentes ainda nao confirmados; hidraulica continua modelo simplificado, sem aprovacao operacional completa |

O usuario informou estar indisponivel e autorizou continuidade autonoma.
Testes automatizados de voo/sistemas serao rotulados como tal; nao certificam
HOTAS fisico. Nenhuma pendencia sera convertida em PASS para encerrar a campanha.

## R03: Navegacao E Soltura

O [subitem basico](Evidence/Operational-REV07/keyboard-core-results.json) foi
concluido e sincronizado em `ecdee0e`: 93 transicoes de 13 controles em BN/BO.
O [subitem de navegacao](Evidence/Operational-REV07/keyboard-navigation-results.json)
acrescenta 92 casos: modos, dez digitos, edicao BINGO valida/invalida, CLR,
ENTR e oito selecoes de pagina por MFD. A origem e Windows SendInput, sem
comandos diagnosticos de cockpit durante as suites.

BQ chegou ao BINGO 675 correto, mas a ultima entrada permaneceu em 1 e o
criterio de soltura falhou. O helper passou a liberar a tecla principal,
aguardar telemetria nova e so entao liberar os modificadores, com limpeza
garantida no erro. A causa unica da omissao antiga nao foi estabelecida.
BR/BS/BT foram abortados pela guarda de foco; o usuario confirmou que fechou,
minimizou ou trocou de janela durante esse grupo de testes. Permanecem
incompletos, sem atribuir autoria a cada evento. O gerador tambem passou a
reservar Alt+F4 em todos os bancos, sem alterar atalhos pessoais.

BU/BV usaram a mesma versao final e mapa privado, em GroundCold com 1500 kg:
92 casos Navigation e 31 Core por sessao, todos aprovados. Cada transicao
exige efeito no produtor e tres amostras estaveis; botoes exigem pressao e
soltura. A sequencia diagnostica Export permaneceu zero. Total: 246 transicoes,
50 acoes distintas em contextos selecionados, nao cobertura integral de 105.
Os hashes das etapas e os resultados anteriores estao no resumo de evidencia.

Ambas finalizaram com integridade verdadeira; zero erros/rejeicoes do
observador, mas 159 registros ERROR/ERROR_ONCE do DCS por sessao. A CI completa
BW passou e reconstruiu o mesmo BuildId
`5A236FF163314E4951959DB9BB1841866CF497A732312CE3AE00C80B515C398B`.
R03 permanece 5/10. Nao ha aprovacao nova de mecanismo, voo completo, mouse,
X56 fisico ou capacidades de sensores/armamento por abrir suas paginas.

O subitem acima foi sincronizado em `80eb2e8`. A
[continuacao de layout](Evidence/Operational-REV07/keyboard-layout-results.json)
testou FULL e troca entre telas nos dois MFDs, incluindo retorno e retencao das
selecoes ao desligar/religar cada visor e o master. BX/BY passaram em 18 etapas
cada, com os dez estados de layout esperados, efeito funcional e soltura.
Sao 36 transicoes adicionais, quatro acoes novas e 54 acoes distintas nas tres
suites. Os dois runs foram finalizados com integridade verdadeira; zero erros
ou rejeicoes do observador e 159 ERROR/ERROR_ONCE do DCS em cada um.
As 257 guardas de integracao passaram; a CI de runtime BW continua historica,
pois este subitem so ampliou o teste. Estado de layout nao comprova pixels.

## Primeiras evidencias

Runs `Native-REV07-Operational-Q` e `Native-REV07-Operational-R` na area local
de integracao. Q recebeu tecla Windows Ctrl+Shift+F4 como comando 3746: MFD1
passou a 0, MFD2 permaneceu 1, erro 0 e sequencia diagnostica Export 0.
F3 restaurou o MFD; F7 produziu pressao/soltura 3716 e pagina COM1.

O roteador anterior gerava 4001+ e eixos 5000+; a prova usa 3701-3805 e eixos
abaixo de 4000. O contador de recepcao e separado do contador de comandos aceitos.
A bancada agora rejeita catalogos fora dessa faixa exercitada.

As primeiras tentativas de mouse foram bloqueadas por cursor deslocado, portanto
nao contam como falha de cockpit. A prova de reativacao moveu o cursor de
904,635 para 895,641 apesar de a janela ja estar em foco. O helper evita
reativacao redundante e usa SetCursorPos, mantendo identidade, foco, coordenada
exata e telemetria recente como guardas. R confirmou COM1 e COM2 por clique real,
com pressao/soltura recebidas e sem comando de instrumento pelo Export.
Uma prova `use_OBB=false` somente em COM1 foi retirada: COM2 funcionou com OBB
original. A configuracao final nao deve depender dessa mudanca experimental.

## Fechamento Dos Ensaios Executados

Dezesseis runs preservados, Q ate AF, com nomes intermediarios no
[indice de evidencias](Evidence/Operational-REV07/index.json). O indice inicial
de treze runs foi mantido; o
[complemento da missao corrigida](Evidence/Operational-REV07/mission-contract-followup.json)
contem AD/AE/AF e a CI mais recente. Todos os processos privados desses ensaios
foram encerrados e os arquivos temporarios de autenticacao removidos.

O preparador substituia `groundControl` e removia `roles`, causando
`COMPILE MISSION ... pairs ... nil`. AD provou que restaurar somente as tabelas
vazias de gatilhos nao bastava. Preservar `groundControl.roles` eliminou esse
erro em AE e AF. A guarda passou a examinar falhas nativas **antes** de aceitar
READY. Os resultados antigos nao foram apagados: Q/AC e anteriores ainda
exigem essa ressalva de contrato de missao, mesmo quando registraram respostas.

AF repetiu com a missao corrigida: partida sem energia bloqueada; partida sem
combustivel bloqueada; partida autorizada ate RPM generico aproximadamente 60;
alimentacao por apenas um gerador; perda de todas as fontes e recuperacao.
BINGO 670 ativou com aproximadamente 600 kg nativos; ACK manteve a causa;
energia ausente invalidou a indicacao, e o retorno a recuperou. Limite 500
limpou a causa com 581.438 kg observados. Desligamento terminou com RPM e fluxo
zero, barramento e dois MFDs desligados. Sao entradas diagnosticas explicitas,
nao operacao fisica de teclado/mouse/HOTAS nem calibracao do Spey.

Trem, flaps e canopy continuam **nao aprovados** em AE/AF. Houve pedidos aceitos,
mas nao as posicoes esperadas. A tecla G em AB tambem nao comprovou atuacao;
envio pelo Windows sem leitura de transicao nao prova que o DCS recebeu G.
Nao atribuir a falha a um descritor, EDM ou SFM sem prova adicional. O argumento
interno 181 do canopy nao tem gauge no painel atual; essa observacao e separada
da falta de movimento externo. Nenhum atuador Lua externo foi inventado.

Z mediu os eixos no solo: comando de pitch alterou `getStickRollPosition` e
comando de roll alterou `getStickPitchPosition`; leme respondeu separadamente.
Preservadas leituras brutas e validade, sem renomear APIs nem afirmar unidades.
O isolamento de X56 ocorre somente dentro dos processos privados RunwayHot/
AirHot, sem salvar ajustes pessoais, seguido de neutralizacao conjunta. Isso
nao constitui teste fisico de X56. A janela curta de AA nao aprova um circuito
completo ou estabilidade prolongada.

[Comparacao de instrumentos](Evidence/Operational-REV07/instrument-comparison.json):
IAS e proa apresentaram diferencas maximas de aproximadamente 0.0000005 kt e
0.000011 grau nos cinco AirHot iniciais. Altitude barometrica versus altitude
geometrica, radar versus AGL vertical e dados de atitude/variometro nao sao
grandezas ou amostras necessariamente equivalentes. Diferencas registradas
nao foram zeradas no observador nem promovidas a calibracao independente.

CI final: 19 scripts PowerShell; 43 guardas de integracao; 36 de texturas;
27 de viewer; 12 de ancoras; 8+14 testes Python; 353 do observador; 219 arquivos
Lua; 527 de registro; 1714 de runtime; 22016 verificacoes de indicadores em
69 paginas. Candidato W: BuildId
`E90C4E097D4F0FF44C87AD5FC39EBFC7B5D1EB25973B529092CD5E320C9FF6B2`.
Essa bancada nao concede aprovacao nativa global.

Preservacao final: 84 arquivos originais AMXDENIS e 93 arquivos protegidos do
ambiente atual sem mudanca contra os respectivos baselines. Na origem, a
comparacao de 2243 arquivos com o snapshot antigo encontrou uma diferenca em
`Tools/Test-DisplayM1.ps1`: guarda adicional contra aeronave placeholder,
timestamp anterior ao checkpoint operacional. Autoria nao estabelecida; versao
atual preservada, sem rollback. Nao afirmar que toda a origem coincide com o
snapshot. Logs mantem erros de modelo de dano, recursos e outras categorias;
finalizacao integra nao significa log sem erros. Nenhum commit/push novo.

## Continuidade AN A BA

O [resumo verificavel](Evidence/Operational-REV07/mechanisms-followup.json)
registra 12 runs privados e 85 relatorios, com hashes, estados brutos resumidos
e finalizacoes. Os arquivos completos permanecem em
`%LOCALAPPDATA%/AMXDENIS-Integration/Runs/Native-REV07-*`. Os 84 arquivos
originais foram conferidos sem alteracao. Todas as finalizacoes desta
continuidade passaram; credenciais temporarias foram removidas. Nenhum perfil
normal foi instalado, nenhum commit/push foi feito e logs nao sao limpos.

Resultados que mudam o diagnostico:

- AN: IDs resolvidos do DCS coincidem com o adaptador, trem 430/431, flaps
	145/146, canopy 71. Flaps pelo roteador e por `LoSetCommand` chegaram a
	`status=2`, mas posicao e leitura do cockpit permaneceram zero. A rolagem
	inicial de GroundHot e uma ressalva; nao foi contada como taxi aprovado.
- AO/AP: partida fria removeu a rolagem como variavel. Canopy permaneceu em
	aproximadamente 0,9, inclusive no argumento externo 38. Comparacoes de
	payload 0/1 e tecla nativa nao demonstraram o curso esperado. Em AP, flaps
	tambem permaneceram em zero com motor em marcha lenta.
- AQ: COM1 sem OBB e COM2 com OBB receberam cliques Windows, dois eventos
	por clique, paginas 1/2 e sequencia diagnostica inalterada. AR, com OBB
	original, teve bloqueios por cursor movido e um clique enviado sem
	recebimento. Nao foi isolada causalidade de OBB; a alteracao foi retirada.
	O teste de outro backend de movimento do mouse tambem foi retirado.
- AT: inventario passivo de 50 getters diretamente presentes na tabela de
	sensores do cockpit. Inclui RPM/temperatura genericos, canopy e trem;
	nao revelou NL/NH/TGT independentes. Nao e inventario de APIs ocultas ou
	herdadas. Getters desconhecidos nao sao executados para enumerar nomes.
- AU: primeira experiencia sem `mechanimations` falhou no loader porque
	`pcall` nao existe no ambiente de declaracao nativo. O placeholder foi
	recusado. O loader e a fixture foram corrigidos; o resultado AU foi mantido.
- AV: retirar a tabela de mecanimacoes carregou corretamente, mas nao resolveu
	canopy/flaps. AW: gauge nativo interno 181 refletiu 0,9, sem destravar a
	canopy; a prova de gauge foi retirada. BA: adicionar somente
	`Door1={DuplicateOf="Door0"}`, conforme a convencao do preset nativo
	`Default`, tambem nao resolveu a canopy. Tempos originais e SFM preservados.
- AY: a janela de velocidade se perdeu antes do pedido de trem e o teste foi
	abortado. AZ: a sequencia continua expirou sem atingir a condicao; ultimo
	estado em 142,790 s tinha IAS 133,534 m/s, AGL 710,809 m, RPM 60 e descida
	proxima de 20 m/s. Nenhum pedido de trem foi enviado nesses dois runs.
	Solicitar retencao de altitude nao comprovou sua atuacao; nao houve pouso.

A origem antiga anima canopy, trem e flaps por Lua. Essa aparencia de movimento
nao comprova atuacao fisica do SFM e os escritores externos nao foram
reimportados para esconder os resultados negativos. O erro nativo de modelo
de dano permanece; a relacao causal dele com os mecanismos nao foi provada.

X56: [Read-Hotas.ps1](../../Tools/Native/Read-Hotas.ps1) consulta WinMM sem
enviar entradas, calibrar ou salvar configuracoes. VID 0738, PID 2221 e A221
identificam manche e manete, ambos com retorno zero (leitura bem-sucedida).
As leituras sao posicoes atuais, nao um exercicio completo. No manete WinMM
nao anuncia POV; seu campo bruto zero nao deve ser contado como hat pressionado.
Os ensaios AirHot isolam hardware somente no processo privado; nao validam X56.

Candidato normal reconstruido: `AMXT_M-REV07-BB-VerifiedBaseline`, BuildId
`777D2B2B3C7DDFCC577A3E16DC597EC6FAD245D73A3F923E0ABCEC99321639DF`, igual ao
runtime observado em AT. Adiciona apenas o inventario passivo de capacidades
ao runtime anterior; nao altera a apresentacao aprovada nem completa sensores.
`DescriptorProbe=none`, `ExperimentalOnly=false`. CI: 20 scripts PowerShell,
43/36/27/12 guardas, 8+15 Python, 473 observador, 221 Lua, 529 registro,
1793 runtime e 22743 indicadores/69 paginas. Testes de bancada nao aprovam voo.

## Referencias locais

AMX-T-1, 15/05/1994: paginas PDF 300 (partida), 310 (apos partida BT),
316-317 (taxi/decolagem BT), 324-325 (pouso), 329 (desligamento).
O cache OCR e apenas localizador; valores e aplicabilidade precisam ser
conferidos no PDF original antes de virar criterio numerico. Nenhum trecho
longo do manual sera redistribuido no repositorio.

## Etapa final: proposta e desenvolvimento do EICAS AMX

Pedido adicional de 18/09/2026, a executar depois da campanha operacional acima.
Trabalhar somente no projeto AMX. O projeto F-5 nao sera modificado: seu EICAS
serve exclusivamente como referencia tecnica. As tres fotografias anexadas pelo
usuario e o exemplo adicional da **imagem 4** sao referencias visuais, nao prova
de escalas, limites ou logica de deteccao. A geometria da imagem 4 tem prioridade
para o desenho do EICAS; seus textos podem estar incorretos. Nao ha afirmacao
de que os anexos foram salvos no repositorio.

### Aprovacao obrigatoria antes da implementacao

Apresentar ao usuario um desenho do layout no display principal e no central
menor, uma tabela de fontes dos parametros/condicoes e as duvidas pendentes.
Identificar para cada dado a referencia documental, variante aplicavel, unidade,
escala/limite confirmado, produtor real no mod e disponibilidade/validade.
O desenho e o mapeamento devem ser aprovados antes de implementar esta etapa.
A autorizacao de continuidade da campanha anterior nao substitui esse aceite.

### Layout solicitado

1. Tres instrumentos circulares alinhados no topo, para grandezas do unico
	 motor. Confirmar no manual NL (%), NH (%) e TGT (graus C), incluindo ordem,
	 escalas e limites. RPM generico nao sera relabelado como NL ou NH; temperatura
	 generica nao sera apresentada como TGT sem fonte correspondente.
2. Duas barras verticais a esquerda, como nas fotos. Identificar seus parametros
	 em documentacao ou imagem legivel; nao presumir oleo, hidraulico ou combustivel.
3. Reproduzir o sinotico central somente depois de confirmar o que representa.
4. Colocar o bloco compacto de mensagens na lateral direita. Nao copiar a grade
	 inferior de alertas do F-5.
5. Reproduzir o conjunto no display central menor com tamanho e espacamento
	 adaptados, consumindo os mesmos dados, validade e estados do display principal.
6. Ambos os displays laterais podem ser divididos em tres areas no padrao
	 do F-5: superior, inferior esquerda e inferior direita; preservar FULL.
	 O central segue a referencia EFI do F-5: instrumentos de voo acima, area
	 de motor abaixo e avisos laterais; adaptar a area de motor ao EICAS AMX,
	 sem afirmar que o novo desenho ja esta implementado. A imagem 3 mostra
	 a ordem inversa (EICAS acima): as duas alternativas ficam para aprovacao
	 no desenho, sem presumir equivalencia entre fotografia e codigo do F-5.

Layout posteriormente aprovado e subconjunto implementado:
[EICAS_PROPOSAL.md](EICAS_PROPOSAL.md). O aceite nao confirma a interpretacao
dos pequenos rotulos das fotos nem autoriza inventar sensores ou limites.
Sinotico: somente o contorno visual do recorte fornecido, sem funcao atribuida.
Nenhum novo detector fisico foi inventado para preencher os quinze grupos.

### Proposta simplificada de 15 mensagens do mod

Esta organizacao foi proposta para o mod; **nao e uma lista oficial do AMX**.
Uma posicao na proposta nao implica que exista sensor ou detector implementado.

| Posicao | Mensagem | Condicao proposta |
| --- | --- | --- |
| 01 | ENG | Alerta do motor |
| 02 | OIL | Alerta do sistema de oleo |
| 03 | CANOPY | Condicao anormal de fechamento ou travamento |
| 04 | ELEC | Geracao, retificacao ou bateria |
| 05 | HYD | Alerta hidraulico |
| 06 | AVIONICS | Avionicos, incluindo dados do ar |
| 07 | FUEL BAL | Desequilibrio de combustivel |
| 08 | FUEL XFER | Transferencia de combustivel |
| 09 | FUEL LO | Combustivel baixo |
| 10 | FUEL PRESS | Pressao de alimentacao de combustivel |
| 11 | EXT TANKS | Condicao dos tanques externos, quando aplicavel |
| 12 | OXYGEN | Fornecimento ou fluxo de oxigenio |
| 13 | T/O CONFIG | Configuracao inadequada para decolagem |
| 14 | SEAT PIN | Pino de seguranca do assento, se monitorado |
| 15 | ANTI-ICE | Indicacao do sistema antigelo, nao necessariamente falha |

### Agrupamento e dados

- ELEC reune geradores, TRU e temperatura da bateria, conforme as fontes
	realmente disponiveis. AVIONICS pode incluir DADC.
- HYD preserva a identificacao de cada circuito nos detalhes. OXYGEN agrupa
	falhas de fornecimento/fluxo; autoteste nao e falha.
- DVR e andamento de testes ficam em area de status ou pagina propria,
	fora das 15 posicoes propostas.
- Nao eliminar circuitos nem tanques por a aeronave possuir apenas um motor.
- Cada aviso agrupado deve manter as origens e a maior severidade ativa;
	nao pode desaparecer enquanto alguma condicao do grupo continuar ativa.
- Usar somente parametros e condicoes realmente disponiveis. Nao inventar
	leituras, limites ou deteccoes para preencher a tela. Distinguir dados
	indisponiveis de valores zero ou de um sistema saudavel.
- Distinguir emergencia, cautela e indicacao de estado. A classificacao depende
	da condicao, nao apenas do nome da mensagem. ANTI-ICE ligado e autoteste de
	oxigenio nao devem ser classificados automaticamente como falha.

Permanecem abertas para a proposta: fontes reais de NL/NH/TGT; ordem, escalas
e limites dos circulares; identidade das duas barras; significado do sinotico;
detector, origem e severidade de cada mensagem. Essas lacunas serao apresentadas
para decisao antes de qualquer implementacao visual ou funcional deste EICAS.

## Fila Solicitada Depois Do EICAS

Pedido atualizado: apos concluir a etapa EICAS aprovada, retomar os itens abaixo.
Esta fila nao autoriza pular o aceite do desenho nem declara aprovados os
recursos que o usuario identificou como fora da aprovacao atual.

| Item | Estado verificado / restricao | Proximo criterio |
| --- | --- | --- |
| Teclado | 105 acoes; layer Unit AMX. AJ confirmou OFF/ON do MFD, FULL/dividido, menus e selecao EICAS primaria/secundaria por teclas Windows. Nao ha aprovacao das 105 | Ampliar cobertura por funcoes, negativos e soltura; recepcao nao basta para aprovar atuacao |
| Cliques de mouse | 34 zonas; os positivos historicos R nao foram generalizados. Em AJ houve uma tentativa bloqueada antes do clique e duas enviadas sem recepcao COM1/COM2, OBB original | Nao aprovado no candidato atual; investigar captura/coordenadas/hit-test sem relaxar guardas ou inventar transicoes |
| HOTAS X56 | Detectado; isolado somente nos processos de voo automatizado, sem salvar ajustes pessoais | Operador deve mover eixos/botoes fisicos no DCS; automacao nao substitui este teste |
| Texturas | 102 arquivos conferidos; faltam `f18c_cpt-naces1`, `f18c_cpt-tex12`, `mb339_glass` | Obter arquivos corretos e autorizados; nao criar aliases ou substitutos para esconder ausencia |
| Radio nativo | Paginas COM e edicao nao comprovam RX/TX | Etapa propria de integracao e teste, com backend/licenca e transmissao/recepcao reais |
| Radar/RWR/FLIR/HMD | Desativados ou indisponiveis no candidato; sem dados ficticios | Integracao por sensor e testes independentes, fora da aprovacao atual |
| Disparo integrado | SMS le inventario de sete estacoes; sem autoridade de disparo/alijamento integrado | Etapa propria de comandos e resultado nativo; nao concluir pela leitura de inventario |
| Bancada/preservacao | CI nao substitui testes funcionais; arquivos originais do AMX protegidos | Reexecutar gates a cada alteracao, conferir hashes e registrar bloqueios sem PASS global |

Radio, sensores e emprego integrado de armamento ficam registrados como etapas
futuras solicitadas, nao como capacidade atual nem autorizacao para contornar
licencas, modificar F-5, exterior, descritores ou SFM. Dependencias de fontes,
hardware e autorizacoes nativas continuam obrigatorias.

## EICAS: Fechamento Do Subconjunto Aprovado

Candidato final `AMXT_M-REV07-EICAS-AK-Bingo`, BuildId
`7FA38051ECD75DFA7D7349C1D843B68EBF61863EB6CDC0209C12048679881FAC`, somente
em perfis privados. [Evidencias](Evidence/EICAS-REV07/index.json) preservam AI
(recorte inicial do central), AJ (enquadramento, agrupamento e navegacao) e AK
(BINGO tambem no central). Fonte unica dos quinze grupos; so CANOPY/ELEC/HYD
tem causas parciais existentes. Sem fonte, manter indisponivel. HYD e geracao
sao modelos simplificados, nao calibracao dos sistemas reais do AMX.

Confirmados: ACK sem limpar causa; origem GEN 2 mantida apos recuperar GEN 1;
ultima origem recuperada limpa ELEC; perda de dados retida com `?`; tela apaga
e retorna nos interiores medidos. BINGO 670 com 620 kg nativos aparece no
principal e central sem fingir o sensor FUEL LO. Motor e fluxo nao foram
injetados. NL/NH/TGT permanecem invalidos, sem escala ou ponteiro inventado.

CI final: 19 PS, 43/36/27/12 guardas, 8+14 Python, 353 observador, 221 Lua,
527 registro, 1776 runtime, 22584 indicadores/69 paginas. 84 originais e
93 arquivos protegidos conferidos; F-5 nao editado; tres sessoes encerradas
com integridade e autenticacao temporaria removida. Nenhum commit/push.
Texto nas areas inferiores e pequeno e uma vista esquerda sofre oclusao
fisica pelo ICP; nao aprovar legibilidade integral/eyebox por estes testes.