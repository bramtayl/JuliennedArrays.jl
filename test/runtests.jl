using JuliennedArrays
using Documenter: makedocs, deploydocs

makedocs(sitename = "JuliennedArrays.jl", strict = true)

if get(ENV, "TRAVIS_OS_NAME", nothing) == "linux" && get(ENV, "TRAVIS_JULIA_VERSION", nothing) == "1.1"
    deploydocs(repo = "github.com/bramtayl/JuliennedArrays.jl.git")
end
