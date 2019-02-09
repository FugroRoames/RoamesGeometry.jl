@testset "BoundingBox" begin
    @test BoundingBox(1.0,2,3,4,5,6) === BoundingBox(1.0,2.0,3.0,4.0,5.0,6.0)

    @test eltype(BoundingBox(1,2,3,4,5,6)) === SVector{3, Int}

    # making bounding boxes by encapsulating geometry
    @test boundingbox(SVector(1,2,3)) === BoundingBox(1,2,3,1,2,3)
    @test boundingbox(SVector(1,2,3), SVector(4,5,6)) === BoundingBox(1,2,3,4,5,6)
    @test boundingbox(SVector(4,5,6), SVector(1,2,3)) === BoundingBox(1,2,3,4,5,6)
    @test boundingbox(BoundingBox(0,0,0,1,1,1), BoundingBox(1,1,1,2,2,2)) === BoundingBox(0,0,0,2,2,2)
    @test boundingbox(BoundingBox(0,0,0,1,1,1), BoundingBox(1.0,1.0,1.0,2.0,2.0,2.0)) === BoundingBox(0.0,0.0,0.0,2.0,2.0,2.0)
    @test boundingbox(BoundingBox(0,0,0,1,1,1), SVector(2,2,2)) === BoundingBox(0,0,0,2,2,2)
    @test boundingbox([SVector(1,2,0), SVector(0,1,2), SVector(2,0,1)]) === BoundingBox(0,0,0,2,2,2)
    @test boundingbox([BoundingBox(0,0,0,1,1,1), BoundingBox(1.0,1.0,1.0,2.0,2.0,2.0)]) === BoundingBox(0.0,0.0,0.0,2.0,2.0,2.0)

    # 27 octants
    @test SVector(1,2,3) ∈ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(-1,2,3) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(5,2,3) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(1,-1,3) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(-1,-1,3) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(5,-1,3) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(1,5,3) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(-1,5,3) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(5,5,3) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))

    @test SVector(1,2,-1) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(-1,2,-1) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(5,2,-1) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(1,-1,-1) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(-1,-1,-1) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(5,-1,-1) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(1,5,-1) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(-1,5,-1) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(5,5,-1) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))

    @test SVector(1,2,5) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(-1,2,5) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(5,2,5) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(1,-1,5) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(-1,-1,5) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(5,-1,5) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(1,5,5) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(-1,5,5) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))
    @test SVector(5,5,5) ∉ boundingbox(SVector(0,0,0), SVector(4,4,4))

    # non-empty intersection
    @test intersects(BoundingBox(0,0,0,1,1,1), BoundingBox(-1,-1,-1,2,2,2))
    @test intersects(BoundingBox(0,0,0,1,1,1), BoundingBox(0.25,0.25,0.25,0.75,0.75,0.75))
    @test intersects(BoundingBox(0,0,0,1,1,1), BoundingBox(0.5,0.5,0.5,1.5,1.5,1.5))
    @test intersects(BoundingBox(0,0,0,1,1,1), BoundingBox(-0.5,-0.5,-0.5,0.5,0.5,0.5))

    # isempty
    @test !isempty(BoundingBox(0,0,0, 1, 1, 1))
    @test  isempty(BoundingBox(0,0,0,-1, 1, 1))
    @test  isempty(BoundingBox(0,0,0, 1,-1, 1))
    @test  isempty(BoundingBox(0,0,0, 1, 1,-1))
    @test  isempty(BoundingBox(0,0,0,-1,-1, 1))
    @test  isempty(BoundingBox(0,0,0,-1, 1,-1))
    @test  isempty(BoundingBox(0,0,0, 1,-1,-1))
    @test  isempty(BoundingBox(0,0,0,-1,-1,-1))

    # pad
    @test pad(BoundingBox(1,2,3,4,5,6), 1) === BoundingBox(0,1,2,5,6,7)

    # wireframe
    @test wireframe(BoundingBox(0,0,0,1,1,1)) == [Line(SVector(0,0,0), SVector(1,0,0)),
                                                  Line(SVector(0,1,0), SVector(1,1,0)),
                                                  Line(SVector(0,0,1), SVector(1,0,1)),
                                                  Line(SVector(0,1,1), SVector(1,1,1)),
                                                  Line(SVector(0,0,0), SVector(0,1,0)),
                                                  Line(SVector(1,0,0), SVector(1,1,0)),
                                                  Line(SVector(0,0,1), SVector(0,1,1)),
                                                  Line(SVector(1,0,1), SVector(1,1,1)),
                                                  Line(SVector(0,0,0), SVector(0,0,1)),
                                                  Line(SVector(1,0,0), SVector(1,0,1)),
                                                  Line(SVector(0,1,0), SVector(0,1,1)),
                                                  Line(SVector(1,1,0), SVector(1,1,1))]
end
