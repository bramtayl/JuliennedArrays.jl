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
        SubArray{TA, N, A, TI,
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

function Swaps(array::A, indexer::I) where {A, I <: AbstractArray{T, N}} where {T, N}
    swap = similar(array, size(@view array[first(indexer)...])...)
    Swaps{typeof(swap), N, A, I}(array, indexer, swap)
end

@propagate_inbounds getindex(s::Swaps{T, N}, index::Vararg{Int, N}) where {T, N} =
    Base._unsafe_getindex!(s.swap, s.array, s.indexer[index...]...)
