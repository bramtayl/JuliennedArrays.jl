import JuliennedArrays
using Documenter: makedocs, deploydocs

root = joinpath(dirname(@__DIR__), "docs")

makedocs(
    modules = [JuliennedArrays],
    sitename = "JuliennedArrays.jl",
    root = root,
    strict = true
)

deploydocs(
    repo = "github.com/bramtayl/JuliennedArrays.jl.git",
    root = root
)
