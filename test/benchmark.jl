using BenchmarkTools, JuliennedArrays, MappedArrays

const array = reshape(1:9, 3, 3)
const big_array = rand(1000, 1000)
const code = (:, *)

sum_test(array) = map(sum, julienne(Swaps, array, code))
sort_test(array) = align(mappedarray(sort, julienne(Swaps, array, code)), code)
sum_non_optimized_test(array) = map(x -> sum(+, x), julienne(Swaps, array, code))
sort_view_test(array) = align(mappedarray(sort, julienne(Views, array, code)), code)

println("map, small")
@btime @inbounds mapslices(sum, array, 1)
@btime @inbounds sum_non_optimized_test(array)
@btime @inbounds sum_test(array)
@btime @inbounds sum(array, 1)

println("map, big")
@btime @inbounds mapslices(sum, big_array, 1)
@btime @inbounds sum_non_optimized_test(big_array)
@btime @inbounds sum_test(big_array)
@btime @inbounds sum(big_array, 1)

println("combine, small")
@btime @inbounds mapslices(sort, array, 1)
@btime @inbounds sort_test(array)
@btime @inbounds sort_view_test(array)
@btime @inbounds sort(array, 1)

println("combine, large")
@btime @inbounds mapslices(sort, big_array, 1)
@btime @inbounds sort(big_array, 1)
@btime @inbounds sort_test(big_array)
@btime @inbounds sort_view_test(big_array)
