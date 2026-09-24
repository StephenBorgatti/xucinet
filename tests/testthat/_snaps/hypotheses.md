# the reports print

    Code
      xregression(y ~ x1 + x2, d, nperm = 100, seed = 1)
    Output
      NODE LEVEL REGRESSION
      --------------------------------------------------------------------------------
      
      Method:                                 Y-perm
      # of permutations:                      100
      Random seed:                            1
      Dependent variable:                     y
      Input dataset:                          y
      Note:                                   100 permutations; p-values are 2-tailed.
      Note:                                   c.Sig is classical significance test. p.Sig is permutation test.
      
      
      
      Overall Regression Fit Statistics
      
    Condition
      Warning in `FUN()`:
      NAs introduced by coercion
    Output
                    1      2      3      4      5      6      7 
                 Nobs R-Squa Adj R-      F   F df Sig (c Sig (p 
                          re square               lassic   erm) 
                                                     al)        
               ------ ------ ------ ------ ------ ------ ------ 
           1 y     20  0.742  0.711 24.394         0.000  0.010 
      
      1 rows, 7 columns, 1 levels.
      
      Regression coefficients - predicting y
      
                            1      2      3      4      5      6      7      8      9 
                         Coef   Beta     SE      T  c.Sig  p.Sig As Lar As Sma As Ext 
                                                                     ge     ll   reme 
                       ------ ------ ------ ------ ------ ------ ------ ------ ------ 
           1 Intercept  1.089         0.307                                           
           2        x1  2.033  0.858  0.293  6.940  0.000  0.010  0.010  1.000  0.010 
           3        x2 -0.066 -0.031  0.263 -0.252  0.804  0.792  0.683  0.327  0.792 
      
      3 rows, 9 columns, 1 levels.
      

---

    Code
      xcorrelation(d$x1, d$y, nperm = 100, seed = 1)
    Output
      NODE-LEVEL CORRELATION
      --------------------------------------------------------------------------------
      
      Variables:                              d$x1 and d$y
      Input dataset:                          d$x1 and d$y
      Note:                                   100 permutations; p-values are 2-tailed.
      
      
      
                              1     2     3     4     5     6     7 
                          Corre  Nobs Sig ( Sig ( As La As Sm As Ex 
                          latio       class perm)   rge   all treme 
                              n       ical)                         
                          ----- ----- ----- ----- ----- ----- ----- 
           1 d$x1 and d$y 0.861    20 0.000 0.010 0.010     1 0.010 
      
      1 rows, 7 columns, 1 levels.
      

---

    Code
      xqap(as.matrix(padgett, relation = 1), as.matrix(padgett, relation = 2), nperm = 100,
      seed = 1)
    Output
      QAP CORRELATION
      --------------------------------------------------------------------------------
      
      Data Matrices:                          as.matrix(padgett, relation = 1), as.matrix(padgett, relation = 2)
      # of Permutations:                      100
      Random seed:                            1
      Tails:                                  2-tailed (|perm| >= |obs|)
      Input dataset:                          as.matrix(padgett, relation = 1)
      Note:                                   Both matrices symmetric: the lower triangle is used.
      
      
      
      QAP results for as.matrix(padgett, relation = 1) * as.matrix(padgett, relation = 2) (100 permutations, 2-tailed)
      
                                        1      2      3      4      5      6      7      8      9     10 
                                   Obs Va Signif Averag Std De Minimu Maximu Prop > Prop <  N Obs Prop | 
                                      lue icance      e      v      m      m  = Obs  = Obs        perm|> 
                                                                                                  =|obs| 
                                   ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ 
           1   Pearson Correlation  0.372  0.010  0.005  0.100 -0.169  0.237  0.010  1.000    120  0.010 
           2    Euclidean Distance  4.359  0.010  5.456  0.273  4.796  5.916  1.000  0.010    120  1.000 
           3      Hamming Distance  0.158  0.010  0.249  0.025  0.192  0.292  1.000  0.010    120  1.000 
           4            Match Coef  0.842  0.010  0.751  0.025  0.708  0.808  0.010  1.000    120  0.010 
           5          Jaccard Coef  0.296  0.010  0.082  0.050  0.000  0.207  0.010  1.000    120  0.010 
           6 Goodman-Kruskal Gamma  0.797  0.069 -0.058  0.412 -1.000  0.625  0.010  1.000    120  0.069 
           7          Hubert Gamma  8.000  0.010  2.580  1.478  0.000  6.000  0.010  1.000    120  0.010 
      
      7 rows, 10 columns, 1 levels.
      

---

    Code
      xmrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 100, seed = 1)
    Output
      MRQAP DEKKER SEMI-PARTIALLING
      --------------------------------------------------------------------------------
      
      Dependent variable:                     Advice
      Independent variables:                  Friendship, ReportTo
      Method:                                 Double Dekker semi-partialling
      Random seed:                            1
      Input dataset:                          Advice
      Note:                                   100 permutations; p-values are 2-tailed, from the t-statistics.
      
      
      
      MODEL FIT
      
                        1     2     3     4     5 
                    R-Squ Adj R P(R-S   Obs Perms 
                      are  -Sqr   qr)             
                    ----- ----- ----- ----- ----- 
           1 Advice 0.063 0.059 0.010   420   100 
      
      1 rows, 5 columns, 1 levels.
      
      REGRESSION COEFFICIENTS
      
                             1      2      3      4      5      6      7      8      9     10     11     12     13 
                        Un-Std Stdize Robust T-stat P-valu As Lar As Sma As Ext Perm A Perm S Collin Tolera    VIF 
                          ized d Coef     SE             e     ge     ll   reme     vg      D  R-Sqr    nce        
                        ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ 
           1 Friendship  0.136  0.117  0.056  2.429  0.109  0.079  0.931  0.109 -0.000  0.087  0.035  0.965  1.036 
           2   ReportTo  0.472  0.202  0.061  7.685  0.010  0.010  1.000  0.010 -0.029  0.110  0.035  0.965  1.036 
           3  Intercept  0.397         0.027 14.491                                                                
      
      3 rows, 13 columns, 1 levels.
      

---

    Code
      xlrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 50, seed = 1)
    Output
      LOGISTIC REGRESSION QAP
      --------------------------------------------------------------------------------
      
      Dependent variable:                     Advice
      Independent variables:                  Friendship, ReportTo
      Data are:                               Non-symmetric
      Random seed:                            1
      Input dataset:                          Advice
      Note:                                   Dependent variable dichotomized: values above 0 are ties.
      Note:                                   The r-squared shown is McFadden's pseudo r-squared.
      Note:                                   50 permutations; p-values are 2-tailed.
      
      
      
      Overall fit of the logistic regression model
      
                           1        2        3        4        5 
                          LL    R-Sqr      Sig      Obs    Perms 
                    -------- -------- -------- -------- -------- 
           1 Advice -274.073    0.052    0.020      420       50 
      
      1 rows, 5 columns, 1 levels.
      
      LR Coefficients & Permutation Results (T-stats used in permutations)
      
                             1      2      3      4      5      6      7      8      9     10     11 
                          Coef OddsRa      T    Sig    Avg    Min    Max     SD  P(ge)  P(le) P(ext) 
                                    t                                                                
                        ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ 
           1  Intercept -0.425  0.654 -3.666                                                         
           2 Friendship  0.579  1.785  2.418  0.118  0.054 -0.703  0.867  0.329  0.078  0.941  0.118 
           3   ReportTo  3.059 21.306  2.957  0.020 -0.122 -1.041  1.009  0.437  0.020  1.000  0.020 
      
      3 rows, 11 columns, 1 levels.
      

---

    Code
      xdensitybygroups(campnet, camp92_attr$Gender, test = TRUE, nperm = 100, seed = 1)
    Output
      DENSITY BY GROUPS
      --------------------------------------------------------------------------------
      
      Input dataset:                          campnet
      Note:                                   ANOVA density models tested by Y permutation: 100 permutations, 2-tailed.
      
      
      
      ANOVA density models: MODEL FIT
      
                                       1     2     3     4 
                                   R-Squ Adj R P(R-S   Obs 
                                     are  -Sqr   qr)       
                                   ----- ----- ----- ----- 
           1    Constant Homophily 0.109 0.106 0.010   306 
           2    Variable Homophily 0.114 0.108 0.010   306 
           3 Structural Blockmodel 0.114 0.105 0.010   306 
      
      3 rows, 4 columns, 1 levels.
      
      Density
      
                   1     2 
                   1     2 
               ----- ----- 
           1 1 0.357 0.050 
           2 2 0.062 0.278 
      
      2 rows, 2 columns, 1 levels.
      
      Constant Homophily
      
                           1     2     3     4     5     6 
                       Un-st Stdiz Signi Propo Propo Propo 
                       dized ed Co fican rtion rtion rtion 
                        Coef effic    ce  As L  As S  As E 
                       ficie  ient        arge  mall xtrem 
                          nt                             e 
                       ----- ----- ----- ----- ----- ----- 
           1  In-group 0.252 0.330 0.010 0.010 1.000 0.010 
           2 Intercept 0.056       1.000 1.000 0.010 1.000 
      
      2 rows, 6 columns, 1 levels.
      
      Variable Homophily
      
                           1     2     3     4     5     6 
                       Un-st Stdiz Signi Propo Propo Propo 
                       dized ed Co fican rtion rtion rtion 
                        Coef effic    ce  As L  As S  As E 
                       ficie  ient        arge  mall xtrem 
                          nt                             e 
                       ----- ----- ----- ----- ----- ----- 
           1   Group 1 0.301 0.305 0.010 0.010 1.000 0.010 
           2   Group 2 0.222 0.265 0.010 0.010 1.000 0.010 
           3 Intercept 0.056       1.000 1.000 0.010 1.000 
      
      3 rows, 6 columns, 1 levels.
      
      Structural Blockmodel
      
                            1      2      3      4      5      6 
                       Un-std Stdize Signif Propor Propor Propor 
                       ized C d Coef icance tion A tion A tion A 
                       oeffic ficien        s Larg s Smal s Extr 
                         ient      t             e      l    eme 
                       ------ ------ ------ ------ ------ ------ 
           1       1-1  0.079  0.081  0.129  0.050  0.960  0.129 
           2       1-2 -0.228 -0.263  0.010  1.000  0.010  0.010 
           3       2-1 -0.215 -0.248  0.010  1.000  0.010  0.010 
           4 Intercept  0.278         0.010  0.010  1.000  0.010 
      
      4 rows, 6 columns, 1 levels.
      

