module JuliennedArrays

using RecurUnroll: getindex_unrolled, setindex_unrolled
using TypedBools: True, False

import Base: indices, size, getindex, setindex!, @propagate_inbounds

struct JulienneIndexer{T, N, Indexes, Indexed} <: AbstractArray{T, N}
    indexes::Indexes
    indexed::Indexed
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
        typeof(indexed)}(indexes, indexed)

struct ReindexedArray{T, N, A, I} <: AbstractArray{T, N}
    array::A
    indexer::I
end

indices(r::ReindexedArray) = indices(r.indexer)
size(r::ReindexedArray) = size(r.indexer)
@propagate_inbounds getindex(r::ReindexedArray{T, N}, index::Vararg{Int, N}) where {T, N} =
    @view r.array[r.indexer[index...]...]
@propagate_inbounds setindex!(r::ReindexedArray{T, N}, v, index::Vararg{Int, N}) where {T, N} =
    r.array[r.indexer[index...]...] = v
ReindexedArray(array::A, indexer::I) where {A, I} =
    ReindexedArray{
        SubArray{eltype(array), ndims(indexer), typeof(array), eltype(indexer),
            isa(IndexStyle(Base.viewindexing(first(indexer)), IndexStyle(array)), IndexLinear)},
            ndims(indexer), A, I}(array, indexer)

is_indexed(::typeof(*)) = True()
is_indexed(::typeof(:)) = False()

export julienne
"""
    julienne(array, code)

Create a view of an array which will return slices. The code should a tuple
of length `ndims(array)`, where `:` indicates an axis parallel to slices and `*`
indices an axis perpendicular to slices.

```jldoctest
julia> using JuliennedArrays

julia> code = (*, :);

julia> array = [5 6 4; 1 3 2; 7 9 8]
3×3 Array{Int64,2}:
 5  6  4
 1  3  2
 7  9  8

julia> foreach(sort!, julienne(array, code));

julia> array
3×3 Array{Int64,2}:
 4  5  6
 1  2  3
 7  8  9
```
"""
julienne(array, code) =
    ReindexedArray(array, JulienneIndexer(indices(array), is_indexed.(code)))

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

julia> align(mappedarray(sort, julienne(array, code)), code)
3×3 Array{Int64,2}:
 4  5  6
 1  2  3
 7  8  9
```
"""
function align(input_slices::MetaArray, code)
    indexed = is_indexed.(code)

    first_input_slice = first(input_slices)

    output_indexes = setindex_unrolled(
        setindex_unrolled(indexed, indices(input_slices), indexed, Base.OneTo(1)),
        indices(first_input_slice),
        .!indexed,
        Base.OneTo(1)
    )

    output = similar(first_input_slice, output_indexes...)
    output_slices = julienne(output, code)

    output_slices[1] = first_input_slice
    for i in Iterators.Drop(eachindex(input_slices), 1)
        output_slices[i] = input_slices[i]
    end
    output
end

end
