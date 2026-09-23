unit ufloyd;
interface
uses
  ucommon, utsmat;

function floyd(d,m:tsmat; diagonal:single=0; undefined:single=bna):integer; overload;
function floyd(d:tsmat; diagonal:single=0; undefined:single=bna):integer; overload;
function reciprocalfloyd(d:tsmat; diagonal:single=bna):integer;
procedure binaryfloyd(d:tsmat);
procedure valuedfloyd(d:tsmat);

implementation

function cleanupfloyd(d:tsmat; diagonal:single=0; undefined:single=bna): integer;
var
  i,j: integer;
Begin
  binaryfloyd(d);
  result:= 0;
  for i:= 1 to d.n do
    for j:= 1 to d.n do if i = j
      then d.cell[i,j]:= diagonal
      else if d.cell[i,j] = 0
        then begin
          inc(result);
          d.cell[i,j]:= undefined;
          end;
end;

function floyd(d,m:tsmat; diagonal:single=0; undefined:single=bna):integer;
begin
  d.copy(m);
  result:= floyd(d,diagonal,undefined);
end;

function floyd(d:tsmat; diagonal:single=0; undefined:single=bna):integer;
Var
  i,j: integer;
Begin
  binaryfloyd(d);
  result:= cleanupfloyd(d,diagonal,undefined);
end;

function reciprocalfloyd(d:tsmat; diagonal:single=bna):integer;
//on input d is adjacency matrix; on output d is reciprocal of distance matrix
//function returns number of undefined distances
Var
  i,j: integer;
Begin
  binaryfloyd(d);
  result:= 0;
  for i:= 1 to d.n do
    for j:= 1 to d.n do if i = j
      then d.cell[i,j]:= diagonal
      else if d.cell[i,j] = 0
        then begin
          inc(result);
          d.cell[i,j]:= 0;
          end
        else d.cell[i,j]:= 1.0/d.cell[i,j];
End;

procedure binaryfloyd(d:tsmat);
//on input d is adjacency matrix; on output d is distance matrix
//values of 0 in off-diagonal cells indicated undefined distance
Var
  s: single;
  i,j,k: integer;
Begin
  for i:= 1 to d.n do d.cell[i,i]:= 0;
    for i:= 1 to d.n do begin
      for j:= 1 to d.n do
        if d.cell[j,i] > 0 then
          for k:= 1 to d.n do
            if (d.cell[i,k] > 0) then begin
              s:= d.cell[j,i] + d.cell[i,k];
              if (d.cell[j,k] = 0) or (s < d.cell[j,k]) then
                d.cell[j,k]:= s;
              end;
      end;
End;

procedure valuedfloyd(d:tsmat);
//on input d is valued matrix; on output d is distance matrix
Var
  s: single;
  i,j,k: integer;
Begin
  for i:= 1 to d.n do
    d.cell[i,i]:= 0;
  for k:= 1 to d.n do
    for i:= 1 to d.n do
      for j:= 1 to d.n do begin
        s:= d.cell[i,k] + d.cell[k,j];
        if d.cell[i,j] > s
          then d.cell[i,j]:= s;
        end;
End;

end.
