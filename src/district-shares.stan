data {
  int N; // number of observations
  int D; // number of districts
  int P;  // number of parties
  vector<lower=0,upper=1>[P] results[N];
  vector<lower=0,upper=1>[D] dummies[N];
  real<lower=0> weights[N];
  vector<lower=0>[P] a[D];
  vector<lower=0>[P] b[D];
}
parameters {
  simplex[P] beta[D];
  cov_matrix[P] sigma[D];
}
model {
  vector[P] mu[N,D];
  for (d in 1:D) {
    beta[d] ~ beta(a[d], b[d]);
      for (n in 1:N) {
        mu[n,d] = beta[d] * dummies[n][d];
        target += multi_normal_lpdf(results[n] | mu[n,d], sigma[d])*weights[n];
      }
  }
}
