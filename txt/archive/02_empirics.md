# Data and methods {#sec:data}

## Data

I use data from the study 3242 from the Centro de Investigaciones
Sociológicas (CIS), a pre-electoral study about the Legislative
Elections of April 2019 with 16,194 face-to-face interviews (out of
16,460 planned). The data was collected using two-stage sampling
("municipios" and "distrito censal") proportional to size and
stratified by the interaction of Autonomous Community and population
size, with final sampling units selected via quotas on age and gender.
The number of collected interviews per Autonomous Community ranges
between approximately 100 in Ceuta and Melilla to 2,755 in Andalucía.
The sample design allows for the estimation of quantities of interest
down to the level of the province---the electoral district for the
_Congreso de los Diputados,_ the Spanish Lower Chamber. However, in
the reminder of this section, I will not use case weights and focus
instead on predictive ability of models at the individual level as
opposed to the estimation of vote shares.

The CIS makes anonymized microdata publicly available soon after data
collection. The survey instrument rotates a number of questions
although the basic wording of the questions and structure of the
interview remain fairly stable. Study 3242 contains evaluation items
for the political and economic context, retrospective evaluation items
for each of the parties with parliamentary representation, a battery
of questions related to vote intention, and a sociodemographic profile
of the respondent---which includes questions age, education,
employment status, occupation, and religion. The instrument asks for
past and intended turnout (in a 1 to 10 scale), evaluation of the
party leaders, placement of each party in an ideological scale (along
with self-placement), and two questions for vote intention: one asking
for the party for respondent will vote for and another asking for a
probability of voting for each of the main parties. The instrument
also includes three questions to measure "proximity" (_Which party is
the closest to your own political ideas?_), expectations about
electoral results (_Which party do you think will win?_) and
preference (_And which party would you like it to win?_) as well as a
question about which party candidate the respondent would like to see
as President of the Government.

Being a pre-electoral study, the instrument favors the measurement of
attributes that can be used for vote share estimation and illustrates
well the design challenges of survey designers. The attention of
respondents is a precious commodity. Asking more questions that
obviously probe the same behavior could help better elicit vote
intention but it also risks disengaging respondents with a more
tedious and repetitive instrument. The question for the designer is
thus about the marginal value and cost of each question. In other
words, among all the potential questions that can be included to make
a reasonable conjecture about what voters will do, what is smallest
subset with the best predictive power? In that regard, we can see the
analyses below as a way of addressing this question. 

With that in mind, I used in the models below the vast majority of the
items available in the instrument. The main exceptions correspond to
questions about the main problem affecting Spain and the main problem
affecting the respondent at the moment (because they are asked in an
awkward semi-open ranking format with 15 closed categories), a
question about media consumption (also asked as a rank) and the
qualitative self-categorization into ideological families. All
remaining items were preserved with minimal recodes.
 
## Methods 

I am interested in the prediction of three different outputs: turnout
and vote choice for all respondents and past vote choice for the
respondents who reported voting in the past election. All three
variables, as indicated in Section [-@sec:literature] correspond to
attributes that analysts often need to impute to create vote share and
seat estimates.

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

Outcome         Training size 
-------        --------------
Vote intention          7,028 
Turnout                12,751 
Past vote               9,736 

Table: Sizes of each the training sets {#tbl:training-sizes}

For each of the outcome variables, I followed the same procedure. I
first selected the cases for which each of the outcome variables were
known. The goal is to use this subsample to learn a relation between
covariates and outcome that can be used for the cases where expected
and past voting behavior is not known. From these known cases, I then
set aside 20% of the cases as test sample and used 5-fold
cross-validation to select the optimal combination of hyperparameters.
The sizes of the training sets are shown in Table
[-@tbl:training-sizes]

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

# Results {#sec:results}

## Model for vote intention {#sec:voting}

Before discussing what the model has captured it is improtant to make
sure it is a good model. 

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

<!-- ![Confusion matrix for the vote choice model](./img/confusion-voteintention.pdf){#fig:confusion-voteintention width=70%} -->

If we take a more detailed look at measures of performance by party
such as the class-specific _sensitivity_ (proportion of cases
predicted to vote for a given party that indeed intended to vote for
such party) and _specificity_ (proportion of cases predicted _not_ to
vote for a given party that indeed do not intend to vote for such
party) are also very high. We see, for instance, that the specificity
is above 98% for all parties, while the sensitivity breaks the 90%
threshold for PP, PSOE, Ciudadanos, or Vox. Smaller sensitivities
correspond appear in the smallest parties, like IU or PDeCat. In
addition, it also performs remarkably well for the "Other" category
(with a sensitivity of 75% and a specificity of 98%) in spite of
including parties of very different nature and ideology. 

It is also worth mentioning that the errors that the model makes are
sensible given the structure of the ideological competition in Spain,
even with the precaution that the cell values in the test set are too
small to make solid inferences. For instance, cases that report an
intention to vote for Podemos are more likely to be (mistakenly)
classified as PSOE or IU voters than as PP voters.Similarly, voters
that report an intention to vote for Ciudadanos are missclassified to
either PP or PSOE but not as often to Vox or Podemos, which are
further apart in the ideological scale. In other words, the model
captures what a voter with spatial preferences would do even though no
such information was explicitly provided.

Applying the model to the full dataset---including the cases for which
the vote intention is not known---gives us the expected vote share
(Table [-@tbl:vote-share]). In the first two columns, I show the
counts and vote share in the observed portion of the dataset, while
the last two report the counts and proportions implied by the model.
Although it is important to keep in mind that the model works under
the assumption of full turnout (see Section [-@sec:likely]), it is
interesting to note that the predicted distribution includes fewer
potential PSOE voters which may be taken as a correction of the
pro-incumbent bias among survey respondents that others have
documented in Spain (CITE) as well as in other countries (CITE). At
the same time, the model allocates a larger number of respondents to
the "Other" category which could very well be the result of including
voters with unclear partisan preferences that are also more likely to
abstain. For all other parties, the differences between observed and
predicted share are modest.

<!-- \input{./img/vote-share.tex} -->
             
The flexible non-parametric nature of this model gives us valuable
insights into the structure of the data that can be used both as a
sanity check for the predictions and the correctness of the model and
as a tool to evaluate some of the assumptions that are commonly made
in the development of voting models. For instance, Figure
[-@fig:varimp_voteintention] displays the variables with the highest
importance in the model. In this case, variable importance is defined
as the frequency with which a given variable is selected while
building a tree and can be understood as a measure of the contribution
of each variable to the final prediction.

<!-- ![Variable importance for the vote choice model](./img/varimp-voteintention.pdf){#fig:varimp_voteintention width=80%} -->

Two sets of predictors stand out in Figure
[-@fig:varimp_voteintention]. Unsurprisingly, the variables that are
ranked at the top are the subjective probability of voting for any of
the major parties, which in the instrument is asked for each party
using a 1 to 10 scale. A second group of questions are the short
batteries with evaluation items about the party leadership and the
past performance of the party in the Lower Chamber. The model also
selects the ideological self-placement of the respondent as well as
the perceived location of some of the major parties. Variable
importance in this model does not correspond to "relevance" in a
causal sense and there is no reason to expect these variables to have
a linear impact on the outcome. However, taken together the do tell a
story about COMPLETE.

In addition to the importance, it is possible to also explore the
marginal effect of the covariates included in the model using a
variety of tools. Figure [-@fig:partial_ideology] shows the partial
effect of the self-placement of respondents in the ideological scale,
which represents the effect of self-placement after integrating out
all the other features---and it is thus similar to the marginal effect
plots in classical models like a logistic regression. The model very
clearly recovers the spatial structure of party competition in Spain
with squiggly approximations to a single-peaked function that achieves
a maximum at reasonable locations for each of the parties---and indeed
all parties are correctly sorted, with Podemos on the left, followed
by PSOE, Ciudadanos, PP, and VOX on the right-end of the scale.

<!-- ![Partial effect of self-placement in the ideology scale](./img/partial-ideology.pdf){#fig:partial-ideology width=80%} -->

Figure [-@fig:shapley] takes a different view on the same idea and
plots the SHAP dependency plot for two relevant variables in common
models of voting behavior. In Figure [-@fig:shapley-context] we see
the effect of the evaluation by the respondent of the political and
economic context (larger values, more negative evaluations). We see
that there is a larger impact in the predictions through the
evaluations of the _political_ situation than through the evaluation
of the _economic_ situation which indirect evidence against the
prevalence of economic voting in the April elections---even if there
is considerable uncertainty for the most pessimistic evaluations.
Finally, in Figure [-@fig:shapley-pastvote], I show the effect of
having voted in the past for a given party in the probability of
voting again. It is noticeable that both Podemos, PSOE, and Ciudadanos
show some stickiness (voting for the party in the past increases the
probability of voting again) while the effect is null---or at least
uncertain---for the case of PP.

<!-- <div id="fig:shapley" class="subfigures">  -->
<!-- ![Contextual evaluation](./img/shapley-context.pdf){#fig:shapley-context width=50%} -->
<!-- ![Past voting behavior](./img/shapley-pastvote.pdf){#fig:shapley-pastvote width=50%} -->

<!-- Shapley dependency plots  -->
<!-- </div> -->

<!-- Finally, figure [-@fig:lime] shows LIME plots for two randomly -->
<!-- respondents who reported a vote intention for the PSOE and that the -->
<!-- model classified correctly (Figure [-@fig:lime-success]) or -->
<!-- incorrectly (Figure [-@fig:lime-error]). LIME, or "local interpretable -->
<!-- model-agnostic explanations"... -->

<!-- <div id="fig:lime" class="subfigures"> -->
<!-- ![Correctly predicted](./img/explanation-success.pdf){#fig:lime-success width=50%} -->
<!-- ![Incorrectly predicted](./img/explanation-error.pdf){#fig:lime-error width=50%} -->

<!-- LIME plots for correctly and incorrectly classified predictions -->
<!-- </div> -->

<!-- OVERALL  -->
<!-- ![Partial effect of self-placement in the ideology -->
<!-- scale](./img/comparative-sizes.pdf){#fig:comparative-sizes width=80%} -->

## Likely voter model

The second item is a _likely voter model_ to score individuals
according to their probability voting. I used here the same modeling
approach as in Section [-@sec:voting] using as outcome variable a
question asked to all respondents about the probability with which
they would turnout in the upcoming elections in a 0-10 ordered scale
(higher values representing higher probabilities). The comparison
between reported and predicted probabilities is shown in
[-@fig:probability-voting] where I included a $45^{\circ}$ line as
well as a linear model between the two variables. Two main
observations stand out. First the model is correctly calibrated in the
sense that the it does not systematically under- or overestimate the
probability of voting of any group. That said, most of the predictions
fall in the bottom of the scale (individuals reporting that will not
vote) and in the top three categories (individuals sure or almost sure
to vote). It indicates that while the instrument was designed to allow
respondents to express the nuances of their decision to participate,
in practice the model reads the data in a bimodal fashion, consistent
with a more traditional Yes-No formulation of the same question.

<!-- ![Turnout](./img/probability-voting.pdf){#fig:probability-voting width=75%} -->

On the other hand, the model learns the tendency to overreport (HOW TO
SHOW THIS?). In this case, and given the sampling method and survey
mode used to collect the data, it is not obvious whether the problem
corresponds to bias in the sample or bias in reporting.

Figure [-@fig:varimp-turnout] shows the most important variables.
Consistent with intuition, not having voted in the past shows the
largest effect together with not showing any sympathy for any of the
parties or an self-identification as someone who does not repeat vote
intention. All other variables, even if they have an impact in the
predictions, clearly lag behind. In other words, the model captures
abstention through disaffection, disinterest, and a learned behavior
of abstention.

<!-- ![Variable importance for the likely voter model](./img/varimp-turnout.pdf){#fig:varimp-turnout width=80%} -->

## Model for past behavior

As discussed in Section [-@sec:pastvote] the literature is split
regarding whether to use past voting behavior or turnout as weighting
variables given overreporting and bandwagon effects. In any case, from
the perspective of the predictive approach taken here, the allocation
of past voting behavior to respondents can follow the same structure
as above. For illustration purposes only, I show here the results of
estimating a predictive model on the question about the party for
which the respondent voted in the past General Elections. While the
model for vote intention in Section [-@sec:voting] achieved high
accuracy, the model using past behavior produces a more modest value
of 72% with a Cohen's $\kappa$ of 0.65. More importantly, while the
specificity is still high---above 90% for all parties with the
exception of the PSOE---, the sensitivity varies widely, with higher
values for PSOE (81.7) and PP (85.6) and low values for Ciudadanos
(55.3) or Podemos (67.1).

This low predictive power of the model for past behavior can be
interpreted in two different ways. On the one hand, it signals the
fact that we do not have the same rich attitudinal battery that we
have available for the prediction of vote intention. Past behavior is
included in the instrument as a single question and the model can only
try to associate it to the _current_ reported attitudes and
preferences of the voter. On the other, if individuals do report past
behavior to accommodate their current preferences---as opposed to what
they would have reported in the past---it is reasonable to expect that
the model will underperform. 

[^1]: I used the `xgboost` [@chen2018] R package through the `caret`
    [@kuhn2018] package.
