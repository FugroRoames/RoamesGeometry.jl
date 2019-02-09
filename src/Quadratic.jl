"""
    Quadratic(trans::AffineMap, length, ay, by, cy, az, bz, cz)

Construct a `Quadratic` object. The `AffineMap` brings the quadratic into a
frame in which the `x` axis is approximately aligned with the quadratic. In this frame,
the `x` values of the quadratic lie between zero and `length`, and the `y` and `z`
components are parameterized by `x` as:

y = ay + by*x + cy*x^2
z = az + bz*x + cz*x^2
"""
struct Quadratic{Tfm <: AffineTransformation, T <: Real}
    transform::Tfm # transformation from global frame to quadratic's frame
    length::T  # replace with xmin, xmax?
    ay::T
    by::T
    cy::T
    az::T
    bz::T
    cz::T
end

"""
    Quadratic(p_start, p_mid, p_end)

Takes three coordinates for the start, somewhere in the middle, and the end of a quadratic
and constructs the appropriate `Quadratic` object.
"""
function Quadratic(p_start::StaticVector{3,T}, p_mid::StaticVector{3,T}, p_end::StaticVector{3,T}) where {T <: Real}
    dir = SVector(p_end[1] - p_start[1], p_end[2] - p_start[2])
    len = norm(dir) # horizontal length
    @static if VERSION < v"0.7"
        θ = atan2(dir[2], dir[1]) # rotation in x-y plane
    else
        θ = atan(dir[2], dir[1]) # rotation in x-y plane
    end
    tform = inv(AffineMap(RotZ(θ), p_start))

    p2_mid = tform(p_mid)
    p2_end = tform(p_end)

    x1 = p2_mid[1]
    y1 = p2_mid[2]
    z1 = p2_mid[3]

    x2 = p2_end[1]
    y2 = p2_end[2]
    z2 = p2_end[3]

    by = (x1*y2/x2 - x2*y1/x1)/(x1 - x2)
    bz = (x1*z2/x2 - x2*z1/x1)/(x1 - x2)

    cy = (y2/x2 - y1/x1)/(x2 - x1)
    cz = (z2/x2 - z1/x1)/(x2 - x1)

    ay = zero(cy)
    az = zero(cz)

    return Quadratic(tform, len, ay, by, cy, az, bz, cz)
end

# mop up other types
function Quadratic(p1::AbstractVector{T}, p2::AbstractVector{T}, p3::AbstractVector{T}) where {T <: Real}
    Quadratic(SVector{3,T}(p1), SVector{3,T}(p2), SVector{3,T}(p3))
end

eltype(::Quadratic{T}) where {T} = SVector{3,T}
eltype(::Type{<:Quadratic{T}}) where {T} = SVector{3,T}

# Use getindex to get points along the line
function getindex(q::Quadratic, x)
    inv(q.transform)(SVector(x, q.ay+q.by*x+q.cy*x*x, q.az+q.bz*x+q.cz*x*x))
end
length(q::Quadratic) = q.length  # matches getindex and makes sense...
if VERSION < v"0.7"
    endof(q::Quadratic) = length(q) # e.g. q[end - 1] is the point 1 metre from top of quadratic
else
    lastindex(q::Quadratic) = length(q) # e.g. q[end - 1] is the point 1 metre from top of quadratic
end

getindex(q::Quadratic, v::AbstractVector) = map(x -> q[x], v)

# Transformations (which compose into AffineMap's)
# Note: Julia's dispatch system makes it difficult to support all `Transformations`.
function (trans::Translation{V})(q::Quadratic) where {V}
    Quadratic(q.transform ∘ inv(trans), q.length, q.ay, q.by, q.cy, q.az, q.bz, q.cz)
end

function (trans::LinearMap{M})(q::Quadratic) where {M}
    Quadratic(q.transform ∘ inv(trans), q.length, q.ay, q.by, q.cy, q.az, q.bz, q.cz)
end

function (trans::AffineMap{M,V})(q::Quadratic) where {M,V}
    Quadratic(q.transform ∘ inv(trans), q.length, q.ay, q.by, q.cy, q.az, q.bz, q.cz)
end
