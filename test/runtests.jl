using JuliennedArrays

import Documenter
Documenter.makedocs(
    modules = [JuliennedArrays],
    format = :html,
    sitename = "JuliennedArrays.jl",
    root = joinpath(dirname(dirname(@__FILE__)), "docs"),
    pages = Any["Home" => "index.md"],
    linkcheck = true,
    checkdocs = :exports,
    authors = "Brandon Taylor"
)
