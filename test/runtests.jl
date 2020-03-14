using Test
using PyStan

@testset "PyStanTestSet" begin
    @testset "compile model" begin
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

        PyStan.dump_model(sm, "test.pkl")
        sm2 = PyStan.load_model("test.pkl")
        fit2 = sampling(sm2, data=schools_dat, iter=1000, chains=5)

    end
end