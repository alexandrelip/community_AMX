# REV07: alinhamento e leitura dos cinco indicadores

## Resultado

**Verificacao visual nativa em 2D, AMXT_M dianteiro, em solo com motor ligado.**
O candidato **AMXT_M-REV07-Displays-M** preserva o encaixe do cockpit aceito pelo
usuario e corrige a proporcao dos caracteres do ICP. O exterior, os dois EDMs,
os descritores e o SFM nao foram alterados.

BuildId: `396A3B739E2E8CDEBCE150970AF7F4E83145C94979525663BDEF9F7E47F3BE69`.
As verificacoes usam uma janela com cliente 1600x900, capturada com moldura em
1616x939. Nao houve teste em VR, voo ou outro posto.

| Indicador | Alteracao | Observacao nativa e limite |
| --- | --- | --- |
| ICP | Proporcao da fonte e espacamento corrigidos | Cinco linhas legiveis nas vistas central, proxima, elevada e laterais; pagina COM1 tambem conferida, sem transbordar a moldura |
| MFD esquerdo | Nenhum reposicionamento necessario nas vistas testadas | Conteudo e rotulos acompanham a tela; bordas e recorte conferidos com a pagina ADHSI exibida |
| MFD direito | Nenhum reposicionamento necessario nas vistas testadas | EICAS acompanha a tela nas vistas amostradas, sem sobreposicao indevida na moldura |
| AUX/EFI central | Nenhum reposicionamento necessario nas vistas testadas | Conteudo permaneceu dentro da abertura central nas vistas amostradas |
| HUD | Posicao e escala mantidas | Simbologia visivel no centro; recorte lateral observado a cerca de 2,5 cm e acentuado nos extremos de 10 cm. Nao foi certificado o eyebox completo nem calibrada a optica |

A fonte original tem celulas de 64x52 pixels. O adaptador anterior calculava
altura e largura independentemente, comprimindo os caracteres. A textura DDS
e sua grade estavam corretas. Agora o layout preserva a proporcao 64:52 e usa
o espacamento da definicao UFCP existente, limitado a 25 colunas e cinco linhas
com margem de 1 mm por lado. Nao foi substituida ou renomeada nenhuma textura.
Os testes conferem o cabecalho DDS, a grade, a proporcao e os limites do texto.

## Vistas e evidencias

- [Vista central proxima](Evidence/Displays-REV07/close-center.png).
- [Vista lateral esquerda](Evidence/Displays-REV07/left-oblique.png) e
  [direita](Evidence/Displays-REV07/right-oblique.png).
- [Vista elevada](Evidence/Displays-REV07/raised-center.png).
- [Pagina COM1 do ICP](Evidence/Displays-REV07/icp-com1.png).
- [Antes da correcao do ICP](Evidence/Native-REV07/alignment-accepted.png).
- [Poses e comandos observados](Evidence/Displays-REV07/view-poses.json).

Na execucao N, a distancia entre as duas posicoes laterais extremas foi
0,200 m; as posicoes menores ficaram a aproximadamente 0,025 m do centro.
A vista elevada deslocou a cabeca aproximadamente 0,020 m. Esses valores vem
das poses nativas, nao da suposicao de que o valor do comando equivale a metros.
A consulta de FOV retornou indisponivel, portanto nao ha afirmacao de angulos
de zoom medidos. As amostras adjacentes as capturas laterais/elevada e os ultimos
estados de cada sequencia foram preservados separadamente.

Nas vistas laterais o HUD colimado perde simbologia ao sair da abertura. Isso
foi registrado, nao ocultado por alargar artificialmente a mascara. O teste
confirma o comportamento observado, nao sua equivalencia a um HUD real AMX.

## Apagamento e restauracao

Na execucao P, os cinco indicadores foram observados nos estados **1 -> 0 -> 1**
apos comandos diagnosticos de bateria e geradores. Nao se usou injeção de pixels,
valores de sensores ou parametros de instrumentos. Os comandos diagnosticos
nao contam como aprovacao de teclado, clique ou HOTAS.

[Ligados](Evidence/Displays-REV07/power-on.png),
[desligados](Evidence/Displays-REV07/power-off.png) e
[restaurados](Evidence/Displays-REV07/power-restored.png).

A [auditoria de pixels](Evidence/Displays-REV07/interior-audit.json) usa
retangulos fixos inteiramente dentro de cada visor, sem moldura. Entre as tres
capturas, a camera variou aproximadamente **0,095 mm** e a diferenca maxima
dos componentes de orientacao foi menor que `0.00001`.

| Interior | Metrica | Ligado | Desligado | Restaurado |
| --- | --- | ---: | ---: | ---: |
| LEFT | Pixels com canal >= 64 | 2.983 | 0 | 2.975 |
| RIGHT | Pixels com canal >= 64 | 1.035 | 0 | 1.030 |
| AUX | Pixels com canal >= 64 | 685 | 0 | 687 |
| ICP | Pixels com canal >= 64 | 447 | 0 | 432 |
| HUD | Pixels de predominancia verde | 553 | 13 | 562 |

No HUD transparente, alguns pixels verdes do cenario permanecem com a energia
desligada. A auditoria combina a queda/retorno dessa metrica com a mudanca de
cor no mesmo interior. Ela comprova o ciclo visual, mas **nao automatiza o aceite
de legibilidade, fidelidade ou alinhamento optico**. A inspeção visual das
capturas complementa esses dados.

## Limites e tentativas preservadas

- A execucao M teve um pedido de camera recusado. Sem motivo detalhado naquele
  observador, nao foi atribuido ao DCS nem considerado movimento realizado.
  O observador posterior registra o motivo de cada rejeicao.
- Na execucao N, uma espera expirou relendo um log de 283 MB, embora o movimento
  ja estivesse registrado. A espera passou a ler somente a cauda recente para
  sequencias de comandos; o arquivo bruto inteiro foi preservado. A mesma
  sequencia foi confirmada sem reenviar o comando.
- N encerrou normalmente antes do ciclo de energia, sem comando de encerramento
  desta tarefa naquele momento. A causa/autor do encerramento nao foi atribuida.
- O ciclo O confirmou os parametros de energia, mas suas capturas nao enquadraram
  os MFDs. **Nao foi aceito como prova visual dos cinco indicadores.** A execucao
  P repetiu o ciclo com todos dentro da imagem. O aceite de pixels usa apenas as
  capturas P 02/03/04, cuja pose foi comparada, nao a captura inicial de P.
- As tres texturas locais ausentes e as pendencias de teclado/mouse/HOTAS,
  radio nativo, radar/RWR/FLIR/HMD e disparo nao foram resolvidas por este teste.
- As 69 paginas passam na bancada Lua, mas nem todas foram exibidas nativamente
  nesta etapa. Nao se extrapola o resultado das paginas observadas a todo o menu.

## Preservacao e reproducao

Os perfis M/N/O/P foram isolados, com registros de PID/inicio, arquivos por hash
e copias temporarias de autenticacao removidas ao finalizar. As quatro
finalizacoes passaram na integridade; a versao atual das opcoes normais, com
hash `934CF441D4899BE6E31B4D9CF1B7106ECA27082C7A26B11A94AA8C94A5DDFD09`, foi o
baseline novo e nao foi restaurada para uma versao anterior.

Os logs completos continuam em `%LOCALAPPDATA%/AMXDENIS-Integration/Runs/Native-REV07-Displays-*`.
Logs DCS existentes contem diagnosticos de modelo de dano/instalacao; esta
entrega nao alega log global limpo. O [resumo](Evidence/Displays-REV07/summary.json)
identifica o escopo, as finalizacoes e a preservacao dos recursos originais.

[CI final](Evidence/Displays-REV07/ci-final.log): 15 scripts PowerShell;
35/36/27/12 guardas; 8+14 testes Python; 20 verificacoes do observador;
219 scripts Lua; 527 verificacoes de registro; 1.599 de runtime;
22.016 dos indicadores em 69 paginas. Resultado de
[bancada do candidato](Evidence/Displays-REV07/bench-final.json).

O ponto do cockpit e a camera padrao do mod permanecem os previamente aceitos.
As vistas de teste sao comandos limitados do observador privado, permitidos
somente perto do solo e com velocidade menor que 0,25 m/s por componente.
Esta etapa deixa alteracoes locais; nao instala no perfil normal nem faz um
novo commit/push automaticamente.