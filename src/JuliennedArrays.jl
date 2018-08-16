module JuliennedArrays

import Base: length, axes, setindex!, getindex, @propagate_inbounds, map
using Keys: getindex_unrolled, setindex_unrolled, find_unrolled, True, False,
    not, fill_tuple

maybe_tuple(t::Tuple) = t
maybe_tuple(any) = (any,)

untuple(t) = t
untuple(t::Tuple{A} where A) = first(t)

struct Views{T, N, A, I} <: AbstractArray{T, N}
    array::A
    locations::I
end

Views(array::AbstractArray, locations::AbstractArray) =
    Views{
        typeof(@view array[maybe_tuple(first(locations))...]),
        ndims(locations),
        typeof(array),
        typeof(locations)
    }(array, locations)

axes(v::Views) = axes(v.locations)
length(v::Views) = length(v.locations)

@propagate_inbounds getindex(views::Views{T, N}, index::Vararg{Int, N}) where {T, N} =
    @view views.array[maybe_tuple(views.locations[index...])...]

@propagate_inbounds Base.setindex!(views::Views, replacement, index::Vararg{Int, N}) where {T, N} =
    views.array[maybe_tuple(views.locations[index...])...] = replacement

struct JulienneIndexer{T, N, IS, ID} <: AbstractArray{T, N}
    indexes::IS
    indexed::ID
end

axes(j::JulienneIndexer) = getindex_unrolled(j.indexes, j.indexed)
length(j::JulienneIndexer) = prod(length.(axes(j)))

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

export julienne
"""
    julienne(array, code)

Slice an array and create views. The code should a tuple of length
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

export align
"""
    align(slices, code)

Align an array of slices into a larger array. Code should be a tuple with an
entry for each dimension of the desired output. Slices will slide into
dimensions coded by `:`, while `*` indicates dimensions taken up by the
container array. Each slice should be EXACTLY the same size.

```jldoctest
julia> using JuliennedArrays, MappedArrays

julia> code = (*, :);

julia> array = [5 6 4; 1 3 2]
2×3 Array{Int64,2}:
 5  6  4
 1  3  2

julia> views = julienne(array, code);

julia> align(mappedarray(sort, views), code)
2×3 Array{Int64,2}:
 4  5  6
 1  2  3
```
"""
function align(input_slices::AbstractArray{<: AbstractArray}, code)
    indexed = is_indexed.(code)
    first_input_slice = first(input_slices)
    trivial = Base.OneTo(1)

    output_indexes =
        fill_tuple(indexed, trivial) |>
        x -> setindex_unrolled(x, axes(input_slices), indexed) |>
        x -> setindex_unrolled(x, axes(first_input_slice), not.(indexed))

    output = similar(first_input_slice, output_indexes...)
    output_slices = julienne(output, code)

    output_slices[1] = first_input_slice
    for i in Iterators.Drop(eachindex(input_slices), 1)
        output_slices[i] = input_slices[i]
    end
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

(r::Reduce)(x) = r.f(x)

export JuliennedArray
const JuliennedArray = Views{T, N, A, I} where {T, N, A, I <: JulienneIndexer}

map(r::Reduce, s::JuliennedArray) =
    mapreduce(identity, r.f, s.array, dims = colon_dimensions(s.locations))

end
