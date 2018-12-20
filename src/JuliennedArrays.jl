module JuliennedArrays

import Base: length, axes, setindex!, getindex, @propagate_inbounds, collect, size, Generator, promote_op, map
import Base.Iterators: flatten
export flatten
using Keys: getindex_unrolled, setindex_unrolled, find_unrolled, True, False,
    not, fill_tuple, filter_unrolled

maybe_tuple(t::Tuple) = t
maybe_tuple(any) = (any,)

untuple(t) = t
untuple(t::Tuple{A} where A) = first(t)

struct Views{T, N, A, I} <: AbstractArray{T, N}
    parent::A
    locations::I
end

inner_eltype(array, locations) = view(array, maybe_tuple(first(locations))...)

Views(array::AbstractArray, locations::AbstractArray) =
    Views{
        promote_op(inner_eltype, typeof(array), typeof(locations)),
        ndims(locations),
        typeof(array),
        typeof(locations)
    }(array, locations)

axes(v::Views) = axes(v.locations)
size(v::Views) = size(v.locations)
length(v::Views) = length(v.locations)

@propagate_inbounds getindex(views::Views{T, N}, index::Vararg{Int, N}) where {T, N} =
    view(views.parent, maybe_tuple(views.locations[index...])...)

@propagate_inbounds Base.setindex!(views::Views, replacement, index::Vararg{Int, N}) where {T, N} =
    views.parent[maybe_tuple(views.locations[index...])...] = replacement

struct JulienneIndexer{T, N, IS, ID} <: AbstractArray{T, N}
    indexes::IS
    indexed::ID
end

axes(j::JulienneIndexer) = getindex_unrolled(j.indexes, j.indexed)
size(j::JulienneIndexer) = length.(axes(j))
length(j::JulienneIndexer) = prod(size(j))

getindex(j::JulienneIndexer{T, N}, index::Vararg{Int, N}) where {T, N} =
    setindex_unrolled(j.indexes, index, j.indexed)

JulienneIndexer(indexes, indexed) =
    JulienneIndexer{
        typeof(map(indexed, indexes) do switch, index
            if Bool(switch)
                1
            else
                index
            end
        end),
        length(getindex_unrolled(indexes, indexed)),
        typeof(indexes),
        typeof(indexed)
    }(indexes, indexed)

drop_tuple(t::Tuple{A}) where A = first(t)
drop_tuple(t) = t

colon_dimensions(j::JulienneIndexer) =
    drop_tuple(find_unrolled(not.(j.indexed)))

is_indexed(::typeof(*)) = True()
is_indexed(::typeof(:)) = False()
is_indexed(::True) = True()
is_indexed(::False) = False()

export julienne
"""
    julienne(array, code)

Slice `array` and create views. The code should a tuple of length
`ndims(array)`, where `:` indicates an axis parallel to slices and `*` axes an
axis perpendicular to slices.

```jldoctest
julia> using JuliennedArrays

julia> array = [5 6 4; 1 3 2; 7 9 8]
3×3 Array{Int64,2}:
 5  6  4
 1  3  2
 7  9  8

julia> map(sum, julienne(array, (*, :)))
3-element Array{Int64,1}:
 15
  6
 24
```
"""
julienne(array, code) =
    Views(array, JulienneIndexer(axes(array), is_indexed.(code)))

"Parent is required to have at least one child"
struct FlattenedArray{T, N, Parent, Indexed} <: AbstractArray{T, N}
    parent::Parent
    indexed::Indexed
end

const trivial = Base.OneTo(1)

function axes(f::FlattenedArray)
    indexed = f.indexed
    array = f.parent
    fill_tuple(indexed, trivial) |>
        x -> setindex_unrolled(x, axes(array), indexed) |>
        x -> setindex_unrolled(x, axes(first(array)), not.(indexed))
end
size(f::FlattenedArray) = length.(axes(f))
IndexStyle(f::FlattenedArray) = IndexStyle(f.parent)
@propagate_inbounds function Base.getindex(f::FlattenedArray{T, N}, i::Vararg{Int, N}) where {T, N}
    indexed = f.indexed
    f.parent[getindex_unrolled(i, indexed)...][getindex_unrolled(i, not.(indexed))...]
end

default_code(nested_array::AbstractArray{<:AbstractArray{T, N}, M}) where {T, N, M} =
    (ntuple(x -> (*), Val(M))..., ntuple(x -> (:), Val(N))...)

FlattenedArray(
    a::AbstractArray{<:AbstractArray{T, N}, M},
    indexed
) where {T, N, M} =
    FlattenedArray{T, N + M, typeof(a), typeof(indexed)}(a, indexed)

"""
    flatten(a::AbstractArray{<:AbstractArray}, code = default_code(a))

Align an array of slices into a larger array. Code should be a tuple with an
entry for each dimension of the desired output. Slices will slide into
dimensions coded by `:`, while `*` indicates dimensions taken up by the
container array. Each slice should be EXACTLY the same size. The default
code will be `*` for each outer dimension followed by `:` for each inner
dimension.

```jldoctest
julia> using JuliennedArrays, MappedArrays

julia> code = (*, :);

julia> array = [5 6 4; 1 3 2]
2×3 Array{Int64,2}:
 5  6  4
 1  3  2

julia> f = mappedarray(sort, julienne(array, code)) |> flatten
2×3 JuliennedArrays.FlattenedArray{Int64,2,ReadonlyMappedArray{Array{Int64,1},1,JuliennedArrays.Views{SubArray{Int64,1,Array{Int64,2},Tuple{Int64,Base.OneTo{Int64}},true},1,Array{Int64,2},JuliennedArrays.JulienneIndexer{Tuple{Int64,Base.OneTo{Int64}},1,Tuple{Base.OneTo{Int64},Base.OneTo{Int64}},Tuple{Keys.True,Keys.False}}},typeof(sort)},Tuple{Keys.True,Keys.False}}:
 4  5  6
 1  2  3

julia> collect(f)
2×3 Array{Int64,2}:
 4  5  6
 1  2  3
```
"""
flatten(a::AbstractArray{<:AbstractArray}, code = default_code(a)) =
    FlattenedArray(a, is_indexed.(code))

@propagate_inbounds function collect(f::FlattenedArray)
    arrays = f.parent
    output = similar(f)
    output_slices = julienne(output, f.indexed)
    output_slices .= arrays
    output
end

export Reduce
"""
    struct Reduce{F}

Reduction of another function. Enables optimizations in some cases.

```jldoctest
julia> using JuliennedArrays

julia> array = [5 6 4; 1 3 2; 7 9 8]
3×3 Array{Int64,2}:
 5  6  4
 1  3  2
 7  9  8

julia> map(Reduce(+), julienne(array, (*, :)))
3×1 Array{Int64,2}:
 15
  6
 24

julia> array = reshape(1:8, 2, 2, 2)
2×2×2 reshape(::UnitRange{Int64}, 2, 2, 2) with eltype Int64:
[:, :, 1] =
 1  3
 2  4

[:, :, 2] =
 5  7
 6  8

julia> map(Reduce(+), julienne(array, (:, *, :)))
1×2×1 Array{Int64,3}:
[:, :, 1] =
 14  22
```
"""
struct Reduce{F}
    f::F
end

(r::Reduce)(x) = reduce(r.f, x)

export JuliennedArray
const JuliennedArray = Views{T, N, A, I} where {T, N, A, I <: JulienneIndexer}

map(r::Reduce, j::JuliennedArray) =
    mapreduce(identity, r.f, j.parent, dims = colon_dimensions(j.locations))

end
