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

julienne_iterator(array, julienne_code) = JulienneIterator(indices(array), julienne_code)

dropped_range(array, julienne_code) =
    fill_index(indices(array), 1, not.(is_iterated.(julienne_code)))

dropping_julienne_iterator(array, julienne_code) =
    JulienneIterator(dropped_range(array, julienne_code), julienne_code)

struct ReiteratedArray{ArrayType, IteratorType}
    array::ArrayType
    iterator::IteratorType
end

inner_iterator(a::ReiteratedArray) = a.iterator

@iterator_wrapper ReiteratedArray function (r, index)
    @view r.array[index...]
end

export julienne
"""
    julienne(array, julienne_code)

Change `atype` between ViewingReiteratedArray and IndexingReiteratedArray

```jldoctest
julia> using JuliennedArrays

julia> array = reshape([1 3 2; 5 6 4; 7 9 8], 3, 3)
3×3 Array{Int64,2}:
 1  3  2
 5  6  4
 7  9  8

julia> begin
            foreach(sort!, julienne(array, (*, :)))
            array
        end
3×3 Array{Int64,2}:
 1  2  3
 4  5  6
 7  8  9
```
"""
julienne(array, julienne_code) =
    ReiteratedArray(array, julienne_iterator(array, julienne_code))
