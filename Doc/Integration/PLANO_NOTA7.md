# AMXT_M REV07: plano para levar todas as areas a 7/10

Data: 19/09/2026. Escopo: AMXT_M, posto dianteiro, cockpit REV07.
Referencia versionada: commit `d39a512` na branch `Sub-Dev`.
Candidato de acompanhamento: `AMXT_M-REV07-CL-CommandNames`, BuildId
`445CADAD2E5B7DD8BCA26EFB0B58AC5692A12E21B9524D107835C7B391D9B571`.

Este documento e um plano, nao um resultado. Nenhuma nota abaixo sobe por
constar aqui. Cada area so muda quando existir efeito medido dentro do DCS,
repetido, com evidencia arquivada e commit proprio.

Escala usada: 1 = sem funcao validada; 10 = completo e validado de forma
repetivel no escopo previsto. O marco 7 significa funcao util e reproduzivel
no escopo do AMXT_M, e nao modulo completo, release publica ou aprovacao em VR.

## 1. Situacao atual

| Area | Nota | Falta para 7 |
| --- | ---: | --- |
| Texturas | 9 | ja acima da meta |
| Visores | 7 | ja na meta |
| Reconstrucao/build | 7 | ja na meta |
| Hidraulica | 6 | carga real de consumidor |
| Teclado | 5 | 51 das 105 acoes e area de trabalho estavel |
| Estabilidade | 5 | sessoes longas repetidas sem interrupcao |
| EICAS | 4 | fontes de NL/NH/TGT e detectores restantes |
| Mecanismos | 3 | capota, flapes, aerofreios e trem |
| Voo completo | 3 | taxi, decolagem, voo e pouso |
| Mouse | 3 | entrega de clique e 34 zonas |
| X56 | 3 | exercicio fisico do operador |
| Instalacao | 3 | autorizacao para o perfil normal |
| Sistemas avancados | 1 | escopo, dados e direitos por sistema |

Dez areas precisam de trabalho. Tres ja estao na meta e entram apenas como
regressao obrigatoria.

## 2. Fontes consultadas

Manuais da aeronave, em `D:/Desenvolvimento/manual amx`:

- `AMX-T-1-Flight-Manual-AMX-Two-Seater-Aircraft-15-May-1994.pdf`, que e a
  referencia primaria por ser biplace. Capitulo de motor com NL, NH e TGT
  (PDF 38-40, Fig 1-9), limites por regime (PDF 404, Fig 5-3), combustivel e
  BINGO (PDF 50-60), hidraulica dupla com 207 bar nominal, 93 bar baixo e
  105 C de sobretemperatura (PDF 66-70), painel de alarmes (PDF 155-159).
- `AMX-1-Flight-Manual-AMX-Series-Aircraft-01-Aug-1989.pdf` como apoio, com a
  ressalva ja registrada de que a associacao LP/HP aparece invertida nele.
- `HUD AMX.pdf` para simbologia.

Referencia de construcao de mods:

- `Beginners Guide to DCS World Aircraft Mods v0.5.1.pdf`. Pagina 49 confirma
  que a capota usa sempre o argumento de desenho 38 no modelo externo. Pagina
  52 registra conflito entre os argumentos 38 (angulo e visibilidade da capota),
  50 (assento e piloto) e 114 (cockpit externo). Pagina 48 lembra que um mod
  SFM pode estar ajustado em voo e ainda assim sem modelo de dano.

Biblioteca de referencia em `D:/Desenvolvimento/BACKUP`, registrada em
[permissoes](PERMISSIONS.json):

- `ex mods/Denis_community_AMX-main`: o AMX original. Verificado que **nao tem
  pasta `Cockpit/`** e **nao tem `AMXT_M.lua`**. O AMXT_M e o cockpit sao
  construcoes deste projeto, nao heranca do mod original.
- `ex mods/F-15E`, `ex mods/AV8BNA`, `ex mods/Hercules`: declaram `Door0` na
  mesma forma do AMX. Comparado e confirmado que a forma do AMX esta correta.
- `AVioesdll`: binarios de modulos para estudo. Conforme sua instrucao, o que
  for necessario dali e reproduzido escrevendo binario proprio.
- `controles HTML`: dumps historicos do X56. O identificador do dispositivo
  difere do X56 conectado hoje, entao servem como referencia, nao como prova.

## 3. Criterio de aceite comum

Vale para todos os pacotes. Um item so conta como concluido quando:

1. Existe efeito medido no DCS, com leitura antes e depois e transicao real.
   Recebimento de comando, contador de entrada ou tempo decorrido nao contam.
2. O efeito se repete em pelo menos duas sessoes independentes.
3. A sessao termina com integridade confirmada e sem erro do observador.
4. A evidencia bruta fica arquivada, inclusive as falhas.
5. Existe regressao offline que falharia se o defeito voltasse.
6. Ha commit com escopo proprio, sincronizado, com o hash informado.

## 4. Pacotes de trabalho

### P1. Mecanismos, de 3 para 7

Situacao: o freio de roda ja atua de forma reproduzivel. Capota, flapes e
aerofreios continuam imoveis. O trem nunca foi testado porque exige a aeronave
no ar.

O que ja foi eliminado como causa: identificadores errados, canal de comando
morto, defeito do produtor do cockpit, forma da chamada, e forma da declaracao
de mecanismo. A capota do AMX nao se move enquanto a de uma aeronave oficial se
move com o mesmo comando, o que aponta para o descritor ou o modelo do AMX.

Passos:

1. Referencia oficial com motor ligado, para julgar flapes e aerofreios. Sem
   isso nao se pode afirmar que estao defeituosos, porque com motor desligado a
   aeronave oficial tambem nao os move.
2. Teste do conflito documentado entre os argumentos 38, 50 e 114, indicado na
   pagina 52 do guia, em candidato separado.
3. Inspecao do `Shapes/AMX.edm` com o importador EDM disponivel em
   `BACKUP/Demais/DCS-EDM-Blender-Importer`, comparando as faixas de animacao
   dos argumentos 38, 9, 10 e 3 com um modelo cujo mecanismo funciona.
4. Fechar a questao do casco de colisao. O `AMX.lods` declara
   `collision_shell = AMX.edm`, mas o parser nao encontra celulas. Os testes de
   dano ja feitos removeram o erro de log sem restaurar movimento, entao o
   proximo passo e verificar se a ausencia de celulas impede o registro dos
   mecanismos, e nao apenas o dano.
5. Se o caminho de descritor se esgotar, avaliar binario proprio de modelo de
   voo, escrito do zero, estudando o comportamento observado nos modulos de
   referencia. Esta alternativa entra com custo e risco declarados, nunca como
   copia.

Aceite para 7: capota abre e fecha, flapes descem e sobem e aerofreios saem e
recolhem, com posicao medida, em duas sessoes. Trem comprovado em fixture aereo
ou declarado explicitamente fora do escopo desta nota.

Risco: se a causa estiver na geometria do EDM, a correcao exige autorizacao
para mexer no modelo, que hoje nao existe.

### P2. Voo completo, de 3 para 7

Situacao: a aeronave liga, estabiliza em marcha lenta, responde a manete e
desliga, tudo repetido. Nao houve taxi, decolagem, voo nem pouso.

Passos:

1. Taxi controlado com freio, com criterio de parada e limite de velocidade.
2. Decolagem usando os parametros do manual de 1994: AOA de decolagem,
   velocidade de rotacao e posicao de flape de manobra.
3. Subida, nivelamento e curva coordenada, com leitura de atitude e altitude.
4. Aproximacao e pouso, com toque e parada dentro da pista.
5. Repetir a sequencia completa em duas sessoes.

Aceite para 7: um ciclo de decolagem, circuito e pouso concluido duas vezes,
com telemetria arquivada.

Dependencia: flapes funcionando, portanto depende de P1.

### P3. Hidraulica, de 6 para 7

Situacao: a dinamica de projeto esta implementada, com pressurizacao, falha
isolada, falha total e recuperacao ja medidas. Falta carga real de consumidor,
porque os consumidores sao trem, flapes e aerofreios.

Passos:

1. Assim que P1 liberar um consumidor, medir a queda de pressao durante o
   movimento e a recuperacao depois dele.
2. Confrontar as faixas com o manual de 1994: 207 bar nominal, 93 bar de
   pressao baixa e escala de 0 a 300 bar.
3. Manter a identificacao de modelo de projeto, sem alegar calibracao ao AMX
   real, conforme sua autorizacao anterior.

Aceite para 7: consumo observavel durante o movimento de pelo menos um
consumidor real, com recuperacao, repetido.

### P4. Teclado, de 5 para 7

Situacao: 54 das 105 acoes foram repetidas em contextos selecionados. As
sessoes de ICP foram interrompidas por perda de foco e por desconexao de
teclado e vídeo durante acesso remoto.

Passos:

1. Executar com sessao local, nao remota, ou com area de trabalho interativa
   estavel, para eliminar a causa das interrupcoes.
2. Fechar os sete controles de ICP e EGI pendentes.
3. Separar pressionamento curto e longo dos botoes de borda dos visores antes
   de aprovar essas ramificacoes.
4. Cobrir as 51 acoes restantes com efeito de produtor, nao recebimento.

Aceite para 7: as 105 acoes exercitadas nos contextos em que existem, com
efeito medido, em duas sessoes.

### P5. Estabilidade, de 5 para 7

Situacao: duas sessoes completas seguidas, com integridade confirmada. A
disputa de arquivo que abortava sessao foi corrigida.

Passos:

1. Sessao longa, de pelo menos trinta minutos, com amostragem continua.
2. Contabilizar erros por severidade no log do DCS e fixar um limite explicito,
   separando o que e herdado da instalacao do que e nosso.
3. Repetir apos reinicio do DCS e apos reconexao de dispositivos.

Aceite para 7: duas sessoes longas sem erro do observador, sem interrupcao e
com contagem de erros dentro do limite declarado.

### P6. EICAS, de 4 para 7

Situacao: o layout aprovado esta implementado, com 15 grupos e as causas
parciais de capota, geradores e hidraulica. NL, NH e TGT seguem sem fonte.

Passos:

1. Levantar do manual de 1994 os limites por regime, da Fig 5-3, e a definicao
   de NL, NH e TGT da Fig 1-9.
2. Decidir entre duas saidas honestas: derivar um modelo de projeto a partir do
   RPM generico disponivel, identificado como projeto igual a hidraulica, ou
   manter a indicacao indisponivel. Nao inventar sensor.
3. Implementar os detectores restantes que tenham fonte real.
4. Validar legibilidade dos paineis menores.

Aceite para 7: indicacoes de motor com origem declarada e coerente com o
manual, mais os detectores com fonte real funcionando e validados no DCS.

### P7. Mouse, de 3 para 7

Situacao: o auxiliar esta pronto e resolve as rotas, mas nao houve nenhum
clique aceito com efeito.

Passos:

1. Resolver a entrega do clique em COM1 e COM2, registrando pose, cursor, modo
   clicavel, argumento e efeito.
2. Expandir para as 34 zonas mapeadas, uma a uma.
3. Tratar o arrasto de eixo, hoje recusado pelo auxiliar.

Aceite para 7: pelo menos as zonas principais com efeito medido, repetidas,
sem afrouxar as protecoes de foco e cursor.

### P8. X56, de 3 para 7

Situacao: o inventario completo por descritor esta feito, com 67 exercicios
pendentes. Os dumps do BACKUP sao historicos e de outro identificador de
dispositivo.

Passos:

1. Capturar estado ao vivo do dispositivo, alem do descritor.
2. Exercicio fisico do operador: curso completo dos eixos, retorno ao centro,
   todos os botoes, o hat e os modos.
3. Correlacionar com o DCS e repetir apos reconectar.

Aceite para 7: eixos e botoes com leitura fisica confirmada e correspondencia
no DCS, repetido apos reconexao.

Dependencia: exige voce no controle. Nao substituo isso por injecao de entrada
ou dispositivo virtual.

### P9. Instalacao, de 3 para 7

Situacao: tudo roda em perfis privados. O perfil normal nunca foi tocado.

Passos:

1. Sua autorizacao explicita para instalar no perfil normal.
2. Procedimento de instalacao, atualizacao, remocao e retorno ao estado
   anterior, com verificacao por hash antes e depois.
3. Teste de ciclo completo, incluindo reversao.

Aceite para 7: instalar, atualizar e remover sem residuo, com retorno
verificado, duas vezes.

### P10. Sistemas avancados, de 1 para 7

Situacao: nao ha escopo definido. Radio, RWR, radar, FLIR, capacete e
armamento estao todos em aberto.

Passos:

1. Definir com voce quais sistemas entram nesta nota. Sete de sete sistemas nao
   e realista no horizonte atual.
2. Para cada um escolhido, levantar fonte de dados e direitos.
3. Implementar somente o que tiver fonte, sem simular sensor inexistente.

Aceite para 7: os sistemas acordados funcionando e validados no DCS, com a
lista do que ficou de fora registrada.

## 5. Ordem de execucao

1. P1 Mecanismos, porque destrava P2 e P3.
2. P3 Hidraulica, logo que houver consumidor.
3. P2 Voo completo.
4. P5 Estabilidade, aproveitando as sessoes longas de voo.
5. P4 Teclado e P7 Mouse, que dependem da area de trabalho.
6. P6 EICAS.
7. P8 X56, quando voce puder operar.
8. P9 Instalacao, quando voce autorizar.
9. P10 Sistemas avancados, apos definicao de escopo.

## 6. O que depende de voce

- Area de trabalho local estavel para teclado e mouse.
- Operar o X56 fisicamente.
- Autorizar o perfil normal para instalacao.
- Definir o escopo de sistemas avancados.
- Autorizar mexer no EDM, caso a investigacao de mecanismos aponte para a
  geometria.

## 7. Onde 7 pode nao ser alcancado

Sendo justo com o que existe hoje: P1 pode parar na geometria do modelo, e
nesse caso P2 e P3 param junto. P10 nao chega a 7 sem reduzir o escopo. P8
depende inteiramente de voce. Se qualquer um desses travar, a nota fica onde
esta e o motivo fica escrito, em vez de ser contornado.

Fontes internas: [progresso](PROGRESS.md), [plano anterior](PLANO_RECUPERACAO.md),
[validacao operacional](OPERATIONAL_VALIDATION.md), [EICAS](EICAS_PROPOSAL.md),
[permissoes](PERMISSIONS.json), [caminho de comando](Evidence/Operational-REV07/command-path-results.json)
e [entrega de comando](Evidence/Operational-REV07/command-delivery-results.json).
