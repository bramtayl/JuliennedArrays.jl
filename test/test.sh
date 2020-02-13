if test "$TRAVIS_JULIA_VERSION" = "1.0"
    then julia --code-coverage=user test/test.jl
    else julia --code-coverage=tracefile-%p.info --code-coverage=user test/test.jl
fi
