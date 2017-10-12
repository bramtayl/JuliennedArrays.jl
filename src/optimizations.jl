abstract type FunctionOptimization{F} end

export Reduction
"""
    struct Reduction{F} <: FunctionOptimization; f::F; end

A reduction of another function. Enables optimizations in some cases.
Automatically enabled for known reduction functions.

```jldoctest
julia> using JuliennedArrays, Base.Test, Base.Test

julia> array = [5 6 4; 1 3 2; 7 9 8]
3×3 Array{Int64,2}:
 5  6  4
 1  3  2
 7  9  8

julia> swaps = @inferred julienne(Swaps, array, (*, :));

julia> @inferred map(Reduction(+), swaps)
3×1 Array{Int64,2}:
 15
  6
 24

julia> @inferred map(sum, swaps)
3×1 Array{Int64,2}:
 15
  6
 24
```
"""
struct Reduction{F} <: FunctionOptimization{F}; f::F; end

const JuliennedArray = Shares{T, N, A, I} where {T, N, A, I <: JulienneIndexer}

map(r::Reduction, s::JuliennedArray) =
    mapreducedim(identity, r.f, s.array, colon_dimensions(s.indexer))

map(f::typeof(sum), s::JuliennedArray) = map(Reduction(+), s)
map(f::typeof(prod), s::JuliennedArray) = map(Reduction(*), s)
map(f::typeof(maximum), s::JuliennedArray) = map(Reduction(scalarmax), s)
map(f::typeof(minimum), s::JuliennedArray) = map(Reduction(scalarmin), s)
map(f::typeof(all), s::JuliennedArray) = map(Reduction(&), s)
map(f::typeof(any), s::JuliennedArray) = map(Reduction(|), s)
