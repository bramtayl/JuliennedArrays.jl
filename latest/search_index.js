var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#JuliennedArrays.Reduce",
    "page": "Home",
    "title": "JuliennedArrays.Reduce",
    "category": "type",
    "text": "struct Reduce{F}\n\nReduction of another function. Enables optimizations in some cases.\n\njulia> using JuliennedArrays\n\njulia> array = [5 6 4; 1 3 2; 7 9 8]\n3×3 Array{Int64,2}:\n 5  6  4\n 1  3  2\n 7  9  8\n\njulia> map(Reduce(+), julienne(array, (*, :)))\n3×1 Array{Int64,2}:\n 15\n  6\n 24\n\njulia> array = reshape(1:8, 2, 2, 2)\n2×2×2 reshape(::UnitRange{Int64}, 2, 2, 2) with eltype Int64:\n[:, :, 1] =\n 1  3\n 2  4\n\n[:, :, 2] =\n 5  7\n 6  8\n\njulia> map(Reduce(+), julienne(array, (:, *, :)))\n1×2×1 Array{Int64,3}:\n[:, :, 1] =\n 14  22\n\n\n\n\n\n"
},

{
    "location": "index.html#JuliennedArrays.align-Tuple{AbstractArray{#s14,N} where N where #s14<:AbstractArray,Any}",
    "page": "Home",
    "title": "JuliennedArrays.align",
    "category": "method",
    "text": "align(slices, code)\n\nAlign an array of slices into a larger array. Code should be a tuple with an entry for each dimension of the desired output. Slices will slide into dimensions coded by :, while * indicates dimensions taken up by the container array. Each slice should be EXACTLY the same size.\n\njulia> using JuliennedArrays, MappedArrays\n\njulia> code = (*, :);\n\njulia> array = [5 6 4; 1 3 2]\n2×3 Array{Int64,2}:\n 5  6  4\n 1  3  2\n\njulia> views = julienne(array, code);\n\njulia> align(mappedarray(sort, views), code)\n2×3 Array{Int64,2}:\n 4  5  6\n 1  2  3\n\n\n\n\n\n"
},

{
    "location": "index.html#JuliennedArrays.julienne-Tuple{Any,Any}",
    "page": "Home",
    "title": "JuliennedArrays.julienne",
    "category": "method",
    "text": "julienne(array, code)\n\nSlice an array and create views. The code should a tuple of length ndims(array), where : indicates an axis parallel to slices and * axes an axis perpendicular to slices.\n\njulia> using JuliennedArrays\n\njulia> array = [5 6 4; 1 3 2; 7 9 8]\n3×3 Array{Int64,2}:\n 5  6  4\n 1  3  2\n 7  9  8\n\njulia> map(sum, julienne(array, (*, :)))\n3-element Array{Int64,1}:\n 15\n  6\n 24\n\n\n\n\n\n"
},

{
    "location": "index.html#JuliennedArrays.jl-1",
    "page": "Home",
    "title": "JuliennedArrays.jl",
    "category": "section",
    "text": "Modules = [JuliennedArrays]"
},

]}
