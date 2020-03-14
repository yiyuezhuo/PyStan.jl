![PyStan-CI](https://github.com/yiyuezhuo/PyStan.jl/workflows/PyStan-CI/badge.svg)

# Lightweight wrapper for PyStan using PyCall

`cmdstan` is hard to setup compared to `pystan` in Windows, so this package is made to provide a easier to use wrapper.

## Example

```julia

schools_code = """
data {
    int<lower=0> J; // number of schools
    vector[J] y; // estimated treatment effects
    vector<lower=0>[J] sigma; // s.e. of effect estimates
}
parameters {
    real mu;
    real<lower=0> tau;
    vector[J] eta;
}
transformed parameters {
    vector[J] theta;
    theta = mu + tau * eta;
}
model {
    eta ~ normal(0, 1);
    y ~ normal(theta, sigma);
}
"""

schools_dat = Dict(
    "J" => 8,
    "y" => [28,  8, -3,  7, -1,  1, 18, 12],
    "sigma" => [15, 10, 16, 11,  9, 11, 10, 18]
)

sm = StanModel(model_code=schools_code)
fit = sampling(sm, data=schools_dat, iter=1000, chains=4)

fit.posterior
#=
PyObject <xarray.Dataset>
Dimensions:      (chain: 4, draw: 500, eta_dim_0: 8, theta_dim_0: 8)
Coordinates:
  * draw         (draw) int32 0 1 2 3 4 5 6 7 ... 493 494 495 496 497 498 499
  * eta_dim_0    (eta_dim_0) int32 0 1 2 3 4 5 6 7
  * theta_dim_0  (theta_dim_0) int32 0 1 2 3 4 5 6 7
  * chain        (chain) int64 0 1 2 3
Data variables:
    mu           (chain, draw) float64 12.92 5.186 12.53 ... 4.598 8.408 5.86
    tau          (chain, draw) float64 0.6728 0.5625 0.7637 ... 12.65 4.333
    eta          (chain, draw, eta_dim_0) float64 -1.662 -1.183 ... 1.032 0.4642
    theta        (chain, draw, theta_dim_0) float64 11.8 12.12 ... 10.33 7.871
Attributes:
    created_at:                 2020-03-14T14:50:33.394853
    inference_library:          pystan
    inference_library_version:  2.19.0.0
=#

fit.posterior.mu.values
#=
4×500 Array{Float64,2}:
 12.9186    5.18576  12.5331    4.62249  16.7877   …  12.2608    1.88204   7.74253  11.3356
  2.58138   2.83618   8.32023   1.9223   22.366        1.51359   2.70711   2.62599   9.4167
  9.05396  10.295     7.39754   7.36052   6.70213      6.92809  11.7895   12.7297   -3.57764
  3.37523   8.50909  15.4496   16.1284   11.3801      10.8383    4.59811   8.40823   5.85974
=#

# Avoiding recompilation of Stan models 
PyStan.dump_model(sm, "test.pkl")
sm = PyStan.load_model("test.pkl")

```

## Why not just using `PyCall`?

`PyCall` seems not working for Python `multiprocessing`, at least on Windows, see this [issue](https://github.com/JuliaPy/PyCall.jl/issues/755). This mechanism is used by `PyStan` to support parallel sampling (`n_chains > 1`), hence I use Julia builtin parallel computing method to run some `n_chains = 1` tasks and merge them using `arviz`. Hope it will make usage a little easier.

## Pitfall

Since I use `arviz` to merge `PyStan` results. Raw `fit` object is not provided. The only limitation introduced may be extra dependency `arviz`, which is recommended method to merge multiple `fit` results, see this [post](https://discourse.mc-stan.org/t/combine-fit-objects/7262/3).

To enable true multi-processing, start Julia REPL with `julia -p num_workers`, ex, `julia -p 4`. But the present implementation may waste some memory compared to using PyStan from Python directly.