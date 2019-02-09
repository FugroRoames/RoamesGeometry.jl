using RoamesGeometry
VERSION < v"0.7" ? using Base.Test : using Test
using StaticArrays
using CoordinateTransformations

include("Line.jl")
include("LineString.jl")
include("Quadratic.jl")
include("Catenary.jl")

include("AbstractRegion.jl")
include("BoundingBox.jl")
include("TriangularPrism.jl")
include("Cylinder.jl")
include("Sphere.jl")
include("Triangle.jl")
include("Circle.jl")
include("Polygon.jl")

include("distances.jl")
include("wkt.jl")

if VERSION >= v"0.7.0"
	using Random
	using AcceleratedArrays
	using Colors
	using FixedPointNumbers
	using TypedTables

	include("GridIndex.jl")
	include("pointcloud_io.jl")
end