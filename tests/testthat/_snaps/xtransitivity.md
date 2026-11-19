# the reports print

    Code
      xreciprocity(campnet)
    Output
      RECIPROCITY
      --------------------------------------------------------------------------------
      
      Input dataset:                          campnet
      
      
      
                         1     2 
                     Dyad  Arc R 
                     Recip ecipr 
                     rocit ocity 
                         y       
                     ----- ----- 
           1 campnet 0.543 0.704 
      
      1 rows, 2 columns, 1 levels.
      

---

    Code
      xtransitivity(campnet)
    Output
      TRANSITIVITY
      --------------------------------------------------------------------------------
      
      Input dataset:                          campnet
      
      
      
                         1     2     3     4     5     6     7     8     9    10    11    12 
                     Three  Twos Trans Densi Ratio Trans TP Co Trans Trans T Cov Trans Trans 
                         s       itivi    ty       itivi varia itivi itivi arian itivi itivi 
                                    ty             ty In   nce ty Ph ty Ph    ce ty Co ty Be 
                                                     dex           i i Bet       rrela    ta 
                                                                         a        tion       
                     ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- 
           1 campnet    60   124 0.484 0.176 2.742 0.373 0.008 0.130 0.315 0.125 0.480 0.269 
      
      1 rows, 12 columns, 1 levels.
      
      If there were no particular tendency toward transitivity, the ratio of transitivity to density would be 1.0
      TPhi/TC are centred (Dekker, Krackhardt & Snijders 2019): ~0 means no increased propensity toward transitive triples.
      

---

    Code
      xcyclicality(campnet)
    Output
      CYCLICALITY
      --------------------------------------------------------------------------------
      
      Input dataset:                          campnet
      
      
      
      Triplet Cyclicality
      
                         1     2     3     4     5     6 
                     Three  Twos Cycli Densi Ratio Cycli 
                         s       calit    ty       city  
                                     y             Index 
                     ----- ----- ----- ----- ----- ----- 
           1 campnet    48   124 0.387 0.176 2.194 0.256 
      
      1 rows, 6 columns, 1 levels.
      

