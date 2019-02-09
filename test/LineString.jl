@testset "LineString" begin
    ps = [SVector(0,0), SVector(0,1), SVector(1,1), SVector(1,0)]
    ls = LineString(ps)

    @test length(ls) == 3
    @test ls[2] == Line(SVector(0,1), SVector(1,1))

    @test boundingbox(ls) == BoundingBox(0,0,typemin(Int),1,1,typemax(Int))
    @test isclosed(ls) == false
    @test issimple(ls) == false

    @test convert2d(ls) == ls
    @test convert3d(ls) == LineString([SVector(0,0,0), SVector(0,1,0), SVector(1,1,0), SVector(1,0,0)])
    @test convert3d(ls, 1) == LineString([SVector(0,0,1), SVector(0,1,1), SVector(1,1,1), SVector(1,0,1)])
    @test convert3d(LineString([SVector(0,0,1), SVector(0,1,1), SVector(1,1,1), SVector(1,0,1)]), 2) == LineString([SVector(0,0,2), SVector(0,1,2), SVector(1,1,2), SVector(1,0,2)])

    push!(ps, SVector(0,0))
    @test length(ls) == 4
    @test isclosed(ls) == true
    @test issimple(ls) == true

    @test issimple(LineString([SVector(0,0), SVector(0,1), SVector(1,0), SVector(1,1), SVector(0,0)])) == false

    @testset "Winding number" begin
        ls_clockwise = LineString([SVector(0.0,0.0), SVector(0.0,1.0), SVector(1.0,1.0), SVector(1.0,0.0), SVector(0.0,0.0)])
        ls_anticlockwise = LineString([SVector(0.0,0.0), SVector(1.0,0.0), SVector(1.0,1.0), SVector(0.0,1.0), SVector(0.0,0.0)])

        p_centre = SVector(0.5, 0.5)
        ps_outer_ring = SVector{2,Float64}[[-1.0,-1.0],[0.0,-1.0],[0.5,-1.0],[1.0,-1.0],
                                           [2.0,-1.0],[2.0,0.0],[2.0,0.5],[2.0,1.0],
                                           [2.0,2.0],[1.0,2.0],[0.5,2.0],[0.0,2.0],
                                           [-1.0,2.0],[-1.0,1.0],[-1.0,0.5],[-1.0,0.0]]

        @test winding_number(p_centre, ls_clockwise) == 1
        @test winding_number(p_centre, ls_anticlockwise) == -1

        for p in ps_outer_ring
            @test winding_number(p, ls_clockwise) == 0
            @test winding_number(p, ls_anticlockwise) == 0
        end
    end
end