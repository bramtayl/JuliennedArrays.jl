using JuliennedArrays

# Build the docs on Julia v1.1
if get(ENV, "TRAVIS_JULIA_VERSION", nothing) == "1.1"
    cd(joinpath(@__DIR__, "..")) do
        withenv("JULIA_LOAD_PATH" => nothing) do
            cmd = `$(Base.julia_cmd()) --depwarn=no --color=yes --project=docs/`
            run(`$(cmd) -e 'using Pkg; Pkg.instantiate()'`)
            run(`$(cmd) docs/make.jl`)
        end
    end
end
