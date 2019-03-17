using Documenter, JuliennedArrays

makedocs(
    modules = JuliennedArrays,
    checkdocs = :exports,
    sitename = "JuliennedArrays.jl",
    pages = Any["index.md"],
    strict = true
)

deploydocs(
    repo = "github.com/bramtayl/JuliennedArrays.jl.git",
)
