using Pkg: instantiate
instantiate()

using Coverage.Codecov: submit
using Coverage: process_folder
using JuliennedArrays

JuliennedArrays |> pathof |> dirname |> dirname |> process_folder |> submit
