#' Read a FARS data file
#'
#' The function accepts the filename (using \code{filename} parameter)
#' of the file containing FARS data for a year to process,
#' checks if the file exists, and returns its data.
#' For more information about FARS data, see
#' \href{https://www.nhtsa.gov/research-data/fatality-analysis-reporting-system-fars}{Fatality Analysis Reporting System}.
#'
#' @param filename A name of the file to read (either a single string or a raw vector).
#'  Please use the \code{\link{make_filename}} function to get a correct file name.
#'
#' @return Returns a tibble containing the FARS data loaded from the source file
#'  (or the several source files).
#'
#' @importFrom dplyr tbl_df
#' @importFrom readr read_csv
#'
#' @examples
#' data2013 <- fars_read("accident_2013.csv.bz2")
#'
#' @export
fars_read <- function(filename) {
  if(!file.exists(filename))
    stop("file '", filename, "' does not exist")
  data <- suppressMessages({
    readr::read_csv(filename, progress = FALSE)
  })
  dplyr::tbl_df(data)
}

#' Get the name of the file containing FARS data for a specific year
#'
#' The function returns the name of the data file
#' containing FARS data for a year of interest (defined using \code{year} argument).
#' For more information about FARS data, see
#' \href{https://www.nhtsa.gov/research-data/fatality-analysis-reporting-system-fars}{Fatality Analysis Reporting System}.
#'
#' @param year An atomic numeric value, which can be coerced to four-digit integer
#'  representing a year to process.
#'
#' @return It returns the name of the file containing the FARS data of the year.
#'
#' @examples
#' FileName2013 <- make_filename(2013)
#'
#' @export
make_filename <- function(year) {
  year <- as.integer(year)
  file_name <- sprintf("accident_%d.csv.bz2", year)
  system.file("extdata", file_name, package = "MyFirstRPackage")
}

#' Return FARS data for a set of years
#'
#' This is an internal function. It returns FARS data for a set of years (defined using \code{years} parameter).
#' For more information about FARS data, see
#' \href{https://www.nhtsa.gov/research-data/fatality-analysis-reporting-system-fars}{Fatality Analysis Reporting System}.
#'
#' @param years A vector of numeric data convertible to four-digits integers
#'  defining the years of interest. The years should belong to the interval [2013, 2015],
#'  otherwise, an exception is trown.
#'
#' @return Returns a tibble containing FARS data for the chosen years (a row per an accident).
#'  The tibble returns only two columns:
#'
#'\describe{
#' \item{MONTH}{The month of an accident}
#' \item{year}{The year of an accident}}
#'
#' @importFrom dplyr mutate select %>%
#'
#' @examples
#' accidents <- fars_read_years(c(2013, 2014))
#' fars_read_years(2015)
fars_read_years <- function(years) {
        lapply(years, function(year) {
                file <- make_filename(year)
                tryCatch({
                        dat <- fars_read(file)
                        dplyr::mutate(dat, year = year) %>%
                                dplyr::select(MONTH, year)
                }, error = function(e) {
                        warning("invalid year: ", year)
                        return(NULL)
                })
        })
}

#' Return number of accidents aggregated by month and year
#'
#' The function processes FARS data to aggregate number of accidents by month and year.
#' For more information about FARS data, see
#' \href{https://www.nhtsa.gov/research-data/fatality-analysis-reporting-system-fars}{Fatality Analysis Reporting System}.
#'
#' @inheritParams fars_read_years
#'
#' @return Returns a tibble containing aggregated number of accidents.
#'  The tibble has the following columns:
#' \describe{
#'  \item{MONTH}{The month of a year, \code{[1:12]} }
#'  \item{<year_1>}{The first year from the \code{years} parameter}
#'  \item{...}{}
#'  \item{<year_N>}{The last year from the \code{years} parameter}}
#'
#' @importFrom dplyr bind_rows group_by summarize %>%
#' @importFrom tidyr spread
#'
#' @examples
#' fars_summarize_years(c(2013, 2014))
#' summary2015 <- fars_summarize_years(2015)
#'
#' @export
fars_summarize_years <- function(years) {
        dat_list <- fars_read_years(years)
        dplyr::bind_rows(dat_list) %>%
                dplyr::group_by(year, MONTH) %>%
                dplyr::summarize(n = n()) %>%
                tidyr::spread(year, n)
}

#' Show accidents on the map of a state
#'
#' The function shows on the map the accidents that happened during a year
#' on the territory of the state.
#' It uses \code{LATITUDE} and \code{LONGITUDE} registered for each accident in FARS
#' to plot it on the state's map.
#' For more information about FARS data, see
#' \href{https://www.nhtsa.gov/research-data/fatality-analysis-reporting-system-fars}{Fatality Analysis Reporting System}.
#'
#' @param state.num An atomic numeric value that can be coerced to a two-digit integer
#'  representing the state's code. If there is no states matching such a code,
#'  an exception is thrown.
#' @param year An atomic numeric value convertible to a four-digit integer
#'  representing a year to process.
#'
#' @return \code{NULL}
#'
#' @importFrom dplyr filter
#' @importFrom maps map
#' @importFrom graphics points
#'
#' @examples
#' fars_map_state(2, year = 2015)
#' fars_map_state(state.num = 1, year = 2013)
#'
#' @export
fars_map_state <- function(state.num, year) {
        filename <- make_filename(year)
        data <- fars_read(filename)
        state.num <- as.integer(state.num)
        if(!(state.num %in% unique(data$STATE)))
                stop("invalid STATE number: ", state.num)
        data.sub <- dplyr::filter(data, STATE == state.num)
        if(nrow(data.sub) == 0L) {
                message("no accidents to plot")
                return(invisible(NULL))
        }
        is.na(data.sub$LONGITUD) <- data.sub$LONGITUD > 900
        is.na(data.sub$LATITUDE) <- data.sub$LATITUDE > 90
        with(data.sub, {
                maps::map("state", ylim = range(LATITUDE, na.rm = TRUE),
                          xlim = range(LONGITUD, na.rm = TRUE))
                graphics::points(LONGITUD, LATITUDE, pch = 46)
        })
}
