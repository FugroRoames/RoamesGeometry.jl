using RoamesGeometry
using StaticArrays
using Displaz
using CoordinateTransformations
using Colors

@static if VERSION >= v"0.7"
    linspace(a,b,c) = range(a, stop = b, length = c)
end

# Make a scene

pole1 = Line(SVector(0.0, 0.0, 0.0), SVector(0.0, 0.0, 8.0))
crossarm1 = Line(SVector(-0.6, 0.0, 7.0), SVector(0.6, 0.0, 7.0))

pole2 = Line(SVector(0.0, 20.0, 0.0), SVector(0.0, 20.0, 8.0))
crossarm2 = Line(SVector(-0.6, 20.0, 7.0), SVector(0.6, 20.0, 7.0))

wire1 = Quadratic(SVector(-0.5, 0.0, 6.8), SVector(-0.5, 10.0, 5.0), SVector(-0.5, 20.0, 6.8))
wire2 = Quadratic(SVector(0.5, 0.0, 6.8), SVector(0.5, 10.0, 5.0), SVector(0.5, 20.0, 6.8))
wire3 = Quadratic(SVector(0.0, 0.0, 8.0), SVector(0.0, 10.0, 6.2), SVector(0.0, 20.0, 8.0))

catwire = Catenary(pi/2, 0.0, 10.0, 6.2, -10.0, 10.0, 28.07275088)

# Combine objects
lines = [pole1, crossarm1, pole2, crossarm2]
quads = [wire1, wire2, wire3]
cats = [catwire]

# plot them
Displaz.plot3d(lines; color = [0.2, 0.2, 0.8])
Displaz.plot3d(quads; color = [0.8, 0.2, 0.1])
Displaz.plot3d(cats; color = [0.8, 0.8, 0.1])

Displaz.plot3d(boundingbox(lines); color = [0.3, 0.3, 0.3])
#Displaz.plot3d(boundingbox(quads); color = [0.3, 0.3, 0.3])
Displaz.plot3d(boundingbox(cats); color = [0.3, 0.3, 0.3])

# Make another bay, test single plotting and transformations

tfm = Translation(SVector(0.0, 20.0, 0.0))

Displaz.plot3d(tfm(pole2), color = [0.2, 0.2, 0.8])
Displaz.plot3d(tfm(crossarm2), color = [0.2, 0.2, 0.8])
Displaz.plot3d(tfm(wire1), color = [0.8, 0.2, 0.1])
Displaz.plot3d(tfm(wire2), color = [0.8, 0.2, 0.1])
Displaz.plot3d(tfm(wire3), color = [0.8, 0.2, 0.1])
Displaz.plot3d(tfm(catwire), color = [0.8, 0.8, 0.1])

# Test the distance functions

dx = 50.0
dy = -30.0
cat = Catenary(pi/2, dx, 10.0 + dy, 6.2, -10.0, 10.0, 10.0)
#cat = Translation(SVector(dx, 0.0, 0.0))(catwire)
points = vec([SVector(x + dx, y + dy, z) for x ∈ linspace(0.0, 4.0, 20), y ∈ linspace(-4.0, 24.0, 140), z ∈ linspace(2.0, 15.0, 130)])
dists = map(p -> distance(cat, p), points)
colors = RGB.(exp.(-1 .* dists), 2 .* dists .* exp.(-1 .* dists), 3 .* (dists .* dists .- 1) .* exp.(-1 .* dists))
Displaz.plot3d(cat, color = [0.8, 0.8, 0.1])
Displaz.plot3d(points, color = colors, label = "distance field")


dx = 50.0
dy = 0.0
cat = Catenary(pi/2, dx, 10.0 + dy, 6.2, -10.0, 10.0, 10.0)
#cat = Translation(SVector(dx, 0.0, 0.0))(catwire)
points = vec([SVector(x + dx, y + dy, z) for x ∈ linspace(0.0, 4.0, 20), y ∈ linspace(-4.0, 24.0, 140), z ∈ linspace(2.0, 15.0, 130)])
dists = map(p -> powerline_distances(cat, p)[2], points)
colors = RGB.(1 ./ (1 .+ (dists .+ 1).*(dists .+ 1)), 1 ./ (1 .+ dists .* dists), 1 ./ (1 .+ (dists .+ 2) .* (dists .+ 2)))
Displaz.plot3d(cat, color = [0.8, 0.8, 0.1])
Displaz.plot3d(points, color = colors, label = "r field")

dx = 50.0
dy = 30.0
cat = Catenary(pi/2, dx, 10.0 + dy, 6.2, -10.0, 10.0, 10.0)
#cat = Translation(SVector(dx, 0.0, 0.0))(catwire)
points = vec([SVector(x + dx, y + dy, z) for x ∈ linspace(0.0, 4.0, 20), y ∈ linspace(-4.0, 24.0, 140), z ∈ linspace(2.0, 15.0, 130)])
dists = map(p -> powerline_distances(cat, p)[3], points)
colors = RGB.(1 ./ (1 .+ 0.25 .* (dists .- 2).*(dists .- 2)), 1 ./ (1 .+ 0.25 .* dists .* dists), 1 ./ (1. .+ 0.25 .* (dists .+ 2).*(dists .+ 2)))
Displaz.plot3d(cat, color = [0.8, 0.8, 0.1])
Displaz.plot3d(points, color = colors, label = "z field")

dx = 50.0
dy = 60.0
cat = Catenary(pi/2, dx, 10.0 + dy, 6.2, -10.0, 10.0, 10.0)
#cat = Translation(SVector(dx, 0.0, 0.0))(catwire)
points = vec([SVector(x + dx, y + dy, z) for x ∈ linspace(0.0, 4.0, 20), y ∈ linspace(-4.0, 24.0, 140), z ∈ linspace(2.0, 15.0, 130)])
dists = map(p -> powerline_distances(cat, p)[4], points)
colors = RGB.(1 ./ (1 .+ 0.02 .* (dists .- 10).*(dists .- 10)), 1 ./ (1 .+ 0.02 .* dists.*dists), 1 ./ (1 .+ 0.02 .* (dists .+ 10).*(dists .+ 10)))
Displaz.plot3d(cat, color = [0.8, 0.8, 0.1])
Displaz.plot3d(points, color = colors, label = "d field")
