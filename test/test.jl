using Pkg: build, test
if VERSION >= v"1.1"
    build(verbose = true)
else
    build()
end
test(coverage = true)
