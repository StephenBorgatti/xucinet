# data-raw

Scripts that build the shipped datasets in `data/` from the csv files in the
book's Dropbox folder (`3e/data/csv files`). One script per dataset family;
each ends with `usethis::use_data(<name>, overwrite = TRUE)`. Dataset names are
lowercase short aliases (campnet, hightech, davis, ...) per the crosswalk.
