# the report prints

    Code
      xegoaltersimilarity(campnet, camp92_attr$Gender, type = "categorical")
    Output
      EGONET ALTER-EGO SIMILARITY (E.G., HOMOPHILY) FOR CATEGORICAL ATTRIBUTES
      --------------------------------------------------------------------------------
      
      Input Attribute:                        Gender
      Ego Network Type:                       Outgoing ties only
      Input dataset:                          campnet
      Note:                                   This routine automatically dichotomizes the network data.
      
      
      
      Node-level alter-ego similarity
      
                          1      2      3      4      5      6      7      8      9     10     11     12     13     14 
                          H     H* Colema     EI Jaccar Yules   Kappa    Phi   Bona Odds_R Log_Od fInGro fOutGr Gender 
                                        n             d      Q                        atio     ds     up    oup        
                     ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ 
           1   HOLLY  0.667  0.255  0.433 -0.333  0.250  0.565  0.433  0.240  0.655  3.600  1.281  2.000  1.000  1.000 
           2  BRAZEY  0.000 -0.412 -1.000  1.000  0.000 -1.000 -0.700 -0.387  0.000                0.000  3.000  1.000 
           3   CAROL  1.000  0.588  1.000 -1.000  0.429  1.000  1.000  0.553  1.000                3.000  0.000  1.000 
           4     PAM  1.000  0.588  1.000 -1.000  0.429  1.000  1.000  0.553  1.000                3.000  0.000  1.000 
           5     PAT  1.000  0.588  1.000 -1.000  0.429  1.000  1.000  0.553  1.000                3.000  0.000  1.000 
           6  JENNIE  1.000  0.588  1.000 -1.000  0.429  1.000  1.000  0.553  1.000                3.000  0.000  1.000 
           7 PAULINE  1.000  0.588  1.000 -1.000  0.429  1.000  1.000  0.553  1.000                3.000  0.000  1.000 
           8     ANN  1.000  0.588  1.000 -1.000  0.429  1.000  1.000  0.553  1.000                3.000  0.000  1.000 
           9 MICHAEL  0.667  0.137  0.292 -0.333  0.200  0.333  0.292  0.127  0.586  2.000  0.693  2.000  1.000  2.000 
          10    BILL  1.000  0.471  1.000 -1.000  0.333  1.000  1.000  0.436  1.000                3.000  0.000  2.000 
          11     LEE  0.667  0.137  0.292 -0.333  0.200  0.333  0.292  0.127  0.586  2.000  0.693  2.000  1.000  2.000 
          12     DON  0.667  0.137  0.292 -0.333  0.200  0.333  0.292  0.127  0.586  2.000  0.693  2.000  1.000  2.000 
          13    JOHN  0.667  0.137  0.292 -0.333  0.200  0.333  0.292  0.127  0.586  2.000  0.693  2.000  1.000  2.000 
          14   HARRY  0.667  0.137  0.292 -0.333  0.200  0.333  0.292  0.127  0.586  2.000  0.693  2.000  1.000  2.000 
          15    GERY  1.000  0.471  1.000 -1.000  0.333  1.000  1.000  0.436  1.000                3.000  0.000  2.000 
          16   STEVE  1.000  0.471  1.000 -1.000  0.333  1.000  1.000  0.436  1.000                3.000  0.000  2.000 
          17    BERT  1.000  0.471  1.000 -1.000  0.333  1.000  1.000  0.436  1.000                3.000  0.000  2.000 
          18    RUSS  1.000  0.471  1.000 -1.000  0.333  1.000  1.000  0.436  1.000                3.000  0.000  2.000 
      
      18 rows, 14 columns, 1 levels.
      

---

    Code
      xegoaltersimilarity(hightech, "Age", data = hightech_attr)
    Output
      EGONET ALTER-EGO SIMILARITY (E.G., HOMOPHILY)
      --------------------------------------------------------------------------------
      
      Input Attribute:                        Age
      Ego Network Type:                       Outgoing ties only
      Measures:                               -AbsDiff
      Normalization:                          None
      Input dataset:                          hightech
      Note:                                   Relation: Advice (of 3).
      
      
      
      Node-level alter-ego similarity
      
                      1 
                 -AbsDi 
                     ff 
                 ------ 
           1 A01  0.384 
           2 A02 -0.297 
           3 A03 -0.042 
           4 A04  0.322 
           5 A05  0.066 
           6 A06 -0.073 
           7 A07  0.191 
           8 A08 -0.134 
           9 A09  0.093 
          10 A10  0.501 
          11 A11  0.180 
          12 A12 -0.153 
          13 A13  0.009 
          14 A14  0.153 
          15 A15        
          16 A16  0.225 
          17 A17  0.045 
          18 A18  0.091 
          19 A19  0.113 
          20 A20  0.182 
          21 A21  0.079 
      
      21 rows, 1 columns, 1 levels.
      

