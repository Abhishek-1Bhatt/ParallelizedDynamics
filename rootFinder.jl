using Distributions, Calculus

function my_quantile(y, d; x=mean(d))
    # g = def_prob(d, y)
    g(x) = cdf(d, x) - (y/100)
    tol = eps(Float64) #tolerance value for isapprox
    while !isapprox(g(x), 0.0, atol=tol) #Applying Newton's Method
        x = x - (g(x)/derivative(g, x))
    end
    return x
end

my_quantile(67.0, Normal(0, 1))
quantile(Normal(0, 1), 0.67)

my_quantile(67.0, Beta(2, 4))
quantile(Beta(2, 4), 0.67)

my_quantile(67.0, Gamma(5, 1))
quantile(Gamma(5, 1), 0.67)

using BenchmarkTools

@btime my_quantile(67.0, Normal(0, 1))
@code_llvm my_quantile(22.0, Normal(0, 1))
