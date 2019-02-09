@testset "Line" begin
    p1 = SVector(1.0, 1.0, 1.0); p2 = SVector(2.0, 2.0, 0.0);
    l1 = Line(p1, p2)

    @test l1[0] ≈ p1
    @test l1[end/2] ≈ SVector(1.5, 1.5, 0.5)
    @test l1[end] ≈ p2

    @test all(map(isapprox, l1[[0, length(l1)]], [p1, p2]))

    p3 = SVector(1.0, 1.0, 1.0); p4 = SVector(1.0, 1.0, 2.0);
    l2 = Line(p3, p4)
   
    l3 = Line(p1, p2) # New instance of l1
    @test isequal(l1, l3)
    @test !isequal(l1, l2)
    @test hash(l1) == hash(l3)

    @test distance(l2, SVector(1.0,1.0,1.0)) == 0
    @test distance(SVector(1,1,1.5), l2) == 0
    @test distance(SVector(3,2,3), l2) == sqrt(6)
    @test distance(l2, SVector(3,2,0)) == sqrt(6)

    @test distance(l2, SVector(1.0,1.0)) == 0
    @test distance(SVector(1,1), l2) == 0
    @test distance(SVector(3,2), l2) == sqrt(5)
    @test distance(l2, SVector(3,2)) == sqrt(5)

    l1 = Line(SVector(0.0, 0.0), SVector(1.0, 0.0))
    @test convert2d(l1) == l1
    @test convert3d(l1) == Line(SVector(0.0, 0.0, 0.0), SVector(1.0, 0.0, 0.0))
    @test convert3d(l1, 1.0) == Line(SVector(0.0, 0.0, 1.0), SVector(1.0, 0.0, 1.0))
    @test convert3d(Line(SVector(0.0, 0.0, 1.0), SVector(1.0, 0.0, 1.0)), 2.0) == Line(SVector(0.0, 0.0, 2.0), SVector(1.0, 0.0, 2.0))

    # boundingbox
    @test boundingbox(Line(SVector(1,2,3), SVector(4,5,6))) == BoundingBox(1,2,3,4,5,6)

    @testset "2D Line distances" begin
        # Intersecting lines
        @test distance(Line(SVector(0.0, 0.0), SVector(1.0, 1.0)), Line(SVector(0.0, 1.0), SVector(1.0, 0.0))) === 0.0
        @test distance(Line(SVector(0.3f0, 0.3f0), SVector(0.6f0, 0.6f0)), Line(SVector(0.3f0, 0.6f0), SVector(0.6f0, 0.3f0))) === 0f0

        # Intersecting at vertices
        @test distance(Line(SVector(0.0, 0.0), SVector(1.0, 1.0)), Line(SVector(1.0, 1.0), SVector(1.0, 0.0))) === 0.0
        @test closest_points(Line(SVector(0.0, 0.0), SVector(1.0, 1.0)), Line(SVector(1.0, 1.0), SVector(1.0, 0.0)))[1] === SVector(1.0, 1.0)
        @test closest_points(Line(SVector(0.0, 0.0), SVector(1.0, 1.0)), Line(SVector(1.0, 1.0), SVector(1.0, 0.0)))[2] === SVector(1.0, 1.0)

        @test distance(Line(SVector(0.3f0, 0.3f0), SVector(0.6f0, 0.6f0)), Line(SVector(0.6f0, 0.6f0), SVector(0.6f0, 0.9f0))) === 0f0
        

        # Parallel lines
        @test distance(Line(SVector(0.0, 0.0), SVector(1.0, 0.0)), Line(SVector(0.0, 0.0), SVector(1.0, 0.0))) === 0.0
        @test distance(Line(SVector(0.3f0, 0.3f0), SVector(0.6f0, 0.6f0)), Line(SVector(0.3f0, 0.3f0), SVector(0.6f0, 0.6f0))) === 0f0
        @test distance(Line(SVector(0.3f0, 0.3f0), SVector(0.6f0, 0.6f0)), Line(SVector(0.4f0, 0.4f0), SVector(0.5f0, 0.5f0))) === 0f0
        @test distance(Line(SVector(0.4f0, 0.4f0), SVector(0.8f0, 0.8f0)), Line(SVector(0.3f0, 0.3f0), SVector(0.6f0, 0.6f0))) === 0f0

        @test distance(Line(SVector(0.0, 0.5), SVector(1.0, 0.5)), Line(SVector(0.0, 0.5), SVector(1.0, 0.5))) === 0.0
        @test distance(Line(SVector(0.0, 0.5), SVector(1.0, 0.5)), Line(SVector(1.0, 0.5), SVector(2.0, 0.5))) === 0.0
        @test distance(Line(SVector(0.0, 0.5), SVector(1.0, 0.5)), Line(SVector(2.0, 0.5), SVector(3.0, 0.5))) === 1.0
        @test distance(Line(SVector(0.0, 0.0), SVector(1.0, 0.0)), Line(SVector(2.0, 0.5), SVector(3.0, 0.5))) ≈ sqrt(1.25)

        # Non-intersecting lines
        @test distance(Line(SVector(0.0, 0.0), SVector(1.0, 0.0)), Line(SVector(1.0, 1.0), SVector(1.0, 2.0))) === 1.0
        @test closest_points(Line(SVector(0.0, 0.0), SVector(1.0, 0.0)), Line(SVector(1.0, 1.0), SVector(1.0, 2.0)))[1] === SVector(1.0, 0.0)
        @test closest_points(Line(SVector(0.0, 0.0), SVector(1.0, 0.0)), Line(SVector(1.0, 1.0), SVector(1.0, 2.0)))[2] === SVector(1.0, 1.0)

    end

    @testset "3D Line distances" begin
        l1 = Line(SVector(0.0, 0.0, 0.0), SVector(1.0, 1.0, 0.0))
        l2 = Line(SVector(0.0, 1.0, 0.5), SVector(1.0, 0.0, 0.5))
        @test distance(l1, l2) ≈ 0.5
        @test closest_points(l1, l2)[1] ≈ SVector(0.5, 0.5, 0.0)
        @test closest_points(l1, l2)[2] ≈ SVector(0.5, 0.5, 0.5)
    end

    # TODO test transformations 
end
