@testset "Cylinder" begin
    N = 1000
    pos = rand(SVector{3,Float32}, N)
    cylinder = Cylinder(0.5, 0.5, 0.2, 0.8, 0.1)

    search_correct = true
    for i = 1:length(pos)
        v = pos[i]
        dv = v - SVector(0.5,0.5,0.5)
        expected = dv[1]^2 + dv[2]^2 < 0.01 && abs(dv[3]) < 0.3
        actual = v ∈ cylinder
        search_correct &= actual == expected
    end
    @test search_correct

    @test boundingbox(cylinder) == BoundingBox(0.4, 0.4, 0.2, 0.6, 0.6, 0.8)

    @test volume(cylinder) ≈ 0.01884955592153876
end