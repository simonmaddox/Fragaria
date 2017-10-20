# SETS

set I;      # Oil types
set J;      # gasoline types

# PARAMS

param c{I};     # cost of each oil type, in euro/barrel
param b{I};     # availability of each oil type, in barrels
param r{J};     # revenue for each gasoline type, in euro/barrel
param q_max{I,J} default 1;   # min proportion of oil for each type of gasoline
param q_min{I,J} default 0;   # max proportion of oil for each type of gasoline

var ChosenQty{I, J} >= 0;  # in gallons

maximize Balance:
  sum {j in J} (  r[j] * (sum {i in I} ChosenQty[i, j]) 
                - (sum {i in I} c[i] * ChosenQty[i, j]));
  
subject to UseExactlyAllTheOil {i in I}:
  (sum {j in J} ChosenQty[i, j]) = b[i];
  
subject to MaximumOilQuantity {i in I, j in J}:
  ChosenQty[i, j] <= (sum {k in I} ChosenQty[k, j]) * q_max[i, j];
  
subject to MinimumOilQuantity {i in I, j in J}:
  ChosenQty[i, j] >= (sum {k in I} ChosenQty[k, j]) * q_min[i, j];

