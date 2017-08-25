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
    "location": "index.html#JuliennedArrays.OutOfPlaceArray",
    "page": "Home",
    "title": "JuliennedArrays.OutOfPlaceArray",
    "category": "Type",
    "text": "struct OutOfPlaceArray{F} <: FunctionOptimization; f::F; end\n\nA function with a faster in-place analog on a whole preallocated output.\n\n\n\n"
},

{
    "location": "index.html#JuliennedArrays.Reduction",
    "page": "Home",
    "title": "JuliennedArrays.Reduction",
    "category": "Type",
    "text": "struct Reduction{F} <: FunctionOptimization; f::F; end\n\nA reduction of another function\n\n\n\n"
},

{
    "location": "index.html#JuliennedArrays.Swap",
    "page": "Home",
    "title": "JuliennedArrays.Swap",
    "category": "Type",
    "text": "struct Swap{F} <: FunctionOptimization; f::F; end\n\nA function that can be reused on a temporary array\n\n\n\n"
},

{
    "location": "index.html#JuliennedArrays.View",
    "page": "Home",
    "title": "JuliennedArrays.View",
    "category": "Type",
    "text": "struct View{F} <: FunctionOptimization; f::F; end\n\nA function that should be called on views, not copies\n\n\n\n"
},

{
    "location": "index.html#JuliennedArrays.combine-Tuple{Base.Generator{#s2,F} where F where #s2<:JuliennedArrays.ReindexedArray}",
    "page": "Home",
    "title": "JuliennedArrays.combine",
    "category": "Method",
    "text": "combine(pieces)\n\nCombine many pieces of an array.\n\njulia> using JuliennedArrays\n\njulia> array = [1 3 2; 5 6 4; 7 9 8]\n3×3 Array{Int64,2}:\n 1  3  2\n 5  6  4\n 7  9  8\n\njulia> result = combine(Base.Generator(sort, julienne(array, (*, :))))\n3×3 Array{Int64,2}:\n 1  2  3\n 4  5  6\n 7  8  9\n\njulia> array == result\nfalse\n\njulia> result2 = combine(Base.Generator(View(sort!), julienne(array, (*, :))))\n3×3 Array{Int64,2}:\n 1  2  3\n 4  5  6\n 7  8  9\n\njulia> array == result2\ntrue\n\n\n\n"
},

{
    "location": "index.html#JuliennedArrays.julienne-Tuple{Any,Any}",
    "page": "Home",
    "title": "JuliennedArrays.julienne",
    "category": "Method",
    "text": "julienne(array, julienne_code)\n\nCreate a view of an array which will return slices. The julienne code should a tuple of length ndims(array), where : indicates an axis parallel to slices and * indices an axis perpendicular to slices.\n\njulia> using JuliennedArrays\n\njulia> array = reshape([1 3 2; 5 6 4; 7 9 8], 3, 3)\n3×3 Array{Int64,2}:\n 1  3  2\n 5  6  4\n 7  9  8\n\njulia> foreach(sort!, julienne(array, (*, :)));\n\njulia> array\n3×3 Array{Int64,2}:\n 1  2  3\n 4  5  6\n 7  8  9\n\n\n\n"
},

{
    "location": "index.html#Base.map!-Tuple{Any,Any,Any}",
    "page": "Home",
    "title": "Base.map!",
    "category": "Method",
    "text": "Base.map!(f, output, r::ReindexedArray)\n\njulia> using JuliennedArrays\n\njulia> array = reshape(1:9, 3, 3)\n3×3 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:\n 1  4  7\n 2  5  8\n 3  6  9\n\njulia> output = Array{Int}(3);\n\njulia> map!(sum, output, julienne(array, (*, :)));\n\njulia> output\n3-element Array{Int64,1}:\n 12\n 15\n 18\n\n\n\n"
},

{
    "location": "index.html#Base.map-Tuple{Any,JuliennedArrays.ReindexedArray}",
    "page": "Home",
    "title": "Base.map",
    "category": "Method",
    "text": "Base.map(f, r::ReindexedArray)\n\njulia> using JuliennedArrays\n\njulia> array = reshape(1:9, 3, 3)\n3×3 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:\n 1  4  7\n 2  5  8\n 3  6  9\n\njulia> map(sum, julienne(array, (:, *)))\n1×3 Array{Int64,2}:\n 6  15  24\n\njulia> map(median, julienne(array, (:, *)))\n1×3 Array{Float64,2}:\n 2.0  5.0  8.0\n\njulia> map(mean, julienne(array, (:, *)))\n1×3 Array{Float64,2}:\n 2.0  5.0  8.0\n\n\n\n"
},

{
    "location": "index.html#Index-1",
    "page": "Home",
    "title": "Index",
    "category": "section",
    "text": "Modules = [JuliennedArrays]"
},

]}
