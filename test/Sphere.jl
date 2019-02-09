@testset "Sphere" begin
    # Make some points between (0,0,0) and (1,1,1) and put in a point cloud
    N = 1000
    pos = rand(SVector{3,Float32}, N)
    sphere = Sphere(0.5, 0.5, 0.5, 0.1)

    sphere_search_correct = true
    for i = 1:length(pos)
        v = pos[i]
        dv = v - SVector(0.5,0.5,0.5)
        distance = sum(abs2, dv)
        expected = distance < 0.01
        actual = v ∈ sphere
        sphere_search_correct &= actual == expected
    end
    @test sphere_search_correct

    @test boundingbox(sphere) == BoundingBox(0.4, 0.4, 0.4, 0.6, 0.6, 0.6)

    @test volume(sphere) ≈ 0.04188790204786391

    @test might_intersect(
        BoundingBox(0.0, 0.0, 0.0, 0.1, 0.1, 0.1),
        Sphere(0.5, 0.5, 0.5, 0.5)
    ) == false

    @test might_intersect(
        BoundingBox(0.0, 0.0, 0.0, 1.0, 1.0, 1.0),
        Sphere(0.5, 0.5, 0.5, 0.2)
    ) == true

    @test might_intersect(
        BoundingBox(0.0, 0.0, 0.0, 0.4, 0.4, 0.4),
        Sphere(0.5, 0.5, 0.5, 0.2)
    ) == true
end