none(array, index, swap) = array[index...]
swap!(array, index, swap) = Base._unsafe_getindex!(swap, array, index...)

optimization(first_input, first_output) = none
optimization(first_input::StridedArray, first_output::Number) = swap!
optimization(first_input::StridedArray, first_output::AbstractArray{T} where T <: Number) = swap!

map_make(input_iterator::JulienneIterator, input, first_output) = begin
    julienne_code = input_iterator.julienne_code
    output = similar(Array{typeof(first_output)},
        dropped_range(input, julienne_code)...)
    output_iterator = dropping_julienne_iterator(output, julienne_code)
    @inbounds output[first(output_iterator)...] = first_output
    output, output_iterator
end

combine_make(input_iterator::JulienneIterator, input, first_output) = begin
    julienne_code = input_iterator.julienne_code
    output = similar(first_output, set_fill_index(
        indices(input),
        indices(first_output),
        not.(is_iterated.(julienne_code)),
        Base.OneTo(1)
    )...)
    output_iterator = julienne_iterator(output, julienne_code)
    @inbounds output[first(output_iterator)...] .= first_output
    output, output_iterator
end

map_update(array, update, index) =
    array[index...] = update

@inline combine_update(array, update, index) =
    array[index...] .= update

function map_template(f, r, make, update)
    input_iterator = inner_iterator(r)
    input = r.array
    julienne_code = input_iterator.julienne_code

    first_input = input[first(input_iterator)...]
    first_output = f(first_input)
    maybe_swap = optimization(first_input, first_output)

    output, output_iterator = make(input_iterator, input, first_output)
    index = first(Iterators.Drop(inner_iterator(input_iterator), 1))
    for index in Iterators.Drop(inner_iterator(input_iterator), 1)
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
combine(g::Base.Generator{T} where T <: ReiteratedArray) = map_template(g.f, g.iter, combine_make, combine_update)
