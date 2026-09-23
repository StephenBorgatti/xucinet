unit uNormalize;

interface
uses
  math, ucommon, utsvec, utsmat, utunivariate;

procedure rowstoch(y,x:tsmat; diagok:boolean);
procedure normvec(x:tsvec; method:integer);
procedure stdizemat(x:tsmat; diagok:boolean; dmean:double=0.0; dstddev:double=1.0);
procedure stdizerows(x:tsmat; diagok:boolean);
procedure stdizecols(x:tsmat; diagok:boolean);
procedure centermat(x:tsmat; diagok:boolean; dmean:double=0.0);
procedure centerrows(x:tsmat; diagok:boolean; dmean:double=0.0);
procedure centercols(x:tsmat; diagok:boolean; dmean:double=0.0);

implementation

procedure rowstoch(y,x:tsmat; diagok:boolean);
var
  i,j: integer;
  sum: single;
begin
  if x.Is2mode
    then diagok:= true;
  for i:= 1 to x.nr do begin
    sum:= 0;
    for j:= 1 to x.nc do if (i<>j) or diagok then
      if x.isvalid(i,j) then
        sum:= sum + x.cell[i,j];
    if not iszero(sum) then
      for j:= 1 to x.nc do if (i<>j) or diagok then
        if x.isvalid(i,j)
          then y.cell[i,j]:= x.cell[i,j]/sum
          else y.cell[i,j]:= bna;
    end;
end;

procedure normvecinterval(x:tsvec);
var
  i: integer;
  u: tsimpleuni;
  sd: double;
begin
  u:= tsimpleuni.create;
  for i:= 1 to x.n do
    u.addcase(x.cell[i]);
  sd:= u.sd;
  if not iszero(u.sd) then
    for i:= 1 to x.n do
      if x.cell[i] < na
        then x.cell[i]:= (x.cell[i] - u.mean)/sd
        else x.cell[i]:= bna;
  u.Free;
end;

procedure normvecratio(x:tsvec);
var
  i: integer;
  u: tunivariate;
  t: double;
begin
  u:= tunivariate.create;
  for i:= 1 to x.n do
    u.addcase(x.cell[i]);
  u.calc;
  t:= sqrt(u.mcssq);
  if not iszero(t) then
    for i:= 1 to x.n do
      x.cell[i]:= x.cell[i]/t;
  u.Free;
end;

procedure normvecadditive(x:tsvec);
var
  i: integer;
  u: tunivariate;
begin
  u:= tunivariate.create;
  for i:= 1 to x.n do
    u.addcase(x.cell[i]);
  u.calc;
  for i:= 1 to x.n do
    x.cell[i]:= x.cell[i] - u.mean;
  u.Free;
end;

procedure normvec(x:tsvec; method:integer);
var
  i: integer;
begin
  case method of
    1: normvecadditive(x);
    2: normvecratio(x);
    3: normvecinterval(x);
    end;
end;

procedure stdizemat(x:tsmat; diagok:boolean; dmean:double=0.0; dstddev:double=1.0);
var
  u: tsimpleuni;
  i,j: integer;
  sd,av: double;
begin try
  u:= tsimpleuni.create;
  if x.Is2mode then diagok:= true;
  for i:= 1 to x.n do
    for j:= 1 to x.n do if (i<>j) or diagok then
      u.addcase(x.cell[i,j]);
  sd:= u.sd;
  av:= u.mean;
  for i:= 1 to x.n do
    for j:= 1 to x.n do if (i<>j) or diagok then
      if x.isvalid(i,j)
        then x.cell[i,j]:= dstddev*(dmean + x.cell[i,j] - av)/sd;
  finally
    u.Free;
  end;
end;

procedure stdizecols(x:tsmat; diagok:boolean);
var
  u: tsimpleuni;
  i,j: integer;
  sd,av: double;
begin try
  u:= tsimpleuni.create;
  if x.Is2mode then diagok:= true;
  for j:= 1 to x.nc do begin
    u.clear;
    for i:= 1 to x.nr do
      if (i<>j) or diagok then
        u.addcase(x.cell[i,j]);
    sd:= u.sd;
    av:= u.mean;
    for i:= 1 to x.nr do if (i<>j) or diagok then
      if x.isvalid(i,j)
        then x.cell[i,j]:= (x.cell[i,j] - av)/sd;
    end;
  finally
    u.Free;
  end;
end;

procedure stdizerows(x:tsmat; diagok:boolean);
var
  u: tsimpleuni;
  i,j: integer;
  sd,av: double;
begin try
  u:= tsimpleuni.create;
  if x.Is2mode then diagok:= true;
  for i:= 1 to x.nr do begin
    u.clear;
    for j:= 1 to x.nc do
      if (i<>j) or diagok then
        u.addcase(x.cell[i,j]);
    sd:= u.sd;
    av:= u.mean;
    for j:= 1 to x.nc do if (i<>j) or diagok then
      if x.isvalid(i,j)
        then x.cell[i,j]:= (x.cell[i,j] - av)/sd;
    end;
  finally
    u.Free;
  end;
end;

procedure centermat(x:tsmat; diagok:boolean; dmean:double=0.0);
var
  u: tsimpleuni;
  i,j: integer;
  av: double;
begin try
  u:= tsimpleuni.create;
  if x.Is2mode then diagok:= true;
  for i:= 1 to x.n do
    for j:= 1 to x.n do if (i<>j) or diagok then
      u.addcase(x.cell[i,j]);
  av:= u.mean;
  for i:= 1 to x.n do
    for j:= 1 to x.n do if (i<>j) or diagok then
      if x.isvalid(i,j)
        then x.cell[i,j]:= dmean + x.cell[i,j] - av;
  finally
    u.Free;
  end;
end;

procedure centerrows(x:tsmat; diagok:boolean; dmean:double=0.0);
var
  u: tsimpleuni;
  i,j: integer;
  av: double;
begin try
  u:= tsimpleuni.create;
  if x.Is2mode then diagok:= true;
  for i:= 1 to x.nr do begin
    u.clear;
    for j:= 1 to x.nc do
      if (i<>j) or diagok then
        u.addcase(x.cell[i,j]);
    av:= u.mean;
    for j:= 1 to x.nc do if (i<>j) or diagok then
      if x.isvalid(i,j)
        then x.cell[i,j]:= dmean + x.cell[i,j] - av;
    end;
  finally
    u.Free;
  end;
end;

procedure centercols(x:tsmat; diagok:boolean; dmean:double=0.0);
var
  u: tsimpleuni;
  i,j: integer;
  av: double;
begin try
  u:= tsimpleuni.create;
  if x.Is2mode then diagok:= true;
  for j:= 1 to x.nc do begin
    u.clear;
    for i:= 1 to x.nr do
      if (i<>j) or diagok then
        u.addcase(x.cell[i,j]);
    av:= u.mean;
    for i:= 1 to x.nr do if (i<>j) or diagok then
      if x.isvalid(i,j)
        then x.cell[i,j]:= dmean + (x.cell[i,j] - av);
    end;
  finally
    u.Free;
  end;
end;



end.
