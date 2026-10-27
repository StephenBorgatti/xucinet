# Build data/friendship_abc.rda and data/friendship_abc_attr.rda: networks A, B
# and C of Figure 15.1 (chapter 15), 14 made-up nodes, undirected, with gender.
# There is no UCINET file for them; the matrices were recovered from the 2022
# rendered 1e practice for chapter 15 (ASNR_Fig15x1) and checked against the
# chapter text: A has 29 edges, 96 2-stars, 19 triangles, 19 same-gender and
# 10 cross-gender edges (15.2.3, 15.3.2); B has 32 2-stars (15.2.3).
#
# Run with the working directory at the package root:
#   source("data-raw/make-friendship-abc.R")

library(xucinet)

m_A <- matrix(c(0,1,1,1,0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,0,0,0,0,0,0,0,0,0,1,1,0,1,0,0,0,0,0,0,0,0,0,0,1,1,1,0,1,0,0,0,1,1,0,0,0,0,0,1,0,1,0,1,1,1,0,0,0,0,0,0,0,0,0,0,1,0,1,1,0,0,0,0,0,0,0,0,0,0,1,1,0,1,0,0,0,0,0,1,0,0,0,0,1,1,1,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,1,0,1,1,0,0,0,0,1,0,0,0,0,1,0,1,1,1,0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,0,0,0,0,0,0,0,0,1,1,1,0,1,0,0,0,0,0,0,0,0,0,1,1,1,1,0,1,0,0,0,0,0,0,1,1,0,0,1,0,1,0),14,14,byrow=TRUE,dimnames=list(sprintf("a%02d",1:14),sprintf("a%02d",1:14)))
m_B <- matrix(c(0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,1,1,0,1,0,0,0,0,1,0,1,1,1,0,0,0,0,0,0,0,0,1,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,1,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0),14,14,byrow=TRUE,dimnames=list(sprintf("a%02d",1:14),sprintf("a%02d",1:14)))
m_C <- matrix(c(0,0,0,1,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,0,0,1,1,0,0,0,0,0,1,1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,1,0,0,1,0,0,0,0,0,0,1,0,0,0,0,1,1,0,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,1,1,0,1,0,0,1,0,0,0,0,0,0,1,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,0,0,0,0,1,0,1,0,0,0,0,0,0,1,0,0,0,0,0,1,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,1,1,0),14,14,byrow=TRUE,dimnames=list(sprintf("a%02d",1:14),sprintf("a%02d",1:14)))

stopifnot(isSymmetric(m_A), isSymmetric(m_B), isSymmetric(m_C))
twostars <- function(m) sum(choose(rowSums(m), 2))
triangles <- function(m) sum(diag(m %*% m %*% m)) / 6
stopifnot(sum(m_A) / 2 == 29, twostars(m_A) == 96, triangles(m_A) == 19,
          twostars(m_B) == 32)

friendship_abc <- as_xucinet(list(NetworkA = m_A, NetworkB = m_B, NetworkC = m_C),
                             directed = FALSE, title = "friendship_abc")
# 1 = male, seven of each (Figure 15.1 caption)
friendship_abc_attr <- data.frame(Gender = c(0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0),
                                  row.names = sprintf("a%02d", 1:14))
same <- outer(friendship_abc_attr$Gender, friendship_abc_attr$Gender, "==")
stopifnot(sum(m_A * same) / 2 == 19, sum(m_A * !same) / 2 == 10)

save(friendship_abc, file = "data/friendship_abc.rda", compress = "xz", version = 2)
save(friendship_abc_attr, file = "data/friendship_abc_attr.rda", compress = "xz", version = 2)
