module JuliennedArrays

import Base: axes, getindex, Int, setindex!, size
using Base: @inline, @propagate_inbounds, @pure, tail

export Slices, Align
export True, False

function is_in(::Needle, ::Needle, _...) where {Needle}
    True()
end
function is_in(needle, _, straws...)
    is_in(needle, straws...)
end
function is_in(_)
    False()
end

function in_unrolled(straws, needle1, needles...)
    is_in(needle1, straws...), in_unrolled(straws, needles...)...
end
function in_unrolled(_)
    ()
end

@pure function as_vals(them::Int...)
    map(Val, them)
end

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

###
# Slices
###
struct Slices{Item,Dimensions,Whole,Alongs} <: AbstractArray{Item,Dimensions}
    whole::Whole
    alongs::Alongs
end
function Slices{Item,Dimensions}(whole::Whole, alongs::Alongs) where {Item,Dimensions,Whole,Alongs}
    Slices{Item,Dimensions,Whole,Alongs}(whole, alongs)
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
    slices::Slices{Item,Dimensions},
    indices::Vararg{Int,Dimensions},
) where {Item,Dimensions}
    view(slices.whole, slice_index(slices, indices)...)
end
@inline @propagate_inbounds function setindex!(
    slices::Slices{Item,Dimensions},
    value,
    indices::Vararg{Int,Dimensions},
) where {Item,Dimensions}
    slices.whole[slice_index(slices, indices)...] = value
end

function axis_or_1(switch, axis)
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
    whole::AbstractArray{<:Any,Dimensions},
    alongs::Vararg{TypedBool,Dimensions},
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
ERROR: ArgumentError: All alongs values (4,) should be less than or equal to 3
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
    whole::AbstractArray{Item,Dimensions},
    alongs::Int...,
) where {Item,Dimensions}
    value_alongs = as_vals(alongs...)
    value_dimensions = ntuple(Val, Dimensions)
    if untyped(is_in(False(), in_unrolled(value_dimensions, value_alongs...)...))
        throw(
            ArgumentError(
                "All alongs values $(alongs) should be less than or equal to $(Dimensions)",
            ),
        )
    end
    Slices(whole, in_unrolled(value_alongs, value_dimensions...)...)
end

function Base.showarg(io::IO, ::Slices{Item,Dimensions}, toplevel) where {Item,Dimensions}
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

@inline function Int(::True)
    1
end
@inline function Int(::False)
    0
end

function match_dimensions(has_dimensions, used_dimensions::Int)
    if used_dimensions !== has_dimensions
        throw(
            DimensionMismatch(
                "$used_dimensions of $has_dimensions inner dimensions are used",
            ),
        )
    end
end

function check_dimensions(has_dimensions, ::Vararg{Int,Dimensions}) where {Dimensions}
    match_dimensions(has_dimensions, Dimensions)
end

function check_dimensions(has_dimensions, alongs::Vararg{TypedBool})
    match_dimensions(has_dimensions, mapreduce(Int, +, alongs))
end

function check_sizes(slices, alongs...)
    if !isempty(slices)
        first_slice = first(slices)
        first_axes = axes(first_slice)
        check_dimensions(ndims(first_slice), alongs...)
        for slice in slices
            if axes(slice) != first_axes
                throw(
                    ArgumentError(
                        "Axes of $slice does not match the axes of the first slice: $first_axes",
                    ),
                )
            end
        end
    end
end

###
# Align
###
struct Align{Item,Dimensions,Sliced,Alongs} <: AbstractArray{Item,Dimensions}
    slices::Sliced
    alongs::Alongs
end

function Align{Item,Dimensions}(
    slices::Sliced,
    alongs::NTuple{Dimensions,TypedBool},
) where {Item,Dimensions,Sliced}
    Align{Item,Dimensions,Sliced,typeof(alongs)}(slices, alongs)
end

function axes(aligned::Align)
    setindex_unrolled(
        setindex_unrolled(aligned.alongs, axes(aligned.slices), map(not, aligned.alongs)),
        axes(first(aligned.slices)),
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
    aligned::Align{Item,Dimensions},
    indices::Vararg{Int,Dimensions},
) where {Item,Dimensions}
    outer, inner = split_indices(aligned, indices)
    aligned.slices[outer...][inner...]
end
@inline @propagate_inbounds function setindex!(
    aligned::Align{Item,Dimensions},
    value,
    indices::Vararg{Int,Dimensions},
) where {Item,Dimensions}
    outer, inner = split_indices(aligned, indices)
    aligned.slices[outer...][inner...] = value
end

"""
    Align(slices, alongs::TypedBool...)

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
ERROR: ArgumentError: Axes of [1, 2] does not match the axes of the first slice: (Base.OneTo(1),)
[...]
```
"""
@inline @propagate_inbounds function Align(
    slices::AbstractArray{<:AbstractArray{Item,InnerDimensions},OuterDimensions},
    alongs::TypedBool...,
) where {Item,InnerDimensions,OuterDimensions}
    @boundscheck check_sizes(slices, alongs...)
    Align{Item,OuterDimensions + InnerDimensions}(slices, alongs)
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
ERROR: DimensionMismatch("1 of 2 inner dimensions are used")
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
"""
@inline @propagate_inbounds function Align(
    slices::AbstractArray{<:AbstractArray{Item,InnerDimensions},OuterDimensions},
    alongs::Int...,
) where {Item,InnerDimensions,OuterDimensions}
    @boundscheck check_sizes(slices, alongs...)
    Align(
        slices,
        in_unrolled(
            as_vals(alongs...),
            ntuple(Val, InnerDimensions + OuterDimensions)...,
        )...,
    )
end

function Base.showarg(io::IO, ::Align{Item,Dimensions}, toplevel) where {Item,Dimensions}
    print(io, "Align{", Item, ", ", Dimensions, "}")
    toplevel && print(io, " with eltype ", Item)
end

end # module
