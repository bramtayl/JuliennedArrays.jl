Base.@propagate_inbounds none(array, index, swap) = array[index...]
Base.@propagate_inbounds swap!(array, index, swap) = Base._unsafe_getindex!(swap, array, index...)

optimization(first_input, first_output) = none
optimization(first_input::StridedArray, first_output::Number) = swap!
optimization(first_input::StridedArray, first_output::AbstractArray{T} where T <: Number) = swap!

map_make(input_iterator::JulienneIterator, first_output) = begin
    iterated = input_iterator.iterated
    output_indexes = fill_index(input_iterator.indexes, 1, not.(iterated))
    output = similar(Array{typeof(first_output)}, output_indexes...)
    output_iterator = JulienneIterator(output_indexes, iterated)
    @inbounds output[first(output_iterator)...] = first_output
    output, output_iterator
end

combine_make(input_iterator::JulienneIterator, first_output) = begin
    iterated = input_iterator.iterated
    output_indexes = set_fill_index(
        input_iterator.indexes,
        indices(first_output),
        not.(iterated),
        Base.OneTo(1)
    )
    output = similar(first_output, output_indexes...)
    output_iterator = JulienneIterator(output_indexes, iterated)
    @inbounds output[first(output_iterator)...] .= first_output
    output, output_iterator
end

Base.@propagate_inbounds map_update(array, update, index) =
    array[index...] = update

Base.@propagate_inbounds combine_update(array, update, index) =
    array[index...] .= update

function map_template(f, r, make, update)
    input_iterator = r.iterator
    input = r.array

    first_input = input[first(input_iterator)...]
    first_output = f(first_input)
    maybe_swap = optimization(first_input, first_output)

    output, output_iterator = make(input_iterator, first_output)
    for index in Iterators.Drop(input_iterator, 1)
        an_output = f(maybe_swap(input, first(next(input_iterator, index)), first_input))
        @inbounds update(output, an_output, first(next(output_iterator, index)))
    end
    output
end

"""
    Base.map(r::ReiteratedArray)

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
```
"""
Base.map(f, r::ReiteratedArray) = map_template(f, r, map_make, map_update)

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
combine(g::Base.Generator{T} where T <: ReiteratedArray) =
    map_template(g.f, g.iter, combine_make, combine_update)
