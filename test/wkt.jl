@testset "Well-known text" begin
    @testset "Writing WKT" begin
	    @test wkt(SVector(1.1, 2.2)) == "POINT (1.1 2.2)"
	    @test wkt(SVector(1.1, 2.2, 3.3)) == "POINT Z (1.1 2.2 3.3)"

	    @test wkt(Line(SVector(1.1, 1.2), SVector(2.1, 2.2))) == "LINESTRING (1.1 1.2, 2.1 2.2)"
	    @test wkt(Line(SVector(1.1, 1.2, 1.3), SVector(2.1, 2.2, 2.3))) == "LINESTRING Z (1.1 1.2 1.3, 2.1 2.2 2.3)"

        @test wkt(LineString(SVector{2,Float64}[])) == "LINESTRING EMPTY"
   	    @test wkt(LineString([SVector(1.1, 1.2), SVector(2.1, 2.2)])) == "LINESTRING (1.1 1.2, 2.1 2.2)"
   	    @test wkt(LineString(SVector{3,Float64}[])) == "LINESTRING Z EMPTY"
	    @test wkt(LineString([SVector(1.1, 1.2, 1.3), SVector(2.1, 2.2, 2.3)])) == "LINESTRING Z (1.1 1.2 1.3, 2.1 2.2 2.3)"

	    @test wkt(Polygon(SVector{2,Float64}[])) == "POLYGON EMPTY"
	    @test wkt(Polygon([SVector(1.0, 1.0), SVector(1.0, 2.0), SVector(2.0, 2.0), SVector(1.0, 1.0)])) == 
	        "POLYGON ((1.0 1.0, 1.0 2.0, 2.0 2.0, 1.0 1.0))"
	    @test wkt(Polygon(SVector{3,Float64}[])) == "POLYGON Z EMPTY"
	    @test wkt(Polygon([SVector(1.0, 1.0, 0.0), SVector(1.0, 2.0, 0.0), SVector(2.0, 2.0, 0.0), SVector(1.0, 1.0, 0.0)])) ==
	        "POLYGON Z ((1.0 1.0 0.0, 1.0 2.0 0.0, 2.0 2.0 0.0, 1.0 1.0 0.0))"

        @test wkt(SVector{2,Float64}[]) == "MULTIPOINT EMPTY"
        @test wkt([SVector(1.1, 2.2)]) == "MULTIPOINT ((1.1 2.2))"
        @test wkt([SVector(1.1, 2.2), SVector(1.1, 2.2)]) == "MULTIPOINT ((1.1 2.2), (1.1 2.2))"
	    @test wkt(SVector{3,Float64}[]) == "MULTIPOINT Z EMPTY"
	    @test wkt([SVector(1.1, 2.2, 3.3)]) == "MULTIPOINT Z ((1.1 2.2 3.3))"
	    @test wkt([SVector(1.1, 2.2, 3.3), SVector(1.1, 2.2, 3.3)]) == "MULTIPOINT Z ((1.1 2.2 3.3), (1.1 2.2 3.3))"

	    @test wkt([Line(SVector(1.1, 1.2), SVector(2.1, 2.2))]) == "MULTILINESTRING ((1.1 1.2, 2.1 2.2))"
	    @test wkt([Line(SVector(1.1, 1.2), SVector(2.1, 2.2)), Line(SVector(1.1, 1.2), SVector(2.1, 2.2))]) ==
	        "MULTILINESTRING ((1.1 1.2, 2.1 2.2), (1.1 1.2, 2.1 2.2))"
	    @test wkt([Line(SVector(1.1, 1.2, 1.3), SVector(2.1, 2.2, 2.3))]) == "MULTILINESTRING Z ((1.1 1.2 1.3, 2.1 2.2 2.3))"
	    @test wkt([Line(SVector(1.1, 1.2, 1.3), SVector(2.1, 2.2, 2.3)), Line(SVector(1.1, 1.2, 1.3), SVector(2.1, 2.2, 2.3))]) ==
	        "MULTILINESTRING Z ((1.1 1.2 1.3, 2.1 2.2 2.3), (1.1 1.2 1.3, 2.1 2.2 2.3))"

   	    @test wkt(LineString{2,Float64,Vector{SVector{2,Float64}}}[]) == "MULTILINESTRING EMPTY"
	    @test wkt([LineString([SVector(1.1, 1.2), SVector(2.1, 2.2)])]) == "MULTILINESTRING ((1.1 1.2, 2.1 2.2))"
   	    @test wkt([LineString([SVector(1.1, 1.2), SVector(2.1, 2.2)]), LineString([SVector(1.1, 1.2), SVector(2.1, 2.2)])]) ==
   	    	"MULTILINESTRING ((1.1 1.2, 2.1 2.2), (1.1 1.2, 2.1 2.2))"
	    @test wkt(LineString{3,Float64,Vector{SVector{3,Float64}}}[]) == "MULTILINESTRING Z EMPTY"
	    @test wkt([LineString([SVector(1.1, 1.2, 1.3), SVector(2.1, 2.2, 2.3)])]) == "MULTILINESTRING Z ((1.1 1.2 1.3, 2.1 2.2 2.3))"
	    @test wkt([LineString([SVector(1.1, 1.2, 1.3), SVector(2.1, 2.2, 2.3)]), LineString([SVector(1.1, 1.2, 1.3), SVector(2.1, 2.2, 2.3)])]) ==
	        "MULTILINESTRING Z ((1.1 1.2 1.3, 2.1 2.2 2.3), (1.1 1.2 1.3, 2.1 2.2 2.3))"

        @test wkt(Polygon{2,Float64,LineString{2,Float64,Vector{SVector{2,Float64}}},Vector{LineString{2,Float64,Vector{SVector{2,Float64}}}}}[]) ==
            "MULTIPOLYGON EMPTY"
	    @test wkt([Polygon([SVector(1.0, 1.0), SVector(1.0, 2.0), SVector(2.0, 2.0), SVector(1.0, 1.0)])]) ==
	        "MULTIPOLYGON (((1.0 1.0, 1.0 2.0, 2.0 2.0, 1.0 1.0)))"
	    @test wkt([Polygon([SVector(1.0, 1.0), SVector(1.0, 2.0), SVector(2.0, 2.0), SVector(1.0, 1.0)]), Polygon([SVector(1.0, 1.0), SVector(1.0, 2.0), SVector(2.0, 2.0), SVector(1.0, 1.0)])]) ==
	        "MULTIPOLYGON (((1.0 1.0, 1.0 2.0, 2.0 2.0, 1.0 1.0)), ((1.0 1.0, 1.0 2.0, 2.0 2.0, 1.0 1.0)))"
	    @test wkt(Polygon{3,Float64,LineString{3,Float64,Vector{SVector{3,Float64}}},Vector{LineString{3,Float64,Vector{SVector{3,Float64}}}}}[]) ==
            "MULTIPOLYGON Z EMPTY"
	    @test wkt([Polygon([SVector(1.0, 1.0, 0.0), SVector(1.0, 2.0, 0.0), SVector(2.0, 2.0, 0.0), SVector(1.0, 1.0, 0.0)])]) ==
	        "MULTIPOLYGON Z (((1.0 1.0 0.0, 1.0 2.0 0.0, 2.0 2.0 0.0, 1.0 1.0 0.0)))"
	    @test wkt([Polygon([SVector(1.0, 1.0, 0.0), SVector(1.0, 2.0, 0.0), SVector(2.0, 2.0, 0.0), SVector(1.0, 1.0, 0.0)]), Polygon([SVector(1.0, 1.0, 0.0), SVector(1.0, 2.0, 0.0), SVector(2.0, 2.0, 0.0), SVector(1.0, 1.0, 0.0)])]) ==
	        "MULTIPOLYGON Z (((1.0 1.0 0.0, 1.0 2.0 0.0, 2.0 2.0 0.0, 1.0 1.0 0.0)), ((1.0 1.0 0.0, 1.0 2.0 0.0, 2.0 2.0 0.0, 1.0 1.0 0.0)))"

        @test wkt(Any[]) == "GEOMETRYCOLLECTION EMPTY"
	    @test wkt(Any[SVector(1.0,2.0)]) == "GEOMETRYCOLLECTION (POINT (1.0 2.0))"
	    @test wkt(Any[SVector(1.0,2.0), Line(SVector(1.1, 1.2), SVector(2.1, 2.2))]) == "GEOMETRYCOLLECTION (POINT (1.0 2.0), LINESTRING (1.1 1.2, 2.1 2.2))"
    end

    @testset "Reading WKT" begin
        @test_broken read_wkt(IOBuffer("POINT EMPTY")) == SVector(NaN, NaN) # Not sure what this should be?
	    @test read_wkt("POINT (1.1 2.2)") == SVector(1.1, 2.2)
	    @test_broken read_wkt(IOBuffer("POINT Z EMPTY")) == SVector(NaN, NaN, NaN) # Not sure what this should be?
	    @test read_wkt("POINT Z (1.1 2.2 3.3)") == SVector(1.1, 2.2, 3.3)

	    @test read_wkt("LINESTRING EMPTY") == LineString(SVector{2,Float64}[])
	    @test read_wkt("LINESTRING (1.1 1.2, 2.1 2.2)") == LineString([SVector(1.1, 1.2), SVector(2.1, 2.2)])
	    @test read_wkt("LINESTRING Z EMPTY") == LineString(SVector{3,Float64}[])
	    @test read_wkt("LINESTRING Z (1.1 1.2 1.3, 2.1 2.2 2.3)") == LineString([SVector(1.1, 1.2, 1.3), SVector(2.1, 2.2, 2.3)])

	    @test read_wkt("POLYGON EMPTY") == Polygon(SVector{2,Float64}[])
	    @test read_wkt("POLYGON ((1.0 1.0, 1.0 2.0, 2.0 2.0, 1.0 1.0))") ==
	        Polygon([SVector(1.0, 1.0), SVector(1.0, 2.0), SVector(2.0, 2.0), SVector(1.0, 1.0)])
	    @test read_wkt("POLYGON Z EMPTY") == Polygon(SVector{3,Float64}[])
	    @test read_wkt("POLYGON Z ((1.0 1.0 0.0, 1.0 2.0 0.0, 2.0 2.0 0.0, 1.0 1.0 0.0))") ==
	        Polygon([SVector(1.0, 1.0, 0.0), SVector(1.0, 2.0, 0.0), SVector(2.0, 2.0, 0.0), SVector(1.0, 1.0, 0.0)])

        @test read_wkt(IOBuffer("MULTIPOINT EMPTY"))::Vector{SVector{2,Float64}} == []
	    @test read_wkt(IOBuffer("MULTIPOINT ((1.1 2.2))")) == [SVector(1.1, 2.2)]
        @test read_wkt(IOBuffer("MULTIPOINT ((1.1 2.2), (1.1 2.2))")) == [SVector(1.1, 2.2), SVector(1.1, 2.2)]
        @test read_wkt(IOBuffer("MULTIPOINT Z EMPTY"))::Vector{SVector{3,Float64}} == []
	    @test read_wkt(IOBuffer("MULTIPOINT Z ((1.1 2.2 3.3))")) == [SVector(1.1, 2.2, 3.3)]
	    @test read_wkt(IOBuffer("MULTIPOINT Z ((1.1 2.2 3.3), (1.1 2.2 3.3))")) == [SVector(1.1, 2.2, 3.3), SVector(1.1, 2.2, 3.3)]

	    @test read_wkt("MULTILINESTRING EMPTY")::Vector{<:LineString{2}} == []
	    @test read_wkt("MULTILINESTRING ((1.1 1.2, 2.1 2.2))") == [LineString([SVector(1.1, 1.2), SVector(2.1, 2.2)])]
   	    @test read_wkt("MULTILINESTRING ((1.1 1.2, 2.1 2.2), (1.1 1.2, 2.1 2.2))") ==
   	        [LineString([SVector(1.1, 1.2), SVector(2.1, 2.2)]), LineString([SVector(1.1, 1.2), SVector(2.1, 2.2)])]
   	    @test read_wkt("MULTILINESTRING Z EMPTY")::Vector{<:LineString{3}} == []
	    @test read_wkt("MULTILINESTRING Z ((1.1 1.2 1.3, 2.1 2.2 2.3))") == [LineString([SVector(1.1, 1.2, 1.3), SVector(2.1, 2.2, 2.3)])]
	    @test read_wkt("MULTILINESTRING Z ((1.1 1.2 1.3, 2.1 2.2 2.3), (1.1 1.2 1.3, 2.1 2.2 2.3))") ==
	        [LineString([SVector(1.1, 1.2, 1.3), SVector(2.1, 2.2, 2.3)]), LineString([SVector(1.1, 1.2, 1.3), SVector(2.1, 2.2, 2.3)])]
	    
	    @test read_wkt("MULTIPOLYGON EMPTY")::Vector{<:Polygon{2}} == []
        @test read_wkt("MULTIPOLYGON (((1.0 1.0, 1.0 2.0, 2.0 2.0, 1.0 1.0)))") ==
	        [Polygon([SVector(1.0, 1.0), SVector(1.0, 2.0), SVector(2.0, 2.0), SVector(1.0, 1.0)])]
	    @test read_wkt("MULTIPOLYGON (((1.0 1.0, 1.0 2.0, 2.0 2.0, 1.0 1.0)), ((1.0 1.0, 1.0 2.0, 2.0 2.0, 1.0 1.0)))") ==
	        [Polygon([SVector(1.0, 1.0), SVector(1.0, 2.0), SVector(2.0, 2.0), SVector(1.0, 1.0)]), Polygon([SVector(1.0, 1.0), SVector(1.0, 2.0), SVector(2.0, 2.0), SVector(1.0, 1.0)])]
	    @test read_wkt("MULTIPOLYGON Z EMPTY")::Vector{<:Polygon{3}} == []
	    @test read_wkt("MULTIPOLYGON Z (((1.0 1.0 0.0, 1.0 2.0 0.0, 2.0 2.0 0.0, 1.0 1.0 0.0)))") ==
	        [Polygon([SVector(1.0, 1.0, 0.0), SVector(1.0, 2.0, 0.0), SVector(2.0, 2.0, 0.0), SVector(1.0, 1.0, 0.0)])]
	    @test read_wkt("MULTIPOLYGON Z (((1.0 1.0 0.0, 1.0 2.0 0.0, 2.0 2.0 0.0, 1.0 1.0 0.0)), ((1.0 1.0 0.0, 1.0 2.0 0.0, 2.0 2.0 0.0, 1.0 1.0 0.0)))") ==
	        [Polygon([SVector(1.0, 1.0, 0.0), SVector(1.0, 2.0, 0.0), SVector(2.0, 2.0, 0.0), SVector(1.0, 1.0, 0.0)]), Polygon([SVector(1.0, 1.0, 0.0), SVector(1.0, 2.0, 0.0), SVector(2.0, 2.0, 0.0), SVector(1.0, 1.0, 0.0)])]

        @test read_wkt("GEOMETRYCOLLECTION EMPTY")::Vector{Any} == []
	    @test read_wkt("GEOMETRYCOLLECTION (POINT (1.0 2.0))") == Any[SVector(1.0,2.0)]
	    @test read_wkt("GEOMETRYCOLLECTION (POINT (1.0 2.0), LINESTRING (1.1 1.2, 2.1 2.2))") ==
	        Any[SVector(1.0,2.0), LineString([SVector(1.1, 1.2), SVector(2.1, 2.2)])]

	    @test_throws RoamesGeometry.WKTParsingError read_wkt(IOBuffer("POINT (1.1 2.2 3.3)"))
	    @test_throws RoamesGeometry.WKTParsingError read_wkt(IOBuffer("POINT Z (1.1 2.2)"))
	    @test_throws RoamesGeometry.WKTParsingError read_wkt(IOBuffer("POINT M (1.1 2.2 0.0)"))
	    @test_throws RoamesGeometry.WKTParsingError read_wkt(IOBuffer("POINT ZM (1.1 2.2 3.3 0.0)"))
	    @test_throws RoamesGeometry.WKTParsingError read_wkt(IOBuffer("PONT (1.1 2.2)"))
	    @test_throws RoamesGeometry.WKTParsingError read_wkt(IOBuffer("POINT 1.1 2.2)"))
	    @test_throws RoamesGeometry.WKTParsingError read_wkt(IOBuffer("POINT (1.1 2.2"))
	    @test_throws RoamesGeometry.WKTParsingError read_wkt(IOBuffer("POINT (1.1 2.2))"))
	    @test_throws RoamesGeometry.WKTParsingError read_wkt(IOBuffer("POINT (1.1 2.2)a"))
    end

    @testset "eWKT" begin
        @test wkt(SVector(1.1, 2.2); srid="32756") == "SRID=32756; POINT (1.1 2.2)"
        @test wkt(SVector(1.1, 2.2); srid="32756,ausgeoid09") == "SRID=32756,ausgeoid09; POINT (1.1 2.2)"

        srid_ref = Ref("")
        @test read_wkt("SRID=32756; POINT (1.1 2.2)", srid=srid_ref) == SVector(1.1, 2.2)
        @test srid_ref[] == "32756"

        srid_ref2 = Ref("")
        @test read_wkt("SRID=32756,ausgeoid09; POINT (1.1 2.2)",srid=srid_ref2) == SVector(1.1, 2.2)
        @test srid_ref2[] == "32756,ausgeoid09"
    end
end