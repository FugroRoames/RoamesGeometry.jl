"""
    wkt(geometry; [srid])

Return a string containing the well-known text for a geometry.
"""
function wkt(geometry; srid::String = "")
    io = IOBuffer()
    if srid != ""
        write(io, "SRID=")
        write(io, srid)
        write(io, "; ")
    end
    write_wkt(io, geometry)
    return String(take!(io))
end

# Filenamed-based I/O uses "load" and "save" terminology

"""
    load_wkt(filename; [srid])

Open a file to read well-known text.

Optionally, may read a SRID string from eWKT into the *reference* provided. E.g.

```
srid_ref = Ref("")
geometry = load_wkt("file.wkt"; srid=srid_ref)
srid = srid_ref[]
```
"""
function load_wkt(filename::AbstractString; srid::RefValue{String} = Ref(""))
    open(io -> read_wkt(io; srid = srid), filename)
end

"""
    save_wkt(filename, geometry; [srid])

Save a geometry to a file in well-known text format. Optionally, provide a `srid` string to
write eWKT.
"""
function save_wkt(filename::AbstractString, geometry; srid::String = "")
    open(filename, "w") do (io)
        if srid != ""
            write(io, "SRID=")
            write(io, srid)
            write(io, "; ")
        end
        write_wkt(io, geometry)
    end
    return nothing
end

# IO stream based I/O uses "read" and "write" terminology

"""
    write_wkt(io, geometry)

Writes well-known text to the IO stream `io` for the provided `geometry`.
"""
function write_wkt(io::IO, point::StaticVector{2})
    bytes = 0 # write functions in Julia tend to return number of written bytes
    bytes += write(io, "POINT (")
    bytes += write(io, string(point[1]))
    bytes += write(io, " ")
    bytes += write(io, string(point[2]))
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, point::StaticVector{3})
    bytes = 0
    bytes += write(io, "POINT Z (")
    bytes += write(io, string(point[1]))
    bytes += write(io, " ")
    bytes += write(io, string(point[2]))
    bytes += write(io, " ")
    bytes += write(io, string(point[3]))
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, l::Line{2})
    bytes = 0
    bytes += write(io, "LINESTRING (") # There is no LINE type in WKT
    bytes += write(io, string(l.p1[1]))
    bytes += write(io, " ")
    bytes += write(io, string(l.p1[2]))
    bytes += write(io, ", ")
    bytes += write(io, string(l.p2[1]))
    bytes += write(io, " ")
    bytes += write(io, string(l.p2[2]))
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, l::Line{3})
    bytes = 0
    bytes += write(io, "LINESTRING Z (") # There is no LINE type in WKT
    bytes += write(io, string(l.p1[1]))
    bytes += write(io, " ")
    bytes += write(io, string(l.p1[2]))
    bytes += write(io, " ")
    bytes += write(io, string(l.p1[3]))
    bytes += write(io, ", ")
    bytes += write(io, string(l.p2[1]))
    bytes += write(io, " ")
    bytes += write(io, string(l.p2[2]))
    bytes += write(io, " ")
    bytes += write(io, string(l.p2[3]))
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, ls::LineString{2})
    if length(ls.points) < 2
        return write(io, "LINESTRING EMPTY")
    end
    
    bytes = 0
    bytes += write(io, "LINESTRING (")
    @inbounds for i = 1:length(ls.points)
        p = ls.points[i]
        bytes += write(io, string(p[1]))
        bytes += write(io, " ")
        bytes += write(io, string(p[2]))
        if i < length(ls.points)
            bytes += write(io, ", ")
        end
    end
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, ls::LineString{3})
    if length(ls.points) < 2
        return write(io, "LINESTRING Z EMPTY")
    end
    
    bytes = 0
    bytes += write(io, "LINESTRING Z (")
    @inbounds for i = 1:length(ls.points)
        p = ls.points[i]
        bytes += write(io, string(p[1]))
        bytes += write(io, " ")
        bytes += write(io, string(p[2]))
        bytes += write(io, " ")
        bytes += write(io, string(p[3]))
        if i < length(ls.points)
            bytes += write(io, ", ")
        end
    end
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, polygon::Polygon{2})
    if length(polygon.exterior.points) < 4
        return write(io, "POLYGON EMPTY")
    end
    
    bytes = 0
    bytes += write(io, "POLYGON ((")
    @inbounds for i = 1:length(polygon.exterior.points)
        p = polygon.exterior.points[i]
        bytes += write(io, string(p[1]))
        bytes += write(io, " ")
        bytes += write(io, string(p[2]))
        if i < length(polygon.exterior.points)
            bytes += write(io, ", ")
        end
    end
    bytes += write(io, ")")

    for ls in polygon.interiors
        bytes += write(io, ", (")
        @inbounds for i = 1:length(ls.points)
            p = ls.points[i]
            bytes += write(io, string(p[1]))
            bytes += write(io, " ")
            bytes += write(io, string(p[2]))
            if i < length(ls.points)
                bytes += write(io, ", ")
            end
        end
        bytes += write(io, ")")
    end
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, polygon::Polygon{3})
    if length(polygon.exterior.points) < 4
        return write(io, "POLYGON Z EMPTY")
    end
    
    bytes = 0
    bytes += write(io, "POLYGON Z ((")
    @inbounds for i = 1:length(polygon.exterior.points)
        p = polygon.exterior.points[i]
        bytes += write(io, string(p[1]))
        bytes += write(io, " ")
        bytes += write(io, string(p[2]))
        bytes += write(io, " ")
        bytes += write(io, string(p[3]))
        if i < length(polygon.exterior.points)
            bytes += write(io, ", ")
        end
    end
    bytes += write(io, ")")

    for ls in polygon.interiors
        bytes += write(io, ", (")
        @inbounds for i = 1:length(ls.points)
            p = ls.points[i]
            bytes += write(io, string(p[1]))
            bytes += write(io, " ")
            bytes += write(io, string(p[2]))
            bytes += write(io, " ")
            bytes += write(io, string(p[3]))
            if i < length(ls.points)
                bytes += write(io, ", ")
            end
        end
        bytes += write(io, ")")
    end
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, points::AbstractVector{<:StaticVector{2, <:Real}})
    if isempty(points)
        return write(io, "MULTIPOINT EMPTY")
    end

    bytes = 0
    bytes += write(io, "MULTIPOINT (")
    @inbounds for i in 1:length(points)
        p = points[i]
        bytes += write(io, "(")
        bytes += write(io, string(p[1]))
        bytes += write(io, " ")
        bytes += write(io, string(p[2]))
        bytes += write(io, ")")
        if i < length(points)
            bytes += write(io, ", ")
        end
    end
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, points::AbstractVector{<:StaticVector{3, <:Real}})
    if isempty(points)
        return write(io, "MULTIPOINT Z EMPTY")
    end

    bytes = 0
    bytes += write(io, "MULTIPOINT Z (")
    @inbounds for i in 1:length(points)
        p = points[i]
        bytes += write(io, "(")
        bytes += write(io, string(p[1]))
        bytes += write(io, " ")
        bytes += write(io, string(p[2]))
        bytes += write(io, " ")
        bytes += write(io, string(p[3]))
        bytes += write(io, ")")
        if i < length(points)
            bytes += write(io, ", ")
        end
    end
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, lines::AbstractVector{<:Line{2}})
    if isempty(lines)
        return write(io, "MULTILINESTRING EMPTY")
    end

    bytes = 0
    bytes += write(io, "MULTILINESTRING (") # There is no LINE type in WKT
    @inbounds for i in 1:length(lines)
        line = lines[i]
        bytes += write(io, "(")
        bytes += write(io, string(line.p1[1]))
        bytes += write(io, " ")
        bytes += write(io, string(line.p1[2]))
        bytes += write(io, ", ")
        bytes += write(io, string(line.p2[1]))
        bytes += write(io, " ")
        bytes += write(io, string(line.p2[2]))
        bytes += write(io, ")")

        if i < length(lines)
            bytes += write(io, ", ")
        end
    end
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, lines::AbstractVector{<:Line{3}})
    if isempty(lines)
        return write(io, "MULTILINESTRING Z EMPTY")
    end

    bytes = 0
    bytes += write(io, "MULTILINESTRING Z (") # There is no LINE type in WKT
    @inbounds for i in 1:length(lines)
        line = lines[i]
        bytes += write(io, "(")
        bytes += write(io, string(line.p1[1]))
        bytes += write(io, " ")
        bytes += write(io, string(line.p1[2]))
        bytes += write(io, " ")
        bytes += write(io, string(line.p1[3]))
        bytes += write(io, ", ")
        bytes += write(io, string(line.p2[1]))
        bytes += write(io, " ")
        bytes += write(io, string(line.p2[2]))
        bytes += write(io, " ")
        bytes += write(io, string(line.p2[3]))
        bytes += write(io, ")")

        if i < length(lines)
            bytes += write(io, ", ")
        end
    end
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, linestrings::AbstractVector{<:LineString{2}})
    if isempty(linestrings)
        return write(io, "MULTILINESTRING EMPTY")
    end

    bytes = 0
    bytes += write(io, "MULTILINESTRING (")
    @inbounds for i in 1:length(linestrings)
        ls = linestrings[i]
        if length(ls.points) < 2
            bytes += write(io, "EMPTY")
        else
            bytes += write(io, "(")
            for j in 1:length(ls.points)
                p = ls.points[j]
                bytes += write(io, string(p[1]))
                bytes += write(io, " ")
                bytes += write(io, string(p[2]))
                if j < length(ls.points)
                    bytes += write(io, ", ")
                end
            end
            bytes += write(io, ")")
        end
        if i < length(linestrings)
            bytes += write(io, ", ")
        end
    end
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, linestrings::AbstractVector{<:LineString{3}})
    if isempty(linestrings)
        return write(io, "MULTILINESTRING Z EMPTY")
    end

    bytes = 0
    bytes += write(io, "MULTILINESTRING Z (")
    @inbounds for i in 1:length(linestrings)
        ls = linestrings[i]
        if length(ls.points) < 2
            bytes += write(io, "EMPTY")
        else
            bytes += write(io, "(")
            for j in 1:length(ls.points)
                p = ls.points[j]
                bytes += write(io, string(p[1]))
                bytes += write(io, " ")
                bytes += write(io, string(p[2]))
                bytes += write(io, " ")
                bytes += write(io, string(p[3]))
                if j < length(ls.points)
                    bytes += write(io, ", ")
                end
            end
            bytes += write(io, ")")
        end
        if i < length(linestrings)
            bytes += write(io, ", ")
        end
    end
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, polygons::AbstractVector{<:Polygon{2}})
    if isempty(polygons)
        return write(io, "MULTIPOLYGON EMPTY")
    end

    bytes = 0
    bytes += write(io, "MULTIPOLYGON (")
    @inbounds for i in 1:length(polygons)
        polygon = polygons[i]
        if length(polygon.exterior.points) < 4
            bytes += write(io, "EMPTY")
        else
            bytes += write(io, "((")
            for j in 1:length(polygon.exterior.points)
                p = polygon.exterior.points[j]
                bytes += write(io, string(p[1]))
                bytes += write(io, " ")
                bytes += write(io, string(p[2]))
                if j < length(polygon.exterior.points)
                    bytes += write(io, ", ")
                end
            end
            bytes += write(io, ")")
            for ls in polygon.interiors
                bytes += write(io, ", (")
                for j in 1:length(ls.points)
                    p = ls.points[j]
                    bytes += write(io, string(p[1]))
                    bytes += write(io, " ")
                    bytes += write(io, string(p[2]))
                    if j < length(ls.points)
                        bytes += write(io, ", ")
                    end
                end
                bytes += write(io, ")")
            end
            bytes += write(io, ")")
        end
        if i < length(polygons)
            bytes += write(io, ", ")
        end
    end
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, polygons::AbstractVector{<:Polygon{3}})
    if isempty(polygons)
        return write(io, "MULTIPOLYGON Z EMPTY")
    end

    bytes = 0
    bytes += write(io, "MULTIPOLYGON Z (")
    @inbounds for i in 1:length(polygons)
        polygon = polygons[i]
        if length(polygon.exterior.points) < 4
            bytes += write(io, "EMPTY")
        else
            bytes += write(io, "((")
            for j in 1:length(polygon.exterior.points)
                p = polygon.exterior.points[j]
                bytes += write(io, string(p[1]))
                bytes += write(io, " ")
                bytes += write(io, string(p[2]))
                bytes += write(io, " ")
                bytes += write(io, string(p[3]))
                if j < length(polygon.exterior.points)
                    bytes += write(io, ", ")
                end
            end
            bytes += write(io, ")")
            for ls in polygon.interiors
                bytes += write(io, ", (")
                for j in 1:length(ls.points)
                    p = ls.points[j]
                    bytes += write(io, string(p[1]))
                    bytes += write(io, " ")
                    bytes += write(io, string(p[2]))
                    bytes += write(io, " ")
                    bytes += write(io, string(p[3]))
                    if j < length(ls.points)
                        bytes += write(io, ", ")
                    end
                end
                bytes += write(io, ")")
            end
            bytes += write(io, ")")
        end
        if i < length(polygons)
            bytes += write(io, ", ")
        end
    end
    bytes += write(io, ")")
    return bytes
end

function write_wkt(io::IO, geometries::AbstractVector)
    if isempty(geometries)
        return write(io, "GEOMETRYCOLLECTION EMPTY")
    end

    bytes = 0
    bytes += write(io, "GEOMETRYCOLLECTION (")
    for i in 1:length(geometries)
        bytes += write_wkt(io, geometries[i])
        if i < length(geometries)
            bytes += write(io, ", ")
        end
    end
    bytes += write(io, ")")
    return bytes
end

# Reading functions
const WKT_WHITESPACE = [' ' #= space =#, '\t' #= tab =#, '\n' #= newline =#, '\r' #= for Windows carriage returns =#]
const WKT_SPECIAL_CHARS = ['(', ')', ',', ';', '=']

"""
    tokenize_wkt(io)

Stream `io` and break it into potential WKT tokens, such as "POINT", "3.0", "(", ")", or ",".
Any whitespace is discarded.
"""
function tokenize_wkt(io::IO)
    out = String[]
    str = ""
    while !eof(io)
        c = read(io, Char) # UTF-8
        if isempty(str) 
            if c ∉ WKT_WHITESPACE
                if c ∈ WKT_SPECIAL_CHARS
                    push!(out, string(c))
                else
                    str = string(c)
                end
            end
        else
            if c ∈ WKT_WHITESPACE
                push!(out, str)
                str = ""
            elseif c ∈ WKT_SPECIAL_CHARS
                push!(out, str)
                push!(out, string(c))
                str = ""
            else
                str = string(str, c)
            end
        end
    end
    if str != ""
        push!(out, str)
    end
    return out
end

struct WKTParsingError <: Exception
    str::String
end

"""
    read_wkt(string::String)

Parse a well-known text `String` and return a geometry.
"""
function read_wkt(str::String; srid::RefValue{String} = Ref(""))
    read_wkt(IOBuffer(str); srid=srid)
end

"""
    read_wkt(io::IO)

Parse a well-known text from IO stream `io` and return a geometry.
"""
function read_wkt(io::IO; srid::RefValue{String} = Ref(""))
    tokens = tokenize_wkt(io)

    if isempty(tokens)
        throw(WKTParsingError("WKT is empty"))
    end
    
    i = 1
    if uppercase(tokens[1]) == "SRID"
        # Search for ";" and save SRID information
        srid_string = ""
        while i < length(tokens)
            i += 1
            if i == 2 && tokens[i] != "="
                throw(WKTParsingError("SRID field does not have ="))
            end
            if tokens[i] == ";"
                i += 1
                break
            elseif i > 2
                srid_string = string(srid_string, tokens[i])
            end
        end
        if isempty(srid_string)
            throw(WKTParsingError("SRID field is empty"))
        end
        srid[] = srid_string # Note that this has lost any whitespace...
        if i >= length(tokens)
            throw(WKTParsingError("SRID field does not terminate"))
        end
    end
    (geom, i) = parse_wkt(tokens, i)
    
    if i != length(tokens) + 1
        throw(WKTParsingError("WKT does not terminate when expected"))
    end
    return geom
end

function parse_wkt(tokens::AbstractVector{<:AbstractString}, i::Integer)
    if uppercase(tokens[i]) == "POINT"
        if length(tokens) > i && (tokens[i+1] == "(" || uppercase(tokens[i+1]) == "EMPTY")
            (geom, i) = parse_wkt(SVector{2, Float64}, tokens, i + 1)
        elseif length(tokens) > i+1 && uppercase(tokens[i+1]) == "Z" && (tokens[i+2] == "(" || uppercase(tokens[i+2]) == "EMPTY")
            (geom, i) = parse_wkt(SVector{3, Float64}, tokens, i + 2)
        elseif length(tokens) > i && (uppercase(tokens[i+1]) == "M" || tokens[i+1] == "ZM")
            throw(WKTParsingError("Error parsing POINT $(uppercase(tokens[i+1])) (Measures are not supported)")) 
        else
            throw(WKTParsingError("Error parsing POINT")) 
        end
    elseif uppercase(tokens[i]) == "LINESTRING"
        if length(tokens) > i && (tokens[i+1] == "(" || uppercase(tokens[i+1]) == "EMPTY")
            (geom, i) = parse_wkt(LineString{2, Float64}, tokens, i + 1)
        elseif length(tokens) > i+1 && uppercase(tokens[i+1]) == "Z" && (tokens[i+2] == "(" || uppercase(tokens[i+2]) == "EMPTY")
            (geom, i) = parse_wkt(LineString{3, Float64}, tokens, i + 2)
        elseif length(tokens) > i && (uppercase(tokens[i+1]) == "M" || tokens[i+1] == "ZM")
            throw(WKTParsingError("Error parsing LINESTRING $(uppercase(tokens[i+1])) (Measures are not supported)")) 
        else
            throw(WKTParsingError("Error parsing LINESTRING")) 
        end
    elseif uppercase(tokens[i]) == "POLYGON"
        if length(tokens) > i && (tokens[i+1] == "(" || uppercase(tokens[i+1]) == "EMPTY")
            (geom, i) = parse_wkt(Polygon{2, Float64}, tokens, i + 1)
        elseif length(tokens) > i+1 && uppercase(tokens[i+1]) == "Z" && (tokens[i+2] == "(" || uppercase(tokens[i+2]) == "EMPTY")
            (geom, i) = parse_wkt(Polygon{3, Float64}, tokens, i + 2)
        elseif length(tokens) > i && (uppercase(tokens[i+1]) == "M" || tokens[i+1] == "ZM")
            throw(WKTParsingError("Error parsing POLYGON $(uppercase(tokens[i+1])) (Measures are not supported)")) 
        else
            throw(WKTParsingError("Error parsing POLYGON")) 
        end
    elseif uppercase(tokens[i]) == "MULTIPOINT"
        if length(tokens) > i && (tokens[i+1] == "(" || uppercase(tokens[i+1]) == "EMPTY")
            (geom, i) = parse_wkt(Vector{SVector{2, Float64}}, tokens, i + 1)
        elseif length(tokens) > i+1 && uppercase(tokens[i+1]) == "Z" && (tokens[i+2] == "(" || uppercase(tokens[i+2]) == "EMPTY")
            (geom, i) = parse_wkt(Vector{SVector{3, Float64}}, tokens, i + 2)
        elseif length(tokens) > i && (uppercase(tokens[i+1]) == "M" || tokens[i+1] == "ZM")
            throw(WKTParsingError("Error parsing MULTIPOINT $(uppercase(tokens[i+1])) (Measures are not supported)")) 
        else
            throw(WKTParsingError("Error parsing MULTIPOINT")) 
        end
    elseif uppercase(tokens[i]) == "MULTILINESTRING"
        if length(tokens) > i && (tokens[i+1] == "(" || uppercase(tokens[i+1]) == "EMPTY")
            (geom, i) = parse_wkt(Vector{LineString{2, Float64}}, tokens, i + 1)
        elseif length(tokens) > i+1 && uppercase(tokens[i+1]) == "Z" && (tokens[i+2] == "(" || uppercase(tokens[i+2]) == "EMPTY")
            (geom, i) = parse_wkt(Vector{LineString{3, Float64}}, tokens, i + 2)
        elseif length(tokens) > i && (uppercase(tokens[i+1]) == "M" || tokens[i+1] == "ZM")
            throw(WKTParsingError("Error parsing MULTILINESTRING $(uppercase(tokens[i+1])) (Measures are not supported)")) 
        else
            throw(WKTParsingError("Error parsing MULTILINESTRING")) 
        end
    elseif uppercase(tokens[i]) == "MULTIPOLYGON"
        if length(tokens) > i && (tokens[i+1] == "(" || uppercase(tokens[i+1]) == "EMPTY")
            (geom, i) = parse_wkt(Vector{Polygon{2, Float64}}, tokens, i + 1)
        elseif length(tokens) > i+1 && uppercase(tokens[i+1]) == "Z" && (tokens[i+2] == "(" || uppercase(tokens[i+2]) == "EMPTY")
            (geom, i) = parse_wkt(Vector{Polygon{3, Float64}}, tokens, i + 2)
        elseif length(tokens) > i && (uppercase(tokens[i+1]) == "M" || tokens[i+1] == "ZM")
            throw(WKTParsingError("Error parsing MULTIPOLYGON $(uppercase(tokens[i+1])) (Measures are not supported)")) 
        else
            throw(WKTParsingError("Error parsing MULTIPOLYGON")) 
        end
    elseif uppercase(tokens[i]) == "GEOMETRYCOLLECTION"
        if length(tokens) > i && (tokens[i+1] == "(" || uppercase(tokens[i+1]) == "EMPTY")
            (geom, i) = parse_wkt(Vector{Any}, tokens, i + 1)
        else
            throw(WKTParsingError("Error parsing GEOMETRYCOLLECTION")) 
        end
    else
        throw(WKTParsingError("Found unknown geometry type $(tokens[i])"))
    end

    return (geom, i)
end

function parse_wkt(::Type{SVector{2,Float64}}, tokens::AbstractVector{<:AbstractString}, i::Integer)
    # Note that in many contexts, it is optional to surround point coordinates in brackets
    if tokens[i] == "("
        if length(tokens) < i+3 || tokens[i+3] != ")"
            throw(WKTParsingError("Error parsing POINT"))
        end

        x = parse(Float64, tokens[i+1])
        y = parse(Float64, tokens[i+2])
        return (SVector(x, y), i+4)
    elseif tokens[i] == "EMPTY"
        # Not sure what this should be? `SVector(NaN, NaN)`? Or `missing`?
        throw(WKTParsingError("POINT EMPTY is not supported"))
    else
        if length(tokens) < i+1
            throw(WKTParsingError("Error parsing POINT"))
        end

        x = parse(Float64, tokens[i])
        y = parse(Float64, tokens[i+1])
        return (SVector(x, y), i+2)
    end
end

function parse_wkt(::Type{SVector{3,Float64}}, tokens::AbstractVector{<:AbstractString}, i::Integer)
    # Note that in many contexts, it is optional to surround point coordinates in brackets
    if tokens[i] == "("
        if length(tokens) < i+4 || tokens[i+4] != ")"
            throw(WKTParsingError("Error parsing POINT Z"))
        end

        x = parse(Float64, tokens[i+1])
        y = parse(Float64, tokens[i+2])
        z = parse(Float64, tokens[i+3])
        return (SVector(x, y,z), i+5)
    elseif tokens[i] == "EMPTY"
        # Not sure what this should be? `SVector(NaN, NaN, Nan)`? Or `missing`?
        throw(WKTParsingError("POINT Z EMPTY is not supported"))
    else
        if length(tokens) < i+2
            throw(WKTParsingError("Error parsing POINT Z"))
        end

        x = parse(Float64, tokens[i])
        y = parse(Float64, tokens[i+1])
        z = parse(Float64, tokens[i+2])
        return (SVector(x, y), i+3)
    end
end

function parse_wkt(::Type{LineString{2,Float64}}, tokens::AbstractVector{<:AbstractString}, i::Integer)
    if tokens[i] == "EMPTY"
        return (LineString(SVector{2,Float64}[]), i+1)
    end
    if tokens[i] != "("
        throw(WKTParsingError("Error parsing LINESTRING"))
    end
    points = Vector{SVector{2, Float64}}()
    i += 1
    while length(tokens) >= i+2
        x = parse(Float64, tokens[i])
        y = parse(Float64, tokens[i+1])
        push!(points, SVector(x, y))

        if tokens[i+2] == ")"
            break
        elseif tokens[i+2] == ","
            i += 3
        else
            throw(WKTParsingError("Error parsing LINESTRING"))
        end
    end

    if tokens[i+2] != ")" || length(points) < 2
        throw(WKTParsingError("Error parsing LINESTRING"))
    end
    
    return (LineString(points), i+3)
end

function parse_wkt(::Type{LineString{3, Float64}}, tokens::AbstractVector{<:AbstractString}, i::Integer)
    if tokens[i] == "EMPTY"
        return (LineString(SVector{3,Float64}[]), i+1)
    end
    if tokens[i] != "("
        throw(WKTParsingError("Error parsing LINESTRING"))
    end
    points = Vector{SVector{3, Float64}}()
    i += 1
    while length(tokens) > i+2
        x = parse(Float64, tokens[i])
        y = parse(Float64, tokens[i+1])
        z = parse(Float64, tokens[i+2])
        push!(points, SVector(x, y, z))

        if tokens[i+3] == ")"
            break
        elseif tokens[i+3] == ","
            i += 4
        else
            throw(WKTParsingError("Error parsing LINESTRING"))
        end
    end

    if tokens[i+3] != ")" || length(points) < 2
        throw(WKTParsingError("Error parsing LINESTRING"))
    end
    
    return (LineString(points), i+4)
end

function parse_wkt(::Type{Polygon{2, Float64}}, tokens::AbstractVector{<:AbstractString}, i::Integer)
    if tokens[i] == "EMPTY"
        return (Polygon(SVector{2,Float64}[]), i+1)
    end
    if tokens[i] != "("
        throw(WKTParsingError("Error parsing POLYGON"))
    end
    interiors = Vector{LineString{2, Float64, Vector{SVector{2, Float64}}}}()
    n_linestrings = 0
    i += 1
    while i <= length(tokens)
        (ls, i) = parse_wkt(LineString{2,Float64}, tokens, i)
        if n_linestrings == 0
            exterior = ls
            n_linestrings += 1
        else
            push!(interiors, ls)
            n_linestrings += 1
        end

        if length(tokens) < i
            throw(WKTParsingError("Error parsing POLYGON"))
        end
        if tokens[i] == ")"
            return (Polygon(exterior, interiors), i+1)
        end
        if tokens[i] != ","
           throw(WKTParsingError("Error parsing POLYGON")) 
        end
        i += 1
    end
    throw(WKTParsingError("Error parsing POLYGON"))
end

function parse_wkt(::Type{Polygon{3, Float64}}, tokens::AbstractVector{<:AbstractString}, i::Integer)
    if tokens[i] == "EMPTY"
        return (Polygon(SVector{3,Float64}[]), i+1)
    end
    if tokens[i] != "("
        throw(WKTParsingError("Error parsing POLYGON Z"))
    end
    interiors = Vector{LineString{3, Float64, Vector{SVector{3, Float64}}}}()
    n_linestrings = 0
    i += 1
    while i <= length(tokens)
        (ls, i) = parse_wkt(LineString{3,Float64}, tokens, i)
        if n_linestrings == 0
            exterior = ls
            n_linestrings += 1
        else
            push!(interiors, ls)
            n_linestrings += 1
        end

        if length(tokens) < i
            throw(WKTParsingError("Error parsing POLYGON Z"))
        end
        if tokens[i] == ")"
            return (Polygon(exterior, interiors), i+1)
        end
        if tokens[i] != ","
           throw(WKTParsingError("Error parsing POLYGON Z")) 
        end
        i += 1
    end
    throw(WKTParsingError("Error parsing POLYGON Z"))
end

function parse_wkt(::Type{Vector{SVector{2, Float64}}}, tokens::AbstractVector{<:AbstractString}, i::Integer)
    if tokens[i] == "EMPTY"
        return (SVector{2,Float64}[], i+1)
    end
    if tokens[i] != "("
        throw(WKTParsingError("Error parsing MULTIPOINT"))
    end
    points = Vector{SVector{2, Float64}}()
    i += 1
    while i <= length(tokens)
        (point, i) = parse_wkt(SVector{2,Float64}, tokens, i)
        push!(points, point)

        if length(tokens) < i
            throw(WKTParsingError("Error parsing MULTIPOINT"))
        end
        if tokens[i] == ")"
            return (points, i+1)
        end
        if tokens[i] != ","
           throw(WKTParsingError("Error parsing MULTIPOINT")) 
        end
        i += 1
    end
    throw(WKTParsingError("Error parsing MULTIPOINT"))
end

function parse_wkt(::Type{Vector{SVector{3, Float64}}}, tokens::AbstractVector{<:AbstractString}, i::Integer)
    if tokens[i] == "EMPTY"
        return (SVector{3,Float64}[], i+1)
    end
    if tokens[i] != "("
        throw(WKTParsingError("Error parsing MULTIPOINT Z"))
    end
    points = Vector{SVector{3, Float64}}()
    i += 1
    while i <= length(tokens)
        (point, i) = parse_wkt(SVector{3,Float64}, tokens, i)
        push!(points, point)

        if length(tokens) < i
            throw(WKTParsingError("Error parsing MULTIPOINT Z"))
        end
        if tokens[i] == ")"
            return (points, i+1)
        end
        if tokens[i] != ","
           throw(WKTParsingError("Error parsing MULTIPOINT Z")) 
        end
        i += 1
    end
    throw(WKTParsingError("Error parsing MULTIPOINT Z"))
end

function parse_wkt(::Type{Vector{LineString{2, Float64}}}, tokens::AbstractVector{<:AbstractString}, i::Integer)
    if tokens[i] == "EMPTY"
        return (LineString{2,Float64,Vector{SVector{2,Float64}}}[], i+1)
    end
    if tokens[i] != "("
        throw(WKTParsingError("Error parsing MULTILINESTRING"))
    end
    linestrings = Vector{LineString{2, Float64, Vector{SVector{2, Float64}}}}()
    i += 1
    while i <= length(tokens)
        (ls, i) = parse_wkt(LineString{2,Float64}, tokens, i)
        push!(linestrings, ls)

        if length(tokens) < i
            throw(WKTParsingError("Error parsing MULTILINESTRING"))
        end
        if tokens[i] == ")"
            return (linestrings, i+1)
        end
        if tokens[i] != ","
           throw(WKTParsingError("Error parsing MULTILINESTRING")) 
        end
        i += 1
    end
    throw(WKTParsingError("Error parsing MULTILINESTRING"))
end

function parse_wkt(::Type{Vector{LineString{3, Float64}}}, tokens::AbstractVector{<:AbstractString}, i::Integer)
    if tokens[i] == "EMPTY"
        return (LineString{3,Float64,Vector{SVector{3,Float64}}}[], i+1)
    end
    if tokens[i] != "("
        throw(WKTParsingError("Error parsing MULTILINESTRING Z"))
    end
    linestrings = Vector{LineString{3, Float64, Vector{SVector{3, Float64}}}}()
    i += 1
    while i <= length(tokens)
        (ls, i) = parse_wkt(LineString{3,Float64}, tokens, i)
        push!(linestrings, ls)

        if length(tokens) < i
            throw(WKTParsingError("Error parsing MULTILINESTRING Z"))
        end
        if tokens[i] == ")"
            return (linestrings, i+1)
        end
        if tokens[i] != ","
           throw(WKTParsingError("Error parsing MULTILINESTRING Z")) 
        end
        i += 1
    end
    throw(WKTParsingError("Error parsing MULTILINESTRING Z"))
end

function parse_wkt(::Type{Vector{Polygon{2, Float64}}}, tokens::AbstractVector{<:AbstractString}, i::Integer)
    if tokens[i] == "EMPTY"
        return (Polygon{2,Float64,LineString{2,Float64,Vector{SVector{2,Float64}}},Vector{LineString{2,Float64,Vector{SVector{2,Float64}}}}}[], i+1)
    end
    if tokens[i] != "("
        throw(WKTParsingError("Error parsing MULTIPOLYGON"))
    end
    polygons = Vector{Polygon{2,Float64,LineString{2,Float64,Vector{SVector{2,Float64}}},Vector{LineString{2,Float64,Vector{SVector{2,Float64}}}}}}()
    i += 1
    while i <= length(tokens)
        (polygon, i) = parse_wkt(Polygon{2,Float64}, tokens, i)
        push!(polygons, polygon)

        if length(tokens) < i
            throw(WKTParsingError("Error parsing MULTIPOLYGON"))
        end
        if tokens[i] == ")"
            return (polygons, i+1)
        end
        if tokens[i] != ","
           throw(WKTParsingError("Error parsing MULTIPOLYGON")) 
        end
        i += 1
    end
    throw(WKTParsingError("Error parsing MULTIPOLYGON"))
end

function parse_wkt(::Type{Vector{Polygon{3, Float64}}}, tokens::AbstractVector{<:AbstractString}, i::Integer)
    if tokens[i] == "EMPTY"
        return (Polygon{3,Float64,LineString{3,Float64,Vector{SVector{3,Float64}}},Vector{LineString{3,Float64,Vector{SVector{3,Float64}}}}}[], i+1)
    end
    if tokens[i] != "("
        throw(WKTParsingError("Error parsing MULTIPOLYGON Z"))
    end
    polygons = Vector{Polygon{3,Float64,LineString{3,Float64,Vector{SVector{3,Float64}}},Vector{LineString{3,Float64,Vector{SVector{3,Float64}}}}}}()
    i += 1
    while i <= length(tokens)
        (polygon, i) = parse_wkt(Polygon{3,Float64}, tokens, i)
        push!(polygons, polygon)

        if length(tokens) < i
            throw(WKTParsingError("Error parsing MULTIPOLYGON Z"))
        end
        if tokens[i] == ")"
            return (polygons, i+1)
        end
        if tokens[i] != ","
           throw(WKTParsingError("Error parsing MULTIPOLYGON Z")) 
        end
        i += 1
    end
    throw(WKTParsingError("Error parsing MULTIPOLYGON Z"))
end

function parse_wkt(::Type{Vector{Any}}, tokens::AbstractVector{<:AbstractString}, i::Integer)
    if tokens[i] == "EMPTY"
        return (Any[], i+1)
    end
    if tokens[i] != "("
        throw(WKTParsingError("Error parsing GEOMETRYCOLLECTION"))
    end
    geometries = Vector{Any}()
    i += 1
    while i <= length(tokens)
        (geometry, i) = parse_wkt(tokens, i)
        push!(geometries, geometry)

        if length(tokens) < i
            throw(WKTParsingError("Error parsing GEOMETRYCOLLECTION"))
        end
        if tokens[i] == ")"
            return (geometries, i+1)
        end
        if tokens[i] != ","
           throw(WKTParsingError("Error parsing GEOMETRYCOLLECTION")) 
        end
        i += 1
    end
    throw(WKTParsingError("Error parsing GEOMETRYCOLLECTION"))
end