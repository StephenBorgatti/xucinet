unit ulrqap;
interface
uses
  classes, sysutils, comctrls, math, system.threading, system.syncobjs,
  vcl.forms,
  ucommon, utsmat, utsmat3, utdvec, utivec, ulogisticregressionnr,
  utunivariate, utsmatds, urandomthreadsafe, udistrib, utcorr;
type
  tresultsrec = record
    coefs,stderrs,tstats: tdvec;
    numit: integer;
    loglik,rsquare: double;
    constructor create(x:integer);
    procedure allocate(n:integer);
    procedure destroy;
    end;
  tlrqapws = class;
  tlrqap = class
    ymat: tsmat;
    xmats: tsmat3;
    xvars: tsmat;
    yvar,rvar,coefs,ge,le: tdvec;
    xvalid,yvalid: arrayofboolean;
    part: tivec;
    n,nx,nv,nobs,ncells,np,wtrack,seed: integer;
    fprogress: integer;   // permutations completed so far (atomic; read by UI)
    p: tivec;
    sym,diagok,hasmissing,useSE,onetailed: boolean;
    obs,ran: tresultsrec;
    cstats,tstats: array of tunivariate;
    cov: array of array of tcorr;
    lstat: tunivariate;
    seeds: arrayofinteger;

    constructor create;
    destructor destroy; override;
    function getvalidlist: integer;
    procedure buildftab(ftab:tsmat);
    procedure buildcov(cmat:tsmat);
    procedure buildctab0(ctab:tsmat);
    procedure buildctab1(ctab:tsmat);
    procedure buildx(xmats:tsmat3; symmet:boolean=false);
    procedure buildy(ymat:tsmat; symmet:boolean=false);
    procedure permuteandcopy(ymat:tsmat; aseed:integer; symmet:boolean=false);
    procedure run(ymat,rmat,history:tsmat; xmats:tsmat3; track:integer=1; maxperm:integer= 10000;
                     symmet:boolean=false; aseed:integer=0; parallel:boolean=false; pb:tprogressbar=nil);
    procedure saveresiduals(rmat:tsmat; symmet:boolean=false);
    procedure storeresults(res:tresultsrec);
    function buildvalidlist(rdsl:tdsl; yval:arrayofboolean): integer;
    procedure buildyws(ws:tlrqapws; symmet:boolean=false);
    procedure runperm(ws:tlrqapws; aseed,it:integer; history:tsmat; symmet:boolean=false);
    end;
  // Per-thread workspace so permutations can run in parallel without sharing
  // mutable state. The design matrix cell data is shared read-only (xview.cell
  // references the master xvars.cell); only the response, valid list and result
  // buffers are per-workspace.
  tlrqapws = class
    localp: tivec;
    localyvar: tdvec;
    localyvalid: arrayofboolean;
    xview: tsmat;
    localran: tresultsrec;
    haveresult: boolean;
    constructor create(owner:tlrqap);
    destructor destroy; override;
    end;

procedure lrqap(ftable,ctable,rmat,cov,ymat,history:tsmat; xmats:tsmat3; var hasmiss:boolean; onetailed:boolean=false; track:integer=1; maxperm:integer=-1; symmet:boolean=false; aseed:integer=-1; parallel:boolean=false; usenormal:boolean=false; pb:tprogressbar=nil);
//ftable is matrix of overall fit statistics
//ctable is matrix of coefficient statistics

const
  trBetas = 0; trTstats = 1;

implementation

procedure lrqap(ftable,ctable,rmat,cov,ymat,history:tsmat; xmats:tsmat3; var hasmiss:boolean; onetailed:boolean=false; track:integer=1; maxperm:integer=-1; symmet:boolean=false; aseed:integer=-1; parallel:boolean=false; usenormal:boolean=false; pb:tprogressbar=nil);
var
  q: tlrqap;
begin try
  q:= tlrqap.create;
  q.useSE:= usenormal;
  q.onetailed:= onetailed;
  q.run(ymat,rmat,history,xmats,track,maxperm,symmet,aseed,parallel,pb);
  q.buildftab(ftable);
  case track of
    trbetas: q.buildctab0(ctable);
    trtstats: q.buildctab1(ctable);
    end;
  hasmiss:= q.hasmissing;
  q.buildcov(cov);
  cov.rdvn.copy(xmats.cdvn);
  cov.cdvn.copy(cov.rdvn);
  finally
    q.free;
  end;
end;

constructor tresultsrec.create(x:integer);
begin
  coefs:= tdvec.create;
  stderrs:= tdvec.create;
  tstats:= tdvec.create;
  numit:= 0;
  loglik:= 0; rsquare:= 0;
end;

procedure tresultsrec.allocate(n:integer);
begin
  coefs.allocate(n,true,true);
  stderrs.allocate(n,true,true);
  tstats.allocate(n,true,true);
end;

procedure tresultsrec.destroy;
begin
  coefs.free;
  stderrs.free;
  tstats.free;
end;

constructor tlrqap.create;
begin
  xvars:= tsmat.create;
  yvar:= tdvec.create;
  rvar:= tdvec.create;
  p:= tivec.create;
  obs:= tresultsrec.create(0);
  ran:= tresultsrec.create(0);
  lstat:= tunivariate.create;
  diagok:= false;
  useSE:= false;
  onetailed:= false;
end;

destructor tlrqap.destroy;
var
  i,j: integer;
begin
  xvars.free;
  yvar.free;
  rvar.free;
  p.free;
  obs.destroy;
  ran.destroy;
  xvalid:= nil;
  yvalid:= nil;
  for j:= 1 to nv do begin
    cstats[j].free;
    tstats[j].free;
    for i:= 1 to nv do
      cov[i,j].free;
    end;
  cstats:= nil;
  tstats:= nil;
  lstat.free;
  cov:= nil;
end;

procedure tlrqap.buildcov(cmat:tsmat);
var
  i,j: integer;
begin
  cmat.allocate(nv,nv,1,true,false);
  for i:= 1 to nv do
    for j:= 1 to nv do begin
      cov[i,j].calc;
      cmat.cell[i,j]:= cov[i,j].cov;
    end;
end;

procedure tlrqap.buildx(xmats:tsmat3; symmet:boolean=false);
//nv is number of variables including intercept. so nv = nx + 1;
var
  top,i,j,k,ij: integer;
begin
  xvars.allocate(ncells,nv,1,true,false);
  xvars.rdsl.allocate(ncells,true,true);
  xvars.cdvn.allocate(nv,true,true);
  xvars.cdvn.sput(1,'Intercept');
  for j:= 1 to nx do
    xvars.cdvn[j+1]:= xmats.mdvn.labelget(j);
  setlength(xvalid,ncells+1);
  ij:= 0;
  for i:= 1 to n do begin
    if symmet then top:= i else top:= n;
    for j:= 1 to top do if (i<>j) or diagok then begin
      inc(ij);
      xvars[ij,1]:= 1.0;
      xvalid[ij]:= true;
      for k:= 2 to nv do begin
        xvars.cell[ij,k]:= xmats.cell[k-1,i,j];
        if xvars.cell[ij,k] >= na then begin
          xvalid[ij]:= false;
          continue;
          end;
        end;
      end;
    end;
end;

procedure tlrqap.buildy(ymat:tsmat; symmet:boolean=false);
var
  top,i,j,ij: integer;
begin
  setlength(yvalid,ncells+1);
  ij:= 0;
  for i:= 1 to n do begin
    if symmet then top:= i else top:= n;
    for j:= 1 to top do if (i<>j) or diagok then begin
      inc(ij);
      yvar[ij]:= ymat.cell[p[i],p[j]];
      if yvar[ij] >= na
        then yvalid[ij]:= false
        else yvalid[ij]:= true;
      end;
    end;
end;

procedure tlrqap.saveresiduals(rmat:tsmat; symmet:boolean=false);
var
  top,i,j,ij: integer;
begin try
  rmat.allocate(n,n,1,true,false);
  rmat.nafill();
  if rvar = nil then exit;
  ij:= 0;
  for i:= 1 to n do begin
    if symmet then top:= i else top:= n;
    for j:= 1 to top do if (i<>j) or diagok
      then begin
        inc(ij);
        if xvalid[ij] and yvalid[ij] then begin
          rmat.cell[i,j]:= rvar[ij];
          if symmet then rmat.cell[j,i]:= rvar[ij];
          end;
        end;
    end;
  except
  end;
end;

function tlrqap.getvalidlist: integer;
var
  ij: integer;
begin
  xvars.rdsl.clear;
  for ij:= 1 to ncells do
    if xvalid[ij] and yvalid[ij] then
      xvars.rdsl.add(ij);
  result:= xvars.rdsl.n;
end;

procedure tlrqap.permuteandcopy(ymat:tsmat; aseed:integer; symmet:boolean=false);
var
  ij: integer;
begin
  p.randomlypermute(aseed);
  buildy(ymat,symmet);
end;

constructor tlrqapws.create(owner:tlrqap);
begin
  localp:= tivec.create;
  localp.allocate(owner.n,true,false);
  localp.one2n;
  localyvar:= tdvec.create;
  localyvar.allocate(owner.ncells,true,false);
  setlength(localyvalid,owner.ncells+1);
  localran:= tresultsrec.create(0);
  localran.allocate(owner.nv);
  xview:= tsmat.create;
  xview.cell:= owner.xvars.cell;   // shared read-only reference (refcounted)
  xview.nr:= owner.xvars.nr;
  xview.nc:= owner.xvars.nc;
  xview.nm:= 1;
  xview.rdsl.allocate(owner.ncells,true,true);
  if not owner.hasmissing then          // constant valid list when no missing y
    owner.buildvalidlist(xview.rdsl,nil);
  haveresult:= false;
end;

destructor tlrqapws.destroy;
begin
  localp.free;
  localyvar.free;
  localran.destroy;
  xview.free;            // frees its own rdsl; only drops the shared cell ref
  localyvalid:= nil;
  inherited;
end;

function tlrqap.buildvalidlist(rdsl:tdsl; yval:arrayofboolean): integer;
var
  ij: integer;
begin
  rdsl.clear;
  if yval = nil
    then for ij:= 1 to ncells do begin
      if xvalid[ij] then rdsl.add(ij);
      end
    else for ij:= 1 to ncells do begin
      if xvalid[ij] and yval[ij] then rdsl.add(ij);
      end;
  result:= rdsl.n;
end;

procedure tlrqap.buildyws(ws:tlrqapws; symmet:boolean=false);
var
  top,i,j,ij: integer;
  v: single;
begin
  ij:= 0;
  for i:= 1 to n do begin
    if symmet then top:= i else top:= n;
    for j:= 1 to top do if (i<>j) or diagok then begin
      inc(ij);
      v:= ymat.cell[ws.localp[i],ws.localp[j]];
      ws.localyvar[ij]:= v;
      if hasmissing then
        ws.localyvalid[ij]:= v < na;
      end;
    end;
end;

procedure tlrqap.runperm(ws:tlrqapws; aseed,it:integer; history:tsmat; symmet:boolean=false);
var
  j,tempnobs: integer;
begin
  ws.localp.randomlypermute(aseed);
  buildyws(ws,symmet);
  if hasmissing
    then tempnobs:= buildvalidlist(ws.xview.rdsl,ws.localyvalid)
    else tempnobs:= ws.xview.rdsl.n;
  ws.haveresult:= logisticregression(ws.localran.coefs,ws.localran.stderrs,
                    ws.localran.loglik,ws.localran.rsquare,ws.localran.numit,
                    ws.localyvar,nil,ws.xview,false,true);
  for j:= 1 to nv do
    history.cell[it,j]:= ws.localran.coefs[j];
  history.cell[it,nv+1]:= ws.localran.loglik;
  history.cell[it,nv+2]:= ws.localran.rsquare;
  history.cell[it,nv+3]:= tempnobs;
  AtomicIncrement(fprogress);   // thread-safe; UI thread reads this for the bar
end;

procedure tlrqap.storeresults(res:tresultsrec);
var
  j: integer;

  procedure addtocov;
  var
    i,k: integer;
  begin
    for i:= 1 to nv do
      for k:= 1 to nv do
        cov[i,k].addcase(res.coefs.cell[i],res.coefs.cell[k]);
  end;

begin
  for j:= 1 to nv do begin
    if abs(res.coefs.cell[j]) < singleprecision
      then res.coefs.cell[j]:= 0.0;
    if abs(res.stderrs.cell[j]) > singleprecision
      then res.tstats.cell[j]:= res.coefs.cell[j]/res.stderrs.cell[j]
      else res.tstats.cell[j]:= bna;
    end;
  case wtrack of
    trbetas:  for j:= 1 to nv do
         cstats[j].addcase(res.coefs.cell[j],obs.coefs[j]);
    trtstats: for j:= 1 to nv do begin
         cstats[j].addcase(res.coefs.cell[j],obs.coefs.cell[j]);
         tstats[j].addcase(res.tstats.cell[j],obs.tstats.cell[j]);
         end;
    end;
  addtocov;
  if hasmissing
    then lstat.addcase(res.rsquare,obs.rsquare)
    else lstat.addcase(res.loglik,obs.loglik);
end;

procedure tlrqap.buildftab(ftab:tsmat);
begin
  ftab.title:= 'Overall fit of the logistic regression model';
  ftab.cdvn.fillwith('LL|R-Sqr|Sig|Obs|Perms');
  ftab.rdvn.allocsize(1);
  ftab.rdvn.sput(1,'Statistics:');
  ftab.allocate(1,ftab.cdvn.n,1,true,false);
  ftab[1,1]:= obs.loglik;
  try ftab[1,2]:= obs.rsquare; except ftab[1,2]:= bna; end;
  if hasmissing
    then ftab[1,3]:= lstat.pge //bna
    else ftab[1,3]:= lstat.pge;
  ftab[1,4]:= nobs;
  ftab[1,5]:= lstat.n;
end;

function getsigviase(tstat:double; df:integer): double;
// returns p-value given tstat
begin
  result:= tprob(tstat,df);
end;

procedure tlrqap.buildctab0(ctab:tsmat);
var j: integer;
begin
  ctab.title:= 'LR Coefficients & Permutation Results (betas used in the permutations)';
  ctab.cdvn.fillwith('Coef|OddsRat|Sig|SD|Avg|Min|Max|P(ge)|P(le)');
  ctab.allocate(nv,ctab.cdvn.n,1,true,true);
  ctab.rdvn.copy(xvars.cdvn);
  for j:= 1 to nv do begin
    ctab[j,1]:= obs.coefs[j];
    try ctab[j,2]:= exp(obs.coefs[j]); except ctab[j,2]:= bna; end;
    if useSE
      then ctab[j,3]:= getsigviaSE(obs.tstats[j],nobs-2)
      else begin
        if obs.coefs[j] < 0
          then ctab[j,3]:= cstats[j].ple
          else ctab[j,3]:= cstats[j].pge;
        end;
    ctab[j,4]:= cstats[j].stddev;
    ctab[j,5]:= cstats[j].avg;
    ctab[j,6]:= cstats[j].min;
    ctab[j,7]:= cstats[j].max;
    ctab[j,8]:= cstats[j].pge;
    ctab[j,9]:= cstats[j].ple;
    end;
end;

procedure tlrqap.buildctab1(ctab:tsmat);
var j: integer;
begin
  ctab.title:= 'LR Coefficients & Permutation Results (T-stats used in permutations)';
  ctab.cdvn.fillwith('Coef|OddsRat|T|Sig|Avg|Min|Max|SD|P(ge)|P(le)|P(ext)');
  ctab.allocate(nv,ctab.cdvn.n,1,true,true);
  ctab.rdvn.copy(xvars.cdvn);
  for j:= 1 to nv do begin
    ctab[j,1]:= obs.coefs[j];
    try ctab[j,2]:= exp(obs.coefs[j]); except ctab[j,2]:= bna; end;
    ctab.vbcn[j,'T']:= obs.tstats[j];
    if useSE
      then ctab.vbcn[j,'Sig']:= getsigviase(obs.tstats[j],nobs-2)
      else begin
        if onetailed
          then begin
            if obs.tstats[j] < 0
              then ctab.vbcn[j,'Sig']:= tstats[j].ple
              else ctab.vbcn[j,'Sig']:= tstats[j].pge;
            end
          else ctab.vbcn[j,'Sig']:= tstats[j].pext;
        end;
    ctab.vbcn[j,'SD']:= cstats[j].stddev;
    ctab.vbcn[j,'Avg']:= cstats[j].avg;
    ctab.vbcn[j,'Min']:= cstats[j].min;
    ctab.vbcn[j,'Max']:= cstats[j].max;
    ctab.vbcn[j,'P(ge)']:= tstats[j].pge;
    ctab.vbcn[j,'P(le)']:= tstats[j].ple;
    ctab.vbcn[j,'P(ext)']:= tstats[j].pext;
    end;
  ctab.vbcn[1,'Sig']:= BNA;
  ctab.vbcn[1,'SD']:= bna;
  ctab.vbcn[1,'Avg']:= bna;
  ctab.vbcn[1,'Min']:= bna;
  ctab.vbcn[1,'Max']:= bna;
  ctab.vbcn[1,'P(ge)']:= bna;
  ctab.vbcn[1,'P(le)']:= bna;
  ctab.vbcn[1,'P(ext)']:= bna;

end;

procedure tlrqap.run(ymat,rmat,history:tsmat; xmats:tsmat3; track:integer=1; maxperm:integer= 10000;
                     symmet:boolean=false; aseed:integer=0; parallel:boolean=false; pb:tprogressbar=nil);
var
  it,j,i: integer;
  ptask: ITask;

  procedure runregular;
  var
    it,pbstep: integer;
    ws: tlrqapws;
  begin
    pbstep:= maxperm div 100;
    if pbstep < 1 then pbstep:= 1;
    ws:= tlrqapws.create(self);
    try
      for it:= 2 to maxperm do begin
        runperm(ws,seeds[it],it,history,symmet);
        if ws.haveresult then storeresults(ws.localran);
        if (pb <> nil) and (it mod pbstep = 0) then begin
          pb.Position:= fprogress;
          Application.ProcessMessages;
          end;
        end;
    finally
      ws.free;
    end;
  end;

begin try
  self.ymat:= ymat;   // buildyws reads the class field, not the parameter
  n:= ymat.n; nx:= xmats.nm; nv:= nx + 1; np:= 0;
  wtrack:= track;
  seed:= aseed;
  if symmet
    then ncells:= n*(n-1) div 2
    else ncells:= n*(n-1);
  setlength(cstats,nv+1);
  for j:= 1 to nv do
    cstats[j]:= tunivariate.create;
  setlength(tstats,nv+1);
  for j:= 1 to nv do
    tstats[j]:= tunivariate.create;
  setlength(cov,nv+1,nv+1);
  for i:= 1 to nv do
    for j:= 1 to nv do
      cov[i,j]:= tcorr.create;
  p.allocate(n,true,false);
  p.one2n;
  yvar.allocate(ncells,true,false);
  rvar.allocate(ncells,true,false);
  try buildx(xmats,symmet); except raise exception.Create('Unable to build X vars'); end;
  try buildy(ymat,symmet); except raise exception.Create('Unable to build X vars'); end;
  nobs:= getvalidlist;
  obs.allocate(nv); ran.allocate(nv);
  if seed = 0 then seed:= getrandomseed;
  setlength(seeds,maxperm+1);
  for j:= 1 to maxperm do 
    seeds[j]:= randomint(maxint,seed);
  history.allocate(maxperm,nv+3,1,true,false);
  history.cdvn.copy(xvars.cdvn);
  history.cdvn.addstr('loglik');
  history.cdvn.addstr('r-squared');
  history.cdvn.addstr('nobs');
  hasmissing:= nobs < ncells;
  if logisticregression(obs.coefs,obs.stderrs,obs.loglik,obs.rsquare,obs.numit,yvar,rvar,xvars,false,true)
    then begin
      storeresults(obs);
      for j:= 1 to nv do history.cell[1,j]:= obs.coefs[j];
      history.cell[1,nv+1]:= obs.loglik;
      history.cell[1,nv+2]:= obs.rsquare;
      history.cell[1,nv+3]:= nobs;
      rmat.copydef(ymat);
      rmat.allocate(ymat.nr,ymat.nc,ymat.nm,true,true);
      saveresiduals(rmat,symmet);
      end
    else raise exception.create('Unable to run logistic regression');
  if pb <> nil then begin
    pb.Position:= 0;
    pb.Max:= maxperm;
    end;
  fprogress:= 1;   // the observed (un-permuted) fit above counts as one
  if parallel
    then begin
      // TParallel.For blocks its calling thread, so run it on a background
      // task and let the UI thread poll the atomic counter and stay responsive.
      // (Body inlined here rather than in a nested procedure: anonymous methods
      // cannot capture nested procedures — E2555 — but can capture self/params.)
      ptask:= TTask.Run(procedure
        var
          cs: tcriticalsection;
          nthreads: integer;
        begin
          cs:= tcriticalsection.create;
          nthreads:= tthread.processorcount;
          if nthreads < 1 then nthreads:= 1;
          try
            // One workspace per thread (not per permutation): partition the
            // permutation range into nthreads contiguous chunks. Each chunk
            // runs independently; only the shared accumulators are serialized.
            TParallel.For(0, nthreads-1, procedure (t: Integer)
              var
                ws: tlrqapws;
                it,lo,hi: integer;
              begin
                lo:= 2 + (int64(t)*(maxperm-1)) div nthreads;
                hi:= 1 + (int64(t+1)*(maxperm-1)) div nthreads;
                if hi > maxperm then hi:= maxperm;
                if lo > hi then exit;
                ws:= tlrqapws.create(self);
                try
                  for it:= lo to hi do begin
                    runperm(ws,seeds[it],it,history,symmet);
                    if ws.haveresult then begin
                      cs.enter;
                      try storeresults(ws.localran); finally cs.leave; end;
                      end;
                    end;
                finally
                  ws.free;
                end;
              end);
          finally
            cs.free;
          end;
        end);
      if pb <> nil
        then begin
          while not ptask.Wait(100) do begin
            pb.Position:= fprogress;
            Application.ProcessMessages;
            end;
          end
        else ptask.Wait;
      end
    else runregular;
  if pb <> nil then pb.Position:= maxperm;
  for j:= 1 to nv do begin
    cstats[j].calc;
    tstats[j].calc;
    end;
  lstat.calc;
  finally
  end;
End;


end.
