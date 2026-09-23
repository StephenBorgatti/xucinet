unit uEgonetStructuralHoles;
{ structural hole statistics using the restricted model. input data
  is ego network only }
interface
uses
  sysutils,
  ucommon, utsmat, utsvec, ucan, utsmatds;
type
  tegonetstructuralholes = class
    n,allocn,ego: integer;
    efficiency, constraint, effectivesize, hierarchy, degree,
      valueddegree, lnconstraint, maxtie, avgaltertie, density, avgdeg,
      indirect,indirectsqrd,opentriads,closedtriads,numholes,
      minconst,maxconst,nconstraint,term1,term2,term3: double;
    customnorm: double;
    pm,dc: arrayofdouble;
    p: arrayofarrayofdouble;
    symmetrize: boolean;
    constructor create(n:integer=0);
    function getpm(z:tsmat): integer;
    function getdensity(z:tsmat): integer;
    function getconstraint(z:tsmat): integer;
    function getdecomp(z:tsmat): integer;
    procedure run(z:tsmat; sym:boolean=true; ego1:integer=1);
    procedure clear;
    destructor destroy; override;
    end;
{---------------------------------------------------------------------------}
implementation
{---------------------------------------------------------------------------}
constructor tegonetstructuralholes.create;
begin
  clear;
  symmetrize:= true;
end;
{---------------------------------------------------------------------------}
procedure tegonetstructuralholes.clear;
begin
  pm:= nil; dc:= nil; p:= nil;
  efficiency:= bna; density:= bna;
  minconst:= bna; maxconst:= bna;
  customnorm:= bna;
end;
{---------------------------------------------------------------------------}
destructor tegonetstructuralholes.destroy;
begin
  clear;
end;
{---------------------------------------------------------------------------}
function tegonetstructuralholes.getpm(z:tsmat): integer;
var
  max,sum,zplus: double;
  deg: integer;
  q,j,i: integer;
  m: arrayofarrayofdouble;
//  temp: tsmatds;

  procedure normalize;
  var
    i,j: integer;
  begin
    for i:= 1 to n do
      for j:= 1 to n do
        if i <> j then
          if symmetrize
            then p[i,j]:= p[i,j]*(z[i,j]+z[j,i])/(2.0*customnorm)
            else p[i,j]:= p[i,j]*z[i,j]/customnorm;
  end;

begin
  setlength(p,n+1,n+1);
  for i:= 1 to n do
    for j:= 1 to n do
      p[i,j]:= 0;
  setlength(m,n+1,n+1);
  setlength(pm,n+1);
  for i:= 1 to n do
    for j:= 1 to n do begin
      p[i,j]:= 0;
      m[i,j]:= 0;
      end;
  for i:= 1 to n do begin
    sum:= 0; max:= -1E38; deg:= 0;
    for q:= 1 to n do if i <> q then begin
      if symmetrize
        then zplus:= z[i,q] + z[q,i]
        else zplus:= z[i,q];
      sum:= sum + zplus;
      if zplus > max then max:= zplus;
      if zplus > 0 then inc(deg);
      end;
    if (sum <> 0) and (max <> 0) and (deg > 0) then
      for q:= 1 to n do if i <> q then begin
      if symmetrize
        then zplus:= z[i,q] + z[q,i]
        else zplus:= z[i,q];
        p[i,q]:= zplus/sum;
        m[i,q]:= zplus/max;
        end;
    if i = ego then begin
      valueddegree:= sum;
      degree:= deg;
      maxtie:= max;
      end;
    end; //i
  if customnorm < na
    then normalize;
  effectivesize:= 0;
  for j:= 1 to n do if (ego <> j) and (p[ego,j] > 0) then begin
    pm[j]:= 0;
//    for q:= 1 to n do if i <> q then
    for q:= 1 to n do if j <> q then
      pm[j]:= pm[j] + p[ego,q]*m[j,q];
    effectivesize:= effectivesize + 1.0-pm[j];
    end;
  if degree < 1
    then effectivesize:= 0;
  if degree > 0 then
    efficiency:= effectivesize/degree
    else efficiency:= bna;
  m:= nil;
end;
{---------------------------------------------------------------------------}
function tegonetstructuralholes.getdensity(z:tsmat): integer;
var
  i,q: integer;
  ties: integer;
  v,nn: double;
begin
  ties:= 0;
  for i:= 1 to n do if i<> ego then
    for q:= 1 to n do if (i <> q) and (q <> ego) then
      if z[i,q] > 0 then inc(ties);
  nn:= n - 1.0;
  if nn > 1
    then begin
      density:= ties/(nn*(nn-1.0));
      avgdeg:= ties/nn;
      end
    else begin
      density:= bna;
      avgdeg:= 0;
      end;
  numholes:= nn*(nn-1) - ties;
  v:= 0;
  for i:= 2 to n do if i <> ego then
    for q:= 1 to i-1 do if q <> ego then
      v:= v + z[i,q]+z[q,i];
  if na > 1 then
    avgaltertie:= 2.0*v/(nn*(nn-1))
end;
{---------------------------------------------------------------------------}
function tegonetstructuralholes.getconstraint(z:tsmat): integer;
//dont run before running maxmin
var
  j,q: integer;
  numer,relij,ind: double;
begin
  setlength(dc,n+1);
  indirect:= 0; indirectsqrd:= 0;
  opentriads:= 0; closedtriads:= 0;
  for j:= 1 to n do if j <> ego then begin
    dc[j]:= 0;
    for q:= 1 to n do if (q <> ego) and (q <> j) then begin
      dc[j]:= dc[j] + p[ego,q]*p[q,j];
      if z[j,q]+z[q,j] > 0
        then closedtriads:= closedtriads + 0.5
        else opentriads:= opentriads + 0.5;
      end;
    indirect:= indirect + dc[j];
    indirectsqrd:= indirectsqrd + sqr(dc[j]);
    dc[j]:= sqr(dc[j]+p[ego,j]);
    end;
  constraint:= 0; 
  for j:= 1 to n do if j <> ego then begin
    constraint:= constraint + dc[j];
    end;
  if degree < 2
    then constraint:= bna;
  //apparently the hierarchy values are correct here but not in uegonetholes
  if (constraint > 0.0) and (degree > 1)
    then begin
      numer:= 0.0;
      for j:= 1 to n do if (ego<>j) and (p[ego,j] > 0.0) then begin
        relij:= dc[j]*degree/constraint;
        if relij > singletolerance then
          numer:= numer + relij*ln(relij);
        end;
      hierarchy:= numer/(degree*ln(degree));
      end
    else if degree = 1
      then hierarchy:= 1
      else hierarchy:= bna;
end;
{---------------------------------------------------------------------------}
function tegonetstructuralholes.getdecomp(z:tsmat): integer;
//dont run before running maxmin
var
  j,q: integer;
  numer,relij,ind: double;

  function getterm1:double;
  var
    j: integer;
  begin
    result:= 0;
    for j:= 1 to n do if j <> ego then
      result:= result + sqr(p[ego,j]);
  end;

  function getterm2:double;
  var
    j,q: integer;
    sum: double;
  begin
    result:= 0;
    for j:= 1 to n do if j <> ego then begin
      sum:= 0;
      for q:= 1 to n do if (j <> ego) and (q <> ego) then
        sum:= sum + p[ego,q]*p[q,j];
      result:= result + p[ego,j]*sum;
    end;
    result:= result*2;
  end;

  function getterm3:double;
  var
    j,q: integer;
    sum: double;
  begin
    result:= 0;
    for j:= 1 to n do if j <> ego then begin
      sum:= 0;
      for q:= 1 to n do if (j <> ego) and (q <> ego) then
        sum:= sum + p[ego,q]*p[q,j];
      result:= result + sqr(sum);
    end;
  end;

begin
  term1:= getterm1;
  term2:= getterm2;
  term3:= getterm3;
end;
{---------------------------------------------------------------------------}
procedure tegonetstructuralholes.run(z:tsmat; sym:boolean=true; ego1:integer=1);
begin
  symmetrize:= sym;
  ego:= ego1;
  n:= z.n;
  getpm(z);
  getdensity(z);
  getconstraint(z);
  getdecomp(z);
  z.istable:= true;
end;
{---------------------------------------------------------------------------}

end.
