# RoamesGeometry

*Primitive geometric objects for Roames modelling.*

## Overview

This package provides a set of geometric primitives and containers for modelling objects
in the physical world.

### Points

The basic geometric point is 2D and 3D real, static vectors, like `SVector{2, Float64}`
or `SVector{3, Float32}`. The `convert2d` and `convert3d` functions can be used to
"upgrade" or "downgrade" dimensionality of points and other geometries.

There is functionality for loading and saving of pointclouds in either LAS or "Roames"
HDF5 formats via `load_pointcloud(filename)` and `save_pointcloud(filename, pointcloud)`.

Generally, in Julia v1.0 onwards a point cloud is represented as a `Table` from
[*TypedTables.jl*](https://github.com/FugroRoames/TypedTables.jl) where the `position`
column contains 3D points. For an introduction to using *TypedTables* see the 
[user guide](https://fugroroames.github.io/TypedTables.jl/latest/). Common manipulations on point
clouds are shown below.

### Geometries

*RoamesGeometry* supports a collection of 2D and 3D geometry types, common to many
geospatial formats including ShapeFiles and Well-Known Text. Currently, we support:

 * `BoundingBox` - a 3D region of space; an axis-aligned bounding box
 * `Line` - a segment connecting two points
 * `LineString` - a contiguous set of touching lines
 * `Quadratic` - a quadratic function that supports "wind blown" wires
 * `Catenary` - a vertically hanging catenary
 * `Polygon` - a closed polygon (in the 2D sense), possibly with interior holes
 * `Sphere` - a uniform sphere centered at a point with given radius
 * `Circle` - a 2D circle
 * `Cylinder` - A circle with min/max height
 * `Triangle` - a three-sided polygon
 * `TriangularPrism` - A triangle with min/max height

Generally, they can be transformed by a `Transformation` and can be plotted in Displaz
via the `plot3d` function.

#### `AbstractRegion` and finding points

Some of these encompass 2D or 3D [regions](https://en.wikipedia.org/wiki/Region_(mathematics)),
and are subtypes of `AbstractRegion`. Regions are defined mathematically as open, connected
and non-empty sets (or the closure thereof) and can support the `in` function (alternatitvely
written `in(point, region)`, `point in region` or `point ∈ region`).

For example, to ask the question if a point is inside a `Sphere`, one could write
`in(point, Sphere(centre, radius))`. The `in` function supports "currying", so that
`f = in(Sphere(centre, radius))` is a function where `f(point)` returns `true` or
`false` depending on whether `point` is in the `Sphere` or not. The predicate function
`f` can then be used in higher order functions like `map`, `filter` and `findall` for
filtering to just the points inside the `Sphere`.

To see this in action, given a `pointcloud` with a `position` column, we can construct
a new pointcloud containing just the points inside a `Sphere`.

```julia
indices = findall(in(Sphere(centre, radius)), pointcloud.position)
pointcloud2 = pc[indices]
```

The `findall` function returns the indices of the elements matching a given predicate.

#### Lines and one-dimensional containers

Generally, points along one-dimensional primitives can be extracted via `getindex`, such as:

```julia
l = Line(SVector(0.0, 0.0, 0.0), SVector(2.0, 0.0, 0.0))
l[0.5] == SVector(0.5, 0.0, 0.0)
```

Note: geometries like `Line` can naturally be thought of as a collection of points, but
they are not a region in the mathematic sense and calculation of `point in line` is not
stable to e.g. floating-point rounding errors.

#### `BoundingBox`

Bounding box represents an axis-aligned rectangular prism and is an `AbstractRegion`.
Its primary use is as a spatial acceleration structure, to check whether two objects
lie within the same bounding box as an efficient pre-filtering step.

It supports the following interface:

 * The `boundingbox` function is the primary constructor. You can call
   `boundingbox` with an arbitrary collection of geometries and a bounding box
   guaranteed to hold all the geometry is returned. Typically, it will be the
   smallest such bounding box. E.g. `boundingbox(catenary, quadratic, line, point)`
   or `boundingbox(points::Vector{SVector{3,Float64}})`.
 * The `in` (or `∈`) function/operator can indicate whether a point is within
   the bounding box, e.g. `point ∈ box`.
 * The `pad` function extends the bounding box by a given amount, e.g. `pad(bb, 1.0)`.
 * The `intersects` function returns `true` if two bounding boxes interect, and
   `false` otherwise.
 * The `wireframe` function returns the 12 lines outlining the box, as a
   `Vector{Line{T}}`.
 * `Displaz.plot3d` can plot the wireframe of a bounding box directly.

### Spatial acceleration using `GridIndex`

Spatial acceleration is used to speed up queries, like finding all the points within
an `AbstractRegion`. A `GridIndex` is used to perform spatial acceleration on
point cloud data of a "2.5 dimensional" nature - meaning points widely distributed
in *x* and *y*, with a relatively few points in a given vertical column, such as
those typical to aerial LiDAR.

A `GridIndex` tracks the points within each cell of an x-y grid of a given spacing,
and furthermore orders them by height within the grid cell. This "index" can be
used to make certain operations faster, for example to find all the points in
a given region. Roughly speaking, given an `AbstractRegion` called `region`,
spatial acceleration will

 * Find `bb = boundingbox(region)`.
 * Use the grid to only search grid cells that intersect with `bb`.
 * For each point in these cells, check precisely whether they are inside `region`.

That way, queries will skip the vast majority of points and the spatial index will make
a tremendous performance improvement, often changing algorithms like PCA from
*O(n²)* to *O(n log n)* or similar.

Acceleration indices are managed through the
[*AcceleratedArrays.jl*](https://github.com/andyferris/AcceleratedArrays.jl) package.
This package provides basic acceleration indices (like `HashIndex` and `SortIndex`)
and is extended by *RoamesGeometry* to include `GridIndex`. An acceleration index
is added to an array like so:

```julia
position = accelerate(position, GridIndex; spacing = 1.0)
```

Note that this has *not* mutated the original `position` array - rather it has created a
new `AcceleratedArray` which wraps the old one. (Warning: mutating the positions will
corrupt the index, meaning the results from `findall` and so-on will be incorrect).

For performance critical applications, one can re-order the array to be more cache-friendly
and reduce lookups using the `accelerate!` function. If you do this to a point cloud,
note the order of the other columns will *not* be modified, so the indices will get out
of sync.

### Distances

The distance between various geometries can be found. The `distance` function
returns the (smallest) Euclidean distance between two geometric objects, and
is currently defined between points and catenaries only. The `closest_point`
and `closest_points` functions return the closest point(s) between geometries.

#### Distance to catenaries

The `powerline_distances(catenary, point)` function returns `(dist, r, z, d)`,
where:

 * `dist` is the Euclidean distance to the closest point on the catenary.
 * `r` is the horizontal distance perpendicular to the catenary.
 * `z` is the height difference between the point and the catenary.
 * `d` is the distance along the catenary, the end points being at
   `catenary.lmin` and `catenary.lmax`.

### Input and Output

#### Well-known text

Input and output operations for well-known text is provided via the following functions:

 * `wkt(geometry)` returns a `String` containing a well-known text representation of `geometry`.
 * `read_wkt(string)` parses a WKT string and returns a geometry.
 * `load_wkt(filename)` opens a well-known text file and reads a geometry.
 * `save_wkt(filename, geometry)` saves `geometry` into a well-known text file.
 * The lower-level operations `read_wkt(io)` and `write_wkt(io, geometry)` act on `IO` streams.

#### Point clouds

The `load_pointcloud(filename)` function can open `.las` and `.h5` as a `Table`. To add
a spatial acceleration `GridIndex` to the pointcloud, you must specify a grid spacing
via `load_pointcloud(filename, spacing = 1.0)` (for a 1 metre grid). It is important to
add the spatial index whenever you plan to make spatial queries, for example neighborhood
search for noise filtering or PCA-based tasks.

The `save_pointcloud(filename, pointcloud)` function is able to save `.las` and `.h5`
files.

Both support GeoRepo2-style HDF5 files generated by `ExtractPoints` by specifying the
relevant `format` string, e.g. `load_pointcloud(filename, format = "XYZIrgb")`.

## Example

To get started, consider this example where we combine the features of this library
to classify points depending on whether they are inside a geometry or not, from files
on disk.

```julia
using RoamesGeometry

pc = load_pointcloud("pointcloud.h5"; spacing = 1.0)
geom = load_wkt("geometry.wkt")

pc.classification .= 0
pc.classification[findall(in(geom)), pc.position)] .= 1

save_pointcloud("pointcloud2.h5", pc)
```