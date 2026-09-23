unit utcpcat;
interface
uses
  generics.collections, math, classes,
  ucommon, ug2tabusearch, utivec, utsvec, utsmat, utcorr, ug2elbow;

type
  tcatcp = class
    n: integer;
    mat: tsmat;
    corr: tcorr;
    clist,plist,iterations: tlist<integer>;
    log: tlist<single>;
    diagok: boolean;
    part: tivec;
    fit,maxfit,lasteval: double;
    c2p,p2c: single;
    maxit,nstart: integer;
    usegreedy: boolean;
    constructor create;
    destructor destroy;  override;
    function evaluate(p:tivec): double;
    function getelbow(v:tsvec): single;
    procedure getrandompart(p:tivec);
    procedure getdegreepart(p:tivec);
    procedure geteigenpart(p:tivec);
    function greedyhillclimb(p:tivec): double;
    function hillclimb(p:tivec): double;
    procedure optimize;
    procedure run(amat:tsmat; opt:boolean=true);
  end;

  procedure makecpmatna(x:tsmat; p:tivec);

implementation

procedure makecpmatna(x:tsmat; p:tivec);
var
  i,j: integer;
begin
  for i:= 1 to x.n do
    for j:= 1 to x.n do
      if (p.cell[i] = p.cell[j])
        then if p.cell[i] = 1
          then x.cell[i,j]:= 1
          else x.cell[i,j]:= 0
        else x.cell[i,j]:= bna;
  for i:= 1 to x.n do
    x.cell[i,i]:= bna;
end;

constructor tcatcp.create;
begin
  diagok:= false;
  c2p:= bna;
  p2c:= bna;
  lasteval:= mindouble;
  maxit:= 100;
  maxfit:= 1.0;
  fit:= 0;
  nstart:= 10;
  usegreedy:= false;
  clist:= tlist<integer>.create;
  plist:= tlist<integer>.create;
  iterations:= tlist<integer>.create;
  log:= tlist<single>.create;
  corr:= tcorr.create;
  part:= tivec.create;
end;

destructor tcatcp.destroy;
begin
  clist.free;
  plist.free;
  corr.free;
  log.free;
  part.free;
  iterations.Free;
end;

function tcatcp.evaluate(p:tivec): double;

  procedure identifycandp;
  var
    i: integer;
  begin
    clist.clear;
    plist.clear;
    for i:= 1 to n do
      if p.cell[i] = 1
        then clist.add(i)
        else plist.add(i);
  end;

  procedure addcases(list1,list2:tlist<integer>; x:single);
  var
    i,j: integer;
    diag: boolean;
  begin
    if list1 = list2
      then diag:= diagok
      else diag:= false;
    for i:= 0 to list1.count-1 do 
      for j:= 0 to list2.count-1 do if (i <> j) or diagok 
        then corr.addcase(x,mat.cell[list1[i],list2[j]]);
  end;

begin
  identifycandp;
  corr.clear;
  addcases(clist,clist,1);
  addcases(plist,plist,0);
  if c2p < na
    then addcases(clist,plist,c2p);
  if p2c < na
    then addcases(plist,clist,p2c);
  corr.calc;
  lasteval:= corr.corr;
  if lasteval >= na
    then result:= mindouble
    else result:= lasteval;
//  log.add(result);
end;

procedure tcatcp.getrandompart(p:tivec);
var
  i,j: integer;
begin
  for i:= 1 to n do 
    if random < 0.384
      then p.cell[i]:= 1
      else p.cell[i]:= 2;
end;
  
function tcatcp.getelbow(v:tsvec): single;
var
  i: integer;
  r,maxcorr: single;
  d: tdsl;
  p: tivec;
  c: tcorr;

  function runsplit(cut:integer): single;
  var
    k: integer;
  begin
    for k:= 1 to v.n do
      if k <= cut
        then p.cell[d[k]]:= 1
        else p.cell[d[k]]:= 2;
    result:= evaluate(p);
  end;
  
begin try
  d:= tdsl.create;
  p:= tivec.create;
  p.allocate(v.n,true,false);
  d.allocate(v.n);
  result:= 0; maxcorr:= -2.0;
  d.sortby('d',v);
  for i:= 1 to v.n-1 do begin
    r:= runsplit(i);
    if r > maxcorr then begin 
      maxcorr:= r; 
      result:= v.cell[d[i]]; 
      end;
    end;
  finally
    d.free;
    p.free;
  end;
end;

function largestdiff(s1,s2:array of double; n:integer): double;
var
  i: integer;
begin
  result:= abs(s1[1]-s2[1]);
  for i := 1 to n do
    if abs(s1[i]-s2[i]) > result then
      result:= abs(s1[i]-s2[i]);
end;

procedure tcatcp.geteigenpart(p:tivec);
var
  i,j,k: integer;
  deg: tsvec;
  x: single;
  s1,s2: array of double;
  tot: double;
begin try
  deg:= tsvec.create;
  deg.allocate(n,true,true);
  setlength(s1,n+1);
  setlength(s2,n+1);
  for i:= 1 to n do s1[i]:= 1.0;
  for k:= 1 to 4 do begin
    tot:= 0;
    for i:= 1 to n do begin
      s2[i]:= 0;
      for j:= 1 to n do if ((i<>j) or diagok) and mat.isvalid(i,j) then
        s2[i]:= s2[i] + (mat.cell[i,j]+mat.cell[j,i])*s1[j];
        tot:= tot + sqr(s2[i]);
        end;
    tot:= sqrt(tot);
    if tot > 0
      then for i:= 1 to n do s1[i]:= s2[i]/tot;
    if largestdiff(s1,s2,n) < 0.01 then
      break;
    end;
  for i:= 1 to n do deg.cell[i]:= s1[i];
  x:= getelbow(deg);
  for i:= 1 to n do
    if deg.cell[i] >= x 
      then p.cell[i]:= 1
      else p.cell[i]:= 2;
  finally
    deg.Free;
    s1:= nil; s2:= nil;
  end;
end;
  
procedure tcatcp.getdegreepart(p:tivec);
var
  i,j: integer;
  deg: tsvec;
  x: single;
begin try
  deg:= tsvec.create;
  deg.allocate(n,true,true);
  for i:= 1 to n do 
    for j:= 1 to n do 
      if (i<>j) and mat.isvalid(i,j) then
        deg.cell[j]:= deg.cell[j] + mat.cell[i,j];
  x:= getelbow(deg);
  for i:= 1 to n do
    if deg.cell[i] >= x 
      then p.cell[i]:= 1
      else p.cell[i]:= 2;
  finally
    deg.Free;
  end;
end;
  
function tcatcp.hillclimb(p:tivec): double;
var
  i,it: integer;
  nextmove: integer;
  nexteval: double;
begin try
  it:= 0;
  repeat
    inc(it);
    result:= evaluate(p);
    nexteval:= result;
    nextmove:= 0;
    for i:= 1 to n do begin
      p.flip(i,1,2); //if pi = 1 then pi := 2 else pi := 1
      if (evaluate(p) > nexteval) and (lasteval < na) then begin
        nexteval:= lasteval;
        nextmove:= i;
        end;
      p.flip(i,1,2); //flips back again
      end;
    if nexteval > result
      then begin p.flip(nextmove,1,2); result:= nexteval; end
      else exit;
  until it = maxit;
  finally
    iterations.Add(it);
  end;
end;

function tcatcp.greedyhillclimb(p:tivec): double;
//currently not used
var
  i,it: integer;
  changed: boolean;
begin
  it:= 0;
  repeat
    inc(it);
    result:= evaluate(p);
    changed:= false;
    for i:= 1 to n do begin
      p.flip(i,1,2); //if pi = 1 then pi := 2 else pi := 1
      if (evaluate(p) <= result)
        then p.flip(i,1,2) //flips back again
        else changed:= true;
      end;
  until (it = maxit) or (not changed);
  iterations.Add(it);
end;

procedure tcatcp.optimize;
type
  Talgorithm = function(p:tivec): double of object;
var
  apart: tivec;
  aneval: double;
  start: integer;
  doit: talgorithm;
begin
  apart:= tivec.create;
  apart.allocate(n,true,false);
  iterations.clear;
  (*
  if mat.IsValued
    then geteigenpart(part)
    else getdegreepart(part);
  *)
  if usegreedy
    then doit:= greedyhillclimb
    else doit:= hillclimb;
  fit:= doit(part);
  for start:= 2 to nstart do begin
    getrandompart(apart);
    aneval:= doit(apart);
    if aneval > fit then begin
      fit:= aneval;
      part.copy(apart);
      end;
    if fit >= maxfit then break;
    end;
end;

procedure tcatcp.run(amat:tsmat; opt:boolean=true);
//if opt = false then it runs initial partition only
begin
  n:= amat.n;
  mat:= amat;
  part.allocate(n,true,true);
  randomize;
  if mat.IsValued
    then geteigenpart(part)
    else getdegreepart(part);
  if opt
    then optimize;
end;

end.
