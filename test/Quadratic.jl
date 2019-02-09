@testset "Quadratic" begin
    p1 = SVector(1.0, 1.0, 1.0); p2 = SVector(2.0, 2.0, 0.0); p3 = SVector(3.0, 3.5, 1.0);
    q = Quadratic(p1, p2, p3)

    @test q[0] ≈ p1
    @test q[1.405563856998] ≈ p2
    @test q[end] ≈ p3

    @test all(map(isapprox, q[[0, 1.405563856998, length(q)]], [p1, p2, p3]))

    # TODO test transformations
end
