@testset "IO LAS PointCloud" begin
    filename = joinpath(tempdir(), "test_pc.las")

    try
        N = 1000
        pos = rand(SVector{3,Float32}, N)
        int = rand(UInt16, N)
        class = zeros(Int, N)
        colors = rand(RGB{N0f8}, N)
        
        pc = Table(position = pos, intensity = int, classification = class, color = colors)
        save_pointcloud(filename, pc)
        pc2 = load_pointcloud(filename; spacing = 0.1)
        @test all(((p1, p2),) -> isapprox(p1, p2; atol = 1e-3), zip(pc.position, pc2.position))
        @test pc2.intensity == pc.intensity
        @test pc2.classification == pc.classification
        @test pc2.color == pc.color
        @test pc2.position isa AcceleratedArray

        colors2 = rand(RGB{N0f16}, N)
        pc = Table(position = pos, intensity = int, classification = class, color = colors2)
        save_pointcloud(filename, pc)
        pc2 = load_pointcloud(filename)
        @test all(((p1, p2),) -> isapprox(p1, p2; atol = 1e-3), zip(pc.position, pc2.position))
        @test pc2.intensity == pc.intensity
        @test pc2.classification == pc.classification
        @test pc2.color == pc.color
        @test !(pc2.position isa AcceleratedArray)

        pc = empty(pc)
        save_pointcloud(filename, pc)
        pc2 = load_pointcloud(filename)
        @test pc2.position == pc.position
        @test pc2.intensity == pc.intensity
        @test pc2.classification == pc.classification
        @test_broken pc2.color == pc.color # empty point cloud defaults to point type 0, should fix at some point
    finally
        rm(filename, force=true)
    end
end
