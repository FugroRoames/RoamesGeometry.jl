function load_pointcloud(filename::AbstractString; kwargs...)
    @info "Loading pointcloud from $filename"
    (_, ext) = splitext(filename)
    if lowercase(ext) == ".h5" || lowercase(ext) == ".hdf5"
        pc = load_h5(filename; kwargs...)
    elseif lowercase(ext) == ".las" || lowercase(ext) == ".laz"
        pc = load_las(filename; kwargs...)
    else
        error("No loader for file extension $ext")
    end

    @info "Successfully loaded pointcloud from $filename"
    return pc
end

"""
    ATTRIBUTE_PATH

Dictionary mapping Julia column name to HDF5 dataset location
"""
const ATTRIBUTE_PATH = Dict{Symbol, String}()

# LAS file attributes
ATTRIBUTE_PATH[:position] = "LAS/Position" # 3D
ATTRIBUTE_PATH[:intensity] = "LAS/Intensity"
ATTRIBUTE_PATH[:gpstime] = "LAS/GpsTime"
ATTRIBUTE_PATH[:returnnumber] = "LAS/ReturnNumber"
ATTRIBUTE_PATH[:numberofreturns] = "LAS/NumberOfReturns"
ATTRIBUTE_PATH[:pointsourceid] = "LAS/PointSourceId"
ATTRIBUTE_PATH[:classification] = "LAS/Classification"
ATTRIBUTE_PATH[:color] = "LAS/Color" # RGB
ATTRIBUTE_PATH[:scananglerank] = "LAS/ScanAngleRank"
ATTRIBUTE_PATH[:scandirectionflag] = "LAS/ScanDirectionFlag"

# Some Julia-specific attributes
ATTRIBUTE_PATH[:featurevector] = "FeatureVector"
ATTRIBUTE_PATH[:featurename] = "FeatureName"
ATTRIBUTE_PATH[:flightstripid] = "FlightStripId"
ATTRIBUTE_PATH[:swathnum] = "Marine/SwathNum"

# Other attributes supported by PointTool, etc (see hpc repo: libs/PointBuffer/include/points/PointAttribute.h)
ATTRIBUTE_PATH[:kp] = "Marine/Distance"

ATTRIBUTE_PATH[:filter] = "Filter"
ATTRIBUTE_PATH[:stringid] = "StringId"

ATTRIBUTE_PATH[:floatposition] = "Float/Position" # 3D

ATTRIBUTE_PATH[:dtmheight] = "DtmHeight"
ATTRIBUTE_PATH[:clusterid] = "ClusterId"
ATTRIBUTE_PATH[:agl] = "AGL"
ATTRIBUTE_PATH[:distance] = "Distance"
ATTRIBUTE_PATH[:normal] = "Normal" # 3D
ATTRIBUTE_PATH[:tile] = "Tile" # 3D


function load_h5(filename::AbstractString; spacing = nothing, format = nothing)
    if format isa AbstractString
        return load_h5_repo2(filename, spacing = spacing, format = format)
    end

    pointcloud = h5open(filename, "r") do f_h # f_h = file handle
        attrs = NamedTuple()
        for (jlname, h5name) in ATTRIBUTE_PATH
            if exists(f_h, h5name)
                attrs = merge(attrs, NamedTuple{(jlname,)}((_read(f_h, jlname, h5name),)))
            end
        end

        if !haskey(attrs, :position)
            @warn "Did not find \"LAS/Position\" in HDF5 file"
        end

        if spacing === nothing
            return Table(attrs)
        else
            return Table(merge(attrs, (position = accelerate(attrs[:position], GridIndex; spacing = spacing),)))
        end
    end
    return pointcloud
end

function load_h5_repo2(filename::AbstractString; spacing = nothing, format::AbstractString = "")
    if format == "" || !isascii(format)
        error("Need to specify point format - see `man ExtractPoints` for help")
    end

    return h5open(filename, "r") do fh
        matrix = read(fh["Points"])
        n_points = isempty(matrix) ? 0 : size(matrix, 2)

        X_i = findall(isequal('X'), format)
        Y_i = findall(isequal('Y'), format)
        Z_i = findall(isequal('Z'), format)
        G_i = findall(isequal('G'), format)
        U_i = findall(isequal('U'), format)
        R_i = findall(isequal('R'), format)
        P_i = findall(isequal('P'), format)
        S_i = findall(isequal('S'), format)
        r_i = findall(isequal('r'), format)
        g_i = findall(isequal('g'), format)
        b_i = findall(isequal('b'), format)
        I_i = findall(isequal('I'), format)

        if isempty(X_i) || isempty(Y_i) || isempty(Z_i)
            error("The XYZ coordinates are mandatory")
        end
        if isempty(r_i) != isempty(g_i) || isempty(r_i) != isempty(b_i)
            error("Either all of 'rgb' or none of 'rgb' must be included in the format string")
        end

        n_attrs = 3
        nt = NamedTuple()

        if n_points == 0
            if spacing === nothing
                nt = (position = SVector{3, Float64}[],)
            else
                nt = (position = accelerate(SVector{3, Float64}[], GridIndex; spacing = spacing),)
            end

            if !isempty(G_i)
                nt = merge(nt, (agl = Float64[],))
                n_attrs += 1
            end
            if !isempty(U_i)
                nt = merge(nt, (clusterid = Int64[],))
                n_attrs += 1
            end
            if !isempty(R_i)
                nt = merge(nt, (returnnumber = Int64[],))
                n_attrs += 1
            end
            if !isempty(P_i)
                nt = merge(nt, (numberofreturns = Int64[],))
                n_attrs += 1
            end
            if !isempty(S_i)
                nt = merge(nt, (flightstripid = Int64[],))
                n_attrs += 1
            end
            if !isempty(I_i)
                nt = merge(nt, (intensity = Int64[],))
                n_attrs += 1
            end
            if !isempty(r_i)
                nt = merge(nt, (color = RGB{N0f8}[],))
                n_attrs += 3
            end
        else
            Xi = X_i[]
            Yi = Y_i[]
            Zi = Z_i[]

            pos = [@inbounds(SVector(matrix[Xi, i], matrix[Yi, i], matrix[Zi, i])) for i in 1:n_points]

            if spacing === nothing
                nt = (position = pos,)
            else
                nt = (position = accelerate(pos, GridIndex; spacing = spacing),)
            end

            if !isempty(G_i)
                Gi = G_i[]
                nt = merge(nt, (agl = [@inbounds(matrix(Zi, i) - matrix(Gi, i)) for i in 1:n_points],))
                n_attrs += 1
            end

            if !isempty(U_i)
                Ui = U_i[]
                nt = merge(nt, (clusterid = Int64[@inbounds(matrix[Ui, i]) for i in 1:n_points],))
                n_attrs += 1
            end

            if !isempty(R_i)
                Ri = R_i[]
                nt = merge(nt, (returnnumber = Int64[@inbounds(matrix[Ri, i]) for i in 1:n_points],))
                n_attrs += 1
            end

            if !isempty(P_i)
                Pi = P_i[]
                nt = merge(nt, (numberofreturns = Int64[@inbounds(matrix[Pi, i]) for i in 1:n_points],))
                n_attrs += 1
            end

            if !isempty(S_i)
                Si = S_i[]
                nt = merge(nt, (flightstripid = Int64[@inbounds(matrix[Si, i]) for i in 1:n_points],))
                n_attrs += 1
            end

            if !isempty(r_i)
                ri = r_i[]
                gi = g_i[]
                bi = b_i[]

                nt = merge(nt, (color = RGB{N0f8}[@inbounds(RGB(reinterpret(N0f8, convert(UInt8, matrix[ri, i])),
                                                                reinterpret(N0f8, convert(UInt8, matrix[gi, i])),
                                                                reinterpret(N0f8, convert(UInt8, matrix[bi, i])))) for i in 1:n_points],))

               n_attrs += 3
            end

            if !isempty(I_i)
                Ii = I_i[]
                nt = merge(nt, (intensity = Int64[@inbounds(matrix[Ii, i]) for i in 1:n_points],))
                n_attrs += 1
            end
        end

        if n_attrs != length(format)
            @warn "Some attribues in $format were ignored"
        end

        return Table(nt)
    end
end

function _read(f_h, jlname::Symbol, h5name::String)
    hdf5_to_data(read(f_h[h5name]), Val(jlname))
end

hdf5_to_data(h5data::AbstractVector, ::Val) = h5data

function hdf5_to_data(h5data::AbstractMatrix, ::Val)
    [SVector(h5data[:, i]...) for i in 1:size(h5data, 2)]
end

function hdf5_to_data(h5data::AbstractMatrix, ::Val{:position})
    @assert size(h5data, 1) == 3
    @inbounds return [SVector(h5data[1, i], h5data[2, i], h5data[3, i]) for i in 1:size(h5data, 2)]
end

function hdf5_to_data(h5data::AbstractMatrix, ::Val{:floatposition})
    @assert size(h5data, 1) == 3
    @inbounds return [SVector(h5data[1, i], h5data[2, i], h5data[3, i]) for i in 1:size(h5data, 2)]
end

function hdf5_to_data(h5data::AbstractMatrix, ::Val{:normal})
    @assert size(h5data, 1) == 3
    @inbounds return [SVector(h5data[1, i], h5data[2, i], h5data[3, i]) for i in 1:size(h5data, 2)]
end

function hdf5_to_data(h5data::AbstractMatrix, ::Val{:tile})
    @assert size(h5data, 1) == 3
    @inbounds return [SVector(h5data[1, i], h5data[2, i], h5data[3, i]) for i in 1:size(h5data, 2)]
end

function hdf5_to_data(h5data::AbstractMatrix{UInt8}, ::Val{:color})
    @assert size(h5data, 1) == 3
    @inbounds return [RGB(reinterpret(N0f8, h5data[1, i]), reinterpret(N0f8, h5data[2, i]), reinterpret(N0f8, h5data[3, i])) for i in 1:size(h5data, 2)]
end

function hdf5_to_data(h5data::AbstractMatrix{UInt16}, ::Val{:color})
    @assert size(h5data, 1) == 3
    @inbounds return [RGB(reinterpret(N0f16, h5data[1, i]), reinterpret(N0f16, h5data[2, i]), reinterpret(N0f16, h5data[3, i])) for i in 1:size(h5data, 2)]
end

function load_las(filename::AbstractString; spacing = nothing, getHeader = false)
    (header, points) = load(filename)

    pointcloud = make_table(points,
                            SVector(header.x_offset, header.y_offset, header.z_offset),
                            SVector(header.x_scale, header.y_scale, header.z_scale))

    if spacing === nothing
        if getHeader
            return pointcloud, header
        else
            return pointcloud
        end
    else
        if getHeader
            return Table(merge(columns(pointcloud), (position = accelerate(pointcloud.position, GridIndex; spacing = spacing),))), header
        else
            return Table(merge(columns(pointcloud), (position = accelerate(pointcloud.position, GridIndex; spacing = spacing),)))
        end
    end
end

function make_table(points::AbstractVector{LasPoint0}, offset, scale)
    position = map(points) do p
        @inbounds SVector(p.x*scale[1] + offset[1], p.y*scale[2] + offset[2], p.z*scale[3] + offset[3])
    end

    intensity = map(p -> p.intensity, points)
    returnnumber = map(p -> p.flag_byte & 0b00000111, points)
    numberofreturns = map(p -> (p.flag_byte & 0b00111000) >> 3, points)
    classification = map(p -> p.raw_classification, points)
    pointsourceid = map(p -> p.pt_src_id, points)

    return Table(position = position,
                 intensity = intensity,
                 returnnumber = returnnumber,
                 numberofreturns = numberofreturns,
                 classification = classification,
                 pointsourceid = pointsourceid)
end

function make_table(points::AbstractVector{LasPoint1}, offset, scale)
    position = map(points) do p
        @inbounds SVector(p.x*scale[1] + offset[1], p.y*scale[2] + offset[2], p.z*scale[3] + offset[3])
    end

    intensity = map(p -> p.intensity, points)
    returnnumber = map(p -> p.flag_byte & 0b00000111, points)
    numberofreturns = map(p -> (p.flag_byte & 0b00111000) >> 3, points)
    classification = map(p -> p.raw_classification, points)
    pointsourceid = map(p -> p.pt_src_id, points)
    gpstime = map(p -> p.gps_time, points)

    return Table(position = position,
                 intensity = intensity,
                 returnnumber = returnnumber,
                 numberofreturns = numberofreturns,
                 classification = classification,
                 pointsourceid = pointsourceid,
                 gpstime = gpstime)
end

function make_table(points::AbstractVector{LasPoint2}, offset, scale)
    position = map(points) do p
        @inbounds SVector(p.x*scale[1] + offset[1], p.y*scale[2] + offset[2], p.z*scale[3] + offset[3])
    end

    intensity = map(p -> p.intensity, points)
    returnnumber = map(p -> p.flag_byte & 0b00000111, points)
    numberofreturns = map(p -> (p.flag_byte & 0b00111000) >> 3, points)
    classification = map(p -> p.raw_classification, points)
    pointsourceid = map(p -> p.pt_src_id, points)

    color = map(points) do p
        @inbounds RGB(p.red, p.green, p.blue)
    end

    return Table(position = position,
                 intensity = intensity,
                 returnnumber = returnnumber,
                 numberofreturns = numberofreturns,
                 classification = classification,
                 pointsourceid = pointsourceid,
                 color = color)
end

function make_table(points::AbstractVector{LasPoint3}, offset, scale)
    position = map(points) do p
        @inbounds SVector(p.x*scale[1] + offset[1], p.y*scale[2] + offset[2], p.z*scale[3] + offset[3])
    end

    intensity = map(p -> p.intensity, points)
    returnnumber = map(p -> p.flag_byte & 0b00000111, points)
    numberofreturns = map(p -> (p.flag_byte & 0b00111000) >> 3, points)
    classification = map(p -> p.raw_classification, points)
    pointsourceid = map(p -> p.pt_src_id, points)
    gpstime = map(p -> p.gps_time, points)
    # userdata = map(p -> p.user_data, points)

    color = map(points) do p
        @inbounds RGB(p.red, p.green, p.blue)
    end



    return Table(position = position,
                 intensity = intensity,
                 returnnumber = returnnumber,
                 numberofreturns = numberofreturns,
                 classification = classification,
                 pointsourceid = pointsourceid,
                 gpstime = gpstime,
                #  userdata = userdata,
                 color = color)
end

function make_table(points::AbstractVector{LasPoint6}, offset, scale)
    position = map(points) do p
        @inbounds SVector(p.x*scale[1] + offset[1], p.y*scale[2] + offset[2], p.z*scale[3] + offset[3])
    end

    intensity = map(p -> p.intensity, points)
    returnnumber = map(p -> p.flag_byte_1 & 0b00001111, points)
    numberofreturns = map(p -> (p.flag_byte_1 & 0b11110000) >> 4, points)
    classification = map(p -> p.classification, points)
    pointsourceid = map(p -> p.pt_src_id, points)
    gpstime = map(p -> p.gps_time, points)
    userdata = map(p -> p.user_data, points)



    return Table(position = position,
                intensity = intensity,
                returnnumber = returnnumber,
                numberofreturns = numberofreturns,
                classification = classification,
                pointsourceid = pointsourceid,
                gpstime = gpstime,
                userdata = userdata)
end

function make_table(points::AbstractVector{LasPoint7}, offset, scale)
    position = map(points) do p
        @inbounds SVector(p.x*scale[1] + offset[1], p.y*scale[2] + offset[2], p.z*scale[3] + offset[3])
    end

    intensity = map(p -> p.intensity, points)
    returnnumber = map(p -> p.flag_byte_1 & 0b00001111, points)
    numberofreturns = map(p -> (p.flag_byte_1 & 0b11110000) >> 4, points)
    classification = map(p -> p.classification, points)
    pointsourceid = map(p -> p.pt_src_id, points)
    gpstime = map(p -> p.gps_time, points)
    userdata = map(p -> p.user_data, points)
    flagbyte2 = map(p -> p.flag_byte_2, points) # classification flags, scanner channel, scan direction flag, edge of flight line
    scanangle = map(p -> p.scan_angle, points)

    color = map(points) do p
        @inbounds RGB(p.red, p.green, p.blue)
    end



    return Table(position = position,
                 intensity = intensity,
                 returnnumber = returnnumber,
                 numberofreturns = numberofreturns,
                 classification = classification,
                 pointsourceid = pointsourceid,
                 gpstime = gpstime,
                 userdata = userdata,
                 color = color,
                 flagbyte2 = flagbyte2,
                 scanangle = scanangle)
end

function make_table(points::AbstractVector{LasPoint8}, offset, scale)
    position = map(points) do p
        @inbounds SVector(p.x*scale[1] + offset[1], p.y*scale[2] + offset[2], p.z*scale[3] + offset[3])
    end

    intensity = map(p -> p.intensity, points)
    returnnumber = map(p -> p.flag_byte_1 & 0b00001111, points)
    numberofreturns = map(p -> (p.flag_byte_1 & 0b11110000) >> 4, points)
    classification = map(p -> p.classification, points)
    pointsourceid = map(p -> p.pt_src_id, points)
    gpstime = map(p -> p.gps_time, points)
    userdata = map(p -> p.user_data, points)
    nir = map(p -> p.nir, points)
    flagbyte2 = map(p -> p.flag_byte_2, points) # classification flags, scanner channel, scan direction flag, edge of flight line
    scanangle = map(p -> p.scan_angle, points)

    color = map(points) do p
        @inbounds RGB(p.red, p.green, p.blue)
    end



    return Table(position = position,
                 intensity = intensity,
                 returnnumber = returnnumber,
                 numberofreturns = numberofreturns,
                 classification = classification,
                 pointsourceid = pointsourceid,
                 gpstime = gpstime,
                 userdata = userdata,
                 color = color,
                 nir = nir,
                 flagbyte2 = flagbyte2,
                 scanangle = scanangle)
end

# Saving

function save_pointcloud(filename::String, pc::AbstractVector{<:NamedTuple}; kwargs...)
    @info "Saving pointcloud to $filename"
    (_, ext) = splitext(filename)
    if lowercase(ext) == ".h5" || lowercase(ext) == ".hdf5"
        pc = save_h5(filename, pc; kwargs...)
    elseif lowercase(ext) == ".las" || lowercase(ext) == ".laz"
        pc = save_las(filename, pc; kwargs...)
    else
        error("No loader for file extension $ext")
    end

    @info "Successfully saved pointcloud to $filename"
    return pc
end

function save_h5(filename::AbstractString, pc::AbstractVector{<:NamedTuple}; format = nothing)
    if format isa AbstractString
        return save_h5_repo2(filename, pc; format = format)
    end

    h5open(filename, "w") do f_h # f_h = file handle
        cols = columns(pc)
        for jlname in propertynames(cols)
            if !haskey(ATTRIBUTE_PATH, jlname)
                @info "Not saving column: $jlname"
                continue
            end
            h5name = ATTRIBUTE_PATH[jlname]
            f_h[h5name] = data_to_h5(getproperty(cols, jlname), Val(jlname))
        end
    end
end

function save_h5_repo2(filename::AbstractString, pc::AbstractVector{<:NamedTuple}; format::AbstractString = "")
    if format == "" || !isascii(format)
        error("Need to specify point format - see `man ExtractPoints` for help")
    end

    h5open(filename, "w") do f_h
        points = Matrix{Float64}(undef, (length(format), length(pc)))
        n_attrs = 0

        for i in 1:length(format)
            if format[i] == 'X'
                points[i,:] .= (p -> p[1]).(pc.position)
                n_attrs += 1
            elseif format[i] == 'Y'
                points[i,:] .= (p -> p[2]).(pc.position)
                n_attrs += 1
            elseif format[i] == 'Z'
                points[i,:] .= (p -> p[3]).(pc.position)
                n_attrs += 1
            elseif format[i] == 'G'
                points[i,:] .= ((agl,p)->p[3]-agl).(pc.agl, pc.position)
                n_attrs += 1
            elseif format[i] == 'U'
                points[i,:] .= pc.clusterid
                n_attrs += 1
            elseif format[i] == 'R'
                points[i,:] .= pc.returnnumber
                n_attrs += 1
            elseif format[i] == 'P'
                points[i,:] .= pc.numberofreturns
                n_attrs += 1
            elseif format[i] == 'S'
                points[i,:] .= pc.flightstripid
                n_attrs += 1
            elseif format[i] == 'r'
                points[i, :] .= round.(255.0 .* red.(pc.color))   # Save 8 bit colors
                n_attrs += 1
            elseif format[i] == 'g'
                points[i, :] .= round.(255.0 .* green.(pc.color)) # Save 8 bit colors
                n_attrs += 1
            elseif format[i] == 'b'
                points[i, :] .= round.(255.0 .* blue.(pc.color))  # Save 8 bit colors
                n_attrs += 1
            elseif format[i] == 'I'
                points[i,:] .= pc.intensity
                n_attrs += 1
            end
        end

        if n_attrs != length(format)
            @warn "Some attribues in $format were ignored"
        end

        f_h["Points"] = points
    end
end

data_to_h5(v::AbstractVector{T}, ::Val) where {T} = convert(Vector{T}, v)

function data_to_h5(v::AbstractVector{<:StaticVector{n}}, ::Val) where {n}
    return [@inbounds(v[i][j]) for j in 1:n, i in firstindex(v):lastindex(v)]
end

function data_to_h5(v::AbstractVector{RGB{N0f8}}, ::Val) where {n}
    return [reinterpret(UInt8, getfield(@inbounds(v[i]), channel)) for channel in [:r, :g, :b], i in firstindex(v):lastindex(v)]
end

function data_to_h5(v::AbstractVector{RGB{N0f16}}, ::Val) where {n}
    return [reinterpret(UInt16, getfield(@inbounds(v[i]), channel)) for channel in [:r, :g, :b], i in firstindex(v):lastindex(v)]
end

function save_las(filename::AbstractString, pc::AbstractVector{<:NamedTuple}; x_scale = 0.001, y_scale = 0.001, z_scale = 0.001, global_encoding = UInt16(0), variable_length_records=[])
    # Get spatial bounds
    box = boundingbox(getproperty(:position).(pc))
    x_min = box.xmin
    y_min = box.ymin
    z_min = box.zmin
    x_max = box.xmax
    y_max = box.ymax
    z_max = box.zmax
    x_offset = x_scale * div((x_min + x_max) / 2, x_scale)
    y_offset = y_scale * div((y_min + y_max) / 2, y_scale)
    z_offset = z_scale * div((z_min + z_max) / 2, z_scale)

    records_count = length(pc)
    point_return_count = UInt32[0,0,0,0,0]
    extended_point_return_count = zeros(UInt64,15)
    if isempty(pc)
        data_format_id = 0
        data_record_length = 20
        data = LasPoint0[]
    else
        if haskey(first(pc), :nir)
            data_format_id = 8
            data_record_length = 38 # in bytes
            data = Vector{LasPoint8}(undef, records_count)
            @inbounds for i in 1:records_count
                p = pc[i]
                data[i] = laspoint8(p, x_offset, y_offset, z_offset, x_scale, y_scale, z_scale)
                if haskey(p, :returnnumber)
                    extended_point_return_count[min(p.returnnumber, length(extended_point_return_count))] += 1
                else
                    extended_point_return_count[1] += 1
                end
            end
        else
            if haskey(first(pc), :gpstime)
                if haskey(first(pc), :color)
                    if haskey(first(pc), :userdata) # Though user data is also present in point type 3 let's ue it as a differentiater for now
                        data_format_id = 7
                        data_record_length = 36 # in bytes
                        data = Vector{LasPoint7}(undef, records_count)
                        @inbounds for i in 1:records_count
                            p = pc[i]
                            data[i] = laspoint7(p, x_offset, y_offset, z_offset, x_scale, y_scale, z_scale)
                            if haskey(p, :returnnumber)
                                extended_point_return_count[min(p.returnnumber, length(extended_point_return_count))] += 1
                            else
                                extended_point_return_count[1] += 1
                            end
                        end
                    else
                        data_format_id = 3
                        data_record_length = 34
                        data = Vector{LasPoint3}(undef, records_count)
                        @inbounds for i in 1:records_count
                            p = pc[i]
                            data[i] = laspoint3(p, x_offset, y_offset, z_offset, x_scale, y_scale, z_scale)
                            if haskey(p, :returnnumber)
                                point_return_count[p.returnnumber] += 1
                            else
                                point_return_count[1] += 1
                            end
                        end
                    end
                else
                    if haskey(first(pc), :userdata)
                        data_format_id = 6
                        data_record_length = 30 # in bytes
                        data = Vector{LasPoint6}(undef, records_count)
                        @inbounds for i in 1:records_count
                            p = pc[i]
                            data[i] = laspoint6(p, x_offset, y_offset, z_offset, x_scale, y_scale, z_scale)
                            if haskey(p, :returnnumber)
                                point_return_count[min(p.returnnumber, length(point_return_count))] += 1
                            else
                                point_return_count[1] += 1
                            end
                        end
                    else
                        data_format_id = 1
                        data_record_length = 28
                        data = Vector{LasPoint1}(undef, records_count)
                        @inbounds for i in 1:records_count
                            p = pc[i]
                            data[i] = laspoint1(p, x_offset, y_offset, z_offset, x_scale, y_scale, z_scale)
                            if haskey(p, :returnnumber)
                                point_return_count[p.returnnumber] += 1
                            else
                                point_return_count[1] += 1
                            end
                        end
                    end
                end
            else
                if haskey(first(pc), :color)
                    data_format_id = 2
                    data_record_length = 26
                    data = Vector{LasPoint2}(undef, records_count)
                    @inbounds for i in 1:records_count
                        p = pc[i]
                        data[i] = laspoint2(p, x_offset, y_offset, z_offset, x_scale, y_scale, z_scale)
                        if haskey(p, :returnnumber)
                            point_return_count[p.returnnumber] += 1
                        else
                            point_return_count[1] += 1
                        end
                    end
                else
                    data_format_id = 0
                    data_record_length = 20
                    data = Vector{LasPoint0}(undef, records_count)
                    @inbounds for i in 1:records_count
                        p = pc[i]
                        data[i] = laspoint0(p, x_offset, y_offset, z_offset, x_scale, y_scale, z_scale)
                        if haskey(p, :returnnumber)
                            point_return_count[p.returnnumber] += 1
                        else
                            point_return_count[1] += 1
                        end
                    end
                end
            end
        end
    end
    version = data_format_id>3 ? 4 : 2
    header_size = UInt16(data_format_id>3 ? 375 : 227)
    t = now()
    header = LasIO.LasHeader(UInt16(0), # file_source_id
                             global_encoding, # global_encoding
                             UInt32(0), # guid_1
                             UInt16(0), # guid_2
                             UInt16(0), # guid_3
                             "", # guid_4
                             UInt8(1), # LAS version major
                             UInt8(version), # LAS version minor
                             "OTHER", # System
                             "ROAMES Julia writer", # Software
                             UInt16(dayofyear(t)), # creation_year
                             UInt16(year(t)), # creation_dayofyear
                             header_size, # header_size
                             UInt32(header_size+(!isempty(variable_length_records) ? sum(sizeof, variable_length_records) : 0)), # data_offset
                             UInt32(length(variable_length_records)), # n_vlr
                             UInt8(data_format_id), # data_format_id
                             UInt16(data_record_length), # data_format_id
                             UInt32(data_format_id>6 ? 0 : records_count),
                             point_return_count,
                             x_scale,
                             y_scale,
                             z_scale,
                             x_offset,
                             y_offset,
                             z_offset,
                             x_max,
                             x_min,
                             y_max,
                             y_min,
                             z_max,
                             z_min,
                             UInt64(0),
                             UInt64(0),
                             UInt32(0),
                             UInt64(data_format_id>6 ? records_count : 0),
                             extended_point_return_count,
                             variable_length_records,
                             []) #user_defined_bytes

    save(filename, header, data)
end

function laspoint6(p::NamedTuple, x_offset, y_offset, z_offset, x_scale, y_scale, z_scale)
    position = p.position
    @inbounds x = round(Int32, (position[1] - x_offset) / x_scale)
    @inbounds y = round(Int32, (position[2] - y_offset) / y_scale)
    @inbounds z = round(Int32, (position[3] - z_offset) / z_scale)
    intensity = haskey(p, :intensity) ? convert(UInt16, p.intensity) : 0x0000
    flagbyte1 = (haskey(p, :numberofreturns) ? convert(UInt8, p.numberofreturns) << 4 : 0x10) | (haskey(p, :returnnumber) ? convert(UInt8, p.returnnumber) : 0x01)
    classification = haskey(p, :classification) ? convert(UInt8, p.classification) : 0x00
    scan_angle = 0x00
    user_data = haskey(p, :userdata) ? p.userdata : 0x00
    pt_src_id = haskey(p, :pointsourceid) ? convert(UInt16, p.pointsourceid) : 0x0000
    gps_time = haskey(p, :gpstime) ? convert(Float64, p.gpstime) : 0.0

    return LasPoint6(x, y, z, intensity, flagbyte1, 0x00, classification, user_data, scan_angle, pt_src_id, gps_time)
end

function laspoint7(p::NamedTuple, x_offset, y_offset, z_offset, x_scale, y_scale, z_scale)
    position = p.position
    @inbounds x = round(Int32, (position[1] - x_offset) / x_scale)
    @inbounds y = round(Int32, (position[2] - y_offset) / y_scale)
    @inbounds z = round(Int32, (position[3] - z_offset) / z_scale)
    intensity = haskey(p, :intensity) ? convert(UInt16, p.intensity) : 0x0000
    flagbyte1 = (haskey(p, :numberofreturns) ? convert(UInt8, p.numberofreturns) << 4 : 0x10) | (haskey(p, :returnnumber) ? convert(UInt8, p.returnnumber) : 0x01)
    classification = haskey(p, :classification) ? convert(UInt8, p.classification) : 0x00
    scan_angle = haskey(p, :scanangle) ? p.scanangle : 0x00
    user_data = haskey(p, :userdata) ? p.userdata : 0x00
    pt_src_id = haskey(p, :pointsourceid) ? convert(UInt16, p.pointsourceid) : 0x0000
    gps_time = haskey(p, :gpstime) ? convert(Float64, p.gpstime) : 0.0
    red = haskey(p, :color) ? convert(N0f16, p.color.r) : 0N0f16
    green = haskey(p, :color) ? convert(N0f16, p.color.g) : 0N0f16
    blue = haskey(p, :color) ? convert(N0f16, p.color.b) : 0N0f16
    flagbyte2 =  haskey(p, :flagbyte2) ? p.flagbyte2 : 0x00

    return LasPoint7(x, y, z, intensity, flagbyte1, flagbyte2, classification, user_data, scan_angle, pt_src_id, gps_time, red, green, blue)
end

function laspoint8(p::NamedTuple, x_offset, y_offset, z_offset, x_scale, y_scale, z_scale)
    position = p.position
    @inbounds x = round(Int32, (position[1] - x_offset) / x_scale)
    @inbounds y = round(Int32, (position[2] - y_offset) / y_scale)
    @inbounds z = round(Int32, (position[3] - z_offset) / z_scale)
    intensity = haskey(p, :intensity) ? convert(UInt16, p.intensity) : 0x0000
    flagbyte1 = (haskey(p, :numberofreturns) ? convert(UInt8, p.numberofreturns) << 4 : 0x10) | (haskey(p, :returnnumber) ? convert(UInt8, p.returnnumber) : 0x01)
    classification = haskey(p, :classification) ? convert(UInt8, p.classification) : 0x00
    scan_angle = haskey(p, :scanangle) ? p.scanangle : 0x00
    user_data = haskey(p, :userdata) ? p.userdata : 0x00
    pt_src_id = haskey(p, :pointsourceid) ? convert(UInt16, p.pointsourceid) : 0x0000
    gps_time = haskey(p, :gpstime) ? convert(Float64, p.gpstime) : 0.0
    red = haskey(p, :color) ? convert(N0f16, p.color.r) : 0N0f16
    green = haskey(p, :color) ? convert(N0f16, p.color.g) : 0N0f16
    blue = haskey(p, :color) ? convert(N0f16, p.color.b) : 0N0f16
    nir = haskey(p, :nir) ? convert(N0f16, p.nir) : 0N0f16
    flagbyte2 =  haskey(p, :flagbyte2) ? p.flagbyte2 : 0x00

    return LasPoint8(x, y, z, intensity, flagbyte1, flagbyte2, classification, user_data, scan_angle, pt_src_id, gps_time, red, green, blue, nir)
end

function laspoint3(p::NamedTuple, x_offset, y_offset, z_offset, x_scale, y_scale, z_scale)
    position = p.position
    @inbounds x = round(Int32, (position[1] - x_offset) / x_scale)
    @inbounds y = round(Int32, (position[2] - y_offset) / y_scale)
    @inbounds z = round(Int32, (position[3] - z_offset) / z_scale)
    intensity = haskey(p, :intensity) ? convert(UInt16, p.intensity) : 0x0000
    flagbyte = (haskey(p, :numberofreturns) ? convert(UInt8, p.numberofreturns) << 3 : 0x08) | (haskey(p, :returnnumber) ? convert(UInt8, p.returnnumber) : 0x01)
    raw_classification = haskey(p, :classification) ? convert(UInt8, p.classification) : 0x00
    scan_angle = 0x00
    # user_data = haskey(p, :userdata) ? p.userdata : 0x00
    user_data = 0x00
    pt_src_id = haskey(p, :pointsourceid) ? convert(UInt16, p.pointsourceid) : 0x0000
    gps_time = haskey(p, :gpstime) ? convert(Float64, p.gpstime) : 0.0
    red = haskey(p, :color) ? convert(N0f16, p.color.r) : 0N0f16
    green = haskey(p, :color) ? convert(N0f16, p.color.g) : 0N0f16
    blue = haskey(p, :color) ? convert(N0f16, p.color.b) : 0N0f16

    return LasPoint3(x, y, z, intensity, flagbyte, raw_classification, scan_angle, user_data, pt_src_id, gps_time, red, green, blue)
end

function laspoint2(p::NamedTuple, x_offset, y_offset, z_offset, x_scale, y_scale, z_scale)
    position = p.position
    @inbounds x = round(Int32, (position[1] - x_offset) / x_scale)
    @inbounds y = round(Int32, (position[2] - y_offset) / y_scale)
    @inbounds z = round(Int32, (position[3] - z_offset) / z_scale)
    intensity = haskey(p, :intensity) ? convert(UInt16, p.intensity) : 0x0000
    flagbyte = (haskey(p, :numberofreturns) ? convert(UInt8, p.numberofreturns) << 3 : 0x08) | (haskey(p, :returnnumber) ? convert(UInt8, p.returnnumber) : 0x01)
    raw_classification = haskey(p, :classification) ? convert(UInt8, p.classification) : 0x00
    scan_angle = 0x00
    user_data = 0x00
    pt_src_id = haskey(p, :pointsourceid) ? convert(UInt16, p.pointsourceid) : 0x0000
    red = haskey(p, :color) ? convert(N0f16, p.color.r) : 0N0f16
    green = haskey(p, :color) ? convert(N0f16, p.color.g) : 0N0f16
    blue = haskey(p, :color) ? convert(N0f16, p.color.b) : 0N0f16

    return LasPoint2(x, y, z, intensity, flagbyte, raw_classification, scan_angle, user_data, pt_src_id, red, green, blue)
end

function laspoint1(p::NamedTuple, x_offset, y_offset, z_offset, x_scale, y_scale, z_scale)
    position = p.position
    @inbounds x = round(Int32, (position[1] - x_offset) / x_scale)
    @inbounds y = round(Int32, (position[2] - y_offset) / y_scale)
    @inbounds z = round(Int32, (position[3] - z_offset) / z_scale)
    intensity = haskey(p, :intensity) ? convert(UInt16, p.intensity) : 0x0000
    flagbyte = (haskey(p, :numberofreturns) ? convert(UInt8, p.numberofreturns) << 3 : 0x08) | (haskey(p, :returnnumber) ? convert(UInt8, p.returnnumber) : 0x01)
    raw_classification = haskey(p, :classification) ? convert(UInt8, p.classification) : 0x00
    scan_angle = 0x00
    user_data = 0x00
    pt_src_id = haskey(p, :pointsourceid) ? convert(UInt16, p.pointsourceid) : 0x0000
    gps_time = haskey(p, :gpstime) ? convert(Float64, p.gpstime) : 0.0

    return LasPoint1(x, y, z, intensity, flagbyte, raw_classification, scan_angle, user_data, pt_src_id, gps_time)
end

function laspoint0(p::NamedTuple, x_offset, y_offset, z_offset, x_scale, y_scale, z_scale)
    position = p.position
    @inbounds x = round(Int32, (position[1] - x_offset) / x_scale)
    @inbounds y = round(Int32, (position[2] - y_offset) / y_scale)
    @inbounds z = round(Int32, (position[3] - z_offset) / z_scale)
    intensity = haskey(p, :intensity) ? convert(UInt16, p.intensity) : 0x0000
    flagbyte = (haskey(p, :numberofreturns) ? convert(UInt8, p.numberofreturns) << 3 : 0x08) | (haskey(p, :returnnumber) ? convert(UInt8, p.returnnumber) : 0x01)
    raw_classification = haskey(p, :classification) ? convert(UInt8, p.classification) : 0x00
    scan_angle = 0x00
    user_data = 0x00
    pt_src_id = haskey(p, :pointsourceid) ? convert(UInt16, p.pointsourceid) : 0x0000

    return LasPoint0(x, y, z, intensity, flagbyte, raw_classification, scan_angle, user_data, pt_src_id)
end
