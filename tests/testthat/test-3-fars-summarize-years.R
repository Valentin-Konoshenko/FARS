context("fars_summarize_years")

test_that("set of columns is correct", {
  a <- fars_summarize_years(c(2013, 2014))
  expect_equivalent(colnames(a), c("MONTH", "2013", "2014"))
})

test_that("number of rows is correct", {
  expect_equivalent(nrow(fars_summarize_years(2013)), 12)
})

test_that("one of the values is correct", {
  a <- fars_summarize_years(2013)
  expect_equivalent(unlist(a[1, 2]), 2230)
})