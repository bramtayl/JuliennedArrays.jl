import Base.tail

macro iterator_wrapper(atype, afunction)
    quote
        $Base.start(a::$atype) = $start($inner_iterator(a))
        $Base.length(a::$atype) = $length($inner_iterator(a))
        $Base.done(a::$atype, state) = $done($inner_iterator(a), state)
        $Base.next(a::$atype, state) = begin
            item, next_state = $next($inner_iterator(a), state)
            $afunction(a, item), next_state
        end
    end |> esc
end

struct JulienneIterator{OldIndicesType, JulienneCodeType}
    old_indices::OldIndicesType
    julienne_code::JulienneCodeType
end

inner_iterator(j::JulienneIterator) = CartesianRange(get_index(j.old_indices, is_iterated.(j.julienne_code)))

@iterator_wrapper JulienneIterator function (j, index)
    set_index(j.old_indices, index.I, is_iterated.(j.julienne_code))
end

export julienne_iterator
"""
    julienne_iterator(array, julienne_code)

`julienne_code` should be a tuple of either `*` (for dimensions to be sliced
over) or `:` for dimenisons to be sliced across. See the example below for
clarification.

```jldoctest
julia> using JuliennedArrays

julia> array = reshape(1:9, 3, 3)
3×3 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:
 1  4  7
 2  5  8
 3  6  9

julia> begin
            iterator = julienne_iterator(array, (:, *))
            map(identity, iterator)
        end
3-element Array{Tuple{Base.OneTo{Int64},Int64},1}:
 (Base.OneTo(3), 1)
 (Base.OneTo(3), 2)
 (Base.OneTo(3), 3)
```
"""
julienne_iterator(array, julienne_code) = JulienneIterator(indices(array), julienne_code)

struct ReiteratedArray{ArrayType, IteratorType}
    array::ArrayType
    iterator::IteratorType
end

inner_iterator(a::ReiteratedArray) = a.iterator

Base.map(f, i::ReiteratedArray) = Base.Generator(f, i)
Base.broadcast(f, i::ReiteratedArray) = Base.Generator(f, i)

@iterator_wrapper ReiteratedArray (a, index) -> @view a.array[index...]

export julienne
"""
    julienne(array, julienne_code)

```jldoctest
julia> using JuliennedArrays

julia> array = reshape(1:9, 3, 3)
3×3 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:
 1  4  7
 2  5  8
 3  6  9

julia> begin
            julienned = julienne(array, (:, *))
            mapped = map(identity, julienned)
            collect(mapped)
        end
3-element Array{SubArray{Int64,1,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}},Tuple{Base.OneTo{Int64},Int64},true},1}:
 [1, 2, 3]
 [4, 5, 6]
 [7, 8, 9]
```
"""
julienne(array, julienne_code) = ReiteratedArray(array, julienne_iterator(array, julienne_code))
