Unit ujohnsonhiclus;
Interface
Uses
  math,
  ucommon, utivec, utsvec, utsmat, utimat;
{===========================================================================}
Function JohnsonHiclus(d:tsmat; p:timat; sim:boolean; method: integer;
  var level:tsvec): boolean;
type
  hiclusfunc = function(x,y:single; s1,s2:integer): single;
Const
  singlelink = 1; completelink = 2; wtdaveragelink = 3; simpleaveragelink = 4;
{===========================================================================}
Implementation
{===========================================================================}
function mincomp(x,y:single; s1,s2:integer): single;
begin
  if x > y then mincomp:= y else mincomp:= x;
end;
{---------------------------------------------------------------------------}
function maxcomp(x,y:single; s1,s2:integer): single;
begin
  if x < y then maxcomp:= y else maxcomp:= x;
end;
{---------------------------------------------------------------------------}
function wtdavgcomp(x,y:single; s1,s2:integer): single;
begin
  result:= (x*s1 + y*s2)/(s1+s2);
end;
{---------------------------------------------------------------------------}
function simpleavgcomp(x,y:single; s1,s2:integer): single;
begin
  result:= (x + y)/2.0;
end;
{---------------------------------------------------------------------------}
Function JohnsonHiclus(d:tsmat; p:timat; sim:boolean; method: integer;
  var level:tsvec): boolean;
label cleanup;
Var
  npart,n,it,ni,nj,i,j: integer;
  size,part: arrayofinteger;
  subsumed: array of boolean;
  rdsl: tivec;
  lastd,dist: single;
  comp: hiclusfunc;

  Procedure GetBiggestPair;
  Var
    i,j: integer;
  Begin
    dist:= minfloat;
    for i:= 2 to rdsl.n do
      for j:= 1 to i-1 do
        if d.cell[rdsl.cell[i]][rdsl.cell[j]] > dist then begin
          ni:= rdsl.cell[i];
          nj:= rdsl.cell[j];
          dist:= d.cell[rdsl.cell[i]][rdsl.cell[j]];
          end;
  End;

  Procedure GetSmallestPair;
  var
    i,j: integer;
  begin
    dist:= maxfloat;
    for i:= 2 to rdsl.n do
      for j:= 1 to i-1 do
        if d.cell[rdsl.cell[i]][rdsl.cell[j]] < dist then begin
          ni:= rdsl.cell[i]; nj:= rdsl.cell[j];
          dist:= d.cell[rdsl.cell[i]][rdsl.cell[j]];
          end;
  End;

  Procedure GetNewDistances;
  Var
    k,l: integer;
  Begin
    for k:= 1 to rdsl.n do begin
      l:= rdsl.cell[k];
      if (l <> ni) then begin
        d.cell[ni][l]:= comp(d.cell[ni][l],d.cell[nj][l],size[ni],size[nj]);
        d.cell[l][ni]:=  d.cell[ni][l];
        end;
      end;
  End;

Begin
try
  rdsl:= tivec.create;
  n:= d.n;
  if not level.hasval then
    if not level.allocsize(n) then goto cleanup;
  if not p.hasval then
    if not p.allocsize(n,n) then goto cleanup;
  if not rdsl.allocsize(n) then goto cleanup;
  setlength(size,n+1);
  setlength(subsumed,n+1);
  setlength(part,n+1);
  for i:= 1 to n do begin
    size[i]:= 1;
    part[i]:= i;
    rdsl[i]:= i;
    end;
  npart:= 0; lastd:= na;
  case method of
    singlelink:   if sim then comp:= maxcomp else comp:= mincomp;
    completelink: if sim then comp:= mincomp else comp:= maxcomp;
    wtdaveragelink:  comp:= wtdavgcomp;
    simpleaveragelink: comp:= simpleavgcomp;
    end;
  for it:= 1 to n-1 do begin
    if sim then getbiggestpair else getsmallestpair;
    subsumed[nj]:= true;
    size[ni]:= size[ni] + size[nj];
    if not samevalue(dist,lastd) then begin
      inc(npart);
      if npart > 1 then
        for j:= 1 to n do p.cell[j][npart-1]:= part[j];
      lastd:= dist;
      level.cell[npart]:= dist;
      end;
    rdsl.n:= 0;
    for j:= 1 to n do begin
      if part[j] = nj
        then part[j]:= ni;
      if not subsumed[j] then rdsl.append(j);
      end;
    GetNewDistances;
    end;
  for j:= 1 to n do p.cell[j][npart]:= part[j];
  p.nc:= npart;
cleanup:
finally
  result := error = 0;
  size:= nil; subsumed:= nil; part:= nil; rdsl.destroy;
end;
End;
{===========================================================================}
End.

