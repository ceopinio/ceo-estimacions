# Introducción  {#sec:introduction}

Ni siquiera quienes participan como entrevistados en las encuestas
electorales saben con certeza lo que ellos mismos harán el día de las
elecciones. Entre un 13% y 54% de la gente que dice que va a votar no
lo hace y sí que lo hacen entre un 29% y un 55% de los que aseguran
que no lo harían [@rogers2011]. Los datos provienen de Estados Unidos
y es cuestionable que se trasladen al caso catalán pero ilustran bien
un reto de usar las encuestas electorales como instrumentos de
predicción: muchas cosas pueden cambiar entre el día de la entrevista
y el día de las elecciones. Quizás aparezcan contigencias de última
hora que impidan al entrevistado ir a las urnas, quizás cambie de
opinión sobre qué hará ese día o incluso quizás prefiera no hacer
partícipe al entrevistador de lo que tiene previsto hacer.

Sin embargo, esta perspectiva sobre el propósito de las encuestas
electorales, aunque común, es errónea. Uno debe interpretar las
preguntas sobre el comportamiento esperado teniendo en cuenta que el
objetivo de las mismas es capturar una disposición y no hacer una
predicción. Como investigadores, no estamos mejor situados que los
entrevistados para deducir si votarán o por quién lo harán y solo
tenemos a nuestro alcance lo que nos dicen que harían llegado el
momento. Sin embargo ese no es nuestro objetivo. Aunque las preguntas
de intención de voto se formulen como un _hipotético_ comportamiento
futuro, es capturar un aspecto concreto de la opinión pública (el
apoyo a cada una de las opciones electorales) en el contexto y en el
momento en el que la entrevista tiene lugar.

La tarea de estimación electoral, vista desde esta interpretación en
la que la intención de voto es una aproximación a una actitud, es más
factible y menos desesperanzadora. La dificultad radica, no en la
imposibilidad práctica de predecir el futuro, sino en el hecho de que
la política es una dimensión secundaria para la mayoría de la
ciudadanía: ni muchos entrevistados tienen preferencias políticas
claramente definidas en el momento de la entrevista ni su memoria
sobre qué hicieron en las últimas elecciones es precisa. De ahí que,
entre otras cosas, las preguntas que nos interesan tengan
habitualmente altas tasas de valores perdidos (esto es, respuestas del
tipo "no sabe/no contesta").

En cualquier caso, esta tarea, la de asignar una disposición a cada
entrevistado y a la muestra en su conjunto, es un frente en el que
podemos hacer avances. Regularidades en las actitudes de los
entrevistados (es de esperar que gente que responde de forma similar a
las mismas preguntas tenga actitudes o comportamientos similares) y
supuestos poco controvertidos acerca de la consistencia interna de los
perfiles de respuestas de cada individuo (por ejemplo, que la gente
que se declara de izquierdas es más probable que vote a partidos de
izquierdas) nos ofrecen una base sólida para imputar comportamientos
plausibles a cada entrevistado.

Este es, precisamente, el objetivo de esta nota. En ella discutimos el
método de estimación electoral usado en los Baròmetres d'Opinió
Política del Centre d'Estudis d'Opinió centrándonos en la motivación
de la solución que adoptamos en cada uno de los pasos. En concreto,
discutimos los modelos de asignación de intención de voto
(@sec:vote-choice) e intención de participación para cada entrevistado
(@sec:vote-propensity) así como de estimación de comportamiento
anterior como fase previa a la re-ponderación de la encuesta
(@sec:weighting). Con esta información, podemos estimar la
distribución de la intención de voto implícita en la encuesta y el
método de asignación de escaños a cada alternativa política
(@sec:seats). Finalmente, en las conclusiones (@sec:conclusions)
presentamos algunas limitaciones conocidas de esta aproximación y
potenciales mejoras futuras. Los detalles técnicos pueden consultarse
en el código de replicación disponible en el repositorio en GitHub del
Centre d'Estudis d'Opinió.

# Asignación de preferencia partidista {#sec:vote-choice}

Aunque quizás no sea el componente que tenga más impacto en la
estimación final, la asignación a cada entrevistado de una intención
de voto es, intuitivamente, la más relevante en el proceso.

A medida que se acerca el día de las elecciones, la decisión de a qué
partido votar tiene más prominencia para la ciudadanía y la pregunta
de intención de voto es probablemente más predictiva de su
comportamiento el día de las elecciones [@crespi1988]. Pero incluso
cuando las elecciones están distantes en el horizonte, la pregunta de
a qué partido votarían de celebrarse elecciones ese mismo día es una
síntesis de predisposiciones, actitudes, evaluaciones y
características personales que tiene potenciales implicaciones
institucionales. El problema es que, como decíamos antes, es una
decisión que no todos los entrevistados están en condiciones de tomar
en el momento de la entrevista.

No es necesaria mucha familiaridad con la literatura académica para
observar que el comportamiento electoral está condicionado por una
enorme variedad de variables. Factores estables como la ideología
[@jessee2012; @albertos2002; @rivero2015] y la identidad partidista
[@bartels2000]; o más contextuales como evaluaciones de las
condiciones políticas o económicas [@fraile2005; @fraile2010] tanto
personales como generales y tanto presentes como esperadas, así como
el conocimiento y valoración de partidos y líderes [@wlezien1997;
@maravall1999] aparecen constantemente en la invesigación
especializada. A éstas habría que añadir factores sociodemográficos
como la edad, el género o la clase social también asociadas con la
decisión de voto [@polavieja2001; @cainzos2001] a través de vías
directas e indirectas. La literatura es inmensa y unas pocas citas no
hacen justicia a su extensión y profundidad pero la idea fundamental
es que existen regularidades bien documentadas que pueden servir para
hacer supuestos razonables sobre la intención de los indecisos.

El mayor problema es, precisamente, uno de sobreabundancia. La
literatura académica no nos ofrece un guía clara para traducir los
resultados disponibles en pasos específicos (por ejemplo, qué
variables usar y cómo usarlas) que podamos aplicar para el análisis de
una encuesta electoral en concreto. Sin embargo, la multitud de
teorías y variables es, en si mismo, una sugerencia usar un modelo que
tenga en cuenta tantos factores potenciales como sea posible. Esto es,
en lugar de apostar por una teoría particular de comportamiento
electoral para asignar una intención de voto a los indecisos, quizás
sea más razonable optar por una aproximación más agnóstica y empírica.

En el caso del Baròmetre, hemos usado un modelo _predictivo_ que
asigna a cada individuo el partido que mejor refleja sus preferencias
políticas usando información contenida en una larga listas de
preguntas que capturan diferentes modelos convencionales de
comportamiento electoral. El énfasis en el término "predictivo"
require una clarificación. Como indicamos al principio, no estamos en
posición de adivinar qué hará el entrevistado. "Predicción" en nuestra
aproximación se refiere a la capacidad del modelo para recuperar
correctamente la respuesta a la pregunta sobre la intención de voto de
los entrevistados que sí declaran su preferencia por un partido. Dicho
de otro modo, la aproximación que usamos en el Baròmetre está diseñada
para escoger los factores comportamiento que mejor capturen la
relación empírica entre las mútiples variables contenidas en la
encuesta y la intención de voto de aquellos que la han declarado.

Así, en lugar de empezar con un modelo teórico de comportamiento
electoral, escogemos la combinación de variables que es capaz de
replicar mejor una información que nos es conocida (a qué partido
dicen que votarán los que responden a la pregunta de intención de
voto) con lo que podemos transportar esa combinación a los casos en
los que esa información no ha sido revelada. Esta aproximación tiene
la ventaja de ofrecernos una herramienta para evaluar expectativas
comunes en análisis electoral y es similar a la usada en los modelos
de _microtargetting_ [@nielsen2012ground; @issenberg2013;
@nickerson2014]. Información más detallada sobre el modelo puede
encontrarse en @sec:appendix.

Un supuesto relevante, no solo para este método, es que quienes sí
declaran su intención de voto lo hacen de forma sincera. Aunque
siempre debemos contemplar la posibilidad de que los entrevistados
mientan, tampoco debemos exagerar la frecuencia de este comportamiento
o su impacto sobre nuestras inferencias. Para empezar, por que, tal y
como dice @sturgis2016: "[t]here is [...] no reason to assume that
embarrassment about admitting support for a particular party should
lead respondents to tell pollsters they intend to vote for a different
party; respondents could also select the Don't Know, or refuse
options". Además, la investigación especializada sobre "voto oculto",
que explota la variación entre modos de administración más o menos
proclives a elicitar un sesgo de deseabilidad social (por ejemplo,
instrumentos administrados por un encuestador frente a instrumentos
autoadministrados), encuentra que es un fenómeno relativamente raro.
Más probable es que, de existir un problema de desajuste entre la
intención de voto en la población y las preferencias políticas
capturadas en la encuesta, este esté causado por una participación
diferencial [@gelman2016] en el que potenciales votantes de
determinados partidos prefieren no participar en la encuesta
[@sturgis2016; @aapor2016]. Este fenómeno es más difícil de detectar y
corregir.

![Confusion matrix for the vote choice model](./img/confusion_matrix-partychoice.pdf){#fig:confusion-voteintention width=70%}

En la @fig:confusion-voteintention mostramos una medida de la
capacidad predictiva del modelo de comportamiento electoral. En
concreto, muestra una comparación entre el comportamiento predicho por
el modelo (en las columnas) y la intención declarada por los
entrevistados (en las filas). Dos notas son especialmente relevantes.
En primer lugar, que el modelo funciona bien en el sentido de que es
capaz de recuperar el comportamiento de un XXX\% de los casos. Además,
el modelo funciona mejor para algunos partidos (XXX) que para otros
(XXX). Esto es el resultado, por una parte, de que el modelo no tiene
suficientes ejemplos para aprender una pauta de comportamiento. Por
otra, de la natural dificultad de predecir algunos grupos como los
votantes a "Otros" partidos ya que se trata de una categoría muy
heterogénea. 

Una observación adicional relevante es el hecho de que las
predicciones de modelo se corresponden con el partido por el que el
entrevistado siente más simpatía en la práctica totalidad de los casos
en los que éste no responde a la pregunta sobre inteción de voto.
Además de ser una forma de validación indirecta del modelo, también
sirve para dar base empírica a prácticas establecidas en el campo.

Con los resultados de este modelo obtenemos una predicción de voto
para todos los entrevistados. En todos los análisis, solo usamos la
predicción de voto si el entrevistado no declara una intención
directa.

# Asignar una probabilidad de participación {#sec:vote-propensity}

Está bien documentado en la investigación especializada que los
entrevistados tienden a sobrereportar sus niveles de participación
política. La explicación tradicional es que los entrevistados no
quieren admitir delante de los entrevistadores que se desentienden de
una actividad socialmente sancionada como votar [@holbrook2010],
especialmente si pertenecen a un grupo del que otros esperan cierta
virtud cívica [@bernstein2001;@hanmer2017], tal y como votantes de
mayor edad o con mayor interés por la política. 

De ahí que, por lo general, las encuestas electorales eviten incluir
una única pregunta directa sobre si los entrevistados tienen intención
de abstenerse. En su lugar, siguiendo a @perry1979, es frecuente usar
una batería de preguntas que intenten capturar esa decisión directa e
indirectamente [@dimock2001]. 

En cualquier caso, como indica @sturgis2016, la cuestión clave no es
tanto la formulación de estas preguntas sino cómo usarlas en el
análisis. Por ejemplo, si preguntamos sobre la probabilidad con la que
un entrevistado cree que irá a votar en una escala en 10 puntos, ¿qué
valor debemos usar para asignarle una decisión? ¿Y cómo combinar esta
información con la de otras preguntas en la batería? Se abren aquí dos
posibilidades. Una es el uso de reglas deterministas potencialmente
complejas que asigne, a cada votante, una decisión sobre si será
contado como abstencionista o no. El mayor inconveniente de esta
estrategia es que, por lo general, las reglas tienen poca base
empírica [@sturgis2016]. La otra posibilidad es usar un modelo
estadístico aproveche las relaciones observadas en la encuesta entre
información sociodemográfica, actitudes e intenciones. Esta estrategia
tiene una larga trayectoria [@traugott1984; @petrocik1991] y es común
en la práctica habitual [@malchow2008; @murray2009; @rusch2013].

Al igual que hicimos en el caso de la intención de voto, usamos un
modelo predictivo para asignar, a cada votante, una probabilidad de no
ser abstencionista. La razón de usar un modelo separado en lugar de
modelizar la decisión de voto y abstención es porque, por una parte es
posible que sea una decisión separada afectada de forma diferente por
las vriables observadas. Por otra, para usar una probabilidad de votar
vs no votar.

La @fig:roc muestra la bondad de ajuste del modelo. Como puede verse,
el modelo tiene una

![Curva ROC para el modelo de participación electoral](./img/roc-abstention.pdf){#fig:roc width=70%}

Del modelo predecimos para cada individuo una probabilidad. Usando
esta probabilidad, inferimos además un threshold que mnimize los
falsos positivos y falsos negativos. Este valor sirve de base para la
estimación de la tasa de participación electoral, aunque es importante
añadir informació adicional como la histórica.

# Ponderación por recuerdo de voto {#sec:weighting}

La ponderación de las encuestas de opinión no es una tarea sencilla y
no existe un método obvio para corregir algunos de los sesgos de
no-participación más frecuentes. Los problemas dependen de elementos
técnicos de la encuesta pero en todos los casos el problema es siempre
el mismo: hay votantes que, por lo general, no están correctamente
representados en la encuestas bien porque declina participar o porque
no es accesible. La re-ponderación de las encuestas de opinión pública
para ajustar tasas diferenciales de participación es común, por
ejemplo, para corregir que habitualmente individuos más jóvenes,
pertenecientes a minorías o con menores niveles de educación
[@battaglia2008; @chang2009] son menos proclives a participar. Una
revisión de estrategias está disponible en @elliott2017. Sin embargo,
incluso esta solución nunca es sencilla de implementar. En palabras de
@gelman2007: "[s]urvey weighting is a mess."

En el caso español, es común ponderar las encuestas por recuerdo de
voto. Es información conocida ya sabemos la distribución de voto de
cualquiera de las elecciones por las que preguntemos con lo que
podemos ajustar la frecuencia de cada grupo de tal forma refleje la
distribución real. Esta práctica es razonable por la estrecha relación
entre voto pasado y voto futuro aunque no está exenta de críticas
[@durand2015] y potenciales problemas [@escobar2014]. @blumenthal2013
discute las estrategias usados por diferentes casas de encuestas. 

Sin embargo, hay dos problemas con los que debemos lidiar. Por una
parte, el voto pasado es difícil de medir: es un evento que ocurre a
gran distancia temporal y que puede ser difícil de recordar, que
además puede estar sesgado por los mismos motivos que la intención de
voto. Por otra, que no todos los entrevistados reponden a esta
pregunta. Obivamente, las dos dimensiones pueden estar asociadas.

Es un resultado común en la literatura en Estaods Unidos que los
entrevistados tienden a sobrereportar voto pasado. Por ejemplo,
@mcdonald2007 muestran que elecciones con tasas de participación de
50% están asociadas a encuestas en las que entre un 70 y un 90% de
entrevistados dicen haber votado. Desde luego esto no es un problema
únicamente americano [@karp2005; @selb2013]. @selb2013, por ejemplo,
indican que la tasa de participación en encuesta casi siempre excede
la tasa de participación oficial usando datos de 128 estudios
postelectorales en 43 países.

Este sesgo debería ser evidencia suficiente de que el problema no es
simplemente uno de memoria [@ansolabehere2017]. @ansolabehere2017, de
hecho, ofrece una explicación que presenta problemas serios para las
encuestas electorales. En su estudio, quizás los entrevistados sean
sinceros sobre su voto pasado pero en problema está en la
participación en la encuesta: aquellos que es más probable que voten
es también más proble que acepten ser entrevistados, quizás por virtud
cívica. Tal y como lo pone @sciarini2016, "responding to a survey
about politics and misreporting on turnout are likely to be driven by
similar factors". De hecho @burden2000 muestra que mayor reticencia a
particpar en el National Election Study está de hecho asociada con
menor probabilidad de votar. En este caso, la diferencia entre
partipación real y estimada en eneustas refleja diferentes tasas de
partipación en la encuesta entre votantes y abstencionistas.

Además, es posible que haya que añadir la posibilidad de que los
entrevistados, bien por falta de memoria o bien por deseabilidad,
reporten que han votado por el partido ganador [@nadeau1993;
@schmitt2015]. A number of experiments have tried to reduce the social
desirability pressure from the past turnout questions, although with
limited success [@abelson1992; @holbrook2010; @hanmer2017].

Por ello, en la estimación electoral, al igual que más arriba, un
modelo se encarga de asignar a cada entrevistado un voto pasado.
Obivamente, este modelo funciona peor que el modelo para estimar
intención de voto. Con la variable rellenada, podemos entonces
corregir la distribución mediante poststratificación para que refleje
la distribución de voto pasado. 

# Asignación de escaños {#sec:seats}

Los pasos anteriores nos permiten una aproximación a la intención de
voto latente en la encuesta. El paso natural siguiente consiste en
traducir estas proporciones de voto a escaños en el Parlament. La
tarea es sencilla si tenemos las proporciones de voto para cada una de
las circunscripciones en las que se eligen diputados: en ese caso solo
tendremos que aplicar las reglas del reparto de escaños a los
resultados estimados en cada circunscripción teniendo en cuenta la
incertidumbre asociada a nuestras estimaciones.[^1] Para cada partido
en cada circunscripción, extrae un resultado aleatorio de los que son
factibles dada la estimación en la encuesta, elimina las listas que no
llegan al umbral mínimo y reparte el resto usando una versión
simplificada del método D'Hondt. Repitiendo el proceso una gran
cantidad de veces, obtenemos la distribución de escaños en el
Parlament que es consistente con los resultados en la encuesta.

Sin embargo, el problema es más complicado porque la encuesta no está
diseñada para estimar la distribución de voto en cada distrito y las
muestras en circunscripciones pequeñas por lo general son demasiado
pequeñas para poder hacer inferencias fiables sin información
adicional. El modelo es un modelo bayesiano de regresión que calcula
la distribución de voto en cada provincia como una combinación entre
los resultados observados en la encuesta e información adicional
aportada por el investigador.[^2] Una fuente razonable de información
adicional es, por ejemplo, la distribución de voto en elecciones
anteriores o, mejor aún, la distribución de voto _relativa_ en cada
circunscripción con respecto al total en Cataluña. El analista,
dispone de un parámetro para escoger en qué medida los resultados
deben guiarse más o menos por esta información previa. 

# Conclusiones {#sec:conclusions}

En las páginas anteriores hemos hecho una revisión a vista de pájaro
de las decisiones que han llevado al método de ponderación
implementado en el código.

Esta aproximación tiene alugunas liminaciones. La más importante es
que el método implica una analogía entre votantes y no-votantes. En la
práctica, la aproximación usada implique que los non-reporters en la
muestra son simliares a aquellos que sí indican sus preferencias de
voto y que, por tanto, la información sobre el comportamiento de los
que reportan puede usarse para hacer predicciones acerca de los que
no. Por supuesto, este supuesto no es exclusivo de una aproximación
predictiva pero sí que aparece como más obvia con esta aproximación. 

Mejoras en el ajuste de la distribución. Ahora mismo solo ponderando
por recuerdo de voto. Es posible ajustar más la distribución a la
disribución sociodemográfica si hubiese más información sobre los
votantes.

La estimación de participación puede usar métodos mas principled que
combinen información histórica con resultados en la encuesta.

Es un primer paso en un proceso de mejora. Accesibilidad del código y
el razonamiento puede involucar a otros.

\newpage

# Bibliography

<div id="refs"></div>

\newpage

\appendix

# El modelo de predicción

Los modelos predictivos usados para la estimación a nivel individual
de intención de voto y recuerdo de voto se basan en la idea de
_boosting._ Una introducción accesible al _boosting_ se puede
encontrar en @friedman2001. En partícular, usamos XGBoost, un
"scalable end-to-end tree boosting system" [@chen2016] que ha
demostrado funcionar bien en muchos dominios incluso aunque los
resultados son conocidamente difíciles de interpretar. XGBoost, que
puede ser visto como implementación eficiente de Gradient Boosting
Machines (GBM), pertenece a una clase de modelos que combina
aprendices débiles (_weak learners_) -- en este caso, árboles de
decisión con poca profundidad -- para formar aprendices fuertes
(_strong learners_) que tienen alta capacidad predictiva. XGBoost
construye una larga secuencia de árbones en los que, en cada paso, un
árbo de clasificación o regresión intenta ajustar una versión
ponderada de los datos. Durante el proces, XGBoost construye un
conjunto de árbones que alcanza bajos errores de generalización a
través de ponderar al alza observaciones que fueron más difíciles de
clasificar por la árboles previos.

XGBoost, como cualquier otro modelo de aprendizaje automático,
requiere ajustar un número de hiperparámetros para conseguir que el
modelo generalice bien entre la información entrante (variables
independientes) y la saliente (variable dependiente). En los modelos,
ajustamos la profundidad de cada árbol, el número de árboles en la
secuencia, y la penalización añadida a cada árbol en la serie. 

Una ventaja crucial de XGBoost en estas aplicaciones es que puede
trabajar de forma natural con valores perdidos en las variables
independientes sin necesitar un paso de imputación. Otros modelos
podrían haber sido usados, como modelos penalizados lineales. La
experiencia de hecho dicta que tendrían un rendimiento similar y que
podrían ser más familiares para audiencias técnicas y más fáciles de
interpretar para las no técnicas. Ya que la tarea es predictiva por
naturaleza, métodos estadísticos convencionales basados en el
contraste de hipótesis nulas, como las variantes de la regresión
logística, fueron rechazados. Sin embargo, es relevante señalar que el
modelo en si mismo no es tan importante como el método usado para
validar las inferencias de l mismo, especialmente en un contexto en el
que los analistas por lo general tienen que trabajar usando hipótesis
que no son contrastables. 

Para cada variable dependiente, usamos el mismo procedimiento. En
primer lugar, seleccionamos los casos para los cuales la variable
dependiente es conocida. De estos casos, dejamos al margen un número
de casos que sirvan como muestra de contraste y usamos validación
cruzada con 5 iteraciones y 5 repeticiones sobre una cuadrícula con
muchos posibles valores para escoger la combinación óptima de
hiperparámetros.

[^1]: Véase el paquete `escons`.

[^2]: Véase el paquete `dshare`.
