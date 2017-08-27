combine(g::Base.Generator) = collect(g)

apply_first(f::FunctionOptimization, input, input_index) = begin
    first_input = input[input_index...]
    first_input, f.f(first_input)
end
apply_first(f::View, input, input_index) = begin
    first_input = @view input[input_index...]
    first_input, f.f(first_input)
end

reoptimize(f, first_input, first_output) =
    f
reoptimize(f::None, first_input::StridedArray, first_output::Number) =
    Swap(f.f)
reoptimize(f::None, first_input::StridedArray, first_output::AbstractArray{<: Number}) =
    Swap(f.f)

apply(reoptimized::FunctionOptimization, input, input_index, first_input) =
    reoptimized.f(input[input_index...])
apply(reoptimized::Swap, input, input_index, first_input) =
    reoptimized.f(Base._unsafe_getindex!(first_input, input, input_index...))
apply(reoptimized::View, input, input_index, first_input) =
    reoptimized.f(@view input[input_index...])

"""
    Base.map!(f, output, r::ReindexedArray)

```jldoctest
julia> using JuliennedArrays

julia> array = reshape(1:9, 3, 3)
3×3 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:
 1  4  7
 2  5  8
 3  6  9

julia> output = Array{Int}(3);

julia> map!(sum, output, julienne(array, (*, :)));

julia> output
3-element Array{Int64,1}:
 12
 15
 18
```
"""
Base.map!(f, output, r) = map!(optimization(f), output, r)

Base.map!(f::FunctionOptimization, output, r) = begin
    input_indexer = r.indexer
    input = r.array

    first_input, first_output = apply_first(f, input, first(input_indexer))
    reoptimized = reoptimize(f, first_input, first_output)

    output_indexes =
        fill_index(input_indexer.indexes, 1, not.(input_indexer.indexed))
    @boundscheck indices(output) == output_indexes
    output_indexer = change_indexes(input_indexer, output_indexes)
    @inbounds output[first(output_indexer)...] = first_output
    for index in Iterators.Drop(input_indexer, 1)
        an_output = apply(reoptimized, input, first(next(input_indexer, index)), first_input)
        @inbounds output[first(next(output_indexer, index))...] = an_output
    end
    output
end

colon_dimensions(r::ReindexedArray{T, N, A, I}) where {T, N, A, I <: JulienneIndexer} =
    drop_tuple(find_tuple(not.(r.indexer.indexed)))

"""
    Base.map(f, r::ReindexedArray)

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

Base.map(f::FunctionOptimization, r::ReindexedArray) = begin
    input_indexer = r.indexer
    input = r.array

    first_input, first_output = apply_first(f, input, first(input_indexer))
    reoptimized = reoptimize(f, first_input, first_output)

    output_indexes =
        fill_index(input_indexer.indexes, 1, not.(input_indexer.indexed))
    output = similar(Array{typeof(first_output)}, output_indexes...)
    output_indexer = change_indexes(input_indexer, output_indexes)
    @inbounds output[first(output_indexer)...] = first_output
    for index in Iterators.Drop(input_indexer, 1)
        an_output = apply(reoptimized, input, first(next(input_indexer, index)), first_input)
        @inbounds output[first(next(output_indexer, index))...] = an_output
    end
    output
end

Base.map(f::Reduction, r::ReindexedArray{T, N, A, I}) where {T, N, A, I <: JulienneIndexer} =
    mapreducedim(identity, f.f, r.array, colon_dimensions(r))

Base.map(f::OutOfPlaceArray, r::ReindexedArray{T, N, A, I}) where {T, N, A, I <: JulienneIndexer} = begin
    array = r.array
    f.f(Base.reducedim_initarray(array, colon_dimensions(r), 0, Base.momenttype(eltype(array))), array)
end

map_combine(f, r) = map_combine(optimization(f), r)
function map_combine(f::FunctionOptimization, r)
    input_indexer = r.indexer
    input = r.array

    first_input, first_output = apply_first(f, input, first(input_indexer))
    reoptimized = reoptimize(f, first_input, first_output)

    output_indexes = set_fill_index(
        input_indexer.indexes,
        indices(first_output),
        not.(input_indexer.indexed),
        Base.OneTo(1)
    )
    output = similar(first_output, output_indexes...)
    output_indexer = change_indexes(input_indexer, output_indexes)
    @inbounds output[first(output_indexer)...] .= first_output
    for index in Iterators.Drop(input_indexer, 1)
        an_output = apply(reoptimized, input, first(next(input_indexer, index)), first_input)
        @inbounds output[first(next(output_indexer, index))...] .= an_output
    end
    output
end

export combine
"""
    combine(pieces)

Combine many pieces of an array.

```jldoctest
julia> using JuliennedArrays

julia> array = [1 3 2; 5 6 4; 7 9 8]
3×3 Array{Int64,2}:
 1  3  2
 5  6  4
 7  9  8

julia> result = combine(Base.Generator(sort, julienne(array, (*, :))))
3×3 Array{Int64,2}:
 1  2  3
 4  5  6
 7  8  9

julia> array == result
false

julia> result2 = combine(Base.Generator(View(sort!), julienne(array, (*, :))))
3×3 Array{Int64,2}:
 1  2  3
 4  5  6
 7  8  9

julia> array == result2
true
```
"""
combine(g::Base.Generator{<: ReindexedArray}) =
    map_combine(g.f, g.iter)
