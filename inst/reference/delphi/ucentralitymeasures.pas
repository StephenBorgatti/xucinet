unit ucentralitymeasures;
interface
uses
  comctrls,
  ucommon, utadjlist, utefficientadjlist, utsvec, utivec;

function CalcOutK_LocalEigenvector(v:tsvec; d:tadjlist; k:integer=2): boolean;
function CalcInK_LocalEigenvector(v:tsvec; d:tadjlist; k:integer=2): boolean;
function CalcInDegree(v:tsvec; d:tadjlist): boolean;
function CalcWtdInDegree(v:tsvec; d:tadjlist; wt:tsvec): boolean;
procedure brandesbetweenness(cb:tsvec; edge:tadjlist; progress:tprogressbar=nil);

implementation

function CalcOutK_LocalEigenvector(v:tsvec; d:tadjlist; k:integer=2): boolean;
{compute k-local out-eigenvectors -- just iterated degree}
Label cleanup;
Var
  oldv: array of extended;
  x: extended;
  kk,n,i,j: integer;
Begin
  try
  n:= d.nr;
  error:= 1;
  setlength(oldv,n+1);
  for i:= 1 to n do v.cell[i]:= 1;
  for kk:= 1 to k do begin
    for i:= 1 to n do oldv[i]:= v.cell[i];
    for i:= 1 to n do begin
      x:= 0;
      for j:= 1 to d.cell[i][0] do x:= x + oldv[d.cell[i,j]];
      v[i]:= x;
      end;
    end;
  error:= 0;
  cleanup:
  finally
    result:= error = 0;
    oldv:= nil;
  end;
  End;
{---------------------------------------------------------------------------}
function CalcInK_LocalEigenvector(v:tsvec; d:tadjlist; k:integer=2): boolean;
{compute k-local in-eigenvectors -- just iterated indegree}
Var
  oldv: array of extended;
  kk,n,i,j: integer;
Begin
  try
  n:= d.nr;
  error:= 1;
  setlength(oldv,n+1);
  for i:= 1 to n do v.cell[i]:= 1;
  for kk:= 1 to k do begin
    for i:= 1 to n do oldv[i]:= v.cell[i];
    v.zerofill;
    for i:= 1 to n do
      for j:= 1 to d.cell[i][0] do
        v.cell[d.cell[i,j]]:= v.cell[d.cell[i,j]] + oldv[i];
    end;
  error:= 0;
  finally
    result:= error = 0;
    oldv:= nil;
  end;
  End;
{---------------------------------------------------------------------------}
function CalcInDegree(v:tsvec; d:tadjlist): boolean;
Var
  n,i,j: integer;
Begin
  try
  n:= d.nr;
  error:= 1;
  v.zerofill;
  for i:= 1 to n do
    for j:= 1 to d.cell[i][0] do
      v.cell[d.cell[i,j]]:= v.cell[d.cell[i,j]] + 1;
  error:= 0;
  finally
    result:= error = 0;
  end;
  End;
{---------------------------------------------------------------------------}
function CalcWtdInDegree(v:tsvec; d:tadjlist; wt:tsvec): boolean;
Var
  n,i,j: integer;
Begin
  try
  n:= d.nr;
  error:= 1;
  v.zerofill;
  for i:= 1 to n do
    for j:= 1 to d.cell[i][0] do
      v.cell[d.cell[i,j]]:= v.cell[d.cell[i,j]] + wt.cell[i];
  error:= 0;
  finally
    result:= error = 0;
  end;
  End;
{---------------------------------------------------------------------------}
procedure brandesbetweenness(cb:tsvec; edge:tadjlist; progress:tprogressbar=nil);
label cleanup;
var
  d: array of integer;
  del,sig: array of double;
  p: tefficientadjlist;
  st: tistack;
  q: tiqueue;
  nvert,i,v,w,s: integer;
begin
  try
  error:= 1;
  st:= tistack.create;
  q:= tiqueue.create;
  nvert:= edge.nr;
  p:= tefficientadjlist.create;
  if not p.allocsize(nvert) then goto cleanup;
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  if not st.allocsize(nvert) then goto cleanup;
  if not q.allocsize(nvert) then goto cleanup;
  if not cb.hasval then if not cb.allocsize(nvert) then goto cleanup;
  cb.zerofill;
  if progress <> nil then begin
    progress.max:= nvert;
    progress.position:= 0;
    end;
  for s:= 1 to nvert do begin
    if progress <> nil then if s mod 1000 = 0 then progress.stepby(1000);
    st.empty;
    for i:= 1 to nvert do p.cell[i][0]:= 0;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge[v,0] do begin
        w:= edge.cell[v,i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          p.qaddarc(w,v);
          end;
        end;
      end;
    for i:= 1 to nvert do del[i]:= 0;
    while not st.isempty do begin
      w:= st.pop;
      for i:= 1 to p.cell[w][0] do
        del[p.cell[w][i]]:= del[p.cell[w][i]] + (sig[p.cell[w][i]]/sig[w])*(1.0+del[w]);
      if w <> s then cb.cell[w]:= cb.cell[w] + del[w];
      end;
    end;
//  for i:= 1 to nvert do cb.cell[i]:= cb.cell[i]/2.0;
  if progress <> nil then progress.position:= 0;
  error:= 0;
  cleanup:
  finally
    del:= nil; d:= nil; sig:= nil;
    p.destroy;
    st.free; q.free;
  end;
//        v:= p.cell[w][i];
//        del[v]:= del[v] + (sig[v]/sig[w])*(1.0+del[w]);
end;
{---------------------------------------------------------------------------}
end.
