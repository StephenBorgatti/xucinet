
unit uMtxvecRegression;
interface
uses
  sysutils, generics.collections,
  ucommon, mtxvec, regress, mtxbasecomp,
  uconvertmtx, udistrib, utunivariate;
type
  tregression = class
    y,b,beta,yhat,w,resid,bse,t,p,permp: mtxvec.tvec;
    uy: tsimpleuni;
    ux: tobjectlist<tsimpleuni>;
    a,ata: tmtx;
    regstat: tregstats;
    permfprob: double;
    caseid: integer;
    ncase,nvar: integer;
    method: TRegSolveMethod;
    mtxconst: boolean;
    constructor create(meth:TRegSolveMethod=regSolveSVD);
    destructor destroy;  override;
    function addcase(const yval:single; const x:arrayofsingle; firstx,lastx:integer; firsta:integer=0): boolean;
    function getfstr: string;
    procedure addconst(j:integer=0);
    procedure addx(j:integer; xval:single);
    procedure clear;
    procedure getypermsig(onetailed:boolean=true; maxit:integer=5000; seed:integer=minint);
    procedure setcapacities(nr,nc:integer);
    procedure calc(withstats:boolean=true);
    procedure partialcopy(reg:tregression);
    property modeldf:integer read regstat.fstats.dfe;
    property residualdf:integer read regstat.fstats.dfr;
    property fstr:string read getfstr;
    property rsqr:double read regstat.r2;
    property adjrsqr:double read regstat.adjustedr2;
    property fstat:double read regstat.fstats.f;
    property fprob:double read regstat.fstats.signif;
  end;

implementation
(* how to use
reg := typermregression.create;
reg.setcapacities
for rec in mydata
  reg.addcase(rec.yval,rec.xvals)
reg.calc
reg.getsignificance
*)

procedure tregression.partialcopy(reg: tregression);
//results are copied, but indep mat A is merely linked to
begin
  y.Copy(reg.y); b.Copy(reg.b); yhat.Copy(reg.yhat); beta.Copy(reg.beta);
  resid.Copy(reg.resid); bse.Copy(reg.bse); t.Copy(reg.t);
  p.copy(reg.p); permp.copy(reg.permp);
  ata.Copy(reg.ata); regstat:= reg.regstat; permfprob:= reg.permfprob;
  ncase:= reg.ncase; caseid:= reg.caseid; nvar:= reg.nvar;
  method:= reg.method;
  a:= reg.a;
end;

constructor tregression.create(meth:TRegSolveMethod=regSolveSVD);
begin
  mtxconst:= true;
  method:= meth;
  createit(y);
  createit(b);
  createit(beta);
  createit(yhat);
  createit(resid);
  createit(bse);
  createit(t);
  createit(p);
  createit(permp);
  createit(a);
  createit(ata);
  uy:= tsimpleuni.create;
  ux:= tobjectlist<tsimpleuni>.create;
  clear;
end;

destructor tregression.destroy;
begin
  clear;
  freeit(y);
  freeit(b);
  freeit(beta);
  freeit(yhat);
  freeit(resid);
  freeit(bse);
  freeit(t);
  freeit(p);
  freeit(permp);
  freeit(a);
  freeit(ata);
  uy.Free;
  ux.Free;
end;

procedure tregression.setcapacities(nr,nc:integer);
var
  i: integer;
begin
  a.Size(nr,nc);
  y.Length:= nr;
  ux.Clear;
  for i:= 1 to nc+1 do    //allow for constant
    ux.Add(tsimpleuni.create);
end;

procedure tregression.clear;
var
  u: tsimpleuni;
begin
  caseid:= -1; ncase:= 0; permfprob:= 0;
  uy.clear;
  for u in ux do
    u.clear;
end;

function tregression.addcase(const yval:single; const x:arrayofsingle; firstx,lastx:integer; firsta:integer=0): boolean;
//x may or may not be 0-based, but must have a.cols values
var
  j,jj: integer;

  function anymissing: boolean;
  var
    j: integer;
  begin
    if yval >= na then exit(true);
    for j:= firstx to lastx do 
      if x[j] >= na then exit(true);
    result:= false;
  end;
  
begin
  if anymissing then exit(false);
  inc(caseid);
  y[caseid]:= yval;
  jj:= firsta-1;
  uy.addcase(yval);
  for j:= firstx to lastx do begin
    inc(jj);
    a[caseid,jj]:= x[j];
    ux[jj+1].addcase(x[j]);
    end;
  result:= true;
end;

procedure tregression.addx(j:integer; xval:single);
begin
  inc(caseid);
  a[caseid,j]:= xval;
end;

procedure tregression.addconst(j:integer=0);
var i: integer;
begin
  for i:= 0 to a.rows-1 do
    a[i,j]:= 1;
end;

procedure tregression.calc(withstats:boolean=true);
var
  j: integer;
begin
  ncase:= caseid + 1;
  if ncase <> a.Rows then begin
    a.Resize(ncase,a.cols);
    y.Resize(ncase);
    end;
  if withstats
    then begin
      MulLinRegress(y,A,b,mtxconst,yhat,ata,method);
      RegressTest(y,yhat,ATA,RegStat,resid,bse,mtxconst,nil);
      t.Size(b.length);
      p.size(b.length);
      permp.size(b.length);
      beta.size(b.Length);
      t[0]:= bna;
      p[0]:= bna;
      beta[0]:= 0;
      permp[0]:= bna;
      for j:= 1 to b.Length-1 do
        if bse[j] > 0
          then begin
            beta[j]:= b[j]*ux[j].sd/uy.sd;
            t[j]:= b[j]/bse[j];
            p[j]:= tprob(t[j],regstat.dfT-1);
//            p[j]:= zprob(t[j]);
            end
          else begin
            t[j]:= bna;
            p[j]:= bna;
            beta[j]:= bna;
            end;
      end
    else MulLinRegress(y,A,b,mtxconst,nil,nil,method);
  nvar:= b.Length;
end;

function tregression.getfstr: string; 
begin
  result:= 'F(' + inttostr(modeldf) + ',' + inttostr(residualdf) + ')';
end;

procedure tregression.getypermsig(onetailed:boolean=true; maxit:integer=5000; seed:integer=minint); 
var
  it,j: integer;
  num: arrayofinteger;
  obs: tregression;
  numf: int64; 

  procedure recordtwotailed(j:integer);
  begin
    if abs(t[j]) >= abs(obs.t[j])
      then inc(num[j]);
  end;
  
  procedure recordneg(j:integer);
  begin
    if t[j] <= obs.t[j]
      then inc(num[j]);
  end;

  procedure recordpos(j:integer);
  begin
    if t[j] >= obs.t[j]
      then inc(num[j]);
  end;

begin  try
  obs:= tregression.create();
  obs.partialcopy(self);
  if seed = minint then seed:= randseed;
  setlength(num,nvar);
  for j:= 0 to nvar-1 do
    num[j]:= 1;
  numf:= 1;
  it:= 1;
  while it < maxit do begin
    inc(it);
    copyrandomlypermuted(y,obs.y);
    calc(true);
    for j:= 0 to nvar-1 do
      if onetailed
        then if obs.t[j] < 0
          then recordneg(j)
          else recordpos(j)
        else recordtwotailed(j);
    if regstat.FStats.f >= obs.regstat.fstats.f
//    if regstat.R2 >= obs.regstat.r2
      then inc(numf);
    end;
  self.partialcopy(obs);
  permp[0]:= bna;
  for j:= 1 to nvar-1 do
    permp[j]:= 1.0*num[j]/maxit;
  permfprob:= 1.0*numf/maxit;
  obs.free; num:= nil;
  except
    raise exception.Create(Inttostr(it)+' iterations. Unable to run permutation regression. Check the variables.');
  end;
end;

end.
