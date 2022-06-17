# Introducción  {#sec:introduction}

@rogers2011 documentan quen en el caso de Estados Unidos, entre un 13%
y 54% de la gente que dice que va a votar no lo hace. Más sorprendente
es el hecho de que entre un 29% y un 55% de los que dicen que _no_ van
a votar sí lo hagan finalmente. Es cuestionable que estas magnitudes
se trasladen al contexto catalán pero ilustran bien los restos en el
uso de encuestas para el análisis electoral. Ni siquiera los
entrevistados pueden predecir con certeza lo que ellos mismos harán el
día de las elecciones: quizás aparezcan contigencias de última hora
que les impidan ir a las urnas, quizás cambien de opinión sobre qué
harán ese día o quizás prefieran no hacer partícipe al entrevistador
de sus planes para ese día.

A la hora de hacer interpretaciones, uno debe por tanto tener en
cuenta que las preguntas sobre comportamiento capturan una
_disposición_ y no una predicción. No hay mucho que, como
investigadores, podamos hacer sobre esto: no estamos en mejor posición
que los entrevistados para deducir si votarán o por quién y solo
tenemos a nuestra disposición lo que, en este momento, nos dicen que
harán.

Sin embargo, sí podemos usar información en la encuesta para hacer
inferencias razonables sobre la disposición de cada entrevistado y la
muestra en su conjunto. Regularidades en las actitudes de los
entrevistados (es de esperar que gente que responde de forma similar a
las mismas preguntas tenga actitudes o comportamientos similares) y
supuestos poco controvertidos acerca de la consistencia interna de los
perfiles de respuestas de cada individuo (por ejemplo, que la gente
que se declara de izquierdas es más probable que vote a partidos de
izquierdas) nos ofrecen una base sólida para imputar comportamientos
plausibles a cada entrevistado incluso aunque no podamos saber qué es
lo que harán al final.

Este es, precisamente, el objetivo de esta nota. En ella discutimos el
método usado en los Baròmetres d'Opinió Política del Centre d'Estudis
d'Opinió. En concreto, centraremos nuestra atención en los modelos
predictivos usados para estimar las variables conductuales más
relevantes en encuestas electorales. En primer lugar, la probabilidad
de que un entrevistado vaya a votar (@sec:vote-propensity) y el
partido por el que lo harán (@sec:vote-choice). Como paso intermedio
para la ponderación de la encuesta (@sec:weighting), también estimamos
el partido por el que lo hicieron en las últimas elecciones
(@sec:pastvote). Esta información nos permite estimar la distribución
de voto implícito en la encuesta. Finalmente, calcularemos una
distribución de escaños correspondiente con el fin de extrapolar las
consecuencias institucionales (@sec:seats). En este paso, la
dificultad técnica estará en asignar porcentajes de voto a cada
partido en cada distrito electoral.

# Estimar la decisión de votar o no {#sec:vote-propensity}

Está bien documentado que los entrevistados tienden a sobrereportar en
encuestas sus niveles de participación política. La explicación
tradicional es que los entrevistados no quieren admitir delante de los
entrevistadores que se desentienden de una actividad socialmente
sancionada como votar [@holbrook2010]. Esta motivación probablemente
afecte a votantes que se ven como más proclives a ilustrar virtudes
cívicas [@bernstein2001;@hanmer2017], lo cual es otra forma de decir
es probable que hay subgrupos de votantes que son más proclives a
exagerar su disposición. Por ejemplo, aquéllos de mayor edad o mayor
educación, o incluso con mayor interés por la política [@hanmer2017;
@ansolabehere2017].[^6] 

Una solución a este problema está, como siempre en el caso de las
encuestas, en mejorar el enunciado de la pregunta sobre intención de
voto. En este sentido, el trabajo de @perry1979 y su batería de ocho
preguntas es particularmente influyente (véase @voss1995 o
@sturgis2016) por cuanto es la base usada por la mayor parte de las
encuestadoras anglosajonas, aún cuando su uso esté abierto a
discrepancias [@dimock2001]. Al mismo tiempo, experiencias como la de
ANES muestran que variaiones sobre las preguntas tienen en realidad un
efecto pequeño, lo cual indica que las actitudes que llevan a
sobrerreporportar voto son muy robustas.

En cualquier caso, como indica @sturgis2016, la pregunta central está
sobre cómo usar los resultados de estas preguntas. Por ejemplo, si
preguntamos sobre la "probabilidad" de ir a votar en una escala en 10
puntos, qué valor usar como barrera para decidir si el votante irá a
las urnas o no? Se abren aquí dos posibilidades. Una es el uso de
mecanismos deterministas que a cada votante asigne una decisión basada
en información pasada o conocimiento del investigador. Volviendo a
@sturgis2016, el problema es que suele basarse en reglas con poca base
empírica. La otra posibilidad es usar aproximiaciones probabilísticas
que modelen el comportamiento reportado en una o varias preguntas.
Esta aproximación tiene una amplia trayectoria en la literatura que,
ya desde el principio ha buscado métodos para agregar preguntas en la
batería de participación [@traugott1984] o bien ha intentado estimar
una probabilidad de votar a nivel individual [@petrocik1991]. La
información que está disponible, como aludíamos antes, va más allá de
la batería de voto y puede depender de informadción sociodemográfica.
Para una aproximación moderna véase @malchow2008, @murray2009, o
@rusch2013.

En el caso del Baròmetre, hemos usado un modelo predictivo que
calcula, para cada individuo, la probabilidad de votar usando
información contenida en el resto de las respuestas. El adjetivo
"predictivo" exige una clarificación. Como indicamos al principio, no
sabemos el comportamiento final del entrevistado así que no tenemos
base para "predecir" qué hará. Con el término, que es convencional en
la literatura, nos referimos a que preferimos modelos basándonos en su
capacidad de representar los datos, independientemente de la base
teórica de comportamiento que refleje. Esto es, en lugar de empezar
con un modelo teórico de comportamiento electoral, escogeremos el
modelo que mejor replique la decisión de votar entre aquellos que sí
la reportan. Esta aproximación tiene la ventada de darnos una
herramienta para diagnosticar y reevaluar expectativas comunes en
análisis electoral. 

El tipo de modelo que usamos en este paso y en los otros pasos está
descrito en @sec:appendix. Para este modelo, usamos una gran variedad
de preguntas atitudinales y sociodemográficas entre las que el modelo
puede escoger para modelar la probabilidad de que el entrevistado diga
que "no votará" a la pregunta sobre intención de voto. Más información
sobre las variables usadas en el modelo puede encontrarse en el
repositorio.

![Confusion matrix for the vote choice model](./img/roc-abstention.pdf){#fig:roc width=70%}

La figura @fig:roc muestra la bondad de ajuste del modelo. Como puede
verse, el modelo tiene una 

# El modelo de comportamiento electoral {#sec:vote-choice}

La decisión más importante en el proceso es la de asignar a cada
entrevistado la opción de voto más probable para aquellos que dicen no
saber qué harán.[^1] No es sorprendente que las encuestas
pre-electorales sean más predictivas a medida que nos acercamos al día
de las elecciones ya que la mayor parte de la gente solidifica sus
decisiones en el último momento posible [@crespi1988]. La pregunta
clave para nosotroes es, podemos hacer inferencias razonables sobre
comportamiento esperado de aquellos que han preferido no expresar
todavía una preferencia electoral en la encuesta?

No es necesaria mucha familiaridad con la literatura para observar que
el comportamiento electoral está afectado por una enorme variedad de
factores. Estos incluyen cosas como la ideología [@jessee2012;
@albertos2002; @rivero2015] o la identidad partidista [@bartels2000]
que tienden a ser estables [@green1994]; o la percepción de las
condiciones económicas [@fraile2005; @fraile2010] y el conocimiento o
valoración de los líderes [@wlezien1997; @maravall1999] que son más
variables. A éstas habría que añadir factores sociodemográficos como
la edad, la clase social, la renta familiar, también asociadas con la
decisión de voto, generalmente a través de su impacto en la
representación [@polavieja2001; @cainzos2001]. La literatura es
inmensa y unas pocas citas no hacen justicia a su extensión y
profundidad pero la idea fundamental es que los analistas pueden usar
una serie de regularidades bien documentadas para hacer supuestos
razonables sobre los votantes que no se han decidido.

Al mismo tiempo, la literatura académica no nos ofrece mucha
información sobre cómo traducir estos resultados para su uso para la
imputación de preferencias partidistas -- en buena medida porque su
interés está en el efecto (potentialmente causal) de diferentes
variables. Sin embargo, igual que antes, una aproximación predictiva
es potencialmente útil. Este tipo de problema es similar al del caso
de microtargetting [@nielsen2012ground; @issenberg2013;
@nickerson2014] en el que este tipo de técnicas son comunes. Por otra,
igual que en la sección anterior, nuestro objetivo es escoger la mejor
decisión para cada individuo independientemente de sus razones.

Un mayor problema en este caso es el caso de aquellos que identifican
incorrectamente sus preferencias en la encuesta. Este problema suele
ser el primero que el público indica en conversacion casual sobre
investigación electoral. Aunque es importante tenerlo en cuenta,
tampoco debemos exagerar su impacto. Tal y como dice @sturgis2016:
"There is [...] no reason to assume that embarrassment about admitting
support for a particular party should lead respondents to tell
pollsters they intend to vote for a different party; respondents could
also select the Don't Know, or refuse options." Es mucho más probable
que el problema sea uno de no-repuesta diferencial [@gelman2016][^3]
en el que determinados votantes prefieren no participar en la encuesta
[@sturgis2016; @aapor2016]. Dado el diseño de la encuesta, esto es un
problam mucho mayor y menor posibilidad de solución. Por decirlo de
otro modo, el problema no es que estos votantes no indiquen su
intención real (camuflándola bajo otra eleccion o ocultándose bajo la
opción no sabe ) sino que no participan en la encuesta.

Al mismo tiempo, podemos encontrar pistas en la literatura sobre datos
incompletos en ciencias sociales. por ejemplo, sabemos que votantes de
mayor edad, mujeres y individuos de menor educación tienen mayor tasas
de no-respuesta en general [@krosnick2002]. Además, @voogt2003 indica
que gente con baja confianza en el gobierno y las instituciones ---
una actitud probablemente relacionada con ciertas preferencias
politíca -- tiene también la probdadilidad de mostrar alta
no-respuesta.

En nuestro caso, adoptamos el mismo modelo que antes, pero en este
caso modelizando la probabilidad de votar a cada uno de los partidos.
La figura [-@fig:confusion-voteintention] muestra la matriz de
confusión 

![Confusion matrix for the vote choice model](./img/confusion_matrix-partychoice.pdf){#fig:confusion-voteintention width=70%}

The reported intended behavior is shown in the rows and the
predictions for each case, in the columns. It is readily seen that the
model achieves a high performance with an overall accuracy of about
91%. This high accuracy reflects the fact that the survey instrument
was designed to include many items that are strongly associated with
intended behavior, as discussed in section [-@sec:data]. Moreover, the
confusion matrix implies Cohen's $\kappa$ of 0.892, which is evidence
that the model performs well for both big and small parties.

# Ponderación de los resultados electorales {#sec:weighting}

Los errores en las encuestas en 2015 y 2016 en Estados Unidos y el
Reino Unido empezarn una revisión más sistemática de los métodos de
ponderación utilizados por las casas de encuestas. La ponderación de
las encuestas de opinión no es una tarea sencilla y no existe un
método obvio para corregir algunos de los sesgos de no-participación
más frecuentes. Los problemas dependen de elementos técnicos de la
encuesta pero en todos los casos el problema es siempre el mismo: que
hay un tipo de posible votante que no está correctamente representado
en la encuesta bien porque no es reachable o bien porque declina
participar. En el contexto de encuestas de opinión pública, es
frecuente hacer ajustes mediante ponderación para corregir estas tasas
diferenciales de particiáción entre grups. Por ejemplo, entrevistados
mas jóvenes, con menores niveles de educación o minorías
[@battaglia2008; @chang2009] son menos proclives a participar en
encuestas. Una revisión de estrategias está disponible en
@elliott2017.

La solución nunca es sencilla. En palabras de @gelman2007: "[s]urvey
weighting is a mess." Es ilustrativo que cuatro encuestadores
profesionales usando los mismos datos obtuviesen estimaciones
nacionales de voto para la elección presidencial de 2016 aue estaban a
más de 4% de diferencia de ellos. [@cohen2016].

El problema se agrava porque, como decíamos antes, es probable que
muchos entrevistados sobreestimen su probabilidad de votar. Filtros
como los suelen ser útiles pero ajustes por voto pasado, para ajustar
la distribución de recuerdo de voto en la encuesta con los resultados
electorales reales, suelen ser recomendables. La práctica es razonable
además por la estrecha relación entre voto pasado y voto futuro aunque
no está exenta de críticas [@durand2015] y potenciales problemas
[@escobar2014]. @blumenthal2013 discuss how different pollsters use
these variables. Uno de ellos es que el voto pasado es difícil de
medir: es un evento que ocurre a gran distancia temporal y que puede
ser difícil de recordar, que además puede estar sesgado por los mismos
motivos que la intención de voto.

## Estimar voto pasado {#sec:pastvote}

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
@schmitt2015]. 

Con esto en cuenta, en la encuesta estimamos voto pasado y ponderamos
para ajustar a la distribución observada. 

# Asignación de escaños {#sec:seats}

Los pasos anteriores nos permiten una aproximación a la intención de
voto latente en la encuesta. El paso natural siguiente consiste en
traducir estas proporciones de voto a escaños en el Parlament. La
tarea es sencilla si tenemos las proporciones de voto para cada una de
las circunscripciones en las que se eligen diputados: en ese caso solo
tendremos que aplicar las reglas del reparto de escaños a los
resultados estimados en cada circunscripción teniendo en cuenta la
incertidumbre asociada a nuestras estimaciones.[^7] Para cada partido
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
aportada por el investigador.[^8] Una fuente razonable de información
adicional es, por ejemplo, la distribución de voto en elecciones
anteriores o, mejor aún, la distribución de voto _relativa_ en cada
circunscripción con respecto al total en Cataluña. El analista,
dispone de un parámetro para escoger en qué medida los resultados
deben guiarse más o menos por esta información previa. 

# Conclusions {#sec:conclusions}

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

\newpage

# Bibliography

<div id="refs"></div>

\newpage

\appendix

# Appendix: XGBoost

The predictive models I use here are based on the idea of _boosting._
An accessible introduction to boosting can be found in @friedman2001.
Specifically, I use XGBoost[^1], a "scalable end-to-end tree boosting
system" [@chen2016] that has been shown to perform well in many
domains although it is notoriously difficult to interpret. XGBoost,
which can be seen as an efficient implementation of GBM or Gradient
Boosting Machines, belongs to a class of models that combines a number
of "weak" learners---here very shallow trees---into a "strong" learner
with high predictive performance. XGBoost builds a large sequence of
trees in which, at each step a regression or classification tree is
fit to data that has been weighted by the residuals from previous
steps. Through this process, XGBoost builds an ensemble of trees that
achieves low generalization error by iteratively upweighting
observations that were harder to classify by the preceding history of
trees.

XGBoost, like any machine learning model, includes a number of
hyperparameters that need to be tuned to ensure that the model does
not overfit the data and that, consequently, generalizes well to
other, unseen datasets---in other words, that it captures a
non-spurious relation between input (the _independent variables_ or
_covariates_ in statistical modeling parlance, or _features_ as they
are commonly called in the machine learning literature) and output
(_dependent variable_ or _outcome_). In this case, I tuned the maximum
depth of each of the trees, the total number of trees in the sequence,
and the penalization for each subsequent tree.


An additional advantage of XGBoost, stemming from the fact that it is
a tree-based method, is that it very naturally deals with missing
values in the covariates without a dedicated imputation step through
surrogate splits. Other machine learning models could have been used,
especially penalized linear models, like elastic net, and experience
dictates that the performance will likely be similar --and they would
probably be more familiar to technical audiences and easier to
understand for non-technical ones. Because the task is predictive in
nature, I disregarded methods based on null-hypothesis testing, such
as vanilla logistic regression-like models even in combination with
step-wise variation selection methods. However, the model itself is
not as important as an adequate framework to ensure the validity of
the inferences, especially in a context in which analysts usually need
to work using untested assumptions---which here correspond to
cross-validation and the bias-variance trade-off in machine learning.

For each of the outcome variables, I followed the same procedure. I
first selected the cases for which each of the outcome variables were
known. The goal is to use this subsample to learn a relation between
covariates and outcome that can be used for the cases where expected
and past voting behavior is not known. From these known cases, I then
set aside 20% of the cases as test sample and used 5-fold
cross-validation to select the optimal combination of hyperparameters.
The sizes of the training sets are shown in Table
[-@tbl:training-sizes]

[^1]: Some scholars have approached the problem from the perspective
of estimating results and therefore they have favored
wisdom-of-the-crowd approaches, like @rothschild2011, who suggests
using the probe "Regardless of who you plan to vote for, who do you
think will win the upcoming election?" However this approach, although
fruitful, does not help us with the estimation of the quantities we
are mainly interested in, like vote share.

<!-- [^2]: Compare with @druckman2004, @jacobson2015, or @iyengar2000. -->

[^3]: Interestingly, @aapor2016 does not report big effects of
    differential nonresponse, although the question they pose is about
    systematic nonresponse on one side.

[^4]: @groves2006 argues that response rates and bias are not
    necessarity correlated. See a discussion in @brick2017.

[^6]: A number of experiments have tried to reduce the social
    desirability pressure from the past turnout questions, although
    with limited success [@abelson1992; @holbrook2010; @hanmer2017].

[^7]: Esto es lo que hace el paquete `escons`:

[^8]: Este método está implementado en el paquete `dshare`.
