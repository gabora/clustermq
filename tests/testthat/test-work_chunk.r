context("work_chunk")

df = Q_call_index(iter = list(
    a = 1:3,
    b = as.list(letters[1:3]),
    c = setNames(as.list(3:1), letters[1:3])
))

test_that("data types and arg names", {
    fx = function(c, a, b) a + c
    expect_equal(work_chunk(df, fx), as.list(rep(4,3)))
})

test_that("check call classes", {
    df2 = df
    df2$a = list(matrix(1:4, nrow=2))
    fx = function(...) sapply(list(...), class)

    re = setNames(c("matrix", "character", "integer"), c("a", "b", "c"))
    expect_equal(work_chunk(df2, fx), rep(list(re), 3))
})

test_that("do not unlist matrix in data.frame", {
    elm = structure(1:4, .Dim = c(2,2), .Dimnames=list(c("r1","r2"), c("c1","c2")))
	df2 = structure(list(expr = structure(list(expr = elm))),
	.Names = "expr", row.names = c(NA, -1L), class = "data.frame")

	fx = function(...) list(...)
	expect_equal(work_chunk(df2, fx)[[1]], list(expr=elm))
})

test_that("try-error", {
    fx = function(a, ...) {
        if (a %% 2 == 0)
            stop("error")
        else
            a
    }

    re = work_chunk(df, fx)
    expect_equal(class(re[[2]]), "try-error")
    expect_equal(re[[1]], 1)
    expect_equal(re[[3]], 3)
})

test_that("const args", {
    fx = function(a, ..., x=23) a + x

    re = work_chunk(df, fx, const=list(x=5))
    expect_equal(re, as.list(df$a + 5))
})

test_that("seed reproducibility", {
    fx = function(a, ...) sample(1:1000, 1)
    
    # seed should be set by common + df row name
    expect_equal(work_chunk(df[1:2,], fx, common_seed=123)[2],
                 work_chunk(df[2:3,], fx, common_seed=123)[1])
})

test_that("env separation", {
    seed = 123
    fx = function(x, common_seed=seed) {
        fun = function(x) stop("overwrite function")
        df = data.frame()
        common_seed
    }
    df2 = Q_call_index(iter=list(x=1:5))
    expect_equal(work_chunk(df2, fx), rep(list(seed), 5))
})
