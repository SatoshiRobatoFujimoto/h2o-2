
setwd(normalizePath(dirname(R.utils::commandArgs(asValues=TRUE)$"f")))
source('../../findNSourceUtils.R')

# library(h2o)
# library(testthat)
# h2o.setLogPath(getwd(), "Command")
# h2o.setLogPath(getwd(), "Error")
# h2o.startLogging()
# conn = h2o.init()


test.pub.668 <- function(conn) {

    a_initial = as.data.frame(cbind(
    c(0,0,1,0,0,1,0,0,0,0),
    c(1,1,1,0,1,0,1,0,1,0),
    c(1,0,1,0,1,0,1,0,0,1),
    c(1,1,0,0,0,1,0,0,0,1),
    c(1,1,1,0,1,0,0,0,1,1),
    c(1,0,1,0,0,0,0,0,1,1),
    c(1,1,1,0,0,0,1,1,1,0),
    c(0,0,1,1,1,0,0,1,1,0),
    c(0,1,1,1,1,0,0,1,1,0),
    c(0,0,0,0,0,1,1,0,0,0)
    ))


    a = a_initial
    a.h2o <- as.h2o(conn, a_initial, key="r.hex")
    d0 = apply(a.h2o, 2, sum)
    d = ifelse(F, a.h2o[1,] , d0)
    dd = ifelse(F, a[1,] , apply(a, 2, sum))
    a.h2o.R = as.matrix(a.h2o)
    a
    a.h2o.R
    expect_that(all(a == a.h2o.R), equals(T))
    expect_that(all(d == dd), equals(T))


    a = a_initial
    a.h2o <- as.h2o(conn, a_initial, key="r.hex")
    d0 = apply(a.h2o, 2, sum)
    d = ifelse(F, a.h2o[1,] , apply(a.h2o, 2, sum))
    dd = ifelse(F, a[1,] , apply(a, 2, sum))
    a.h2o.R = as.matrix(a.h2o)
    a
    a.h2o.R
    expect_that(all(a == a.h2o.R), equals(T))
    expect_that(all(d == dd), equals(T))


    a = a_initial
    a.h2o <- as.h2o(conn, a_initial, key="r.hex")
    d = ifelse(F, a.h2o[1,] , 0)
    dd = ifelse(F, a[1,] , 0)
    a.h2o.R = as.matrix(a.h2o)
    a
    a.h2o.R
    expect_that(all(a == a.h2o.R), equals(T))
    expect_that(all(d == dd), equals(T))


    a = a_initial
    a.h2o <- as.h2o(conn, a_initial, key="r.hex")
    d = ifelse(FALSE, a.h2o[1,] , apply(a.h2o,2,sum)); g = ifelse(FALSE, 1.23<2.34 , min(1,2))
    dd = ifelse(FALSE, a[1,] , apply(a,2,sum)); gg = ifelse(FALSE, 1.23<2.34, min(1,2))
    a.h2o.R = as.matrix(a.h2o)
    a
    a.h2o.R
    expect_that(all(a == a.h2o.R), equals(T))
    expect_that(all(d == dd), equals(T))


    testEnd()
}

doTest("Test for pub-668.", test.pub.668)

