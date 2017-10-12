var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#JuliennedArrays.jl-1",
    "page": "Home",
    "title": "JuliennedArrays.jl",
    "category": "section",
    "text": ""
},

{
    "location": "index.html#Demo-1",
    "page": "Home",
    "title": "Demo",
    "category": "section",
    "text": "This package contains a fast iterator for slicing (julienning) arrays."
},

{
    "location": "index.html#JuliennedArrays.Reduction",
    "page": "Home",
    "title": "JuliennedArrays.Reduction",
    "category": "Type",
    "text": "struct Reduction{F} <: FunctionOptimization; f::F; end\n\nA reduction of another function. Enables optimizations in some cases. Automatically enabled for known reduction functions.\n\njulia> using JuliennedArrays, Base.Test, Base.Test\n\njulia> array = [5 6 4; 1 3 2; 7 9 8]\n3×3 Array{Int64,2}:\n 5  6  4\n 1  3  2\n 7  9  8\n\njulia> swaps = @inferred julienne(Swaps, array, (*, :));\n\njulia> @inferred map(Reduction(+), swaps)\n3×1 Array{Int64,2}:\n 15\n  6\n 24\n\njulia> @inferred map(sum, swaps)\n3×1 Array{Int64,2}:\n 15\n  6\n 24\n\n\n\n"
},

{
    "location": "index.html#JuliennedArrays.align-Tuple{AbstractArray{#s5,N} where N where #s5<:AbstractArray,Any}",
    "page": "Home",
    "title": "JuliennedArrays.align",
    "category": "Method",
    "text": "align(slices, code)\n\nAlign an array of slices into a larger array. Code should be a tuple for each dimension of the desired output. Slices will slide into dimensions coded by :, while * indicates dimensions taken up by the container array. Each slice should be EXACTLY the same size.\n\njulia> using JuliennedArrays, MappedArrays, Base.Test\n\njulia> code = (*, :);\n\njulia> array = [5 6 4; 1 3 2; 7 9 8]\n3×3 Array{Int64,2}:\n 5  6  4\n 1  3  2\n 7  9  8\n\njulia> swaps = @inferred julienne(Swaps, array, code);\n\njulia> @inferred align(mappedarray(sort, swaps), code)\n3×3 Array{Int64,2}:\n 4  5  6\n 1  2  3\n 7  8  9\n\n\n\n"
},

{
    "location": "index.html#JuliennedArrays.julienne-Tuple{Any,Any,Any}",
    "page": "Home",
    "title": "JuliennedArrays.julienne",
    "category": "Method",
    "text": "julienne(T, array, code)\njulienne(T, array, code, swap)\n\nSlice an array and create shares of type T. T should be one of Arrays, Swaps, or Views. The code should a tuple of length ndims(array), where : indicates an axis parallel to slices and * indices an axis perpendicular to slices.\n\njulia> using JuliennedArrays, Base.Test\n\njulia> code = (*, :);\n\njulia> array = [5 6 4; 1 3 2; 7 9 8]\n3×3 Array{Int64,2}:\n 5  6  4\n 1  3  2\n 7  9  8\n\njulia> arrays = @inferred julienne(Arrays, array, (*, :));\n\njulia> @inferred map(mean, arrays)\n3-element Array{Float64,1}:\n 5.0\n 2.0\n 8.0\n\njulia> views = @inferred julienne(Views, array, (*, :));\n\njulia> @inferred map(mean, views)\n3-element Array{Float64,1}:\n 5.0\n 2.0\n 8.0\n\njulia> swaps = @inferred julienne(Swaps, array, (*, :));\n\njulia> @inferred map(mean, swaps)\n3-element Array{Float64,1}:\n 5.0\n 2.0\n 8.0\n\n\n\n"
},

{
    "location": "index.html#Index-1",
    "page": "Home",
    "title": "Index",
    "category": "section",
    "text": "Modules = [JuliennedArrays]"
},

]}
