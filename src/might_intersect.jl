"""
    might_intersect(bb, region)

Returns true if the bounding box bb *might* intersect the region, otherwise returns
false.  To be used as an optimisation to exclude a bounding box before testing
points within the bounding box.
"""
@inline might_intersect(r1::AbstractRegion, r2::AbstractRegion) = intersects(boundingbox(r1), r2)
@inline might_intersect(bb1::BoundingBox, r2::AbstractRegion) = intersects(bb1, boundingbox(r2))
@inline might_intersect(bb::BoundingBox, region::Circle) = _might_intersect_circle(bb, region)
@inline might_intersect(bb::BoundingBox, region::Cylinder) = _might_intersect_circle(bb, region)
@inline might_intersect(bb::BoundingBox, region::Sphere) = _might_intersect_circle(bb, region)

function _might_intersect_circle(bb, circle)
    if !intersects(bb, boundingbox(circle))
        return false
    end
    # Fit a circle and find the y distance from center
    if circle.y > bb.ymax
        dy = circle.y - bb.ymax
    elseif circle.y >= bb.ymin
        dy = zero(promote_type(eltype(eltype(bb)), eltype(eltype(circle))))
    else
        dy = bb.ymin - circle.y
    end

    # Fit a circle and find the x range to query, if any
    if circle.x > bb.xmax
        dx = circle.x - bb.xmax
    elseif circle.x >= bb.xmin
        dx = zero(promote_type(eltype(eltype(bb)), eltype(eltype(circle))))
    else
        dx = bb.xmin - circle.x
    end

    h² = dx * dx + dy * dy
    r² = circle.radius * circle.radius

    return h² <= r²
end

