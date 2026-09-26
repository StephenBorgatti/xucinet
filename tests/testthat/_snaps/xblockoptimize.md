# the reports print

    Code
      xblockoptimize(campnet, k = 3, seed = 1)
    Output
      STRUCTURAL BLOCKMODELS
      --------------------------------------------------------------------------------
      
      Model:                                  Structural, binary
      Number of blocks:                       3
      Diagonal valid?                         NO
      Iterations/series:                      50
      Penalty iterations:                     25
      Random starts:                          5
      Random # seed:                          1
      Input dataset:                          campnet
      Note:                                   Random number seed: 1.
      
      
      
      Initial partition
      
      Number of errors: 50
      R-square = 0.294
      
      Iteration 2 Number of errors: 48
      Iteration 3 Number of errors: 40
      Iteration 4 Number of errors: 42
      Iteration 5 Number of errors: 44
      
      RESULTS:
        Number of errors: 40
        R-square = 0.257
      
      Block Assignments:
      
          1:  LEE STEVE BERT RUSS
          2:  HOLLY BRAZEY CAROL PAT MICHAEL BILL DON JOHN HARRY GERY
          3:  PAM JENNIE PAULINE ANN
      
      Blocked Adjacency Matrix
      
                     1 1 1 1             1 1 1 1 1            
                     1 6 7 8   1 2 3 5 9 0 2 3 4 5   4 6 7 8  
                     L S B R   H B C P M B D J H G   P J P A  
                    ----------------------------------------- 
        11     LEE |   1 1   |   1                 |         |
        16   STEVE | 1   1 1 |                     |         |
        17    BERT | 1 1   1 |                     |         |
        18    RUSS |   1 1   |                   1 |         |
                   -------------------------------------------
         1   HOLLY |         |       1     1       | 1       |
         2  BRAZEY | 1 1 1   |                     |         |
         3   CAROL |         |       1             | 1   1   |
         5     PAT |         | 1   1               |   1     |
         9 MICHAEL |         | 1           1   1   |         |
        10    BILL |         |         1   1   1   |         |
        12     DON |         | 1       1       1   |         |
        13    JOHN |       1 |                   1 |     1   |
        14   HARRY |         | 1       1   1       |         |
        15    GERY |   1   1 |         1           |         |
                   -------------------------------------------
         4     PAM |         |                     |   1 1 1 |
         6  JENNIE |         |       1             | 1     1 |
         7 PAULINE |         |     1 1             | 1       |
         8     ANN |         |                     | 1 1 1   |
                   ------------------------------------------
      
      
      Density matrix
      
                   1     2     3 
                   1     2     3 
               ----- ----- ----- 
           1 1 0.833 0.050 0.000 
           2 2 0.150 0.211 0.125 
           3 3 0.000 0.075 0.750 
      
      3 rows, 3 columns, 1 levels.
      
      Errors per block
      
                1  2  3 
                1  2  3 
               -- -- -- 
           1 1  2  6  0 
           2 2  2 19  3 
           3 3  0  5  3 
      
      3 rows, 3 columns, 1 levels.
      

---

    Code
      xblockoptimize(campnet, k = 2, type = "regular", seed = 1, starts = 5)
    Output
      REGULAR BLOCKMODELS VIA TABU SEARCH
      --------------------------------------------------------------------------------
      
      Model:                                  Regular
      Number of blocks:                       2
      Diagonal valid?                         NO
      Iterations/series:                      30
      Penalty iterations:                     25
      Random starts:                          5
      Random # seed:                          1
      Input dataset:                          campnet
      Note:                                   Random number seed: 1.
      
      
      
      Initial Partition
      Number of errors: 4
      Initial Partition
      Number of errors: 4
      
      Iterations:
        No. of errors: 5
        No. of errors: 5
        No. of errors: 5
        No. of errors: 5
        No. of errors: 5
      
      RESULTS:
        Number of errors: 4
      
      Block Assignments:
      
          1:  HOLLY BRAZEY CAROL PAM PAT JENNIE PAULINE ANN MICHAEL BILL LEE DON HARRY GERY STEVE BERT RUSS
          2:  JOHN
      
      Blocked Adjacency Matrix
      
                                       1 1 1 1 1 1 1 1   1  
                     1 2 3 4 5 6 7 8 9 0 1 2 4 5 6 7 8   3  
                     H B C P P J P A M B L D H G S B R   J  
                    --------------------------------------- 
         1   HOLLY |       1 1             1           |   |
         2  BRAZEY |                     1       1 1   |   |
         3   CAROL |       1 1   1                     |   |
         4     PAM |           1 1 1                   |   |
         5     PAT | 1   1     1                       |   |
         6  JENNIE |       1 1     1                   |   |
         7 PAULINE |     1 1 1                         |   |
         8     ANN |       1   1 1                     |   |
         9 MICHAEL | 1                     1 1         |   |
        10    BILL |                 1     1 1         |   |
        11     LEE |   1                         1 1   |   |
        12     DON | 1               1       1         |   |
        14   HARRY | 1               1     1           |   |
        15    GERY |                 1           1   1 |   |
        16   STEVE |                     1         1 1 |   |
        17    BERT |                     1       1   1 |   |
        18    RUSS |                           1 1 1   |   |
                   -----------------------------------------
        13    JOHN |             1             1     1 |   |
                   ----------------------------------------
      
      

