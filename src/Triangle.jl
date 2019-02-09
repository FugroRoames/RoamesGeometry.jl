"""
    Triangle(a, b, c)

Create a `Triangle` that can be used for spatial lookup.

`a`, `b`, and `c` are the points of the triangle on the x/y plane.

See also `AbstractRegion`
"""
struct Triangle{T <: Real} <: AbstractRegion{T}
    a::SVector{2,T}
    b::SVector{2,T}
    c::SVector{2,T}
end

@inline function Triangle(a::AbstractVector{<:Real}, b::AbstractVector{<:Real}, c::AbstractVector{<:Real})
    T = promote_type(eltype(a), eltype(b), eltype(c))
    Triangle(convert(SVector{2,T}, a), convert(SVector{2,T}, b), convert(SVector{2,T}, c))
end

"""
    area(triangle::Triangle)

Returns the area of the `triangle`.
"""
@inline function area(t::Triangle{T}) where {T}
    # Should possibly use same convention as LineString and Polygon, and return negative area for counter-clockwise triangles
    convert(T, 0.5) * abs((t.b - t.a) × (t.c - t.a))
end

function boundingbox(t::Triangle{T}) where T
    points = [t.a, t.b, t.c]

    xmin, xmax = extrema(map(x -> x[1], points))
    ymin, ymax = extrema(map(x -> x[2], points))
    zmin, zmax = typemin(T), typemax(T)
    return BoundingBox{T}(xmin, ymin, zmin, xmax, ymax, zmax)
end

function in(p::StaticVector{3,T}, t::Triangle) where T <: Real
    a, b, c = t.a, t.b, t.c
    p2d = p[1:2]

    areaABC = cross(b - a, c - a)

    areaPBC = cross(b - p2d, c - p2d)
    areaPCA = cross(c - p2d, a - p2d)
    areaPAB = cross(a - p2d, b - p2d)

    u = areaPBC / areaABC
    v = areaPCA / areaABC
    w = areaPAB / areaABC

    return (u + v + w) ≈ 1.0 && u > 0 && v > 0 && w > 0 && u < 1 && v < 1 && w < 1
end

