module JuliennedArrays

import Base: axes, getindex, setindex!, size
using Base: @pure, tail

export Slices, Align
export True, False

@inline is_in(needle::Needle, straw1::Needle, straws...) where {Needle} = True()
@inline is_in(needle, straw1, straws...) = is_in(needle, straws...)
@inline is_in(needle) = False()

@inline in_unrolled(straws, needle1, needles...) =
    is_in(needle1, straws...), in_unrolled(straws, needles...)...
@inline in_unrolled(straws) = ()

@pure as_vals(them::Int...) = map(Val, them)

abstract type TypedBool end
"""
    struct True

Typed `true`
"""
struct True <: TypedBool end
"""
    struct False

Typed `false`
"""
struct False <: TypedBool end

@inline untyped(::True) = true
@inline untyped(::False) = false

@inline not(::False) = True()
@inline not(::True) = False()

@inline getindex_unrolled(into::Tuple{}, switches::Tuple{}) = ()
@inline function getindex_unrolled(into, switches)
    next = getindex_unrolled(tail(into), tail(switches))
    if untyped(first(switches))
        (first(into), next...)
    else
        next
    end
end

@inline setindex_unrolled(old::Tuple{}, something, ::Tuple{}) = ()
@inline setindex_unrolled(old, new, switches) =
    if untyped(first(switches))
        first(new), setindex_unrolled(tail(old), tail(new), tail(switches))...
    else
        first(old), setindex_unrolled(tail(old), new, tail(switches))...
    end

###
# Slices
###
struct Slices{Item,Dimensions,Whole,Alongs} <: AbstractArray{Item,Dimensions}
    whole::Whole
    alongs::Alongs
    function Slices{T,N,W,A}(whole::W, alongs::A) where {T,N,W,A}
        any(isequal(True()), alongs) || throw(DimensionMismatch("Expected to have at least one active slicing dimension."))
        new{T,N,W,A}(whole, alongs)
    end
end
@inline Slices{Item,Dimensions}(
    whole::Whole,
    alongs::Alongs,
) where {Item,Dimensions,Whole,Alongs} = Slices{Item,Dimensions,Whole,Alongs}(whole, alongs)

@inline axes(slices::Slices) =
    getindex_unrolled(axes(slices.whole), map(not, slices.alongs))
@inline size(slices::Slices) = map(length, axes(slices))

@inline slice_index(slices, indices) =
    setindex_unrolled(axes(slices.whole), indices, map(not, slices.alongs))
@inline getindex(slices::Slices, indices::Int...) =
    view(slices.whole, slice_index(slices, indices)...)
@inline setindex!(slices::Slices, value, indices::Int...) =
    slices.whole[slice_index(slices, indices)...] = value

@inline axis_or_1(switch, axis) = untyped(switch) ? axis : 1

"""
    Slices(whole, alongs::TypedBool...)

Slice `whole` into `view`s.

`alongs`, made of [`True`](@ref) and [`False`](@ref) objects, shows which dimensions will be replaced with `:` when slicing.

```jldoctest
julia> using JuliennedArrays

julia> whole = [1 2; 3 4];

julia> slices = Slices(whole, False(), True())
2-element Slices{SubArray{Int64,1,Array{Int64,2},Tuple{Int64,Base.OneTo{Int64}},true},1,Array{Int64,2},Tuple{False,True}}:
 [1, 2]
 [3, 4]

julia> slices[1] == whole[1, :]
true

julia> slices[1] = [2, 1];

julia> whole
2×2 Array{Int64,2}:
 2  1
 3  4

julia> larger = rand(5, 5, 5);

julia> larger_slices = Slices(larger, True(), False(), False());

julia> size(first(larger_slices))
(5,)
```
"""
function Slices(whole::AbstractArray, alongs::TypedBool...)
    length(alongs) <= ndims(whole) || throw(ArgumentError("$(length(alongs)) dimensions are specified, expected to be <= $(ndims(whole))"))
    # mark all tailing dimensions as outer dimensions
    alongs = (alongs..., ntuple(i->False(), ndims(whole)-length(alongs))...)
    x = @inbounds view(whole, map(axis_or_1, alongs, axes(whole))...)
    N = length(getindex_unrolled(alongs, map(not, alongs)))
    return Slices{typeof(x),N}(whole, alongs)
end

"""
    Slices(whole, alongs::Int...)

Alternative syntax: `alongs` is which dimensions will be replaced with `:` when slicing.

```jldoctest
julia> using JuliennedArrays

julia> input = reshape(1:8, 2, 2, 2)
2×2×2 reshape(::UnitRange{Int64}, 2, 2, 2) with eltype Int64:
[:, :, 1] =
 1  3
 2  4

[:, :, 2] =
 5  7
 6  8

julia> s = Slices(input, 1, 3)
2-element Slices{SubArray{Int64,2,Base.ReshapedArray{Int64,3,UnitRange{Int64},Tuple{}},Tuple{Base.OneTo{Int64},Int64,Base.OneTo{Int64}},false},1,Base.ReshapedArray{Int64,3,UnitRange{Int64},Tuple{}},Tuple{True,False,True}}:
 [1 5; 2 6]
 [3 7; 4 8]

julia> map(sum, s)
2-element Array{Int64,1}:
 14
 22
```
"""
function Slices(whole::AbstractArray{T,N}, alongs::Int...) where {T,N}
    any(x->x>N, alongs) && throw(ArgumentError("All alongs values $(alongs) should be less than $(N)"))
    Slices(whole, in_unrolled(as_vals(alongs...), ntuple(Val, N)...)...)
end

###
# Align
###
struct Align{Item,Dimensions,Sliced,Alongs} <: AbstractArray{Item,Dimensions}
    slices::Sliced
    alongs::Alongs
    function Align{T,N,S,A}(slices::S, alongs::A) where {T,N,S,A}
        sz = size(first(slices))
        all(x->sz==size(x), slices) || throw(ArgumentError("All sizes of slices should be the same."))
        length(alongs) == N || throw(DimensionMismatch("The total dimension $(N) is expected to be the sum of inner dimension $(length(sz)) and outer dimension $(length(alongs))"))
        inner_dimensions = mapreduce(isequal(True()), +, alongs)
        inner_dimensions == ndims(first(slices)) || throw(DimensionMismatch("Only $inner_dimensions inner dimensions are used, expected $(ndims(first(slices))) dimensions."))
        new{T,N,S,A}(slices, alongs)
    end
end
@inline Align{Item,Dimensions}(
    slices::Sliced,
    alongs::Alongs,
) where {Item,Dimensions,Sliced,Alongs} =
    Align{Item,Dimensions,Sliced,Alongs}(slices, alongs)

@inline axes(aligned::Align) = setindex_unrolled(
    setindex_unrolled(aligned.alongs, axes(aligned.slices), map(not, aligned.alongs)),
    axes(first(aligned.slices)),
    aligned.alongs,
)
@inline size(aligned::Align) = map(length, axes(aligned))

@inline split_indices(aligned, indices) =
    getindex_unrolled(indices, map(not, aligned.alongs)),
    getindex_unrolled(indices, aligned.alongs)
@inline function getindex(aligned::Align, indices::Int...)
    outer, inner = split_indices(aligned, indices)
    aligned.slices[outer...][inner...]
end
@inline function setindex!(aligned::Align, value, indices::Int...)
    outer, inner = split_indices(aligned, indices)
    aligned.slices[outer...][inner...] = value
end

"""
    Align(slices, alongs::TypedBool...)

`Align` an array of arrays, all with the same size.

`alongs`, made of [`True`](@ref) and [`False`](@ref) objects, shows which dimensions will be taken up by the inner arrays. Inverse of [`Slices`](@ref).

```jldoctest
julia> using JuliennedArrays

julia> slices = [[1, 2], [3, 4]];

julia> aligned = Align(slices, False(), True())
2×2 Align{Int64,2,Array{Array{Int64,1},1},Tuple{False,True}}:
 1  2
 3  4

julia> aligned[1, :] == slices[1]
true

julia> aligned[1, 1] = 0;

julia> slices
2-element Array{Array{Int64,1},1}:
 [0, 2]
 [3, 4]
```
"""
@inline Align(
    slices::AbstractArray{<:AbstractArray{Item,InnerDimensions},OuterDimensions},
    alongs::TypedBool...,
) where {Item,InnerDimensions,OuterDimensions} =
    Align{Item,OuterDimensions + InnerDimensions}(slices, alongs)

"""
    Along(slices, alongs::Int...)

Alternative syntax: `alongs` is which dimensions will be taken up by the inner arrays.

```jldoctest
julia> using JuliennedArrays

julia> input = reshape(1:8, 2, 2, 2)
2×2×2 reshape(::UnitRange{Int64}, 2, 2, 2) with eltype Int64:
[:, :, 1] =
 1  3
 2  4

[:, :, 2] =
 5  7
 6  8

julia> slices = collect(Slices(input, 1, 3))
2-element Array{SubArray{Int64,2,Base.ReshapedArray{Int64,3,UnitRange{Int64},Tuple{}},Tuple{Base.OneTo{Int64},Int64,Base.OneTo{Int64}},false},1}:
 [1 5; 2 6]
 [3 7; 4 8]

julia> Align(slices, 1, 3)
2×2×2 Align{Int64,3,Array{SubArray{Int64,2,Base.ReshapedArray{Int64,3,UnitRange{Int64},Tuple{}},Tuple{Base.OneTo{Int64},Int64,Base.OneTo{Int64}},false},1},Tuple{True,False,True}}:
[:, :, 1] =
 1  3
 2  4

[:, :, 2] =
 5  7
 6  8
```
"""
Align(
    slices::AbstractArray{<:AbstractArray{Item,InnerDimensions},OuterDimensions},
    alongs::Int...,
) where {Item,InnerDimensions,OuterDimensions} = Align(
    slices,
    in_unrolled(
        as_vals(alongs...),
        ntuple(Val, InnerDimensions + OuterDimensions)...,
    )...,
)

end
