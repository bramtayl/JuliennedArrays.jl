using Base.Iterators: flatten
using BenchmarkTools: @btime
using JuliennedArrays: julienne
using MappedArrays: mappedarray

const small_array = [1 3 2; 4 6 5; 7 9 8]
const big_array = rand(1000, 1000)
const code = (:, *)

sum_test(array) = map(sum, julienne(array, code))
function sort_test(array)
    f = mappedarray(sort, julienne(array, code)) |> flatten
    @inbounds collect(f)
end

println("map, small")
@btime @inbounds mapslices(sum, small_array; dims = 1);
@btime sum_test(small_array);
@btime @inbounds sum(small_array; dims = 1);

println("map, big")
@btime @inbounds mapslices(sum, big_array; dims = 1);
@btime sum_test(big_array);
@btime @inbounds sum(big_array; dims = 1);

println("combine, small")
@btime @inbounds mapslices(sort, small_array; dims = 1);
@btime sort_test(small_array);

println("combine, large")
@btime @inbounds mapslices(sort, big_array; dims = 1);
@btime sort_test(big_array);

function profile_test(f, a, n)
    for i in 1:n
        f(a)
    end
end

using Profile: @profile, clear
import ProfileView

clear()
@profile profile_test(sum_test, small_array, 10000)
ProfileView.view()

clear()
@profile profile_test(sort_test, small_array, 10000)
ProfileView.view()

clear()
@profile profile_test(sum_test, big_array, 100000)
ProfileView.view()

clear()
@profile profile_test(sort_test, big_array, 10000)
ProfileView.view()
