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
        typeof(Indexes),
        typeof(Iterated)}(indexes, iterated)

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
