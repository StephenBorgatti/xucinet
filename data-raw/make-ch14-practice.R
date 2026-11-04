# Build data/classrooms.rda and data/teams.rda: made-up data for Practice 14.1
# of the book (chapter 14, testing hypotheses). The chapter's examples (63
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

# callcenter (Practice 14.2) waits for #49: its planted properties cannot all
# be had with 30 nodes.

save(classrooms, file = "data/classrooms.rda", compress = "xz", version = 2)
save(teams, file = "data/teams.rda", compress = "xz", version = 2)
