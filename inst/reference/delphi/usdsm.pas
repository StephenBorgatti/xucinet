unit usdsm;
{===========================================================================}
{ Stochastic Degree Sequence Model (SDSM) Backbone Extraction.
  Neal (2014). "The backbone of bipartite projections..." Social Networks.

  Given a 2-mode (bipartite) matrix B with rows R and columns C, the 1-mode
  projection is P = B*B' (row mode) or B'*B (column mode). SDSM tests each
  cell P[i,j] against a null distribution drawn from random bipartite
  graphs that preserve the expected row and column degree sequences
  (configuration model). Cells with significantly more co-occurrences than
  expected (one-tailed) are retained as 1; all others are 0.

  Edge probabilities under the null can be obtained two ways (TSDSMModel):

  smLogit (default) - Neal's logistic SDSM, as implemented in the R
    "backbone" package. A single logistic regression is fit across all
    cells of the bipartite matrix:

        logit(p_ik) = b0 + b1*R_i + b2*C_k

    where R_i is the binary degree of row i and C_k the binary degree of
    column k. The fitted cell probabilities p_ik are used as the null edge
    probabilities. Fit by Newton-Raphson / IRLS (3 parameters). This is a
    low-dimensional surrogate for the per-node BiCM fitnesses and is what
    backbone::sdsm() uses by default (formula edge ~ rowmarg + colmarg,
    family binomial(link="logit"), no interaction term).

  smBiCM - the exact Bipartite Configuration Model (BiCM, Saracco et al.
    2015): fitnesses x_i, y_k are solved so that p_ik = x_i*y_k /
    (1 + x_i*y_k) yields expected row and column sums equal to the observed
    R_i, C_k. The fixed-point iteration

        x_i  <-  R_i / Sum_k [ y_k / (1 + x_i*y_k) ]
        y_k  <-  C_k / Sum_i [ x_i / (1 + x_i*y_k) ]

    is run to convergence. Rows with R_i = 0 or R_i = ncols (and the
    symmetric column cases) are pinned at p = 0 or p = 1 respectively.
    BiCM fixes the degree sequence exactly in expectation and is the more
    principled max-entropy null, but UCINET defaults to smLogit so that
    results agree with Neal's package.

  Co-occurrences of i and j across opposite-mode nodes are a sum of
  independent Bernoulli(q_k) variables with q_k = p_ik*p_jk. The exact
  upper-tail probability is computed by Poisson-Binomial convolution,
  matching R's backbone::sdsm().

  Input is treated as binary: any nonzero, non-missing cell counts as 1.
}
{===========================================================================}

interface
uses
  sysutils, math,
  ucommon, utsmatds, utlogfile;

type
  TSDSMMode = (smRows, smCols);
  TSDSMModel = (smLogit, smBiCM);

  TSDSMResults = record
    Backbone: tsmatds;
    Mode: TSDSMMode;
    Model: TSDSMModel;
    Alpha: double;
    NumNodes: integer;
    NumPairs: integer;
    SignificantEdges: integer;
    SolverIters: integer;
    SolverConverged: boolean;
    {Logit coefficients (valid when Model = smLogit).}
    LogitB0, LogitB1, LogitB2: double;
  end;

procedure SDSMBackbone(data: tsmatds; mode: TSDSMMode; model: TSDSMModel;
  alpha: double; var results: TSDSMResults);
procedure WriteSDSMResults(log: tlogfile; var results: TSDSMResults);
procedure FreeSDSMResults(var results: TSDSMResults);

{===========================================================================}
implementation
{===========================================================================}

const
  bicm_maxiter = 2000;
  bicm_tol     = 1e-8;
  pin_inf      = 1e12; {"infinity" fitness for pinned full-degree nodes}
  logit_maxiter = 100;
  logit_tol     = 1e-8;
  logit_etacap  = 30.0; {clamp linear predictor to avoid exp overflow}

type
  TMat3 = array[0..2, 0..2] of double;
  TVec3 = array[0..2] of double;

function PoissonBinomialUpperTailP(obs: integer; const q: array of double;
  nq: integer): double;
(* Exact P(S >= obs) where S = Sum_{k=0..nq-1} Bernoulli(q[k]).
  O(nq^2) DP convolution. q values clamped to [0,1]. *)
var
  prob, newprob: array of double;
  k, s, smax: integer;
  qk: double;
begin
  if obs <= 0 then begin result := 1.0; exit; end;
  if obs > nq then begin result := 0.0; exit; end;
  setlength(prob, nq + 1);
  setlength(newprob, nq + 1);
  prob[0] := 1.0;
  for s := 1 to nq do prob[s] := 0;
  smax := 0;
  for k := 0 to nq - 1 do begin
    qk := q[k];
    if qk < 0 then qk := 0 else if qk > 1 then qk := 1;
    smax := smax + 1;
    newprob[0] := prob[0] * (1 - qk);
    for s := 1 to smax do
      newprob[s] := prob[s - 1] * qk + prob[s] * (1 - qk);
    for s := 0 to smax do prob[s] := newprob[s];
  end;
  result := 0;
  for s := obs to nq do result := result + prob[s];
  if result < 0 then result := 0;
  if result > 1 then result := 1;
end;

function GetBinary(data: tsmatds; r, c: integer): double;
{ Read cell as 0/1. Missings (>= na) and zeros become 0; anything else 1. }
var
  v: single;
begin
  v := data.cell[r, c];
  if (v >= na) or (v = 0) then result := 0 else result := 1;
end;

function ProbIK(xi, yk: double): double;
{ p_ik = x_i * y_k / (1 + x_i * y_k), with pinned-fitness handling. }
begin
  if (xi <= 0) or (yk <= 0) then
    result := 0
  else if (xi >= pin_inf) or (yk >= pin_inf) then
    result := 1
  else
    result := xi * yk / (1.0 + xi * yk);
end;

procedure SolveBiCM(nrows, ncols: integer;
  const R, C: array of double;
  var x, y: array of double;
  var iters: integer; var converged: boolean);
{ Fixed-point solver for the Bipartite Configuration Model. }
var
  i, k, it: integer;
  M, denom, change, maxchange: double;
  newx, newy: array of double;
  pinned_x, pinned_y: array of boolean;
begin
  M := 0;
  for i := 1 to nrows do M := M + R[i];

  setlength(newx, nrows + 1);
  setlength(newy, ncols + 1);
  setlength(pinned_x, nrows + 1);
  setlength(pinned_y, ncols + 1);

  {Initialise. Pin boundary cases (degree 0 or full).}
  for i := 1 to nrows do begin
    pinned_x[i] := false;
    if R[i] <= 0 then begin x[i] := 0; pinned_x[i] := true; end
    else if R[i] >= ncols then begin x[i] := pin_inf; pinned_x[i] := true; end
    else if M > 0 then x[i] := R[i] / sqrt(M)
    else x[i] := 1;
  end;
  for k := 1 to ncols do begin
    pinned_y[k] := false;
    if C[k] <= 0 then begin y[k] := 0; pinned_y[k] := true; end
    else if C[k] >= nrows then begin y[k] := pin_inf; pinned_y[k] := true; end
    else if M > 0 then y[k] := C[k] / sqrt(M)
    else y[k] := 1;
  end;

  converged := false;
  iters := 0;
  for it := 1 to bicm_maxiter do begin
    {Update x using current y. Term y_k/(1+x_i*y_k) -> 1/x_i as y_k -> inf.
     For pinned-low y (y_k=0) the term is 0 and contributes nothing.}
    for i := 1 to nrows do begin
      if pinned_x[i] then begin newx[i] := x[i]; continue; end;
      denom := 0;
      for k := 1 to ncols do begin
        if y[k] <= 0 then continue
        else if y[k] >= pin_inf then begin
          if x[i] > 0 then denom := denom + 1.0 / x[i];
        end
        else
          denom := denom + y[k] / (1.0 + x[i] * y[k]);
      end;
      if denom > 0 then newx[i] := R[i] / denom else newx[i] := x[i];
    end;

    {Update y using newx. Symmetric handling.}
    for k := 1 to ncols do begin
      if pinned_y[k] then begin newy[k] := y[k]; continue; end;
      denom := 0;
      for i := 1 to nrows do begin
        if newx[i] <= 0 then continue
        else if newx[i] >= pin_inf then begin
          if y[k] > 0 then denom := denom + 1.0 / y[k];
        end
        else
          denom := denom + newx[i] / (1.0 + newx[i] * y[k]);
      end;
      if denom > 0 then newy[k] := C[k] / denom else newy[k] := y[k];
    end;

    maxchange := 0;
    for i := 1 to nrows do begin
      if pinned_x[i] then continue;
      change := abs(newx[i] - x[i]);
      if change > maxchange then maxchange := change;
      x[i] := newx[i];
    end;
    for k := 1 to ncols do begin
      if pinned_y[k] then continue;
      change := abs(newy[k] - y[k]);
      if change > maxchange then maxchange := change;
      y[k] := newy[k];
    end;

    iters := it;
    if maxchange < bicm_tol then begin
      converged := true;
      break;
    end;
  end;
end;

function Det3(a11, a12, a13, a21, a22, a23, a31, a32, a33: double): double;
begin
  result := a11 * (a22 * a33 - a23 * a32)
          - a12 * (a21 * a33 - a23 * a31)
          + a13 * (a21 * a32 - a22 * a31);
end;

function Solve3x3(const M: TMat3; const b: TVec3; var sol: TVec3): boolean;
{ Solve M*sol = b for a 3x3 system via Cramer's rule. }
var
  det, d0, d1, d2: double;
begin
  det := Det3(M[0,0], M[0,1], M[0,2],
              M[1,0], M[1,1], M[1,2],
              M[2,0], M[2,1], M[2,2]);
  if abs(det) < 1e-300 then begin result := false; exit; end;
  d0 := Det3(b[0], M[0,1], M[0,2],
             b[1], M[1,1], M[1,2],
             b[2], M[2,1], M[2,2]);
  d1 := Det3(M[0,0], b[0], M[0,2],
             M[1,0], b[1], M[1,2],
             M[2,0], b[2], M[2,2]);
  d2 := Det3(M[0,0], M[0,1], b[0],
             M[1,0], M[1,1], b[1],
             M[2,0], M[2,1], b[2]);
  sol[0] := d0 / det;
  sol[1] := d1 / det;
  sol[2] := d2 / det;
  result := true;
end;

function LogisticP(eta: double): double;
{ Numerically safe logistic transform with clamped linear predictor. }
begin
  if eta > logit_etacap then eta := logit_etacap
  else if eta < -logit_etacap then eta := -logit_etacap;
  result := 1.0 / (1.0 + exp(-eta));
end;

procedure SolveLogitSDSM(data: tsmatds; nrows, ncols: integer;
  const R, C: array of double;
  var b0, b1, b2: double; var iters: integer; var converged: boolean);
{ Fit logit(p_ik) = b0 + b1*R_i + b2*C_k over all cells by Newton/IRLS.
  Response is the binary edge indicator; predictors are the binary row
  and column degrees. Matches backbone::sdsm (edge ~ rowmarg + colmarg). }
var
  it, i, k, aa, bb: integer;
  eta, p, w, resid, yik, maxchange: double;
  H: TMat3;
  g, delta, xv: TVec3;
begin
  b0 := 0; b1 := 0; b2 := 0;
  converged := false;
  iters := 0;
  for it := 1 to logit_maxiter do begin
    for aa := 0 to 2 do begin
      g[aa] := 0;
      for bb := 0 to 2 do H[aa, bb] := 0;
    end;
    for i := 1 to nrows do
      for k := 1 to ncols do begin
        yik := GetBinary(data, i, k);
        xv[0] := 1.0; xv[1] := R[i]; xv[2] := C[k];
        eta := b0 + b1 * R[i] + b2 * C[k];
        p := LogisticP(eta);
        w := p * (1.0 - p);
        resid := yik - p;
        for aa := 0 to 2 do begin
          g[aa] := g[aa] + xv[aa] * resid;
          for bb := 0 to 2 do H[aa, bb] := H[aa, bb] + xv[aa] * xv[bb] * w;
        end;
      end;
    if not Solve3x3(H, g, delta) then begin
      {Singular Hessian (e.g. perfect separation); stop with current betas.}
      converged := false;
      break;
    end;
    b0 := b0 + delta[0];
    b1 := b1 + delta[1];
    b2 := b2 + delta[2];
    iters := it;
    maxchange := max(abs(delta[0]), max(abs(delta[1]), abs(delta[2])));
    if maxchange < logit_tol then begin
      converged := true;
      break;
    end;
  end;
end;

{---------------------------------------------------------------------------}
procedure SDSMBackbone(data: tsmatds; mode: TSDSMMode; model: TSDSMModel;
  alpha: double; var results: TSDSMResults);
var
  nrows, ncols, nproj, noth: integer;
  R, C: array of double;
  x, y: array of double;
  P: array of array of double; {cell probabilities p_ik, 1..nrows x 1..ncols}
  q: array of double;
  i, j, k: integer;
  bik, bjk, p_ik, p_jk: double;
  b0, b1, b2: double;
  observed: integer;
  pval: double;
  outmat: tsmatds;
  signif, iters: integer;
  converged, hasdata: boolean;
  s: string;
begin
  nrows := data.nr;
  ncols := data.nc;
  if (alpha <= 0) or (alpha >= 1) then
    raise Exception.Create('SDSM: alpha must be between 0 and 1.');

  if mode = smRows then begin
    nproj := nrows; noth := ncols;
  end
  else begin
    nproj := ncols; noth := nrows;
  end;

  {Compute binary row/column degrees.}
  setlength(R, nrows + 1);
  setlength(C, ncols + 1);
  for i := 1 to nrows do R[i] := 0;
  for j := 1 to ncols do C[j] := 0;
  hasdata := false;
  for i := 1 to nrows do
    for j := 1 to ncols do begin
      bik := GetBinary(data, i, j);
      if bik > 0 then hasdata := true;
      R[i] := R[i] + bik;
      C[j] := C[j] + bik;
    end;

  {Build cell-probability matrix P[i,k] from the chosen null model.}
  setlength(P, nrows + 1);
  for i := 0 to nrows do setlength(P[i], ncols + 1);
  iters := 0;
  converged := true;
  b0 := 0; b1 := 0; b2 := 0;
  if hasdata then begin
    if model = smBiCM then begin
      setlength(x, nrows + 1);
      setlength(y, ncols + 1);
      SolveBiCM(nrows, ncols, R, C, x, y, iters, converged);
      for i := 1 to nrows do
        for k := 1 to ncols do
          P[i][k] := ProbIK(x[i], y[k]);
    end
    else begin
      SolveLogitSDSM(data, nrows, ncols, R, C, b0, b1, b2, iters, converged);
      for i := 1 to nrows do
        for k := 1 to ncols do
          P[i][k] := LogisticP(b0 + b1 * R[i] + b2 * C[k]);
    end;
  end;

  {Allocate output backbone matrix.}
  outmat := tsmatds.create;
  outmat.allocate(nproj, nproj, 1, true, true);
  outmat.title := 'SDSM Backbone (alpha=' +
    FloatToStrF(alpha, ffFixed, 10, 4) + ')';
  for i := 1 to nproj do begin
    if mode = smRows then s := data.rdvn.labelget(i)
    else s := data.cdvn.labelget(i);
    outmat.rdvn.sput(i, s);
    outmat.cdvn.sput(i, s);
  end;
  for i := 1 to nproj do
    for j := 1 to nproj do
      outmat.cell[i, j] := 0;

  setlength(q, noth);
  signif := 0;
  if hasdata then
    for i := 1 to nproj do
      for j := i + 1 to nproj do begin
        observed := 0;
        for k := 1 to noth do begin
          if mode = smRows then begin
            bik := GetBinary(data, i, k);
            bjk := GetBinary(data, j, k);
            p_ik := P[i][k];
            p_jk := P[j][k];
          end
          else begin
            bik := GetBinary(data, k, i);
            bjk := GetBinary(data, k, j);
            p_ik := P[k][i];
            p_jk := P[k][j];
          end;
          if (bik > 0) and (bjk > 0) then inc(observed);
          q[k - 1] := p_ik * p_jk;
        end;
        pval := PoissonBinomialUpperTailP(observed, q, noth);
        if pval < alpha then begin
          outmat.cell[i, j] := 1;
          outmat.cell[j, i] := 1;
          inc(signif);
        end;
      end;

  results.Backbone := outmat;
  results.Mode := mode;
  results.Model := model;
  results.Alpha := alpha;
  results.NumNodes := nproj;
  results.NumPairs := nproj * (nproj - 1) div 2;
  results.SignificantEdges := signif;
  results.SolverIters := iters;
  results.SolverConverged := converged;
  results.LogitB0 := b0;
  results.LogitB1 := b1;
  results.LogitB2 := b2;
end;

{---------------------------------------------------------------------------}
procedure WriteSDSMResults(log: tlogfile; var results: TSDSMResults);
var
  pct: double;
begin
  log.lf;
  if results.Model = smLogit
    then log.putstr('Null model:', 'Logistic SDSM (logit p = b0 + b1*R + b2*C)')
    else log.putstr('Null model:', 'BiCM (bipartite configuration model)');
  if results.Mode = smRows
    then log.putint('Projected nodes (rows):', results.NumNodes)
    else log.putint('Projected nodes (columns):', results.NumNodes);
  log.putfloat('Alpha (one-tailed):', results.Alpha, 0, 4);
  log.putint('Pairs tested:', results.NumPairs);
  log.putint('Significant edges retained:', results.SignificantEdges);
  if results.NumPairs > 0 then
    pct := 100.0 * results.SignificantEdges / results.NumPairs
  else
    pct := 0.0;
  log.putfloat('Percent of pairs retained:', pct, 0, 2);
  if results.Model = smLogit then begin
    log.putfloat('Logit intercept (b0):', results.LogitB0, 0, 4);
    log.putfloat('Logit row-degree coef (b1):', results.LogitB1, 0, 4);
    log.putfloat('Logit col-degree coef (b2):', results.LogitB2, 0, 4);
    log.putint('IRLS iterations:', results.SolverIters);
    if results.SolverConverged
      then log.putstr('IRLS convergence:', 'yes')
      else log.putstr('IRLS convergence:', 'NO (check separation / max iters)');
  end
  else begin
    log.putint('BiCM iterations:', results.SolverIters);
    if results.SolverConverged
      then log.putstr('BiCM convergence:', 'yes')
      else log.putstr('BiCM convergence:', 'NO (check tolerance / max iters)');
  end;
  log.lf;
end;

{---------------------------------------------------------------------------}
procedure FreeSDSMResults(var results: TSDSMResults);
begin
  if Assigned(results.Backbone) then results.Backbone.Free;
  results.Backbone := nil;
end;

{===========================================================================}
end.
