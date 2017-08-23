using BenchmarkTools

const array = reshape(1:9, 3, 3)
const big_array = rand(1000, 1000)

test1(array) = map(sum, julienne(array, (:, *)))
test2(array) = combine(Base.Generator(sort, julienne(array, (:, *))))
test3(array) = map(Reduction(+), julienne(array, (:, *)))

println("map, small")
@btime mapslices(sum, array, 1)
@btime test1(array)
@btime test3(array)
@btime sum(array, 1)

println("map, big")
@btime @inbounds mapslices(sum, big_array, 1)
@btime @inbounds test1(big_array)
@btime @inbounds test3(big_array)
@btime @inbounds sum(big_array, 1)

println("combine, small")
@btime mapslices(sort, array, 1)
@btime test2(array)
@btime sort(array, 1)

println("combine, large")
@btime @inbounds mapslices(sort, big_array, 1)
@btime @inbounds test2(big_array)
@btime @inbounds sort(big_array, 1)
