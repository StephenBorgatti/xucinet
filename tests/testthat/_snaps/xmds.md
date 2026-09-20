# the printed report prints every row, never head()

    Code
      print(xmds(cities, type = "d", plot = FALSE))
    Output
      MULTIDIMENSIONAL SCALING
      --------------------------------------------------------------------------------
      
      Method:                                 Classical (Torgerson) scaling
      Type of Data:                           Dissimilarities
      Dimensions:                             2
      Input dataset:                          cities
      
      
      
      MDS Coordinates
      
                             1         2 
                          Dim1      Dim2 
                     --------- --------- 
           1  BOSTON -1348.668  -462.401 
           2      NY -1198.874  -306.547 
           3      DC -1076.986  -136.432 
           4   MIAMI -1226.939  1013.628 
           5 CHICAGO  -428.455  -174.603 
           6 SEATTLE  1596.159  -639.308 
           7      SF  1697.228   131.686 
           8      LA  1464.047   560.580 
           9  DENVER   522.487    13.396 
      
      9 rows, 2 columns, 1 levels.
      
                        1     2     3 
                    Stres  GOF1  GOF2 
                        s             
                    ----- ----- ----- 
           1 cities 0.020 0.958 1.000 
      
      1 rows, 3 columns, 1 levels.
      
      Eigenvalues
      
                          1            2 
                      Value         Prop 
               ------------ ------------ 
           1 1 13949791.247        0.851 
           2 2  2124813.269        0.130 
           3 3   183009.131        0.011 
           4 4    90600.521        0.006 
           5 5    37352.793        0.002 
      
      5 rows, 2 columns, 1 levels.
      

