struct JulienneIterator{T, N, Indexes, Iterated} <: AbstractArray{T, N}
    indexes::Indexes
    iterated::Iterated
end

Base.indices(j::JulienneIterator) = get_index(j.indexes, j.iterated)
Base.size(j::JulienneIterator) = length.(indices(j))
Base.getindex(j::JulienneIterator{T, N}, index::Vararg{Int, N}) where {T, N} =
    set_index(j.indexes, index, j.iterated)

JulienneIterator(indexes, iterated) =
    JulienneIterator{
        typeof(fill_index(indexes, 1, iterated)),
        length(get_index(indexes, iterated)),
        typeof(indexes),
        typeof(iterated)}(indexes, iterated)

struct ReiteratedArray{T, N, A, I} <: AbstractArray{T, N}
    array::A
    iterator::I
end

Base.indices(r::ReiteratedArray) = indices(r.iterator)
Base.size(r::ReiteratedArray) = size(r.iterator)
Base.getindex(r::ReiteratedArray{T, N}, index::Vararg{Int, N}) where {T, N} =
    @view r.array[r.iterator[index...]...]
Base.setindex!(r::ReiteratedArray{T, N}, v, index::Vararg{Int, N}) where {T, N} =
    broadcast!(identity, r[index...], v)
ReiteratedArray(array::A, iterator::I) where {A, I} =
    ReiteratedArray{
        SubArray{eltype(array), ndims(iterator), typeof(array), eltype(iterator),
            isa(IndexStyle(Base.viewindexing(first(iterator)), IndexStyle(array)), IndexLinear)},
            ndims(iterator), A, I}(array, iterator)

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
    ReiteratedArray(array, JulienneIterator(indices(array), is_iterated.(julienne_code)))
