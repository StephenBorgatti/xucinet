unit umrqapdekker;
interface
uses
  classes, sysutils, math, system.threading, system.syncobjs,
  ucommon, utsmat, utevec, utivec, utdvec, utvec, utunivariate, utdmat,
  ug2svd, ug2regression, urestrictedqap, urandomthreadsafe;

const
  trBetas = 0; trTstats = 1;

type
  tboolmatrix = array of array of boolean;

  tmrqapdekker = class
    // Config
    n, nx, nx1, ncells, nperm, seed: integer;
    sym, diagok, hasmissing, useparallel, onetailed: boolean;
    trackmethod: integer;  // 0=Betas, 1=T-stats

    // Data (loaded by caller before calling run)
    ymat: tsmat;
    xmats: array of tsmat;  // [1..nx]
    storedx: tsmat;
    ismissing: tboolmatrix;
    map: tivec;
    ncat: integer;
    cat: array of tivec;

    // Observed results
    coef, beta, robustse, obst: tdvec;
    collinrsqr: tdvec;  // R-squared of each IV predicted by the other IVs
    rsqr, adjrsqr, prsqr: double;

    // Predicted & residual matrices (built during observed regression)
    combo, resid: tsmat;

    // Permutation tracking
    cstats, tstats: array of tunivariate;  // [1..nx1]
    lstat: tunivariate;
    seeds: array of integer;

    constructor create;
    destructor destroy; override;
    procedure run;
    procedure runobservedregression;
    procedure runrsquaredpermutations;
    procedure getpartialresidual(k: integer);
    procedure regressresidual(k: integer);
    procedure buildftab(ftab: tsmat);
    procedure buildctab(ctab: tsmat);
    procedure buildpredicted(pred: tsmat);
    procedure buildresiduals(rmat: tsmat);
  end;

procedure mrqapdekker(ftab, ctab, predmat, residmat: tsmat;
  ymat: tsmat; xmats: array of tsmat;
  ismissing: tboolmatrix;
  map: tivec; ncat: integer; cat: array of tivec;
  var hasmiss: boolean;
  onetailed: boolean = false;
  track: integer = 1;
  maxperm: integer = 5000;
  aseed: integer = 0;
  parallel: boolean = false);

implementation

{---------------------------------------------------------------------------}
procedure mrqapdekker(ftab, ctab, predmat, residmat: tsmat;
  ymat: tsmat; xmats: array of tsmat;
  ismissing: tboolmatrix;
  map: tivec; ncat: integer; cat: array of tivec;
  var hasmiss: boolean;
  onetailed: boolean = false;
  track: integer = 1;
  maxperm: integer = 5000;
  aseed: integer = 0;
  parallel: boolean = false);
var
  q: tmrqapdekker;
  i: integer;
begin try
  q := tmrqapdekker.create;
  q.n := ymat.nr;
  q.nx := length(xmats) - 1;  // xmats is [1..nx]
  q.nx1 := q.nx + 1;
  q.onetailed := onetailed;
  q.trackmethod := track;
  q.nperm := maxperm;
  q.seed := aseed;
  q.useparallel := parallel;
  q.ymat := ymat;
  // Copy open array params into dynamic arrays
  setlength(q.xmats, length(xmats));
  for i := 0 to high(xmats) do q.xmats[i] := xmats[i];
  setlength(q.ismissing, length(ismissing));
  for i := 0 to high(ismissing) do q.ismissing[i] := ismissing[i];
  q.map := map;
  q.ncat := ncat;
  setlength(q.cat, length(cat));
  for i := 0 to high(cat) do q.cat[i] := cat[i];
  q.run;
  q.buildftab(ftab);
  q.buildctab(ctab);
  q.buildpredicted(predmat);
  q.buildresiduals(residmat);
  hasmiss := q.hasmissing;
  finally
    q.free;
  end;
end;
{---------------------------------------------------------------------------}
constructor tmrqapdekker.create;
begin
  coef := tdvec.create;
  beta := tdvec.create;
  robustse := tdvec.create;
  obst := tdvec.create;
  collinrsqr := tdvec.create;
  storedx := tsmat.create;
  combo := tsmat.create;
  resid := tsmat.create;
  lstat := tunivariate.create;
  map := nil;    // assigned by caller
  diagok := false;
  onetailed := false;
  useparallel := false;
  trackmethod := trTstats;
end;
{---------------------------------------------------------------------------}
destructor tmrqapdekker.destroy;
var
  j: integer;
begin
  coef.free;
  beta.free;
  robustse.free;
  obst.free;
  collinrsqr.free;
  storedx.free;
  combo.free;
  resid.free;
  for j := 1 to length(cstats) - 1 do begin
    if j < length(cstats) then cstats[j].free;
    if j < length(tstats) then tstats[j].free;
  end;
  cstats := nil;
  tstats := nil;
  lstat.free;
  inherited destroy;
end;
{---------------------------------------------------------------------------}
procedure tmrqapdekker.run;
var
  j, k: integer;
begin
  // Auto-detect symmetry: only use lower half if ALL matrices are symmetric
  // Uses IsSymmetric which checks with singleprecision tolerance (samevalue)
  sym := ymat.IsSymmetric;
  if sym then
    for k := 1 to nx do
      if not xmats[k].IsSymmetric then begin
        sym := false;
        break;
      end;

  if sym
    then ncells := n * (n - 1) div 2
    else ncells := n * (n - 1);

  // Allocate result vectors
  coef.allocsize(nx1);
  beta.allocsize(nx1);
  robustse.allocsize(nx1);
  obst.allocsize(nx1);
  collinrsqr.allocsize(nx);

  // Allocate permutation stats
  setlength(cstats, nx1 + 1);
  setlength(tstats, nx1 + 1);
  for j := 1 to nx1 do begin
    cstats[j] := tunivariate.create;
    tstats[j] := tunivariate.create;
  end;

  // Pre-generate seeds
  if seed = 0 then seed := getrandomseed;
  setlength(seeds, nperm + 1);
  for j := 1 to nperm do
    seeds[j] := randomint(maxint, seed);

  // 1. Run observed regression (OLS + Huber-White)
  runobservedregression;

  // 2. Run R-squared permutations
  runrsquaredpermutations;

  // 3. For each IV, semi-partial and permute
  for k := 1 to nx do begin
    storedx.copy(xmats[k]);
    getpartialresidual(k);
    regressresidual(k);
    xmats[k].copy(storedx);
  end;

  // 4. Finalize stats
  for j := 1 to nx1 do begin
    cstats[j].calc;
    tstats[j].calc;
  end;
  lstat.calc;
end;
{---------------------------------------------------------------------------}
procedure tmrqapdekker.runobservedregression;
type
  tindex = record
    idx, jdx: integer;
  end;
var
  x, xtx, vmat, inv, meat, sand: tsmat;
  y, b, se, sdx, w, xty: tevec;
  ind: array of tindex;
  sx: array of double;
  sy_mean, sy_mcssq, sdy, dx: double;
  mx, mcx, ddx: double;
  i, j, k, m, np, ncase, rank: integer;
  toty, yty, btxty, sse, sst, lc, e_m, v_val, tmp: extended;

  procedure addcase(var am: integer; ai, aj: integer);
  var l: integer;
  begin
    if ismissing[ai, aj] then exit;
    inc(am);
    ind[am].idx := ai; ind[am].jdx := aj;
    y.cell[am] := ymat.cell[ai, aj];
    for l := 1 to nx do
      x.cell[am, l] := xmats[l].cell[ai, aj];
    x.cell[am, nx1] := 1;
  end;

begin
  x := tsmat.create;
  xtx := tsmat.create;
  y := tevec.create;
  b := tevec.create;
  se := tevec.create;
  sdx := tevec.create;
  w := tevec.create;
  xty := tevec.create;
  vmat := tsmat.create;
  inv := tsmat.create;
  meat := tsmat.create;
  sand := tsmat.create;
  try
    np := ncells;
    x.allocate(np, nx1, 1, true, true);
    y.allocate(np, true, true);
    b.allocsize(nx1);
    se.allocsize(nx1);
    sdx.allocsize(nx1);
    setlength(ind, np + 1);

    // Build design matrix
    m := 0;
    if sym
      then for i := 2 to n do for j := 1 to i - 1 do addcase(m, i, j)
      else for i := 1 to n do for j := 1 to n do if (i <> j) then addcase(m, i, j);
    x.nr := m; y.n := m;
    ncells := m;
    ncase := m;

    hasmissing := ncase < np;

    // Compute sdy for standardized betas (Welford's method)
    sy_mean := 0; sy_mcssq := 0;
    for i := 1 to ncase do begin
      dx := y.cell[i] - sy_mean;
      sy_mean := sy_mean + dx / i;
      sy_mcssq := sy_mcssq + (y.cell[i] - sy_mean) * dx;
    end;
    if ncase > 0 then sdy := sqrt(sy_mcssq / ncase) else sdy := 0;

    // Compute sdx for each variable (Welford's)
    for k := 1 to nx do begin
      mx := 0; mcx := 0;
      for i := 1 to ncase do begin
        ddx := x.cell[i, k] - mx;
        mx := mx + ddx / i;
        mcx := mcx + (x.cell[i, k] - mx) * ddx;
      end;
      if ncase > 0 then sdx.cell[k] := sqrt(mcx / ncase) else sdx.cell[k] := 0;
    end;

    // --- SVD regression for OLS coefficients ---
    // Build X'X and X'y (keeping X intact for sandwich estimator)
    xtx.allocate(nx1, nx1, 1, true, true);
    xty.allocate(nx1, true, true);
    yty := 0; toty := 0;
    for k := 1 to ncase do begin
      for i := 1 to nx1 do
        for j := 1 to i do begin
          xtx.cell[i, j] := xtx.cell[i, j] + x.cell[k, i] * x.cell[k, j];
          xtx.cell[j, i] := xtx.cell[i, j];
        end;
      yty := yty + sqr(y.cell[k]);
      toty := toty + y.cell[k];
      for i := 1 to nx1 do
        xty.cell[i] := xty.cell[i] + x.cell[k, i] * y.cell[k];
    end;

    // SVD of X'X
    vmat.allocate(nx1, nx1, 1, true, true);
    w.allocsize(nx1);
    svd(xtx, vmat, w, rank);
    svdbacksub(xtx, vmat, w, xty, b);

    // Get (X'X)^-1 for standard errors and sandwich
    getinversefromsvd(inv, xtx, vmat, w);

    // Compute R-squared
    btxty := 0;
    for j := 1 to nx1 do
      btxty := btxty + b.cell[j] * xty.cell[j];
    sse := yty - btxty;
    sst := yty - toty * (toty / ncase);
    if sst > 0
      then rsqr := 1.0 - sse / sst
      else rsqr := bna;
    adjrsqr := 1.0 - (1.0 - rsqr) * (1.0 * ncase - 1) / (1.0 * ncase - nx - 1.0);

    // Store coefficients
    for j := 1 to nx1 do
      coef.cell[j] := b.cell[j];

    // Standardized betas
    if sdy > doubleprecision then
      for k := 1 to nx do
        beta.cell[k] := coef.cell[k] * sdx.cell[k] / sdy;

    // --- Huber-White HC0 sandwich estimator ---
    // meat[i,j] = sum_m(X[m,i] * e[m]^2 * X[m,j])
    meat.allocate(nx1, nx1, 1, true, true);
    for i := 1 to ncase do begin
      lc := 0;
      for j := 1 to nx1 do
        lc := lc + x.cell[i, j] * b.cell[j];
      e_m := y.cell[i] - lc;
      for j := 1 to nx1 do
        for k := 1 to nx1 do
          meat.cell[j, k] := meat.cell[j, k] + x.cell[i, j] * sqr(e_m) * x.cell[i, k];
    end;

    // sandwich = inv * meat * inv
    sand.allocate(nx1, nx1, 1, true, true);
    for i := 1 to nx1 do
      for j := 1 to nx1 do begin
        v_val := 0;
        for k := 1 to nx1 do begin
          tmp := 0;
          for m := 1 to nx1 do
            tmp := tmp + inv.cell[i, m] * meat.cell[m, k];
          v_val := v_val + tmp * inv.cell[k, j];
        end;
        sand.cell[i, j] := v_val;
      end;

    // Extract robust SEs and t-statistics
    for j := 1 to nx1 do begin
      if sand.cell[j, j] > 0
        then robustse.cell[j] := sqrt(sand.cell[j, j])
        else robustse.cell[j] := 0;
      if robustse.cell[j] > doubleprecision
        then obst.cell[j] := coef.cell[j] / robustse.cell[j]
        else obst.cell[j] := bna;
    end;

    // Build predicted and residual matrices
    combo.allocate(n, n, 1, true, true);
    combo.nafill;
    resid.allocate(n, n, 1, true, true);
    resid.nafill;
    for m := 1 to ncase do begin
      lc := 0;
      for j := 1 to nx1 do
        lc := lc + b.cell[j] * x.cell[m, j];
      combo.cell[ind[m].idx, ind[m].jdx] := lc;
      resid.cell[ind[m].idx, ind[m].jdx] := y.cell[m] - lc;
      if sym then begin
        combo.cell[ind[m].jdx, ind[m].idx] := combo.cell[ind[m].idx, ind[m].jdx];
        resid.cell[ind[m].jdx, ind[m].idx] := resid.cell[ind[m].idx, ind[m].jdx];
      end;
    end;

  finally
    x.free; xtx.free; y.free; b.free; se.free; sdx.free; w.free; xty.free;
    vmat.free; inv.free; meat.free; sand.free;
    ind := nil;
    sx := nil;
  end;
end;
{---------------------------------------------------------------------------}
procedure tmrqapdekker.runrsquaredpermutations;
var
  qc: trqapcorr;
  group: tivec;
  i: integer;
begin
  qc := trqapcorr.create;
  try
    group := tivec.create;
    try
      group.allocsize(n);
      if (map <> nil) and (map.n >= n)
        then begin for i := 1 to n do group.cell[i] := map[i]; end
        else group.fill(1, n);
      qc.run(ymat, combo, group, nperm);
      prsqr := qc.q.pgreat;
    finally
      group.free;
    end;
  finally
    qc.destroy;
  end;
end;
{---------------------------------------------------------------------------}
procedure tmrqapdekker.getpartialresidual(k: integer);
type
  tindex = record
    idx, jdx: integer;
  end;
var
  i, j, l, ll, m, np: integer;
  x: tsmat;
  yy, b: tevec;
  localrsqr, lc: double;
  ind: array of tindex;
begin
  x := tsmat.create;
  yy := tevec.create;
  b := tevec.create;
  try
    np := ncells;
    x.allocate(np, nx, 1, true, true);
    x.nc := nx;  // nx-1 other IVs + 1 intercept
    yy.allocate(np, true, true);
    b.allocsize(nx);
    storedx.copy(xmats[k]);
    setlength(ind, np + 1);

    // Build design matrix: Y=xmats[k], X=all other xmats + intercept
    m := 0;
    if sym then begin
      for i := 2 to n do for j := 1 to i - 1 do begin
        if ismissing[i, j] then continue;
        inc(m);
        ind[m].idx := i; ind[m].jdx := j;
        yy.cell[m] := xmats[k].cell[i, j];
        ll := 0;
        for l := 1 to nx do if l <> k then begin
          inc(ll);
          x.cell[m, ll] := xmats[l].cell[i, j];
        end;
        x.cell[m, x.nc] := 1;
      end;
    end else begin
      for i := 1 to n do for j := 1 to n do if (i <> j) then begin
        if ismissing[i, j] then continue;
        inc(m);
        ind[m].idx := i; ind[m].jdx := j;
        yy.cell[m] := xmats[k].cell[i, j];
        ll := 0;
        for l := 1 to nx do if l <> k then begin
          inc(ll);
          x.cell[m, ll] := xmats[l].cell[i, j];
        end;
        x.cell[m, x.nc] := 1;
      end;
    end;
    x.nr := m; yy.n := m;

    basicsvdregression(localrsqr, b, x, yy);
    collinrsqr.cell[k] := localrsqr;

    // Replace xmats[k] with residuals
    // SVD destroyed x, so recompute linear combos from stored xmats
    for m := 1 to yy.n do begin
      lc := 0;
      ll := 0;
      for l := 1 to nx do if l <> k then begin
        inc(ll);
        lc := lc + b.cell[ll] * xmats[l].cell[ind[m].idx, ind[m].jdx];
      end;
      lc := lc + b.cell[nx] * 1.0; // intercept
      xmats[k].cell[ind[m].idx, ind[m].jdx] := storedx.cell[ind[m].idx, ind[m].jdx] - lc;
      if sym then
        xmats[k].cell[ind[m].jdx, ind[m].idx] := xmats[k].cell[ind[m].idx, ind[m].jdx];
    end;
  finally
    b.free; yy.free; x.free;
    ind := nil;
  end;
end;
{---------------------------------------------------------------------------}
procedure tmrqapdekker.regressresidual(k: integer);
type
  tindex = record
    idx, jdx: integer;
  end;
var
  i, j, l, l2, m, np, nvalid, ncase: integer;
  id: tivec;
  catcopy: tivec;
  ot: double;
  rank: integer;

  // Optimized path: column storage and pre-computed cross-products
  xcols: array of tevec;
  yvec: tevec;
  ind: array of tindex;
  xtx_base, xtx_work, vmat_w: tdmat;
  xty_base, xty_work, w_w, bvec, ob: tevec;
  yty, toty: extended;

  // Fallback path (hasmissing=true): full design matrix per iteration
  xfb: tsmat;
  yfb, bfb, ob_fb, se_fb: tevec;
  localrsqr_fb: double;

  procedure permuteidvariable(aid: tivec; aseed: integer; acatcopy: tivec);
  var ii, jj, node: integer;
  begin
    for ii := 1 to n do aid[ii] := ii;
    for ii := 1 to ncat do begin
      acatcopy.copy(cat[ii]);
      acatcopy.randomlypermute(aseed);
      acatcopy.resetcurrent;
      for jj := 1 to cat[ii].n do begin
        node := cat[ii].cell[jj];
        aid[node] := acatcopy.getnextvalue;
      end;
    end;
  end;

  // ===== OPTIMIZED PATH: rank-1 X'X update (no missing values) =====

  procedure runsequential_opt;
  var
    it_s, mm, ll, ll2: integer;
    pval, bk, ts, inv_kk, mse_val, btxty_s, sse_s, se_sq: extended;
  begin
    for it_s := 1 to nperm - 1 do begin
      permuteidvariable(id, seeds[it_s], catcopy);

      // Copy base to work
      for ll := 1 to nx1 do begin
        for ll2 := 1 to nx1 do
          xtx_work.cell[ll, ll2] := xtx_base.cell[ll, ll2];
        xty_work.cell[ll] := xty_base.cell[ll];
      end;

      // Add permuted column k's contribution to row k
      for mm := 1 to ncase do begin
        pval := xmats[k].cell[id[ind[mm].idx], id[ind[mm].jdx]];
        for ll := 1 to nx1 do
          xtx_work.cell[k, ll] := xtx_work.cell[k, ll] + pval * xcols[ll].cell[mm];
        xty_work.cell[k] := xty_work.cell[k] + pval * yvec.cell[mm];
      end;

      // Symmetrize row/col k
      for ll := 1 to nx1 do
        xtx_work.cell[ll, k] := xtx_work.cell[k, ll];

      // SVD solve
      svd(xtx_work, vmat_w, w_w, rank);
      svdbacksub(xtx_work, vmat_w, w_w, xty_work, bvec);

      bk := bvec.cell[k];
      if abs(bk) < doubleprecision then bk := 0;
      cstats[k].addcase(bk, ob.cell[k]);

      // Compute inv[k,k] for SE
      inv_kk := 0;
      for ll := 1 to nx1 do
        if w_w.cell[ll] > doubleprecision then
          inv_kk := inv_kk + vmat_w.cell[k, ll] * xtx_work.cell[k, ll] / w_w.cell[ll];

      // Compute MSE
      btxty_s := 0;
      for ll := 1 to nx1 do
        btxty_s := btxty_s + bvec.cell[ll] * xty_work.cell[ll];
      sse_s := yty - btxty_s;
      mse_val := sse_s / (ncase - nx1);
      se_sq := mse_val * inv_kk;

      if se_sq > doubleprecision then begin
        ts := bk / se_sq;
        tstats[k].addcase(ts, ot);
        inc(nvalid);
      end;
    end;
  end;

  procedure runparallel_opt;
  var
    c_ge, c_le, c_ext, c_n: integer;
    c_sum, c_ssq, c_min, c_max: double;
    t_ge, t_le, t_ext, t_n: integer;
    t_sum, t_ssq, t_min, t_max: double;
    cs: tcriticalsection;
  begin
    c_ge := 0; c_le := 0; c_ext := 0; c_n := 0;
    c_sum := 0; c_ssq := 0;
    c_min := maxextended; c_max := -maxextended;
    t_ge := 0; t_le := 0; t_ext := 0; t_n := 0;
    t_sum := 0; t_ssq := 0;
    t_min := maxextended; t_max := -maxextended;
    cs := tcriticalsection.create;
    try
      TParallel.For(1, nperm - 1, procedure(it_p: integer)
        var
          lxtx, lvmat: tdmat;
          lxty, lw, lb: tevec;
          lid: tivec;
          lcatcopy: tivec;
          ll, ll2, lm, lseed, node: integer;
          lpval, lbk, lts, linv_kk, lmse, lbtxty, lsse, lse_sq: extended;
          lrank: integer;
        begin
          lxtx := tdmat.create;
          lvmat := tdmat.create;
          lxty := tevec.create;
          lw := tevec.create;
          lb := tevec.create;
          lid := tivec.create;
          lcatcopy := tivec.create;
          try
            lxtx.allocsize(nx1, nx1);
            lvmat.allocsize(nx1, nx1);
            lxty.allocsize(nx1);
            lw.allocsize(nx1);
            lb.allocsize(nx1);
            lid.allocsize(n);

            // Permute
            lseed := seeds[it_p];
            for ll := 1 to n do lid[ll] := ll;
            for ll := 1 to ncat do begin
              lcatcopy.copy(cat[ll]);
              lcatcopy.randomlypermute(lseed);
              lcatcopy.resetcurrent;
              for ll2 := 1 to cat[ll].n do begin
                node := cat[ll].cell[ll2];
                lid[node] := lcatcopy.getnextvalue;
              end;
            end;

            // Copy base to work
            for ll := 1 to nx1 do begin
              for ll2 := 1 to nx1 do
                lxtx.cell[ll, ll2] := xtx_base.cell[ll, ll2];
              lxty.cell[ll] := xty_base.cell[ll];
            end;

            // Add permuted column k's contribution
            for lm := 1 to ncase do begin
              lpval := xmats[k].cell[lid[ind[lm].idx], lid[ind[lm].jdx]];
              for ll := 1 to nx1 do
                lxtx.cell[k, ll] := lxtx.cell[k, ll] + lpval * xcols[ll].cell[lm];
              lxty.cell[k] := lxty.cell[k] + lpval * yvec.cell[lm];
            end;

            // Symmetrize
            for ll := 1 to nx1 do
              lxtx.cell[ll, k] := lxtx.cell[k, ll];

            // SVD solve
            svd(lxtx, lvmat, lw, lrank);
            svdbacksub(lxtx, lvmat, lw, lxty, lb);

            lbk := lb.cell[k];
            if abs(lbk) < doubleprecision then lbk := 0;

            // Compute inv[k,k]
            linv_kk := 0;
            for ll := 1 to nx1 do
              if lw.cell[ll] > doubleprecision then
                linv_kk := linv_kk + lvmat.cell[k, ll] * lxtx.cell[k, ll] / lw.cell[ll];

            // Compute MSE
            lbtxty := 0;
            for ll := 1 to nx1 do
              lbtxty := lbtxty + lb.cell[ll] * lxty.cell[ll];
            lsse := yty - lbtxty;
            lmse := lsse / (ncase - nx1);
            lse_sq := lmse * linv_kk;

            // Accumulate stats atomically
            cs.Enter;
            try
              inc(c_n);
              c_sum := c_sum + lbk;
              c_ssq := c_ssq + sqr(lbk);
              if lbk < c_min then c_min := lbk;
              if lbk > c_max then c_max := lbk;
              if lbk >= ob.cell[k] then inc(c_ge);
              if lbk <= ob.cell[k] then inc(c_le);
              if abs(lbk) >= abs(ob.cell[k]) then inc(c_ext);

              if lse_sq > doubleprecision then begin
                lts := lbk / lse_sq;
                inc(t_n);
                t_sum := t_sum + lts;
                t_ssq := t_ssq + sqr(lts);
                if lts < t_min then t_min := lts;
                if lts > t_max then t_max := lts;
                if lts >= ot then inc(t_ge);
                if lts <= ot then inc(t_le);
                if abs(lts) >= abs(ot) then inc(t_ext);
              end;
            finally
              cs.Leave;
            end;

          finally
            lxtx.free; lvmat.free; lxty.free; lw.free; lb.free;
            lid.free; lcatcopy.free;
          end;
        end);

      // Transfer accumulated stats to tunivariate objects
      cstats[k].n := c_n;
      cstats[k].tot := c_sum;
      cstats[k].ssq := c_ssq;
      if c_n > 0 then begin
        cstats[k].mean := c_sum / c_n;
        cstats[k].mcssq := c_ssq - sqr(c_sum) / c_n;
      end;
      cstats[k].min := c_min;
      cstats[k].max := c_max;
      cstats[k].ge := c_ge;
      cstats[k].le := c_le;
      cstats[k].ext := c_ext;
      cstats[k].sumwt := c_n;
      cstats[k].ge := cstats[k].ge + 1;
      cstats[k].le := cstats[k].le + 1;
      cstats[k].ext := cstats[k].ext + 1;
      cstats[k].n := c_n + 1;
      cstats[k].sumwt := c_n + 1;

      tstats[k].n := t_n;
      tstats[k].tot := t_sum;
      tstats[k].ssq := t_ssq;
      if t_n > 0 then begin
        tstats[k].mean := t_sum / t_n;
        tstats[k].mcssq := t_ssq - sqr(t_sum) / t_n;
      end;
      tstats[k].min := t_min;
      tstats[k].max := t_max;
      tstats[k].ge := t_ge;
      tstats[k].le := t_le;
      tstats[k].ext := t_ext;
      tstats[k].sumwt := t_n;
      tstats[k].ge := tstats[k].ge + 1;
      tstats[k].le := tstats[k].le + 1;
      tstats[k].ext := tstats[k].ext + 1;
      tstats[k].n := t_n + 1;
      tstats[k].sumwt := t_n + 1;

      nvalid := t_n;
    finally
      cs.free;
    end;
  end;

  // ===== FALLBACK PATH (with missing values) =====

  procedure addcase_fb(var am: integer; ai, aj: integer);
  var al: integer;
  begin
    if ismissing[ai, aj] then exit;
    inc(am);
    yfb.cell[am] := ymat.cell[ai, aj];
    for al := 1 to nx do
      xfb.cell[am, al] := xmats[al].cell[ai, aj];
    xfb.cell[am, nx1] := 1;
  end;

  procedure buildvariables_fb;
  var mm, ii, jj: integer;
  begin
    mm := 0;
    if sym
      then for ii := 2 to n do for jj := 1 to ii - 1 do addcase_fb(mm, ii, jj)
      else for ii := 1 to n do for jj := 1 to n do if (ii <> jj) then addcase_fb(mm, ii, jj);
    xfb.nr := mm; yfb.n := mm;
  end;

  procedure permutekmat_fb(aseed: integer);
  var mm, ii, jj: integer;
  begin
    permuteidvariable(id, aseed, catcopy);
    mm := 0;
    if sym
      then for ii := 2 to n do for jj := 1 to ii - 1 do begin
        if not ismissing[id[ii], id[jj]] then begin
          inc(mm);
          xfb.cell[mm, k] := xmats[k].cell[id[ii], id[jj]];
        end;
      end
      else for ii := 1 to n do for jj := 1 to n do if (ii <> jj) and (not ismissing[id[ii], id[jj]]) then begin
        inc(mm);
        xfb.cell[mm, k] := xmats[k].cell[id[ii], id[jj]];
      end;
  end;

  procedure runsequential_fb;
  var
    it_s: integer;
    localrsqr_s, t_s: double;
  begin
    for it_s := 1 to nperm - 1 do begin
      permutekmat_fb(seeds[it_s]);
      svdregression(localrsqr_s, bfb, se_fb, xfb, yfb);
      if abs(bfb[k]) < doubleprecision then bfb[k] := 0;
      cstats[k].addcase(bfb.cell[k], ob_fb.cell[k]);
      if se_fb.cell[k] > doubleprecision then begin
        t_s := bfb.cell[k] / se_fb.cell[k];
        tstats[k].addcase(t_s, ot);
        inc(nvalid);
      end;
    end;
  end;

  procedure runparallel_fb;
  var
    c_ge, c_le, c_ext, c_n: integer;
    c_sum, c_ssq, c_min, c_max: double;
    t_ge, t_le, t_ext, t_n: integer;
    t_sum, t_ssq, t_min, t_max: double;
    cs: tcriticalsection;
  begin
    c_ge := 0; c_le := 0; c_ext := 0; c_n := 0;
    c_sum := 0; c_ssq := 0;
    c_min := maxextended; c_max := -maxextended;
    t_ge := 0; t_le := 0; t_ext := 0; t_n := 0;
    t_sum := 0; t_ssq := 0;
    t_min := maxextended; t_max := -maxextended;
    cs := tcriticalsection.create;
    try
      TParallel.For(1, nperm - 1, procedure(it_p: integer)
        var
          lx: tsmat;
          ly: tevec;
          lb, lse: tevec;
          lid: tivec;
          lcatcopy: tivec;
          lrsqr, lt: double;
          lm, li, lj, ll: integer;
          lseed, node: integer;
        begin
          lx := tsmat.create;
          ly := tevec.create;
          lb := tevec.create;
          lse := tevec.create;
          lid := tivec.create;
          lcatcopy := tivec.create;
          try
            lx.allocate(ncells, nx1, 1, true, true);
            ly.allocate(ncells, true, true);
            lb.allocsize(nx1);
            lse.allocsize(nx1);
            lid.allocsize(n);

            // Build design matrix (thread-local copy)
            lm := 0;
            if sym then begin
              for li := 2 to n do for lj := 1 to li - 1 do
                if not ismissing[li, lj] then begin
                  inc(lm);
                  ly.cell[lm] := ymat.cell[li, lj];
                  for ll := 1 to nx do
                    lx.cell[lm, ll] := xmats[ll].cell[li, lj];
                  lx.cell[lm, nx1] := 1;
                end;
            end else begin
              for li := 1 to n do for lj := 1 to n do if (li <> lj) then
                if not ismissing[li, lj] then begin
                  inc(lm);
                  ly.cell[lm] := ymat.cell[li, lj];
                  for ll := 1 to nx do
                    lx.cell[lm, ll] := xmats[ll].cell[li, lj];
                  lx.cell[lm, nx1] := 1;
                end;
            end;
            lx.nr := lm; ly.n := lm;

            // Permute column k
            lseed := seeds[it_p];
            for li := 1 to n do lid[li] := li;
            for li := 1 to ncat do begin
              lcatcopy.copy(cat[li]);
              lcatcopy.randomlypermute(lseed);
              lcatcopy.resetcurrent;
              for lj := 1 to cat[li].n do begin
                node := cat[li].cell[lj];
                lid[node] := lcatcopy.getnextvalue;
              end;
            end;

            lm := 0;
            if sym then begin
              for li := 2 to n do for lj := 1 to li - 1 do
                if not ismissing[lid[li], lid[lj]] then begin
                  inc(lm);
                  lx.cell[lm, k] := xmats[k].cell[lid[li], lid[lj]];
                end;
            end else begin
              for li := 1 to n do for lj := 1 to n do if (li <> lj) then
                if not ismissing[lid[li], lid[lj]] then begin
                  inc(lm);
                  lx.cell[lm, k] := xmats[k].cell[lid[li], lid[lj]];
                end;
            end;

            svdregression(lrsqr, lb, lse, lx, ly);
            if abs(lb[k]) < doubleprecision then lb[k] := 0;

            cs.Enter;
            try
              inc(c_n);
              c_sum := c_sum + lb.cell[k];
              c_ssq := c_ssq + sqr(lb.cell[k]);
              if lb.cell[k] < c_min then c_min := lb.cell[k];
              if lb.cell[k] > c_max then c_max := lb.cell[k];
              if lb.cell[k] >= ob_fb.cell[k] then inc(c_ge);
              if lb.cell[k] <= ob_fb.cell[k] then inc(c_le);
              if abs(lb.cell[k]) >= abs(ob_fb.cell[k]) then inc(c_ext);

              if lse.cell[k] > doubleprecision then begin
                lt := lb.cell[k] / lse.cell[k];
                inc(t_n);
                t_sum := t_sum + lt;
                t_ssq := t_ssq + sqr(lt);
                if lt < t_min then t_min := lt;
                if lt > t_max then t_max := lt;
                if lt >= ot then inc(t_ge);
                if lt <= ot then inc(t_le);
                if abs(lt) >= abs(ot) then inc(t_ext);
              end;
            finally
              cs.Leave;
            end;

          finally
            lx.free; ly.free; lb.free; lse.free; lid.free; lcatcopy.free;
          end;
        end);

      cstats[k].n := c_n;
      cstats[k].tot := c_sum;
      cstats[k].ssq := c_ssq;
      if c_n > 0 then begin
        cstats[k].mean := c_sum / c_n;
        cstats[k].mcssq := c_ssq - sqr(c_sum) / c_n;
      end;
      cstats[k].min := c_min;
      cstats[k].max := c_max;
      cstats[k].ge := c_ge;
      cstats[k].le := c_le;
      cstats[k].ext := c_ext;
      cstats[k].sumwt := c_n;
      cstats[k].ge := cstats[k].ge + 1;
      cstats[k].le := cstats[k].le + 1;
      cstats[k].ext := cstats[k].ext + 1;
      cstats[k].n := c_n + 1;
      cstats[k].sumwt := c_n + 1;

      tstats[k].n := t_n;
      tstats[k].tot := t_sum;
      tstats[k].ssq := t_ssq;
      if t_n > 0 then begin
        tstats[k].mean := t_sum / t_n;
        tstats[k].mcssq := t_ssq - sqr(t_sum) / t_n;
      end;
      tstats[k].min := t_min;
      tstats[k].max := t_max;
      tstats[k].ge := t_ge;
      tstats[k].le := t_le;
      tstats[k].ext := t_ext;
      tstats[k].sumwt := t_n;
      tstats[k].ge := tstats[k].ge + 1;
      tstats[k].le := tstats[k].le + 1;
      tstats[k].ext := tstats[k].ext + 1;
      tstats[k].n := t_n + 1;
      tstats[k].sumwt := t_n + 1;

      nvalid := t_n;
    finally
      cs.free;
    end;
  end;

var
  btxty, sse, inv_kk, mse_val, se_sq: extended;
  val: extended;

begin
  id := tivec.create;
  catcopy := tivec.create;
  nvalid := 0;
  try

  if not hasmissing then begin
    // ===== OPTIMIZED PATH: rank-1 X'X update =====
    yvec := tevec.create;
    xtx_base := tdmat.create;
    xtx_work := tdmat.create;
    vmat_w := tdmat.create;
    xty_base := tevec.create;
    xty_work := tevec.create;
    w_w := tevec.create;
    bvec := tevec.create;
    ob := tevec.create;
    setlength(xcols, nx1 + 1);
    for l := 1 to nx1 do xcols[l] := tevec.create;
    try
      np := ncells;
      id.allocsize(n);
      setlength(ind, np + 1);

      // Allocate column vectors and Y
      for l := 1 to nx1 do
        xcols[l].allocate(np, true, true);
      yvec.allocate(np, true, true);

      // Build column vectors and index mapping
      m := 0;
      if sym then begin
        for i := 2 to n do for j := 1 to i - 1 do begin
          inc(m);
          ind[m].idx := i; ind[m].jdx := j;
          yvec.cell[m] := ymat.cell[i, j];
          for l := 1 to nx do
            xcols[l].cell[m] := xmats[l].cell[i, j];
          xcols[nx1].cell[m] := 1;
        end;
      end else begin
        for i := 1 to n do for j := 1 to n do if (i <> j) then begin
          inc(m);
          ind[m].idx := i; ind[m].jdx := j;
          yvec.cell[m] := ymat.cell[i, j];
          for l := 1 to nx do
            xcols[l].cell[m] := xmats[l].cell[i, j];
          xcols[nx1].cell[m] := 1;
        end;
      end;
      ncase := m;
      yvec.n := ncase;
      for l := 1 to nx1 do xcols[l].n := ncase;

      // Compute full X'X into xtx_base
      xtx_base.allocsize(nx1, nx1);
      xty_base.allocsize(nx1);
      for l := 1 to nx1 do
        for l2 := 1 to l do begin
          val := 0;
          for m := 1 to ncase do
            val := val + xcols[l].cell[m] * xcols[l2].cell[m];
          xtx_base.cell[l, l2] := val;
          xtx_base.cell[l2, l] := val;
        end;

      // Compute full X'y
      for l := 1 to nx1 do begin
        val := 0;
        for m := 1 to ncase do
          val := val + xcols[l].cell[m] * yvec.cell[m];
        xty_base.cell[l] := val;
      end;

      // Compute y'y and total y
      yty := 0; toty := 0;
      for m := 1 to ncase do begin
        yty := yty + sqr(yvec.cell[m]);
        toty := toty + yvec.cell[m];
      end;

      // --- Run observed regression using full X'X ---
      xtx_work.allocsize(nx1, nx1);
      vmat_w.allocsize(nx1, nx1);
      w_w.allocsize(nx1);
      bvec.allocsize(nx1);
      ob.allocsize(nx1);
      xty_work.allocsize(nx1);

      // Copy full X'X/X'y to work buffers
      for l := 1 to nx1 do begin
        for l2 := 1 to nx1 do
          xtx_work.cell[l, l2] := xtx_base.cell[l, l2];
        xty_work.cell[l] := xty_base.cell[l];
      end;

      // SVD of full X'X
      svd(xtx_work, vmat_w, w_w, rank);
      svdbacksub(xtx_work, vmat_w, w_w, xty_work, ob);

      // Compute observed SE[k] (as mse*inv[k,k] to match svdregression)
      inv_kk := 0;
      for l := 1 to nx1 do
        if w_w.cell[l] > doubleprecision then
          inv_kk := inv_kk + vmat_w.cell[k, l] * xtx_work.cell[k, l] / w_w.cell[l];

      btxty := 0;
      for l := 1 to nx1 do
        btxty := btxty + ob.cell[l] * xty_base.cell[l];
      sse := yty - btxty;
      mse_val := sse / (ncase - nx1);
      se_sq := mse_val * inv_kk;

      if se_sq > doubleprecision
        then ot := ob.cell[k] / se_sq
        else ot := bna;

      // Remove column k's contribution from row/col k of xtx_base
      // (so base = full X'X with row/col k zeroed, ready for permuted contribution)
      for l := 1 to nx1 do begin
        xtx_base.cell[k, l] := 0;
        xtx_base.cell[l, k] := 0;
      end;
      xty_base.cell[k] := 0;

      // --- Permutation loop ---
      if nperm <= 1 then begin
        cstats[k].addcase(ob.cell[k], ob.cell[k]);
        if ot < bna then tstats[k].addcase(ot, ot);
      end else begin
        cstats[k].addcase(ob.cell[k], ob.cell[k]);
        if ot < bna then tstats[k].addcase(ot, ot);

        if useparallel
          then runparallel_opt
          else runsequential_opt;
      end;

    finally
      for l := 1 to nx1 do xcols[l].free;
      xcols := nil;
      yvec.free;
      xtx_base.free; xtx_work.free; vmat_w.free;
      xty_base.free; xty_work.free; w_w.free;
      bvec.free; ob.free;
      ind := nil;
    end;

  end else begin
    // ===== FALLBACK PATH: full svdregression per iteration (missing values) =====
    xfb := tsmat.create;
    yfb := tevec.create;
    bfb := tevec.create;
    ob_fb := tevec.create;
    se_fb := tevec.create;
    try
      np := ncells;
      xfb.allocate(np, nx1, 1, true, true);
      yfb.allocate(np, true, true);
      bfb.allocsize(nx1);
      ob_fb.allocsize(nx1);
      se_fb.allocsize(nx1);
      id.allocsize(n);
      for i := 1 to n do id[i] := i;

      // Run observed regression
      buildvariables_fb;
      svdregression(localrsqr_fb, ob_fb, se_fb, xfb, yfb);

      if se_fb.cell[k] > doubleprecision
        then ot := ob_fb.cell[k] / se_fb.cell[k]
        else ot := bna;

      if nperm <= 1 then begin
        cstats[k].addcase(ob_fb.cell[k], ob_fb.cell[k]);
        if ot < bna then tstats[k].addcase(ot, ot);
      end else begin
        cstats[k].addcase(ob_fb.cell[k], ob_fb.cell[k]);
        if ot < bna then tstats[k].addcase(ot, ot);

        if useparallel
          then runparallel_fb
          else runsequential_fb;
      end;

    finally
      xfb.free; yfb.free; bfb.free; ob_fb.free; se_fb.free;
    end;
  end;

  finally
    catcopy.free;
    id.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure tmrqapdekker.buildftab(ftab: tsmat);
begin
  ftab.cdvn.fillwith('R-Square|Adj R-Sqr|P(R-Sqr)|Obs|Perms');
  ftab.allocate(1, ftab.cdvn.n, 1, true, false);
  ftab.rdvn.addstr('Model');
  ftab.title := 'MODEL FIT';
  ftab[1, 1] := rsqr;
  ftab[1, 2] := adjrsqr;
  ftab[1, 3] := prsqr;
  ftab[1, 4] := ncells;
  ftab[1, 5] := nperm;
end;
{---------------------------------------------------------------------------}
procedure tmrqapdekker.buildctab(ctab: tsmat);
var
  j: integer;
  pval: double;
begin
  case trackmethod of
    trBetas: begin
      ctab.title := 'REGRESSION COEFFICIENTS (betas used in permutations)';
      ctab.cdvn.fillwith('Un-Stdized|Stdized Coef|Robust SE|T-stat|P-value|As Large|As Small|As Extreme|Perm Avg|Perm SD|Collin R-Sqr|Tolerance|VIF');
      ctab.allocate(nx1, ctab.cdvn.n, 1, true, false);
      for j := 1 to nx1 do begin
        ctab[j, 1] := coef[j];
        ctab[j, 2] := beta[j];
        ctab[j, 3] := robustse[j];
        ctab[j, 4] := obst[j];
        if onetailed then begin
          if coef.cell[j] < 0
            then pval := cstats[j].ple
            else pval := cstats[j].pge;
        end else
          pval := cstats[j].pext;
        ctab[j, 5] := pval;
        ctab[j, 6] := cstats[j].pge;
        ctab[j, 7] := cstats[j].ple;
        ctab[j, 8] := cstats[j].pext;
        ctab[j, 9] := cstats[j].avg;
        ctab[j, 10] := cstats[j].stddev;
        // Collinearity diagnostics (IVs only, not intercept)
        if j <= nx then begin
          ctab[j, 11] := collinrsqr[j];
          ctab[j, 12] := 1.0 - collinrsqr[j];
          if collinrsqr[j] < 1.0
            then ctab[j, 13] := 1.0 / (1.0 - collinrsqr[j])
            else ctab[j, 13] := bna;
        end else begin
          ctab[j, 11] := bna;
          ctab[j, 12] := bna;
          ctab[j, 13] := bna;
        end;
      end;
    end;
    trTstats: begin
      ctab.title := 'REGRESSION COEFFICIENTS (t-statistics used in permutations)';
      ctab.cdvn.fillwith('Un-Stdized|Stdized Coef|Robust SE|T-stat|P-value|As Large|As Small|As Extreme|Perm Avg|Perm SD|Collin R-Sqr|Tolerance|VIF');
      ctab.allocate(nx1, ctab.cdvn.n, 1, true, false);
      for j := 1 to nx1 do begin
        ctab[j, 1] := coef[j];
        ctab[j, 2] := beta[j];
        ctab[j, 3] := robustse[j];
        ctab[j, 4] := obst[j];
        if onetailed then begin
          if obst.cell[j] < 0
            then pval := tstats[j].ple
            else pval := tstats[j].pge;
        end else
          pval := tstats[j].pext;
        ctab[j, 5] := pval;
        ctab[j, 6] := tstats[j].pge;
        ctab[j, 7] := tstats[j].ple;
        ctab[j, 8] := tstats[j].pext;
        ctab[j, 9] := cstats[j].avg;
        ctab[j, 10] := cstats[j].stddev;
        // Collinearity diagnostics (IVs only, not intercept)
        if j <= nx then begin
          ctab[j, 11] := collinrsqr[j];
          ctab[j, 12] := 1.0 - collinrsqr[j];
          if collinrsqr[j] < 1.0
            then ctab[j, 13] := 1.0 / (1.0 - collinrsqr[j])
            else ctab[j, 13] := bna;
        end else begin
          ctab[j, 11] := bna;
          ctab[j, 12] := bna;
          ctab[j, 13] := bna;
        end;
      end;
      // Intercept row: blank out permutation stats
      ctab[nx1, 5] := bna;
      ctab[nx1, 6] := bna;
      ctab[nx1, 7] := bna;
      ctab[nx1, 8] := bna;
      ctab[nx1, 9] := bna;
      ctab[nx1, 10] := bna;
    end;
  end;
end;
{---------------------------------------------------------------------------}
procedure tmrqapdekker.buildpredicted(pred: tsmat);
begin
  pred.copy(combo);
  pred.title := 'Expected values based on MRQAP regression';
end;
{---------------------------------------------------------------------------}
procedure tmrqapdekker.buildresiduals(rmat: tsmat);
begin
  rmat.copy(resid);
  rmat.title := 'Residual values from MRQAP regression';
end;
{---------------------------------------------------------------------------}
end.
