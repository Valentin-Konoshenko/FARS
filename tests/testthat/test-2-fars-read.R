context("fars_read")

test_that("a class of read data is tbl_df", {
  a <- fars_read(make_filename(2013))
  expect_is(a, "tbl_df")
})

test_that("the erros is thrown if a file does not exist", {
  expect_error(fars_read("absent_file"), "does not exist")
})
