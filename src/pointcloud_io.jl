function load_pointcloud(filename::AbstractString; kwargs...)
    @info "Loading pointcloud from $filename"
    (_, ext) = splitext(filename)
    if lowercase(ext) == ".las" || lowercase(ext) == ".laz"
        pc = load_las(filename; kwargs...)
    else
        error("No loader for file extension $ext")
    end

    @info "Successfully loaded pointcloud from $filename"
    return pc
end

function load_las(filename::AbstractString; spacing = nothing)
    (header, points) = load(filename)

    pointcloud = make_table(points,
                            SVector(header.x_offset, header.y_offset, header.z_offset),
                            SVector(header.x_scale, header.y_scale, header.z_scale))

    if spacing === nothing
        return pointcloud
    else
        return Table(merge(columns(pointcloud), (position = accelerate(pointcloud.position, GridIndex; spacing = spacing),)))
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
                 color = color)
end


# Saving

function save_pointcloud(filename::String, pc::AbstractVector{<:NamedTuple}; kwargs...)
    @info "Saving pointcloud to $filename"
    (_, ext) = splitext(filename)
    if lowercase(ext) == ".las" || lowercase(ext) == ".laz"
        pc = save_las(filename, pc; kwargs...)
    else
        error("No loader for file extension $ext")
    end

    @info "Successfully saved pointcloud to $filename"
    return pc
end

function save_las(filename::AbstractString, pc::AbstractVector{<:NamedTuple}; x_scale = 0.001, y_scale = 0.001, z_scale = 0.001)
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

    records_count = Int32(length(pc))
    point_return_count = UInt32[0,0,0,0,0]
    if isempty(pc)
        data_format_id = 0
        data_record_length = 20
        data = LasPoint0[]
    else
        if haskey(first(pc), :gpstime)
            if haskey(first(pc), :color)
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

    t = now()
    header = LasIO.LasHeader(0, # file_source_id
                             0, # global_encoding
                             0, # guid_1
                             0, # guid_2
                             0, # guid_3
                             "", # guid_4
                             1, # LAS version major
                             2, # LAS version minor
                             "OTHER", # System
                             "ROAMES Julia writer", # Software
                             dayofyear(t), # creation_year
                             year(t), # creation_dayofyear
                             227, # header_size
                             227, # data_offset
                             0, # n_vlr
                             data_format_id, # data_format_id
                             data_record_length, # data_format_id
                             records_count, 
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
                             [], #variable_length_records
                             []) #user_defined_bytes

    save(filename, header, data)
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
