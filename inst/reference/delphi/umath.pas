Unit UMath;
Interface
uses
  sysutils, math,
  ucommon,ugeneral;
const
  Epsilon = 1E-06;
  goldenratio = 1.6180339887498948482;
  magicnumber = 1.0 - 1/goldenratio;  //around 0.381966011

  function binaryval(x:extended): byte;
  function BooleanEval(x:extended; op:integer; val:extended): boolean;
  function clocksum(x,y:integer; n:integer=12): integer;
  function comparevals(a:extended; op:tdichop; b:extended): boolean; overload;
  function comparevals(a:integer; op:tdichop; b:integer): boolean; overload;
  function density2ties(den:single; n:integer; dir:char='d'): single;
  function different(a,b:extended; crit:extended=0.00001): boolean;
  function fabsdiff(a,b: extended): extended;
  function factorial(n:integer): int64;
  function favg(a,b:extended): extended;
  function fdiff(a,b: extended): extended;
  function feq(a,b:extended): boolean;
  function fge(a,b:extended): boolean;
  function fgt(a,b:extended): boolean;
  function fle(a,b:extended): boolean;
  function flt(a,b:extended): boolean;
  function FMax(a,b:extended):extended;
  function FMin(a,b:extended):extended;
  function fminovermax(a,b: extended): extended;
  function fminovermaxh(a,b:extended): extended;
  function fnegabsdiff(a,b: extended): extended;
  function fneq(a,b:extended): boolean;
  function fprod(a,b:extended):extended;
  function fsqrdiff(a,b: extended): extended;
  function fsum(a,b:extended):extended;
  function fzegers(a,b: extended): extended;
  function identical(a,b: extended): extended;
  function IMax(a,b:longint):longint;
  function IMin(a,b:longint):longint;
  function inrange(x,lo,hi:integer): boolean;
  function integertobinary(x:int64): string;
  function integerval(x:extended; dt:datatype=integerdt): integer;
  function isna(x:extended): boolean; overload;
  function isna(x:double): boolean; overload;
  function linearscale(x,xlo,xhi,ylo,yhi:double): double;
  function Log10(x:extended): extended;
  function Log2(x:extended): extended;
  function nchoose2(n:integer): int64;
  function nchoosek(N, K: integer): int64;
  function nonzero(x:extended): boolean;
  function Pwr(base,expon: extended): extended;
  function pythag(a,b: extended): extended;
  function rescale01(x,smax:double; smin:double=0): double;
  function Sign(a,b:extended): extended;
  function wholenumber(x:extended): boolean;
  procedure getij(k,nr,nc:integer; var i,j:integer);
  procedure getijuh(k,nr,nc:integer; var i,j:integer);
type
  comparetype = function(a,b:extended): boolean;
  binaryfunction = function(a,b:extended): extended;
{===========================================================================}
Implementation
uses
  ustring;
{===========================================================================}
function density2ties(den:single; n:integer; dir:char='d'): single;
begin
  case dir of
    'd','D': result:= den*n*(n-1);
    'u','U': result:= den*n*(n-1)/2;
    end;
end;
{---------------------------------------------------------------------------}
function rescale01(x,smax:double; smin:double=0): double;
//rescales number to 0 to 1 continuum
begin
  result:= (x - smin)/(smax - smin);
end;
{---------------------------------------------------------------------------}
Function nonzero(x:extended): boolean;
Begin result:= not iszero(x); end;
{---------------------------------------------------------------------------}
Function inrange(x,lo,hi:integer): boolean;
Begin
  result:= (x >= lo) and (x <= hi);
End;
{---------------------------------------------------------------------------}
Function linearscale(x,xlo,xhi,ylo,yhi:double): double;
Begin
  if xhi = xlo
    then result:= bna
    else result:= (x-xlo)*((yhi-ylo)/(xhi-xlo)) + ylo;
End;
{---------------------------------------------------------------------------}
  Function Log10(x:extended): extended;
  Begin
       if x <= 0.0 then log10:= 0 else log10:= ln(x)/ln(10);
  End;
{---------------------------------------------------------------------------}
  Function Log2(x:extended): extended;
  Begin
       if x <= 0.0 then log2:= 0 else log2:= ln(x)/ln(2);
  End;
{---------------------------------------------------------------------------}
  Function Pwr(base,expon: extended): extended;
  Begin
       if base = 0 then begin pwr:= 0; exit; end;
       if expon = 1 then begin pwr:= base; exit; end;
       if expon = 0 then begin pwr:= 1; exit; end;
       if base > 0 then begin pwr:= exp(expon * ln(base)); exit; end;
                                    { base < 0 and exponent <> 1 }
       pwr:= exp(expon*ln(abs(base)));
  End;
{---------------------------------------------------------------------------}
function identical(a,b: extended): extended;
begin
  if (a < na) and (b < na)
    then if samevalue(a,b)
      then result:= 1.0
      else result:= 0.0
    else result:= bna;
end;
{---------------------------------------------------------------------------}
function fzegers(a,b: extended): extended;
var
  temp: extended;
begin
  if (a < na) and (b < na)
    then begin
      temp:= sqr(a) + sqr(b);
      if not iszero(temp)
        then exit(2*a*b/temp);
      end;
  result:= bna;
end;
{---------------------------------------------------------------------------}
function fminovermax(a,b: extended): extended;
begin
  if (a >= na) or (b >= na) then exit(bna);
  if samevalue(a,b) then exit(1.0);
  if a > b
    then result:= b/a
    else result:= a/b;
end;
{---------------------------------------------------------------------------}
function fminovermaxh(a,b: extended): extended;
begin
  if (a >= na) or (b >= na) then exit(bna);
  if samevalue(a,b) then exit(1.0);
  if iszero(a) then a:= 0.01;
  if iszero(b) then b:= 0.01;
  if a > b
    then result:= b/a
    else result:= a/b;
end;
{---------------------------------------------------------------------------}
function fabsdiff(a,b: extended): extended;
begin
  if (a < na) and (b < na)
    then result:= abs(a-b)
    else result:= bna;
end;
{---------------------------------------------------------------------------}
function fnegabsdiff(a,b: extended): extended;
begin
  if (a < na) and (b < na)
    then result:= -abs(a-b)
    else result:= bna;
end;
{---------------------------------------------------------------------------}
function fsqrdiff(a,b: extended): extended;
begin
  if (a < na) and (b < na)
    then result:= sqr(a-b)
    else result:= bna;
end;
{---------------------------------------------------------------------------}
function fdiff(a,b: extended): extended;
//result = a - b
begin
  if (a < na) and (b < na)
    then result:= a - b
    else result:= bna;
end;
{---------------------------------------------------------------------------}
Function IMin(a,b:integer): integer;
Begin
  if (a < maxint) and (b < maxint )
    then result:= min(a,b)
    else result:= maxint;
End;
{---------------------------------------------------------------------------}
Function IMax(a,b:integer): integer;
Begin
  if (a < maxint) and (b < maxint)
    then result:= max(a,b)
    else result:= maxint;
End;
{---------------------------------------------------------------------------}
Function FMin(a,b:extended): extended;
Begin
  if (a < na) and (b < na)
    then result:= min(a,b)
    else result:= bna;
End;
{---------------------------------------------------------------------------}
Function FMax(a,b:extended): extended;
Begin
     if a > b then fmax:= a else fmax:= b;
End;
{---------------------------------------------------------------------------}
function fsum(a,b:extended):extended;
begin fsum:= a + b; end;
{---------------------------------------------------------------------------}
function fprod(a,b:extended):extended;
begin fprod:= a * b; end;
{---------------------------------------------------------------------------}
function favg(a,b:extended):extended;
begin favg:= (a+b)/2.0; end;
{---------------------------------------------------------------------------}
Function Sign(a,b:extended): extended;
Begin
     if b > 0.0 then sign:= abs(a) else sign:= -abs(a);
End;
{===========================================================================}
FUNCTION pythag(a,b: extended): extended;
VAR
   at,bt: extended;
BEGIN
     at := abs(a);
     bt := abs(b);
     IF at > bt THEN
         pythag := at*sqrt(1.0+sqr(bt/at))
     ELSE
         IF bt = 0.0 THEN
             pythag := 0.0
         ELSE
             pythag := bt*sqrt(1.0+sqr(at/bt))
END;
{---------------------------------------------------------------------------}
function flt(a,b:extended): boolean;
begin flt:= a < b; end;
{---------------------------------------------------------------------------}
function fgt(a,b:extended): boolean;
begin fgt:= a > b; end;
{---------------------------------------------------------------------------}
function fle(a,b:extended): boolean;
begin fle:= a <= b; end;
{---------------------------------------------------------------------------}
function fge(a,b:extended): boolean;
begin fge:= a >= b; end;
{---------------------------------------------------------------------------}
function feq(a,b:extended): boolean;
begin 
//  feq:= abs(a - b) < singletolerance; 
  feq:= samevalue(a,b);
end;
{---------------------------------------------------------------------------}
function fneq(a,b:extended): boolean;
begin fneq:= abs(a - b) >= singletolerance; end;
{---------------------------------------------------------------------------}
function different(a,b:extended; crit:extended=0.00001): boolean;
begin result:= abs(a - b) >= crit; end;
{---------------------------------------------------------------------------}
function comparevals(a:extended; op:tdichop; b:extended): boolean; overload;
var
  x: byte;
begin
  x:= comparevalue(a,b);
  case op of
    opgt: result:= x = 1;
    opge: result:= (x > -1);
    opeq: result:= x = 0;
    ople: result:= (x < 1);
    oplt: result:= x = -1;
    opne: result:= (x <> 0);
    else raise exception.create('Unrecognized relational value');
    end;
end;
{---------------------------------------------------------------------------}
function comparevals(a:integer; op:tdichop; b:integer): boolean; overload;
begin
  case op of
    opgt: result:= a > b;
    opge: result:= (a >= b);
    opeq: result:= a = b;
    ople: result:= (a <= b);
    oplt: result:= a < b;
    opne: result:= (a <> b);
    else raise exception.create('Unrecognized relational value');
    end;
end;
{---------------------------------------------------------------------------}
procedure minsum(var x,y,z:single);
begin x:= fmin(x,y+z); end;
{---------------------------------------------------------------------------}
procedure minproduct(var x,y,z:single);
begin x:= fmin(x,y*z); end;
{---------------------------------------------------------------------------}
procedure minminimum(var x,y,z:single);
begin x:= fmin(x,fmin(y,z)); end;
{---------------------------------------------------------------------------}
procedure minmaximum(var x,y,z:single);
begin x:= fmin(x,fmax(y,z)); end;
{---------------------------------------------------------------------------}
procedure maxsum(var x,y,z:single);
begin x:= fmax(x,y+z); end;
{---------------------------------------------------------------------------}
procedure maxproduct(var x,y,z:single);
begin x:= fmax(x,y*z); end;
{---------------------------------------------------------------------------}
procedure maxminimum(var x,y,z:single);
begin x:= fmax(x,fmin(y,z)); end;
{---------------------------------------------------------------------------}
procedure maxmaximum(var x,y,z:single);
begin x:= fmax(x,fmax(y,z)); end;
{---------------------------------------------------------------------------}
procedure getij(k,nr,nc:integer; var i,j:integer);
begin
  i:= (k div nc) + 1;
  j:= k mod nc;
end;
{---------------------------------------------------------------------------}
procedure getijuh(k,nr,nc:integer; var i,j:integer);
var
  ii,jj,kk: integer;
begin
  if nc > nr then nc:= nr;
  kk:= 0;
  for ii:= 1 to nr-1 do
    for jj:= 2 to ii do begin
      inc(kk);
      if kk = k then begin i:= ii; j:= jj; end;
      end;
end;
{---------------------------------------------------------------------------}
function clocksum(x,y:integer; n:integer=12): integer;
begin
  result:= 1 + (x+y) mod n;
end;
{---------------------------------------------------------------------------}
function wholenumber(x:extended): boolean;
begin
  result:= x = trunc(x);
end;
{---------------------------------------------------------------------------}
function integerval(x:extended; dt:datatype=integerdt): integer;
begin
  result:= 0;
  if x >= na then exit;
  try
    case dt of
      integerdt: result:= integer(round(x));
      bytedt:    result:= byte(round(x));
      smallintdt: result:= smallint(round(x));
      end;
  except
    on einvalidop do
  end;
end;
{---------------------------------------------------------------------------}
function isna(x:extended): boolean;
begin
  result:= x >= na;
end;
{---------------------------------------------------------------------------}
function isna(x:double): boolean;
begin
  result:= x >= na;
end;
{---------------------------------------------------------------------------}
function byteval(x:extended): byte;
begin
  if x >= na
    then result:= 0
    else if iszero(x)
      then result:= 0
      else if x > 255
        then result:= 255
        else if x < 1
          then result:= ceil(x)
          else result:= round(x);
end;
{---------------------------------------------------------------------------}
function binaryval(x:extended): byte;
begin
  if x >= na
    then result:= 0
    else if iszero(x)
      then result:= 0
      else result:= 1;
end;
{---------------------------------------------------------------------------}
function BooleanEval(x:extended; op:integer; val:extended): boolean;
begin
  case op of
    1: result:= fgt(x,val);
    2: result:= fge(x,val);
    3: result:= feq(x,val);
    4: result:= fle(x,val);
    5: result:= flt(x,val);
    end;
end;
{---------------------------------------------------------------------------}
function integertobinary(x:int64): string;
begin
  result:= '';
  while x > 0 do begin
    result:= result + inttostr(byte(x mod 2));
    x:= x div 2;
    end;
  result:= reversestr(result);
end;
{---------------------------------------------------------------------------}
function nchoose2(n:integer): int64;
begin result:= (n*(n-1)) div 2; end;
{---------------------------------------------------------------------------}
function factorial(n:integer): int64;
var i: integer;
begin
  result:= 1;
  for i:= 1 to n do
    result:= result*i;
end;
{---------------------------------------------------------------------------}
function nchoosek(N, K: integer): int64;
//from wikipedia
var
  L: int64;
begin
  if N < K
    then exit(0)
    else begin
      if K > N - K then
        K:= N - K;    // Optimization
      Result:= 1;
      L:= 0;
      while L < K do begin
        Result:= Result * (N - L);
        Inc(L);
        Result:= Result div L;
        end;
      end;
end;
{---------------------------------------------------------------------------}
End.
