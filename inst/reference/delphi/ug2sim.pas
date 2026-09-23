Unit ug2sim;

Interface
Uses
    math, ucommon,utevec,utsmat,umsg,ugeodist,ukey,umath, utsvec, 
    utivec, utsmat3, ustats;
type
  simfunc = function(x,y:tevec; var z:extended): boolean;
{func}
Function AVGSSCP(x,y:tevec; var z:extended): boolean;
Function CohenKappa(x,y:tevec; var z:extended): boolean;
Function Correlation(x,y:tevec; var z:extended): boolean;
Function Covariance(x,y:tevec; var z:extended): boolean;
Function Coverage(x,y:tevec; var z:extended): boolean;
Function euclid(x,y:tevec; var z:extended): boolean;
Function GeneralizedJaccard(x,y:tevec; var z:extended): boolean;
function getcorrcovamongmatrices(r:tsmat; x:tsmat3; corr:boolean=true; typeofdata:integer=4; pi:extended=0.5): boolean;
function getcorrcovamongrows(r:tsmat; x:tsmat; corr:boolean=true; pi:extended=0.5): boolean;
Function hammondsim(x,y:tevec; var z:extended): boolean;
Function Identity(x,y:tevec; var z:extended): boolean;
Function manhattan(x,y:tevec; var z:extended): boolean;
Function Matches(x,y:tevec; var z:extended): boolean;
function matchmatrices(r:tsmat; x:tsmat3; typeofdata:integer=4; guessing:single=bna): boolean;
function matchrows(r:tsmat; d:tsmat; guessing:single=bna): boolean;
Function mcSSCP(x,y:tevec; var z:extended): boolean;
function methstr(m:integer): string;
Function nonMatches(x,y:tevec; var z:extended): boolean;
Function nssd(x,y:tevec; var z:extended): boolean;
Function Overlaps(x,y:tevec; var z:extended): boolean;
Function PosMatches(x,y:tevec; var z:extended): boolean;
Function PosnonMatches(x,y:tevec; var z:extended): boolean;
function sesim2(r:tsmat; d:tsmat3; simdis:simfunc; sym,transp,usedist:boolean; method:smallint): boolean;
Function SSCP(x,y:tevec; var z:extended): boolean;
function wmeth(s:string): integer;

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
Function Matches(x,y:tevec; var z:extended): boolean;
var
  num,k: integer;
begin
  num:= 0; z:= 0;
  for k:= 1 to x.n do
    if (x.cell[k] < na) and (y.cell[k] < na) then begin
      z:= z + integer(samevalue(x.cell[k],y.cell[k]));
      inc(num);
      end;
  if num > 0 then z:= z/num else z:= bna;
  result:= z <> bna;
end;
{---------------------------------------------------------------------------}
Function Overlaps(x,y:tevec; var z:extended): boolean;
var
  num,k: integer;
begin
  num:= 0; z:= 0;
  for k:= 1 to x.n do
    if (x.cell[k] < na) and (y.cell[k] < na) then begin
      if (x.cell[k] > 0) and (y.cell[k] > 0) then
        z:= z + 1;
      inc(num);
      end;
  if num > 0 then z:= z/num else z:= bna;
  result:= z <> bna;
end;
{---------------------------------------------------------------------------}
Function Coverage(x,y:tevec; var z:extended): boolean;
//x covers y to the extent of all of y's 1s are in x
var
  num,denom,k: integer;
begin
  num:= 0; denom:= 0;
  for k:= 1 to x.n do
    if (x.cell[k] < na) and (y.cell[k] < na) then
      if y.cell[k] > 0 then begin
        inc(denom);
        if (x.cell[k] > 0) then inc(num);
        end;
  if denom > 0 then z:= 1.0*num/denom else z:= bna;
  result:= z < na;
end;
{---------------------------------------------------------------------------}
Function PosMatches(x,y:tevec; var z:extended): boolean;
Var
  num,k,iz: integer;
Begin
  num:= 0; iz:= 0;
  for k:= 1 to x.n do
      if (x.cell[k] < na) and (y.cell[k] < na) then
          if (x.cell[k] > 0) or (y.cell[k] > 0) then begin
              inc(num);
              if (x.cell[k] > 0) and (y.cell[k] > 0) then inc(iZ);
          end;
  if num > 0
    then begin
      z:= 1.0*iz/num; result:= true; end
    else
      begin z:= bna; result:= false;
  end;
End;
{---------------------------------------------------------------------------}
Function GeneralizedJaccard(x,y:tevec; var z:extended): boolean;
Var
  k: integer;
  numer,denom: double;
Begin
  numer:= 0; denom:= 0;
  for k:= 1 to x.n do
    if (x.cell[k] < na) and (y.cell[k] < na) then begin
      numer:= numer + min(x.cell[k],y.cell[k]);
      denom:= denom + max(x.cell[k],y.cell[k]);
      end;
  if denom > 0
    then begin z:= numer/denom; result:= true; end
    else begin z:= bna; result:= false; end;
End;
{---------------------------------------------------------------------------}
Function nonmatches(x,y:tevec; var z:extended): boolean;
Begin
  nonmatches:= matches(x,y,z);
  if z < na then z:= 1.0 - z;
End;
{---------------------------------------------------------------------------}
Function posnonmatches(x,y:tevec; var z:extended): boolean;
Begin
  posnonmatches:= posmatches(x,y,z);
  if z < na then z:= 1.0 - z;
End;
{---------------------------------------------------------------------------}
Function euclid(x,y:tevec; var z:extended): boolean;
{euclidean distance}
Var
  num,k: integer;
Begin
  num:= 0; z:= 0;
  for k:= 1 to x.n do
      if (x.cell[k] < na) and (y.cell[k] < na) then begin
          z:= z + sqr(x.cell[k]-y.cell[k]); inc(num);
      end;
  if num > 0 then z:= x.n*sqrt(z)/num else z:= bna;
  if z = bna then euclid:= false else euclid:= true;
End;
{---------------------------------------------------------------------------}
Function manhattan(x,y:tevec; var z:extended): boolean;
{city block distance}
Var
  num,k: integer;
Begin
  num:= 0; z:= 0;
  for k:= 1 to x.n do
      if (x.cell[k] < na) and (y.cell[k] < na) then begin
          z:= z + abs(x.cell[k]-y.cell[k]); inc(num);
      end;
      if num > 0 then z:= x.n*z/num else z:= bna;
      if z = bna then manhattan:= false else manhattan:= true;
End;
{---------------------------------------------------------------------------}
Function nssd(x,y:tevec; var z:extended): boolean;
{normed sum of squared differences}
Var
  k: integer;
  xsq,ysq: extended;
Begin
  z:= 0; xsq:= 0; ysq:= 0;
  for k:= 1 to x.n do
      if (x.cell[k] < na) and (y.cell[k] < na) then begin
         z:= z + sqr(x.cell[k]-y.cell[k]);
         xsq:= xsq + sqr(x.cell[k]); ysq:= ysq + sqr(y.cell[k]);
      end;
  if (xsq > 0) and (ysq > 0) then z:= z/(xsq*ysq) else z:= bna;
  if z = bna then nssd:= false else nssd:= true;
End;
{---------------------------------------------------------------------------}
Function AVGSSCP(x,y:tevec; var z:extended): boolean;
{ avg sums of squares and cross products}
Var
  num,k: integer;
Begin
  num:= 0; z:= 0;
  for k:= 1 to x.n do
      if (x.cell[k] < na) and (y.cell[k] < na) then begin
          z:= z + x.cell[k]*y.cell[k]; inc(num);
      end;
  if num > 0 then z:= z/num else z:= bna;
  if z = bna then result:= false else result:= true;
End;
{---------------------------------------------------------------------------}
Function Identity(x,y:tevec; var z:extended): boolean;
{sums of squares and cross products}
Var
  k: integer;
  sum: extended;
Begin
  sum:= 0; z:= 0;
  for k:= 1 to x.n do
    if (x.cell[k] < na) and (y.cell[k] < na) then begin
      z:= z + x.cell[k]*y.cell[k];
      sum:= sum + sqr(x.cell[k]) + sqr(y.cell[k]);
      end;
  if sum > 0 then z:= 2.0*z/sum else z:= bna;
  if z = bna then result:= false else result:= true;
End;
{---------------------------------------------------------------------------}
Function CohenKappa(x,y:tevec; var z:extended): boolean;
{cohen's kappa measure of intercoder reliability}
Var
  k: integer;
  n,expagree,a,b,c,d,ae,be,ce,de,r1,r2,c1,c2: extended;
Begin
  a:= 0; b:= 0; c:= 0; d:= 0;
  ae:= 0; be:= 0; ce:= 0; de:= 0;
  for k:= 1 to x.n do
    if (x.cell[k] < na) and (y.cell[k] < na) then begin
      if x.cell[k] > 0
        then if y.cell[k] > 0
          then a:= a + 1
          else b:= b + 1
        else if y.cell[k] > 0
          then c:= c + 1
          else d:= d + 1;
      end;
  r1:= a + b;
  r2:= c + d;
  c1:= a + c;
  c2:= b + d;
  n:= r1 + r2;
  if n < singleprecision then begin
    result:= false;
    z:= bna;
    exit;
    end;
  ae:= r1*c1/n;
  be:= r1*c2/n;
  ce:= r2*c1/n;
  de:= r2*c2/n;
  expagree:= ae + de;
  if n > expagree
    then z:= (a+d - expagree)/(n - expagree)
    else z:= bna;
  if z = bna then result:= false else result:= true;
End;
{---------------------------------------------------------------------------}
Function hammondsim(x,y:tevec; var z:extended): boolean;
{sums of squares and cross products}
Var
  k,num: integer;
Begin
  z:= 0; num:= 0;
  for k:= 1 to x.n do
    if (x.cell[k] < na) and (y.cell[k] < na) then begin
      z:= z + integer(x.cell[k]=y.cell[k]);
      inc(num);
      end;
  if num = 0 then begin z:= bna; result:= false; end
  else result:= true;
End;
{---------------------------------------------------------------------------}
Function SSCP(x,y:tevec; var z:extended): boolean;
{sums of squares and cross products}
Var
  num,k: integer;
Begin
  num:= 0; z:= 0;
  for k:= 1 to x.n do
      if (x.cell[k] < na) and (y.cell[k] < na) then begin
          z:= z + x.cell[k]*y.cell[k]; inc(num);
      end;
//  if num > 0 then z:= x.n*z/num else z:= bna;
  if num = 0 then z:= bna;
  if z = bna then sscp:= false else sscp:= true;
End;
{---------------------------------------------------------------------------}
Function mcsscp(x,y:tevec; var z:extended): boolean;
Var
  dx,dy,mx,my,sxy,nxy: extended;
  k: integer;
Begin
  nxy:= 0; mx:= 0; my:= 0; sxy:= 0;
  for k:= 1 to x.n do
      if (x.cell[k] < na) and (y.cell[k] < na) then begin
          nxy:= nxy + 1;
          dx:= x.cell[k] - mx; mx:= mx + dx/nxy;
          dy:= y.cell[k] - my; my:= my + dy/nxy;
          sxy:= sxy + dx*(y.cell[k]-my);
      end;
  if nxy < 1 then z:= bna else z:= x.n*sxy/nxy;
  if z = bna then mcsscp:= false else mcsscp:= true;
End;
{---------------------------------------------------------------------------}
Function Covariance(x,y:tevec; var z:extended): boolean;
Var
  dx,dy,mx,my,sxy,nxy: extended;
  k: integer;
Begin
  nxy:= 0; mx:= 0; my:= 0; sxy:= 0;
  for k:= 1 to x.n do
      if (x.cell[k] < na) and (y.cell[k] < na) then begin
          nxy:= nxy + 1;
          dx:= x.cell[k] - mx; mx:= mx + dx/nxy;
          dy:= y.cell[k] - my; my:= my + dy/nxy;
          sxy:= sxy + dx*(y.cell[k]-my);
      end;
  if nxy < 1 then z:= bna else z:= sxy;
  if z = bna then covariance:= false else covariance:= true;
End;
{---------------------------------------------------------------------------}
Function Correlation(x,y:tevec; var z:extended): boolean;
Var
  dx,dy,mx,my,sx,sy,sxy,nxy: extended;
  k: integer;
Begin
  nxy:= 0; mx:= 0; sx:= 0; my:= 0; sy:= 0; sxy:= 0;
  for k:= 1 to x.n do
      if (x.cell[k] < na) and (y.cell[k] < na) then begin
          nxy:= nxy + 1;
          dx:= x.cell[k] - mx; mx:= mx + dx/nxy;
          sx:= sx + (x.cell[k]-mx)*dx;
          dy:= y.cell[k] - my; my:= my + dy/nxy;
          sy:= sy + (y.cell[k]-my)*dy;
          sxy:= sxy + dx*(y.cell[k]-my);
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
  if z = bna then correlation:= false else correlation:= true;
End;
{---------------------------------------------------------------------------}
Function runCovCorr(x,y:tsvec; m,n:smallint): extended;
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
function matchrows(r:tsmat; d:tsmat; guessing:single=bna): boolean;
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
      if (d.cell[i,k] < na) and (d.cell[j,k] < na) then begin
        if feq(d.cell[i,k],d.cell[j,k]) then x:= x + 1.0;
        num:= num + 1.0;
        end;
    if num > 0
      then if guessing < na
        then r.cell[i,j]:= (guessing*x/num - 1.0)/(guessing-1.0)
        else r.cell[i,j]:= x/num
      else r.cell[i,j]:= bna;
    r.cell[j,i]:= r.cell[i,j];
    end;
  for i:= 1 to d.nr do r.cell[i,i]:= 1;
  cleanup:
    result:= error = 0;
end;
{---------------------------------------------------------------------------}
function matchmatrices(r:tsmat; x:tsmat3; typeofdata:integer=4; guessing:single=bna): boolean;
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
          then r.cell[i,j]:= (guessing*matches/num - 1.0)/(guessing-1.0)
          else r.cell[i,j]:= matches
        else r.cell[i,j]:= bna;
      r.cell[j,i]:= r.cell[i,j];
      end;
  for i:= 1 to x.nm do r.cell[i,i]:= 1.0;
  cleanup:
    result:= error = 0;
end;
{---------------------------------------------------------------------------}
function sesim2(r:tsmat; d:tsmat3; simdis:simfunc;
  sym,transp,usedist:boolean; method:smallint): boolean;
//sym here refers to whether the simfunc delivers a symmetric measure of similarity
label cleanup;
var
  err,nrel,n,m,i,j,k,top: integer;
  nn: longint;
  x,y: tevec;
  z: extended;
  nmiss: longint;
  id: boolean;
  ten: integer;

  procedure buildignore(i,j:integer);
  var
    m,k,mk: integer;
  begin
    mk:= 0;
    for m:= 1 to nrel do begin
      for k:= 1 to n do if (k<>i) and (k<>j) then begin
        inc(mk);
        x.cell[mk]:= d.cell[m][i][k];
        y.cell[mk]:= d.cell[m][j][k];
        end;
      if transp then for k:= 1 to n do if (k<>i) and (k<>j) then begin
        inc(mk);
        x.cell[mk]:= d.cell[m][k][i];
        y.cell[mk]:= d.cell[m][k][j];
        end;
      end;
    x.n:= mk; y.n:= mk;
  end;

  procedure buildcountsingle(i,j:integer);
  var
    m,k,mk: integer;
  begin
    mk:= 0;
    for m:= 1 to nrel do begin
      for k:= 1 to n do begin
        inc(mk);
        x.cell[mk]:= d.cell[m][i][k];
        y.cell[mk]:= d.cell[m][j][k];
        end;
      if transp then for k:= 1 to n do if (k<>i) and (k<>j) then begin
        inc(mk);
        x.cell[mk]:= d.cell[m][k][i];
        y.cell[mk]:= d.cell[m][k][j];
        end;
      end;
    x.n:= mk; y.n:= mk;
  end;

  procedure buildcountdouble(i,j:integer);
  var
    m,k,mk: integer;
  begin
    mk:= 0;
    for m:= 1 to nrel do begin
      for k:= 1 to n do begin
        inc(mk);
        x.cell[mk]:= d.cell[m][i][k];
        y.cell[mk]:= d.cell[m][j][k];
        end;
      for k:= 1 to n do begin
        inc(mk);
        x.cell[mk]:= d.cell[m][k][i];
        y.cell[mk]:= d.cell[m][k][j];
        end;
      end;
    x.n:= mk; y.n:= mk;
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
            x.cell[mk]:= d.cell[m][i][i];
            y.cell[mk]:= d.cell[m][j][j];
            end
          else if k = j
            then begin
              x.cell[mk]:= d.cell[m][i][j];
              y.cell[mk]:= d.cell[m][j][i];
              end
            else begin
              x.cell[mk]:= d.cell[m][i][k];
              y.cell[mk]:= d.cell[m][j][k];
              end;
        end;
      if transp then for k:= 1 to n do if (k<>i) and (k<>j) then begin
        inc(mk);
        x.cell[mk]:= d.cell[m][k][i];
        y.cell[mk]:= d.cell[m][k][j];
        end;
      end;
    x.n:= mk; y.n:= mk;
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
            x.cell[mk]:= d.cell[m][i][i];
            y.cell[mk]:= d.cell[m][j][j];
            end
          else if k = j
            then begin
              x.cell[mk]:= d.cell[m][i][j];
              y.cell[mk]:= d.cell[m][j][i];
              end
            else begin
              x.cell[mk]:= d.cell[m][i][k];
              y.cell[mk]:= d.cell[m][j][k];
              end;
        end;
      for k:= 1 to n do begin
        inc(mk);
        if k = i
          then begin
            x.cell[mk]:= d.cell[m][i][i];
            y.cell[mk]:= d.cell[m][j][j];
            end
          else if k = j
            then begin
              x.cell[mk]:= d.cell[m][j][i];
              y.cell[mk]:= d.cell[m][i][j];
              end
            else begin
              x.cell[mk]:= d.cell[m][k][i];
              y.cell[mk]:= d.cell[m][k][j];
               end;
        end;
      end;
    x.n:= mk; y.n:= mk;
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
  x:= tevec.create;
  y:= tevec.create;
  if usedist then
    for m:= 1 to nrel do
      runfloyd(m);
  nn:= longint(n)*nrel;
  if transp then nn:= longint(nn)*2;
  if not x.allocsize(nn) then goto cleanup;
  if not y.allocsize(nn) then  goto cleanup;
  if not r.allocsize(n,n) then goto cleanup;
  ten:= n div 10;
  for i:= 1 to n do begin
    if sym then top:= i else top:= n;
    for j:= 1 to top do begin
      case method of
        ignore:  buildignore(i,j);
        retain1,retain: buildcountsingle(i,j);
        retain2: buildcountdouble(i,j);
        recip1,recip:  buildreciprocalsingle(i,j);
        recip2:  buildreciprocaldouble(i,j);
        end;
      simdis(x,y,z);
      r.cell[i][j]:= z;
      if sym then r.cell[j][i]:= z;
      end;
    end;
cleanup:
  y.free; x.free;
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
function getcorrcovamongmatrices(r:tsmat; x:tsmat3; corr:boolean=true; typeofdata:integer=4; pi:extended=0.5): boolean;
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
        then r.cell[i,j]:= s.corr
        else r.cell[i,j]:= s.cov/pivar;
      r.cell[j,i]:= r.cell[i,j];
      end;
  for i:= 1 to r.nr do r.cell[i,i]:= 1.0;
  cleanup:
    s.free;
    result:= error = 0;
end;
{------------------------------------------------------------------------------}
function getcorrcovamongrows(r:tsmat; x:tsmat; corr:boolean=true; pi:extended=0.5): boolean;
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
      then r.cell[i,j]:= bna
      else begin
        sx:= sqrt(sx/n); sy:= sqrt(sy/n);
        if (sx < singleprecision) or (sy < singleprecision)
          then r.cell[i,j]:= bna
          else if corr
            then r.cell[i,j]:= cov/(n*sx*sy)
            else begin
              cov:= cov;
              if pivar > 0
                then r.cell[i,j]:= cov/((n-1)*pivar)
                else r.cell[i,j]:= cov/(n-1);
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
      for k:= 1 to x.nc do if (x.cell[i,k] < na) and (x.cell[j,k] < na) then begin
        n:= n + 1.0;
        dx:= x.cell[i,k] - mx; mx:= mx + dx/n; sx:= sx + (x.cell[i,k]-mx)*dx;
        dy:= x.cell[j,k] - my; my:= my + dy/n; sy:= sy + (x.cell[j,k]-my)*dy;
        cov:= cov + dx*(x.cell[j,k]-my);
        end;
      calc;
      r.cell[j,i]:= r.cell[i,j];
      end;
  for i:= 1 to r.nr do r.cell[i][i]:= 1.0;
  cleanup:
    result:= error = 0;
end;
{------------------------------------------------------------------------------}
End.
