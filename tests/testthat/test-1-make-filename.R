context("make_filename")

test_that("filename is character", {
  expect_is(make_filename(2013), "character")
})

test_that("filename is formatted correctly", {
  expect_match(make_filename(2013), "accident_2013\\.csv\\.bz2")
})