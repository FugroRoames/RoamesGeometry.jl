"""
    BoundingBox(xmin, ymin, zmin, xmax, ymax, zmax)
    BoundingBox(corner_min, corner_max)

Construct a three-dimensional `BoundingBox` representing a closed, axis-aligned rectangular
prism with the given coordinates.

Note that users will usually want to call the `boundingbox` function, which constructs a
`BoundingBox` guaranteed to contain all of the inputed geometry.

See also `AbstractRegion`
"""
struct BoundingBox{T <: Real} <: AbstractRegion{T}
    xmin::T
    ymin::T
    zmin::T
    xmax::T
    ymax::T
    zmax::T
end

@inline function BoundingBox(xmin, ymin, zmin, xmax, ymax, zmax)
    T = promote_type(typeof(xmin), promote_type(typeof(ymin), promote_type(typeof(zmin), promote_type(typeof(xmax), promote_type(typeof(ymax), typeof(zmax))))))
    BoundingBox(convert(T, xmin), convert(T, ymin), convert(T, zmin), convert(T, xmax), convert(T, ymax), convert(T, zmax))
end

@inline BoundingBox(v1::AbstractVector{<:Real}, v2::AbstractVector{<:Real}) = boundingbox(v1, v2)

@inline function Base.:(==)(bb1::BoundingBox, bb2::BoundingBox)
    bb1.xmin == bb2.xmin &&
        bb1.xmax == bb2.xmax &&
        bb1.ymin == bb2.ymin &&
        bb1.ymax == bb2.ymax &&
        bb1.zmin == bb2.zmin &&
        bb1.zmax == bb2.zmax
end

@inline function in(p::StaticVector{3, <:Real}, bb::BoundingBox)
    @inbounds return (p[1] >= bb.xmin) & (p[2] >= bb.ymin) & (p[3] >= bb.zmin) &
        (p[1] <= bb.xmax) & (p[2] <= bb.ymax) & (p[3] <= bb.zmax)
end

"""
    intersects(bb1, bb2)

Returns true if the bounding boxes `bb1` and `bb2` intersect.
"""
function intersects(bb1::BoundingBox, bb2::BoundingBox)
    ! ( bb1.xmax < bb2.xmin || bb1.xmin > bb2.xmax ||
        bb1.ymax < bb2.ymin || bb1.ymin > bb2.ymax ||
        bb1.zmax < bb2.zmin || bb1.zmin > bb2.zmax )
end

@inline might_intersect(bb1::BoundingBox, bb2::BoundingBox) = intersects(bb1, bb2)

"""
    isempty(bb)

Returns true if the bounding box bb is empty.
"""
function isempty(bb::BoundingBox)
    bb.xmin > bb.xmax || bb.ymin > bb.ymax || bb.zmin > bb.zmax
end

# contains (issubset, ⊑), intersect (∩)

"""
    pad(bb::BoundingBox, dist)

Pad out the bounding box `bb` by distance `dist`.
"""
pad(bb::BoundingBox, dist) = BoundingBox(bb.xmin-dist, bb.ymin-dist, bb.zmin-dist, bb.xmax+dist, bb.ymax+dist, bb.zmax+dist)


"""
    wireframe(bb::BoundingBox)

Returns a vector of 12 `Line`s representing the wireframe of the bounding box
(primarily for plotting purposes).
"""
function wireframe(bb::BoundingBox)
    if isempty(bb)
        return Vector{Line{3, eltype(eltype(bb))}}()
    else
        @static if VERSION < v"0.7"
            lines = Vector{Line{3, eltype(eltype(bb))}}(12)
        else
            lines = Vector{Line{3, eltype(eltype(bb))}}(undef, 12)
        end
        @inbounds begin
            lines[1]  = Line(SVector(bb.xmin, bb.ymin, bb.zmin), SVector(bb.xmax, bb.ymin, bb.zmin))
            lines[2]  = Line(SVector(bb.xmin, bb.ymax, bb.zmin), SVector(bb.xmax, bb.ymax, bb.zmin))
            lines[3]  = Line(SVector(bb.xmin, bb.ymin, bb.zmax), SVector(bb.xmax, bb.ymin, bb.zmax))
            lines[4]  = Line(SVector(bb.xmin, bb.ymax, bb.zmax), SVector(bb.xmax, bb.ymax, bb.zmax))

            lines[5]  = Line(SVector(bb.xmin, bb.ymin, bb.zmin), SVector(bb.xmin, bb.ymax, bb.zmin))
            lines[6]  = Line(SVector(bb.xmax, bb.ymin, bb.zmin), SVector(bb.xmax, bb.ymax, bb.zmin))
            lines[7]  = Line(SVector(bb.xmin, bb.ymin, bb.zmax), SVector(bb.xmin, bb.ymax, bb.zmax))
            lines[8]  = Line(SVector(bb.xmax, bb.ymin, bb.zmax), SVector(bb.xmax, bb.ymax, bb.zmax))

            lines[9]  = Line(SVector(bb.xmin, bb.ymin, bb.zmin), SVector(bb.xmin, bb.ymin, bb.zmax))
            lines[10] = Line(SVector(bb.xmax, bb.ymin, bb.zmin), SVector(bb.xmax, bb.ymin, bb.zmax))
            lines[11] = Line(SVector(bb.xmin, bb.ymax, bb.zmin), SVector(bb.xmin, bb.ymax, bb.zmax))
            lines[12] = Line(SVector(bb.xmax, bb.ymax, bb.zmin), SVector(bb.xmax, bb.ymax, bb.zmax))
        end
        return lines
    end
end


"""
    boundingbox(geometry...)

Construct a `BoundingBox` which encapsulates all the `geometry` given. The geometry might
including objects like points (length-3 vectors), other bounding boxes, and other Roames
geometry types.
"""
boundingbox(bb::BoundingBox) = bb
boundingbox(x) = error("BoundingBox for type $(typeof(x)) not implemented.")
@inline boundingbox(geom1, geoms...) = boundingbox(boundingbox(geom1), boundingbox(geoms...))
@inline function boundingbox(bb::BoundingBox, geoms...)
    bb2 = boundingbox(geoms...)
    T = promote_type(eltype(eltype(bb)), eltype(eltype(bb2)))
    if isempty(bb2)
        BoundingBox(convert(T, bb.xmin), convert(T, bb.ymin), convert(T, bb.zmin),
                    convert(T, bb.xmax), convert(T, bb.ymax), convert(T, bb.zmax))
    elseif isempty(bb)
        BoundingBox(convert(T, bb2.xmin), convert(T, bb2.ymin), convert(T, bb2.zmin),
                    convert(T, bb2.xmax), convert(T, bb2.ymax), convert(T, bb2.zmax))
    else
        BoundingBox(min(bb.xmin, bb2.xmin), min(bb.ymin, bb2.ymin), min(bb.zmin, bb2.zmin),
                    max(bb.xmax, bb2.xmax), max(bb.ymax, bb2.ymax), max(bb.zmax, bb2.zmax))
    end
end


"""
    boundingbox(geometries::AbstractVector)

Construct a `BoundingBox` from `geometries`, which is a vector containing an arbitrary
number of points, lines, bounding boxes or any other Roames geometry type.
"""
boundingbox(geometries::AbstractVector) = mapreduce(boundingbox, boundingbox, geometries)

# micro-optimization for collections of points (3x faster)
function boundingbox(points::AbstractVector{<:StaticVector{2, T}}) where T <: Real
    xmin = typemax(T)
    xmax = typemin(T)
    ymin = typemax(T)
    ymax = typemin(T)

    @inbounds for p ∈ points
        x = p[1]
        y = p[2]

        if x < xmin
            xmin = x
        end
        if y < ymin
            ymin = y
        end
        if x > xmax
            xmax = x
        end
        if y > ymax
            ymax = y
        end
    end

    return BoundingBox(xmin, ymin, typemin(T), xmax, ymax, typemax(T))
end

function boundingbox(points::AbstractVector{<:StaticVector{3, T}}) where T <: Real
    xmin = typemax(T)
    xmax = typemin(T)
    ymin = typemax(T)
    ymax = typemin(T)
    zmin = typemax(T)
    zmax = typemin(T)

    @inbounds for p ∈ points
        x = p[1]
        y = p[2]
        z = p[3]

        if x < xmin
            xmin = x
        end
        if y < ymin
            ymin = y
        end
        if z < zmin
            zmin = z
        end
        if x > xmax
            xmax = x
        end
        if y > ymax
            ymax = y
        end
        if z > zmax
            zmax = z
        end
    end

    return BoundingBox(xmin, ymin, zmin, xmax, ymax, zmax)
end

# Point
function boundingbox(point::StaticVector{2, T}) where {T <: Real}
    @inbounds return BoundingBox(point[1], point[2], typemin(T), point[1], point[2], typemax(T))
end

function boundingbox(point::StaticVector{3, T}) where {T <: Real}
    @inbounds return BoundingBox(point[1], point[2], point[3], point[1], point[2], point[3])
end

# Line
boundingbox(line::Line) = boundingbox(line.p1, line.p2)

# LineString
boundingbox(ls::LineString) = boundingbox(ls.points)

# Polygon
boundingbox(p::Polygon) = boundingbox(p.exterior)

# Catenary
function boundingbox(cat::Catenary)
    if cat.lmin < 0 && cat.lmax > 0
        boundingbox(cat[cat.lmin], cat[0], cat[cat.lmax])
    else
        boundingbox(cat[cat.lmin], cat[cat.lmax])
    end
end

# Quadratic (TODO)
function boundingbox(q::Quadratic)
    error("BoundingBox for quadratic is not yet implemented")
end

