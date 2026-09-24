Unit ug2simdis;
{deprecated in favor of ug2sim2?}
Interface
Uses
    math, ucommon,utevec,utsmat,umsg,ugeodist,ukey,umath, utsvec, utsmat3, ustats;
type
  simdisfunc = procedure(var x,y:arrayofsingle; var z:extended; n:integer);
{func}
function methstr(m:integer): string;
function wmeth(s:string): integer;
procedure AVGSSCP(var x,y:arrayofsingle; var z:extended; n:integer);
procedure bonacich72(var x,y:arrayofsingle; var z:extended; n:integer);
procedure CohenKappa(var x,y:arrayofsingle; var z:extended; n:integer);
procedure Correlation(var x,y:arrayofsingle; var z:extended; n:integer);
procedure cosine(var x,y:arrayofsingle; var z:extended; n:integer);
procedure Covariance(var x,y:arrayofsingle; var z:extended; n:integer);
procedure euclid(var x,y:arrayofsingle; var z:extended; n:integer);
procedure GeneralizedJaccard(var x,y:arrayofsingle; var z:extended; n:integer);
procedure getcorrcovamongmatrices(r:tsmat; x:tsmat3; corr:boolean=true; typeofdata:integer=4; pi:extended=0.5);
procedure getcorrcovamongrows(r:tsmat; x:tsmat; corr:boolean=true; pi:extended=0.5);
procedure hammondsim(var x,y:arrayofsingle; var z:extended; n:integer);
procedure Identity(var x,y:arrayofsingle; var z:extended; n:integer);
procedure manhattan(var x,y:arrayofsingle; var z:extended; n:integer);
procedure Matches(var x,y:arrayofsingle; var z:extended; n:integer);
procedure matchmatrices(r:tsmat; x:tsmat3; typeofdata:integer=4; guessing:single=bna);
procedure matchrows(r:tsmat; d:tsmat; guessing:single=bna);
procedure maxcrossmin(var x,y:arrayofsingle; var z:extended; n:integer);
procedure mcSSCP(var x,y:arrayofsingle; var z:extended; n:integer);
procedure nonMatches(var x,y:arrayofsingle; var z:extended; n:integer);
procedure nssd(var x,y:arrayofsingle; var z:extended; n:integer);
procedure Overlaps(var x,y:arrayofsingle; var z:extended; n:integer);
procedure PosMatches(var x,y:arrayofsingle; var z:extended; n:integer);
procedure PosnonMatches(var x,y:arrayofsingle; var z:extended; n:integer);
procedure sesim2(r:tsmat; d:tsmat3; simdis:simdisfunc;transp,usedist:boolean; method:smallint);
procedure SSCP(var x,y:arrayofsingle; var z:extended; n:integer);
procedure SSCPmin(var x,y:arrayofsingle; var z:extended; n:integer);
procedure sumcrossmin(var x,y:arrayofsingle; var z:extended; n:integer);
procedure SumSqrDiff(var x,y:arrayofsingle; var z:extended; n:integer);

Const
  ignore = 1; retain1 = 2; retain2 = 3; recip1 = 4; recip2 = 5; retain = 6;
  recip = 7;
{===========================================================================}
Implementation
{===========================================================================}
function wmeth(s:string): integer;
begin
     if iskey(s,'i|d') then begin wmeth:= ignore; exit; end;
     if iskey(s,'retain1|ret1|rt1') then begin wmeth:= retain1; exit; end;
     if iskey(s,'retain2|ret2|rt2') then begin wmeth:= retain2; exit; end;
     if iskey(s,'ret') then begin wmeth:= retain; exit; end;
     if iskey(s,'reciprocal1|rc1|rec1|recip1')  then begin wmeth:= recip1; exit; end;
     if iskey(s,'reciprocal2|rc2|rec2|recip2')  then begin wmeth:= recip2; exit; end;
     if iskey(s,'rec')  then begin wmeth:= recip; exit; end;
     wmeth:= 0;
end;
{---------------------------------------------------------------------------}
function diagstr(i:integer): string;
begin
  case i of
    1: diagstr:= 'IGNORE';
    2: diagstr:= 'RETAIN1 (single count)';
    3: diagstr:= 'RETAIN2 (double count)';
    4: diagstr:= 'RECIPROCAL1 (single count)';
    5: diagstr:= 'RECIPROCAL2 (double count)';
    6: diagstr:= 'RETAIN';
    7: diagstr:= 'RECIPROCAL';
    else diagstr:= 'UNKNOWN';
    end;
end;
{---------------------------------------------------------------------------}
function methstr(m:integer): string;
begin
  case m of
    ignore: result:= 'Ignore';
    retain1: result:= 'Retain1 (single count)';
    retain2: result:= 'Retain2 (double count)';
    recip1: result:= 'Reciprocal1 (single count)';
    recip2: result:= 'Reciprocal2 (double count)';
    retain: result:= 'Retain';
    recip: result:= 'Reciprocal';
    else result:= 'Unknown';
    end;
end;
{---------------------------------------------------------------------------}
procedure Matches(var x,y:arrayofsingle; var z:extended; n:integer);
var
  num,k: integer;
begin
  num:= 0; z:= 0;
  for k:= 1 to n do
    if (x[k] < na) and (y[k] < na) then begin
      z:= z + smallint(x[k]=y[k]);
      inc(num);
      end;
  if num > 0 then z:= z/num else z:= bna;
end;
{---------------------------------------------------------------------------}
procedure Overlaps(var x,y:arrayofsingle; var z:extended; n:integer);
var
  num,k: integer;
begin
  num:= 0; z:= 0;
  for k:= 1 to n do
    if (x[k] < na) and (y[k] < na) then begin
      if (x[k] > 0) and (y[k] > 0) then
        z:= z + 1;
      inc(num);
      end;
  if num > 0 then z:= z/num else z:= bna;
end;
{---------------------------------------------------------------------------}
procedure PosMatches(var x,y:arrayofsingle; var z:extended; n:integer);
Var
  num,k,iz: integer;
Begin
  num:= 0; iz:= 0;
  for k:= 1 to n do
      if (x[k] < na) and (y[k] < na) then
          if (x[k] > 0) or (y[k] > 0) then begin
              inc(num);
              if (x[k] > 0) and (y[k] > 0) then inc(iZ);
          end;
  if num > 0
    then z:= 1.0*iz/num
    else z:= bna;
End;
{---------------------------------------------------------------------------}
procedure GeneralizedJaccard(var x,y:arrayofsingle; var z:extended; n:integer);
Var
  k: integer;
  numer,denom: double;
Begin
  numer:= 0; denom:= 0;
  for k:= 1 to n do
    if (x[k] < na) and (y[k] < na) then begin
      numer:= numer + min(x[k],y[k]);
      denom:= denom + max(x[k],y[k]);
      end;
  if denom > 0
    then  z:= numer/denom
    else  z:= bna;
End;
{---------------------------------------------------------------------------}
procedure nonmatches(var x,y:arrayofsingle; var z:extended; n:integer);
Begin
  matches(x,y,z,n);
  if z < na then z:= 1.0 - z;
End;
{---------------------------------------------------------------------------}
procedure posnonmatches(var x,y:arrayofsingle; var z:extended; n:integer);
Begin
  posmatches(x,y,z,n);
  if z < na then z:= 1.0 - z;
End;
{---------------------------------------------------------------------------}
procedure euclid(var x,y:arrayofsingle; var z:extended; n:integer);
{euclidean distance}
Var
  num,k: integer;
Begin
  num:= 0; z:= 0;
  for k:= 1 to n do
      if (x[k] < na) and (y[k] < na) then begin
          z:= z + sqr(x[k]-y[k]); inc(num);
      end;
  if num > 0 then z:= n*sqrt(z)/num else z:= bna;
End;
{---------------------------------------------------------------------------}
procedure manhattan(var x,y:arrayofsingle; var z:extended; n:integer);
{city block distance}
Var
  num,k: integer;
Begin
  num:= 0; z:= 0;
  for k:= 1 to n do
      if (x[k] < na) and (y[k] < na) then begin
          z:= z + abs(x[k]-y[k]); inc(num);
      end;
  if num > 0 then z:= n*z/num else z:= bna;
End;
{---------------------------------------------------------------------------}
procedure nssd(var x,y:arrayofsingle; var z:extended; n:integer);
{normed sum of squared differences}
Var
  k: integer;
  xsq,ysq: extended;
Begin
  z:= 0; xsq:= 0; ysq:= 0;
  for k:= 1 to n do
      if (x[k] < na) and (y[k] < na) then begin
         z:= z + sqr(x[k]-y[k]);
         xsq:= xsq + sqr(x[k]); ysq:= ysq + sqr(y[k]);
      end;
  if (xsq > 0) and (ysq > 0) then z:= z/(xsq*ysq) else z:= bna;
End;
{---------------------------------------------------------------------------}
procedure AVGSSCP(var x,y:arrayofsingle; var z:extended; n:integer);
{ avg sums of squares and cross products}
Var
  num,k: integer;
Begin
  num:= 0; z:= 0;
  for k:= 1 to n do
      if (x[k] < na) and (y[k] < na) then begin
          z:= z + x[k]*y[k]; inc(num);
      end;
  if num > 0 then z:= z/num else z:= bna;
End;
{---------------------------------------------------------------------------}
procedure Identity(var x,y:arrayofsingle; var z:extended; n:integer);
{sums of squares and cross products}
Var
  k: integer;
  sum: extended;
Begin
  sum:= 0; z:= 0;
  for k:= 1 to n do
    if (x[k] < na) and (y[k] < na) then begin
      z:= z + x[k]*y[k];
      sum:= sum + sqr(x[k]) + sqr(y[k]);
      end;
  if sum > 0 then z:= 2.0*z/sum else z:= bna;
End;
{---------------------------------------------------------------------------}
procedure CohenKappa(var x,y:arrayofsingle; var z:extended; n:integer);
{cohen's kappa measure of intercoder reliability}
Var
  k: integer;
  num,expagree,a,b,c,d,ae,be,ce,de,r1,r2,c1,c2: extended;
Begin
  a:= 0; b:= 0; c:= 0; d:= 0;
  ae:= 0; be:= 0; ce:= 0; de:= 0;
  for k:= 1 to n do
    if (x[k] < na) and (y[k] < na) then begin
      if x[k] > 0
        then if y[k] > 0
          then a:= a + 1
          else b:= b + 1
        else if y[k] > 0
          then c:= c + 1
          else d:= d + 1;
      end;
  r1:= a + b;
  r2:= c + d;
  c1:= a + c;
  c2:= b + d;
  num:= r1 + r2;
  if num < singleprecision then begin
    z:= bna;
    exit;
    end;
  ae:= r1*c1/num;
  be:= r1*c2/num;
  ce:= r2*c1/num;
  de:= r2*c2/num;
  expagree:= ae + de;
  if num > expagree
    then z:= (a+d - expagree)/(num - expagree)
    else z:= bna;
End;
{---------------------------------------------------------------------------}
procedure hammondsim(var x,y:arrayofsingle; var z:extended; n:integer);
{sums of squares and cross products}
Var
  k,num: integer;
Begin
  z:= 0; num:= 0;
  for k:= 1 to n do
    if (x[k] < na) and (y[k] < na) then begin
      z:= z + integer(x[k]=y[k]);
      inc(num);
      end;
  if num = 0 then z:= bna;
End;
{---------------------------------------------------------------------------}
procedure SSCP(var x,y:arrayofsingle; var z:extended; n:integer);
{sums of squares and cross products}
Var
  num,k: integer;
Begin
  num:= 0; z:= 0;
  for k:= 1 to n do
    if (x[k] < na) and (y[k] < na) then begin
      inc(num);
      if (not iszero(x[k])) and (not iszero(y[k]))
        then z:= z + x[k]*y[k];
    end;
//  if num > 0 then z:= n*z/num else z:= bna;
  if num = 0 then z:= bna;
End;
{---------------------------------------------------------------------------}
procedure SSCPmin(var x,y:arrayofsingle; var z:extended; n:integer);
{sums of squares and cross products, then divided by smaller of
 sum(x) or sum(y)}
Var
  num,k: integer;
  xsum,ysum,minsum: extended;
Begin
  num:= 0; z:= 0; xsum:= 0; ysum:= 0;
  for k:= 1 to n do
    if (x[k] < na) and (y[k] < na) then begin
      z:= z + x[k]*y[k]; inc(num);
      xsum:= xsum + x[k];
      ysum:= ysum + y[k];
      end;
  minsum:= min(xsum,ysum);
  if (num = 0) or iszero(minsum,singleprecision)
    then z:= bna
    else z:= z/minsum;
End;
{---------------------------------------------------------------------------}
procedure SumSqrDiff(var x,y:arrayofsingle; var z:extended; n:integer);
{square of euclidean distance}
Var
  num,k: integer;
Begin
  num:= 0; z:= 0;
  for k:= 1 to n do
    if (x[k] < na) and (y[k] < na) then begin
      z:= z + sqr(x[k] - y[k]);
      inc(num);
      end;
End;
{---------------------------------------------------------------------------}
procedure bonacich72(var x,y:arrayofsingle; var z:extended; n:integer);
{this is the method suggested by phil bonacich that adjusts for group sizes.
 the formula is described in this paper:
 Bonacich P. (1972) 'Techniques for analyzing overlapping memberships'
 Sociological Methodology 176-185 Jossey-Bass.}
var
  i,j: integer;
  xx,yy,n11,n12,n21,n22,n11n22,n12n21: extended;
begin
  sscp(x,y,n11,n);
  sscp(x,x,xx,n);
  sscp(y,y,yy,n);
  n12:= xx-n11;
  n21:= yy-n11;
  n22:= n - (n11+n12+n21);
  n11n22:= n11*n22;
  n12n21:= n12*n21;
  if (n11n22 < 0) or (n12n21 < 0) then begin z:= bna; exit; end;
  if feq(n11n22,n12n21)
    then z:= 0.5
    else z:= (n11n22-sqrt(n11n22*n12n21))/(n11n22-n12n21);
end;
{---------------------------------------------------------------------------}
procedure mcsscp(var x,y:arrayofsingle; var z:extended; n:integer);
Var
  dx,dy,mx,my,sxy,nxy: extended;
  k: integer;
Begin
  nxy:= 0; mx:= 0; my:= 0; sxy:= 0;
  for k:= 1 to n do
      if (x[k] < na) and (y[k] < na) then begin
          nxy:= nxy + 1;
          dx:= x[k] - mx; mx:= mx + dx/nxy;
          dy:= y[k] - my; my:= my + dy/nxy;
          sxy:= sxy + dx*(y[k]-my);
      end;
  if nxy < 1 then z:= bna else z:= n*sxy/nxy;
End;
{---------------------------------------------------------------------------}
procedure sumcrossmin(var x,y:arrayofsingle; var z:extended; n:integer);
{}
Var
  num,k: integer;
Begin
  num:= 0; z:= 0;
  for k:= 1 to n do
      if (x[k] < na) and (y[k] < na) then begin
        inc(num);
        z:= z + min(x[k],y[k]);
      end;
//  if num > 0 then z:= n*z/num else z:= bna;
  if num = 0 then z:= bna;
End;
{---------------------------------------------------------------------------}
procedure maxcrossmin(var x,y:arrayofsingle; var z:extended; n:integer);
{z = largest min(xi,yi)}
Var
  num,k: integer;
  minxy: double;
Begin
  num:= 0; z:= mindouble;
  for k:= 1 to n do
      if (x[k] < na) and (y[k] < na) then begin
        inc(num);
        minxy:= min(x[k],y[k]);
        if minxy > z then z:= minxy;
      end;
//  if num > 0 then z:= n*z/num else z:= bna;
  if num = 0 then z:= bna;
End;
{---------------------------------------------------------------------------}
procedure Covariance(var x,y:arrayofsingle; var z:extended; n:integer);
Var
  dx,dy,mx,my,sxy,nxy: extended;
  k: integer;
Begin
  nxy:= 0; mx:= 0; my:= 0; sxy:= 0;
  for k:= 1 to n do
      if (x[k] < na) and (y[k] < na) then begin
          nxy:= nxy + 1;
          dx:= x[k] - mx; mx:= mx + dx/nxy;
          dy:= y[k] - my; my:= my + dy/nxy;
          sxy:= sxy + dx*(y[k]-my);
      end;
  if nxy < 1 then z:= bna else z:= sxy;
End;
{---------------------------------------------------------------------------}
procedure Correlation(var x,y:arrayofsingle; var z:extended; n:integer);
Var
  dx,dy,mx,my,sx,sy,sxy,nxy: extended;
  k: integer;
Begin
  nxy:= 0; mx:= 0; sx:= 0; my:= 0; sy:= 0; sxy:= 0;
  for k:= 1 to n do
      if (x[k] < na) and (y[k] < na) then begin
          nxy:= nxy + 1;
          dx:= x[k] - mx; mx:= mx + dx/nxy;
          sx:= sx + (x[k]-mx)*dx;
          dy:= y[k] - my; my:= my + dy/nxy;
          sy:= sy + (y[k]-my)*dy;
          sxy:= sxy + dx*(y[k]-my);
      end;
      if nxy < 1 then
          z:= bna
      else
          if (sx < singleprecision) xor (sy < singleprecision) then
              z:= 0
          else
              if (sx < singleprecision) and (sy < singleprecision) then
                  z:= 1
              else
                  z:= sxy/sqrt(sx*sy);
End;
{---------------------------------------------------------------------------}
procedure cosine(var x,y:arrayofsingle; var z:extended; n:integer);
{cosine similarity (congruence coefficient): sum(xi*yi)/sqrt(sum(xi^2)*sum(yi^2))}
var
  num,k: integer;
  sxy,sx,sy: extended;
begin
  num:= 0; sxy:= 0; sx:= 0; sy:= 0;
  for k:= 1 to n do
    if (x[k] < na) and (y[k] < na) then begin
      inc(num);
      sxy:= sxy + x[k]*y[k];
      sx:= sx + x[k]*x[k];
      sy:= sy + y[k]*y[k];
      end;
  if num = 0 then
    z:= bna
  else
    if (sx < singleprecision) xor (sy < singleprecision) then
      z:= 0
    else
      if (sx < singleprecision) and (sy < singleprecision) then
        z:= 1
      else
        z:= sxy/sqrt(sx*sy);
end;
{---------------------------------------------------------------------------}
function runCovCorr(x,y:tsvec; m,n:smallint): extended;
{m = 0 for mean-corrected sscp, m = 1 for covariance, m = 2 for correlation}
Var
  dx,dy,mx,my,sx,sy,sxy,nxy: extended;
  k: integer;
Begin
  nxy:= 0; mx:= 0; sx:= 0; my:= 0; sy:= 0; sxy:= 0;
  for k:= 1 to n do
      if (x[k] < na) and (y[k] < na) then begin
          nxy:= nxy + 1;
          dx:= x[k] - mx; mx:= mx + dx/nxy; sx:= sx + (x[k]-mx)*dx;
          dy:= y[k] - my; my:= my + dy/nxy; sy:= sy + (y[k]-my)*dy;
          sxy:= sxy + dx*(y[k]-my);
      end;
  if m = 0 then
      runcovcorr:= sxy
  else
      if nxy < 1 then
          runcovcorr:= bna
      else
          if m = 1 then
              runcovcorr:= sxy/n
          else
              if (sx < singleprecision) xor (sy < singleprecision) then
                  runcovcorr:= 0
              else
                  if sx*sy < singleprecision then
                      runcovcorr:= 1
                  else
                      runcovcorr:= sxy/sqrt(sx*sy);
End;
{---------------------------------------------------------------------------}
procedure matchrows(r:tsmat; d:tsmat; guessing:single=bna);
label cleanup;
var
  i,j,k,m: integer;
  x,num: extended;
begin
  error:= 0;
  if not r.hasval
    then if not r.allocsize(d.nr,d.nr) then goto cleanup;
  r.rdvn.copy(d.rdvn); r.cdvn.copy(d.rdvn);
  r.title:= 'Matches among rows';
  for i:= 2 to d.nr do for j:= 1 to i-1 do begin
    x:= 0; num:= 0;
    for k:= 1 to d.nc do
      if (d[i,k] < na) and (d[j,k] < na) then begin
        if feq(d[i,k],d[j,k]) then x:= x + 1.0;
        num:= num + 1.0;
        end;
    if num > 0
      then if guessing < na
        then r[i,j]:= (guessing*x/num - 1.0)/(guessing-1.0)
        else r[i,j]:= x/num
      else r[i,j]:= bna;
    r[j,i]:= r[i,j];
    end;
  for i:= 1 to d.nr do r[i,i]:= 1;
  cleanup:
end;
{---------------------------------------------------------------------------}
procedure matchmatrices(r:tsmat; x:tsmat3; typeofdata:integer=4; guessing:single=bna);
label cleanup;
var
  i,j,matches,num: integer;

  procedure run2; {symmetric}
  var
    k,m: integer;
  begin
    for k:= 2 to x.nr do for m:= 1 to k-1 do
      if (x.cell[i,k,m] < na) and (x.cell[j,k,m] < na)
        then begin
          inc(num);
          if feq(x.cell[i,k,m],x.cell[j,k,m]) then inc(matches);
          end;
  end;

  procedure run3; {nonsymmetric square, diagonal absent}
  var
    k,m: integer;
  begin
    for k:= 1 to x.nr do for m:= 1 to x.nc do if k <> m then
      if (x.cell[i,k,m] < na) and (x.cell[j,k,m] < na)
        then begin
          inc(num);
          if feq(x.cell[i,k,m],x.cell[j,k,m]) then inc(matches);
          end;
  end;

  procedure run4; {rectangular, diagonal present}
  var
    k,m: integer;
  begin
    for k:= 1 to x.nr do for m:= 1 to x.nc do
      if (x.cell[i,k,m] < na) and (x.cell[j,k,m] < na)
        then begin
          inc(num);
          if feq(x.cell[i,k,m],x.cell[j,k,m]) then inc(matches);
          end;
  end;

begin
  if not r.hasval
    then if not r.allocsize(x.nm,x.nm) then goto cleanup;
  r.rdvn.copy(x.mdvn); r.cdvn.copy(x.mdvn);
  r.title:= 'Matches among matrices';
  for i:= 2 to x.nm do
    for j:= 1 to i-1 do begin
      matches:= 0; num:= 0;
      case typeofdata of
        2: run2;
        3: run3;
        4: run4;
        end;
      if num > 0
        then if guessing < na
          then r[i,j]:= (guessing*matches/num - 1.0)/(guessing-1.0)
          else r[i,j]:= matches
        else r[i,j]:= bna;
      r[j,i]:= r[i,j];
      end;
  for i:= 1 to x.nm do r[i,i]:= 1.0;
  cleanup:
end;
{---------------------------------------------------------------------------}
procedure sesim2(r:tsmat; d:tsmat3; simdis:simdisfunc;
  transp,usedist:boolean; method:smallint);
label cleanup;
var
  err,nrel,n,m,i,j,k: integer;
  nn: longint;
  x,y: tsvec;
  z: extended;
  nmiss: longint;
  ten: integer;

  procedure buildignore(i,j:integer);
  var
    m,k,mk: integer;
  begin
    mk:= 0;
    for m:= 1 to nrel do begin
      for k:= 1 to n do if (k<>i) and (k<>j) then begin
        inc(mk);
        x[mk]:= d.cell[m][i][k];
        y[mk]:= d.cell[m][j][k];
        end;
      if transp then for k:= 1 to n do if (k<>i) and (k<>j) then begin
        inc(mk);
        x[mk]:= d.cell[m][k][i];
        y[mk]:= d.cell[m][k][j];
        end;
      end;
    n:= mk; y.n:= mk;
  end;

  procedure buildcountsingle(i,j:integer);
  var
    m,k,mk: integer;
  begin
    mk:= 0;
    for m:= 1 to nrel do begin
      for k:= 1 to n do begin
        inc(mk);
        x[mk]:= d.cell[m][i][k];
        y[mk]:= d.cell[m][j][k];
        end;
      if transp then for k:= 1 to n do if (k<>i) and (k<>j) then begin
        inc(mk);
        x[mk]:= d.cell[m][k][i];
        y[mk]:= d.cell[m][k][j];
        end;
      end;
    n:= mk; y.n:= mk;
  end;

  procedure buildcountdouble(i,j:integer);
  var
    m,k,mk: integer;
  begin
    mk:= 0;
    for m:= 1 to nrel do begin
      for k:= 1 to n do begin
        inc(mk);
        x[mk]:= d.cell[m][i][k];
        y[mk]:= d.cell[m][j][k];
        end;
      for k:= 1 to n do begin
        inc(mk);
        x[mk]:= d.cell[m][k][i];
        y[mk]:= d.cell[m][k][j];
        end;
      end;
    n:= mk; y.n:= mk;
  end;

  procedure buildreciprocalsingle(i,j:integer);
  var
    m,k,mk: integer;
  begin
    mk:= 0;
    for m:= 1 to nrel do begin
      for k:= 1 to n do begin
        inc(mk);
        if k = i
          then begin
            x[mk]:= d.cell[m][i][i];
            y[mk]:= d.cell[m][j][j];
            end
          else if k = j
            then begin
              x[mk]:= d.cell[m][i][j];
              y[mk]:= d.cell[m][j][i];
              end
            else begin
              x[mk]:= d.cell[m][i][k];
              y[mk]:= d.cell[m][j][k];
              end;
        end;
      if transp then for k:= 1 to n do if (k<>i) and (k<>j) then begin
        inc(mk);
        x[mk]:= d.cell[m][k][i];
        y[mk]:= d.cell[m][k][j];
        end;
      end;
    n:= mk; y.n:= mk;
  end;

  procedure buildreciprocaldouble(i,j:integer);
  var
    m,k,mk: integer;
  begin
    mk:= 0;
    for m:= 1 to nrel do begin
      for k:= 1 to n do begin
        inc(mk);
        if k = i
          then begin
            x[mk]:= d.cell[m][i][i];
            y[mk]:= d.cell[m][j][j];
            end
          else if k = j
            then begin
              x[mk]:= d.cell[m][i][j];
              y[mk]:= d.cell[m][j][i];
              end
            else begin
              x[mk]:= d.cell[m][i][k];
              y[mk]:= d.cell[m][j][k];
              end;
        end;
      for k:= 1 to n do begin
        inc(mk);
        if k = i
          then begin
            x[mk]:= d.cell[m][i][i];
            y[mk]:= d.cell[m][j][j];
            end
          else if k = j
            then begin
              x[mk]:= d.cell[m][j][i];
              y[mk]:= d.cell[m][i][j];
              end
            else begin
              x[mk]:= d.cell[m][k][i];
              y[mk]:= d.cell[m][k][j];
               end;
        end;
      end;
    n:= mk; y.n:= mk;
  end;

  procedure runfloyd(rel:integer);
  Label cleanup;
  Var
    s: single;
    i,j,k: integer;
  Begin
    for i:= 1 to d.n do d.cell[rel,i,i]:= 0;
    for i:= 1 to d.n do begin
      for j:= 1 to d.n do
        if d.cell[rel,j,i] > 0 then
          for k:= 1 to d.n do
            if (d.cell[rel,i,k] > 0) then begin
              s:= d.cell[rel,j,i] + d.cell[rel,i,k];
              if (d.cell[rel,j,k] = 0) or (s < d.cell[rel,j,k]) then
                d.cell[rel,j,k]:= s;
              end;
      end;
    for i:= 1 to d.n do
      for j:= 1 to d.n do if i = j
        then d.cell[rel,i,j]:= 0
        else if d.cell[rel,i,j] = 0
          then d.cell[rel,i,j]:= d.n;
  cleanup:
  End;

begin
  nrel:= d.nm;
  n:= d.n;
  x:= tsvec.create;
  y:= tsvec.create;
  if usedist then
    for m:= 1 to nrel do
      runfloyd(m);
  nn:= longint(n)*nrel;
  if transp then nn:= longint(nn)*2;
  if not x.allocsize(nn) then goto cleanup;
  if not y.allocsize(nn) then  goto cleanup;
  if not r.allocsize(n,n) then goto cleanup;
  ten:= n div 10;
  for i:= 1 to n do
    for j:= 1 to i do begin
      case method of
        ignore:  buildignore(i,j);
        retain1,retain: buildcountsingle(i,j);
        retain2: buildcountdouble(i,j);
        recip1,recip:  buildreciprocalsingle(i,j);
        recip2:  buildreciprocaldouble(i,j);
        end;
      simdis(x.cell,y.cell,z,n);
      r[i,j]:= z;
      r[j,i]:= z;
      end;
cleanup:
  y.free; x.free;
end;
{---------------------------------------------------------------------------}
procedure getcorrcovamongmatrices(r:tsmat; x:tsmat3; corr:boolean=true; typeofdata:integer=4; pi:extended=0.5);
label cleanup;
var
  i,j,k,m: integer;
  pivar: double;
  s: bestimator;
begin
  s:= bestimator.create;
  if not r.hasval
    then if not r.allocsize(x.nm,x.nm) then goto cleanup;
  r.rdvn.copy(x.mdvn); r.cdvn.copy(x.mdvn);
  pivar:= pi*(1.0-pi);
  for i:= 2 to x.nm do
    for j:= 1 to i-1 do begin
      s.clear;
      case typeofdata of
        2: for k:= 2 to x.nr do for m:= 1 to k-1 do
             s.addcase(x.cell[i,k,m],x.cell[j,k,m]);
        3: for k:= 1 to x.nr do for m:= 1 to x.nc do if k <> m then
             s.addcase(x.cell[i,k,m],x.cell[j,k,m]);
        4: for k:= 1 to x.nr do for m:= 1 to x.nc do
             s.addcase(x.cell[i,k,m],x.cell[j,k,m]);
        end;
      s.calc;
      if corr
        then r[i,j]:= s.corr
        else r[i,j]:= s.cov/pivar;
      r[j,i]:= r[i,j];
      end;
  for i:= 1 to r.nr do r[i,i]:= 1.0;
  cleanup:
    s.free;
end;
{------------------------------------------------------------------------------}
procedure getcorrcovamongrows(r:tsmat; x:tsmat; corr:boolean=true; pi:extended=0.5);
label cleanup;
var
  i,j,k,m: integer;
  pivar,cov,sx,sy,dx,dy,mx,my,n: extended;

  procedure clear;
  begin
    sx:= 0; sy:= 0; mx:= 0; my:= 0; n:= 0; cov:= 0;
  end;

  procedure calc;
  begin
    if n < 2
      then r[i,j]:= bna
      else begin
        sx:= sqrt(sx/n); sy:= sqrt(sy/n);
        if (sx < singleprecision) or (sy < singleprecision)
          then r[i,j]:= bna
          else if corr
            then r[i,j]:= cov/(n*sx*sy)
            else begin
              cov:= cov;
              if pivar > 0
                then r[i,j]:= cov/((n-1)*pivar)
                else r[i,j]:= cov/(n-1);
              end;
        end;
  end;

begin
  error:= 0;
  if not r.hasval
    then if not r.allocsize(x.nr,x.nr) then goto cleanup;
  r.rdvn.copy(x.rdvn); r.cdvn.copy(x.rdvn);
  pivar:= pi*(1.0-pi);
  for i:= 2 to x.nr do
    for j:= 1 to i-1 do begin
      clear;
      for k:= 1 to x.nc do if (x[i,k] < na) and (x[j,k] < na) then begin
        n:= n + 1.0;
        dx:= x[i,k] - mx; mx:= mx + dx/n; sx:= sx + (x[i,k]-mx)*dx;
        dy:= x[j,k] - my; my:= my + dy/n; sy:= sy + (x[j,k]-my)*dy;
        cov:= cov + dx*(x[j,k]-my);
        end;
      calc;
      r[j,i]:= r[i,j];
      end;
  for i:= 1 to r.nr do r.cell[i][i]:= 1.0;
  cleanup:
end;
{------------------------------------------------------------------------------}
End.
