"""
    AbstractRegion

`AbstractRegion` is an abstract type representing region of space which will be
used to perform a spatial query.

An implementation `Region <: AbstractRegion` must provide implementations for;
- `in(::SVector{3, T}, ::Region{T})`
- `boundingbox{T}(::Region{T})`

An implementation `Region <: AbstractRegion` may provided optimized
implementations for;
- `might_intersect(::BoundingBox{T}, ::Region{T})`


See also `BoundingBox`, `Sphere`, `Cylinder`, `Circle`, `TriangularPrism`, and `Triangle`.
"""
abstract type AbstractRegion{T <: Real} end

"""
    in(p, region)

Determine whether a point `p` is within the given `region`.
"""
@inline function in(p::AbstractVector{T}, region::AbstractRegion) where T
    return in(convert(SVector{3,T}, p), region)
end
function in(p::StaticVector{3, T}, region::Region) where {T <: Real, Region <: AbstractRegion}
    error("Base.in not implemented for region type $Region")
end

"""
    eltype(region)

Determine the type of Real used to describe the `region` geometry
"""
eltype(::AbstractRegion{T}) where {T} = SVector{3, T}
eltype(::Type{<:AbstractRegion{T}}) where {T} = SVector{3, T}

"""
    boundingbox(region)

Construct a `BoundingBox` which encapsulates all the `region` which is of a
sub-type of AbstractRegion.
"""
function boundingbox(::Region) where Region <: AbstractRegion
    error("bounding box not implemented for region type $(Region)")
end