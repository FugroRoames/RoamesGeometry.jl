function is_Displaz_installed()
    try
        @static if VERSION < v"0.7.0"
            return Pkg.installed("Displaz") != nothing
        else
            return haskey(Pkg.installed(), "Displaz")
        end
    catch
        return false
    end
end

@static if is_Displaz_installed()
    using Displaz

    # Plot Lines
    function Displaz.plot3d(l::Line, args...; label = "Line", kwargs...)
        vertices = [l[0], l[end]]
        Displaz.plot3d(vertices, args...; label = label, markershape = '-', linebreak = 20, kwargs...)
    end

    function Displaz.plot3d(ls::AbstractVector{<:Line}, args...; label = "Lines [$(length(ls))]", kwargs...)
        vertices = zeros(SVector{3,Float64}, 2*length(ls))
        for i = 1:length(ls)
            vertices[2*i-1] = ls[i][0.0]
            vertices[2*i] = ls[i][end]
        end
        Displaz.plot3d(vertices, args...; label = label, markershape = '-', linebreak = 2, kwargs...)
    end

    function Displaz.plot3d!(l::Line, args...; label = "Line", kwargs...)
        vertices = [l[0], l[end]]
        Displaz.plot3d!(vertices, args...; label = label, markershape = '-', linebreak = 20, kwargs...)
    end

    function Displaz.plot3d!(ls::AbstractVector{<:Line}, args...; label = "Lines [$(length(ls))]", kwargs...)
        vertices = zeros(SVector{3,Float64}, 2*length(ls))
        for i = 1:length(ls)
            vertices[2*i-1] = ls[i][0.0]
            vertices[2*i] = ls[i][end]
        end
        Displaz.plot3d!(vertices, args...; label = label, markershape = '-', linebreak = 2, kwargs...)
    end

    # Plot LineStrings
    function Displaz.plot3d(ls::LineString, args...; label = "LineString", kwargs...)
        Displaz.plot3d(lines(ls), args...; label = label, kwargs...)
    end

    function Displaz.plot3d(lss::AbstractVector{<:LineString{N,T}}, args...; label = "LineStrings [$(length(lss))]", kwargs...) where {N,T}
        tmp = Vector{Line{N,T}}()
        for ls in lss
            append!(tmp, lines(ls))
        end
        Displaz.plot3d(tmp, args...; label = label, kwargs...)
    end

    function Displaz.plot3d!(ls::LineString, args...; label = "LineString", kwargs...)
        Displaz.plot3d!(lines(ls), args...; label = label, kwargs...)
    end

    function Displaz.plot3d!(lss::AbstractVector{<:LineString{N,T}}, args...; label = "LineStrings [$(length(lss))]", kwargs...) where {N,T}
        tmp = Vector{Line{N,T}}()
        for ls in lss
            append!(tmp, lines(ls))
        end
        Displaz.plot3d!(tmp, args...; label = label, kwargs...)
    end

    # Plot Polygon
    function Displaz.plot3d(p::Polygon, args...; label = "Polygon", kwargs...)
        Displaz.plot3d(lines(p), args...; label = label, kwargs...)
    end

    function Displaz.plot3d!(p::Polygon, args...; label = "Polygon", kwargs...)
        Displaz.plot3d!(lines(p), args...; label = label, kwargs...)
    end

    function Displaz.plot3d(ps::AbstractVector{<:Polygon{N,T}}, args...; label = "Polygons [$(length(ps))]", kwargs...) where {N,T}
        tmp = Vector{Line{N,T}}()
        for p in ps
            append!(tmp, lines(p))
        end
        Displaz.plot3d(tmp, args...; label = label, kwargs...)
    end

    function Displaz.plot3d!(p::AbstractVector{<:Polygon}, args...; label = "Polygon", kwargs...)
        Displaz.plot3d!(lines(p), args...; label = label, kwargs...)
    end

    function Displaz.plot3d!(ps::AbstractVector{<:Polygon{N,T}}, args...; label = "Polygons [$(length(ps))]", kwargs...) where {N,T}
        tmp = Vector{Line{N,T}}()
        for p in ps
            append!(tmp, lines(p))
        end
        Displaz.plot3d!(tmp, args...; label = label, kwargs...)
    end

    # Plot Quadratics
    function Displaz.plot3d(q::Quadratic, args...; label = "Quadratic", kwargs...)
        vertices = q[linspace(zero(length(q)), length(q), 20)]
        Displaz.plot3d(vertices, args...; label = label, markershape = '-', linebreak = 20, kwargs...)
    end

    function Displaz.plot3d(qs::AbstractVector{<:Quadratic}, args...; label = "Quadratics [$(length(qs))]", kwargs...)
        vertices = zeros(SVector{3,Float64}, 20*length(qs))
        for i = 1:length(qs)
            vertices[(1+20*(i-1)):(20*i)] = qs[i][linspace(zero(length(qs[i])), length(qs[i]), 20)]
        end
        Displaz.plot3d(vertices, args...; label = label, markershape = '-', linebreak = 20, kwargs...)
    end

    function Displaz.plot3d!(q::Quadratic, args...; label = "Quadratic", kwargs...)
        vertices = q[linspace(zero(length(q)), length(q), 20)]
        Displaz.plot3d!(vertices, args...; label = label, markershape = '-', linebreak = 20, kwargs...)
    end

    function Displaz.plot3d!(qs::AbstractVector{<:Quadratic}, args...; label = "Quadratics [$(length(qs))]", kwargs...)
        vertices = zeros(SVector{3,Float64}, 20*length(qs))
        for i = 1:length(qs)
            vertices[(1+20*(i-1)):(20*i)] = qs[i][linspace(zero(length(qs[i])), length(qs[i]), 20)]
        end
        Displaz.plot3d!(vertices, args...; label = label, markershape = '-', linebreak = 20, kwargs...)
    end

    # Plot Catenaries
    function Displaz.plot3d(c::Catenary, args...; label = "Catenary", kwargs...)
        vertices = c[linspace(c.lmin, c.lmax, 20)]
        Displaz.plot3d(vertices, args...; label = label, markershape = '-', linebreak = 20, kwargs...)
    end

    function Displaz.plot3d(cs::AbstractVector{<:Catenary}, args...; label = "Catenaries [$(length(cs))]", kwargs...)
        vertices = zeros(SVector{3,Float64}, 20*length(cs))
        for i = 1:length(cs)
            vertices[(1+20*(i-1)):(20*i)] = cs[i][linspace(cs[i].lmin, cs[i].lmax, 20)]
        end
        Displaz.plot3d(vertices, args...; label = label, markershape = '-', linebreak = 20, kwargs...)
    end

    function Displaz.plot3d!(c::Catenary, args...; label = "Catenary", kwargs...)
        vertices = c[linspace(c.lmin, c.lmax, 20)]
        Displaz.plot3d!(vertices, args...; label = label, markershape = '-', linebreak = 20, kwargs...)
    end

    function Displaz.plot3d!(cs::AbstractVector{<:Catenary}, args...; label = "Catenaries [$(length(cs))]", kwargs...)
        vertices = zeros(SVector{3,Float64}, 20*length(cs))
        for i = 1:length(cs)
            vertices[(1+20*(i-1)):(20*i)] = cs[i][linspace(cs[i].lmin, cs[i].lmax, 20)]
        end
        Displaz.plot3d!(vertices, args...; label = label, markershape = '-', linebreak = 20, kwargs...)
    end

    # Plot BoundingBoxes
    function Displaz.plot3d(bb::BoundingBox, args...; label = "BoundingBox", kwargs...)
        lines = wireframe(bb)
        Displaz.plot3d(lines, args...; label = label, kwargs...)
    end

    function Displaz.plot3d(bbs::AbstractVector{<:BoundingBox}, args...; label = "BoundingBoxes [$(length(bb))]", kwargs...)
        lines = Vector{Line{eltype(eltype(bbs))}}()
        for i = 1:length(bbs)
            append!(lines, wireframe(bbs[i]))
        end
        Displaz.plot3d(lines, args...; label = label, kwargs...)
    end

    function Displaz.plot3d!(bb::BoundingBox, args...; label = "BoundingBox", kwargs...)
        lines = wireframe(bb)
        Displaz.plot3d!(lines, args...; label = label, kwargs...)
    end

    function Displaz.plot3d!(bbs::AbstractVector{<:BoundingBox}, args...; label = "BoundingBoxes [$(length(bb))]", kwargs...)
        lines = Vector{Line{eltype(eltype(bbs))}}()
        for i = 1:length(bbs)
            append!(lines, wireframe(bbs[i]))
        end
        Displaz.plot3d!(lines, args...; label = label, kwargs...)
    end
end
