using BenchmarkTools

const array = reshape(1:9, 3, 3)
const big_array = rand(1000, 1000)

sum_test(array) = map(sum, julienne(array, (:, *)))
sort_test(array) = combine(Base.Generator(sort, julienne(array, (:, *))))
sum_non_optimized_test(array) = map(x -> sum(+, x), julienne(array, (:, *)))
sort_view_test(array) = combine(Base.Generator(View(sort), julienne(array, (:, *))))

println("map, small")
@btime mapslices(sum, array, 1)
@btime sum_non_optimized_test(array)
@btime sum_test(array)
@btime sum(array, 1)

println("map, big")
@btime @inbounds mapslices(sum, big_array, 1)
@btime @inbounds sum_non_optimized_test(big_array)
@btime @inbounds sum_test(big_array)
@btime @inbounds sum(big_array, 1)

println("combine, small")
@btime mapslices(sort, array, 1)
@btime sort_test(array)
@btime sort(array, 1)

println("combine, large")
@btime @inbounds mapslices(sort, big_array, 1)
@btime @inbounds sort_test(big_array)
@btime @inbounds sort(big_array, 1)
@btime @inbounds sort_view_test(big_array)
