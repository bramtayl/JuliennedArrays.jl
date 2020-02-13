using Pkg: instantiate
instantiate()
using Coverage
coverage = process_folder()
coverage = merge_coverage_counts(coverage, filter!(
    let prefix = joinpath(pwd(), "src", "")
        coverage_file -> startswith(coverage_file.filename, prefix)
    end,
    LCOV.readfolder(pwd())
))
Codecov.submit(coverage)
