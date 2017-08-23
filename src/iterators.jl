struct JulienneIterator{Indices, Iterated, Iterator}
    indices::Indices
    iterated::Iterated
    iterator::Iterator
end

JulienneIterator(indices, iterated) =
    JulienneIterator(indices, iterated,
        CartesianRange(get_index(indices, iterated)))

Base.start(j::JulienneIterator) = start(j.iterator)
Base.done(j::JulienneIterator, state) = done(j.iterator, state)
Base.next(j::JulienneIterator, state) = begin
    index, next_state = next(j.iterator, state)
    set_index(j.indices, index.I, j.iterated), next_state
end

struct ReiteratedArray{ArrayType, IteratorType}
    array::ArrayType
    iterator::IteratorType
end

julienne(array, julienne_code) =
    ReiteratedArray(array, JulienneIterator(indices(array), is_iterated.(julienne_code)))
