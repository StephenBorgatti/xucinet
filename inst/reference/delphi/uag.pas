unit uag;
interface
uses
  ucommon, ugeneral, umatrix, usmatrix, ulmatrix, uvector, ustats;

function densitymodel1(x:matrix; y:smatrix; p:sivector; diagok:boolean; nclass:integer=0): integer;
function blockdensity(d,bm: smatrix; rp,cp:sivector;
                      nrp,ncp:integer; diagok:boolean=false): integer;
function blockrsq(var rsqr:single; d,den:smatrix; rp,cp:sivector; diagok:boolean=false): integer;
{---------------------------------------------------------------------------}
implementation
{---------------------------------------------------------------------------}
{procedure getnumclasses(var p:dslvector; var np: integer);
begin
  for i:= 1 to p.n do begin
    list.appendifnew(
end;}
{---------------------------------------------------------------------------}
procedure getmaxclass(var p:sivector; var np:integer);
var i: integer;
begin
  np:= 0;
  for i:= 1 to p.n do
    if p.cell^[i] > np then np:= p.cell^[i];
end;
{---------------------------------------------------------------------------}
function densitymodel1(x:matrix; y:smatrix; p:sivector; diagok:boolean; nclass:integer=0): integer;
label cleanup;
var
  num: lmatrix;
  i,j,ii,jj: integer;
begin
  num:= lmatrix.create;
  if nclass = 0 then getmaxclass(p,nclass);
  if nclass = 0 then goto cleanup;
  if num.allocsize(nclass,nclass) <> 0 then goto cleanup;
  if y.allocsize(nclass,nclass) <> 0 then goto cleanup;
//  y.zerofill; num.zerofill;
  for i:= 1 to x.nr do
    for j:= 1 to x.nc do
      if (i <> j) or diagok then begin
        ii:= p.cell^[i]; jj:= p.cell^[j];
        y.cell^[ii]^[jj]:= y.cell^[ii]^[jj] + x.fget(i,j);
        inc(num.cell^[ii]^[jj]);
        end;
  for i:= 1 to y.nr do
    for j:= 1 to y.nc do
      if num.cell^[i]^[j] > 0
        then y.cell^[i]^[j]:= y.cell^[i]^[j]/num.cell^[i]^[j]
        else y.cell^[i]^[j]:= bna;
  cleanup:
    num.free;
    result:= error;
end;
{---------------------------------------------------------------------------}
function blockdensity(d,bm: smatrix; rp,cp:sivector;
                      nrp,ncp:integer; diagok:boolean=false): integer;
{assumes p has values from 1 to k, where k is number of blocks}
label cleanup;
var
  bn: array of array of integer;
  i,j,rpi,cpj: integer;
begin
  bm.allocsize(nrp,ncp);
  bm.title:= 'Density Table';
  setlength(bn,nrp+1,ncp+1);
  for i:= 1 to nrp do for j:= 1 to ncp do bn[i,j]:= 0;
  {if not bm.hasval then if bm.allocsize(nrp,ncp) <> 0 then goto cleanup;}
  for i:= 1 to d.nr do for j:= 1 to d.nc do if (i<>j) or diagok then begin
    if d.cell^[i]^[j] < na
      then begin
        rpi:= rp.cell^[i]; cpj:= cp.cell^[j];
        bm.cell^[rpi]^[cpj]:= bm.cell^[rpi]^[cpj] + d.cell^[i]^[j];
        inc(bn[rpi,cpj]);
        end;
    end;
  for i:= 1 to nrp do for j:= 1 to ncp do if bn[i,j] > 0
    then bm.cell^[i]^[j]:= bm.cell^[i]^[j]/bn[i,j]
    else bm.cell^[i]^[j]:= bna;
  cleanup:
    bn:= nil;
    result:= error;
end;
{---------------------------------------------------------------------------}
function blockrsq(var rsqr:single; d,den:smatrix; rp,cp:sivector; diagok:boolean=false): integer;
label cleanup;
var
  n,bi,bj,i,j: integer;
  s: bestimator;
begin
  try
  error := 0;
  s:= bestimator.create;
  if (d.nr <> d.nc) then diagok:= true;
  for i:= 1 to d.nr do
    for j:= 1 to d.nc do
      if ((i <> j) or diagok) and (d.cell^[i]^[j] < na) and
         (den.cell^[rp.cell^[i]]^[cp.cell^[j]] < na) then
            s.addrcase(d.cell^[i]^[j],den.cell^[rp.cell^[i]]^[cp.cell^[j]]);
  s.rcalc;
  if s.corr < 1.0+singleprecision
    then rsqr:= sqr(s.corr)
    else rsqr:= bna;
  cleanup:
    result:= error;
    s.free;
  except
    result:= 1;
    s.free;
  end;
  end;
{---------------------------------------------------------------------------}
end.
