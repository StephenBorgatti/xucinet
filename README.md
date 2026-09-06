# xucinet

UCINET-style social network analysis in R: the same routines, the same numbers, the same
printed output, under names that track UCINET's menus. Companion package to *Analyzing
Social Networks Using R*, 2nd edition (Borgatti, Everett, Johnson and Agneessens, Sage).

Status: version 2.0 is a rebuild from the ground up (September 2026). The 0.x package that
accompanied the first edition is not compatible; its function names are kept as deprecated
aliases.

```r
# install.packages("remotes")
remotes::install_github("stephenborgatti/xucinet")
library(xucinet)
net <- xread("campnet.csv")
xdensity(net)
xdegree(net)
```

Design documents: [dev/SPEC.md](dev/SPEC.md), [dev/PLAN.md](dev/PLAN.md).
