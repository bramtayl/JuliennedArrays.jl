struct JulienneIndexer{T, N, Indexes, Indexed} <: AbstractArray{T, N}
    indexes::Indexes
    indexed::Indexed
end

Base.indices(j::JulienneIndexer) = get_index(j.indexes, j.indexed)
Base.size(j::JulienneIndexer) = length.(indices(j))
Base.getindex(j::JulienneIndexer{T, N}, index::Vararg{Int, N}) where {T, N} =
    set_index(j.indexes, index, j.indexed)

JulienneIndexer(indexes, indexed) =
    JulienneIndexer{
        typeof(fill_index(indexes, 1, indexed)),
        length(get_index(indexes, indexed)),
        typeof(indexes),
        typeof(indexed)}(indexes, indexed)

struct ReindexedArray{T, N, A, I} <: AbstractArray{T, N}
    array::A
    indexer::I
end

Base.indices(r::ReindexedArray) = indices(r.indexer)
Base.size(r::ReindexedArray) = size(r.indexer)
Base.getindex(r::ReindexedArray{T, N}, index::Vararg{Int, N}) where {T, N} =
    @view r.array[r.indexer[index...]...]
Base.setindex!(r::ReindexedArray{T, N}, v, index::Vararg{Int, N}) where {T, N} =
    broadcast!(identity, r[index...], v)
ReindexedArray(array::A, indexer::I) where {A, I} =
    ReindexedArray{
        SubArray{eltype(array), ndims(indexer), typeof(array), eltype(indexer),
            isa(IndexStyle(Base.viewindexing(first(indexer)), IndexStyle(array)), IndexLinear)},
            ndims(indexer), A, I}(array, indexer)

export julienne
"""
    julienne(array, julienne_code)

Create a view of an array which will return slices. The julienne code should a tuple
of length `ndims(array)`, where `:` indicates an axis parallel to slices and `*`
indices an axis perpendicular to slices.

```jldoctest
julia> using JuliennedArrays

julia> array = reshape([1 3 2; 5 6 4; 7 9 8], 3, 3)
3×3 Array{Int64,2}:
 1  3  2
 5  6  4
 7  9  8

julia> foreach(sort!, julienne(array, (*, :)));

julia> array
3×3 Array{Int64,2}:
 1  2  3
 4  5  6
 7  8  9
```
"""
julienne(array, julienne_code) =
    ReindexedArray(array, JulienneIndexer(indices(array), is_indexed.(julienne_code)))
