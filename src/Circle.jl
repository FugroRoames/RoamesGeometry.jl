
"""
Search.Circle(x, y, radius)

Create a `Search.Circle` that can be used for spatial lookup.

See also `AbstractRegion`
"""
struct Circle{T <: Real} <: AbstractRegion{T}
    x::T
    y::T
    radius::T
end

"""
    area(circle)

Returns the area of the `circle`.
"""
@inline area(t::Circle) = π * t.radius * t.radius

function boundingbox(c::Circle{T}) where T
    xmin, xmax = c.x - c.radius, c.x + c.radius
    ymin, ymax = c.y - c.radius, c.y + c.radius
    zmin, zmax = typemin(T), typemax(T)
    return BoundingBox{T}(xmin, ymin, zmin, xmax, ymax, zmax)
end

function in(p::StaticVector{3,T}, region::Region) where T <: Real where Region <: Circle
    r² = region.radius * region.radius
    Δx = p[1] - region.x
    Δy = p[2] - region.y
    return Δx*Δx + Δy*Δy <= r²
end

