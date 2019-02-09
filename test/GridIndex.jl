@testset "GridIndex" begin
    Random.seed!(42)
    points = rand(SVector{3, Float64}, 1_000)

    ps = accelerate(points, GridIndex; spacing = 0.1)

    for p in points
    	radius = rand()
    	@test count(in(Sphere(p, radius)), ps) == count(in(Sphere(p, radius)), points)
    	@test issetequal(findall(in(Sphere(p, radius)), ps), findall(x -> x in Sphere(p, radius) #= Base bug... wants `length` of `Sphere`? =#, points))
    	@test issetequal(filter(in(Sphere(p, radius)), ps), filter(in(Sphere(p, radius)), points))
    end

    ps2 = accelerate!(points, GridIndex; spacing = 0.1)

    for p in points
    	radius = rand()
    	@test count(in(Sphere(p, radius)), ps2) == count(in(Sphere(p, radius)), points)
    	@test issetequal(findall(in(Sphere(p, radius)), ps2), findall(x -> x in Sphere(p, radius) #= Base bug... wants `length` of `Sphere`? =#, points))
    	@test issetequal(filter(in(Sphere(p, radius)), ps2), filter(in(Sphere(p, radius)), points))
    end
end
