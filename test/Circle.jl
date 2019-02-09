@testset "Circle" begin
    # Make some points between (0,0,0) and (1,1,1) and put in a point cloud
    N = 1000
    pos = rand(SVector{3,Float32}, N)
    circle = Circle(0.5, 0.5, 0.1)

    search_correct = true
    for i = 1:length(pos)
        v = pos[i]
        dv = v - SVector(0.5,0.5,0.5)
        expected =  dv[1]^2 + dv[2]^2 < 0.01
        actual = v ∈ circle
        search_correct &= actual == expected
    end
    @test search_correct

    @test boundingbox(circle) == BoundingBox(0.4, 0.4, -Inf, 0.6, 0.6, Inf)

    @test area(circle) ≈ 0.031415926535897934
end