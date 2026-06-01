
"""
function read_kml(kml_file::String;
        return_table::Bool = false,
        swap_axes::Bool = false,
        first_outer_ring_only = true)

By default will return only the first outer ring found in the file as a Polygon type. If first_outer_ring_only = false Reads in a vector of RoamesGeometry Polygon type,
 It works for single polygons, multi polygons and polygons with holes note in the case of holes the direction of the hole needs to be the opposite of the exterior otherwise points in the hole will be included, all inner
and outer LineStrings need to be closed and simple. If  first_outer_ring_only = true and return_table is true a Table type is returned instead of a Polygon (note you cannot read as a table if first_outer_ring_only is false).
By default the polygon points will be lat followed by lon, ie the opposite of the kml file, setting swap_axes=true will makeit lon, lat 
"""
function read_kml(kml_file::String;
    return_table::Bool = false,
    swap_axes::Bool = false,
    first_outer_ring_only = true)::Union{Table,Polygon,Vector{P} where P<:Polygon}
    poly = Polygon[]
    s = read(kml_file, String)
    samples = swap_axes ? [1, 2, 3] : [2, 1, 3]
    loc = 1
    while true
        tag = r"<Polygon>"
        m1 = match(tag, s, loc)
        if isnothing(m1)
            break
        end
        outer = SArray{Tuple{2},Float64,1,2}[]
        inners = Vector{SVector{2, Float64}}[]
        firstPass = true
        is3D = false
        while true
            tag2 = r"<outerBoundaryIs>"
            m2 = match(tag2, s, m1.offset)
            tag3 = r"<innerBoundaryIs>"
            m3 = match(tag3, s, m1.offset)
            tag4 = r"</Polygon>"
            m4 = match(tag4, s, m1.offset)
            if (isnothing(m2) || m4.offset < m2.offset) && (isnothing(m3) || m4.offset < m3.offset)
                break
            end
            isInner = false
            if isnothing(m3) || !isnothing(m2) && m3.offset > m2.offset
                m1 = m2
            else
                m1 = m3
                isInner = true
            end
            tag = r"<coordinates>"
            m1 = match(tag, s, m1.offset)
            start = m1.offset + length(tag.pattern)
            tag = r"</coordinates>"
            m1 = match(tag, s, m1.offset)
            loc = m1.offset
            finish = m1.offset - 1
            temp = split(s[start:finish])
            if firstPass
                is3D = length(split(temp[1],',')) > 2
                if is3D # if all z values are 0 treat as being 2D polygon
                    is3D = !(all(t->parse(Float64, split(t,',')[end]) == 0.0, temp))
                end
            end
            sampler = is3D ? samples : samples[1:2] 
            if firstPass && is3D
                outer = SArray{Tuple{3},Float64,1,3}[]
                inners = Vector{SVector{3, Float64}}[]
            end
            if isInner
                push!(inners, map(ss->SVector(parse.(Float64,split(ss,',')[sampler])...), temp))
            else
                outer = map(ss->SVector(parse.(Float64,split(ss,',')[sampler])...), temp)
            end
            firstPass = false
        end
        if first_outer_ring_only
            if return_table
                return Table(position = outer)
            else
                return Polygon(LineString(outer))
            end
        end
        push!(poly, Polygon(LineString(outer), LineString.(inners)))
    end
    return poly
end

function write_kml(
    polygon::Union{Table,Polygon},
    poly_file::String;
    poly_name::String = "Test",
    color::String = "ffffff",
)::Nothing
    if polygon isa Table
        poly = polygon.position
        write_kml(
            [Polygon(poly)],
            poly_file;
            poly_name,
            color,
        )
    else
        write_kml(
            [polygon],
            poly_file;
            poly_name,
            color,
        )
    end
    return nothing
end

"""
    function write_kml(
        polygon::Vector{P} where P <:Polygon,
        poly_file::String;
        poly_name::String = "Test",
        color::String = "ffffff",
    )::Nothing
Exports polygon to a `kml` file.
* `polygon`: Is a vector of RoamesGeometry.Polygon type, the vector being how we deal with multipolygons, each polygon may contain holes and be 2D or 3D
* `poly_file`: Polygon file name
* `poly_name`: Polygon name that goes into the kml file.
* `color`: Color of the polygon
"""
function write_kml(
    polygon::Vector{P} where P<:Polygon,
    poly_file::String;
    poly_name::String = "Test",
    color::String = "ffffff",
)::Nothing
    has_alt = polygon[1].exterior.points[1] == 3
    values = has_alt ? [2,1,3] : [2,1]
    open(poly_file, "w") do f
        println(
            f,
            """<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
<Document>
        <name>$(basename(poly_file))</name>
        <StyleMap id="msn_ylw-pushpin">
                <Pair>
                        <key>normal</key>
                        <styleUrl>#sn_ylw-pushpin</styleUrl>
                </Pair>
                <Pair>
                        <key>highlight</key>
                        <styleUrl>#sh_ylw-pushpin</styleUrl>
                </Pair>
        </StyleMap>
        <Style id="sh_ylw-pushpin">
                <IconStyle>
                        <scale>1.2</scale>
                </IconStyle>
                <LineStyle>
                        <color>ff$color</color>
                </LineStyle>
                <PolyStyle>
                        <color>50$color</color>
                </PolyStyle>
        </Style>
        <Style id="sn_ylw-pushpin">
                <LineStyle>
                        <color>ff$color</color>
                </LineStyle>
                <PolyStyle>
                        <color>50$color</color>
                </PolyStyle>
        </Style>
        <Placemark>
                <name>$(poly_name)</name>
                <styleUrl>#msn_ylw-pushpin</styleUrl>"""
        )
        println(f,"<MultiGeometry>")
        for poly in polygon
            println(f,"<Polygon>")
            if !isempty(poly.exterior)
                println(f, "<outerBoundaryIs><LinearRing><coordinates>")
                points = poly.exterior.points
                if is_clockwise(map(e -> (lat=e[1], lon=e[2]), points))
                    points = reverse(points)
                end
                text = join(map(p->join(p[values],','), points)," ")
                println(f, text)
                println(f, "</coordinates></LinearRing></outerBoundaryIs>")
            end
            if !isempty(poly.interiors)
                for inner in poly.interiors
                    println(f, "<innerBoundaryIs><LinearRing><coordinates>")
                    points = inner.points
                    if !is_clockwise(map(e -> (lat=e[1], lon=e[2]), points))
                        points = reverse(points)
                    end
                    text = join(map(p->join(p[values],','), points)," ")
                    println(f, text)
                    println(f, "</coordinates></LinearRing></innerBoundaryIs>")
                end
            end
            println(f,"</Polygon>")
        end
        println(f,"</MultiGeometry></Placemark></Document></kml>")
    end
    return nothing
end

"""
Checks if polygon points are clockwise

    https://www.element84.com/blog/determining-the-winding-of-a-polygon-given-as-a-set-of-ordered-points
"""
function is_clockwise(polygon_edges::Vector)::Bool
    x = map(p -> p.lat, polygon_edges[1:end-1])
    y = map(p -> p.lon, polygon_edges[1:end-1])
    x_dif = circshift(x, -1) .- x
    y_sum = circshift(y, -1) .+ y
    return sum(x_dif .* y_sum) > 0
end

function is_clockwise(polygon::Union{Table,Polygon})::Bool
    edges = if polygon isa Table 
        polygon.position
    else
        polygon.exterior.points
    end
    edges = map(e -> (lat=e[1], lon=e[2]), edges)
    return is_clockwise(edges)
end