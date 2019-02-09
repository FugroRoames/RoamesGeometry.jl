"""
    Cylinder(x, y, zmin, zmax, radius)

Create a `Cylinder` that can be used for spatial lookup.

See also `AbstractRegion`
"""
struct Cylinder{T <: Real} <: AbstractRegion{T}
    x::T
    y::T
    zmin::T
    zmax::T
    radius::T
end

"""
    volume(cylinder::Cylinder)

Returns the volume of the `cylinder`.
"""
@inline function volume(cylinder::Cylinder)
    π * cylinder.radius * cylinder.radius * (cylinder.zmax - cylinder.zmin)
end

function boundingbox(cylinder::Cylinder{T}) where T
    xmin = cylinder.x - cylinder.radius
    xmax = cylinder.x + cylinder.radius
    ymin = cylinder.y - cylinder.radius
    ymax = cylinder.y + cylinder.radius
    return BoundingBox{T}(xmin, ymin, cylinder.zmin, xmax, ymax, cylinder.zmax)
end

function in(p::StaticVector{3, <:Real}, cylinder::Cylinder)
    r² = cylinder.radius * cylinder.radius
    Δx = p[1] - cylinder.x
    Δy = p[2] - cylinder.y
    return Δx*Δx + Δy*Δy <= r² && p[3] >= cylinder.zmin && p[3] <= cylinder.zmax
end