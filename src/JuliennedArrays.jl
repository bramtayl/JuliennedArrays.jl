module JuliennedArrays

import Base: axes, getindex, setindex!, size
using Base: @pure, tail

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

export True
export False

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

struct Slices{Item,Dimensions,Whole,Alongs} <: AbstractArray{Item,Dimensions}
    whole::Whole
    alongs::Alongs
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

@inline axis_or_1(switch, axis) =
    if untyped(switch)
        axis
    else
        1
    end
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
Slices(whole::AbstractArray, alongs::TypedBool...) = Slices{
    typeof(@inbounds view(whole, map(axis_or_1, alongs, axes(whole))...)),
    length(getindex_unrolled(alongs, map(not, alongs))),
}(
    whole,
    alongs,
)

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
Slices(
    whole::AbstractArray{Item,NumberOfDimensions},
    alongs::Int...,
) where {Item,NumberOfDimensions} =
    Slices(whole, in_unrolled(as_vals(alongs...), ntuple(Val, NumberOfDimensions)...)...)
export Slices

struct Align{Item,Dimensions,Sliced,Alongs} <: AbstractArray{Item,Dimensions}
    slices::Sliced
    alongs::Alongs
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
export Align

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


"""
    stack(slices, [dims::Int])

Stack slices along `dims` with a new dimension.

When `dims > ndims(first(slices))`, this is equivalent to `cat(slices...; dims=dims)` except that
this is a lazy operation.

# Examples

```jldoctest; setup=:(using JuliennedArrays: stack)
julia> x = [rand(2, 3) for _ in 1:4];

julia> size(stack(x, 1))
(4, 2, 3)

julia> size(stack(x, 2))
(2, 4, 3)

julia> size(stack(x, 3))
(2, 3, 4)

julia> stack(x) == stack(x, 3) == cat(x..., dims=3)
true
```

The `dims` argument currently only supports one scalar integer, if you want to stack along multiple
dimensions, please use [`Align`](@ref).
"""
function stack(slices::AbstractVector{<:AbstractArray}, dims::Int=ndims(first(slices))+1)
    alongs = ntuple(ndims(first(slices))) do i
        i < dims ? i : i + 1
    end
    Align(slices, alongs...)
end

"""
    unstack(whole, [dims::Int])

Slicing an array along dimension `dims` and make a vector from it.

This is equivalent to `eachslice(whole, dims=dims)` except that this creates an vector interface
instead of a generic iterator.

# Examples

```jldoctest; setup=:(using JuliennedArrays: unstack)
julia> x = rand(2, 3, 4);

julia> size(unstack(x, 1))
(2,)

julia> size(unstack(x, 2))
(3,)

julia> size(unstack(x, 3))
(4,)

julia> unstack(x, 3) == collect(eachslice(x, dims=3))
true
```

The `dims` argument currently only supports one scalar integer, if you want to make slices along
multiple dimensions, please use [`Slices`](@ref).
"""
function unstack(whole, dims::Int=ndims(whole))
    alongs = ntuple(ndims(whole)) do i
        i < dims ? i : i + 1
    end
    Slices(whole, alongs...)
end

end
