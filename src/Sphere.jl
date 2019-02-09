"""
    Search.Sphere(x, y, z, radius)
    Search.Sphere(center, radius)

Create a `Search.Sphere` that can be used for spatial lookup.

See also `AbstractRegion`
"""
struct Sphere{T <: Real} <: AbstractRegion{T}
    x::T
    y::T
    z::T
    radius::T
end

@inline function Sphere(center::AbstractVector{T}, radius::Number) where {T}
    @assert length(center) == 3
    @inbounds return Sphere{T}(center[1], center[2], center[3], radius)
end

function boundingbox(region::Sphere{T}) where T
    xmin = region.x - region.radius
    xmax = region.x + region.radius
    ymin = region.y - region.radius
    ymax = region.y + region.radius
    zmin = region.z - region.radius
    zmax = region.z + region.radius

    return BoundingBox{T}(xmin, ymin, zmin, xmax, ymax, zmax)
end

@inline function in(p::StaticVector{3, <:Real}, sphere::Sphere)
    diff = p - SVector(sphere.x, sphere.y, sphere.z)
    r² = sphere.radius * sphere.radius
    return dot(diff, diff) <= r²
end

@inline function volume(s::Sphere{T}) where T
     (convert(T, 4) / convert(T, 3)) * pi * s.radius * s.radius
end