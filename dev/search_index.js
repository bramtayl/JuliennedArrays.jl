var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "JuliennedArrays.jl",
    "title": "JuliennedArrays.jl",
    "category": "page",
    "text": ""
},

{
    "location": "#JuliennedArrays.True",
    "page": "JuliennedArrays.jl",
    "title": "JuliennedArrays.True",
    "category": "type",
    "text": "struct True\n\nTyped true\n\n\n\n\n\n"
},

{
    "location": "#JuliennedArrays.False",
    "page": "JuliennedArrays.jl",
    "title": "JuliennedArrays.False",
    "category": "type",
    "text": "struct False\n\nTyped false\n\n\n\n\n\n"
},

{
    "location": "#JuliennedArrays.Slices",
    "page": "JuliennedArrays.jl",
    "title": "JuliennedArrays.Slices",
    "category": "type",
    "text": "Slices(array, along...)\n\nSlice array into views.\n\nalong, made of True and False objects, shows which dimensions will be replaced with : when slicing.\n\njulia> using JuliennedArrays\n\njulia> it = [1 2; 3 4];\n\njulia> slices = Slices(it, False(), True())\n2-element Slices{SubArray{Int64,1,Array{Int64,2},Tuple{Int64,Base.OneTo{Int64}},true},1,Array{Int64,2},Tuple{False,True}}:\n [1, 2]\n [3, 4]\n\njulia> slices[1] == it[1, :]\ntrue\n\njulia> slices[1] = [2, 1];\n\njulia> it\n2×2 Array{Int64,2}:\n 2  1\n 3  4\n\n\n\n\n\n"
},

{
    "location": "#JuliennedArrays.Align",
    "page": "JuliennedArrays.jl",
    "title": "JuliennedArrays.Align",
    "category": "type",
    "text": "Align(it, along...)\n\nAlign an array of arrays, all with the same size.\n\nalong, made of True and False objects, shows which dimensions will be taken up by the inner arrays. Inverse of Slices.\n\njulia> using JuliennedArrays\n\njulia> array = [[1, 2], [3, 4]];\n\njulia> aligned = Align(array, False(), True())\n2×2 Align{Int64,2,Array{Array{Int64,1},1},Tuple{False,True}}:\n 1  2\n 3  4\n\njulia> aligned[1, :] == array[1]\ntrue\n\njulia> aligned[1, 1] = 0;\n\njulia> array\n2-element Array{Array{Int64,1},1}:\n [0, 2]\n [3, 4]\n\n\n\n\n\n"
},

{
    "location": "#JuliennedArrays.jl-1",
    "page": "JuliennedArrays.jl",
    "title": "JuliennedArrays.jl",
    "category": "section",
    "text": "True\nFalse\nSlices\nAlign"
},

]}
