using Pkg: instantiate
instantiate()

using JuliennedArrays
using Coverage.Codecov: submit
using Coverage: process_folder

JuliennedArrays |> pathof |> dirname |> dirname |> process_folder |> submit
