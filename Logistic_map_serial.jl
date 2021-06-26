using BenchmarkTools
using Plots

f(x, p) = p*x*(one(x)-x)

function calc_attractor!(out, f, p, num_attract, warmup)

    x = 0.25
    for i in 1:warmup
        x = f(x, p)
    end
    @inbounds out[1] = x

    @inbounds for i in 1:num_attract-1
        out[i+1] = f(out[i], p)
    end
end

x₀ = 0.25
out = Vector{typeof(x₀)}(undef, 150)
out[1] = x₀
@btime calc_attractor!(out, f, 2.9, 150, 400)

@code_llvm calc_attractor!(out, f, 2.9, 150, 400)
@code_warntype calc_attractor!(out, f, 2.9, 150, 400)



function bifurcation_data!(data, f, r, n_cols)

    for i in 1:n_cols
        calc_attractor!(@view(data[:, i]), f, r[i], 150, 400)
    end
end

r = 2.9:0.001:4
n_cols = length(r)
n_rows = 150
pl_data = Array{Float64}(undef, n_rows, n_cols)
pl_data[1, :] .= 0.25
@btime bifurcation_data!(pl_data, f, r, n_cols)

p = plot(xlims=(2.9,4), ylims=(0, 1), title="Bifurcation Plot", label=false)
for i in 1:n_rows
    scatter!(r, pl_data[i, :], label=false, color=:black, alpha=0.1)
end
p
