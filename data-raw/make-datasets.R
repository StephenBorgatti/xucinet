# Build data/*.rda for every dataset the book uses.
#
# Source of truth is the UCINET ##h/##d pair, not the csv exports: since the
# native reader landed (issue #3) the labels, the multi-relation stacks and the
# 2-mode shapes all come across intact, which the csv round trip loses. csv is
# only a fallback for datasets that have no ##h.
#
# Run with the working directory at the package root:
#   source("data-raw/make-datasets.R")

library(xucinet)

# ---- where the UCINET files live --------------------------------------------

book <- "C:/Users/sborg2/Dropbox/Shared Folders/Analyzing Social Networks book/3e/data"
sources <- c(
  file.path(book, "DataUCINET"),        # the battery named in ISSUES-phase0.md
  file.path(book, "ASN3 Ucinet Files")  # a superset: adds Knecht and Lazega
)

# DataUCINET currently holds only DataUCINET.zip, so unpack it to a cache the
# first time. The cache is disposable; nothing is written back into Dropbox.
cache <- file.path(tempdir(), "xucinet-datauci")
zip <- file.path(book, "DataUCINET.zip")
if (!length(list.files(sources[1], pattern = "h$")) && file.exists(zip)) {
  dir.create(cache, showWarnings = FALSE, recursive = TRUE)
  if (!length(list.files(cache))) utils::unzip(zip, exdir = cache)
  sources <- c(cache, sources)
}

find_ucinet <- function(stem) {
  for (d in sources) {
    for (ext in c(".##h", ".##H")) {
      p <- file.path(d, paste0(stem, ext))
      if (file.exists(p)) return(p)
    }
  }
  NA_character_
}

# ---- what to build ----------------------------------------------------------

# name    the lowercase 2.0 name, from the crosswalk Datasets sheet
# stem    the UCINET file, minus extension
# kind    "net" -> an xucinet object; "attr" -> a plain data frame (SPEC D1 keeps
#         node covariates out of the network object)
manifest <- read.csv(text = '
name,stem,kind
baker_journals,Baker_Journals,net
bkham,Bernard_HamRadio,net
camp92,Borgatti_Camp92,net
camp92_attr,Borgatti_Camp92_Attributes,attr
campnet,Borgatti_Campnet,net
pv504,Borgatti_Scientists504,net
pv504_attr,Borgatti_Scientists504_Attributes,attr
pv960,Borgatti_Scientists960,net
burkhardt,Burkhardt_GovernmentAgency,net
davis,Davis_SouthernWomen,net
eies,Freeman_EIES,net
eies_attr,Freeman_EIES_Attributes,attr
doctorates,Greenacre_Doctorates,net
wiring,Hawthorne_BankWiring,net
cities,Johnson_CitiesUS,net
polarstation,Johnson_PolarStation,net
kaptail,Kapferer_Tailorship,net
knecht,Knecht_Class12b,net
knecht_attr,Knecht_Class12b_Attributes,attr
hightech,Krackhardt_HighTech,net
hightech_attr,Krackhardt_HighTech_Attributes,attr
mainas_terro,Mainas_Terro,net
newfrat,Newcomb_Fraternity,net
padgett,Padgett_FlorentineFamilies,net
padgett_attr,Padgett_FlorentineFamilies_Attributes,attr
pane_training,Pane_Training,net
sampson,Sampson_Monastery,net
trade_pre29,Savage_TradePre29,net
papuan_village,Schwimmer_PapuanVillage,net
wolfe_primates,Wolfe_Primates,net
wolfe_primates_attr,Wolfe_Primates_Attributes,attr
zachary,Zachary_KarateClub,net
zachary_attr,Zachary_KarateClub_Attributes,attr
', stringsAsFactors = FALSE, strip.white = TRUE)

# Not built, and why:
#   hollywood, reddit_fracking, sunbelt_tweets, youtube_falcon9
#     The four Everett social-media datasets (crosswalk 4.7 / 4.7.1). No source
#     file of any kind exists on this machine - not ##h, not csv. Add them here
#     once the data turns up.
#   campnet_attr
#     The crosswalk lists it, but there is no Borgatti_Campnet_Attributes file.
#     camp92_attr covers the same participants.
#   lazega, newguinea, supremecourt
#     Present as ##h and shipped by xUCINET 0.x, but absent from the crosswalk
#     Datasets sheet, so they have no agreed 2.0 name yet. Naming them is a book
#     edit (CLAUDE.md), so they wait for Steve rather than being coined here.

# ---- build ------------------------------------------------------------------

# An attribute file is a nodes-by-variables matrix whose column labels are the
# variable names; SPEC D1 wants that as an ordinary data frame keyed by node.
as_attribute_frame <- function(net) {
  m <- as.matrix(net)
  df <- as.data.frame(m, stringsAsFactors = FALSE)
  names(df) <- colnames(m)
  rownames(df) <- rownames(m)
  df
}

dir.create("data", showWarnings = FALSE)
built <- character(0)
for (i in seq_len(nrow(manifest))) {
  nm <- manifest$name[i]
  path <- find_ucinet(manifest$stem[i])
  if (is.na(path)) {
    warning("no UCINET file for ", manifest$stem[i], " (", nm, ")", call. = FALSE)
    next
  }
  net <- xreaducinet(path, title = nm)
  value <- if (manifest$kind[i] == "attr") as_attribute_frame(net) else net
  assign(nm, value)
  save(list = nm, file = file.path("data", paste0(nm, ".rda")),
       compress = "xz", version = 2)
  built <- c(built, nm)
  cat(sprintf("%-22s <- %-40s %s\n", nm, basename(path),
              if (manifest$kind[i] == "attr")
                paste0(nrow(value), " x ", ncol(value), " attributes")
              else paste0(paste(dim(net), collapse = " x "), ", ",
                          xnrelations(net), " relation(s)")))
}

cat("\nbuilt ", length(built), " datasets, ",
    round(sum(file.info(list.files("data", full.names = TRUE))$size) / 1024), " KB total\n",
    sep = "")
