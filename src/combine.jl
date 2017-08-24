Base.@propagate_inbounds none(array, index, swap) = array[index...]
Base.@propagate_inbounds swap!(array, index, swap) = Base._unsafe_getindex!(swap, array, index...)

is_swappable(first_input, first_output) = none
is_swappable(first_input::StridedArray, first_output::Number) = swap!
is_swappable(first_input::StridedArray, first_output::AbstractArray{T} where T <: Number) = swap!

map_make(input_indexer::JulienneIndexer, first_output) = begin
    indexed = input_indexer.indexed
    output_indexes = fill_index(input_indexer.indexes, 1, not.(indexed))
    output = similar(Array{typeof(first_output)}, output_indexes...)
    output_indexer = JulienneIndexer(output_indexes, indexed)
    @inbounds output[first(output_indexer)...] = first_output
    output, output_indexer
end

combine_make(input_indexer::JulienneIndexer, first_output) = begin
    indexed = input_indexer.indexed
    output_indexes = set_fill_index(
        input_indexer.indexes,
        indices(first_output),
        not.(indexed),
        Base.OneTo(1)
    )
    output = similar(first_output, output_indexes...)
    output_indexer = JulienneIndexer(output_indexes, indexed)
    @inbounds output[first(output_indexer)...] .= first_output
    output, output_indexer
end

Base.@propagate_inbounds map_update(array, update, index) =
    array[index...] = update

Base.@propagate_inbounds combine_update(array, update, index) =
    array[index...] .= update

function map_template(f, r, make, update)
    input_indexer = r.indexer
    input = r.array

    first_input = input[first(input_indexer)...]
    first_output = f(first_input)
    maybe_swap = is_swappable(first_input, first_output)

    output, output_indexer = make(input_indexer, first_output)
    for index in Iterators.Drop(input_indexer, 1)
        an_output = f(maybe_swap(input, first(next(input_indexer, index)), first_input))
        @inbounds update(output, an_output, first(next(output_indexer, index)))
    end
    output
end

abstract type FunctionOptimization end
struct None{F} <: FunctionOptimization; f::F; end
struct Reduction{F} <: FunctionOptimization; f::F; end
struct OutOfPlaceArray{F} <: FunctionOptimization; f::F; end
optimization(f) = None(f)
optimization(::typeof(median)) = None(median!)
optimization(::typeof(sum)) = Reduction(+)
optimization(::typeof(prod)) = Reduction(*)
optimization(::typeof(maximum)) = Reduction(scalarmax)
optimization(::typeof(minimum)) = Reduction(scalarmin)
optimization(::typeof(all)) = Reduction(&)
optimization(::typeof(any)) = Reduction(|)
optimization(::typeof(mean)) = OutOfPlaceArray(mean!)

# TODO: varm, var, std

colon_dimensions(r::ReindexedArray{T, N, A, I}) where {T, N, A, I <: JulienneIndexer} =
    find_tuple(not.(r.indexer.indexed))

"""
    Base.map(r::ReindexedArray)

```jldoctest
julia> using JuliennedArrays

julia> array = reshape(1:9, 3, 3)
3×3 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:
 1  4  7
 2  5  8
 3  6  9

julia> map(sum, julienne(array, (:, *)))
1×3 Array{Int64,2}:
 6  15  24

julia> map(median, julienne(array, (:, *)))
1×3 Array{Float64,2}:
 2.0  5.0  8.0

julia> map(mean, julienne(array, (:, *)))
1×3 Array{Float64,2}:
 2.0  5.0  8.0
```
"""
Base.map(f, r::ReindexedArray) = Base.map(optimization(f), r)

Base.map(f::FunctionOptimization, r::ReindexedArray) =
    map_template(f.f, r, map_make, map_update)

Base.map(f::Reduction, r::ReindexedArray{T, N, A, I}) where {T, N, A, I <: JulienneIndexer} =
    mapreducedim(identity, f.f, r.array, colon_dimensions(r))

Base.map(f::OutOfPlaceArray, r::ReindexedArray{T, N, A, I}) where {T, N, A, I <: JulienneIndexer} = begin
    array = r.array
    f.f(Base.reducedim_initarray(array, colon_dimensions(r), 0, Base.momenttype(eltype(array))), array)
end

export combine
"""
    combine(pieces)

Combine many pieces of an array.

```jldoctest
julia> using JuliennedArrays

julia> array = reshape([1 3 2; 5 6 4; 7 9 8], 3, 3)
3×3 Array{Int64,2}:
 1  3  2
 5  6  4
 7  9  8

julia> combine(Base.Generator(sort, julienne(array, (*, :))))
3×3 Array{Int64,2}:
 1  2  3
 4  5  6
 7  8  9
```
"""
combine(g::Base.Generator{T} where T <: ReindexedArray) =
    map_template(g.f, g.iter, combine_make, combine_update)
