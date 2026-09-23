unit uc_factions;

{ 64-bit-clean rewrite of xfaction.pas using the G2Tools tmat family
  (tsmatds / tsmat / tivec / timat / timatds). The dialog form is the
  existing TFactionsDlg from uc_factionsdlg.pas.

  Algorithmic structure mirrors xfaction.pas:
    - load matrix, dichotomize if valued
    - pick a starting partition with Floyd + km1
    - run nstarts random-start tabu searches and keep the best
    - for symmetric networks, snap pendants onto their neighbour's group
    - report block densities and save partition + indicator matrix

  Speedups over the original:
    - One-shot edge list. The fit measures (Hamming, Phi, Modularity,
      Entailment) only depend on directed edges and group sizes, so each
      call is O(narcs + nb) instead of O(n^2). For typical sparse
      networks this dominates the runtime improvement.
    - Group sizes are maintained incrementally, not rescanned per move.
    - Dropped the dead "prod" matrix that the active modularity branch
      never used, and the temporary "tmp" header matrix used only to
      save the partition (timatds does that directly). }

interface

uses
  Forms, Dialogs, Controls, SysUtils, Math,
  ucommon, ugeneral, ufn, ustring, utlogfile,
  utsmatds, utsmat, utivec, utimat, utimatds,
  ufloyd, ukm1, ug2display,
  uc_factionsdlg;

const
  fmHamming    = 0;
  fmPhi        = 1;
  fmModularity = 2;
  fmEntailment = 3;

  fmName: array[0..3] of string =
    ('Hamming', 'Phi', 'Modularity', 'Entailment');

procedure runfactions;

{ Algorithm core. Both the GUI entry point and the CLI runfactions2 in
  Xdpmat.pas call this. amat is dichotomized in place if it has any cell
  > 1. resultpart receives the best partition (1..ngroups) on exit and
  bestcost is the corresponding cost (lower is better; for measures
  bounded above by 1 the displayable score is 1 - bestcost). }
procedure factionsoptimize(amat: tsmatds; ngroups: integer;
  measureidx: integer; nstartsval, maxitval, nbanval, seedval: integer;
  resultpart: tivec; var bestcost: double);

implementation

const
  ifn: string = '';
  pfn: string = 'FactionsPart';
  sfn: string = 'FactionsSets';
  nb: integer = 2;
  maxit: integer = 20;
  seed: integer = 0;
  nstarts: integer = 3;
  nban: integer = 15;
  measure: integer = 0;
  meas: string = 'Hamming';

type
  tfitfunc = function(p: tivec): double;

var
  d: tsmatds;
  e: timat;                              // group x group edge counts (modularity)
  edgesi, edgesj: array of integer;      // flat directed edge list
  numedges: integer;
  groupsize: tivec;
  n: integer;
  log: tlogfile;

{---------------------------------------------------------------------------}
function askparameters: boolean;
var
  dlg: TFactionsDlg;
begin
  dlg:= TFactionsDlg.Create(Application);
  try
    with dlg do begin
      if displayfullpathnames
        then InputFn.Text:= ifn
        else InputFn.Text:= fnandext(ifn);
      InputFn.SelStart:= length(InputFn.Text);
      NoFactions.Text:= istr(nb,0);
      MaxIterations.Text:= istr(maxit,0);
      Penalty.Text:= istr(nban,0);
      RandomStarts.Text:= istr(nstarts,0);
      randomize;
      seed:= trunc(random(1000)) + 1;
      RandomSeed.Text:= istr(seed,0);
      OutputFn.Text:= pfn;
      OutputSets.Text:= sfn;
      pmeasure.itemindex:= measure;
    end;
    dlg.ShowModal;
    result:= dlg.ModalResult <> mrCancel;
    if result then with dlg do begin
      ifn:= InputFn.Text;
      nb:= strtointdef(NoFactions.Text, 2);
      maxit:= strtointdef(MaxIterations.Text, 20);
      nban:= strtointdef(Penalty.Text, 15);
      nstarts:= strtointdef(RandomStarts.Text, 3);
      seed:= strtointdef(RandomSeed.Text, 0);
      pfn:= outdir(OutputFn.Text);
      sfn:= outdir(OutputSets.Text);
      measure:= pmeasure.itemindex;
      meas:= pmeasure.text;
    end;
  finally
    dlg.Free;
  end;
end;
{---------------------------------------------------------------------------}
procedure recountgroupsizes(p: tivec);
var
  i: integer;
begin
  groupsize.zerofill;
  for i:= 1 to n do
    inc(groupsize.cell[p.cell[i]]);
end;
{---------------------------------------------------------------------------}
function intrapairs: int64;
//directed pairs (i,j), i<>j, with same group
var
  g: integer;
  s: int64;
begin
  result:= 0;
  for g:= 1 to nb do begin
    s:= groupsize.cell[g];
    result:= result + s*(s-1);
  end;
end;
{---------------------------------------------------------------------------}
function countintraedges(p: tivec): int64;
var
  k: integer;
begin
  result:= 0;
  for k:= 0 to numedges - 1 do
    if p.cell[edgesi[k]] = p.cell[edgesj[k]]
      then inc(result);
end;
{---------------------------------------------------------------------------}
function hamming(p: tivec): double;
//number of cells whose tie/no-tie disagrees with same-group/diff-group.
//directed pairs total = numedges_present + numedges_absent
//errors = (intraP - intraE)  [missing intra ties]
//       + (numedges - intraE)  [cross ties]
var
  intraE, intraP: int64;
begin
  recountgroupsizes(p);
  intraE:= countintraedges(p);
  intraP:= intrapairs;
  result:= intraP + numedges - 2*intraE;
end;
{---------------------------------------------------------------------------}
function phi(p: tivec): double;
var
  intraE, intraP, totalP, a, b, c, dd: int64;
  den: double;
begin
  recountgroupsizes(p);
  intraE:= countintraedges(p);
  intraP:= intrapairs;
  totalP:= int64(n)*(n - 1);
  a:= intraE;
  b:= intraP - intraE;
  c:= numedges - intraE;
  dd:= totalP - intraP - c;
  den:= sqrt(((a+b)*1.0) * ((c+dd)*1.0) * ((a+c)*1.0) * ((b+dd)*1.0));
  if den <= 0
    then result:= 1.0
    else result:= 1.0 - ((a*1.0)*dd - (b*1.0)*c)/den;
end;
{---------------------------------------------------------------------------}
function entailment(p: tivec): double;
//proportion of directed edges that span groups
var
  intraE: int64;
begin
  recountgroupsizes(p);
  if numedges = 0 then exit(0);
  intraE:= countintraedges(p);
  result:= (numedges - intraE) / numedges;
end;
{---------------------------------------------------------------------------}
function modularity(p: tivec): double;
var
  i, g, k: integer;
  ai, eii, q: double;
begin
  recountgroupsizes(p);
  e.zerofill;
  for k:= 0 to numedges - 1 do
    inc(e.cell[p.cell[edgesi[k]], p.cell[edgesj[k]]]);
  q:= 0;
  for i:= 1 to nb do begin
    eii:= e.cell[i,i];
    ai:= 0;
    for g:= 1 to nb do
      ai:= ai + e.cell[i,g];
    q:= q + eii/numedges - sqr(ai/numedges);
  end;
  result:= 1.0 - q;
end;
{---------------------------------------------------------------------------}
procedure buildedgelist;
var
  i, j, k: integer;
  rowp: arrayofsingle;
begin
  numedges:= 0;
  for i:= 1 to n do begin
    rowp:= d.cell[i];
    for j:= 1 to n do if i <> j then
      if rowp[j] > 0 then inc(numedges);
  end;
  setlength(edgesi, numedges);
  setlength(edgesj, numedges);
  k:= 0;
  for i:= 1 to n do begin
    rowp:= d.cell[i];
    for j:= 1 to n do if i <> j then
      if rowp[j] > 0 then begin
        edgesi[k]:= i;
        edgesj[k]:= j;
        inc(k);
      end;
  end;
end;
{---------------------------------------------------------------------------}
function dichotomize: boolean;
//in-place: any cell > 1 collapses to 1. Reports back whether anything
//had to be collapsed (i.e., the input was valued).
var
  i, j: integer;
  rowp: arrayofsingle;
begin
  result:= false;
  for i:= 1 to n do begin
    rowp:= d.cell[i];
    for j:= 1 to n do if i <> j then
      if rowp[j] > 1 then begin
        rowp[j]:= 1;
        result:= true;
      end;
  end;
end;
{---------------------------------------------------------------------------}
function issym: boolean;
var
  i, j: integer;
begin
  for i:= 2 to n do
    for j:= 1 to i-1 do
      if d.cell[i,j] <> d.cell[j,i]
        then exit(false);
  result:= true;
end;
{---------------------------------------------------------------------------}
procedure adjustpendants(p: tivec);
//pin every degree-1 node to its sole neighbour's group
var
  i, j, deg, f: integer;
  rowp: arrayofsingle;
begin
  for i:= 1 to n do begin
    rowp:= d.cell[i];
    deg:= 0; f:= 0;
    for j:= 1 to n do
      if (i <> j) and (rowp[j] > 0) then begin
        inc(deg);
        f:= j;
        if deg > 1 then break;
      end;
    if (deg = 1) and (f > 0)
      then p.cell[i]:= p.cell[f];
  end;
end;
{---------------------------------------------------------------------------}
procedure getstartingpartition(p: tivec);
var
  dist: tsmat;
  i, j: integer;
begin
  dist:= tsmat.create;
  try
    dist.allocate(n, n, 1, true, false);
    for i:= 1 to n do
      for j:= 1 to n do
        dist.cell[i,j]:= d.cell[i,j];
    floyd(dist);
    km1(p, dist, nb, false);
  finally
    dist.Free;
  end;
end;
{---------------------------------------------------------------------------}
procedure randompart(p: tivec);
var
  i: integer;
begin
  for i:= 1 to n do
    p.cell[i]:= random(nb) + 1;
end;
{---------------------------------------------------------------------------}
procedure tabuoptimize(bestp: tivec; fitof: tfitfunc; var bestf: double);
//Tabu search that minimizes fitof. bestp holds initial partition on entry
//and the best partition found on exit. Uses delta-array to pick the move
//that least worsens (or most improves) cost; recently-vacated groups are
//tabu for "nban" steps.
var
  p: tivec;
  delta: array of array of double;
  dok: timat;
  currentcost, bd, sentinel: double;
  bi, oj, bj, r, i, g: integer;
  changed: boolean;

  function deltacost(node, newg: integer): double;
  //fit fns recount groupsize from scratch on entry, so after they return
  //groupsize matches the moved partition; revert it for the original.
  var
    oldg: integer;
  begin
    oldg:= p.cell[node];
    if groupsize.cell[oldg] < 2
      then exit(sentinel);
    p.cell[node]:= newg;
    result:= fitof(p) - currentcost;
    p.cell[node]:= oldg;
    inc(groupsize.cell[oldg]);
    dec(groupsize.cell[newg]);
  end;

  procedure updatedelta;
  var
    i, g: integer;
  begin
    for i:= 1 to n do
      for g:= 1 to nb do
        if g = p.cell[i]
          then delta[i,g]:= 0
          else delta[i,g]:= deltacost(i, g);
  end;

  procedure getnext;
  var
    i, g: integer;
  begin
    bd:= maxdouble; bi:= 1; oj:= p.cell[1]; bj:= p.cell[1];
    for i:= 1 to n do
      for g:= 1 to nb do
        if (dok.cell[i,g] = 0) and (p.cell[i] <> g) and
           (delta[i,g] <= bd) then begin
          bd:= delta[i,g];
          bi:= i;
          oj:= p.cell[i];
          bj:= g;
        end;
  end;

begin
  if nb < 2 then begin
    bestf:= fitof(bestp);
    exit;
  end;
  p:= tivec.create;
  dok:= timat.create;
  try
    p.allocsize(n, false);
    p.copy(bestp);
    setlength(delta, n+1, nb+1);
    dok.allocate(n, nb, 1, true, true);
    recountgroupsizes(p);
    currentcost:= fitof(p);
    bestf:= currentcost;
    sentinel:= 2*abs(currentcost) + 1;
    updatedelta;
    changed:= false;
    r:= maxit;
    while r > 0 do begin
      getnext;
      if bd >= 0 then dok.cell[bi, oj]:= nban;
      if groupsize.cell[oj] > 1
        then p.cell[bi]:= bj;
      currentcost:= fitof(p);  //also rebuilds groupsize to match new p
      updatedelta;
      if currentcost < bestf then begin
        bestf:= currentcost;
        bestp.copy(p);
        changed:= true;
      end;
      dec(r);
      for i:= 1 to n do
        for g:= 1 to nb do
          if dok.cell[i,g] > 0 then dec(dok.cell[i,g]);
      if (r = 0) and changed then begin
        changed:= false;
        r:= maxit;
      end;
    end;
  finally
    dok.Free;
    p.Free;
    delta:= nil;
  end;
end;
{---------------------------------------------------------------------------}
procedure makeblockdensity_data(amat: tsmatds; bm: tsmat; rp: tivec);
//bm[g,h] := density of ties from group g to group h.
//Diagonal blocks exclude the diagonal of amat.
var
  i, j, ng, nn: integer;
  count, possible: timat;
  rowp: arrayofsingle;
begin
  count:= timat.create;
  possible:= timat.create;
  try
    nn:= amat.n;
    ng:= 1;
    for i:= 1 to nn do
      if rp.cell[i] > ng
        then ng:= rp.cell[i];
    bm.allocate(ng, ng, 1, true, true);
    count.allocate(ng, ng, 1, true, true);
    possible.allocate(ng, ng, 1, true, true);
    for i:= 1 to nn do begin
      rowp:= amat.cell[i];
      for j:= 1 to nn do if i <> j then begin
        inc(possible.cell[rp.cell[i], rp.cell[j]]);
        if rowp[j] > 0
          then inc(count.cell[rp.cell[i], rp.cell[j]]);
      end;
    end;
    for i:= 1 to ng do
      for j:= 1 to ng do
        if possible.cell[i,j] > 0
          then bm.cell[i,j]:= count.cell[i,j]/possible.cell[i,j]
          else bm.cell[i,j]:= 0;
    bm.title:= 'Block densities';
  finally
    count.Free;
    possible.Free;
  end;
end;
{---------------------------------------------------------------------------}
procedure factionsoptimize(amat: tsmatds; ngroups: integer;
  measureidx: integer; nstartsval, maxitval, nbanval, seedval: integer;
  resultpart: tivec; var bestcost: double);
//Sets up the module-level state, runs nstarts random-start tabu searches
//starting from a Floyd+km1 partition, and returns the best partition.
var
  p: tivec;
  fit: double;
  k: integer;
  fitof: tfitfunc;
  ownsedge, ownse, ownsgs: boolean;
begin
  d:= amat;
  n:= amat.n;
  nb:= ngroups;
  measure:= measureidx;
  nstarts:= nstartsval;
  maxit:= maxitval;
  nban:= nbanval;
  seed:= seedval;

  ownsedge:= false; ownse:= false; ownsgs:= false;
  p:= tivec.create;
  try
    if groupsize = nil then begin
      groupsize:= tivec.create;
      ownsgs:= true;
      end;
    groupsize.allocsize(nb, true);
    if e = nil then begin
      e:= timat.create;
      ownse:= true;
      end;
    e.allocate(nb, nb, 1, true, true);
    p.allocsize(n, false);
    resultpart.allocsize(n, false);

    dichotomize;
    buildedgelist;
    ownsedge:= true;

    randseed:= seed;

    case measure of
      fmHamming:    fitof:= hamming;
      fmPhi:        fitof:= phi;
      fmModularity: fitof:= modularity;
      fmEntailment: fitof:= entailment;
      else exit;
    end;
    if (measure = fmModularity) and (numedges = 0) then begin
      bestcost:= 1.0;  //modularity Q = 0
      for k:= 1 to n do resultpart.cell[k]:= 1;
      exit;
    end;

    getstartingpartition(resultpart);
    bestcost:= fitof(resultpart);

    for k:= 1 to nstarts do begin
      randseed:= randseed + 31;
      randompart(p);
      tabuoptimize(p, fitof, fit);
      fit:= fitof(p);
      if fit < bestcost then begin
        bestcost:= fit;
        resultpart.copy(p);
        end;
      end;

    if amat.IsSymmetric()
      then adjustpendants(resultpart);
  finally
    p.Free;
    if ownse then begin e.Free; e:= nil; end;
    if ownsgs then begin groupsize.Free; groupsize:= nil; end;
    if ownsedge then begin
      edgesi:= nil;
      edgesj:= nil;
      end;
    d:= nil;
  end;
end;
{---------------------------------------------------------------------------}
procedure runfactions;
var
  k, i: integer;
  bestfit: double;
  bestp: tivec;
  partmat: timatds;
  sets: tsmatds;
  bm: tsmat;
  ncells: int64;
  data: tsmatds;
begin
  if not askparameters then exit;

  data:= tsmatds.create;
  bestp:= tivec.create;
  partmat:= timatds.create;
  sets:= tsmatds.create;
  bm:= tsmat.create;
  log:= tlogfile.stdcreate('Factions',copyright);
  try
    log.putstr('Number of factions:', istr(nb,0));
    log.putstr('Measure of fit:', meas);
    meas:= uppercase(meas);
    log.dataset(ifn);
    log.lf;

    if not data.load(ifn) then exit;
    if data.nr <> data.nc then begin
      messagedlg('ERROR: File ' + ifn + ' does not contain a square matrix.',
        mtError, [mbOK], 0);
      error:= 9;
      exit;
    end;
    if data.IsValued
      then log.put('This version of Factions is intended for binary data');

    factionsoptimize(data, nb, measure, nstarts, maxit, nban, seed,
      bestp, bestfit);

    ncells:= int64(data.n)*(data.n - 1);
    case measure of
      fmHamming:    log.putfloat('Final proportion "correct": ', 1.0 - bestfit/ncells, 0, 4);
      fmPhi:        log.putfloat('Final correlation (phi): ',    1.0 - bestfit, 0, 4);
      fmModularity: log.putfloat('Final modularity: ',           1.0 - bestfit, 0, 4);
      fmEntailment: log.putfloat('Final entailment: ',           1.0 - bestfit, 0, 4);
    end;

    log.lf;
    log.put('Group Assignments:');
    log.lf;
    sets.allocate(nb, data.n, 1, true, true);
    sets.title:= 'Factions';
    sets.cdvn.copy(data.cdvn);
    for k:= 1 to nb do begin
      log.write(istr(k,5) + ': ');
      for i:= 1 to data.n do
        if bestp.cell[i] = k then begin
          log.write(' ' + data.rdvn.sget(i));
          sets.cell[k,i]:= 1;
        end;
      log.lf;
    end;
    log.lf;

    blockdisplay(log.stream, data, bestp, bestp, pagewidth, -1, -1, 1.0, ' ');
    makeblockdensity_data(data, bm, bestp);
    bm.displayasmatrix(log.stream);

    partmat.allocate(data.n, 1, 1, true, false);
    partmat.title:= 'Partition';
    partmat.rdvn.copy(data.rdvn);
    for i:= 1 to data.n do
      partmat.cell[i,1]:= bestp.cell[i];
    partmat.save(pfn);

    sets.save(sfn);
    log.outfile('Partition saved as dataset ', pfn);
    log.outfile('Faction-by-actor indicator matrix saved as dataset ', sfn);
  finally
    log.browse;
    log.Free;
    bm.Free;
    sets.Free;
    partmat.Free;
    bestp.Free;
    data.Free;
  end;
end;
{---------------------------------------------------------------------------}

end.
