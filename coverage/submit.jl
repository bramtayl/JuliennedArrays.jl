using Pkg: instantiate
instantiate()

using Coverage.Codecov: submit
using Coverage: process_folder

submit(process_folder(pwd()))
