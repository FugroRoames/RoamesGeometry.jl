"""
    (dist, r, z, d) = powerline_distances(catenary, point, [swing = 0])
    (dist, r, z, d) = powerline_distances(point, catenary, [swing = 0])

Distance between the given point and the closest point on the specified catenary. If
`swing` is specified, it returns the distance of closest approach as the catenary is swung
across an arc of `±swing` from vertical. The `swing` angle is specified in radians.

 * `dist` is 3D distance to closest point on catenary
 * `r` is a horizontal coordinate (positive or negative) transverse to the catenary
 * `z` is the vertical distance from the point on the catenary at given `d` (or nearest end)
 * `d` is a horizontal coordiante longitudanal to the catenary.
"""
function powerline_distances(cat::Catenary, p::AbstractVector{T}, swing = zero(T)) where {T <: Real}
    if length(p) !== 3
        error("Expected 3d point")
    end
    if swing != 0
        error("Swing is not implemented yet")
    end

    inv_a = inv(cat.a)

    # Point transformed into the frame of the catenary
    p_trans = cat.transform(p)

    # The beginning and end of the catenary
    p_begin = SVector(cat.lmin, 0, cat.a * (cosh(cat.lmin * inv_a) - 1))
    p_end = SVector(cat.lmax, 0, cat.a * (cosh(cat.lmax * inv_a) - 1))

    # Find coordinates relative to line
    @inbounds d = p_trans[1]
    @inbounds r = p_trans[2]
    @inbounds z = p_trans[3] - cat.a * (cosh(d * inv_a) - 1)

    # Determine whether we are closest in 3D to one of the ends, or the body of the catenary
    @inbounds if d > (p_end[3] - p_trans[3]) * sinh(cat.lmax * inv_a) + cat.lmax
        dist = norm(p_trans - p_end)
    elseif d < (p_begin[3] - p_trans[3]) * sinh(cat.lmin * inv_a) + cat.lmin
        dist = norm(p_trans - p_begin)
    else
        # With a local gradient approximation, find the distance to the closest point on the
        # line in the d-z plane. Effectively performs the first Newton-Raphson step.
        sinh_d_a = sinh(d * inv_a)
        d_perp = d + z * sinh_d_a / (1 + sinh_d_a*sinh_d_a)
        Δz = p_trans[3] - cat.a * (cosh(d_perp * inv_a) - 1) # recalculating z at new d helps accuracy signficantly
        Δd = d_perp - p_trans[1]

        dist = sqrt(r*r + Δz*Δz + Δd*Δd)
    end

    # output z depends on whether outside catenary region or not
    @inbounds if d > p_end[1] # beyond end
        z = p_trans[3] - p_end[3]
    elseif d < p_begin[1] # beyond begin
        z = p_trans[3] - p_begin[3]
    end

    return (dist, r, z, d)
end


powerline_distances(p::AbstractVector{<:Real}, cat::Catenary) = powerline_distances(cat, p)

"""
    p = closest_point(geom1, geom2)

Return the point on `geom1` closest to `geom2`.
"""
closest_point(a, b) = closest_points(a, b)[1]

"""
    (p1, p2) = closest_points(geom1, geom2)

Return the two closest points between two geometries.
"""
closest_points(p1::AbstractVector{<:Real}, p2::AbstractVector{<:Real}) = (p1, p2)

function closest_points(line::Line, p::AbstractVector{T}) where {T <: Real}
    d = line.p2 - line.p1
    sd = sum(abs2, d)
    closest = sd > 0 ? line.p1 + d * clamp(dot(p - line.p1, d) / sd, zero(T), one(T)) : line.p1
    return (closest, p)
end
closest_points(p::AbstractVector{<:Real}, line::Line) = reverse(closest_points(line, p))

function closest_points(l1::Line{2}, l2::Line{2})
    # Parameterize each line as pi + ti*di
    p1 = l1.p1
    p2 = l2.p1
    d1 = l1.p2 - l1.p1
    d2 = l2.p2 - l2.p1

    denom = d1 × d2 # 2D cross product from StaticArrays - returns scalar

    # Check that denominator is reasonable - otherwise assume parallel lines
    if abs(denom) > 10*eps(norm(d1)*norm(d2))
        r = p1 - p2
        t1 = (d2 × r) / denom
        t2 = (d1 × r) / denom

        # The segments cross iff the ti are in 0..1
        if t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1
            return (p1 + t1*d1, p2 + t2*d2)
        end
    end

    # Otherwise, one of the end points is closest - but there is no hint as to which
    (out1, out2) = closest_points(l1.p1, l2)
    dist = distance(out1, out2)

    (tmp1, tmp2) = closest_points(l1.p2, l2)
    dist_tmp = distance(tmp1, tmp2)
    if dist_tmp < dist
        dist = dist_tmp
        out1 = tmp1
        out2 = tmp2
    end

    (tmp1, tmp2) = closest_points(l1, l2.p1)
    dist_tmp = distance(tmp1, tmp2)
    if dist_tmp < dist
        dist = dist_tmp
        out1 = tmp1
        out2 = tmp2
    end

    (tmp1, tmp2) = closest_points(l1, l2.p2)
    dist_tmp = distance(tmp1, tmp2)
    if dist_tmp < dist
        dist = dist_tmp
        out1 = tmp1
        out2 = tmp2
    end

    return (out1, out2)
end

function closest_points(l1::Line{3}, l2::Line{3})
    # Parameterize each line as pi + ti*di
    p1 = l1.p1
    p2 = l2.p1
    d1 = l1.p2 - l1.p1
    d2 = l2.p2 - l2.p1

    denom = d1 × d2 # 2D cross product from StaticArrays - returns scalar

    # The line connecting points of closest approach is perendicular to both d1 and d2
    n = d1 × d2

    # Check that the cross product is reasonable - otherwise assume parallel lines
    if norm(n) > 10*eps(norm(d1)*norm(d2))
        r = p1 - p2
        t1 = -(d2 ⋅ (n × r)) / (d2 ⋅ (n × d1))
        t2 =  (d1 ⋅ (n × r)) / (d1 ⋅ (n × d2))

        # The segments reach closest approach (of infinite lines) iff the ti are in 0..1
        if t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1
            return (p1 + t1*d1, p2 + t2*d2)
        end
    end

    # Otherwise, one of the end points is closest - but there is no hint as to which
    (out1, out2) = closest_points(l1.p1, l2)
    dist = distance(out1, out2)

    (tmp1, tmp2) = closest_points(l1.p2, l2)
    dist_tmp = distance(tmp1, tmp2)
    if dist_tmp < dist
        dist = dist_tmp
        out1 = tmp1
        out2 = tmp2
    end

    (tmp1, tmp2) = closest_points(l1, l2.p1)
    dist_tmp = distance(tmp1, tmp2)
    if dist_tmp < dist
        dist = dist_tmp
        out1 = tmp1
        out2 = tmp2
    end

    (tmp1, tmp2) = closest_points(l1, l2.p2)
    dist_tmp = distance(tmp1, tmp2)
    if dist_tmp < dist
        dist = dist_tmp
        out1 = tmp1
        out2 = tmp2
    end

    return (out1, out2)
end

"""
    distance(geom1, geom2)

Calculate the minimum Euclidean distance between two geometries.
"""
@inline distance(p1::AbstractVector{<:Real}, p2::AbstractVector{<:Real}) = norm(p1 - p2)

@inline function distance(p1::StaticVector{n, <:Real}, p2::StaticVector{n, <:Real}) where {n}
    norm(p1 - p2)
end
@inline function distance(p1::StaticVector{2, <:Real}, p2::StaticVector{3, <:Real})
    norm(p1 - convert2d(p2))
end
@inline function distance(p1::StaticVector{3, <:Real}, p2::StaticVector{2, <:Real})
    norm(convert2d(p1) - p2)
end

# Distance between a point and the closest point on a Line
function distance(line::Line, p::AbstractVector{<:Real})
    return distance(p, closest_point(line, p))
end
distance(line::Line{2}, p::StaticVector{3, <:Real}) = distance(line, convert2d(p))
distance(line::Line{3}, p::StaticVector{2, <:Real}) = distance(convert2d(line), p)
distance(p::AbstractVector{<:Real}, line::Line) = distance(line, p)

# Shortest distance between two Lines
function distance(l1::Line{2}, l2::Line{2})
    # Parameterize each line as pi + ti*di
    p1 = l1.p1
    p2 = l2.p1
    d1 = l1.p2 - l1.p1
    d2 = l2.p2 - l2.p1

    denom = d1 × d2 # 2D cross product from StaticArrays - returns scalar

    # Check that denominator is reasonable - otherwise assume parallel lines
    if abs(denom) > 10*eps(norm(d1)*norm(d2))
        r = p1 - p2
        t1 = (d2 × r) / denom
        t2 = (d1 × r) / denom

        # The segments cross iff the ti are in 0..1
        if t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1
            return zero(t1)
        end
    end

    # Otherwise, one of the end points is closest - but there is no hint as to which
    dist = distance(l1.p1, l2)
    dist = min(dist, distance(l1.p2, l2))
    dist = min(dist, distance(l1, l2.p1))
    dist = min(dist, distance(l1, l2.p2))

    return dist
end

function distance(l1::Line{3}, l2::Line{3})
    # Parameterize each line as pi + ti*di
    p1 = l1.p1
    p2 = l2.p1
    d1 = l1.p2 - l1.p1
    d2 = l2.p2 - l2.p1

    # The line connecting points of closest approach is perendicular to both d1 and d2
    n = d1 × d2

    # Check that the cross product is reasonable - otherwise assume parallel lines
    if norm(n) > 10*eps(norm(d1)*norm(d2))
        r = p1 - p2
        t1 = -(d2 ⋅ (n × r)) / (d2 ⋅ (n × d1))
        t2 =  (d1 ⋅ (n × r)) / (d1 ⋅ (n × d2))

        # The segments reach closest approach (of infinite lines) iff the ti are in 0..1
        if t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1
            return n ⋅ r / norm(n)
        end
    end

    # Otherwise, one of the end points is closest - but there is no hint as to which
    dist = distance(l1.p1, l2)
    dist = min(dist, distance(l1.p2, l2))
    dist = min(dist, distance(l1, l2.p1))
    dist = min(dist, distance(l1, l2.p2))

    return dist
end

distance(l1::Line{2}, l2::Line{3}) = distance(l1, convert2d(l2))
distance(l1::Line{3}, l2::Line{2}) = distance(convert2d(l1), l2)

# Distance between a point and the closest point on a LineString
function distance(ls::LineString, p::AbstractVector{<:Real})
    mapreduce(l -> distance(l, p), min, ls)
end
distance(p::AbstractVector{<:Real}, ls::LineString) = distance(ls, p)

function distance(polygon::Polygon, p::AbstractVector{T}) where {T <: Real}
    if p in polygon
        return zero(T)
    end

    dist = distance(polygon.exterior, p)
    for ls in polygon.interiors
        dist = min(dist, distance(ls, p))
    end

    return dist
end
distance(p::AbstractVector{<:Real}, polygon::Polygon) = distance(polygon, p)

# Distance between a point and the closest point on a Catenary
distance(p::AbstractVector{<:Real}, cat::Catenary) = powerline_distances(cat, p)[1]
distance(cat::Catenary, p::AbstractVector{<:Real}) = powerline_distances(cat, p)[1]
