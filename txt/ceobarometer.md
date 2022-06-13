# Introduction  {#sec:introduction}

@rogers2011 encuentran que, en el caso de Estados Unidos, entre un 13%
y 54% de la gente que dice que va a votar no lo hace. Quizás más
sorprendente que entre un 29% y un 55% de los que dicen que _no_ van a
votar sí lo hagan finalmente. Estos números están ligados a un
contexto institucional muy específico y uno debe ser cuidadoso con
hacer extrapolaciones a otros casos pero ilustran las dificultades
para el uso de encuestas para la predicción electoral.

Los entrevistados no pueden predecir lo que ocurrirá el día de las
eleccione: quizás aparezcan contigencias de última hora que les
impidan ir a las urnas o puede que simplemente cambien de vista sobre
los candidatos. En la interpretación de encuestas electorales uno debe
por tanto pensar que la intención declarada intenta capturar una
_disposición_ y no un comportamiento futuro[^5]. No hay mucho que
podamos hacer sobre esto: no estamos en mejor posición que los
entrevistados para estimar si votarán y por quién. 

Sin embargo, sí podemos usar información en la encuesta para hacer
inferencias razonables sobre cada entrevistado y sobre la muestra en
su conjunto. Regularidades en las actitudes de los entrevistados --
gente que responde de forma similar, se comporta de forma similar -- y
supuestos sobre la consistencia internal de las respuestas -- gente
que se declara de derechas es más probable que vote a partidos de
derechas -- nos permiten estimar, para cada entrevistado, que opción
escogerían (votar o no votar y, si votan, por quién) incluso aunque no
podamos saber si efectivamente lo harán al final. 

Es una forma de decir que a lo que el proceso aspira es a seguir las
decisiones que el individuo es más razonable que tome incluso si
finalmente haya otros factores que decidan su comportamiento final.
Por decirlo de otro modo, el objetivo es proveer de la mejor
estimación posible del estado actual de las preferencias de los
ciudadanos -- y no sobre que harán en un futuro. 

In this article, we discuss the use of a predictive modeling approach
to estimate likelihood of voting (for every respondent in the sample),
vote choice (for non-reporters), and past vote (for non-reporters), as
an alternative to deterministic, rule-based models. As I argue below,
a probabilistic approach offers two advantages. First, it allows the
analyst to exploit additional information available in the data, which
can then provide a fuller, richer view of electoral behavior compared
to rule-based imputation. Second, as a data-driven model, it gives
analysts a way of contrasting and inspecting their intuitions in the
light of regularities sustained by data. It is thus similar to what
has been suggested in literature on political microtargeting
[@hersh2015; @endres2017]. 

Con esto en mente, el objetivo de los pasos siguientes es asignar a
cada individuo una preferencia de voto (si votarán y por quién). En
buena medida son gente que declara no saberlo todavía (SECCION). Para
utilizar estas figuras, deberemos tener en cuenta que la participación
en la encuesta está a veces motivada por partido al que votaron en el
pasado (SECCION). Finalmente, para extrapolar consecuencias
institucionales de los resultados, asignaresmos a los resultados
electorales de la encuesta diferentes resultaados de seats en el
parlamento (SECCION). Para ello, tendremos que asignar primero
porcentajes de voto a cadar provincia (SECCION).

## El modelo de comportamiento electoral {#sec:vote-choice}

La decisión más improtante en el proceso es la de asignar a cada
entrevistado la opción de voto más probable para aquellos que dicen no
saber qué harán.[^1] No es sorprendente que las encuestas
pre-electorales sean más predictivas a medida que nos acercamos al día
de las elecciones ya que la mayor parte de la gente solidifica sus
decisiones en el último momento posible [@crespi1988]. La pregunta
clave para nosotroes es, podemos hacer inferencias razonables sobre
comportamiento esperado de aquellos que han preferido no expresar
todavía una preferencia electoral en la encuesta?

Una revisión rápida de la literatura muestra que el comportamiento
electoral está afectado por una enorme variedad de factores
atitudinales como la ideología [@jessee2012; @albertos2002;
@rivero2015] o la identidad partidista [@bartels2000] que tienden a
ser estables [@green1994]; o la percepción de las condiciones
económicas [@fraile2005; @fraile2010], o conocimiento o valoración de
los líderes [@wlezien1997; @maravall1999]. Factores sociodemográficos
como la edad, la clase social, la renta familiar, son tambien
correlatos conocidos de la elección partidista en tanto que aproximan
atributos que importan a grupos en términos de representación
[@polavieja2001; @cainzos2001]. Incluso para votantes con poco interés
por la política podemos hacer inferencias razonables de los sesgos que
dominarán el día de las elecciones [@delacalle2010]. La literura es
inmensa y unas pocas citas no hacen justicia pero la idea fundamental
es que los analistas pueden usar una serie de regularidades bien
documentadas para hacer supuestos razonables sobre los votantes que no
se han decidido.

Esta disucsión sugiere el uso de modelos multivariddos. Por desgracia,
la litartura académica no nos da mucha información sobre cómo hacer
ese modelado ya que ha estado interesado en el efecto (potencialmente
causal) de diferntes variables. El problema de asignar preferencias a
votantes potenciales aparece en el caso de microtargetting con más
claridad [@nielsen2012ground; @issenberg2013; @nickerson2014]. Sin
embargo, en ese caso, el problema es que esta litartura está centrada
en el caso de estados unidos y suele usar mucha información adicional
que no está disponible en españa [@hersh2015hacking; @endres2017].

Al mismo tiempo, podemos encontrar pistas en la literatura sobre datos
incompletos en ciencias sociales. por ejemplo, sabemos que votantes de
mayor edad, mujeres y individuos de menor educación tienen mayor tasas
de no-respuesta en general [@krosnick2002]. Además, @voogt2003 indica
que gente con baja confianza en el gobierno y las instituciones ---
una actitud probablemente relacionada con ciertas preferencias
politíca -- tiene también la probdadilidad de mostrar alta no-respuesta.

Es importante reiterar aquí la limitación fundamnetal del projecto.
Algunos entrevistados cambiarán de opinión antes de las elecciones y,
en el mejor de los casos, lo que podemos ofrecer es una aproximación
imperfecta dada por la información disponible en la encuesta. Si esto
es un pboema depende, en última instancia del objeto de la
investigación. Si estamos intereados en _nowcasting_, en estimar el
estado de la opinión pública en el momento de la encuesta, los cambios
en las preferencias a lo largo de las campañas o durante el ciclo
político son _precisamente_ el objeto de nuestra atención. 

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

En nuestro caso, adoptamos el mismo modelo 

![Confusion matrix for the vote choice model](./img/confusion_matrix-partychoice.pdf){#fig:confusion-voteintention width=70%}

Figure [-@fig:confusion-voteintention] shows the confusion matrix
resulting from applying the model to a test set containing 20% of the
observations. The reported intended behavior is shown in the rows and
the predictions for each case, in the columns. It is readily seen that
the model achieves a high performance with an overall accuracy of
about 91%. This high accuracy reflects the fact that the survey
instrument was designed to include many items that are strongly
associated with intended behavior, as discussed in section
[-@sec:data]. Moreover, the confusion matrix implies Cohen's $\kappa$
of 0.892, which is evidence that the model performs well for both big
and small parties.

El model corresponde con simpatía. 

## Estimar la decisión de votar o no {#sec:vote-propensity}

Uno de los problemas mejor documentados en la literatura es que los
entrevistados tienden a sobreestimar su probabilidad de votar. Pero
algunos lo hacen más que otros. Usando la noción de que el acto de
votar es algo socialmente sancionado [@holbrook2010], @bernstein2001 o
@hanmer2017 sugieren que la motivación de reportar alineamiento con
expectativas sociales es intrínsica. Por decirlo de otra forma, la
deseabilidad social afecta "people who are under the most pressure to
vote," [@bernstein2001] or "people who think of themselves as voters"
[@hanmer2017]. Esta es una motivación de muchas otras posibles que
habla de que hay subgrupos de votantes que son más probables de
overreportar un comportamiento -- en este caso, aquellos que se ven
como más procivles a seguir virtudes cívicas como aquellos de mayor
edad o mayor educación, o incluso con mayor interés por la política
[@hanmer2017; @ansolabehere2017].[^6] Por decirlo de otra manera, es
un comportamiento sobre el que podemos hacer cierta mella con la
información en la encuesta.

Por supuesto, una solución al problema está, como siempre, en mejorar
cómo preguntamos y en cómo usar esa información. En este sentido el
trabajo de @perry1979 es particularmente influyente (véase @voss1995 o
@sturgis2016) como fundación de una _batería_ de preguntas sobre
comportamiento que pueden ser usadas para adelantar si el votante
tiene intención real te votar [CUALES SON]. Sin embargo, la discusión
no está cerrada y evaluaciones empíricas de las baterias basadas en
@perry1979 [@dimock2001] arrojan una diversidad de resultados.
Experiencias como la de ANES muestran que variaiones sobre las
preguntas tienen en realidad poco efecto -- las actitudes que llevan a
sobrerreporportar voto son muy robustas. 

Una cuestión sobre la que puede hacerse trabajo, sin embargo es con el
uso de las preguntas. Como indica [@sturgis2016], el problema es en el
uso de la información. Por ejemplo, si preguntamos sobre la
"probabilidad" de ir a votar en una escala en 10 puntos, qué valor
usar como barrera para decidir si el votante irá a las urnas o no? 

Se abren aquí dos posibilidades. Una es el uso de mecanismos
deterministas que a cada votante asigne una decisión basada en
información pasada o conocimiento del investigador. Tal y como dice
@sturgis2016, el problema es que suele basarse en reglas con poca base
empírica. Otra es en el uso de aproximiaciones probabilísticas que
modelen el comportamiento reportado en una o varias preguntas. Esta
aproximación tiene un linaje extenso. Ya al principio d ela
invesgaición, los investigadores han tratado de agregar preguntas
[@traugott1984] o estimar una probabilildada de votar a nnivel
individual [@petrocik1991]. La información que está disponible, como
aludíamos antes, va más allá de la batería de voto y puede depender de
informadción sociodemográfica. Para una aproximación moderna véase
@malchow2008, @murray2009, or @rusch2013.

En este caso adoptamos un modelo predictivo dadas las liminaciones de
trabajar con una única encuesta. En primer lugar, es una aproximación
que puede capturar mejor la decisión de los votantes en relación a la
información disponible en los datos. Usando un modelo al nivel del
inviduo, el analista puede entender major los factores que llevan a la
decisión de participar. Como consequiencia, el modelo pone en manos
del analista una herramienta para diagnosticar y reevaluar
expectativas comunes en análisis electoral. Segundo, una aproximación
que produce probabilidades para cada individuo ofrece la posibilidad
de cuantificar la sensibilidad de las estimaciones a diferentes
supuestos de particiación total.

En el caso de nuestro modelo...

![Confusion matrix for the vote choice model](./img/roc-abstention.pdf){#fig:roc width=70%}

## Weighting political surveys {#sec:weighting}

The polling misses of 2015 and 2016 in the U.S. and the U.K. sparked a
review of the weighting methods used by polling houses. Weighting of
public opinion polls is a hard task and no obvious method exist for
correcting some of the biases listed above. As @gelman2007 succintly
puts it "[s]urvey weighting is a mess." It is illustrative that four
professional pollsters using the same dataset could make estimates at
the national level in the 2016 U.S. Presidential elections that were
4% apart [@cohen2016].

Weighting is commonly used to address two separate concerns
[@voss1995], which depend on the sampling procedure. First,
participation in the survey may be correlated with variables of
interest. For instance, adults with poor health may be less likely to
participate in studies about medical expenditures due to the burden
imposed by the survey instrument. In that case, weighting by the
overall health of the individual, _if we had access to this variable,_
corrects the survey estimates. In the context of public opinion
polling, many pollsters adjust their raw results to population
benchmarks because of differential rates of participation for various
subgroups. For instance, young respondents, with low levels of
education, and minorities [@battaglia2008; @chang2009] are less likely
to cooperate in surveys. Fortunately, @dimock2013 and @aapor2016 show
evidence that partisan leaning does not seem to affect the decision to
participate in polls.

The problem seems easy _prima facie_ but it is complicated by the fact
that many opinion polls are either nonprobability quota samples or
have low response rates[^4]. In both cases, correction of nonresponse
without hard evidence on who is more likely to not cooperate with the
survey makes the problem one about knowing which variables should be
used for correction. It is worth noting that quota sampling ignoring
cooperation rates does to solve the bias issue [@sturgis2016]. A
recent review of strategies is available @elliott2017.

The second issue that weighting addresses is that respondents tend to
overreport their likelihood to vote. Screeners for likely voters are
common, especially in the last few weeks before election day, but
typically further corrections by the inverse of turnout probability
are necessary [@sturgis2016]. Adjustments by estimates by the past
vote share seems to be country specific practice. The practice seems
well grounded, as it addreses potentially both concerns. On the one
hand, we are weighing down overreporters to well known population
values. On the other, past behavior may be useful to correct future
behavior. However, the practive of weighting by past vote has been
criticized on a number of practical grounds [@durand2015].
@escobar2014, for the Spanish case, finds that it only improves
prediction in elections in which the incumbent wins.

However, the practice underpins on a number of troublesome
assumptions. First, that voters report their past voting behavior
truthfully. True, the assumption of truthfulness pervades the whole
enterprise of survey data analysis, but we know that distant behavior
is hard to recall and voters show a tendency to report voting for the
incumbent party. Second, and more problematic, the practice implicitly
assumes that some type of voters are overrepresented in the sample
which speaks about nonresponse bias. Third, weighting by past vote
forces us to reweight the demographic composition of the sample to
match the sampling quotas.

### Recovering past vote {#sec:pastvote}

In this category of misreporting we also have the evidence of
"bandwagoning" [@nadeau1993; @schmitt2015] with respondents
disproportionately recalling having voted for the winning party.

Past turnout and past vote choice are relevant because they can be
used to both estimate future behavior and also to benchmark surveys
based on observed results from previous elections (see Section
-@sec:weighting). @blumenthal2013 discuss how different pollsters use
these variables.

Reports of past turnout are affected by the same factors that I
described for the case of _expected_ turnout, with some
particularities. It is a commonly reported result in the U.S.
literature that respondents overreport their past turnout. For
instance, @mcdonald2007 show that elections with turnouts of 50% can
have surveys with a 70 to 90% of respondents reporting having voted.
By no means this is an American phenomenon [@karp2005; @selb2013].
@selb2013 report that sample turnout in surveys virtually always
exceed official turnout using data from 128 postelection studies in 43
countries.

The consistently upward bias should be sufficient proof that
overreporting cannot simply be attributed to poor respondent recall
[@ansolabehere2017]. @ansolabehere2017 elaborate on potential
arguments that explain turnout overreporting. A common, and worrisome
explanation, is that the overestimation of turnout in public opinion
surveys is due to sample selection bias and not only to missreporting.
As @sciarini2016 note, "responding to a survey about politics and
misreporting on turnout are likely to be driven by similar factors"
and, in fact, @burden2000 shows that higher reluctance to
participating in the National Election Study is indeed associated with
a smaller propensity to vote. In that case, the difference between
reported turnout between public opinion surveys and the observed
turnout from past electoral results reflects differential
participation rates between voters and non-voters.

El model obviamente funciona peor ya que depende de mucha menos
información. Sin embargo, es mucho más preciso que . 

La ponderación a voto pasado es mediate poststratafificación alos
resultados reales después de agrupar los partidos. 

# Escaños

El Sistema 

# Conclusions {#sec:conclusions}

The current approach also comes with a number of limitations. Some of
them are the result of the questionnaire not being designed for the
type of applications that I suggested here. For instance, the
performance likely voter model could be improved with access to a
richer battery of screener questions. Instead, the models had to rely
to one response category in the vote intention question. Similarly,
changes to the design of the questionnaire in different field
iterations make it difficult to identify an ideal common set of
variables that can be used throughout a long span of time.

More generally, it can be argued that the ideal situation would be one
in which the questionnaire structure could be adapted to make better
use of predictive models. For instance, an inspection of the
systematic errors that the models may be making could inform the
redesign of the survey instrument. The difficulties that the models
above face when trying to classify voters from the smaller parties is
an illustration of the kind of items that could be added to the
instrument.

The most important limitation is that the approach suggested here
relies on an analogy assumption between voters and non-voters. In
practice, it means that non-reporters in the sample are similar to
those who do report their voting preference and that therefore
information about how reporters behavior can be used to make
predictions about non-reporters. The assumption is by no means
exclusive of a predictive approach but it does become more obvious
within this framework.

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

[^5]: In fact, @morwitz1996, @mann2005 and @heij2011 even
argue that participating in the survey changes the likelihood of
voting for respondents, although the evidence seems to be weak at
least.

[^6]: A number of experiments have tried to reduce the social
desirability pressure from the past turnout questions, although with
limited success [@abelson1992; @holbrook2010; @hanmer2017].

