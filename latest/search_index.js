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
    "location": "index.html#JuliennedArrays.combine-Tuple{Base.Generator{T1,F} where F where T1<:(JuliennedArrays.ReiteratedArray{T2,T3} where T3<:JuliennedArrays.JulienneIterator where T2)}",
    "page": "Home",
    "title": "JuliennedArrays.combine",
    "category": "Method",
    "text": "combine(array)\n\nCombine an array that has been julienned (or otherwise split).\n\njulia> using JuliennedArrays\n\njulia> array = reshape(1:9, 3, 3)\n3×3 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:\n 1  4  7\n 2  5  8\n 3  6  9\n\njulia> begin\n            julienned = julienne(array, (:, *))\n            mapped = map(sum, julienned)\n            combine(mapped)\n        end\n1×3 Array{Int64,2}:\n 6  15  24\n\n\n\n"
},

{
    "location": "index.html#JuliennedArrays.julienne-Tuple{Any,Any}",
    "page": "Home",
    "title": "JuliennedArrays.julienne",
    "category": "Method",
    "text": "julienne(array, julienne_code)\n\njulia> using JuliennedArrays\n\njulia> array = reshape(1:9, 3, 3)\n3×3 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:\n 1  4  7\n 2  5  8\n 3  6  9\n\njulia> begin\n            julienned = julienne(array, (:, *))\n            mapped = map(identity, julienned)\n            collect(mapped)\n        end\n3-element Array{SubArray{Int64,1,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}},Tuple{Base.OneTo{Int64},Int64},true},1}:\n [1, 2, 3]\n [4, 5, 6]\n [7, 8, 9]\n\n\n\n"
},

{
    "location": "index.html#JuliennedArrays.julienne_iterator-Tuple{Any,Any}",
    "page": "Home",
    "title": "JuliennedArrays.julienne_iterator",
    "category": "Method",
    "text": "julienne_iterator(array, julienne_code)\n\njulienne_code should be a tuple of either * (for dimensions to be sliced over) or : for dimenisons to be sliced across. See the example below for clarification.\n\njulia> using JuliennedArrays\n\njulia> array = reshape(1:9, 3, 3)\n3×3 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:\n 1  4  7\n 2  5  8\n 3  6  9\n\njulia> begin\n            iterator = julienne_iterator(array, (:, *))\n            map(identity, iterator)\n        end\n3-element Array{Tuple{Base.OneTo{Int64},Int64},1}:\n (Base.OneTo(3), 1)\n (Base.OneTo(3), 2)\n (Base.OneTo(3), 3)\n\n\n\n"
},

{
    "location": "index.html#Index-1",
    "page": "Home",
    "title": "Index",
    "category": "section",
    "text": "Modules = [JuliennedArrays]"
},

]}
