using Documenter: makedocs, deploydocs
import JuliennedArrays

makedocs(
    modules = [JuliennedArrays],
    sitename = "JuliennedArrays.jl",
    strict = true
)

deploydocs(
    repo = "github.com/bramtayl/JuliennedArrays.jl.git",
)
