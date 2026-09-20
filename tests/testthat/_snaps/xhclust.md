# the printed report snapshot

    Code
      print(xhclust(cities, type = "d", method = "single", plot = FALSE))
    Output
      JOHNSON'S HIERARCHICAL CLUSTERING
      --------------------------------------------------------------------------------
      
      Method:                                 SINGLE_LINK (minimum)
      Type of Data:                           Dissimilarities
      Input dataset:                          cities
      
      
      
      HIERARCHICAL CLUSTERING
      
                S           C  
                E     B     H D
              M A     O     I E
              I T     S     C N
              A T     T     A V
              M L S L O N D G E
              I E F A N Y C O R
      
      Level   4 6 7 8 1 2 3 5 9
      -----   - - - - - - - - -
        206   . . . . XXX . . .
        233   . . . . XXXXX . .
        379   . . XXX XXXXX . .
        671   . . XXX XXXXXXX .
        808   . XXXXX XXXXXXX .
        996   . XXXXX XXXXXXXXX
       1059   . XXXXXXXXXXXXXXX
       1075   XXXXXXXXXXXXXXXXX
      
      Partition indicator matrix
      
                     1 2 3 4 5 6 7 8 
                     1 2 3 4 5 6 7 8 
                     ( ( ( ( ( ( ( ( 
                     8 7 6 5 4 3 2 1 
                     ) ) ) ) ) ) ) ) 
                     2 2 3 6 8 9 1 1 
                     0 3 7 7 0 9 0 0 
                     6 3 9 1 8 6 5 7 
                                 9 5 
                     - - - - - - - - 
           1  BOSTON 1 1 1 1 1 1 1 1 
           2      NY 1 1 1 1 1 1 1 1 
           3      DC 2 1 1 1 1 1 1 1 
           4   MIAMI 3 2 2 2 2 2 2 1 
           5 CHICAGO 4 3 3 1 1 1 1 1 
           6 SEATTLE 5 4 4 3 3 3 1 1 
           7      SF 6 5 5 4 3 3 1 1 
           8      LA 7 6 5 4 3 3 1 1 
           9  DENVER 8 7 6 5 4 1 1 1 
      
      9 rows, 8 columns, 1 levels.
      
                        1     2 
                    Cophe Level 
                    netic     s 
                    ----- ----- 
           1 cities 0.714     8 
      
      1 rows, 2 columns, 1 levels.
      
      Measures of cluster adequacy
      
                             1      2      3      4      5      6      7      8 
                         1 (8)  2 (7)  3 (6)  4 (5)  5 (4)  6 (3)  7 (2)  8 (1) 
                        ------ ------ ------ ------ ------ ------ ------ ------ 
           1       Corr  0.284  0.480  0.554  0.657  0.711  0.687  0.151        
           2 Modularity -0.041  0.046  0.105  0.115  0.151  0.131 -0.009        
           3 Silhouette  0.071  0.211  0.342  0.364  0.352  0.364  0.073        
      
      3 rows, 8 columns, 1 levels.
      
      Cluster sizes (proportion of items)
      
                     1     2     3     4     5     6     7     8 
                 1 (8) 2 (7) 3 (6) 4 (5) 5 (4) 6 (3) 7 (2) 8 (1) 
                 ----- ----- ----- ----- ----- ----- ----- ----- 
           1 CL1 0.222 0.333 0.333 0.444 0.444 0.556 0.889     1 
           2 CL2 0.111 0.111 0.111 0.111 0.111 0.111 0.111       
           3 CL3 0.111 0.111 0.111 0.111 0.333 0.333             
           4 CL4 0.111 0.111 0.111 0.222 0.111                   
           5 CL5 0.111 0.111 0.222 0.111                         
           6 CL6 0.111 0.111 0.111                               
           7 CL7 0.111 0.111                                     
           8 CL8 0.111                                           
      
      8 rows, 8 columns, 1 levels.
      

