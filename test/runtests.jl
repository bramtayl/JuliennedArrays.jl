using JuliennedArrays
using Test
using Documenter: doctest

if VERSION >= v"1.6"
    doctest(JuliennedArrays)
end

@testset "JuliennedArrays.jl" begin
    @testset "Align" begin
        Xs = [rand(2, 3) for _ = 1:4]
        X = @inferred Align(Xs, True(), False(), True())
        @test size(X) == (2, 4, 3)
        @test permutedims(cat(Xs...; dims = 3), (1, 3, 2)) == X
        @test X[1] == Xs[1][1] # test linear indexing
        @test X[1, 2, 3] == Xs[2][1, 3] # test cartesian indexing

        Xs = reshape(Xs, 1, 4)
        X = @inferred Align(Xs, True(), False(), True(), False())
        @test size(X) == (2, 1, 3, 4)
        @test permutedims(X, (1, 3, 2, 4))[:] == cat(Xs...; dims = 3)[:]

        # type is inferrable for constant integer alongs
        align_1_3(x) = Align(x, 1, 3)
        @inferred align_1_3(Xs)

        @test_throws DimensionMismatch Align([rand(2, 3) for _ in 1:4], 1)
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

        # type is inferrable for constant integer alongs
        slices_1_3(x) = Slices(x, 1, 3)
        @inferred slices_1_3(X)

        X = rand(2, 3, 4, 5)
        @test_throws MethodError Slices(X, True())
        @test_throws MethodError Slices(X, True(), False(), False(), False(), False())
        @test_throws ArgumentError("All alongs values (5,) should be less than or equal to 4") Slices(X, 5)
    end
end
