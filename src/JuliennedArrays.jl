module JuliennedArrays

import Base: axes, getindex, Int, setindex!, size
using Base: @inline, @propagate_inbounds, @pure, tail

export Slices, Align
export True, False

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

@inline function untyped(::True)
    true
end
@inline function untyped(::False)
    false
end

function not(::False)
    True()
end
function not(::True)
    False()
end

function getindex_unrolled(::Tuple{}, ::Tuple{})
    ()
end
function getindex_unrolled(into, switches)
    next = getindex_unrolled(tail(into), tail(switches))
    if untyped(first(switches))
        (first(into), next...)
    else
        next
    end
end

function setindex_unrolled(::Tuple{}, _, ::Tuple{})
    ()
end
function setindex_unrolled(old, new, switches)
    if untyped(first(switches))
        first(new), setindex_unrolled(tail(old), tail(new), tail(switches))...
    else
        first(old), setindex_unrolled(tail(old), new, tail(switches))...
    end
end

function find_in_error(::Val{along}) where {along}
    throw(ArgumentError("$along, a dimension number, is out of bounds or out of order."))
end

function find_in_skip(alongs, dimensions)
    (False(), find_in(alongs, tail(dimensions))...)
end

function find_in_check(
    ::Val{along},
    ::Val{dimension},
    alongs,
    dimensions,
) where {along, dimension}
    if dimension < along
        find_in_skip(alongs, dimensions)
    elseif dimension == along
        (True(), find_in(tail(alongs), tail(dimensions))...)
    else
        # dimension > along
        find_in_error(first_along)
    end
end

function find_in(::Tuple{}, ::Tuple{})
    ()
end
function find_in(alongs::Tuple{}, dimensions)
    find_in_skip(alongs, dimensions)
end
function find_in(alongs, ::Tuple{})
    find_in_error(first(alongs))
end
function find_in(alongs, dimensions)
    find_in_check(first(alongs), first(dimensions), alongs, dimensions)
end

###
# Slices
###
struct Slices{Item, Dimensions, Whole, Alongs} <: AbstractArray{Item, Dimensions}
    whole::Whole
    alongs::Alongs
end
function Slices{Item, Dimensions}(
    whole::Whole,
    alongs::Alongs,
) where {Item, Dimensions, Whole, Alongs}
    Slices{Item, Dimensions, Whole, Alongs}(whole, alongs)
end

function axes(slices::Slices)
    getindex_unrolled(axes(slices.whole), map(not, slices.alongs))
end
function size(slices::Slices)
    map(length, axes(slices))
end

function slice_index(slices, indices)
    setindex_unrolled(axes(slices.whole), indices, map(not, slices.alongs))
end
@inline @propagate_inbounds function getindex(
    slices::Slices{Item, Dimensions},
    indices::Vararg{Int, Dimensions},
) where {Item, Dimensions}
    view(slices.whole, slice_index(slices, indices)...)
end
@inline @propagate_inbounds function setindex!(
    slices::Slices{Item, Dimensions},
    value,
    indices::Vararg{Int, Dimensions},
) where {Item, Dimensions}
    slices.whole[slice_index(slices, indices)...] = value
end

@inline function axis_or_1(switch, axis)
    if untyped(switch)
        axis
    else
        1
    end
end

"""
    Slices(whole, alongs::TypedBool...)

Slice `whole` into `view`s.

`alongs`, made of [`True`](@ref) and [`False`](@ref) objects, shows which dimensions will be replaced with `:` when slicing.

```jldoctest slices_bools
julia> using JuliennedArrays

julia> whole = [1 2; 3 4];

julia> slices = Slices(whole, False(), True())
2-element Slices{SubArray{$Int, 1}, 1}:
 [1, 2]
 [3, 4]

julia> slices[1] == whole[1, :]
true

julia> slices[1] = [2, 1];

julia> whole
2×2 Matrix{$Int}:
 2  1
 3  4

julia> larger = rand(5, 5, 5);

julia> larger_slices = Slices(larger, True(), False(), False());

julia> size(first(larger_slices))
(5,)
```

You must include one along for each dimension of `whole`.

```jldoctest slices_bools
julia> using Test: @test_throws

julia> @test_throws MethodError Slices(whole, True());
```
"""
function Slices(
    whole::AbstractArray{<:Any, Dimensions},
    alongs::Vararg{TypedBool, Dimensions},
) where {Dimensions}
    Slices{
        typeof(@inbounds view(whole, map(axis_or_1, alongs, axes(whole))...)),
        length(getindex_unrolled(alongs, map(not, alongs))),
    }(
        whole,
        alongs,
    )
end

"""
    Slices(whole, alongs::Int...)

Alternative syntax: `alongs` is which dimensions will be replaced with `:` when slicing.

```jldoctest slices_ints
julia> using JuliennedArrays

julia> input = reshape(1:8, 2, 2, 2)
2×2×2 reshape(::UnitRange{$Int}, 2, 2, 2) with eltype $Int:
[:, :, 1] =
 1  3
 2  4

[:, :, 2] =
 5  7
 6  8

julia> s = Slices(input, 1, 3)
2-element Slices{SubArray{$Int, 2}, 1}:
 [1 5; 2 6]
 [3 7; 4 8]

julia> map(sum, s)
2-element Vector{$Int}:
 14
 22
```

No along should be greater than the number of dimensions of `whole`.

```jldoctest slices_ints
julia> Slices(input, 4)
ERROR: ArgumentError: 4, a dimension number, is out of bounds or out of order.
[...]
```

You can infer the result if the dimensions are constant.

```jldoctest slices_ints
julia> using Test: @inferred

julia> slices_1_3(x) = Slices(x, 1, 3);

julia> @inferred slices_1_3(input)
2-element Slices{SubArray{$Int, 2}, 1}:
 [1 5; 2 6]
 [3 7; 4 8]
```
"""
@inline function Slices(
    whole::AbstractArray{Item, Dimensions},
    alongs::Int...,
) where {Item, Dimensions}
    Slices(whole, find_in(map(Val, alongs), ntuple(Val, Dimensions))...)
end

function Base.showarg(io::IO, ::Slices{Item, Dimensions}, toplevel) where {Item, Dimensions}
    print(
        io,
        "Slices{",
        basetype(Item),
        "{",
        eltype(Item),
        ", ",
        ndims(Item),
        "}, ",
        Dimensions,
        "}",
    )
end

# This is to be added to Julia (maybe under a different name)
# Follow https://github.com/JuliaLang/julia/issues/35543 for progress
function basetype(Item::Type)
    Base.typename(Item).wrapper
end
function basetype(Item)
    basetype(typeof(Item))
end

###
# Align
###
struct Align{Item, Dimensions, Sliced, Alongs, SliceAxes} <: AbstractArray{Item, Dimensions}
    slices::Sliced
    alongs::Alongs
    slice_axes::SliceAxes
end

function Align{Item, Dimensions}(
    slices::Sliced,
    alongs::NTuple{Dimensions, TypedBool},
    slice_axes::SliceAxes,
) where {Item, Dimensions, Sliced, SliceAxes}
    Align{Item, Dimensions, Sliced, typeof(alongs), SliceAxes}(slices, alongs, slice_axes)
end

function axes(aligned::Align)
    setindex_unrolled(
        setindex_unrolled(aligned.alongs, axes(aligned.slices), map(not, aligned.alongs)),
        aligned.slice_axes,
        aligned.alongs,
    )
end
function size(aligned::Align)
    map(length, axes(aligned))
end

function split_indices(aligned, indices)
    getindex_unrolled(indices, map(not, aligned.alongs)),
    getindex_unrolled(indices, aligned.alongs)
end
@inline @propagate_inbounds function getindex(
    aligned::Align{Item, Dimensions},
    indices::Vararg{Int, Dimensions},
) where {Item, Dimensions}
    outer, inner = split_indices(aligned, indices)
    aligned.slices[outer...][inner...]
end
@inline @propagate_inbounds function setindex!(
    aligned::Align{Item, Dimensions},
    value,
    indices::Vararg{Int, Dimensions},
) where {Item, Dimensions}
    outer, inner = split_indices(aligned, indices)
    aligned.slices[outer...][inner...] = value
end

"""
    Align(slices, alongs::TypedBool...; slice_axes = axes(first(slices)))

`Align` an array of arrays, all with the same size.

`alongs`, made of [`True`](@ref) and [`False`](@ref) objects, shows which dimensions will be taken up by the inner arrays. Inverse of [`Slices`](@ref).

```jldoctest align_bools
julia> using JuliennedArrays

julia> slices = [[1, 2], [3, 4]];

julia> aligned = Align(slices, False(), True())
2×2 Align{$Int, 2} with eltype $Int:
 1  2
 3  4

julia> aligned[1, :] == slices[1]
true

julia> aligned[1, 1] = 0;

julia> slices
2-element Vector{Vector{$Int}}:
 [0, 2]
 [3, 4]
```

Will throw an error if you try to align slices with different axes.
Use `@inbounds` to skip this check.

```jldoctest align_bools
julia> unequal = [[1], [1, 2]];

julia> Align(unequal, False(), True())
ERROR: ArgumentError: Slice [1, 2] does not have slice_axes (Base.OneTo(1),)
[...]
```

`slice_axes` is the axes of one slice.
If `slices` is empty, you can specify `slice_axes` manually.

```jldoctest align_bools
julia> Align([rand(3) for _ in 1:0], True(), False())
ERROR: BoundsError: attempt to access 0-element Vector{Vector{Float64}} at index [1]
[...]

julia> Align([rand(3) for _ in 1:0], True(), False(); slice_axes = axes(rand(3)))
3×0 Align{Float64, 2} with eltype Float64
```
"""
@inline @propagate_inbounds function Align(
    slices::AbstractArray{<:AbstractArray{Item, InnerDimensions}, OuterDimensions},
    alongs::TypedBool...;
    slice_axes = axes(first(slices)),
) where {Item, InnerDimensions, OuterDimensions}
    @boundscheck for slice in slices
        if axes(slice) != slice_axes
            throw(ArgumentError("Slice $slice does not have slice_axes $slice_axes."))
        end
    end
    Align{Item, OuterDimensions + InnerDimensions}(slices, alongs, slice_axes)
end

"""
    Align(slices, alongs::Int...)

Alternative syntax: `alongs` is which dimensions will be taken up by the inner arrays.

```jldoctest align_ints
julia> using JuliennedArrays

julia> input = reshape(1:8, 2, 2, 2)
2×2×2 reshape(::UnitRange{$Int}, 2, 2, 2) with eltype $Int:
[:, :, 1] =
 1  3
 2  4

[:, :, 2] =
 5  7
 6  8

julia> slices = Slices(input, 1, 3)
2-element Slices{SubArray{$Int, 2}, 1}:
 [1 5; 2 6]
 [3 7; 4 8]

julia> Align(slices, 1, 3)
2×2×2 Align{$Int, 3} with eltype $Int:
[:, :, 1] =
 1  3
 2  4

[:, :, 2] =
 5  7
 6  8
```

You must include one `along` for each inner dimension.

```jldoctest align_ints
julia> Align(slices, 1)
ERROR: ArgumentError: (1,) is not of length inner dimensions (2).
[...]
```

Julia can infer the result if `alongs` is constant.

```jldoctest align_ints
julia> using Test: @inferred

julia> align_1_3(x) = Align(x, 1, 3);

julia> @inferred align_1_3(slices)
2×2×2 Align{$Int, 3} with eltype $Int:
[:, :, 1] =
 1  3
 2  4

[:, :, 2] =
 5  7
 6  8 
```

`slice_axes` is the axes of one slice.
If `slices` is empty, you can specify `slice_axes` manually.

```jldoctest align_ints
julia> Align([rand(3) for _ in 1:0], 1)
ERROR: BoundsError: attempt to access 0-element Vector{Vector{Float64}} at index [1]
[...]

julia> Align([rand(3) for _ in 1:0], 1; slice_axes = axes(rand(3)))
3×0 Align{Float64, 2} with eltype Float64
```
"""
@inline @propagate_inbounds function Align(
    slices::AbstractArray{<:AbstractArray{Item, InnerDimensions}, OuterDimensions},
    alongs::Int...;
    slice_axes = axes(first(slices)),
) where {Item, InnerDimensions, OuterDimensions}
    if length(alongs) != InnerDimensions
        throw(
            ArgumentError("$alongs is not of length inner dimensions ($InnerDimensions)."),
        )
    end
    Align(
        slices,
        find_in(map(Val, alongs), ntuple(Val, InnerDimensions + OuterDimensions))...;
        slice_axes = slice_axes,
    )
end

function Base.showarg(io::IO, ::Align{Item, Dimensions}, toplevel) where {Item, Dimensions}
    print(io, "Align{", Item, ", ", Dimensions, "}")
    toplevel && print(io, " with eltype ", Item)
end

end # module
