@testset "TriangularPrism" begin
    t = TriangularPrism(SVector(0.0, 0.0, 0.0), 
            SVector(1.0, 0.0, 0.0), 
            SVector(0.0, 1.0, 0.0),
            0.5, 0.25)

    @test SVector(0.1, 0.1, 0.2) ∈ t
    @test SVector(0.1, 0.1, 0.3) ∉ t
    @test SVector(1.0, 1.0, 0.2) ∉ t
    @test volume(t) == 0.25

    @test boundingbox(TriangularPrism(SVector(1.0, 0.0, 0.0), SVector(1.0, 1.0, 0.0), SVector(0.0, 1.0, 0.0), 1.0)) == BoundingBox(0.0, 0.0, 0.0, 1.0, 1, 1)
    @test boundingbox(TriangularPrism(SVector(2.0, 0.0, 0.0), SVector(2.0, 2.0, 0.0), SVector(0.0, 2.0, 0.0), 1.0)) == BoundingBox(0.0, 0.0, 0.0, 2.0, 2, 1)
    @test boundingbox(TriangularPrism(SVector(0.0, 0.0, 0.0), SVector(5.0, 0.0, 0.0), SVector(0.0, 4.0, 0.0), 1.0)) == BoundingBox(0.0, 0.0, 0.0, 5.0, 4, 1)
    @test boundingbox(TriangularPrism(SVector(0.0, 0.0, 0.0), SVector(0.0, 0.0, 5.0), SVector(0.0, 4.0, 0.0), 1.0)) == BoundingBox(-1, 0, 0.0, 0.0, 4.0, 5.0)
    @test boundingbox(TriangularPrism(SVector(0.5, 0.5, 0.5), SVector(5.5, 0.5, 0.5), SVector(0.5, 4.5, 0.5), 1.0)) == BoundingBox(0.5, 0.5, 0.5, 5.5, 4.5, 1.5)
    @test boundingbox(TriangularPrism(SVector(0.5, 0.5, 0.5), SVector(5.6, 0.5, 0.5), SVector(0.5, 4.5, 0.5), 1.0)) == BoundingBox(0.5, 0.5, 0.5, 5.6, 4.5, 1.5)

    @test volume(TriangularPrism(SVector(1.0, 0.0, 0.0), SVector(1.0, 1.0, 0.0), SVector(0.0, 1.0, 0.0), 1.0)) == 0.5
    @test volume(TriangularPrism(SVector(2.0, 0.0, 0.0), SVector(2.0, 2.0, 0.0), SVector(0.0, 2.0, 0.0), 1.0)) == 2.0
    @test volume(TriangularPrism(SVector(0.0, 0.0, 0.0), SVector(5.0, 0.0, 0.0), SVector(0.0, 4.0, 0.0), 1.0)) == 10.0
    @test volume(TriangularPrism(SVector(0.0, 0.0, 0.0), SVector(0.0, 0.0, 5.0), SVector(0.0, 4.0, 0.0), 1.0)) == 10.0
    @test volume(TriangularPrism(SVector(0.5, 0.5, 0.5), SVector(5.5, 0.5, 0.5), SVector(0.5, 4.5, 0.5), 1.0)) == 10.0
    @test volume(TriangularPrism(SVector(0.5, 0.5, 0.5), SVector(5.6, 0.5, 0.5), SVector(0.5, 4.5, 0.5), 1.0)) == 10.2

    @test volume(TriangularPrism(SVector(1.0, 0.0, 0.0), SVector(1.0, 1.0, 0.0), SVector(0.0, 1.0, 0.0), 3.0)) == 1.5
    @test volume(TriangularPrism(SVector(2.0, 0.0, 0.0), SVector(2.0, 2.0, 0.0), SVector(0.0, 2.0, 0.0), 3.0)) == 6.0
    @test volume(TriangularPrism(SVector(0.0, 0.0, 0.0), SVector(5.0, 0.0, 0.0), SVector(0.0, 4.0, 0.0), 3.0)) == 30.0
    @test volume(TriangularPrism(SVector(0.0, 0.0, 0.0), SVector(0.0, 0.0, 5.0), SVector(0.0, 4.0, 0.0), 3.0)) == 30.0
    @test volume(TriangularPrism(SVector(0.5, 0.5, 0.5), SVector(5.5, 0.5, 0.5), SVector(0.5, 4.5, 0.5), 3.0)) == 30.0
    @test volume(TriangularPrism(SVector(0.5, 0.5, 0.5), SVector(5.6, 0.5, 0.5), SVector(0.5, 4.5, 0.5), 3.0)) ≈ 30.6

    @test volume(TriangularPrism(SVector(1.0, 0.0, 0.0), SVector(1.0, 1.0, 0.0), SVector(0.0, 1.0, 0.0), 3.0, -1.2)) == 1.5
    @test volume(TriangularPrism(SVector(2.0, 0.0, 0.0), SVector(2.0, 2.0, 0.0), SVector(0.0, 2.0, 0.0), 3.0, -1.2)) == 6.0
    @test volume(TriangularPrism(SVector(0.0, 0.0, 0.0), SVector(5.0, 0.0, 0.0), SVector(0.0, 4.0, 0.0), 3.0, -1.2)) == 30.0
    @test volume(TriangularPrism(SVector(0.0, 0.0, 0.0), SVector(0.0, 0.0, 5.0), SVector(0.0, 4.0, 0.0), 3.0, -1.2)) == 30.0
    @test volume(TriangularPrism(SVector(0.5, 0.5, 0.5), SVector(5.5, 0.5, 0.5), SVector(0.5, 4.5, 0.5), 3.0, -1.2)) == 30.0
    @test volume(TriangularPrism(SVector(0.5, 0.5, 0.5), SVector(5.6, 0.5, 0.5), SVector(0.5, 4.5, 0.5), 3.0, -1.2)) ≈ 30.6
end