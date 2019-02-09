@testset "Triangle" begin
    # Make some points between (0,0,0) and (1,1,1) and put in a point cloud
    N = 1000
    pos = rand(SVector{3,Float32}, N)
    triangle = Triangle(SVector(0.0, 0.0), SVector(1.0, 0.0), SVector(0.0, 1.0))

    search_correct = true
    for i = 1:length(pos)
        v = pos[i]
        expected = v[1] + v[2] < 1.0
        actual = v ∈ triangle
        search_correct &= actual == expected
    end
    @test search_correct

    triangle = Triangle(SVector(0.5, 0.5), SVector(0.5, 1.5), SVector(1.5, 1.0))
    @test SVector(0.0, 0.0, 0.0) ∉ triangle
    @test SVector(0.0, 0.0, 1.0) ∉ triangle
    @test SVector(0.0, 0.0, -1.0) ∉ triangle
    @test SVector(1.0, 1.0, 0.0) ∈ triangle
    @test SVector(1.0, 1.0, -1.0) ∈ triangle
    @test SVector(1.0, 1.0, 1.0) ∈ triangle

    @test boundingbox(triangle) == BoundingBox(0.5, 0.5, -Inf, 1.5, 1.5, Inf)

    @test area(triangle) == 0.5
end