@testset "Polygon" begin
    a = SVector{2,Float32}(0, 0)
    b = SVector{2,Float32}(0, 1)
    c = SVector{2,Float32}(1, 1)
    d = SVector{2,Float32}(1, 0)
    p = Polygon([a,b,c,d,a])

    @test boundingbox(p) == BoundingBox(0,0,-Inf,1,1,Inf)

    @test convert2d(p) == p
    @test convert3d(p) == Polygon(map(x->SVector{3,Float32}(x[1], x[2], 0.0), [a,b,c,d,a]))
    @test convert3d(p, 1) == Polygon(map(x->SVector{3,Float32}(x[1], x[2], 1.0), [a,b,c,d,a]))
    @test convert3d(Polygon(map(x->SVector{3,Float32}(x[1], x[2], 1.0), [a,b,c,d,a])), 2) == Polygon{3}([Float32[0.0, 0.0, 2.0], Float32[0.0, 1.0, 2.0], Float32[1.0, 1.0, 2.0], Float32[1.0, 0.0, 2.0], Float32[0.0, 0.0, 2.0]])

    @testset "Point containment and distance" begin
        ls_outer = LineString([SVector(0.0,0.0), SVector(0.0,1.0), SVector(1.0,1.0), SVector(1.0,0.0), SVector(0.0,0.0)])
        ls_inner = LineString([SVector(0.4,0.4), SVector(0.6,0.4), SVector(0.6,0.6), SVector(0.4,0.6), SVector(0.4,0.4)])

        poly1 = Polygon(ls_outer)
        poly2 = Polygon(ls_outer, [ls_inner])

        p_centre = SVector(0.5, 0.5)
        ps_inner_ring = SVector{2,Float64}[[0.3,0.3],[0.4,0.3],[0.5,0.3],[0.6,0.3],[0.7,0.3],[0.7,0.4],[0.7,0.5],[0.7,0.6],[0.7,0.7],[0.6,0.7],[0.5,0.7],[0.4,0.7],[0.3,0.7],[0.3,0.6],[0.3,0.5],[0.3,0.4]]
        ps_outer_ring = SVector{2,Float64}[[-1.0,-1.0],[0.0,-1.0],[0.3,-1.0],[0.4,-1.0],[0.5,-1.0],[0.6,-1.0],[0.7,-1.0],[1.0,-1.0],
                                           [2.0,-1.0],[2.0,0.0],[2.0,0.3],[2.0,0.4],[2.0,0.5],[2.0,0.6],[2.0,0.7],[2.0,1.0],
                                           [2.0,2.0],[1.0,2.0],[0.7,2.0],[0.6,2.0],[0.5,2.0],[0.4,2.0],[0.3,2.0],[0.0,2.0],
                                           [-1.0,2.0],[-1.0,1.0],[-1.0,0.7],[-1.0,0.6],[-1.0,0.5],[-1.0,0.4],[-1.0,0.3],[-1.0,0.0]]

        dists_outer = [sqrt(2), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
                       sqrt(2), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
                       sqrt(2), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
                       sqrt(2), 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

        @test p_centre ∈ poly1
        @test p_centre ∉ poly2
        @test distance(p_centre, poly1) == 0.0
        @test distance(p_centre, poly2) ≈ 0.1

        for p in ps_inner_ring
            @test p ∈ poly1
            @test p ∈ poly2
            @test distance(p, poly1) == 0.0
            @test distance(p, poly2) == 0.0
        end

        for (i, p) in enumerate(ps_outer_ring)
            @test p ∉ poly1
            @test p ∉ poly2
            @test distance(p, poly1) == dists_outer[i]
            @test distance(p, poly2) == dists_outer[i]
        end

        poly3 = Polygon(ls_outer) # New instance of poly1
        @test isequal(poly1, poly3)
        @test !isequal(poly1, poly2)
        @test hash(poly1) == hash(poly3)
    end
end