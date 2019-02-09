using Displaz
using StaticArrays
using RoamesGeometry

println("Press ENTER to make a new example")
println("Type any non-empty string and press ENTER to quit")

while(readline(STDIN) == "")
	l1 = Line(rand(SVector{3,Float64}), rand(SVector{3,Float64}))
	l2 = Line(rand(SVector{3,Float64}), rand(SVector{3,Float64}))
	(p1, p2) = closest_points(l1, l2)
	l3 = Line(p1, p2)

	plot3d!(l1, color = [0.6, 0.1, 1.0], label = "Line 1")
	plot3d!(l2, color = [0.1, 0.6, 1.0], label = "Line 2")
	plot3d!(l3, color = [0.8, 0.8, 0.2], label = "Closest points")
end