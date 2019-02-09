struct Dummy{T} <: AbstractRegion{T}
end

@testset "AbstractRegion" begin
    @test_throws ErrorException SVector(0.0, 0.0, 0.0) ∈ Dummy{Float64}()
    @test_throws ErrorException boundingbox(Dummy{Float64}())
end