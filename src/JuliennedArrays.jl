module JuliennedArrays

import Base: axes, getindex, setindex!, size
using Base: promote_op, @propagate_inbounds, tail

map_unrolled(call, variables::Tuple{}) = ()
map_unrolled(call, variables) =
    call(first(variables)), map_unrolled(call, tail(variables))...

map_unrolled(call, variables1::Tuple{}, variables2::Tuple{}) = ()
map_unrolled(call, variables1, variables2) =
    call(first(variables1), first(variables2)),
    map_unrolled(call, tail(variables1), tail(variables2))...

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

not(::False) = True()
not(::True) = False()

export True
export False

getindex_unrolled(into::Tuple{}, switches::Tuple{}) = ()
function getindex_unrolled(into, switches)
    next = getindex_unrolled(tail(into), tail(switches))
    if untyped(first(switches))
        (first(into), next...)
    else
        next
    end
end

setindex_unrolled(old::Tuple{}, something, ::Tuple{}) = ()
setindex_unrolled(old, new, switches) =
    if untyped(first(switches))
        first(new),
        setindex_unrolled(tail(old), tail(new), tail(switches))...
    else
        first(old),
        setindex_unrolled(tail(old), new, tail(switches))...
    end

struct Slices{Item, Dimensions, Whole, Along} <: AbstractArray{Item, Dimensions}
    whole::Whole
    along::Along
end
Slices{Item, Dimensions}(whole::Whole, along::Along) where {Item, Dimensions, Whole, Along} =
    Slices{Item, Dimensions, Whole, Along}(whole, along)

axes(sliced::Slices) =
    getindex_unrolled(axes(sliced.whole), map_unrolled(not, sliced.along))
size(sliced::Slices) = map_unrolled(length, axes(sliced))

slice_index(sliced, indices) = setindex_unrolled(
    axes(sliced.whole),
    indices,
    map_unrolled(not, sliced.along)
)
@propagate_inbounds getindex(sliced::Slices, indices::Int...) =
    view(sliced.whole, slice_index(sliced, indices)...)
@propagate_inbounds setindex!(sliced::Slices, value, indices::Int...) =
    sliced.whole[slice_index(sliced, indices)...] = value

axis_or_1(switch, axis) =
    if untyped(switch)
        axis
    else
        1
    end
"""
    Slices(whole, along...)

Slice `whole` into `view`s.

`along`, made of [`True`](@ref) and [`False`](@ref) objects, shows which dimensions will be replaced with `:` when slicing.

```jldoctest
julia> using JuliennedArrays

julia> whole = [1 2; 3 4];

julia> sliced = Slices(whole, False(), True())
2-element Slices{SubArray{Int64,1,Array{Int64,2},Tuple{Int64,Base.OneTo{Int64}},true},1,Array{Int64,2},Tuple{False,True}}:
 [1, 2]
 [3, 4]

julia> sliced[1] == whole[1, :]
true

julia> sliced[1] = [2, 1];

julia> whole
2×2 Array{Int64,2}:
 2  1
 3  4

julia> larger = rand(5, 5, 5);

julia> larger_sliced = Slices(larger, True(), False(), False());

julia> size(first(larger_sliced))
(5,)
```
"""
Slices(whole, along...) =
    Slices{
        typeof(@inbounds view(
            whole,
            map_unrolled(axis_or_1, along, axes(whole))...
        )),
        length(getindex_unrolled(along, map_unrolled(not, along)))
    }(whole, along)
export Slices

struct Align{Item, Dimensions, Sliced, Along} <: AbstractArray{Item, Dimensions}
    sliced::Sliced
    along::Along
end
Align{Item, Dimensions}(sliced::Sliced, along::Along) where {Item, Dimensions, Sliced, Along} =
    Align{Item, Dimensions, Sliced, Along}(sliced, along)

axes(aligned::Align) = setindex_unrolled(
    setindex_unrolled(
        aligned.along,
        axes(aligned.sliced),
        map_unrolled(not, aligned.along)
    ),
    axes(first(aligned.sliced)),
    aligned.along
)
size(aligned::Align) = map_unrolled(length, axes(aligned))

split_indices(aligned, indices) =
    getindex_unrolled(indices, map_unrolled(not, aligned.along)),
    getindex_unrolled(indices, aligned.along)
@propagate_inbounds function getindex(aligned::Align, indices::Int...)
    outer, inner = split_indices(aligned, indices)
    aligned.sliced[outer...][inner...]
end
@propagate_inbounds function setindex!(aligned::Align, value, indices::Int...)
    outer, inner = split_indices(aligned, indices)
    aligned.sliced[outer...][inner...] = value
end

"""
    Align(sliced, along...)

`Align` an array of arrays, all with the same size.

`along`, made of [`True`](@ref) and [`False`](@ref) objects, shows which dimensions will be taken up by the inner arrays. Inverse of [`Slices`](@ref).

```jldoctest
julia> using JuliennedArrays

julia> sliced = [[1, 2], [3, 4]];

julia> aligned = Align(sliced, False(), True())
2×2 Align{Int64,2,Array{Array{Int64,1},1},Tuple{False,True}}:
 1  2
 3  4

julia> aligned[1, :] == sliced[1]
true

julia> aligned[1, 1] = 0;

julia> sliced
2-element Array{Array{Int64,1},1}:
 [0, 2]
 [3, 4]
```
"""
Align(sliced::AbstractArray{<:AbstractArray{Item, InnerDimensions}, OuterDimensions}, along...) where {Item, InnerDimensions, OuterDimensions} =
    Align{Item, OuterDimensions + InnerDimensions}(sliced, along)
export Align

end
