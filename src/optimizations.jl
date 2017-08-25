export Reduction, OutOfPlaceArray, View, Swap

abstract type FunctionOptimization end

struct None{F} <: FunctionOptimization; f::F; end

"""
    struct Reduction{F} <: FunctionOptimization; f::F; end

A reduction of another function
"""
struct Reduction{F} <: FunctionOptimization; f::F; end

"""
    struct OutOfPlaceArray{F} <: FunctionOptimization; f::F; end

A function with a faster in-place analog on a whole preallocated output.
"""
struct OutOfPlaceArray{F} <: FunctionOptimization; f::F; end

"""
    struct View{F} <: FunctionOptimization; f::F; end

A function that should be called on views, not copies
"""
struct View{F} <: FunctionOptimization; f::F; end

"""
    struct Swap{F} <: FunctionOptimization; f::F; end

A function that can be reused on a temporary array
"""
struct Swap{F} <: FunctionOptimization; f::F; end

optimization(f) = None(f)
optimization(::typeof(median)) = None(median!)
optimization(::typeof(sum)) = Reduction(+)
optimization(::typeof(prod)) = Reduction(*)
optimization(::typeof(maximum)) = Reduction(scalarmax)
optimization(::typeof(minimum)) = Reduction(scalarmin)
optimization(::typeof(all)) = Reduction(&)
optimization(::typeof(any)) = Reduction(|)
optimization(::typeof(mean)) = OutOfPlaceArray(mean!)

# TODO: varm, var, std
