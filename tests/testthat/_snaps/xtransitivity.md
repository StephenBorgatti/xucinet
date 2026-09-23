# the reports print

    Code
      xreciprocity(campnet)
    Output
      RECIPROCITY
      --------------------------------------------------------------------------------
      
      Input dataset:                          campnet
      
      
      
      Node-level Reciprocity Statistics -- All values are Proportions
      
                        1         2         3         4         5         6         7 
                     Node Symmetric Non-Symme Out/NonSy In/NonSym   Sym/Out    Sym/In 
                                         tric         m                               
                --------- --------- --------- --------- --------- --------- --------- 
           1  1 HOLLY     0.4000000 0.6000000 0.3333333 0.6666667 0.6666667 0.5000000 
           2  2 BRAZEY    0.3333333 0.6666667 1.0000000 0.0000000 0.3333333 1.0000000 
           3  3 CAROL     0.6666667 0.3333333 1.0000000 0.0000000 0.6666667 1.0000000 
           4  4 PAM       0.6000000 0.4000000 0.0000000 1.0000000 1.0000000 0.6000000 
           5  5 PAT       0.7500000 0.2500000 0.0000000 1.0000000 1.0000000 0.7500000 
           6  6 JENNIE    1.0000000 0.0000000 NA        NA        1.0000000 1.0000000 
           7  7 PAULINE   0.4000000 0.6000000 0.3333333 0.6666667 0.6666667 0.5000000 
           8  8 ANN       0.6666667 0.3333333 1.0000000 0.0000000 0.6666667 1.0000000 
           9  9 MICHAEL   0.4000000 0.6000000 0.3333333 0.6666667 0.6666667 0.5000000 
          10 10 BILL      0.0000000 1.0000000 1.0000000 0.0000000 0.0000000 NA        
          11 11 LEE       1.0000000 0.0000000 NA        NA        1.0000000 1.0000000 
          12 12 DON       0.7500000 0.2500000 0.0000000 1.0000000 1.0000000 0.7500000 
          13 13 JOHN      0.0000000 1.0000000 1.0000000 0.0000000 0.0000000 NA        
          14 14 HARRY     0.5000000 0.5000000 0.5000000 0.5000000 0.6666667 0.6666667 
          15 15 GERY      0.2500000 0.7500000 0.6666667 0.3333333 0.3333333 0.5000000 
          16 16 STEVE     0.6000000 0.4000000 0.0000000 1.0000000 1.0000000 0.6000000 
          17 17 BERT      0.7500000 0.2500000 0.0000000 1.0000000 1.0000000 0.7500000 
          18 18 RUSS      0.7500000 0.2500000 0.0000000 1.0000000 1.0000000 0.7500000 
      
      18 rows, 7 columns, 1 levels.
      
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
      
      
      
      Triplet Transitivity
      
                         1     2     3     4     5     6     7     8     9    10    11    12    13 
                     Three  Twos Trans Densi Ratio Trans TP Co Trans Trans T Cov Trans Trans Clust 
                         s       itivi    ty       itivi varia itivi itivi arian itivi itivi ering 
                                    ty             ty In   nce ty Ph ty Ph    ce ty Co ty Be  Coef 
                                                     dex           i i Bet       rrela    ta ficie 
                                                                         a        tion          nt 
                     ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- 
           1 campnet    60   124 0.484 0.176 2.742 0.373 0.008 0.130 0.315 0.125 0.480 0.269 0.569 
      
      1 rows, 13 columns, 1 levels.
      

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
      

