# Detecção de Faces com Histogramas de Gradientes Orientados
![GitHub release](https://img.shields.io/github/release/abnersn/hog_detector.svg?style=flat-square)
![GitHub](https://img.shields.io/github/license/abnersn/hog_detector.svg?style=flat-square)

Implementação em MATLAB de um detector facial baseado em histogramas de gradientes orientados para extração de características e máquinas de vetores de suporte (SVM) para classificação.

## Requisitos
Os softwares abaixo (ou versões compatíveis) são necessários para executar os scripts.
* [MATLAB r2017a](https://www.mathworks.com/products/matlab.html);
* [Mathworks Image Acquisition Toolbox](https://www.mathworks.com/products/imaq.html);
* [LibSVM 3.23](https://www.csie.ntu.edu.tw/~cjlin/libsvm/) (incluso no repositório);

## Como executar
O repositório já inclui classificadores SVM pré treinados com parte dos dados (200 amostras positivas e 20.000 negativas), nos arquivos `svm_model_sobel.mat` e `svm_model_prewitt.mat`. Para efetuar a detecção, execute o script `detect.m`, especificando o arquivo de imagem na linha 21 e o filtro a ser utilizado na linha 19.

## Como treinar um novo modelo
Para treino do classificador SVM, são necessárias amostras de imagens com tamanho 32x32 que contém faces (positivas) e que não contém (negativas). Para melhor desempenho, as amostras devem apresentar similaridade com os blocos da janela deslizante que serão processados durante a fase de detecção. As imagens devem ser organizadas conforme a seguinte estrutura de diretórios:
```
- data
    |_ positive
        |_ positive_1.jpg
        |_ positive_2.jpg
        |_ ...
    |_ negative
        |_ negative_1.jpg
        |_ negative_2.jpg
        |_ ...
```
A pasta `data` contém amostras já preparadas, com 200 exemplares positivos e 20 mil negativos. Uma vez organizados os dados para treino, basta executar o script `train.m`, especificando os parâmetros de treino desejados. O script deve produzir um arquivo `svm_model_sobel.mat` ou `svm_model_prewitt.mat`, conforme o filtro escolhido. Os arquivos `.mat` contém os modelos SVM usados para executar a detecção.

# Documentação

- [Introdução](#introdução-e-justificativa)
- [Fundamentação Teórica](#fundamentação-teórica)
  - [Sinais bidimensionais discretos e imagens digitais](#sinais-bidimensionais-discretos-e-imagens-digitais)
  - [Processamento de sinais bidimensionais discretos](#processamento-de-sinais-bidimensionais-discretos)
  - [Sistemas lineares invariantes](#sistemas-lineares-invariantes)
  - [Convolução](#convolução)
  - [Filtros diferenciadores](#filtros-diferenciadores)
  - [Filtro de Prewitt](#filtro-de-prewitt)
  - [Filtro de Sobel](#filtro-de-sobel)
  - [Histogramas de gradientes](#histogramas-de-gradientes)
  - [Classificação](#classificação)
- [Metodologia](#metodologia)
  - [Aquisição e pré-processamento dos dados](#aquisição-e-pré-processamento-dos-dados)
  - [Cálculo dos gradientes e histogramas](#cálculo-dos-gradientes-e-histogramas)
  - [Treino do classificador e testes de desempenho](#treino-do-classificador-e-testes-de-desempenho)
- [Resultados](#resultados)
  - [Aplicação dos filtros](#aplicação-dos-filtros)
  - [Visualização dos histogramas](#visualização-dos-histogramas)
  - [Resultados nas bases de teste](#resultados-nas-bases-de-teste)
- [Conclusões](#conclusões)

## Introdução

A capacidade de reconhecer rostos familiares é uma habilidade inata dos seres humanos, fruto evolutivo da necessidade de interação social e comunicação entre indivíduos de uma espécie na qual a visão é um dos principais sentidos. Entretanto, em termos computacionais, essa habilidade não é trivial, uma vez que a representação matemática da face, em seus diversos ângulos e formas, é inerentemente não-linear e não-convexa. Na ilustração abaixo, encontram-se exemplificados graus de variabilidade possíveis na imagem de um rosto humano.

<p align="center">
<img src="https://s3.amazonaws.com/abnersn/github/hog-detector/variacoes_.jpg" alt=" Exemplos de possíveis variações de aspectos como ângulo, expressão, oclusão e condições de iluminação para imagens de faces." width="80.0%" />
<br>
<i>Exemplos de possíveis variações de aspectos como ângulo, expressão, oclusão e condições de iluminação para imagens de faces.</i>
</p>

Porém, independentemente do nível de sofisticação do método empregado na tarefa de identificação, o passo primordial no fluxo de implementação geral de sistemas de reconhecimento facial passa pela segmentação da região da face, _i.e._, a detecção facial. Tal fase, por sua vez, depende de uma série de operações de filtragem e pré-processamento que viabilizam a extração das características descritivas imprescindíveis à maioria dos algoritmos e metodologias. Assim, a compreensão das imagens enquanto entidades matemáticas que codificam mensagens e, portanto, estão intrinsecamente ligadas ao conceito de sinais, revela-se uma tarefa de crítica importância na implementação de sistemas computacionais que buscam imitar a visão humana.

## Fundamentação Teórica

### Sinais bidimensionais discretos e imagens digitais

Um sinal bidimensional discreto pode ser matematicamente definido por uma função ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_01.png), isto é, uma mapeamento de pontos representados por 2 coordenadas inteiras a um valor no plano complexo. Em analogia aos sinais unidimensionais, é possível definir um impulso bidimensional ![\delta[x, y]](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_02.png), com ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_03.png), conforme a equação abaixo. Na figura abaixo, encontra-se uma representação gráfica da função impulso.

![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_04.png)

Assim, qualquer sinal bidimensional pode ser representado por uma soma de impulsos deslocados nas duas dimensões e escalonados:

![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_05.png)

<p align="center">
<img src="https://s3.amazonaws.com/abnersn/github/hog-detector/impulso.jpg" alt=" Representação gráfica da função impulso bidimensional." width="40%" />
<br>
<i>
Representação gráfica da função impulso bidimensional.
</i>
</p>

Computacionalmente, uma imagem digital em níveis de cinza consiste numa matriz ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_06.png), cujos elementos, chamados de _pixels_, representam níveis de brilho que os componentes da mídia utilizada para exibição devem assumir. Imagens coloridas são representadas por múltiplas matrizes, denominadas canais, de modo que cada uma carrega as informações de intensidade apenas para a componente de cor à qual está associada. Neste trabalho, a fim de sintetizar as definições, apenas imagens em níveis de cinza serão consideradas nas seções que se seguem.

Uma imagem digital pode, portanto, ser representada por uma função bidimensional ![i[x, y]](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_07.png), em que ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_08.png) e ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_09.png) representam índices de um elemento ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_10.png) na matriz de _pixels_. Como os elementos ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_11.png) carregam informações sobre níveis de intensidade luminosa, uma imagem ![i[x, y]](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_12.png) é, em geral, convencionada como um sinal puramente real, _i.e._, sem componentes complexas. Na figura a seguir, é possível visualizar uma imagem digital tanto em sua forma matricial quanto a função discreta bidimensional associada.

<p align="center">
<img src="https://s3.amazonaws.com/abnersn/github/hog-detector/plotdisc.jpg" alt="Uma imagem digital e o gráfico da função discreta." width="70%"/>
<br>
<i>
Uma imagem digital e o gráfico da função discreta.
</i>
</p>

### Processamento de sinais bidimensionais discretos

### Sistemas lineares invariantes

Um sistema bidimensional é definido como um operador matemático ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_13.png), que mapeia uma função bidimensional de entrada ![i[x, y]](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_14.png) a uma saída ![o[x, y]](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_15.png). As propriedades de linearidade e invariância também podem estabelecidas para os sistemas bidimensionais, da seguinte forma:

- **Linearidade**: ![T{ai_1[x, y] + bi_2[x, y]} = aT{i_1[x, y]} + bT{i_2[x, y]}](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_16.png).

- **Invariância**: ![T{i[x - x_0, y - y_0]} = o[x - x_0, y - y_0]](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_17.png).

<p align="center">
<img src="https://s3.amazonaws.com/abnersn/github/hog-detector/SLIT_2D.jpg" alt="[fig:slit2d] Representação em blocos de um sistema bidimensional." width="40%" />
<br>
<i>
Representação em blocos de um sistema bidimensional.
</i>
</p>

### Convolução

Se um sistema ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_18.png) observa as propriedades de linearidade e invariância no tempo, pode-se proceder conforme a equação abaixo para se estabelecer a operação de convolução em duas dimensões. Analogamente aos sinais unidimensionais, a função ![h[x, y]](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_19.png) também é denominada resposta ao impulso do sistema ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_20.png). A convolução em duas dimensões guarda as mesmas propriedades da convolução simples, isto é, a comutatividade, associatividade e distributividade.

![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_21.png)

Em imagens, a convolução pode ser visualmente compreendida em termos de janelas deslizantes. Nesse processo, a resposta ao impulso do sistema ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_22.png), representada na forma matricial, é deslizada sobre a imagem. Pelo resultado acima, cada _pixel_ da saída corresponde, portanto, à soma das multiplicações ponto a ponto entre a matriz de ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_23.png) e os elementos da imagem sobre os quais ela está sobreposta. Uma ilustração para um dos passos do processo está exposta na figura abaixo. No contexto do processamento de imagens, a resposta ao impulso ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_24.png) é denominada máscara de filtragem.

<p align="center">
<img src="https://s3.amazonaws.com/abnersn/github/hog-detector/conv2d.jpg" alt="[fig:slit2d] Representação em blocos de um sistema bidimensional." width="60%" /><br>
<i>
Um dos passos do processo de convolução de uma imagem e da resposta ao impulso de um sistema para o cálculo do elemento central da saída.
</i>
</p>

### Filtros diferenciadores

O operador gradiente ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_25.png), definido sobre funções contínuas, expressa a magnitude, direção e sentido de variação nos valores de uma função de duas variáveis ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_26.png), ao longo de seu domínio. Em sinais unidimensionais, é possível expressar um diferenciador ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_27.png) como um sistema cuja resposta em frequência ideal é ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_28.png). As respostas em magnitude e fase do diferenciador ideal são representadas nos gráficos a seguir.

<p align="center">
<img src="https://s3.amazonaws.com/abnersn/github/hog-detector/ideal.jpg" title="fig:" alt="Resposta em frequência para o filtro diferenciador ideal." /><br>
<i>
Resposta em frequência para o filtro diferenciador ideal.
</i>
</p>

Em muitas aplicações do processamento de imagens, o cálculo do gradiente é útil para demarcar contornos e sintetizar as formas dos objetos. Entretanto, esse operador não pode ser utilizado, a rigor, no contexto discreto das imagens digitais. Todavia, se ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_29.png) for uma função contínua a partir da qual ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_30.png) foi amostrada, é possível obter uma aproximação para as derivadas parciais de ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_31.png) através da equação a seguir, com os intervalos discretos ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_32.png) e ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_33.png) tão pequenos quanto possível. Essa formulação é a base para a definição dos filtros de Prewitt e Sobel.

![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_34.png)

### Filtro de Prewitt

O filtro de Prewitt consiste numa implementação não-escalonada da equação do gradiente, com ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_35.png). A máscaras de filtragem de Prewitt para cálculo das derivadas parciais no eixo horizontal e vertical são definidas conforme:

![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_36.png)

Essas máscaras advém da convolução de dois filtros unidimensionais, um derivador ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_37.png), a ser aplicado no eixo principal, e um suavizador, ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_38.png), aplicado no eixo transversal. Abaixo, encontram-se expressas as componentes do filtro de Prewitt para cálculo da derivada no eixo horizontal. As componentes verticais estão expostas logo a seguir.

<p align="center">
<img src="https://s3.amazonaws.com/abnersn/github/hog-detector/diferenciador_prewitt.jpg" alt="Diferenciador." /><br>
<i>
Resposta em frequência da componente diferenciadora do filtro de Prewitt.
</i>
</p>

<p align="center">
<img src="https://s3.amazonaws.com/abnersn/github/hog-detector/suavizador_prewitt.jpg" alt="Suavizador." /><br>
<i>
Resposta em frequência da componente suavizadora do filtro de Prewitt.
</i>
</p>

![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_39.png)

![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_40.png)

Na imagem a seguir, é possível observar a resposta em frequência unidimensional de ambas as componentes do filtro de Prewitt. Para baixas frequências, a resposta em magnitude da componente diferenciadora aproxima-se do que se observa no diferenciador contínuo ideal, porém com atenuação das altas frequências. O papel do filtro suavizador, por sua vez, é reduzir a ruidosidade eventualmente intensificada no eixo transversal pela aplicação da componente diferenciadora.

### Filtro de Sobel

O filtro de Sobel é uma variação do filtro de Prewitt, com o sinal da componente derivadora invertido e um suavizador mais intenso. As componentes e máscaras desse filtro são definidas conforme as matrizes abaixo. A resposta em magnitude da componente diferenciadora do filtro de Sobel é similar à que se observa no filtro de Prewitt. Porém, na resposta do suavizador, ilustrada na mesma figura, verifica-se um comportamento mais próximo de um filtro passa-baixa, sem os pequenos picos nas altas frequências observados em Prewitt.

![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_41.png)

![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_42.png)

<p align="center">
<img src="https://s3.amazonaws.com/abnersn/github/hog-detector/derivador.jpg" alt="Diferenciador." /><br>
<i>
Resposta em frequência da componente diferenciadora do filtro de Sobel.
</i>
</p>

<p align="center">
<img src="https://s3.amazonaws.com/abnersn/github/hog-detector/suavizador.jpg" alt="Suavizador." /><br>
<i>
Resposta em frequência da componente suavizadora do filtro de Sobel.
</i>
</p>

### Histogramas de gradientes

Histogramas de Gradientes Orientados – abreviados por HOGs, do inglês _Histogram of Oriented Gradients_ – são um recurso computacional que permitem sintetizar matematicamente o aspecto morfológico de objetos em imagens (Dalal and Triggs 2005). O cálculo dos HOGs baseia-se na magnitude, direção e sentido dos vetores gradientes da imagem obtidos através da aplicação de um filtro diferenciador. Os filtros fornecem as componentes horizontais e verticais do gradiente de cada _pixel_, a partir das quais pode-se calcular o ângulo e módulo do vetor, conforme:

![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_43.png)

Em que ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_44.png) e ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_45.png) representam, respectivamente, o resultado da convolução de um filtro diferenciador parcial horizontal ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_46.png), e vertical, ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_47.png), sobre uma imagem ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_48.png).

Após o cálculo dos vetores gradientes, a imagem é setorizada em blocos quadrados de igual tamanho. Para cada bloco, um histograma das faixas de ângulos existentes é construído, de modo que o valor dos intervalos corresponde à soma das magnitudes dos ângulos correspondentes. O processo é ilustrado na imagem abaixo para blocos de tamanho ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_49.png) e um histograma de ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_50.png) setores. Na figura seguinte, encontra-se uma imagem descrita por histogramas de gradientes orientados de uma imagem de dimensões ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_51.png), blocos de tamanho ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_52.png) e histogramas de ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_53.png) setores. As linhas brancas localizadas sobre os blocos expressam a magnitude final de cada setor do histograma após a soma dos módulos dos vetores.

<p align="center">
<img src="https://s3.amazonaws.com/abnersn/github/hog-detector/histograma.jpg" alt=" Processo de construção dos histograma em um bloco 3\times3, com 4 intervalos de orientações." width="70%" /><br>
<i> Processo de construção dos histograma em um bloco 3 por 3 com 4 intervalos de orientações.</i>
</p>

<p align="center"><img src="https://s3.amazonaws.com/abnersn/github/hog-detector/image_comb.jpg" width="70%" alt="HOG" /><br><i> Representação gráfica dos histogramas de gradientes orientados da imagem
de um rosto, calculados com 9 intervalos em blocos de tamanho 8 por 8.</i></p>

### Classificação

As Máquinas de Vetores de Suporte – do inglês, SVM, ou _Support Vector Machines_ – são classificadores lineares binários que podem ser empregados na tarefa de identificar objetos em imagens previamente descritas por HOGs. Classificadores SVM, munidos de dados para treino, calculam hiperplanos separadores para as duas classes, de modo a maximizar a distância entre os planos e as amostras. Uma vez obtidos os hiperplanos, a predição de classe para uma amostra inédita é feita de forma extremamente eficaz, pois basta determinar a qual subespaço a amostra pertence, _i.e._, de qual lado do hiperplano ela está.

<p align="center"><img src="https://s3.amazonaws.com/abnersn/github/hog-detector/svm_2.jpg" width="50%" alt=" Representação do hiperplano separador de duas classes calculado por um SVM." /><br><i> Representação do hiperplano separador de duas classes calculado por um SVM.</i></p>

## Metodologia

### Aquisição e pré-processamento dos dados

A fim de treinar o algoritmo classificador adotado, um conjunto de amostras positivas, isto é, de imagens que contém faces, e negativas, sem faces, foi preparado. As amostras positivas foram extraídas da base de dados Caltech Web Faces.

<p align="center"><img src="https://s3.amazonaws.com/abnersn/github/hog-detector/positive_comb.jpg" width="80%" alt="Exemplares de amostras positivas e negativas da base de dados." /><br><i> Exemplares de amostras positivas e negativas da base de dados.</i></p>

### Cálculo dos gradientes e histogramas

As máscaras correspondentes aos filtros de Prewitt e Sobel foram definidas no software MATLAB e aplicadas sobre as imagens com auxílio da função `conv2`, que realiza a convolução bidimensional. A partir do resultado obtido pelos filtros parciais em cada eixo, o cálculo da magnitude e ângulo dos vetores gradientes foram feitos conforme as definições apresentadas. As filtragens com ambos os operadores foram realizadas no domínio do espaço.

Para a construção dos histogramas, cada imagem foi dividida em 64 blocos de tamanho ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_54.png), sobre os quais histogramas de 8 setores foram calculados e distribuídos ao longo da terceira dimensão. Em seguida, a matriz resultante, de dimensões ![](https://s3.amazonaws.com/abnersn/github/hog-detector/equations/eq_55.png), foi comprimida em um vetor com 512 características para treino do classificador. Na figura abaixo, encontra-se uma síntese desse processo.

<p align="center"><img src="https://s3.amazonaws.com/abnersn/github/hog-detector/histimg.jpg" width="80%" alt="Vetores." /><br><i> Processo de construção dos vetores de descritores a partir dos histogramas dos gradientes de uma imagem filtrada com filtros diferenciadores.</i></p>

### Treino do classificador e testes de desempenho

Para reduzir a incidência de falsas detecções, as amostras foram tomadas numa razão de 100 amostras negativas para cada positiva. No total, 200 amostras positivas e 20 mil negativas foram utilizadas, das quais 70% foram destinadas para treino e 30% para testes. A performance do algoritmo foi avaliada quanto ao erro de classificação nas amostras de teste, além da capacidade de detecção em imagens com múltiplas faces por meio de uma janela deslizante de classificação. Nesse último caso, as detecções sobrepostas foram eliminadas conforme o grau de confiabilidade retornado pelo classificador e o tamanho da área de sobreposição, de modo que blocos de detecção com muitos _pixels_ em coincidência com outros blocos positivos detectados foram descartados. Esse procedimento configura uma versão simplificada da técnica de supressão não-máxima.

## Resultados

### Aplicação dos filtros

A fim de visualizar o resultado da convolução dos filtros de Prewitt e Sobel sobre as imagens, a magnitude e o ângulo dos vetores calculados foram normalizadas e exibidas na forma matricial. É possível verificar que ambos os filtros apresentam resultados similares, com forte resposta na região das bordas dos objetos. De fato, contornos são regiões com brusca variação de intensidade nos tons de cinza da imagem, o que explica a saída observada para os filtros diferenciadores. Embora seja capaz de filtrar ruídos de alta frequência melhor que o filtro de Prewitt, o resultado da aplicação do operador de Sobel não apresentou diferenças significativas em relação ao primeiro. Isso se deve, principalmente, à redução na resolução das amostras, processo que atenua significativamente a presença de ruído.

<p align="center"><img src="https://s3.amazonaws.com/abnersn/github/hog-detector/resultados_filtros.jpg" width="80%" alt="Resultado para as magnitudes dos vetores gradientes calculados com os
filtros de Sobel e Prewitt." /><br><i> Resultado para as magnitudes dos vetores gradientes calculados com os
filtros de Sobel e Prewitt.</i></p>

### Resultados nas bases de teste

A fim de verificar a robustez da metodologia quanto à capacidade de detectar a presença de faces em novos blocos, foram efetuados testes com 30% das imagens, cujos resultados estão expostos na tabela a seguir. Ambos os filtros obtiveram desempenho similar, com baixas taxas de erro. O índice de falsos positivos nulo deve-se ao favorecimento das amostras negativas em detrimento das positivas, que tende limitar significativamente a região N-dimensional para a qual o classificador sinaliza uma detecção.

<p align="center">
<img src="https://s3.amazonaws.com/abnersn/github/hog-detector/res.jpg" width="80%" alt="Resultados obtidos pela janela deslizante de detecção." /><br>
<i>
Resultados obtidos pela janela deslizante de detecção.
</i>
</p>

<table><caption>Resultados obtidos por classificadores treinados com descritores de ambos os filtros.</caption><thead><tr class="header"><th style="text-align: center;">Filtro utilizado</th><th style="text-align: center;">Erro global</th><th style="text-align: center;">Falsos-positivos</th><th style="text-align: center;">Falsos-negativos</th></tr></thead><tbody><tr class="odd"><td style="text-align: center;">Prewitt</td><td style="text-align: center;">0,53%</td><td style="text-align: center;">0%</td><td style="text-align: center;">0,53%</td></tr><tr class="even"><td style="text-align: center;">Sobel</td><td style="text-align: center;">0,47%</td><td style="text-align: center;">0%</td><td style="text-align: center;">0,47%</td></tr></tbody></table>

Por fim, para avaliar a performance da técnica na detecção de múltiplas faces em imagens com resolução maior, foi implementada uma janela de detecção com os classificadores associados. Ambos alcançaram desempenhos próximos, porém apresentaram dificuldade na detecção de faces inclinadas ou com tamanho maior, em virtude da ausência de amostras suficientemente similares na base de treino.

## Referências

Angelova, Anelia, Yaser Abu-Mostafam, and Pietro Perona. 2005a. “Pruning Training Sets for Learning of Object Categories.” In _Computer Vision and Pattern Recognition, 2005. CVPR 2005. IEEE Computer Society Conference on_, 1:494–501. IEEE.

Chalup, Stephan, Kenny Hong, and Michael Ostwald. 2009. “Simulating Pareidolia of Faces for Architectural Image Analysis.” _International Journal of Computer Information Systems and Industrial Management Applications_ 2 (January).

Dalal, Navneet, and Bill Triggs. 2005. “Histograms of Oriented Gradients for Human Detection.” In _Computer Vision and Pattern Recognition, 2005. CVPR 2005. IEEE Computer Society Conference on_, 1:886–93. IEEE.

Fei-Fei, Li, Rob Fergus, and Pietro Perona. 2007. “Learning Generative Visual Models from Few Training Examples: An Incremental Bayesian Approach Tested on 101 Object Categories.” _Computer Vision and Image Understanding_ 106 (1): 59–70.

Gonzalez, Rafael C, Richard E Woods, and others. 2002. “Digital Image Processing.” Prentice hall Upper Saddle River, NJ.

Griffin, Gregory, Alex Holub, and Pietro Perona. 2007. “Caltech-256 Object Category Dataset.”

Hearst, Marti A., Susan T Dumais, Edgar Osuna, John Platt, and Bernhard Scholkopf. 1998. “Support Vector Machines.” _IEEE Intelligent Systems and Their Applications_ 13 (4): 18–28.

Kanade, Takeo. 1974. “Picture Processing System by Computer Complex and Recognition of Human Faces.”

Neubeck, Alexander, and Luc Van Gool. 2006. “Efficient Non-Maximum Suppression.” In _Pattern Recognition, 2006. ICPR 2006. 18th International Conference on_, 3:850–55. IEEE.

Prewitt, Judith MS. 1970. “Object Enhancement and Extraction.” _Picture Processing and Psychopictorics_ 10 (1): 15–19.

Schroff, Florian, Dmitry Kalenichenko, and James Philbin. 2015. “Facenet: A Unified Embedding for Face Recognition and Clustering.” In _Proceedings of the Ieee Conference on Computer Vision and Pattern Recognition_, 815–23.

Sobel, Irwin. 1968. “An Isotropic 3x3 Image Gradient Operator.” _Presentation at Stanford A.I. Project 1968_, February.

Stan Z. Li, Anil K. Jain. 2011. _Handbook of Face Recognition_. 2nd ed. Springer-Verlag London.

Woods, J.W. 2011. _Multidimensional Signal, Image, and Video Processing and Coding_. Elsevier Science. <https://books.google.com.br/books?id=0lJ0atc5X-UC>.

## Autor
* Abner Nascimento - [Universidade Federal do Ceará](http://www.ec.ufc.br/).

