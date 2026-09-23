unit unetmixingmodels;
interface

uses
  SysUtils, Math, // Added Math for Max
  ucommon,
  utvec,
  utivec,
  utsmat, uaggregate;

// --- Observed Mixing Matrix ---
// Calculates the observed sum of weights of ties between classes.
// For directed: M_rs = sum of weights from class r to class s.
// For undirected: M_rs = sum of edge weights between class r and s.
//                 M_rr includes sum of edge weights within r AND sum of self-loop weights of nodes in r.

{******************************************************************************}
function getgroupsizes(sizes,part:tivec): integer;
procedure getdensitymatrix(y,x:tsmat; p,groupsizes:tivec);
procedure getobsmixingmatrix(y,x:tsmat; p,groupsizes:tivec; directed:boolean);
procedure getexpmixingmatrix(y,x:tsmat; p,groupsizes:tivec; directed:boolean; method:integer);
{******************************************************************************}

procedure CalculateObservedMixingMatrix_Directed(
  MixingMatrix: tsmat;          // Output: Valued mixing matrix (1-based)
  AdjMatrix: tsmat;             // Input: Valued adjacency matrix (1-based)
  Partition: tivec;             // Input: Partition vector (1-based, values 1 to NumClasses)
  GroupSizes: tivec);         // Input: Number of classes and size of each class

procedure CalculateObservedMixingMatrix_Undirected(
  MixingMatrix: tsmat;          // Output: Valued mixing matrix (1-based, symmetric)
  AdjMatrix: tsmat;             // Input: Valued adjacency matrix (1-based, symmetric)
  Partition: tivec;             // Input: Partition vector (1-based, values 1 to NumClasses)
  GroupSizes: tivec);         // Input: Number of classes and size of each class

// --- Model 1: Density-Based Expected Values ---
// Expected sum of weights based on overall network density and group sizes.
procedure CalculateExpectedMM_Model1_Directed(
  ExpectedMixingMatrix: tsmat;  // Output: Valued expected mixing matrix (1-based)
  AdjMatrix: tsmat;             // Input: Valued adjacency matrix (1-based)
  Partition: tivec;             // Input: Partition vector (1-based, values 1 to NumClasses)
  GroupSizes: tivec);         // Input: Number of classes and size of each class

procedure CalculateExpectedMM_Model1_Undirected(
  ExpectedMixingMatrix: tsmat;  // Output: Valued expected mixing matrix (1-based)
  AdjMatrix: tsmat;             // Input: Valued adjacency matrix (1-based, symmetric)
  Partition: tivec;             // Input: Partition vector (1-based, values 1 to NumClasses)
  GroupSizes: tivec);         // Input: Number of classes and size of each class

// --- Model 2: Configuration Model Expected Values ---
// Expected sum of weights preserving group-level total outgoing/incoming strengths (directed)
// or total group strengths (undirected).
procedure CalculateExpectedMM_Model2_Directed(
  ExpectedMixingMatrix: tsmat;  // Output: Valued expected mixing matrix (1-based)
  AdjMatrix: tsmat;             // Input: Valued adjacency matrix (1-based)
  Partition: tivec;             // Input: Partition vector (1-based, values 1 to NumClasses)
  GroupSizes: tivec);         // Input: Number of classes and size of each class

procedure CalculateExpectedMM_Model2_Undirected(
  ExpectedMixingMatrix: tsmat;  // Output: Valued expected mixing matrix (1-based)
  AdjMatrix: tsmat;             // Input: Valued adjacency matrix (1-based, symmetric)
  Partition: tivec;             // Input: Partition vector (1-based, values 1 to NumClasses)
  GroupSizes: tivec);         // Input: Number of classes and size of each class

// --- Model 3: Fixed Outgoing Strength/Degree, Targets by Size ---
// Expected sum of weights where groups control their total outgoing strength,
// and targets are chosen proportionally to their size (number of nodes).
procedure CalculateExpectedMM_Model3_Directed(
  ExpectedMixingMatrix: tsmat;  // Output: Valued expected mixing matrix (1-based)
  AdjMatrix: tsmat;             // Input: Valued adjacency matrix (1-based)
  Partition: tivec;             // Input: Partition vector (1-based, values 1 to NumClasses)
  GroupSizes: tivec);         // Input: Number of classes

procedure CalculateExpectedMM_Model3_Undirected(
  ExpectedMixingMatrix: tsmat;  // Output: Valued expected mixing matrix (1-based)
  AdjMatrix: tsmat;             // Input: Valued adjacency matrix (1-based, symmetric)
  Partition: tivec;             // Input: Partition vector (1-based, values 1 to NumClasses)
  GroupSizes: tivec);         // Input: Number of classes

implementation


// --- Helper Procedure to Get Class Sizes ---
// Populates GroupSizes array (1-based) with the number of nodes in each class.

function getgroupsizes(sizes,part:tivec): integer;
//ensures numbers from 1 to nclasses
//nclasses stored a part.n
begin
  result:= part.renumberandcount(sizes);
end;

procedure getdensitymatrix(y,x:tsmat; p,groupsizes:tivec);
var
  ng: integer;
begin
  ng:= groupsizes.n;
  aggbygroups(y,x,p,p,ng,ng);
end;

procedure getobsmixingmatrix(y,x:tsmat; p,groupsizes:tivec; directed:boolean);
begin
  if directed
    then CalculateObservedMixingMatrix_Directed(y,x,p,groupsizes)
    else CalculateObservedMixingMatrix_UnDirected(y,x,p,groupsizes);
end;

procedure getexpmixingmatrix(y,x:tsmat; p,groupsizes:tivec; directed:boolean; method:integer);
begin
  case method of
    0: if directed
         then CalculateExpectedMM_Model1_Directed(y,x,p,groupsizes)
         else CalculateExpectedMM_Model1_unDirected(y,x,p,groupsizes);
    1: if directed
         then CalculateExpectedMM_Model2_Directed(y,x,p,groupsizes)
         else CalculateExpectedMM_Model2_unDirected(y,x,p,groupsizes);
    2: if directed
         then CalculateExpectedMM_Model3_Directed(y,x,p,groupsizes)
         else CalculateExpectedMM_Model3_unDirected(y,x,p,groupsizes);
    end;
end;

  // --- Observed Mixing Matrix ---

procedure CalculateObservedMixingMatrix_Directed(
  MixingMatrix: tsmat;
  AdjMatrix: tsmat;
  Partition: tivec;
  GroupSizes: tivec);
var
  i, j, r, s, NumNodes, Numclasses: integer;
  val: Single;
begin
  // Assumes MixingMatrix object is created by the caller.
  // This procedure allocates its internal cells and sets dimensions.
  numclasses:= groupsizes.n;
  MixingMatrix.allocate(NumClasses, NumClasses, -1, true, true); // setsize=true, zfill=true
  MixingMatrix.nr := NumClasses; // Explicitly set dimensions
  MixingMatrix.nc := NumClasses;
  NumNodes := AdjMatrix.n;     // Use AdjMatrix.n for number of nodes

  // Iterate through all possible directed ties in the adjacency matrix.
  for i := 1 to NumNodes do
  begin
    r := Partition.cell[i]; // Get class of the sender node i
    // AdjMatrix.nc should also be NumNodes for a square matrix; AdjMatrix.n covers this.
    for j := 1 to NumNodes do
    begin
      val := AdjMatrix.cell[i,j]; // Get weight of tie from i to j
      if val <> ucommon.na then // Process only if the value is not missing
      begin
        s := Partition.cell[j]; // Get class of the receiver node j
        // Add the weight to the corresponding cell in the mixing matrix
        MixingMatrix.cell[r,s] := MixingMatrix.cell[r,s] + val;
      end;
    end;
  end;
end;

procedure CalculateObservedMixingMatrix_Undirected(
  MixingMatrix: tsmat;
  AdjMatrix: tsmat;
  Partition: tivec;
  GroupSizes: tivec);
var
  i, j, r, s, NumNodes, NumClasses: integer;
  val: Single;
begin
  numclasses:= groupsizes.n;
  MixingMatrix.allocate(NumClasses, NumClasses, -1, true, true);
  MixingMatrix.nr := NumClasses;
  MixingMatrix.nc := NumClasses;
  NumNodes := AdjMatrix.n; // Use AdjMatrix.n for number of nodes

  // M_rs = sum of weights of edges between class r and class s.
  // M_rr includes weights of edges within class r AND self-loop weights of nodes in r.
  // Iterate through the upper triangle of the adjacency matrix (including the diagonal)
  // to count each edge and self-loop once.
  for i := 1 to NumNodes do
  begin
    r := Partition.cell[i]; // Class of node i
    for j := i to NumNodes do // j starts from i to cover diagonal and upper triangle
    begin
      val := AdjMatrix.cell[i,j]; // Get weight of edge (i,j)
      if val <> ucommon.na then
      begin
        s := Partition.cell[j]; // Class of node j
        if i = j then // This is a node self-loop (or any diagonal value)
        begin
          // r will be equal to s here. Add weight to M_rr.
          MixingMatrix.cell[r,r] := MixingMatrix.cell[r,r] + val;
        end
        else // This is an edge between distinct nodes i and j
        begin
          // Add weight to M_rs
          MixingMatrix.cell[r,s] := MixingMatrix.cell[r,s] + val;
          if r <> s then // If nodes are in different groups, also add to M_sr for symmetry
            MixingMatrix.cell[s,r] := MixingMatrix.cell[s,r] + val;
        end;
      end;
    end;
  end;
end;

// --- Model 1: Density-Based Expected Values ---

procedure CalculateExpectedMM_Model1_Directed(
  ExpectedMixingMatrix: tsmat;
  AdjMatrix: tsmat;
  Partition: tivec;
  GroupSizes: tivec);
var
  i, j, r, s, NumNodes, Numclasses: integer;
  TotalWeight_OffDiag, Density_OffDiag: Extended; // Use Extended for precision
  val: Single;
begin
  NumNodes := AdjMatrix.n; // Use AdjMatrix.n
  numclasses:= groupsizes.n;

  // Calculate total weight of off-diagonal elements (ties between distinct nodes)
  TotalWeight_OffDiag := 0;
  for i := 1 to NumNodes do
    for j := 1 to NumNodes do
    begin
      if i <> j then // Only consider off-diagonal elements
      begin
        val := AdjMatrix.cell[i,j];
        if val <> ucommon.na then
          TotalWeight_OffDiag := TotalWeight_OffDiag + val;
      end;
    end;

  ExpectedMixingMatrix.allocate(NumClasses, NumClasses, 1, true, true);
  ExpectedMixingMatrix.nr := NumClasses;
  ExpectedMixingMatrix.nc := NumClasses;

  // Handle cases with too few nodes to form distinct pairs
  if (NumNodes < 2) then // NumNodes * (NumNodes - 1) would be 0 or negative
  begin
    Exit;
  end;

  Density_OffDiag := TotalWeight_OffDiag / (NumNodes * (NumNodes - 1));

  // Calculate expected values for each cell in the mixing matrix
  for r := 1 to NumClasses do
  begin
    for s := 1 to NumClasses do
    begin
      if r = s then // Expected ties within the same class (between distinct nodes)
        ExpectedMixingMatrix.cell[r,s] := Density_OffDiag * GroupSizes[r] * Max(0, GroupSizes[r] - 1)
      else // Expected ties between different classes
        ExpectedMixingMatrix.cell[r,s] := Density_OffDiag * GroupSizes[r] * GroupSizes[s];
    end;
  end;
end;

procedure CalculateExpectedMM_Model1_Undirected(
  ExpectedMixingMatrix: tsmat;
  AdjMatrix: tsmat;
  Partition: tivec;
  GroupSizes: tivec);
var
  i, j, r, s, NumNodes, NumClasses: integer;
  TotalWeight_OffDiag, Density_OffDiag: Extended;
  TotalWeight_Diag, Density_Diag: Extended;
  val: Single;
  NumPossiblePairs_OffDiag: Extended;
begin
  NumNodes := AdjMatrix.n; // Use AdjMatrix.n
  Numclasses:= groupsizes.n;

  TotalWeight_OffDiag := 0;
  for i := 1 to NumNodes do
    for j := i + 1 to NumNodes do
    begin
      val := AdjMatrix.cell[i,j];
      if val <> ucommon.na then
        TotalWeight_OffDiag := TotalWeight_OffDiag + val;
    end;

  TotalWeight_Diag := 0;
  for i := 1 to NumNodes do
  begin
    val := AdjMatrix.cell[i,i];
    if val <> ucommon.na then
      TotalWeight_Diag := TotalWeight_Diag + val;
  end;

  ExpectedMixingMatrix.allocate(NumClasses, NumClasses, 1, true, true);
  ExpectedMixingMatrix.nr := NumClasses;
  ExpectedMixingMatrix.nc := NumClasses;

  Density_OffDiag := 0;
  if NumNodes >= 2 then
  begin
    NumPossiblePairs_OffDiag := NumNodes * (NumNodes - 1) / 2.0;
    if NumPossiblePairs_OffDiag > 0 then
      Density_OffDiag := TotalWeight_OffDiag / NumPossiblePairs_OffDiag;
  end;

  Density_Diag := 0;
  if NumNodes > 0 then
    Density_Diag := TotalWeight_Diag / NumNodes;

  for r := 1 to NumClasses do
  begin
    for s := r to NumClasses do
    begin
      if r = s then
      begin
        ExpectedMixingMatrix.cell[r,r] := (Density_OffDiag * groupSizes[r] * Max(0, GroupSizes[r] - 1) / 2.0);
        ExpectedMixingMatrix.cell[r,r] := ExpectedMixingMatrix.cell[r,r] + (Density_Diag * GroupSizes[r]);
      end
      else
      begin
        ExpectedMixingMatrix.cell[r,s] := Density_OffDiag * GroupSizes[r] * GroupSizes[s];
      end;
    end;
  end;

  for r := 1 to NumClasses do
    for s := r + 1 to NumClasses do
      ExpectedMixingMatrix.cell[s,r] := ExpectedMixingMatrix.cell[r,s];
end;

// --- Model 2: Configuration Model Expected Values ---

procedure CalculateExpectedMM_Model2_Directed(
  ExpectedMixingMatrix: tsmat;
  AdjMatrix: tsmat;
  Partition: tivec;
  GroupSizes: tivec);
var
  i, j, r, s, NumNodes, NumClasses: integer;
  S_out_group, S_in_group: array of Extended;
  TotalNetworkWeight: Extended;
  val: Single;
begin
  NumNodes := AdjMatrix.n; // Use AdjMatrix.n
  NumClasses:= groupsizes.n;
  SetLength(S_out_group, NumClasses + 1);
  SetLength(S_in_group, NumClasses + 1);

  for i := 1 to NumClasses do
  begin
    S_out_group[i] := 0;
    S_in_group[i] := 0;
  end;
  TotalNetworkWeight := 0;

  for i := 1 to NumNodes do
  begin
    r := Partition.cell[i];
    for j := 1 to NumNodes do
    begin
      val := AdjMatrix.cell[i,j];
      if val <> ucommon.na then
      begin
        s := Partition.cell[j];
        S_out_group[r] := S_out_group[r] + val;
        S_in_group[s] := S_in_group[s] + val;
      end;
    end;
  end;

  for i := 1 to NumClasses do
    TotalNetworkWeight := TotalNetworkWeight + S_out_group[i];

  ExpectedMixingMatrix.allocate(NumClasses, NumClasses, 1, true, true);
  ExpectedMixingMatrix.nr := NumClasses;
  ExpectedMixingMatrix.nc := NumClasses;

  if TotalNetworkWeight = 0 then
  begin
    Exit;
  end;

  for r := 1 to NumClasses do
  begin
    for s := 1 to NumClasses do
    begin
      ExpectedMixingMatrix.cell[r,s] := (S_out_group[r] * S_in_group[s]) / TotalNetworkWeight;
    end;
  end;
end;

procedure CalculateExpectedMM_Model2_Undirected(
  ExpectedMixingMatrix: tsmat;
  AdjMatrix: tsmat;
  Partition: tivec;
  GroupSizes: tivec);
var
  i, j, r, s, NumNodes, NumClasses: integer;
  K_group: array of Extended;
  TotalStrengthSum_2W: Extended;
  val: Single;
begin
  NumNodes := AdjMatrix.n; // Use AdjMatrix.n
  NumClasses:= groupsizes.n;
  SetLength(K_group, NumClasses + 1);
  for i := 1 to NumClasses do
    K_group[i] := 0;

  TotalStrengthSum_2W := 0;

  for i := 1 to NumNodes do
  begin
    r := Partition.cell[i];
    for j := 1 to NumNodes do
    begin
      val := AdjMatrix.cell[i,j];
      if val <> ucommon.na then
      begin
        K_group[r] := K_group[r] + val;
      end;
    end;
  end;

  for i := 1 to NumNodes do
    for j := 1 to NumNodes do
    begin
      val := AdjMatrix.cell[i,j];
      if val <> ucommon.na then
        TotalStrengthSum_2W := TotalStrengthSum_2W + val;
    end;

  ExpectedMixingMatrix.allocate(NumClasses, NumClasses, 1, true, true);
  ExpectedMixingMatrix.nr := NumClasses;
  ExpectedMixingMatrix.nc := NumClasses;

  if TotalStrengthSum_2W = 0 then
  begin
    Exit;
  end;

  for r := 1 to NumClasses do
  begin
    for s := 1 to NumClasses do
    begin
      ExpectedMixingMatrix.cell[r,s] := (K_group[r] * K_group[s]) / TotalStrengthSum_2W;
    end;
  end;
end;

// --- Model 3: Fixed Outgoing Strength/Degree, Targets by Size ---

procedure CalculateExpectedMM_Model3_Directed(
  ExpectedMixingMatrix: tsmat;
  AdjMatrix: tsmat;
  Partition: tivec;
  GroupSizes: tivec);
var
  i, j, r, s, NumNodes, NumClasses: integer;
  S_out_group: array of Extended;
  val: Single;
begin
  NumNodes := AdjMatrix.n; // Use AdjMatrix.n
  numclasses:= groupsizes.n;

  SetLength(S_out_group, NumClasses + 1);
  for i := 1 to NumClasses do
    S_out_group[i] := 0;

  for i := 1 to NumNodes do
  begin
    r := Partition.cell[i];
    for j := 1 to NumNodes do
    begin
      val := AdjMatrix.cell[i,j];
      if val <> ucommon.na then
        S_out_group[r] := S_out_group[r] + val;
    end;
  end;

  ExpectedMixingMatrix.allocate(NumClasses, NumClasses, 1, true, true);
  ExpectedMixingMatrix.nr := NumClasses;
  ExpectedMixingMatrix.nc := NumClasses;

  if NumNodes <= 1 then
  begin
    Exit;
  end;

  for r := 1 to NumClasses do
  begin
    for s := 1 to NumClasses do
    begin
      if r = s then
        ExpectedMixingMatrix.cell[r,s] := S_out_group[r] * (GroupSizes[r] - 1) / (NumNodes - 1)
      else
        ExpectedMixingMatrix.cell[r,s] := S_out_group[r] * GroupSizes[s] / (NumNodes - 1);
    end;
  end;
end;

procedure CalculateExpectedMM_Model3_Undirected(
  ExpectedMixingMatrix: tsmat;
  AdjMatrix: tsmat;
  Partition: tivec;
  GroupSizes: tivec);
var
  i, j, r, s, NumNodes, NumClasses: integer;
  K_group: array of Extended;
  val: Single;
begin
  NumNodes := AdjMatrix.n; // Use AdjMatrix.n
  NumClasses:= groupsizes.n;

  SetLength(K_group, NumClasses + 1);
  for i := 1 to NumClasses do
    K_group[i] := 0;

  for i := 1 to NumNodes do
  begin
    r := Partition.cell[i];
    for j := 1 to NumNodes do
    begin
      val := AdjMatrix.cell[i,j];
      if val <> ucommon.na then
        K_group[r] := K_group[r] + val;
    end;
  end;

  ExpectedMixingMatrix.allocate(NumClasses, NumClasses, 1, true, true);
  ExpectedMixingMatrix.nr := NumClasses;
  ExpectedMixingMatrix.nc := NumClasses;

  if NumNodes <= 1 then
  begin
    Exit;
  end;

  for r := 1 to NumClasses do
  begin
    for s := r to NumClasses do
    begin
      if r = s then
        ExpectedMixingMatrix.cell[r,s] := K_group[r] * (GroupSizes[r] - 1) / (2.0 * (NumNodes - 1))
      else
      begin
        ExpectedMixingMatrix.cell[r,s] := (K_group[r] * GroupSizes[s] + K_group[s] * GroupSizes[r]) / (2.0 * (NumNodes - 1));
        ExpectedMixingMatrix.cell[s,r] := ExpectedMixingMatrix.cell[r,s];
      end;
    end;
  end;
end;

end.

