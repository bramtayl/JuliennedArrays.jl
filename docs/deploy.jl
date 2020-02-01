using Pkg: instantiate
instantiate()

@static if VERSION == v"1.3"
    instantiate()

    using JuliennedArrays
    using Documenter: deploydocs, makedocs

    makedocs(sitename = "JuliennedArrays.jl", modules = [JuliennedArrays], doctest = false)
    deploydocs(repo = "github.com/bramtayl/JuliennedArrays.jl.git")
end
