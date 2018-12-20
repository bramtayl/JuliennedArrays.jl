using JuliennedArrays
import Documenter: makedocs

makedocs(
    modules = [JuliennedArrays],
    sitename = "JuliennedArrays.jl",
    root = joinpath(dirname(@__DIR__), "docs"),
    strict = true
)
