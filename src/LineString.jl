"""
    LineString(points)

Construct a `LineString` geometric object, which is a connected string of lines. The
`points` are expected to be a vector 2-vectors or 3-vectors.

Certain two-dimensional operations are provided for `LineString`. A `LineString`
`isclosed` if it is not empty and the first and last point is identical. A `LineString`
`issimple` if it `isclosed`, and no lines intersect (when projected to the X-Y plane).
"""
struct LineString{N, T <: Real, V <: AbstractVector{<:StaticVector{N, T}}} <: AbstractVector{Line{N, T}}
    points::V
end

LineString(points::StaticVector{N,T}...) where {N, T <: Real} = LineString(collect(points))
if VERSION < v"0.7" 
    LineString(points::AbstractVector{<:StaticVector{N, T}}) where {N, T <: Real} = LineString{N, T}(points)
end
LineString{N}(points::AbstractVector{T}...) where {N, T <: Real} = LineString{N}(collect(points))
LineString{N}(points::AbstractVector{<:AbstractVector{T}}) where {N, T <: Real} = LineString{N, T}(points)
LineString{N, T}(points::AbstractVector{<:Real}...) where {N, T <: Real} = LineString{N, T}(collect(points))
LineString{N, T}(points::AbstractVector{<:AbstractVector{<:Real}}) where {N, T <: Real} = LineString{N, T}(convert.(SVector{N,T}, points))
LineString{N, T}(points::AbstractVector{<:StaticVector{N, T}}) where {N, T <: Real} = LineString{N, T, typeof(points)}(points)

# AbstractArray interface
Base.IndexStyle(ls::Type{<:LineString}) = IndexLinear()
size(ls::LineString) = (max(1, length(ls.points)) - 1,)
# TODO support offset vectors
@propagate_inbounds getindex(ls::LineString, i::Int) = Line(ls.points[i], ls.points[i+1])

function Base.:(==)(ls1::LineString{N}, ls2::LineString{N}) where N
    return ls1.points == ls2.points
end

function show(io::IO, ls::LineString{N}) where N
    print(io, "LineString{$N}([")
    for i in 1:length(ls.points)
        print(io, ls.points[i])
        if i < length(ls.points)
            print(io, ", ")
        end
    end
    print(io, "])")
end

# Transformations (Affine only, for the moment)
(trans::Translation{V})(l::LineString) where {V} = LineString(trans.(l.points))
(trans::LinearMap{M})(l::LineString) where {M} = LineString(trans.(l.points))
(trans::AffineMap{M,V})(l::LineString) where {M,V} = LineString(trans.(l.points))

# Some geometry interfaces
isclosed(ls::LineString) = length(ls.points) > 1 && first(ls.points) == last(ls.points)
function issimple(ls::LineString)
    if length(ls.points) < 3 || first(ls.points) != last(ls.points)
        return false
    end

    # TODO: Use Shamos-Huey algorithm
    @inbounds for i1 = 1:length(ls)
        l1 = convert2d(ls[i1])
        for i2 = i1+2:length(ls) - (i1 == 1)
            l2 = convert2d(ls[i2])
            if intersects(l1, l2)
                return false
            end
        end
    end
    return true
end

function lines(ls::LineString{N,T}) where {N, T}
    out = Vector{Line{N,T}}()
    for i in 2:length(ls.points)
        push!(out, Line(ls.points[i-1], ls.points[i]))
    end
    return out
end

function area(ls::LineString{2, T}) where {T}
    out = zero(T)
    if length(ls.points) < 2
        return out
    end
    if first(ls.points) != last(ls.points)
        error("LineString is not closed")
    end

    # Use offsets from first point for increased numerical accuracy
    @inbounds origin = ls.points[1]
    @inbounds oldpoint = ls.points[2] - origin
    @inbounds for i = 3 : length(ls.points)-1
        newpoint = ls.points[i] - origin
        out += newpoint × oldpoint
        oldpoint = newpoint
    end
    return convert(T, 0.5) * out
end

convert2d(ls::LineString{2}) = ls
convert2d(ls::LineString{3}) = LineString(convert2d.(ls.points))
convert3d(ls::LineString{2}) = LineString(convert3d.(ls.points))
convert3d(ls::LineString{2}, z::Real) = LineString(convert3d.(ls.points, z))
convert3d(ls::LineString{3}) = ls
convert3d(ls::LineString{3}, z::Real) = LineString(convert3d.(ls.points, z))

function intersects(l1::Line{2}, ls2::LineString{2})
    for l2 in ls2
        if intersects(l1, l2)
            return true
        end
    end
    return false
end

function intersects(ls1::LineString{2}, l2::Line{2})
    for l1 in ls1
        if intersects(l1, l2)
            return true
        end
    end
    return false
end

function intersects(ls1::LineString{2}, ls2::LineString{2})
    for l1 in ls1
        for l2 in ls2
            if intersects(l1, l2)
                return true
            end
        end
    end
    return false
end

function winding_number(p::StaticVector{2, <:Real}, ls::LineString{2})
    # Calculate clockwise winding number.
    # See for example http://geomalgorithms.com/a03-_inclusion.html
    if isempty(ls.points)
        return 0
    end

    winding = 0

    # Shift origin to p, and test winding of all Line(p1, p2)
    p1 = ls.points[1] - p
    for i in 2:length(ls.points)
        p2 = ls.points[i] - p
        if p1[2] <= 0
            if p2[2] > 0 # crosses x-axis upwards
                if p1 × p2 > 0 # orign, p1, p2 form anticlockwise triangle if it passes to the right
                    winding -= 1
                end
            end
        else
            if p2[2] <= 0 # crosses x-axis downwards
                if p1 × p2 < 0 # orign, p1, p2 form clockwise triangle if it passes to the right
                    winding += 1
                end
            end
        end
        p1 = p2
    end
    return winding # clockwise sense
end
