# the reports print

    Code
      xcoreperiphery(campnet, seed = 1)
    Output
      CATEGORICAL CORE/PERIPHERY
      --------------------------------------------------------------------------------
      
      Exclude diagonal:                       YES
      Number of random starts:                20
      Maximum iterations:                     500
      Density of core->periphery ties:        NA
      Density of periphery->core ties:        NA
      Measure of fit:                         Correlation
      Input dataset:                          campnet
      Note:                                   Random number seed: 1.
      
      
      
      Core/Periphery fit (correlation) =  0.36
      
      Core/Periphery Class Memberships:
      
             Core:  LEE STEVE BERT RUSS
        Periphery:  HOLLY BRAZEY CAROL PAM PAT JENNIE PAULINE ANN MICHAEL BILL DON JOHN HARRY GERY
      
                     1 1 1 1                     1 1 1 1 1  
                     1 6 7 8   1 2 3 4 5 6 7 8 9 0 2 3 4 5  
                     L S B R   H B C P P J P A M B D J H G  
                    --------------------------------------- 
        11     LEE |   1 1   |   1                         |
        16   STEVE | 1   1 1 |                             |
        17    BERT | 1 1   1 |                             |
        18    RUSS |   1 1   |                           1 |
                   -----------------------------------------
         1   HOLLY |         |       1 1           1       |
         2  BRAZEY | 1 1 1   |                             |
         3   CAROL |         |       1 1   1               |
         4     PAM |         |           1 1 1             |
         5     PAT |         | 1   1     1                 |
         6  JENNIE |         |       1 1     1             |
         7 PAULINE |         |     1 1 1                   |
         8     ANN |         |       1   1 1               |
         9 MICHAEL |         | 1                   1   1   |
        10    BILL |         |                 1   1   1   |
        12     DON |         | 1               1       1   |
        13    JOHN |       1 |             1             1 |
        14   HARRY |         | 1               1   1       |
        15    GERY |   1   1 |                 1           |
                   ----------------------------------------
      
      Iterations: 2 5 6 4 5 7 14 8 6 3 9 8 9 7 5 7 7 8 7 3
      
                         1 
                     Categ 
                     orica 
                     l fit 
                     ----- 
           1 campnet 0.360 
      
      1 rows, 1 columns, 1 levels.
      
      Density matrix
      
                           1     2 
                        Core Perip 
                              hery 
                       ----- ----- 
           1      Core 0.833 0.036 
           2 Periphery 0.107 0.198 
      
      2 rows, 2 columns, 1 levels.
      

---

    Code
      xcoreperiphery(campnet, type = "continuous")
    Output
      CONTINUOUS CORENESS MODEL
      --------------------------------------------------------------------------------
      
      Algorithm:                              Minres (SVD)
      Diagonal values valid:                  NO
      Input dataset:                          campnet
      Note:                                   Random number seed: 7014.
      
      
      
      Minres concluded in 22 iterations.
      
      Multiplicative Coreness
      
                         1 
                     Coren 
                       ess 
                     ----- 
           1   HOLLY 0.257 
           2  BRAZEY 0.011 
           3   CAROL 0.296 
           4     PAM 0.508 
           5     PAT 0.353 
           6  JENNIE 0.385 
           7 PAULINE 0.377 
           8     ANN 0.334 
           9 MICHAEL 0.122 
          10    BILL 0.053 
          11     LEE 0.016 
          12     DON 0.147 
          13    JOHN 0.061 
          14   HARRY 0.118 
          15    GERY 0.038 
          16   STEVE 0.026 
          17    BERT 0.022 
          18    RUSS 0.032 
      
      18 rows, 1 columns, 1 levels.
      
      DESCRIPTIVE STATISTICS FOR EACH MEASURE
      
                            1 
                       Corene 
                           ss 
                       ------ 
           1      Mean  0.175 
           2   Std Dev  0.157 
           3       Sum  3.157 
           4  Variance  0.025 
           5       SSQ  1.000 
           6     MCSSQ  0.446 
           7  Euc Norm  1.000 
           8   Minimum  0.011 
           9   Maximum  0.508 
          10  N of Obs 18.000 
          11 N Missing  0.000 
      
                         1     2     3     4 
                     Conti Gini  Gini- Heter 
                     nuous coeff based ogene 
                       fit icien  core   ity 
                               t /peri       
                                 pheri       
                                  ness       
                     ----- ----- ----- ----- 
           1 campnet 0.327 0.493 0.161 0.047 
      
      1 rows, 4 columns, 1 levels.
      
      Concentration scores for different sizes of core
      
                     1      2      3      4      5      6      7 
                  Diff  nDiff   Corr  Ident CoreDe PerDen DenDif 
                                                 n             f 
                ------ ------ ------ ------ ------ ------ ------ 
           1  1  0.477  0.477  0.512  0.418         0.169        
           2  2  0.315  0.446  0.609  0.607  1.000  0.175  0.825 
           3  3  0.323  0.560  0.704  0.735  0.667  0.176  0.490 
           4  4  0.318  0.635  0.783  0.817  0.583  0.181  0.402 
           5  5  0.339  0.759  0.851  0.872  0.600  0.212  0.388 
           6  6  0.342  0.837  0.899  0.901  0.567  0.250  0.317 
           7  7  0.413  1.091  0.929  0.909  0.476  0.264  0.213 
           8  8  0.309  0.874  0.891  0.878  0.393  0.267  0.126 
           9  9  0.273  0.819  0.848  0.845  0.347  0.278  0.069 
          10 10  0.316  1.000  0.813  0.815  0.333  0.339 -0.006 
          11 11  0.251  0.831  0.746  0.774  0.282  0.405 -0.123 
          12 12  0.245  0.847  0.680  0.735  0.258  0.567 -0.309 
          13 13  0.221  0.795  0.607  0.698  0.231  0.700 -0.469 
          14 14  0.209  0.782  0.532  0.663  0.214  0.833 -0.619 
          15 15  0.196  0.760  0.452  0.631  0.200  0.833 -0.633 
          16 16  0.189  0.756  0.364  0.602  0.192  1.000 -0.808 
          17 17  0.180  0.744  0.253  0.574  0.184               
      
      17 rows, 7 columns, 1 levels.
      
      Expected Values
      
                         1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17    18 
                     HOLLY BRAZE CAROL   PAM   PAT JENNI PAULI   ANN MICHA  BILL   LEE   DON  JOHN HARRY  GERY STEVE  BERT  RUSS 
                               Y                       E    NE          EL                                                       
                     ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- 
           1   HOLLY 0.241 0.010 0.277 0.476 0.331 0.361 0.353 0.313 0.115 0.050 0.015 0.138 0.058 0.111 0.035 0.024 0.020 0.030 
           2  BRAZEY 0.010 0.000 0.012 0.020 0.014 0.015 0.015 0.013 0.005 0.002 0.001 0.006 0.002 0.005 0.001 0.001 0.001 0.001 
           3   CAROL 0.277 0.012 0.320 0.548 0.381 0.416 0.407 0.361 0.132 0.058 0.017 0.159 0.066 0.128 0.041 0.028 0.023 0.034 
           4     PAM 0.476 0.020 0.548 0.939 0.654 0.713 0.698 0.618 0.226 0.099 0.030 0.272 0.114 0.219 0.069 0.048 0.040 0.059 
           5     PAT 0.331 0.014 0.381 0.654 0.455 0.496 0.486 0.430 0.158 0.069 0.021 0.189 0.079 0.152 0.048 0.033 0.028 0.041 
           6  JENNIE 0.361 0.015 0.416 0.713 0.496 0.541 0.529 0.469 0.172 0.075 0.022 0.207 0.086 0.166 0.053 0.036 0.030 0.045 
           7 PAULINE 0.353 0.015 0.407 0.698 0.486 0.529 0.518 0.459 0.168 0.073 0.022 0.202 0.084 0.162 0.052 0.035 0.030 0.044 
           8     ANN 0.313 0.013 0.361 0.618 0.430 0.469 0.459 0.407 0.149 0.065 0.020 0.179 0.075 0.144 0.046 0.031 0.026 0.039 
           9 MICHAEL 0.115 0.005 0.132 0.226 0.158 0.172 0.168 0.149 0.055 0.024 0.007 0.066 0.027 0.053 0.017 0.011 0.010 0.014 
          10    BILL 0.050 0.002 0.058 0.099 0.069 0.075 0.073 0.065 0.024 0.010 0.003 0.029 0.012 0.023 0.007 0.005 0.004 0.006 
          11     LEE 0.015 0.001 0.017 0.030 0.021 0.022 0.022 0.020 0.007 0.003 0.001 0.009 0.004 0.007 0.002 0.002 0.001 0.002 
          12     DON 0.138 0.006 0.159 0.272 0.189 0.207 0.202 0.179 0.066 0.029 0.009 0.079 0.033 0.063 0.020 0.014 0.012 0.017 
          13    JOHN 0.058 0.002 0.066 0.114 0.079 0.086 0.084 0.075 0.027 0.012 0.004 0.033 0.014 0.026 0.008 0.006 0.005 0.007 
          14   HARRY 0.111 0.005 0.128 0.219 0.152 0.166 0.162 0.144 0.053 0.023 0.007 0.063 0.026 0.051 0.016 0.011 0.009 0.014 
          15    GERY 0.035 0.001 0.041 0.069 0.048 0.053 0.052 0.046 0.017 0.007 0.002 0.020 0.008 0.016 0.005 0.004 0.003 0.004 
          16   STEVE 0.024 0.001 0.028 0.048 0.033 0.036 0.035 0.031 0.011 0.005 0.002 0.014 0.006 0.011 0.004 0.002 0.002 0.003 
          17    BERT 0.020 0.001 0.023 0.040 0.028 0.030 0.030 0.026 0.010 0.004 0.001 0.012 0.005 0.009 0.003 0.002 0.002 0.003 
          18    RUSS 0.030 0.001 0.034 0.059 0.041 0.045 0.044 0.039 0.014 0.006 0.002 0.017 0.007 0.014 0.004 0.003 0.003 0.004 
      
      18 rows, 18 columns, 1 levels.
      
      Recommended core membership: top 7 nodes (concentration = 0.929).
      

