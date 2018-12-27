var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "JuliennedArrays.jl",
    "title": "JuliennedArrays.jl",
    "category": "page",
    "text": ""
},

{
    "location": "#JuliennedArrays.Align-Union{Tuple{M}, Tuple{N}, Tuple{T}, Tuple{AbstractArray{#s12,M} where #s12<:AbstractArray{T,N},Vararg{Any,N} where N}} where M where N where T",
    "page": "JuliennedArrays.jl",
    "title": "JuliennedArrays.Align",
    "category": "method",
    "text": "Align(it, along...)\n\njulia> using JuliennedArrays\n\njulia> array = [[1, 2], [3, 4]];\n\njulia> aligned = Align(array, False(), True())\n2×2 Align{Int64,2,Array{Array{Int64,1},1},Tuple{False,True}}:\n 1  2\n 3  4\n\njulia> aligned[1, 1] = 5;\n\njulia> collect(aligned)\n2×2 Array{Int64,2}:\n 5  2\n 3  4\n\n\n\n\n\n"
},

{
    "location": "#JuliennedArrays.False",
    "page": "JuliennedArrays.jl",
    "title": "JuliennedArrays.False",
    "category": "type",
    "text": "struct False\n\n\n\n\n\n"
},

{
    "location": "#JuliennedArrays.Slices-Tuple{Any,Vararg{Any,N} where N}",
    "page": "JuliennedArrays.jl",
    "title": "JuliennedArrays.Slices",
    "category": "method",
    "text": "Slices(array, code...)\n\njulia> using JuliennedArrays\n\njulia> it = [1 2; 3 4];\n\njulia> Slices(it, False(), True())\n2-element Slices{SubArray{Int64,1,Array{Int64,2},Tuple{Int64,Base.OneTo{Int64}},true},1,Array{Int64,2},Tuple{False,True}}:\n [1, 2]\n [3, 4]\n\n\n\n\n\n"
},

{
    "location": "#JuliennedArrays.True",
    "page": "JuliennedArrays.jl",
    "title": "JuliennedArrays.True",
    "category": "type",
    "text": "struct True\n\n\n\n\n\n"
},

{
    "location": "#JuliennedArrays.jl-1",
    "page": "JuliennedArrays.jl",
    "title": "JuliennedArrays.jl",
    "category": "section",
    "text": "Modules = [JuliennedArrays]"
},

]}
