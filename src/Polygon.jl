struct Polygon{N, T <: Real, L <: LineString{N, T}, V <: AbstractVector{L}} <: AbstractRegion{T}
    exterior::L
    interiors::V
end

if VERSION < v"0.7"
    function Polygon(exterior::L, interiors::AbstractVector{L}) where {N, T, L <: LineString{N, T}}
        Polygon{N, T, L, typeof(interiors)}(exterior, interiors)
    end
end
function Polygon{N}(exterior::L, interiors::AbstractVector{L}) where {N, T, L <: LineString{N, T}}
    Polygon{N, T, L, typeof(interiors)}(exterior, interiors)
end
function Polygon{N,T}(exterior::L, interiors::AbstractVector{L}) where {N, T, L <: LineString{N, T}}
    Polygon{N, T, L, typeof(interiors)}(exterior, interiors)
end

Polygon(points::StaticVector{N,T}...) where {N, T<:Real} = Polygon(collect(points))
Polygon(points::AbstractVector{<:StaticVector{N,T}}) where {N,T<:Real} = Polygon{N}(LineString{N}(points))
Polygon{N}(points::AbstractVector{T}...) where {N, T<:Real} = Polygon{N}(collect(points))
Polygon{N}(points::AbstractVector{<:AbstractVector{T}}) where {N, T<:Real} = Polygon{N,T}(LineString{N,T}(points))
Polygon{N,T}(points::AbstractVector{<:Real}...) where {N, T<:Real} = Polygon{N,T}(collect(points))
Polygon{N,T}(points::AbstractVector{<:AbstractVector{<:Real}}) where {N, T<:Real} = Polygon{N,T}(LineString{N,T}(points))

Polygon(ls::LineString) = Polygon(ls, Vector{typeof(ls)}())
Polygon{N}(ls::LineString{N}) where {N} = Polygon{N}(ls, Vector{typeof(ls)}())
Polygon{N,T}(ls::LineString{N,T}) where {N,T<:Real} = Polygon{N,T}(ls, Vector{typeof(ls)}())

convert2d(p::Polygon{2}) = p
convert2d(p::Polygon{3}) = Polygon(convert2d(p.exterior), convert2d.(p.interiors))
convert3d(p::Polygon{2}) = Polygon(convert3d(p.exterior), convert3d.(p.interiors))
convert3d(p::Polygon{2}, z::Real) = Polygon(convert3d(p.exterior, z), convert3d.(p.interiors, z))
convert3d(p::Polygon{3}) = p
convert3d(p::Polygon{3}, z::Real) = Polygon(convert3d(p.exterior, z), convert3d.(p.interiors, z))

# Note: This doesn't compare the ordering of points
function Base.:(==)(p1::Polygon{N}, p2::Polygon{N}) where N
    p1.exterior == p2.exterior && p1.interiors == p2.interiors
end

function Base.isequal(p1::Polygon{N}, p2::Polygon{N}) where N
    isequal(p1.exterior, p2.exterior) && isequal(p1.interiors, p2.interiors)
end

function Base.hash(p::Polygon, h::UInt)
    hash(p.exterior, hash(p.interiors, hash(UInt === UInt64 ? 0xde95b490c51c55a5 : 0x0f7345a4, h)))
end

function show(io::IO, polygon::Polygon{N}) where N
    print(io, "Polygon{$N}([")
    for i in 1:length(polygon.exterior.points)
        print(io, polygon.exterior.points[i])
        if i < length(polygon.exterior.points)
            print(io, ", ")
        end
    end
    print(io, "]")
    for ls in polygon.interiors
    	print(io, ", [")
    	for i in 1:length(ls.points)
	        print(io, ls.points[i])
	        if i < length(ls.points)
	            print(io, ", ")
	        end
	    end
    	print(io, "]")
    end
    print(io, ")")
end

function lines(p::Polygon)
    out = lines(p.exterior)
    for ls in p.interiors
        append!(out, lines(ls))
    end
    return out
end

function area(p::Polygon{2, T}) where {T}
    return area(p.exterior) + mapreduce(area, +, p.interiors; init = zero(T))
end

function in(p::StaticVector{2, <:Real}, polygon::Polygon{2})
    # Winding number algorith, for example read
    # http://geomalgorithms.com/a03-_inclusion.html

    # Count number of times an edge of the polygon crosses a ray from
    # p to infinity (doesn't matter which direction but we choose +x direction)
    wn = winding_number(p, polygon.exterior)
    for linestring in polygon.interiors
        wn += winding_number(p, linestring)
    end

    return wn != 0 # Valid polygons can be oriented clockwise or anticlockwise
end

intersects(p::StaticVector{2, <:Real}, polygon::Polygon{2}) = p ∈ polygon
intersects(polygon::Polygon{2}, p::StaticVector{2, <:Real}) = p ∈ polygon

function intersects(l::Line{2}, polygon::Polygon{2})
    # The polygon is a surface. Either `l` intersects the edge of
    # the polygon or it is entirely *inside* the polygon (or else it
    # doesn't intersect at all)
    if intersects(l, polygon.exterior)
        return true
    end

    for linestring in polygon.interiors
        if intersects(l, linestring)
            return true
        end
    end

    # Either both endpoints are inside, or outside, so just test one
    return l.p1 ∈ polygon
end
intersects(polygon::Polygon{2}, l::Line{2}) = intersects(l, polygon)

function intersects(ls::LineString{2}, polygon::Polygon{2})
    # The polygon is a surface. Either `ls` intersects the edge of
    # the polygon, or it is entirely *inside* the polygon (or else it
    # doesn't intersect at all)
    if intersects(ls, polygon.exterior)
        return true
    end

    for linestring in polygon.interiors
        if intersects(ls, linestring)
            return true
        end
    end

    for p in ls.points
        if p ∉ polygon
            return false
        end
    end

    # `ls` must be entirely inside `polygon`
    return true
end
intersects(polygon::Polygon{2}, ls::LineString{2}) = intersects(ls, polygon)

function intersects(p1::Polygon{2}, p2::Polygon{2})
    # If any line (interior OR exterior) intersects with any other line,
    # then the two polygons intersect. If not, check if one polygon
    # is entirely inside the other
    
    # Check if edges intersect
    if intersects(p1.exterior, p2)
        return true
    end

    for linestring in p1.interiors
        if intersects(linestring, p2)
            return true
        end
    end

    # One polygon might be entirely inside another
    # Since there can't be multple "onion" rings in any
    # polygon (it can have holes but is otherwise contiguous)
    # we only need to check the exteriors
    if all(p -> p in p2, p1.exterior.points)
        return true
    end
    if all(p -> p in p1, p2.exterior.points)
        return true
    end

    # Or else they do not intersect
    return false
end