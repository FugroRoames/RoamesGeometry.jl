"""
    Line(p1, p2)

Construct a `Line` geometric object (representing a segment) with given beginning and end
points, which are generally 2-vectors or 3-vectors.
"""
struct Line{N, T <: Real}
    p1::SVector{N, T}
    p2::SVector{N, T}
end

function Line(p1::StaticVector{N, T}, p2::StaticVector{N, T}) where {N, T <: Real}
    Line{N, T}(p1, p2)
end

function Line{N}(p1::AbstractVector{T}, p2::AbstractVector{T}) where {N, T <: Real}
    Line{N, T}(p1, p2)
end

# Note: This doesn't compare the ordering of points
function Base.:(==)(l1::Line{N}, l2::Line{N}) where N
    return l1.p1 == l2.p1 && l1.p2 == l2.p2
end

function Base.isequal(l1::Line{N}, l2::Line{N}) where N
    isequal(l1.p1, l2.p1) && isequal(l1.p2, l2.p2)
end

function Base.hash(l::Line, h::UInt)
    hash(l.p1, hash(l.p2, hash(UInt === UInt64 ? 0x627c5acc5b1e3d3d : 0x94c690be, h)))
end

# Use getindex to get points along the line
length(l::Line) = norm(l.p1 - l.p2)
function getindex(l::Line, t)
    t = t/length(l)
    (1-t)*l.p1 + t*l.p2
end
if VERSION < v"0.7"
    endof(l::Line) = length(l) # e.g. l[end - 1.0] is the point 1 metre from end of line
else
    lastindex(l::Line) = length(l) # e.g. l[end - 1.0] is the point 1 metre from end of line
end

eltype(::Line{N, T}) where {N, T} = SVector{N,T}
eltype(::Type{Line{N, T}}) where {N, T} = SVector{N,T}

getindex(l::Line, v::AbstractVector) = map(x -> l[x], v)

# Transformations (Affine only, for the moment)
(trans::Translation{V})(l::Line) where {V} = Line(trans(l.p1), trans(l.p2))
(trans::LinearMap{M})(l::Line) where {M} = Line(trans(l.p1), trans(l.p2))
(trans::AffineMap{M,V})(l::Line) where {M,V} = Line(trans(l.p1), trans(l.p2))

# Geometric operations
convert2d(l::Line{2}) = l
convert2d(l::Line{3}) = Line(convert2d(l.p1), convert2d(l.p2))
convert3d(l::Line{2}) = Line(convert3d(l.p1), convert3d(l.p2))
convert3d(l::Line{2}, z::Real) = Line(convert3d(l.p1, z), convert3d(l.p2, z))
convert3d(l::Line{3}) = l
convert3d(l::Line{3}, z::Real) = Line(convert3d(l.p1, z), convert3d(l.p2, z))

function intersects(l1::Line, l2::Line)
    return distance(l1, l2) == 0
end

function show(io::IO, l::Line{N}) where N
    print(io, "Line{$N}(")
    print(io, l.p1)
    print(io, ", ")
    print(io, l.p2)
    print(io, ")")
end

lines(l::Line) = [l]
