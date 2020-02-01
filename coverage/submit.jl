instantiate()

using Coverage.Codecov: submit
using Coverage: process_folder
import JuliennedArrays

JuliennedArrays |> pathof |> dirname |> dirname |> process_folder |> submit
