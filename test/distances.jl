@testset "Point distances" begin
    p1_2d = SVector(0.0, 0.0)
    p2_2d = SVector(1.0, 1.0)
    @test distance(p1_2d, p2_2d) == sqrt(2.0)
    
    p1_3d = SVector(0.0, 0.0, 1.0)
    p2_3d = SVector(1.0, 1.0, 2.0)
    @test distance(p1_3d, p2_3d) == sqrt(3.0)

    @test distance(p1_3d, p2_2d) == sqrt(2.0)
    @test distance(p1_2d, p2_3d) == sqrt(2.0)
end

@testset "Catenary distances" begin

    # z = cosh(x) - 1 for x ∈ -1.0 .. 1.0
    cat = Catenary(IdentityTransformation(), -1.0, 1.0, 1.0)

    @test distance(cat, SVector(0.0, 0.0, 0.0)) === 0.0
    @test distance(SVector(0.0, 0.0, 0.0), cat) === 0.0

    @test powerline_distances(cat, SVector(0.0, 0.0, 0.0)) === (0.0, 0.0, 0.0, 0.0)
    @test powerline_distances(SVector(0.0, 0.0, 0.0), cat) === (0.0, 0.0, 0.0, 0.0)

    # Distance to catenary body
    # below
    @test powerline_distances(cat, SVector(0.5, 0.0, 0.0)) === (0.11454038802773013, 0.0, -(cosh(0.5)-1), 0.5)
    @test powerline_distances(cat, SVector(-0.5, 0.0, 0.0)) === (0.11454038802773013, 0.0, -(cosh(0.5)-1), -0.5)
    @test powerline_distances(cat, SVector(0.5, 0.5, 0.0)) === (nextfloat(sqrt(0.5^2 + 0.11454038802773013^2)), 0.5, -(cosh(0.5)-1), 0.5)
    @test powerline_distances(cat, SVector(-0.5, 0.5, 0.0)) === (nextfloat(sqrt(0.5^2 + 0.11454038802773013^2)), 0.5, -(cosh(0.5)-1), -0.5)
    @test powerline_distances(cat, SVector(0.5, -0.5, 0.0)) === (nextfloat(sqrt(0.5^2 + 0.11454038802773013^2)), -0.5, -(cosh(0.5)-1), 0.5)
    @test powerline_distances(cat, SVector(-0.5, -0.5, 0.0)) === (nextfloat(sqrt(0.5^2 + 0.11454038802773013^2)), -0.5, -(cosh(0.5)-1), -0.5)

    # above
    @test powerline_distances(cat, SVector(0.5, 0.0, 0.5)) === (0.31834847276128164, 0.0, -(cosh(0.5)-1.5), 0.5)
    @test powerline_distances(cat, SVector(-0.5, 0.0, 0.5)) === (0.31834847276128164, 0.0, -(cosh(0.5)-1.5), -0.5)
    @test powerline_distances(cat, SVector(0.5, 0.5, 0.5)) === (nextfloat(sqrt(0.5^2 + 0.31834847276128164^2)), 0.5, -(cosh(0.5)-1.5), 0.5)
    @test powerline_distances(cat, SVector(-0.5, 0.5, 0.5)) === (nextfloat(sqrt(0.5^2 + 0.31834847276128164^2)), 0.5, -(cosh(0.5)-1.5), -0.5)
    @test powerline_distances(cat, SVector(0.5, -0.5, 0.5)) === (nextfloat(sqrt(0.5^2 + 0.31834847276128164^2)), -0.5, -(cosh(0.5)-1.5), 0.5)
    @test powerline_distances(cat, SVector(-0.5, -0.5, 0.5)) === (nextfloat(sqrt(0.5^2 + 0.31834847276128164^2)), -0.5, -(cosh(0.5)-1.5), -0.5)

    # distance to catenary end points
    # left
    @test powerline_distances(cat, SVector(-1.5, 0.0, 0.5430806348152437)) === (0.5, 0.0, 0.0, -1.5)

    # right
    @test powerline_distances(cat, SVector(1.5, 0.0, 0.5430806348152437)) === (0.5, 0.0, 0.0, 1.5)
end
