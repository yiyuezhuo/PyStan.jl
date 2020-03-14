module PyStan

export StanModel, sampling

using PyCall
using Distributed

const pystan = PyNULL()
const arviz = PyNULL()
const xr = PyNULL()
const pickle = PyNULL()

const StanModel = PyNULL()


function __init__()
    copy!(pystan, pyimport_conda("pystan", "pystan"))
    copy!(arviz, pyimport_conda("arviz", "arviz"))
    copy!(xr, pyimport_conda("xarray", "xarray"))
    copy!(pickle, pyimport("pickle"))

    copy!(StanModel, pystan.StanModel)
end


function sampling(sm ;chains, kwargs...)
    future_list = Vector()
    for i in 1:chains
        fit_future = @spawnat :any sm.sampling(;chains=1, kwargs...)
        push!(future_list, fit_future)
    end

    infer_list = Vector()
    for fit_future in future_list
        fit = fetch(fit_future)
        infer = arviz.from_pystan(fit)
        push!(infer_list, infer)
    end

    merged_dict = Dict()
    for group in infer_list[1]._groups
        merged = xr.concat([getproperty(infer, group) for infer in infer_list], "chain")
        for i in 0:(chains-1)
            set!(getproperty(merged.chain, "values"), i, i)
        end
        merged_dict[group] = merged
    end

    kw = Dict(Symbol(key) => value for (key, value) in merged_dict)
    infer_merged = arviz.InferenceData(;kw...)
    return infer_merged

end

function dump_model(sm, path::String)
    @pywith pybuiltin("open")(path, "wb") as f begin
        pickle.dump(sm, f)
    end
end

function load_model(path::String)
    sm = nothing
    @pywith pybuiltin("open")(path, "rb") as f begin
        sm = pickle.load(f)
    end
    return sm
end

end # module
