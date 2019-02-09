"""
    TriangularPrism(a, b, c, n, height, offset)
    TriangularPrism(a, b, c, height, offset = 0)

Create a `TriangularPrism` that can be used for spatial lookup.

`a`, `b`, and `c` are the points of the triangle, `n` if provided is the normal
for the plane defined by `a`, `b`, and `c`.

The `height` is along the normal of the plane defined by the points of the triangle.
`offset` is a distance along the negative of the normal to `offset` the `height`.

For example, a prism with `height` 1 and `offset` 0 extends from the plane a
distance of 1 along the normal.  A prism with `height` 1 and `offset` 0.5 extends
from a plane 0.5 along the negative of the normal and a distance of 1 along
the normal, in essence centering the volume for the prism evenly on both sides
of the plane defined by the three points of the triangle.

See also `AbstractRegion`
"""
struct TriangularPrism{T <: Real} <: AbstractRegion{T}
    a::SVector{3,T}
    b::SVector{3,T}
    c::SVector{3,T}
    n::SVector{3,T}
    height::T
    offset::T
end

@inline function TriangularPrism(a::StaticVector{3,T}, b::StaticVector{3,T}, c::StaticVector{3,T}, height::T, offset::T = 0.0) where T <: Real
    v1 = b - a
    v2 = c - a
    n = cross(v1, v2)
    n = n / norm(n)

    return TriangularPrism{T}(a, b, c, n, height, offset)
end

"""
    volume(prism::TriangularPrism)

Returns the volume of the `prism`.
"""
@inline volume(t::TriangularPrism) = t.height * dot(t.n, cross(t.b - t.a, t.c - t.a)) / 2.0

function boundingbox(t::TriangularPrism{T}) where T
    points = vcat(
        map(x -> x - t.offset * t.n, [t.a, t.b, t.c]),
        map(x -> x + (t.height - t.offset) * t.n, [t.a, t.b, t.c])
    )

    xmin, xmax = extrema(map(x -> x[1], points))
    ymin, ymax = extrema(map(x -> x[2], points))
    zmin, zmax = extrema(map(x -> x[3], points))
    return BoundingBox{T}(xmin, ymin, zmin, xmax, ymax, zmax)
end

function Base.in(p::StaticVector{3,T}, t::Region) where T <: Real where Region <: TriangularPrism
    a, b, c, n, h = t.a, t.b, t.c, t.n, t.height

    distance  = dot(n, p - a)

    if distance < -t.offset || distance > (t.height - t.offset)
        return false
    end

    # project p to the plane
    p = p - t.n * distance

    # determine if the point is in the triangle when projected to the plane
    # using barycentric coordinates http://mathworld.wolfram.com/BarycentricCoordinates.html

    areaABC = dot(n, cross(b - a, c - a))

    areaPBC = dot(n, cross(b - p, c - p))
    areaPCA = dot(n, cross(c - p, a - p))
    areaPAB = dot(n, cross(a - p, b - p))

    u = areaPBC / areaABC
    v = areaPCA / areaABC
    w = areaPAB / areaABC

    return (u + v + w) ≈ 1.0 && u > 0 && v > 0 && w > 0 && u < 1 && v < 1 && w < 1
end

