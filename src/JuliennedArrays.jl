module JuliennedArrays

using RecurUnroll: getindex_unrolled, setindex_unrolled
using TypedBools: True, False

import Base: indices, size, getindex, setindex!, @propagate_inbounds

struct JulienneIndexer{T, N, IS, ID} <: AbstractArray{T, N}
    indexes::IS
    indexed::ID
end

indices(j::JulienneIndexer) = getindex_unrolled(j.indexes, j.indexed)
size(j::JulienneIndexer) = length.(indices(j))
getindex(j::JulienneIndexer{T, N}, index::Vararg{Int, N}) where {T, N} =
    setindex_unrolled(j.indexes, index, j.indexed)

JulienneIndexer(indexes::IS, indexed::ID) where {IS, ID} =
    JulienneIndexer{
        typeof(setindex_unrolled(indexes, 1, indexed)),
        length(getindex_unrolled(indexes, indexed)),
        IS, ID}(indexes, indexed)

abstract type Shares{T, N, A, I} <: AbstractArray{T, N} end

size(r::Shares) = size(r.indexer)
@propagate_inbounds setindex!(r::Shares{T, N}, v, index::Vararg{Int, N}) where {T, N} =
    r.array[r.indexer[index...]...] = v

export Arrays
struct Arrays{T, N, A, I} <: Shares{T, N, A, I}
    array::A
    indexer::I
end

@propagate_inbounds getindex(r::Arrays{T, N}, index::Vararg{Int, N}) where {T, N} =
    r.array[r.indexer[index...]...]

Arrays(array::A, indexer::I) where {A, I <: AbstractArray{T, N}}  where {T, N} =
    Arrays{typeof(array[first(indexer)...]), N, A, I}(array, indexer)

export Views
struct Views{T, N, A, I} <: Shares{T, N, A, I}
    array::A
    indexer::I
end

Views(array::A, indexer::I) where
    {A <: AbstractArray{TA}, I <: AbstractArray{TI, N}} where
        {TA, TI, N} =
    Views{
        SubArray{TA, TI, A, N,
            isa(IndexStyle(Base.viewindexing(first(indexer)), IndexStyle(array)), IndexLinear)},
        N, A, I}(array, indexer)

@propagate_inbounds getindex(r::Views{T, N}, index::Vararg{Int, N}) where {T, N} =
    @view r.array[r.indexer[index...]...]

export Swaps
struct Swaps{T, N, A, I} <: Shares{T, N, A, I}
    array::A
    indexer::I
    swap::T
end

function Swaps(array::A, indexer::I) where
    {A, I <: AbstractArray{T, N}} where
        {T, N}
    swap = similar(array, size(@view array[first(indexer)...])...)
    Swaps{typeof(swap), N, A, I}(array, indexer, swap)
end

@propagate_inbounds getindex(s::Swaps{T, N}, index::Vararg{Int, N}) where {T, N} =
    Base._unsafe_getindex!(s.swap, s.array, s.indexer[index...]...)

is_indexed(::typeof(*)) = True()
is_indexed(::typeof(:)) = False()

export julienne
"""
    julienne(T, array, code)
    julienne(T, array, code, swap)

Slice an array and create shares of type `T`. `T` should be one of `Arrays`,
`Swaps`, or `Views`. The code should a tuple of length `ndims(array)`, where `:`
indicates an axis parallel to slices and `*` indices an axis perpendicular to
slices.

```jldoctest
julia> using JuliennedArrays

julia> code = (*, :);

julia> array = [5 6 4; 1 3 2; 7 9 8]
3×3 Array{Int64,2}:
 5  6  4
 1  3  2
 7  9  8

julia> arrays = julienne(Arrays, array, (*, :));

julia> map(sum, arrays)
3-element Array{Int64,1}:
 15
  6
 24

julia> views = julienne(Views, array, (*, :));

julia> map(sum, views)
3-element Array{Int64,1}:
 15
  6
 24

julia> swaps = julienne(Swaps, array, (*, :));

julia> map(sum, swaps)
3-element Array{Int64,1}:
 15
  6
 24
```
"""
julienne(T, array, code) =
    T(array, JulienneIndexer(indices(array), is_indexed.(code)))

const MetaArray = AbstractArray{<: AbstractArray}

export align
"""
    align(slices, code)

Align an array of slices into a larger array. Code should be a tuple for each
dimension of the desired output. Slices will slide into dimensions coded by `:`,
while `*` indicates dimensions taken up by the container array. Each slice
should be EXACTLY the same size.

```jldoctest
julia> using JuliennedArrays, MappedArrays

julia> code = (*, :);

julia> array = [5 6 4; 1 3 2; 7 9 8]
3×3 Array{Int64,2}:
 5  6  4
 1  3  2
 7  9  8

julia> swaps = julienne(Swaps, array, code);

julia> align(mappedarray(sort, swaps), code)
3×3 Array{Int64,2}:
 4  5  6
 1  2  3
 7  8  9
```
"""
function align(input_slices::MetaArray, code)
    indexed = is_indexed.(code)

    first_input_slice = first(input_slices)

    output_indexes =
        setindex_unrolled(
            setindex_unrolled(
                indexed,
                indices(input_slices),
                indexed,
                Base.OneTo(1)),
            indices(first_input_slice),
            .!indexed,
            Base.OneTo(1)
        )

    output = similar(first_input_slice, output_indexes...)
    output_slices = julienne(Arrays, output, code)

    output_slices[1] = first_input_slice
    for i in Iterators.Drop(eachindex(input_slices), 1)
        output_slices[i] = input_slices[i]
    end
    output
end

end
