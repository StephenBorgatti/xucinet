# the report prints

    Code
      xclusteringcoefficient(campnet)
    Output
      CLUSTERING COEFFICIENT
      --------------------------------------------------------------------------------
      
      Input dataset:                          campnet
      
      
      
      Overall Clustering Coefficients
      
                         1     2     3     4     5     6     7 
                     Overa Weigh Fagio Fagio O-P O O-P W Densi 
                     ll CC ted O lo Ov lo We veral eight    ty 
                           veral erall ighte  l CC ed CC       
                            l CC    CC  d CC                   
                     ----- ----- ----- ----- ----- ----- ----- 
           1 campnet 0.569 0.505 0.509 0.452 0.526 0.484 0.176 
      
      1 rows, 7 columns, 1 levels.
      
      Overall CC is the mean of the node-level clustering coefficients, over nodes with at least two neighbors.
      Weighted Overall CC weights each node by its number of pairs of neighbors; on binary data it equals the transitivity of the network with the direction of ties ignored.
      On binary data, O-P Weighted CC equals the Transitivity reported by xtransitivity().
      

---

    Code
      xclusteringcoefficient(padgett)
    Output
      CLUSTERING COEFFICIENT
      --------------------------------------------------------------------------------
      
      Input dataset:                          padgett
      
      
      
      Overall Clustering Coefficients
      
                          1     2     3 
                      Overa Weigh Densi 
                      ll CC ted O    ty 
                            veral       
                             l CC       
                      ----- ----- ----- 
           1 Marriage 0.218 0.191 0.167 
           2 Business 0.596 0.417 0.125 
      
      2 rows, 3 columns, 1 levels.
      
      Overall CC is the mean of the node-level clustering coefficients, over nodes with at least two neighbors.
      Weighted Overall CC weights each node by its number of pairs of neighbors; on binary data it equals the transitivity of the network with the direction of ties ignored.
      The Fagiolo and O-P coefficients equal these on symmetric binary data and are in $summary.
      

