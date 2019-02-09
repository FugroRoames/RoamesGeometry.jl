@testset "Catenary" begin
    offset = SVector(1.0, 0.0, 5.0)
    Θ = pi / 4
    trans = inv(Translation(offset) ∘ LinearMap(RotZ(Θ)))
    lmin = -10.0
    lmax = 10.0
    a = 5.0

    cat = Catenary(trans, lmin, lmax, a)

    @test Catenary(Θ, offset[1], offset[2], offset[3], lmin, lmax, a) === cat

    @test cat[0.0] ≈ SVector(1.0, 0.0, 5.0)
    @test cat[sqrt(2.0)] ≈ SVector(2.0, 1.0, 5.2013368939727722)

    @test all(map(isapprox, cat[[0.0, sqrt(2.0)]], [SVector(1.0, 0.0, 5.0), SVector(2.0, 1.0, 5.2013368939727722)]))

    @test Quadratic(cat)[0.0] ≈ cat[-10.0]
    @test Quadratic(cat)[10.0] ≈ cat[0.0]
    @test Quadratic(cat)[20.0] ≈ cat[10.0]

    # Test these are invertible (up to numerical error)
    @test Catenary(Quadratic(cat))[-10.0] ≈ cat[-10.0]
    @test Catenary(Quadratic(cat))[0.0] ≈ cat[0.0]
    @test Catenary(Quadratic(cat))[10.0] ≈ cat[10.0]

    @test Quadratic(Catenary(Quadratic(cat)))[0.0] ≈ Quadratic(cat)[0.0]
    @test Quadratic(Catenary(Quadratic(cat)))[10.0] ≈ Quadratic(cat)[10.0]
    @test Quadratic(Catenary(Quadratic(cat)))[20.0] ≈ Quadratic(cat)[20.0]

    # Test stability for tight, steep wires like stays
    points = [SVector(0.0, 0.0, 10.0), SVector(5.0, 0.0, 5.0 - 0.000001), SVector(10.0, 0.0, 0.0)]
    cat = Catenary(points...)
    @test cat[cat.lmin] ≈ points[1]
    @test cat[(cat.lmin + cat.lmax)/2] ≈ points[2]
    @test cat[cat.lmax] ≈ points[3]

    # Exactly linear
    points = [SVector(0.0, 0.0, 10.0), SVector(5.0, 0.0, 5.0), SVector(10.0, 0.0, 0.0)]
    cat = Catenary(points...)
    @test isapprox(cat[cat.lmin], points[1]; atol = 1e-5)
    @test isapprox(cat[(cat.lmin + cat.lmax)/2], points[2]; atol = 1e-5)
    @test isapprox(cat[cat.lmax], points[3]; atol = 1e-5)

    # Degeneracy - flat
    points = [SVector(0.0, 0.0, 10.0), SVector(10.0, 0.0, 10.0), SVector(10.0, 0.0, 10.0)]
    cat = Catenary(points...)
    @test cat[cat.lmin] ≈ points[1]
    @test cat[cat.lmax] ≈ points[3]

    # Degeneracy - sloped
    points = [SVector(0.0, 0.0, 10.0), SVector(10.0, 0.0, 0.0), SVector(10.0, 0.0, 0.0)]
    cat = Catenary(points...)
    @test cat[cat.lmin] ≈ points[1]
    @test cat[cat.lmax] ≈ points[3]

    # Degeneracy - almost flat
    points = [SVector(0.0, 0.0, 10.0), SVector(10.0, 0.0, nextfloat(10.0)), SVector(10.0, 0.0, nextfloat(10.0))]
    cat = Catenary(points...)
    @test cat[cat.lmin] ≈ points[1]
    @test cat[cat.lmax] ≈ points[3]

    # Test stability for flat wires
    cat = Catenary(AffineMap(RotZ(0.374587), SVector(1.67667,-6.34842,-4.604)),-23.078470200626043,-18.554467003815063,2.067954545961777e11)
    p1 = cat[cat.lmin]
    p2 = cat[(cat.lmin + cat.lmax)/2]
    p3 = cat[cat.lmax]
    cat2 = Catenary(p1, p2, p3)
    @test cat2[cat2.lmin] ≈ p1
    @test cat2[(cat2.lmin + cat2.lmax)/2] ≈ p2
    @test cat2[cat2.lmax] ≈ p3

    cat = Catenary(AffineMap(RotZ(0.296116), SVector(1.17404,-6.46032,-4.395)),159.39653663015895,163.80649017276102,6.345e9)
    p1 = cat[cat.lmin]
    p2 = cat[(cat.lmin + cat.lmax)/2]
    p3 = cat[cat.lmax]
    cat2 = Catenary(p1, p2, p3)
    @test cat2[cat2.lmin] ≈ p1
    @test cat2[(cat2.lmin + cat2.lmax)/2] ≈ p2
    @test cat2[cat2.lmax] ≈ p3

    # TODO test transformations
end
