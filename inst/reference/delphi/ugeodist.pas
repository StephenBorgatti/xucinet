unit uGEODIST;
interface
uses
  ucommon, ugeneral,uvector,umatrix,ubmatrix,usimatrix,usmatrix,umath,utsmat,
  ucan; {uvmatrix;}

Type
    optproc = procedure(var x,y,z:single);
    optfunc = function(x,y:extended):extended;
    optbfunc = function(x,y:extended):boolean;
    optshellproc = procedure(j,i,k:integer);

procedure bfs(isbest,dist:matrix);
function  Floyd(d:bmatrix; var hasmissing:boolean): smallint;
function bFloyd(d:bmatrix; var miss:longint; rec:boolean = true; countmiss:boolean=true): smallint;
function iFloyd(d:simatrix; var miss:longint; rec:boolean = true; countmiss:boolean=true): smallint;
function  sFloyd(d:smatrix; var miss:longint): smallint;
function  mfloyd(d:matrix; var miss:longint): smallint;
function  mifloyd(d:matrix): smallint;
Procedure FloydDist(d:smatrix);
function ModifiedFloyd(d,c:simatrix; var infinites:integer; rec:boolean=true): smallint;
Procedure mFloydDist(d:matrix);
Procedure iFloydDist(d:simatrix);
Procedure bFloydDist(d:bmatrix);
Procedure FloydSim(d:smatrix);
Procedure FloydSimLength(d:smatrix; len:simatrix);
function smallestsumdist(x,value:smatrix; links:simatrix):smallint;
function largestproductdist(x,value:smatrix; links:simatrix):smallint;
function largestminimumdist(x,value:smatrix; links:simatrix):smallint;
Function optpathvalue(d:smatrix; outside,inside:optfunc):integer; overload;
Function optpathvalue(d:tsmat; outside,inside:optfunc): boolean; overload;
Function voptpathvalue(d:matrix; outside,inside:optfunc):integer;
Function voptpathlength(g,len:matrix; outside,inside:optfunc):integer;
Function voptpathlength2(g:smatrix; len:simatrix; outside,inside:optfunc)
         :integer;
Function optpathlength(d:smatrix; len:bmatrix; comp:optbfunc;
                           inside:optfunc):integer;
Function optpathvalue2(d:smatrix; p:optproc):integer;
Procedure optpathshell(n:integer; p:optshellproc);
{===========================================================================}
implementation
{uses Ucinet;}
{===========================================================================}
procedure bfs(isbest,dist:matrix);
{isbest(i,j) = 1 if edge(i,j) is optimal path from i to j.}
{algorithm: Dijkstra; coding: Borgatti; date: 3/17/90}
label cleanup;
Var
  i,j,n: smallint;
  length: ivector;

  Procedure Loop(i,d:smallint);
  label cleanup;
  Var
    j,k: smallint;
    fresh: ivector;
  Begin
    fresh:= ivector.create;
    if fresh.allocsize(n) <> 0 then goto cleanup;
    inc(d); k:= 0;
    for j:= 1 to n do
        if (length.cell^[j] > d) and (isbest.iget(i,j) = 1) then begin
           length.cell^[j]:= d;
           inc(k);
           fresh.cell^[k]:= j;
        end;
    if k > 0 then for j:= 1 to k do loop(fresh.cell^[j],d);
    cleanup: fresh.free;
  End;

Begin
  length:= sivector.create; n:= isbest.n;
  if length.allocsize(n) <> 0 then goto cleanup;
  for i:= 1 to n do begin
    for j:= 1 to n do
        if j = i then
            length.cell^[j]:= 0
        else
            length.cell^[j]:= n;
    loop(i,0);
    for j:= 1 to n do dist.iput(i,j,length.cell^[j]);
  end;
  cleanup:
    length.free;
End;
{---------------------------------------------------------------------------}
 function Floyd(d:bmatrix; var hasmissing:boolean): smallint;
  {input is adjacency matrix. output is geodesic distance matrix}
  Label cleanup;
  Var
    s,i,j,k: smallint;
  Begin
    error:= 0; hasmissing:= false;
    for i:= 1 to d.n do d.cell^[i]^[i]:= 0;
    for i:= 1 to d.n do begin
        for j:= 1 to d.n do
            if (d.cell^[j]^[i] > 0) then
               for k:= 1 to d.n do
                   if (d.cell^[i]^[k] > 0) then begin
                      s:= d.cell^[j]^[i] + d.cell^[i]^[k];
                      if (d.cell^[j]^[k] = 0) or (s < d.cell^[j]^[k]) then
                         d.cell^[j]^[k]:= s;
                      end;
    end;
    for i:= 1 to d.n do
        for j:= 1 to d.n do
            if i = j then
                d.cell^[i]^[j]:= 0
            else
                if d.cell^[i]^[j] = 0 then begin
                   hasmissing:= true;
                   d.cell^[i]^[j]:= d.n;
                end;
  cleanup:
    floyd:= error;
  End;
{---------------------------------------------------------------------------}
 function ModifiedFloyd(d,c:simatrix; var infinites:integer; rec:boolean=true): smallint;
 {this procedure doesn't work}
  {input is adjacency matrix. output is geodesic distance matrix plus # of geodesics matrix}
  Label cleanup;
  Var
    s,i,j,k: smallint;
  Begin
    for i:= 1 to d.n do d.cell^[i]^[i]:= 0;
    for i:= 1 to d.n do for j:= 1 to d.n do if i = j
      then c.cell^[i]^[j]:= 0
      else if d.cell^[i]^[j] = 1
        then c.cell^[i]^[j]:= 1
        else c.cell^[i]^[j]:= 0;
    for i:= 1 to d.n do begin
        for j:= 1 to d.n do
            if (d.cell^[j]^[i] > 0) then
               for k:= 1 to d.n do
                   if (d.cell^[i]^[k] > 0) then begin
                      s:= d.cell^[j]^[i] + d.cell^[i]^[k];
                      if (d.cell^[j]^[k] = 0) or (s <= d.cell^[j]^[k]) then begin
                         d.cell^[j]^[k]:= s;
                         c.cell^[j]^[k]:= c.cell^[j]^[k] + 1;
                         end;
                      end;
    end;
    infinites:= 0;
    if rec then for i:= 1 to d.n do
      for j:= 1 to d.n do
        if i = j
          then d.cell^[i]^[j]:= 0
          else if d.cell^[i]^[j] = 0 then begin
            inc(infinites);
            d.cell^[i]^[j]:= d.n;
            end;
  cleanup:
    result:= error;
  End;
{---------------------------------------------------------------------------}
  function iFloyd(d:simatrix; var miss:longint; rec:boolean = true; countmiss:boolean=true): smallint;
  {input is binary adjacency matrix. output is geodesic distance matrix}
  Label cleanup;
  Var
    s,i,j,k: integer;
  Begin
    error:= 0; miss:= 0;
    for i:= 1 to d.n do d.cell^[i]^[i]:= 0;
    for i:= 1 to d.n do begin
        for j:= 1 to d.n do
            if (d.cell^[j]^[i] > 0) then
               for k:= 1 to d.n do
                   if (d.cell^[i]^[k] > 0) then begin
                      s:= d.cell^[j]^[i] + d.cell^[i]^[k];
                      if (d.cell^[j]^[k] = 0) or (s < d.cell^[j]^[k]) then
                         d.cell^[j]^[k]:= s;
                   end;
    end;
    if rec or countmiss then
      for i:= 1 to d.n do
        for j:= 1 to d.n do if i = j
          then d.cell^[i]^[j]:= 0
          else if d.cell^[i]^[j] = 0 then begin
            inc(miss);
            if rec then d.cell^[i]^[j]:= d.n;
            end;
  cleanup:
    ifloyd:= error;
  End;
{---------------------------------------------------------------------------}
  function bFloyd(d:bmatrix; var miss:longint; rec:boolean = true; countmiss:boolean=true): smallint;
  {input is binary adjacency matrix. output is geodesic distance matrix}
  Label cleanup;
  Var
    s,i,j,k: integer;
  Begin
    error:= 0; miss:= 0;
    for i:= 1 to d.n do d.cell^[i]^[i]:= 0;
    for i:= 1 to d.n do begin
        for j:= 1 to d.n do
            if (d.cell^[j]^[i] > 0) then
               for k:= 1 to d.n do
                   if (d.cell^[i]^[k] > 0) then begin
                      s:= d.cell^[j]^[i] + d.cell^[i]^[k];
                      if (d.cell^[j]^[k] = 0) or (s < d.cell^[j]^[k]) then
                         d.cell^[j]^[k]:= s;
                   end;
    end;
    if rec or countmiss then
      for i:= 1 to d.n do
        for j:= 1 to d.n do if i = j
          then d.cell^[i]^[j]:= 0
          else if d.cell^[i]^[j] = 0 then begin
            inc(miss);
            if rec then d.cell^[i]^[j]:= d.n;
            end;
  cleanup:
    result:= error;
  End;
{---------------------------------------------------------------------------}
 function sFloyd(d:smatrix; var miss:longint): smallint;
  {input is adjacency matrix. output is geodesic distance matrix}
  Label cleanup;
  Var
    s: double;
    i,j,k: smallint;
  Begin
    error:= 0; miss:= 0;
    for i:= 1 to d.n do d.cell^[i]^[i]:= 0;
    for i:= 1 to d.n do begin
      for j:= 1 to d.n do
        if (d.cell^[j]^[i] > 0) then
          for k:= 1 to d.n do
            if (d.cell^[i]^[k] > 0) then begin
              s:= d.cell^[j]^[i] + d.cell^[i]^[k];
              if (d.cell^[j]^[k] < singleprecision) or (s < d.cell^[j]^[k]) then d.cell^[j]^[k]:= s;
              end;
      end;
    for i:= 1 to d.n do
      for j:= 1 to d.n do
        if i = j
          then d.cell^[i]^[j]:= 0
          else if d.cell^[i]^[j] < singleprecision then begin
            inc(miss);
            d.cell^[i]^[j]:= d.n;
            end;
  cleanup:
    sfloyd:= error;
  End;
{---------------------------------------------------------------------------}
  Function mfloyd(d:matrix; var miss:longint):smallint;
  {input is adjacency matrix. output is geodesic distance matrix}
  Label cleanup;
  Var
    s: extended;
    i,j,k: smallint;
  Begin
    miss:= 0;
    for i:= 1 to d.n do d.fput(i,i,0);
    for i:= 1 to d.n do begin
        for j:= 1 to d.n do
            if d.fget(j,i) > 0 then
               for k:= 1 to d.n do
                   if (d.fget(i,k) > 0) then begin
                      s:= d.fget(j,i) + d.fget(i,k);
                      if (d.fget(j,k) = 0) or (s < d.fget(j,k)) then
                         d.fput(j,k,s);
                   end;
    end;
    for i:= 1 to d.n do
        for j:= 1 to d.n do
            if i = j then
                d.fput(i,j,0)
            else
                if d.fget(i,j) = 0 then begin
                   inc(miss);
                   d.fput(i,j,d.n);
                end;
  cleanup:
    mFloyd := error;
  End;
{---------------------------------------------------------------------------}
  Function mifloyd(d:matrix):smallint;
  {input is adjacency matrix. output is geodesic distance matrix}
  Label cleanup;
  Var
    s: longint;
    i,j,k: smallint;
  Begin
    for i:= 1 to d.n do d.iput(i,i,0);
    for i:= 1 to d.n do begin
        for j:= 1 to d.n do
            if d.iget(j,i) > 0 then
               for k:= 1 to d.n do
                   if (d.iget(i,k) > 0) then begin
                      s:= d.iget(j,i) + d.iget(i,k);
                      if (d.iget(j,k) = 0) or (s < d.iget(j,k)) then
                         d.iput(j,k,s);
                   end;
    end;
    for i:= 1 to d.n do
        for j:= 1 to d.n do
            if i = j then
                d.iput(i,j,0)
            else
                if d.iget(i,j) = 0 then d.iput(i,j,d.n);
  cleanup:
    miFloyd := error;
  End;
{---------------------------------------------------------------------------}
  Procedure FloydDist(d:smatrix);
  {input is distance matrix. output is geodesic distance matrix}
  Var
    i,j,k: smallint;
    s: single;
  Begin
    for i:= 1 to d.n do
        for j:= 1 to d.n do
            for k:= 1 to d.n do begin
                s:= d.cell^[j]^[i] + d.cell^[i]^[k];
                if s < d.cell^[j]^[k] then d.cell^[j]^[k]:= s;
            end;
  End;
{---------------------------------------------------------------------------}
  Procedure mFloydDist(d:matrix);
  {input is distance matrix. output is geodesic distance matrix}
  Var
    i,j,k: smallint;
    s: extended;
  Begin
    for i:= 1 to d.n do
        for j:= 1 to d.n do
            for k:= 1 to d.n do begin
                s:= d.fget(j,i) + d.fget(i,k);
                if s < d.fget(j,k) then d.fput(j,k,s);
            end;
  End;
{---------------------------------------------------------------------------}
  Procedure iFloydDist(d:simatrix);
  {input is distance matrix. output is geodesic distance matrix}
  Var
    i,j,k: smallint;
    s: longint;
  Begin
    for i:= 1 to d.n do
        for j:= 1 to d.n do
            for k:= 1 to d.n do begin
                s:= d.cell^[j]^[i] + d.cell^[i]^[k];
                if s < d.cell^[j]^[k] then d.cell^[j]^[k]:= s;
            end;
  End;
{---------------------------------------------------------------------------}
  Procedure bFloydDist(d:bmatrix);
  {input is distance matrix. output is geodesic distance matrix}
  Var
    i,j,k: smallint;
    s: longint;
  Begin
    for i:= 1 to d.n do
        for j:= 1 to d.n do
            for k:= 1 to d.n do begin
                s:= d.cell^[j]^[i] + d.cell^[i]^[k];
                if s < d.cell^[j]^[k] then d.cell^[j]^[k]:= s;
            end;
  End;
{---------------------------------------------------------------------------}
  Procedure FloydSim(d:smatrix);
  {input is similarity matrix. output is geodesic distance matrix}
  Var
    i,j,k: smallint;
  Begin
    for i:= 1 to d.n do
        for j:= 1 to d.n do
            for k:= 1 to d.n do
                d.cell^[j]^[k]:= fmax(fmin(d.cell^[j]^[i],d.cell^[i]^[k]),d.cell^[j]^[k]);
  End;
{---------------------------------------------------------------------------}
  Procedure FloydSimLength(d:smatrix; len:simatrix);
  {input is similarity matrix. output is geodesic distance matrix}
  Var
    i,j,k: smallint;
  Begin
    for i:= 1 to d.n do
        for j:= 1 to d.n do
            len.cell^[i]^[j]:= 1;
    for i:= 1 to d.n do
        for j:= 1 to d.n do
            for k:= 1 to d.n do
                if fmin(d.cell^[j]^[i],d.cell^[i]^[k]) > d.cell^[j]^[k] then begin
                   d.cell^[j]^[k]:= fmin(d.cell^[j]^[i],d.cell^[i]^[k]);
                   len.cell^[j]^[k]:= len.cell^[j]^[i] + len.cell^[i]^[k];
                end;
  End;
{---------------------------------------------------------------------------}
function getsdistij(var x:smatrix; s,t:integer;
                   var value:single; var links:integer): smallint;
label cleanup;
var
  n,j: smallint;
  d: svector;
  l: sivector;

  procedure ssprocess2(v,it:integer);
  var
    j: integer;
  begin
    inc(it);
    for j:= 1 to n do
      if (v <> j) and (d.cell^[v] + x.cell^[v]^[j] < d.cell^[j])
        then begin
          d.cell^[j]:= d.cell^[v] + x.cell^[v]^[j];
          l.cell^[j]:= it;
          end;
    for j:= 1 to n do if l.cell^[j] = it then
      ssprocess2(j,it);
  end;

begin
  d:= svector.create; l:= sivector.create;
  n:= x.nr;
  if d.allocsize(n) <> 0 then goto cleanup;
  if l.allocsize(n) <> 0 then goto cleanup;
  for j:= 1 to n do
    if s = j
      then begin d.cell^[j]:= 0; l.cell^[j]:= 0; end
      else begin d.cell^[j]:= bna; l.cell^[j]:= n; end;
  ssprocess2(s,0);
  value:= d.cell^[t];
  links:= l.cell^[t];
  cleanup:
    result:= error;
    d.free; l.free;
end;
{---------------------------------------------------------------------------}
function smallestsumdist(x,value:smatrix; links:simatrix): smallint;
label cleanup;
var
  n,i,j: smallint;
  d: svector;
  l: sivector;

  procedure ssprocess(v:smallint; it:smallint);
  var
    j: smallint;
  begin
    inc(it);
    for j:= 1 to n do
      if (v <> j) and (d.cell^[v]+x.cell^[v]^[j] < d.cell^[j])
        then begin
          d.cell^[j]:= d.cell^[v] + x.cell^[v]^[j];
          l.cell^[j]:= it;
          ssprocess(j,it);
          end;
  end;

  procedure ssprocess2(v:smallint; it:smallint);
  var
    j: smallint;
  begin
    inc(it);
    for j:= 1 to n do
      if (v <> j) and (d.cell^[v]+x.cell^[v]^[j] < d.cell^[j])
        then begin
          d.cell^[j]:= d.cell^[v] + x.cell^[v]^[j];
          l.cell^[j]:= it;
          end;
    for j:= 1 to n do if l.cell^[j] = it then
      ssprocess2(j,it);
  end;


  begin
  d:= svector.create; l:= sivector.create;
  n:= x.nr;
  if d.allocsize(n) <> 0 then goto cleanup;
  if l.allocsize(n) <> 0 then goto cleanup;
  //if value.allocsize(n,n) <> 0 then goto cleanup;
  //if links.allocsize(n,n) <> 0 then goto cleanup;
  for i:= 1 to n do begin
    for j:= 1 to n do
      if i = j
        then begin d.cell^[j]:= 0; l.cell^[j]:= 0; end
        else begin d.cell^[j]:= bna; l.cell^[j]:= n; end;
    ssprocess2(i,0);
    for j:= 1 to n do begin
      value.cell^[i]^[j]:= d.cell^[j];
      links.cell^[i]^[j]:= l.cell^[j];
      end;
    end;
  cleanup:
    result:= error;
    d.free; l.free;
end;
{---------------------------------------------------------------------------}
function largestproductdist(x,value:smatrix; links:simatrix): smallint;
label cleanup;
var
  n,i,j: smallint;
  d: svector;
  l: sivector;

  procedure lpprocess(v:smallint; it:smallint);
  var
    j: smallint;
  begin
    inc(it);
    for j:= 1 to n do
      if (v <> j) and (x.cell^[v]^[j] > 0) and (d.cell^[v]*x.cell^[v]^[j] > d.cell^[j])
        then begin
          d.cell^[j]:= d.cell^[v]*x.cell^[v]^[j];
          l.cell^[j]:= it;
//        lpprocess(j,it);
          end;
    for j:= 1 to n do if l.cell^[j] = it then
      lpprocess(j,it);
  end;

begin
  d:= svector.create; l:= sivector.create;
  n:= x.nr;
  //if value.allocsize(n,n) <> 0 then goto cleanup;
  //if links.allocsize(n,n) <> 0 then goto cleanup;
  if d.allocsize(n) <> 0 then goto cleanup;
  if l.allocsize(n) <> 0 then goto cleanup;
  for i:= 1 to n do begin
    for j:= 1 to n do
      if i = j
        then begin d.cell^[j]:= 1; l.cell^[j]:= 0; end
        else begin d.cell^[j]:= -1E38; l.cell^[j]:= n; end;
    lpprocess(i,0);
    for j:= 1 to n do begin
      if d.cell^[j] <= -1E38
        then value.cell^[i]^[j]:= bna
        else value.cell^[i]^[j]:= d.cell^[j];
      links.cell^[i]^[j]:= l.cell^[j];
      end;
    end;
  cleanup:
    result:= error;
    d.free; l.free;
end;
{---------------------------------------------------------------------------}
function largestminimumdist(x,value:smatrix; links:simatrix): smallint;
label cleanup;
var
  n,i,j: smallint;
  d: svector;
  l: sivector;

  procedure lmprocess(v:smallint; it:smallint);
  var
    j: smallint;
  begin
    inc(it);
    for j:= 1 to n do
      if (v<>j) and (fmin(d.cell^[v],x.cell^[v]^[j]) > d.cell^[j])
        then begin
          d.cell^[j]:= fmin(d.cell^[v],x.cell^[v]^[j]);
          l.cell^[j]:= it;
//          lmprocess(j,it);
          end;
    for j:= 1 to n do if l.cell^[j] = it then
      lmprocess(j,it);
  end;

begin
  d:= svector.create; l:= sivector.create;
  n:= x.nr;
  //if value.allocsize(n,n) <> 0 then goto cleanup;
  //if links.allocsize(n,n) <> 0 then goto cleanup;
  if d.allocsize(n) <> 0 then goto cleanup;
  if l.allocsize(n) <> 0 then goto cleanup;
  for i:= 1 to n do begin
    for j:= 1 to n do
      if i = j
        then begin d.cell^[j]:= bna; l.cell^[j]:= 0; end
        else begin d.cell^[j]:= -1E38; l.cell^[j]:= n; end;
    lmprocess(i,0);
    for j:= 1 to n do begin
      if d.cell^[j] <= -1E38
        then value.cell^[i]^[j]:= bna
        else value.cell^[i]^[j]:= d.cell^[j];
      links.cell^[i]^[j]:= l.cell^[j];
      end;
    end;
  cleanup:
    result:= error;
    d.free; l.free;
end;
{---------------------------------------------------------------------------}
Function optpathvalue(d:smatrix; outside,inside:optfunc):integer;
Label cleanup;
Var
  err,i,j,k: integer;
Begin
  err := 0;
  for i:= 1 to d.n do begin
//      if InterruptTest then begin err := 1; goto cleanup; end;
      for j:= 1 to d.n do
          if i<>j then
             for k:= 1 to d.n do
                 if (k<>i) and (k<>j) then
                    d.cell^[j]^[k]:= outside(inside(d.cell^[j]^[i],
                                     d.cell^[i]^[k]),d.cell^[j]^[k]);
  end;
cleanup:
  optpathvalue := err;
End;
{---------------------------------------------------------------------------}
Function voptpathvalue(d:matrix; outside,inside:optfunc):integer;
Label cleanup;
Var
  err,i,j,k: integer;
Begin
  err := 0;
  for i:= 1 to d.n do begin
{      Application.ProcessMessages;
      if InterruptTest then begin err := 1; goto cleanup; end;}
      for j:= 1 to d.n do
          if i<>j then
             for k:= 1 to d.n do
                 if (k<>i) and (k<>j) then
                    d.fput(j,k,outside(inside(d.fget(j,i),d.fget(i,k)),
                           d.fget(j,k)));
  end;
cleanup:
  voptpathvalue := err;
End;
{---------------------------------------------------------------------------}
Function voptpathlength(g,len:matrix; outside,inside:optfunc):integer;
label cleanup;
Var
  err,i,j: integer;
  {d: vmatrix;}
  d: smatrix; {*********}
Begin
  err := 0;
  d:= smatrix.create;
  if d.allocsize(g.n,g.n) <> 0 then goto cleanup;
  d.copyval(g);
  if cant(voptpathvalue(d,outside,inside)) then begin err := 1; goto cleanup;
  end;
  len.zerofill;
  for i:= 1 to d.n do
      for j:= 1 to d.n do
          if (i<>j) then
             if d.fget(i,j) = g.fget(i,j) then
                len.iput(i,j,1);
  bfs(len,len);
cleanup:
  d.free;
  voptpathlength := err;
End;
{---------------------------------------------------------------------------}
Function voptpathlength2(g:smatrix; len:simatrix; outside,inside:optfunc)
         :integer;
label cleanup;
Var
  err,i,j: integer;
  d: smatrix;
Begin
  err := 0;
  d:= smatrix.create;
  if d.allocsize(g.n,g.n) <> 0 then goto cleanup;
  d.copyval(g);
  if cant(voptpathvalue(d,outside,inside)) then begin err := 1; goto cleanup;
  end;
  len.zerofill;
  for i:= 1 to d.n do
      for j:= 1 to d.n do
          if (i<>j) then
             if d.fget(i,j) = g.fget(i,j) then
                len.iput(i,j,1);
  bfs(len,len);
cleanup:
  d.free;
  voptpathlength2 := err;
End;
{---------------------------------------------------------------------------}
Function optpathlength(d:smatrix; len:bmatrix; comp:optbfunc;
         inside:optfunc):integer;
Label cleanup;
Var
  err,i,j,k,s: integer;
  insjiik: extended;
Begin
  err := 0;
  for i:= 1 to d.n do
      for j:= 1 to d.n do
          if i = j then
              len.cell^[i]^[j]:= 0
          else
              len.cell^[i]^[j]:= 1;

  for i:= 1 to d.n do begin
      for j:= 1 to d.n do
          if i<>j then
             for k:= 1 to d.n do
                 if (k<>i) and (k<>j) then begin
                    insjiik:= inside(d.cell^[j]^[i],d.cell^[i]^[k]);
                    if comp(insjiik,d.cell^[j]^[k]) then begin
                       d.cell^[j]^[k]:= insjiik;
                       len.cell^[j]^[k]:= len.cell^[j]^[i] + len.cell^[i]^[k];
                    end;
                 end;
  end;
  for i:= 1 to d.n do
      for j:= 1 to d.n do begin
          for k:= 1 to d.n do begin
              s:= len.cell^[j]^[i] + len.cell^[i]^[k];
              if s < len.cell^[j]^[k] then len.cell^[j]^[k]:= s;
          end;
      end;
cleanup:
  optpathlength := err;
End;
{---------------------------------------------------------------------------}
Function optpathvalue2(d:smatrix; p:optproc): integer;
Label cleanup;
Var
  err,i,j,k: integer;
Begin
  err := 0;
  for i:= 1 to d.n do begin
      for j:= 1 to d.n do begin
          if i<>j then
             for k:= 1 to d.n do
                 if (k<>i) and (k<>j) then
                    p(d.cell^[j]^[k],d.cell^[j]^[i],d.cell^[i]^[k]);
      end;
  end;
cleanup:
  optpathvalue2 := err;
End;
{---------------------------------------------------------------------------}
Procedure optpathshell(n:integer; p:optshellproc);
Var
  i,j,k: integer;
Begin
  for i:= 1 to n do
      for j:= 1 to n do
          if i<>j then
             for k:= 1 to n do
                 if (k<>i) and (k<>j) then p(j,i,k);
End;
{---------------------------------------------------------------------------}
Function optpathvalue(d:tsmat; outside,inside:optfunc): boolean;
Label cleanup;
Var
  i,j,k: integer;
Begin
  error := 0;
  for i:= 1 to d.n do
    for j:= 1 to d.n do if i<>j then
      for k:= 1 to d.n do if (k<>i) and (k<>j) then
        d.cell[j,k]:= outside(inside(d.cell[j,i],d.cell[i,k]),d.cell[j,k]);
cleanup:
  result:= error = 0;
End;
{---------------------------------------------------------------------------}
Procedure optimalpathvalue(d:tsmat; outside,inside:optfunc);
Label cleanup;
Var
  i,j,k: integer;
Begin
  for i:= 1 to d.n do
    for j:= 1 to d.n do if i<>j then
      for k:= 1 to d.n do if (k<>i) and (k<>j) then
        d.cell[j,k]:= outside(inside(d.cell[j,i],d.cell[i,k]),d.cell[j,k]);
End;
{---------------------------------------------------------------------------}
End.

