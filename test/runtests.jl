using JuliennedArrays
using Test
using Documenter: doctest

@testset "JuliennedArrays.jl" begin
    @testset "Align" begin
        Xs = [rand(2, 3) for _ in 1:4]
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

        @test_throws ArgumentError("(1,) is not of length inner dimensions (2).") Align(
            [rand(2, 3) for _ in 1:4],
            1,
        )
        @test_throws MethodError Align(ones(2, 3, 4), 1, 2, 3)

        @test size(Align(Slices(Slices(randn(3, 4, 5, 2), 3), 3), 3)) == (3, 4, 2)
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
        @test_throws ArgumentError(
            "5, a dimension number, is out of bounds or out of order.",
        ) Slices(X, 5)
        @test_throws ArgumentError("-1, a dimension number, is out of bounds or out of order.") Slices(X, -1)

        empties = [rand(3) for _ in 1:0]
        @test_throws BoundsError(Vector{Float64}[], (1,)) Align(empties, True(), False())
        @test size(Align(empties, True(), False(); slice_axes = axes(rand(3)))) == (3, 0)
        @test_throws BoundsError(Vector{Float64}[], (1,)) Align(empties, 1)
        @test size(Align(empties, 1; slice_axes = axes(rand(3)))) == (3, 0)
    end
end

if VERSION >= v"1.6"
    doctest(JuliennedArrays)
end
