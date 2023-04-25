__precompile__()

module RoamesGeometry

using StaticArrays
using CoordinateTransformations
using Rotations

import Base: getindex, setindex!, size, length, lastindex, in, isempty, eltype, IndexStyle,
             push!, pop!, show
using Base: @propagate_inbounds, RefValue
import CoordinateTransformations: Transformation, IdentityTransformation,
                                  Translation, LinearMap, AffineMap

if VERSION < v"0.7"
    import Base: endof
else
    using LinearAlgebra, Pkg

    import Base: lastindex
    linspace(a,b,c) = range(a, stop = b, length = c)
end

export AbstractRegion, BoundingBox, TriangularPrism, Sphere, Triangle, Circle, Cylinder,
       Line, LineString, Quadratic, Catenary, Polygon

export boundingbox, pad, intersects, wireframe, distance, powerline_distances, volume,
       area, might_intersect, isclosed, issimple, closest_point, closest_points, convert2d,
       convert3d, winding_number, containsMoreThanN, database_params

export wkt, load_wkt, save_wkt, read_wkt, write_wkt

# Any affine transformation type
const AffineTransformation = Union{IdentityTransformation, Translation, LinearMap, AffineMap}

# Zero-dimensional entities
#  - Points are AbstractVector{<:Real} of length 2 or 3, usually a StaticVector{N, <:Real}
convert2d(p::StaticVector{2, <:Real}) = p
convert2d(p::StaticVector{3, <:Real}) = similar_type(typeof(p), Size(2))((p[1], p[2]))
convert3d(p::StaticVector{2, T}, z::Real = zero(T)) where {T<:Real} = similar_type(typeof(p), Size(3))((p[1], p[2], T(z)))
convert3d(p::StaticVector{3, T}, z::Real) where {T<:Real} = similar_type(typeof(p), Size(3))((p[1], p[2], T(z)))
convert3d(p::StaticVector{3, <:Real}) = p

# 1D geometries
include("Line.jl")
include("LineString.jl")
include("Quadratic.jl")
include("Catenary.jl")

# 2D geometries
# - triangle?
# - mesh?
# - polygon?

# 3D geometries
include("AbstractRegion.jl")
include("TriangularPrism.jl")
include("Cylinder.jl")
include("Sphere.jl")
include("Triangle.jl")
include("Circle.jl")
include("Polygon.jl")
include("BoundingBox.jl")

include("might_intersect.jl") # included last as uses unions of geometries
include("distances.jl") # calculates the distances between e.g. points and catenaries
include("wkt.jl") # read and write WKT files
include("displaz.jl") # optionally loads methods if the Displaz package is installed

if VERSION >= v"0.7.0"
    using AcceleratedArrays
    using TypedTables
    using FileIO
    using LasIO
    using HDF5
    using Colors
    using FixedPointNumbers
    using Dates

    export GridIndex
    export load_pointcloud, save_pointcloud

    include("GridIndex.jl")
    include("pointcloud_io.jl")
end

end # module
