module JuliennedArrays

import Base: axes, setindex!, getindex, collect, size, Bool, setindex
using Base: @propagate_inbounds, OneTo, promote_op, tail

const More{Number, Item} = Tuple{Item, Vararg{Item, Number}}

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
@inline Bool(::True) = true
@inline Bool(::False) = false
not(::False) = True()
not(::True) = False()
export True
export False

getindex(into::Tuple{}, switch::Tuple{}) = ()
function getindex(into::More{Number, Any}, switch::More{Number, TypedBool}) where {Number}
    next = getindex(tail(into), tail(switch))
    if Bool(first(switch))
        (first(into), next...)
    else
        next
    end
end
setindex(old::Tuple{}, ::Tuple, ::Tuple{}) = ()
function setindex(old::More{Number, Any}, new::Tuple, switch::More{Number, TypedBool}) where {Number}
    first_tuple, tail_tuple =
        if Bool(first(switch))
            (first(new), tail(new))
        else
            (first(old), new)
        end
    (first_tuple, setindex(tail(old), tail_tuple, tail(switch))...)
end

struct Slices{Item, Dimensions, Parent, Along} <: AbstractArray{Item, Dimensions}
    parent::Parent
    along::Along
end
axes(it::Slices) = getindex(axes(it.parent), not.(it.along))
size(it::Slices) = length.(axes(it))
@propagate_inbounds getindex(it::Slices, index...) =
    view(it.parent, setindex(axes(it.parent), index, not.(it.along))...)
@propagate_inbounds setindex!(it::Slices, value, index...) =
    it.parent[setindex(axes(it.parent), index, not.(it.along))...] = value
"""
    Slices(array, along...)

Slice array into `view`s.

`along`, made of [`True`](@ref) and [`False`](@ref) objects, shows which dimensions will be replaced with `:` when slicing.

```jldoctest
julia> using JuliennedArrays

julia> it = [1 2; 3 4];

julia> slices = Slices(it, False(), True())
2-element Slices{SubArray{Int64,1,Array{Int64,2},Tuple{Int64,Base.OneTo{Int64}},true},1,Array{Int64,2},Tuple{False,True}}:
 [1, 2]
 [3, 4]

julia> slices[1] == it[1, :]
true

julia> slices[1] = [2, 1];

julia> it
2×2 Array{Int64,2}:
 2  1
 3  4
```
"""
function Slices(it, along...)
    Slices{
        promote_op(
            (it, along) -> view(it, map(
                (switch, axis) ->
                    if Bool(switch)
                        axis
                    else
                        1
                    end,
                along, axes(it)
            )...),
            typeof(it), typeof(along)
        ),
        length(getindex(along, not.(along))),
        typeof(it),
        typeof(along)
    }(it, along)
end
export Slices

struct Align{Item, Dimensions, Parent, Along} <: AbstractArray{Item, Dimensions}
    parent::Parent
    along::Along
end
axes(it::Align) = ntuple(x -> OneTo(1), length(it.along)) |>
    x -> setindex(x, axes(first(it.parent)), it.along) |>
    x -> setindex(x, axes(it.parent), not.(it.along))
size(it::Align) = length.(axes(it))
@propagate_inbounds getindex(it::Align, index...) =
    it.parent[getindex(index, not.(it.along))...][getindex(index, it.along)...]
@propagate_inbounds setindex!(it::Align, value, index...) =
    it.parent[getindex(index, not.(it.along))...][getindex(index, it.along)...] = value
"""
    Align(it, along...)

`Align` an array of arrays, all with the same size.

`along`, made of [`True`](@ref) and [`False`](@ref) objects, shows which dimensions will be taken up by the inner arrays. Inverse of [`Slices`](@ref).

```jldoctest
julia> using JuliennedArrays

julia> array = [[1, 2], [3, 4]];

julia> aligned = Align(array, False(), True())
2×2 Align{Int64,2,Array{Array{Int64,1},1},Tuple{False,True}}:
 1  2
 3  4

julia> aligned[1, :] == array[1]
true

julia> aligned[1, 1] = 0;

julia> array
2-element Array{Array{Int64,1},1}:
 [0, 2]
 [3, 4]
```
"""
Align(it::AbstractArray{<:AbstractArray{Item, Inner}, Outer}, along...) where {Item, Inner, Outer} =
    Align{Item, Inner + Outer, typeof(it), typeof(along)}(it, along)
export Align

end
