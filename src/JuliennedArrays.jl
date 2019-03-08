module JuliennedArrays

import Base: axes, setindex!, getindex, collect, size, Bool, setindex
using Base: @propagate_inbounds, OneTo,  promote_op, tail

const More{N, T} = Tuple{T, Vararg{T, N}}

abstract type TypedBool end
"""
    struct True
"""
struct True <: TypedBool end
export True
"""
    struct False
"""
struct False <: TypedBool end
export False

@inline Bool(::True) = true
@inline Bool(::False) = false

not(::False) = True()
not(::True) = False()

getindex(into::Tuple{}, switch::Tuple{}) = ()
function getindex(into::More{N, Any}, switch::More{N, TypedBool}) where {N}
    next = getindex(tail(into), tail(switch))
    if Bool(first(switch))
        (first(into), next...)
    else
        next
    end
end
setindex(old::Tuple{}, ::Tuple, ::Tuple{}) = ()
function setindex(old::More{N, Any}, new::Tuple, switch::More{N, TypedBool}) where {N}
    first_tuple, tail_tuple =
        if Bool(first(switch))
            (first(new), tail(new))
        else
            (first(old), new)
        end
    (first_tuple, setindex(tail(old), tail_tuple, tail(switch))...)
end
struct Slices{ElementType, NumberOfDimensions, Parent, Along} <:
    AbstractArray{ElementType, NumberOfDimensions}
    parent::Parent
    along::Along
end
function axes(it::Slices)
    getindex(axes(it.parent), not.(it.along))
end
function size(it::Slices)
    length.(axes(it))
end
@propagate_inbounds function getindex(it::Slices, index...)
    parent = it.parent
    view(parent, setindex(axes(parent), index, not.(it.along))...)
end
@propagate_inbounds function setindex!(it::Slices, value, index...)
    parent = it.parent
    parent[
        setindex(axes(parent), index, not.(it.along))...
    ] = value
end
"""
    Slices(array, code...)

Slice array into `view`s. `code` shows which dimensions will be replaced with `:` when slicing.

```jldoctest
julia> using JuliennedArrays

julia> it = [1 2; 3 4];

julia> slices = Slices(it, False(), True())
2-element Slices{SubArray{Int64,1,Array{Int64,2},Tuple{Int64,Base.OneTo{Int64}},true},1,Array{Int64,2},Tuple{False,True}}:
 [1, 2]
 [3, 4]

julia> slices[1] == it[1, :]
true
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

struct Align{T, N, Parent, Along} <:
    AbstractArray{T, N}
    parent::Parent
    along::Along
end
function axes(it::Align)
    array = it.parent
    along = it.along
    ntuple(x -> OneTo(1), length(along)) |>
        x -> setindex(x, axes(first(array)), along) |>
        x -> setindex(x, axes(array), not.(along))
end
function size(it::Align)
    length.(axes(it))
end
@propagate_inbounds function getindex(it::Align, index...)
    along = it.along
    it.parent[getindex(index, not.(along))...][getindex(index, along)...]
end
@propagate_inbounds function setindex!(it::Align, value, index...)
    along = it.along
    it.parent[getindex(index, not.(along))...][getindex(index, along)...] = value
end
"""
    Align(it, along...)

`Align` an array of arrays, all with the same size. `along` shows which dimensions will be taken up by the inner arrays. Inverse of [`Slice`](@ref).

```jldoctest
julia> using JuliennedArrays

julia> array = [[1, 2], [3, 4]];

julia> aligned = Align(array, False(), True())
2×2 Align{Int64,2,Array{Array{Int64,1},1},Tuple{False,True}}:
 1  2
 3  4

julia> aligned[1, :] == array[1]
true
```
"""
function Align(it::AbstractArray{<:AbstractArray{T, N}, M}, along...) where {T, N, M}
    Align{T, N + M, typeof(it), typeof(along)}(it, along)
end
export Align

end
