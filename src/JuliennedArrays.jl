module JuliennedArrays

using RecurUnroll: getindex_unrolled, setindex_unrolled, find_unrolled
using TypedBools: True, False
using Parts: AbstractParts, Arrays, Views, Swaps

export Arrays
export Views
export Swaps

import Base: indices, size, getindex, setindex!, @propagate_inbounds, map

struct JulienneIndexer{T, N, IS, ID} <: AbstractArray{T, N}
    indexes::IS
    indexed::ID
end

indices(j::JulienneIndexer) = getindex_unrolled(j.indexes, j.indexed)
size(j::JulienneIndexer) = length.(indices(j))
getindex(j::JulienneIndexer{T, N}, index::Vararg{Int, N}) where {T, N} =
    setindex_unrolled(j.indexes, index, j.indexed)

JulienneIndexer(indexes, indexed) =
    JulienneIndexer{
        typeof(setindex_unrolled(indexes, 1, indexed)),
        length(getindex_unrolled(indexes, indexed)),
        typeof(indexes),
        typeof(indexed)
    }(indexes, indexed)

drop_tuple(t::Tuple{A}) where A = first(t)
drop_tuple(t) = t

colon_dimensions(j::JulienneIndexer) =
    drop_tuple(find_unrolled(.!(j.indexed)))

is_indexed(::typeof(*)) = True()
is_indexed(::typeof(:)) = False()

export julienne
"""
    julienne(T, array, code)
    julienne(T, array, code, swap)

Slice an array and create `Parts` of type `T`. `T` should be one of `Arrays`,
`Swaps`, or `Views`. See the `Parts` package for more information. The code
should a tuple of length `ndims(array)`, where `:` indicates an axis parallel
to slices and `*` indices an axis perpendicular to slices.

```jldoctest
julia> using JuliennedArrays, Base.Test

julia> code = (*, :);

julia> array = [5 6 4; 1 3 2; 7 9 8]
3×3 Array{Int64,2}:
 5  6  4
 1  3  2
 7  9  8

julia> arrays = @inferred julienne(Views, array, (*, :));

julia> @inferred map(sum, arrays)
3-element Array{Int64,1}:
 15
  6
 24
```
"""
julienne(T, array, code) =
    T(array, JulienneIndexer(indices(array), is_indexed.(code)))

export align
"""
    align(slices, code)

Align an array of slices into a larger array. Code should be a tuple with an
entry for each dimension of the desired output. Slices will slide into
dimensions coded by `:`, while `*` indicates dimensions taken up by the
container array. Each slice should be EXACTLY the same size.

```jldoctest
julia> using JuliennedArrays, MappedArrays, Base.Test

julia> code = (*, :);

julia> array = [5 6 4; 1 3 2; 7 9 8]
3×3 Array{Int64,2}:
 5  6  4
 1  3  2
 7  9  8

julia> swaps = @inferred julienne(Views, array, code);

julia> @inferred align(mappedarray(sort, swaps), code)
3×3 Array{Int64,2}:
 4  5  6
 1  2  3
 7  8  9
```
"""
function align(input_slices::AbstractArray{<: AbstractArray}, code)
    indexed = is_indexed.(code)

    first_input_slice = first(input_slices)

    trivial = Base.OneTo(1)

    output_indexes =
        setindex_unrolled(
            setindex_unrolled(
                indexed,
                indices(input_slices),
                indexed,
                trivial),
            indices(first_input_slice),
            .!indexed,
            trivial
        )

    output = similar(first_input_slice, output_indexes...)
    output_slices = julienne(Arrays, output, code)

    output_slices[1] = first_input_slice
    for i in Iterators.Drop(eachindex(input_slices), 1)
        output_slices[i] = input_slices[i]
    end
    output
end

abstract type FunctionOptimization{F} end

export Reduction
"""
    struct Reduction{F}

A reduction of another function. Enables optimizations in some cases.

```jldoctest
julia> using JuliennedArrays, Base.Test, Base.Test

julia> array = [5 6 4; 1 3 2; 7 9 8]
3×3 Array{Int64,2}:
 5  6  4
 1  3  2
 7  9  8

julia> swaps = @inferred julienne(Views, array, (*, :));

julia> @inferred map(Reduction(+), swaps)
3×1 Array{Int64,2}:
 15
  6
 24
```
"""
struct Reduction{F} <: FunctionOptimization{F}; f::F; end

const JuliennedArray = AbstractParts{T, N, A, I} where {T, N, A, I <: JulienneIndexer}

map(r::Reduction, s::JuliennedArray) =
    mapreducedim(identity, r.f, s.array, colon_dimensions(s.locations))

end
