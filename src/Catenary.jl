"""
    Catenary(trans::AffineMap, xmin, xmax, a)

Construct a `Catenary` object. The `AffineMap` brings the catenary into a frame
frame in which the `x` axis is aligned with vertically hanging catenary. In this frame,
the `x` values of the catenary lie between `xmin` and `xmax`, the `y` component is zero,
and `z` is parameterized by `x` as:

z = a * (cosh(x / a) - 1)
"""
struct Catenary{Tfm <: AffineTransformation, T <: Real}
    transform::Tfm # transformation from global frame to quadratic's frame
    lmin::T  # "Longitudinal" coordinate at end of catenary
    lmax::T  # "Longitudinal" coordinate at start of catenary
    a::T # Catenary paramter equivalent to 1/2a (such that ax^2+bx+c)
end

"""
    Catenary(Θ, x, y, z, lmin, lmax, a)

Create a catenary from the parameters stored in the Roames database.

### Arguments
* `Θ` : Angle of catenary in XY plane
* `x`: x position of lowest point on catenary
* `y`: y position of lowest point on catenary
* `z`: z position of lowest point on catenary
* `lmin`: Longitudinal coordinate at start of catenary
* `lmax`: Longitudinal coordinate at end of catenary
* `a`: Catenary paramter equivalent to 1/2a (such that ax^2+bx+c)
"""
function Catenary(Θ::T, x::T, y::T, z::T, lmin::T, lmax::T, a::T) where {T}
    trans = inv(Translation(SVector(x, y, z)) ∘ LinearMap(RotZ(Θ)))
    return Catenary(trans, lmin, lmax, a)
end
@inline Catenary(args...) = Catenary(promote(args...)...)

eltype(::Catenary{T}) where {T} = SVector{3,T}
eltype(::Type{<:Catenary{T}}) where {T} = SVector{3,T}

# Use getindex to get points along the line
function getindex(c::Catenary, x)
    inv(c.transform)(SVector(x, 0, c.a * (cosh(x / c.a) - 1)))
end
length(c::Catenary) = c.lmax - c.lmin
#lastindex(c::Catenary) = c.lmax # seems unsafe with `begin`

getindex(c::Catenary, v::AbstractVector) = map(x -> c[x], v)

# Transformations (which compose into AffineMap's)
# Note: Julia's dispatch system makes it difficult to support all `Transformations`.
(trans::Translation{V})(c::Catenary) where {V} = Catenary(c.transform ∘ inv(trans), c.lmin, c.lmax, c.a)
(trans::LinearMap{M})(c::Catenary) where {M} = Catenary(c.transform ∘ inv(trans), c.lmin, c.lmax, c.a)
(trans::AffineMap{M,V})(c::Catenary) where {M,V} = Catenary(c.transform ∘ inv(trans), c.lmin, c.lmax, c.a)

"""
function databaseParams(c::Catenary)
    return Roames database paramaters for a catenary object
    ie Θ, x, y, z, lmin, lmax, a
"""
function database_params(c::Catenary)
    temp = c[c.lmax][1:2] .- c[c.lmin][1:2]
    θ = atan(temp[2], temp[1])
    return θ, c[0]..., c.lmin, c.lmax, c.a
end

"""
    Quadratic(c::Catenary)

Create a quadratic which approximates `c`. This is an approximate operation, however
the fitted quadratic is tuned for the relevant segment of the catenary and
`Catenary(Quadratic(c))` should be equal to `c` up to numerical error.
"""
function Quadratic(c::Catenary)
    Quadratic(c[c.lmin], c[0.5*(c.lmin + c.lmax)], c[c.lmax])
end

"""
    Catenary(q::Quadratic)

Create a quadratic which approximates `q`. This is an approximate operation, however
the fitted catenary is tuned for the relevant segment of the quadratic and
`Quadratic(Catenary(q))` should be equal to `q` up to numerical error.
"""
function Catenary(q::Quadratic)
    Catenary(q[0], q[0.5*end], q[end])
end

"""
    Catenary(p_start, p_mid, p_end)

Takes three coordinates for the start, somewhere in the middle, and the end of a catenary
and constructs the appropriate `Catenary` object. A numerical fitting method is used to
fit the catenary parameters.
"""
function Catenary(p_start::StaticVector{3,T}, p_mid::StaticVector{3,T}, p_end::StaticVector{3,T}) where {T}
    dir = SVector(p_end[1] - p_start[1], p_end[2] - p_start[2])
    len = norm(dir) # horizontal length
    @static if VERSION < v"0.7"
        θ = atan2(dir[2], dir[1]) # rotation in x-y plane
    else
        θ = atan(dir[2], dir[1]) # rotation in x-y plane
    end
    tform = inv(AffineMap(RotZ(θ), p_start))

    # Now fit a catenary in the x-z plane. Ignore y value of midpoint on the basis that
    # `Catenary` does not swing (unlike `Quadratic`)
    p_mid_trans = tform(p_mid)
    x_mid = p_mid_trans[1]
    z_mid = p_mid_trans[3]

    x_end = len
    z_end = p_end[3] - p_start[3]

    (a, x0, z0) = fit_catenary_origin_2d(x_mid, z_mid, x_end, z_end)

    # Bring transformation to midpoint
    tform2 = Translation(SVector(-x0, zero(T), -z0)) ∘ tform

    return Catenary(tform2, -x0, -x0+len, a)
end

function fit_catenary_origin_2d(x1::T, z1::T, x2::T, z2::T) where {T}
    # Note: one point is going through the origin

    # First guess - make a quadratic approximation: z = q_a*x^2 + q_b*x + q_c
    q_a = (z2/x2 - z1/x1)/(x2 - x1)
    q_b = (x1*z2/x2 - x2*z1/x1)/(x1 - x2)
    # q_c = 0

    # Find the catenary which matches best at the minimum

    # defend against straight catenaries and degeneracies
    if isnan(q_a) || abs(q_a*max(x1,x2)) < 1e-6 # Second term selects cases where quadratic term changes z by less than 1e-6th of it's length
        # It's either flat or degenerate

        # Choose a bottom which is one million times further than points
        q_b = z2/x2 # slope

        # allow x0 to be close when it's (almost?) flat, but force it to be far when slope is large
        x0 = -1e6*z2 # = -1e6*x2*sign(z2)*abs(q_b)
        a = (q_b == zero(T)) ? inv(2*eps(T)) : -x0/q_b

        # Iteratively improve (as below, but optimizing only `a` w.r.t. `z2`)
        for i = 1:10
            Δz₂ = a*(cosh((x2-x0)/a) - cosh(-x0/a)) - z2
            dΔz₂_da = (cosh((x2-x0)/a) - cosh(-x0/a)) - (((x2-x0)/a)*sinh((x2-x0)/a) - (-x0)/a*sinh(-x0/a))
            a = a - dΔz₂_da \ Δz₂
        end

        z0 = a*(1 - cosh(-x0/a))

        if !isfinite(z0)||!isfinite(x0)||!isfinite(a) # On rare occassions this path proves unstable when the standard one succeeds
            # Continue with standard path
            q_b = (x1*z2/x2 - x2*z1/x1)/(x1 - x2)
        else
            return (a, x0, z0)
        end
    end

    a = inv(2*q_a)
    x0 = -q_b * a # -q_b/(2*q_a)
    # z0 = q_a*x0*x0 + q_b*x0 - a

    # Now iteratively improve upon this guess, fixing z0 = a(1-cosh(-x0/a))
    for i = 1:10
        Δz₁ = a*(cosh((x1-x0)/a) - cosh(-x0/a)) - z1
        Δz₂ = a*(cosh((x2-x0)/a) - cosh(-x0/a)) - z2
        dΔz₁_dx0 = -(sinh((x1-x0)/a) - sinh(-x0/a))
        dΔz₂_dx0 = -(sinh((x2-x0)/a) - sinh(-x0/a))
        dΔz₁_da = (cosh((x1-x0)/a) - cosh(-x0/a)) - (((x1-x0)/a)*sinh((x1-x0)/a) - (-x0)/a*sinh(-x0/a))
        dΔz₂_da = (cosh((x2-x0)/a) - cosh(-x0/a)) - (((x2-x0)/a)*sinh((x2-x0)/a) - (-x0)/a*sinh(-x0/a))

        J = @SMatrix [dΔz₁_dx0 dΔz₁_da; dΔz₂_dx0 dΔz₂_da]
        x = @SVector [Δz₁, Δz₂]
        sol = J \ x
        x0 = x0 - sol[1]
        a = a - sol[2]

        if Δz₁*Δz₁ + Δz₂*Δz₂ < eps(T)
            break
        end
    end

    z0 = a*(1 - cosh(-x0/a))

    return (a, x0, z0)
end
