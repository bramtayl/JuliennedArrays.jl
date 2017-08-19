maybe_wrap(a::AbstractArray{T, 0} where T) = [a]
maybe_wrap(a::AbstractArray) = a
maybe_wrap(any) = [any]

export combine

combine(j::IteratedArray) = j.array

"""
    combine(array)

Combine an array that has been julienned (or otherwise split).

```jldoctest
julia> using JuliennedArrays

julia> array = reshape(1:9, 3, 3)
3×3 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:
 1  4  7
 2  5  8
 3  6  9

julia> begin
            julienned = julienne(array, (:, *))
            mapped = map(sum, julienned)
            combine(mapped)
        end
1×3 Array{Int64,2}:
 6  15  24
```
"""
function combine(g::Base.Generator{T1} where T1 <: (IteratedArray{T2, T3} where T3 <: JulienneIterator where T2) )
    iterated_array = g.iter
    input_iterator = inner_iterator(iterated_array)
    first_return = maybe_wrap(first(g))
    result = similar(first_return, set_fill_index(
        indices(iterated_array.array),
        indices(first_return),
        not.(is_iterated.(input_iterator.julienne_code)),
        Base.OneTo(1)
    )...)
    julienned_result = julienne(result, input_iterator.julienne_code)
    first(julienned_result) .= first_return
    for index in Iterators.Drop(inner_iterator(input_iterator), 1)
        first(next(julienned_result, index)) .= first(next(g, index))
    end
    result
end
