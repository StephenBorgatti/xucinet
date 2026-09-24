# the report prints

    Code
      xautoregression(campnet, indeg ~ btw, ar_data())
    Output
      NETWORK AUTOREGRESSION
      --------------------------------------------------------------------------------
      
      Model:                                  Network effects (lag)
      Dependent variable:                     indeg
      Input dataset:                          campnet
      Note:                                   W row-normalized.
      Note:                                   Maximum likelihood by sna::lnam; Sig is from the normal distribution.
      
      
      
      Model fit
      
                           1       2       3       4       5       6 
                        Nobs   Sigma  LogLik Null LL     AIC     BIC 
                     ------- ------- ------- ------- ------- ------- 
           1 campnet      18   1.271 -30.054 -32.742  68.108  71.669 
      
      1 rows, 6 columns, 1 levels.
      
      Coefficients - predicting indeg
      
                            1      2      3      4 
                         Coef     SE      Z    Sig 
                       ------ ------ ------ ------ 
           1 Intercept  3.513  1.661  2.114  0.034 
           2       btw  0.031  0.013  2.450  0.014 
           3       Rho -0.315  0.435 -0.724  0.469 
      
      3 rows, 4 columns, 1 levels.
      

