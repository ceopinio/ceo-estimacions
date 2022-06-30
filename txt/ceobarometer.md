# Introducción  {#sec:introduction}

Ni siquiera quienes participan como entrevistados en las encuesta
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

# Asignación de una preferencia partidista {#sec:vote-choice}

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

# Asignación de una probabilidad de participación {#sec:vote-propensity}

Es un fenómeno bien documentado que los entrevistados en encuestas
políticas tienden a exagerar su nivel de participación política. La
explicación tradicional es que los entrevistados no quieren admitir
delante de los entrevistadores que se desentienden de una actividad
bien vista socialmente como votar [@holbrook2010], especialmente si
son parte de un grupo de que se espera cierta virtud cívica
[@bernstein2001;@hanmer2017], como es el caso de votantes de mayor
edad o aquéllos que se dicen más interesados por la política.

De ahí que sea práctica común incluir en el instrumento preguntas
directas sobre intención de voto con una opción que capture abstención
pero también otras preguntas indirectas que den pistas a los
investigadores sobre la probabilidad con la que el entrevistado irá a
votar [@perry1979; @dimock2001].

Estas preguntas nos dan información adicional, quizás más completa y
correcta de la intención real de los entrevistados, pero tiene un
coste añadido. Por ejemplo, si preguntamos sobre la probabilidad con
la que un entrevistado cree que irá a votar en una escala en 10
puntos, ¿qué valor debemos usar para asignarle una decisión? ¿Y cómo
combinar esta información con la de otras preguntas en la batería? Se
presentan aquí dos posibles métodos de análisis. Una es el uso de
reglas que asigne, a cada votante, una decisión sobre si será contado
como abstencionista o no. El mayor inconveniente de esta estrategia es
que, por lo general, las reglas tienen poco apoyo empírico
[@sturgis2016]. 

La otra posibilidad es recurrir a un modelo estadístico que explote la
asociación entre las diferentes preguntas sobre la intención de ir a
votar, otras actitudes capturadas en la encuesta y, tal vez,
información sociodemográfica sobre los entrevistados. Esta estrategia
tiene una larga trayectoria en la literatura [@traugott1984;
@petrocik1991] y es práctica común [@malchow2008; @murray2009;
@rusch2013] no solo en análisis de encuestas electorales, sino también
en estudios de microtargeting [@endres2016; @endres2017;
@hersh2015hacking].

La estrategia que usamos para asignar, a cada potencial votante, una
decisión sobre si se abstendrá o no es equivalente a la que usamos
para estimar a qué partido votarán. En concreto usamos un modelo
predictivo con la misma estructura: de los casos en los cuales sabemos
si los entrevistados votarán o no, aprendemos una relación entre
variables que transportaremos a los casos que han preferido no
declarar su intención. 

Hay dos razones para separar las decisiones de voto y abstención a
pesar de que su parecido. Por una parte, usar modelos separados nos
dan más flexibilidad para, por ejemplo permitir que las dos decisiones
estén influenciadas por factores diferentes. Por otra, porque, si en
el caso de la intención de voto estábamos interesados en asignar un
partido a cada votante, en el caso de la intención de abstenerse,
estamos interesados en asignar una probabilidad. Esta probabilidad nos
dará un instrumento flexible para simular diferentes escenarios de
participación: podemos evaluar el efecto de diferentes umbrales en la
probabilidad de voto para comprobar la composición de los votantes que
irán a las urnas y su impacto sobre los resultados electorales
estimados.

La @fig:roc muestra la bondad de ajuste del modelo. En concreto, la
relación entre la proporción de verdaderos positivos y falsos
negativos para diferentes posibles umbrales de probabilidad que pueden
usarse para transformar probabilidades en decisiones. Como puede
verse, el modelo tiene una alta capacidad predictiva y tiene asociada
una exactitud de XXX.

![Curva ROC para el modelo de participación electoral](./img/roc-abstention.pdf){#fig:roc width=70%}

Al igual que antes, del modelo obtenemos una intención de
comportamiento únicamente para los entrevistados que no la declaran.
Esto es, el modelo no reemplaza las decisiones reportadas por los
entrevistados. [PERO ESTO NO ARREGLA EL PROBLEMA DE SOBRERREPORTING]

# Ponderación por recuerdo de voto {#sec:weighting}

La re-ponderación de encuestas nunca es sencilla o, en palabras, de
@gelman2007: "[s]urvey weighting is a mess". En general, la
re-ponderación es necesaria para ajustar discrepancias entre la
muestra planeada y la muestra ejecutada: no todos los individuos
seleccionados para ser entrevistados aceptan serlo y suele ser
necesario hacer correcciones a los pesos asignados a cada individuo
para que las estimaciones sigan siendo válidas. Por ejemplo, si las
mujeres fuesen menos proclives a participar en la encuesta, sería
razonable aumentar los pesos de aquéllas que sí han contestado al
cuestionario para que la distribución de mujeres en la muestra siga
reflejando la distribución en la población. Una revisión de
estrategias específicas para el caso de la opinión pública está
disponible en @elliott2017 y @blumenthal2013 discute las estrategias
usados por diferentes casas de encuestas.

En el caso español, es común re-ponderar las encuestas de opinión
pública para ajustar el recuerdo de voto a la distribución de voto
observada en el pasado. Es una práctica intuitivamente razonable ya
que existe una estrecha relación entre voto pasado y futuro: el voto
pasado es un buen predictor del voto futuro (tanto de la decisión de
ir a votar como del partido elegido) así que corregir la distribución
de recuerdo de voto puede servir para atajar problemas con, por
ejemplo, la distribución en la intención de acudir a las urnas y las
preferencias partidistas de los participantes en la encuesta en
relación a la población de interés. Al mismo tiempo, es una estrategia
que no está exenta de críticas [@durand2015] y han sido documentados
potenciales problemas para la estimación electoral [@escobar2014].

Sin embargo, para hacer esta re-ponderación, hay dos problemas con los
que debemos lidiar. Por una parte, y como ocurre con el resto de
preguntas de la encuesta, no todos los entrevistados responden a la
pregunta. Por otra parte, las últimas elecciones pueden ser un evento
distante y de bajo interés con lo que los entrevistados pueden tener
dificultades para recordar qué hicieron. Este segundo problema merece
un poco más de nuestra atención.

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
encuestas electorales. Quizás los entrevistados estén siendo sinceros
sobre qué hicieron en el pasado pero tal vez el desajuste entre la
distribución de recuerdo de voto y el valor real venga de un problema
de participación diferencial en la encuesta: aquellos que es más
probable que voten es también más proble que acepten ser
entrevistados, quizás, como vimos antes, por virtud cívica. Tal y como
lo pone @sciarini2016, "responding to a survey about politics and
misreporting on turnout are likely to be driven by similar factors".
De hecho @burden2000 muestra que mayor reticencia a participar en los
American National Election Studies está de hecho asociada con menor
probabilidad de votar. Compatible con esta interpretación, los
experimentos dirigidos a reducir la presión por deseabilidad social en
la pregunta sobre recuerdo de voto han tenido relativamente bajo éxito
[@abelson1992; @holbrook2010; @hanmer2017].

Esto no elimina la posibilidad de que, efectivamente, haya sesgos
causados por la distancia temporal a las últimas elecciones. Un patrón
frecuentemente repetido es que, por ejemplo, los entrevistados
indiquen que han votado por el partido ganador en una mayor proporción
que la real [@nadeau1993; @schmitt2015] .

Aún con estos inconvenientes, en el Baròmetre hemos optado por
re-ponderar la encuesta para que el recuerdo de voto refleje la
distribución real en las últimas elecciones. Para ello, imputamos un
recuerdo de voto esperado a aquellos entrevistados que no contestan a
la pregunta usando, como antes, un modelo predictivo. Como es de
esperar, este modelo tiene un rendimiento inferior al usado para las
variables de comportamiento futuro pero todavía lo bastante elevado
como para poder usar sus predicciones para postestratificar la muestra
de votantes.

# Estimación de la distribución de voto y escaños {#sec:seats}

Los pasos anteriores nos permiten una aproximación a la distribución
de voto esperado. Tras ellos, para cada individuo tenemos una
intención de voto que combina lo que han contestado a la pregunta con
lo que hemos imputado a los que no lo han hecho, una probabilidad de
abstenerse para aquéllos que no saben qué harán el día de las
elecciones y un peso que ajusta el recuerdo de voto. Con estas piezas
podemos calcular el porcentaje de individuos en la muestra que apoyan
a cada partido para diferentes escenarios de participación electoral.

El paso natural siguiente consiste en traducir estas proporciones de
voto a escaños en el Parlament. La tarea sería sencilla si pudiésemos
usar la encuesta para hacer inferencias sobre el apoyo a cada partido
en cada una de las circunscripciones en las que se eligen diputados.
Ignoremos por un momento ese problema. En ese caso, podríamos aplicar
las reglas de reparto de escaños a los resultados estimados en cada
circunscripción. Sin embargo, es importante hacer esto teniendo en
cuenta la incertidumbre asociada a nuestras estimaciones. Idealmente,
haremos el reparto usando extracciones aleatorias de las
distribuciones de apoyo a cada partido que son factible dada la
estimación en la encuesta, esto es, teniendo en cuenta el margen de
error muestral. Repitiendo esta simulación una gran cantidad de veces,
obtendríamos la distribución de escaños en el Parlament que es
consistente con los resultados en la encuesta.[^1]

Volvamos ahora al problema de estimar la distribución de apoyo a cada
partido en cada distrito. El tamaño de muestra del Baròmetre en las
circunscripciones más pequeñas no es lo bastante grande como para
hacer inferencias fiables sin información adicional. Una forma de
superar este inconveniente es usando un modelo que permita combinar
los resultados observados en la encuesta para cada provincia con
información adicional que es accesible para el investigador. Una
fuente es, por ejemplo, la distribución de voto en elecciones
anteriores. Esta es la estrategia que hemos adoptado en los análisis.
En concreto, usamos un modelo de regresión bayesiano que nos permite
hacer la mejor combinación posible entre los resultados en la encuesta
y los resultados históricos de cada circunscripción relativos al total
en Cataluña.[^2] 

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
