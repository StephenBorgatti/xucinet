# the cliques report prints

    Code
      xcliques(campnet)
    Output
      CLIQUES
      --------------------------------------------------------------------------------
      
      Minimum Set Size:                       3
      Type:                                   Weak
      Input dataset:                          campnet
      
      
      
      10 cliques found.
      
         1:  HOLLY MICHAEL DON HARRY
         2:  BRAZEY LEE STEVE BERT
         3:  CAROL PAT PAULINE
         4:  CAROL PAM PAULINE
         5:  PAM JENNIE ANN
         6:  PAM PAULINE ANN
         7:  MICHAEL BILL DON HARRY
         8:  JOHN GERY RUSS
         9:  GERY STEVE RUSS
        10:  STEVE BERT RUSS
      
      participation
      
                         1     2     3     4     5     6     7     8     9    10 
                         1     2     3     4     5     6     7     8     9    10 
                     ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- 
           1   HOLLY 1.000 0.000 0.333 0.333 0.333 0.333 0.750 0.000 0.000 0.000 
           2  BRAZEY 0.000 1.000 0.000 0.000 0.000 0.000 0.000 0.000 0.333 0.667 
           3   CAROL 0.000 0.000 1.000 1.000 0.333 0.667 0.000 0.000 0.000 0.000 
           4     PAM 0.250 0.000 0.667 1.000 1.000 1.000 0.000 0.000 0.000 0.000 
           5     PAT 0.250 0.000 1.000 0.667 0.333 0.333 0.000 0.000 0.000 0.000 
           6  JENNIE 0.000 0.000 0.333 0.333 1.000 0.667 0.000 0.000 0.000 0.000 
           7 PAULINE 0.000 0.000 1.000 1.000 0.667 1.000 0.000 0.333 0.000 0.000 
           8     ANN 0.000 0.000 0.333 0.667 1.000 1.000 0.000 0.000 0.000 0.000 
           9 MICHAEL 1.000 0.000 0.000 0.000 0.000 0.000 1.000 0.333 0.333 0.000 
          10    BILL 0.750 0.000 0.000 0.000 0.000 0.000 1.000 0.000 0.000 0.000 
          11     LEE 0.000 1.000 0.000 0.000 0.000 0.000 0.000 0.000 0.333 0.667 
          12     DON 1.000 0.000 0.000 0.000 0.000 0.000 1.000 0.000 0.000 0.000 
          13    JOHN 0.000 0.000 0.333 0.333 0.000 0.333 0.000 1.000 0.667 0.333 
          14   HARRY 1.000 0.000 0.000 0.000 0.000 0.000 1.000 0.000 0.000 0.000 
          15    GERY 0.250 0.250 0.000 0.000 0.000 0.000 0.250 1.000 1.000 0.667 
          16   STEVE 0.000 1.000 0.000 0.000 0.000 0.000 0.000 0.667 1.000 1.000 
          17    BERT 0.000 1.000 0.000 0.000 0.000 0.000 0.000 0.333 0.667 1.000 
          18    RUSS 0.000 0.500 0.000 0.000 0.000 0.000 0.000 1.000 1.000 1.000 
      
      18 rows, 10 columns, 1 levels.
      
      HIERARCHICAL CLUSTERING OF OVERLAP MATRIX
      
                     P         M                  
               J     A         I     B            
               E   C U       H C   H R   S        
               N   A L     B O H   A A   T B J G R
               N P R I P A I L A D R Z L E E O E U
               I A O N A N L L E O R E E V R H R S
               E T L E M N L Y L N Y Y E E T N Y S
      
                           1     1 1   1 1 1 1 1 1
       Level   6 5 3 7 4 8 0 1 9 2 4 2 1 6 7 3 5 8
      ------   - - - - - - - - - - - - - - - - - -
      0.0000   . . XXX XXX . . XXXXX . . XXX . XXX
      1.0000   . . XXXXXXX . XXXXXXX XXXXXXX XXXXX
      1.2500   . . XXXXXXX XXXXXXXXX XXXXXXX XXXXX
      1.5000   . XXXXXXXXX XXXXXXXXX XXXXXXX XXXXX
      1.6000   XXXXXXXXXXX XXXXXXXXX XXXXXXX XXXXX
      1.6667   XXXXXXXXXXX XXXXXXXXX XXXXXXXXXXXXX
      2.0000   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      

# the factions report prints

    Code
      xfactions(campnet, 2, seed = 1)
    Output
      FACTIONS
      --------------------------------------------------------------------------------
      
      Number of factions:                     2
      Measure of fit:                         Hamming
      Random number seed:                     1
      Input dataset:                          campnet
      
      
      
      Group Assignments:
      
          1:  HOLLY CAROL PAM PAT JENNIE PAULINE ANN MICHAEL DON HARRY
          2:  BRAZEY BILL LEE JOHN GERY STEVE BERT RUSS
      
                         1     2     3 
                     Final Clust Modul 
                      prop   ers arity 
                     ortio             
                     n "co             
                     rrect             
                         "             
                     ----- ----- ----- 
           1 campnet 0.667     2 0.342 
      
      1 rows, 3 columns, 1 levels.
      
      Block densities
      
                   1     2 
                   1     2 
               ----- ----- 
           1 1 0.333 0.000 
           2 2 0.062 0.339 
      
      2 rows, 2 columns, 1 levels.
      

# the Girvan-Newman report prints

    Code
      xgirvannewman(campnet)
    Output
      GIRVAN-NEWMAN
      --------------------------------------------------------------------------------
      
      Maximum no. of clusters:                10
      Input dataset:                          campnet
      Note:                                   Data were symmetrized via the maximum method.
      
      
      
      Partition with the highest modularity
      
                         1     2 
                     Clust Modul 
                       ers arity 
                     ----- ----- 
           1 campnet     3 0.550 
      
      1 rows, 2 columns, 1 levels.
      
      Partitions
      
                      1  2  3  4  5  6  7 
                     C1 C2 C3 C4 C5 C7 C1 
                                        8 
                     -- -- -- -- -- -- -- 
           1   HOLLY  1  1  1  1  1  1  1 
           2  BRAZEY  1  2  2  2  2  2  2 
           3   CAROL  1  1  3  3  3  3  3 
           4     PAM  1  1  3  3  4  4  4 
           5     PAT  1  1  3  3  3  3  5 
           6  JENNIE  1  1  3  3  4  4  6 
           7 PAULINE  1  1  3  3  3  3  7 
           8     ANN  1  1  3  3  4  4  8 
           9 MICHAEL  1  1  1  1  1  5  9 
          10    BILL  1  1  1  1  1  6 10 
          11     LEE  1  2  2  2  2  2 11 
          12     DON  1  1  1  1  1  5 12 
          13    JOHN  1  2  2  4  5  7 13 
          14   HARRY  1  1  1  1  1  5 14 
          15    GERY  1  2  2  4  5  7 15 
          16   STEVE  1  2  2  2  2  2 16 
          17    BERT  1  2  2  2  2  2 17 
          18    RUSS  1  2  2  4  5  7 18 
      
      18 rows, 7 columns, 1 levels.
      
      Modularity
      
                             1      2      3      4      5      6      7 
                            C1     C2     C3     C4     C5     C7    C18 
                        ------ ------ ------ ------ ------ ------ ------ 
           1 Modularity      0  0.410  0.550  0.531  0.471  0.348 -0.058 
      
      1 rows, 7 columns, 1 levels.
      

# the Louvain report prints

    Code
      xlouvain(campnet)
    Output
      LOUVAIN COMMUNITY DETECTION
      --------------------------------------------------------------------------------
      
      For directed data:                      Maximum/union
      Input dataset:                          campnet
      Note:                                   Data symmetrized by max.
      
      
      
                         1     2 
                     Clust Modul 
                       ers arity 
                     ----- ----- 
           1 campnet     3 0.550 
      
      1 rows, 2 columns, 1 levels.
      
      Levels
      
                     1 2 
                     4 3 
                     | | 
                     0 0 
                     . . 
                     5 5 
                     3 5 
                     1 0 
                     - - 
           1   HOLLY 3 2 
           2  BRAZEY 2 3 
           3   CAROL 1 1 
           4     PAM 1 1 
           5     PAT 1 1 
           6  JENNIE 1 1 
           7 PAULINE 1 1 
           8     ANN 1 1 
           9 MICHAEL 3 2 
          10    BILL 3 2 
          11     LEE 2 3 
          12     DON 3 2 
          13    JOHN 4 3 
          14   HARRY 3 2 
          15    GERY 4 3 
          16   STEVE 2 3 
          17    BERT 2 3 
          18    RUSS 4 3 
      
      18 rows, 2 columns, 1 levels.
      

# xcommunities prints

    Code
      xcommunities(campnet, seed = 1)
    Output
      COMMUNITY DETECTION
      --------------------------------------------------------------------------------
      
      Input dataset:                          campnet
      Note:                                   Data symmetrized by max.
      Note:                                   Data were symmetrized via the maximum method.
      Note:                                   Random seed: 1.
      
      
      
      Cluster membership by method
      
                     1 2 3 4 5 
                     L F G L F 
                     o a i a a 
                     u s r b c 
                     v t v e t 
                     a G a l i 
                     i r n P o 
                     n e N r n 
                       e e o s 
                       d w p   
                       y m     
                         a     
                         n     
                     - - - - - 
           1   HOLLY 2 1 1 1 1 
           2  BRAZEY 3 2 2 2 2 
           3   CAROL 1 3 3 3 1 
           4     PAM 1 3 3 3 1 
           5     PAT 1 3 3 3 1 
           6  JENNIE 1 3 3 3 1 
           7 PAULINE 1 3 3 3 1 
           8     ANN 1 3 3 3 1 
           9 MICHAEL 2 1 1 1 1 
          10    BILL 2 1 1 1 2 
          11     LEE 3 2 2 2 2 
          12     DON 2 1 1 1 1 
          13    JOHN 3 2 2 2 2 
          14   HARRY 2 1 1 1 1 
          15    GERY 3 2 2 2 2 
          16   STEVE 3 2 2 2 2 
          17    BERT 3 2 2 2 2 
          18    RUSS 3 2 2 2 2 
      
      18 rows, 5 columns, 1 levels.
      
                              1     2 
                          Clust Modul 
                            ers arity 
                          ----- ----- 
           1      Louvain     3 0.550 
           2   FastGreedy     3 0.550 
           3 GirvanNewman     3 0.550 
           4    LabelProp     3 0.550 
           5     Factions     2 0.342 
      
      5 rows, 2 columns, 1 levels.
      

