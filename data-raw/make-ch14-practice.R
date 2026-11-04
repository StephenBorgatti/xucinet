# Build data/classrooms.rda, data/teams.rda, data/callcenter.rda and
# data/callcenter_attr.rda: made-up data for Practices 14.1 and 14.2 of the book (chapter 14, testing hypotheses). The chapter's examples (63
# classrooms sampled from 439, the 18 project teams of section 14.3) are
# hypothetical, so these datasets are invented to reproduce the situations the
# chapter describes. They describe no real classrooms or teams. Each part has
# its own seed, found by trying seeds until the checks below held; the checks
# are the properties the practice relies on.
#
# Run with the working directory at the package root:
#   source("data-raw/make-ch14-practice.R")

library(xucinet)

# --- classrooms: a random sample of 63 classrooms from a population of 439 ----
# CorePeriphery rises with TeacherStyle (standardized coefficient about 0.4)
# and is unrelated to ClassSize.

set.seed(1)
n <- 63
TeacherStyle <- round(pmin(7, pmax(1, rnorm(n, 4, 1.3))), 1)
ClassSize <- sample(18:32, n, replace = TRUE)
CorePeriphery <- 0.45 + 0.04 * (TeacherStyle - 4) + rnorm(n, 0, 0.11)
CorePeriphery <- round(pmin(0.95, pmax(0.05, CorePeriphery)), 3)
classrooms <- data.frame(TeacherStyle, ClassSize, CorePeriphery,
                         row.names = sprintf("c%02d", 1:n))

fit <- summary(lm(scale(CorePeriphery) ~ scale(TeacherStyle) + scale(ClassSize),
                  classrooms))$coefficients
stopifnot(abs(fit[2, 1] - 0.4) < 0.05, fit[2, 4] < 0.01, fit[3, 4] > 0.3,
          all(classrooms$CorePeriphery > 0 & classrooms$CorePeriphery < 1))

# --- teams: the 18 project teams of section 14.3, a whole population ---------
# cor(Centralization, Performance) is the 0.384 the chapter quotes (built
# exactly, then rounded; the seed is one for which the rounded values still
# give 0.384). TeamSize is unrelated to both.

set.seed(83)
n <- 18
x <- rbeta(n, 2, 3)
z <- residuals(lm(rnorm(n) ~ x))
y <- 0.384 * scale(x)[, 1] + sqrt(1 - 0.384^2) * scale(z)[, 1]
teams <- data.frame(Centralization = round(x, 3),
                    Performance = round(pmin(10, pmax(1, 6.2 + 1.5 * y)), 1),
                    TeamSize = sample(4:9, n, replace = TRUE),
                    row.names = sprintf("t%02d", 1:n))

stopifnot(round(cor(teams$Centralization, teams$Performance), 3) == 0.384,
          abs(cor(teams$TeamSize, teams$Centralization)) < 0.15,
          abs(cor(teams$TeamSize, teams$Performance)) < 0.15)

# --- callcenter: advice among 30 call centre employees, with attributes -------
# Practice 14.2. Each person asks 1-7 others for advice, chosen with
# person-specific popularity weights, so a few people are asked by many.
# Satisfaction depends on in-degree (standardized coefficient about 0.35),
# weakly on Extraversion, not on Age, plus a contagion term with true rho 0.3
# along the row-normalized advice ties: y = (I - 0.3 W)^-1 (exogenous part).
# Steve's decision on #49 (option c): with 30 people a network effect of this
# size cannot be told apart from zero, so the fitted rho is required to lie in
# 0.2-0.4 but NOT to be significant. Seed 145 is the first of seeds 1, 2, ...
# for which every check below holds (145 tried).

set.seed(145)
n <- 30
ids <- sprintf("e%02d", 1:n)
pop <- rgamma(n, shape = 0.8, rate = 1)
k <- sample(1:7, n, replace = TRUE)
A <- matrix(0, n, n, dimnames = list(ids, ids))
for (i in 1:n) {
  p <- pop
  p[i] <- 0
  A[i, sample(n, k[i], prob = p)] <- 1
}
indeg <- colSums(A)
Age <- sample(22:58, n, replace = TRUE)
Extraversion <- round(pmin(5, pmax(1, rnorm(n, 3.2, 0.8))), 1)
exog <- 0.35 * scale(indeg)[, 1] + 0.12 * scale(Extraversion)[, 1] + rnorm(n, 0, 0.85)
W <- A / pmax(rowSums(A), 1)
y <- solve(diag(n) - 0.3 * W, exog)
Satisfaction <- round(pmin(7, pmax(1, 4.3 + 1.1 * scale(y)[, 1])), 1)

callcenter <- as_xucinet(list(Advice = A), directed = TRUE, title = "callcenter")
callcenter_attr <- data.frame(Age, Extraversion, Satisfaction, row.names = ids)

d <- callcenter_attr
d$Indeg <- indeg[rownames(d)]
f <- Satisfaction ~ Age + Extraversion + Indeg
reg <- xregression(f, d, nperm = 10000, seed = 1)$matrices[[1]]
lag <- xautoregression(callcenter, f, d)$matrices[[1]]
err <- xautoregression(callcenter, f, d, model = "error")$matrices[[1]]
b <- reg["Indeg", "Coef"]
stopifnot(abs(sum(A) / (n * (n - 1)) - 0.12) < 0.02,
          all(Satisfaction > 1 & Satisfaction < 7),
          abs(reg["Indeg", "Beta"] - 0.35) < 0.08,
          lag["Rho", "Coef"] >= 0.2, lag["Rho", "Coef"] <= 0.4, lag["Rho", "Sig"] > 0.05,
          reg["Indeg", "p.Sig"] < 0.05, reg["Age", "p.Sig"] > 0.05,
          lag["Indeg", "Sig"] < 0.05, err["Indeg", "Sig"] < 0.05,
          abs(lag["Indeg", "Coef"] / b - 1) < 0.10,
          abs(err["Indeg", "Coef"] / b - 1) < 0.10)

save(classrooms, file = "data/classrooms.rda", compress = "xz", version = 2)
save(teams, file = "data/teams.rda", compress = "xz", version = 2)
save(callcenter, file = "data/callcenter.rda", compress = "xz", version = 2)
save(callcenter_attr, file = "data/callcenter_attr.rda", compress = "xz", version = 2)
