using JuliennedArrays
using Test

@testset "JuliennedArrays.jl" begin
    @testset "Align" begin
        Xs = [rand(2, 3) for _ in 1:4]
        X = @inferred Align(Xs, True(), False(), True())
        @test size(X) == (2, 4, 3)
        @test permutedims(cat(Xs...; dims=3), (1, 3, 2)) == X
        @test X[1] == Xs[1][1] # test linear indexing
        @test X[1, 2, 3] == Xs[2][1, 3] # test cartesian indexing

        Xs = reshape(Xs, 1, 4)
        X = @inferred Align(Xs, True(), False(), True(), False())
        @test size(X) == (2, 1, 3, 4)
        @test permutedims(X, (1, 3, 2, 4))[:] == cat(Xs...; dims=3)[:]

        # type is not inferrable for integer alongs
        Xs = [rand(2, 3) for _ in 1:4]
        RT = Base.return_types(Align, (typeof(Xs), Int, Int))[1]
        @test !isconcretetype(RT)
        @test Align(Xs, True(), False(), True()) == Align(Xs, 1, 3)

        @test_throws ArgumentError Align([rand(2, 3), rand(3, 4)], 2, 3)
        @test_throws DimensionMismatch Align([rand(2, 3) for _ in 1:4], 1) # issue #25
        @test_throws MethodError Align(ones(2, 3, 4), 1, 2, 3)
    end

    @testset "Slice" begin
        X = rand(2, 3, 4, 5)
        Xs = @inferred Slices(X, True(), False(), False(), False())

        Xs = Slices(X, 1)
        @test size(Xs) == (3, 4, 5)
        @test Xs[1, 1, 1] == X[:, 1, 1, 1]

        Xs = Slices(X, 2)
        @test size(Xs) == (2, 4, 5)
        @test Xs[1, 1, 1] == X[1, :, 1, 1]

        Xs = Slices(X, 1, 3)
        @test size(Xs) == (3, 5)
        @test Xs[1, 2] == X[:, 1, :, 2]
        @test Align(Xs, 1, 3) == X # Slices is the inverse of Align
        @test Xs[1] == X[:, 1, :, 1] # test linear indexing
        @test Xs[1, 3] == X[:, 1, :, 3] # test cartesian indexing

        # type is not inferrable for integer alongs
        RT = Base.return_types(Slices, (typeof(X), Int, Int))[1]
        @test !isconcretetype(RT)
        @test Slices(X, True(), False(), True(), False()) == Slices(X, 1, 3)

        X = rand(2, 3, 4, 5)
        @test_throws ArgumentError Slices(X, True())
        @test_throws ArgumentError Slices(X, True(), False(), False(), False(), False())
        @test_throws ArgumentError Slices(X, 5)
    end
end
