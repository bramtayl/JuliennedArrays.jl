using Pkg: develop, instantiate, PackageSpec
develop(PackageSpec(path=pwd()))
instantiate()

using JuliennedArrays
using Documenter: deploydocs, makedocs

makedocs(sitename = "JuliennedArrays.jl", modules = [JuliennedArrays], doctest = false)
deploydocs(repo = "github.com/bramtayl/JuliennedArrays.jl.git")
