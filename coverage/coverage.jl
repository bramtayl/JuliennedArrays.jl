using Coverage.Codecov: submit, process_folder

cd(
    () -> process_folder |> submit
    (@__FILE__) |> dirname |> dirname |> x -> joinpath(x, "src")
)
