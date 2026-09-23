unit u2modelouvain;
(*===========================================================================
  Bipartite Communities via Louvain-style optimization of Barber's
  bipartite modularity Q_b (Barber 2007, "Modularity and community
  detection in bipartite networks").

  Q_b = (1/m) * sum over row-col pairs (i,j) of
          [A_ij - (dR_i * dC_j)/m] * delta(c_i, c_j)

  where dR_i = sum_j A_ij, dC_j = sum_i A_ij, m = sum A_ij, and c_u is
  the community label of node u. Communities span both modes (each
  community can contain row-nodes and col-nodes). The number of
  communities is chosen by the algorithm.

  Search: single-level Louvain-style local moving. Each sweep visits
  every node in a randomized order; for each node u, the move that
  best improves Q_b is applied (delta > 0 threshold). Sweeps repeat
  until no move is accepted.

  After convergence:
    - Community labels are compacted to 1..K.
    - RowPart (size nr) and ColPart (size nc) are returned. Row and
      col cluster labels are drawn from the SAME community index
      space, so equal labels across sides mean same community.

  Missing cells (>= na) are treated as zero, matching x2modefactions.
===========================================================================*)
interface
uses
  sysutils, math, classes,
  ucommon,
  utsmatds, utsmat, utivec;

type
  T2ModeLouvainResults = record
    RowPart:      tivec;      { size nr; values in 1..NumCommunities }
    ColPart:      tivec;      { size nc; values in 1..NumCommunities }
    NumCommunities:  integer;
    NumRowClusters:  integer; { distinct row-community labels }
    NumColClusters:  integer; { distinct col-community labels }
    Modularity:      double;  { final Q_b }
    Sweeps:          integer;
    Moves:           int64;
  end;

procedure TwoModeLouvain(data: tsmatds; seed: integer;
  var results: T2ModeLouvainResults);
procedure FreeTwoModeLouvainResults(var r: T2ModeLouvainResults);

{===========================================================================}
implementation
{===========================================================================}

type
  TNodeEdge = record
    other: integer;   { opposite-mode node id in adjacency space }
    w:     double;
  end;

  TAdj = array of array of TNodeEdge;

{ Adjacency indexing convention:
    row nodes: id 1..nr
    col nodes: id nr+1..nr+nc  (col j -> id nr+j)
  neighbors of a row node are all col node ids with A[i,j] <> 0; and
  vice versa.
}

{ ------------------------------------------------------------------------- }
procedure BuildAdjacency(data: tsmatds; var adj: TAdj;
  var dR, dC: array of double; var m: double);
var
  nr, nc, i, j: integer;
  v: single;
  cnt: array of integer;
  ntotal: integer;
begin
  nr := data.nr;
  nc := data.nc;
  ntotal := nr + nc;
  SetLength(adj, ntotal + 1);
  SetLength(cnt, ntotal + 1);
  for i := 0 to ntotal do cnt[i] := 0;

  m := 0;
  for i := 1 to nr do
    for j := 1 to nc do begin
      v := data.cell[i, j];
      if v >= na then v := 0;
      if v <> 0 then begin
        inc(cnt[i]);
        inc(cnt[nr + j]);
        m := m + v;
      end;
    end;

  for i := 1 to ntotal do
    SetLength(adj[i], cnt[i]);

  for i := 0 to ntotal do cnt[i] := 0;
  for i := 1 to nr do
    for j := 1 to nc do begin
      v := data.cell[i, j];
      if v >= na then v := 0;
      if v <> 0 then begin
        adj[i][cnt[i]].other := nr + j;
        adj[i][cnt[i]].w := v;
        inc(cnt[i]);
        adj[nr + j][cnt[nr + j]].other := i;
        adj[nr + j][cnt[nr + j]].w := v;
        inc(cnt[nr + j]);
      end;
    end;

  for i := 1 to nr do begin
    dR[i] := 0;
    for j := 0 to Length(adj[i]) - 1 do dR[i] := dR[i] + adj[i][j].w;
  end;
  for j := 1 to nc do begin
    dC[j] := 0;
    for i := 0 to Length(adj[nr + j]) - 1 do dC[j] := dC[j] + adj[nr + j][i].w;
  end;
end;

{ ------------------------------------------------------------------------- }
function ComputeModularity(nr, nc: integer; const c: array of integer;
  const dR, dC: array of double; const adj: TAdj; m: double): double;
var
  i, j, jj, cid, maxc: integer;
  q: double;
  Srow, Scol: array of double;
begin
  if m <= 0 then begin
    result := 0;
    exit;
  end;
  q := 0;
  { First term: sum A_ij over row-col pairs with same community. }
  for i := 1 to nr do begin
    cid := c[i];
    for jj := 0 to Length(adj[i]) - 1 do begin
      j := adj[i][jj].other;
      if c[j] = cid then q := q + adj[i][jj].w;
    end;
  end;
  { Second term: subtract sum dR_i * dC_j / m over same-community pairs. }
  maxc := 0;
  for i := 1 to nr + nc do
    if c[i] > maxc then maxc := c[i];
  SetLength(Srow, maxc + 1);
  SetLength(Scol, maxc + 1);
  for i := 0 to maxc do begin Srow[i] := 0; Scol[i] := 0; end;
  for i := 1 to nr do Srow[c[i]] := Srow[c[i]] + dR[i];
  for j := 1 to nc do Scol[c[nr + j]] := Scol[c[nr + j]] + dC[j];
  for i := 1 to maxc do q := q - Srow[i] * Scol[i] / m;
  result := q / m;
end;

{ ------------------------------------------------------------------------- }
procedure ShuffleArray(var a: array of integer; n: integer);
var
  i, k, t: integer;
begin
  for i := n - 1 downto 1 do begin
    k := random(i + 1);
    t := a[i]; a[i] := a[k]; a[k] := t;
  end;
end;

{ ------------------------------------------------------------------------- }
procedure TwoModeLouvain(data: tsmatds; seed: integer;
  var results: T2ModeLouvainResults);
var
  nr, nc, ntotal, u, i, j, cid, jj: integer;
  adj: TAdj;
  dR, dC: array of double;
  c: array of integer;
  Srow, Scol: array of double;   { per community sums }
  e_to_C: array of double;       { edge weight from u to community C's opposite mode }
  visited: array of integer;
  numVisited: integer;
  m, deg_u, ownSopp, bestGain, gain, cur, val: double;
  bestC, curC, Cnew, cid_v: integer;
  moved: boolean;
  order: array of integer;
  sweeps: integer;
  moves: int64;
  relabel: array of integer;
  nextlabel: integer;
  rowset, colset: array of boolean;
  nRow, nCol: integer;
begin
  if data = nil then
    raise Exception.Create('TwoModeLouvain: data is nil.');
  nr := data.nr;
  nc := data.nc;
  ntotal := nr + nc;
  if (nr < 1) or (nc < 1) then
    raise Exception.Create('TwoModeLouvain: empty matrix.');

  if seed = 0 then randomize else randseed := seed;

  SetLength(dR, nr + 1);
  SetLength(dC, nc + 1);
  BuildAdjacency(data, adj, dR, dC, m);

  { Initialize: each node in its own community. }
  SetLength(c, ntotal + 1);
  SetLength(Srow, ntotal + 1);
  SetLength(Scol, ntotal + 1);
  for u := 0 to ntotal do begin
    c[u] := u;
    Srow[u] := 0;
    Scol[u] := 0;
  end;
  for i := 1 to nr do Srow[i] := dR[i];
  for j := 1 to nc do Scol[nr + j] := dC[j];

  SetLength(e_to_C, ntotal + 1);
  SetLength(visited, ntotal + 1);
  for u := 0 to ntotal do e_to_C[u] := 0;

  SetLength(order, ntotal);
  for u := 0 to ntotal - 1 do order[u] := u + 1;

  sweeps := 0;
  moves := 0;
  if m > 0 then begin
    repeat
      moved := false;
      inc(sweeps);
      ShuffleArray(order, ntotal);
      for i := 0 to ntotal - 1 do begin
        u := order[i];
        curC := c[u];

        { Determine node degree (dR or dC). }
        if u <= nr then deg_u := dR[u]
        else               deg_u := dC[u - nr];
        if deg_u = 0 then continue;

        { Accumulate e_to_C[C] = sum of A[u,v] for opposite-mode
          neighbors v with c[v] = C. }
        numVisited := 0;
        for jj := 0 to Length(adj[u]) - 1 do begin
          cid_v := c[adj[u][jj].other];
          if e_to_C[cid_v] = 0 then begin
            visited[numVisited] := cid_v;
            inc(numVisited);
          end;
          e_to_C[cid_v] := e_to_C[cid_v] + adj[u][jj].w;
        end;

        { Contribution of u in community C (u is row -> use Scol[C];
          u is col -> use Srow[C]).
          Contrib(u,C) = e_to_C[C] - deg_u * Sopp[C]/m
          Note: ignoring self-contribution — u is currently in curC.
          For candidate C = curC, Sopp[curC] already reflects opposite-mode
          nodes only, unaffected by u's presence (u is on the other side). }

        { Current contribution. }
        if u <= nr then ownSopp := Scol[curC] else ownSopp := Srow[curC];
        cur := e_to_C[curC] - deg_u * ownSopp / m;

        bestC := curC;
        bestGain := 0;
        for jj := 0 to numVisited - 1 do begin
          Cnew := visited[jj];
          if Cnew = curC then continue;
          if u <= nr then val := Scol[Cnew] else val := Srow[Cnew];
          gain := (e_to_C[Cnew] - deg_u * val / m) - cur;
          if gain > bestGain + 1e-12 then begin
            bestGain := gain;
            bestC := Cnew;
          end;
        end;

        { Reset e_to_C. }
        for jj := 0 to numVisited - 1 do e_to_C[visited[jj]] := 0;

        if bestC <> curC then begin
          { Move u from curC to bestC. }
          if u <= nr then begin
            Srow[curC] := Srow[curC] - dR[u];
            Srow[bestC] := Srow[bestC] + dR[u];
          end
          else begin
            Scol[curC] := Scol[curC] - dC[u - nr];
            Scol[bestC] := Scol[bestC] + dC[u - nr];
          end;
          c[u] := bestC;
          inc(moves);
          moved := true;
        end;
      end;
    until (not moved) or (sweeps > 200);
  end;

  { Compact community labels to 1..K. }
  SetLength(relabel, ntotal + 1);
  for u := 0 to ntotal do relabel[u] := 0;
  nextlabel := 0;
  for u := 1 to ntotal do begin
    cid := c[u];
    if relabel[cid] = 0 then begin
      inc(nextlabel);
      relabel[cid] := nextlabel;
    end;
  end;
  for u := 1 to ntotal do c[u] := relabel[c[u]];

  { Count communities per side. }
  SetLength(rowset, nextlabel + 1);
  SetLength(colset, nextlabel + 1);
  for u := 0 to nextlabel do begin rowset[u] := false; colset[u] := false; end;
  for i := 1 to nr do rowset[c[i]] := true;
  for j := 1 to nc do colset[c[nr + j]] := true;
  nRow := 0; nCol := 0;
  for u := 1 to nextlabel do begin
    if rowset[u] then inc(nRow);
    if colset[u] then inc(nCol);
  end;

  { Build outputs. }
  results.NumCommunities := nextlabel;
  results.NumRowClusters := nRow;
  results.NumColClusters := nCol;
  results.Sweeps := sweeps;
  results.Moves := moves;

  { Recompute Q_b from final c (uses compacted labels). }
  results.Modularity := ComputeModularity(nr, nc, c, dR, dC, adj, m);

  results.RowPart := tivec.create;
  results.RowPart.allocate(nr, false);
  results.RowPart.n := nr;   { allocate does not set n }
  for i := 1 to nr do results.RowPart.cell[i] := c[i];

  results.ColPart := tivec.create;
  results.ColPart.allocate(nc, false);
  results.ColPart.n := nc;
  for j := 1 to nc do results.ColPart.cell[j] := c[nr + j];
end;

{ ------------------------------------------------------------------------- }
procedure FreeTwoModeLouvainResults(var r: T2ModeLouvainResults);
begin
  if Assigned(r.RowPart) then r.RowPart.Free;
  if Assigned(r.ColPart) then r.ColPart.Free;
  r.RowPart := nil;
  r.ColPart := nil;
end;

{===========================================================================}
end.
