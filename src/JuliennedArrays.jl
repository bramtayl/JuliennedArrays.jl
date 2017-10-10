module JuliennedArrays

using RecurUnroll: getindex_unrolled, setindex_unrolled
using TypedBools: True, False

import Base: indices, size, getindex, setindex!, @propagate_inbounds, map

include("shares.jl")
include("julienne.jl")
include("optimizations.jl")

end
