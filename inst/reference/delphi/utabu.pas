unit utabu;

interface
uses
    Forms,Waiting,Dialogs,
    ucommon, ugeneral,uvector,ubmatrix,usmatrix, 
    utivec, utsmat, utimat, utdmat,
    ucan;
type
  tabufunc = function(var p:ivector; ptr:pointer; var break:smallint): single;
  tabufunc2 = function(p:tivec; ptr:pointer; var break:smallint): double;
  tabufunc3 = function(p:tivec; ptr:pointer; var break:smallint): double of object;
{---------------------------------------------------------------------------}
function fasttabus(var bestp:ivector; var bestf:single; mincost:single;
  n,nv,maxit,penalty:smallint; costof:tabufunc; ptr:pointer): smallint;
function tabus(var bestp:ivector; var bestf:single; mincost:single;
  n,nv,maxit,penalty:smallint; costof:tabufunc; ptr:pointer): smallint; overload;
function tabus(bestp:tivec; var bestf:double; mincost:double;
  n,nv,maxit,penalty:integer; costof:tabufunc2; ptr:pointer): smallint; overload;
function tabus(bestp:tivec; var bestf:double; mincost:double;
  n,nv,maxit,penalty:integer; costof:tabufunc3; ptr:pointer): smallint; overload;
{---------------------------------------------------------------------------}
implementation
{---------------------------------------------------------------------------}
function fasttabus(var bestp:ivector; var bestf:single; mincost:single;
  n,nv,maxit,penalty:smallint; costof:tabufunc; ptr:pointer): smallint;
{prevents solutions with less than nv blocks}
{program assumes P and BESTP are smallint vectors...}
label cleanup,top;
var
  size,p,rj: ivector;
  rd: svector;
  d: smatrix;
  dok: bmatrix;
  currentcost,bd: single;
  err,bi,oj,bj: smallint;
  r,i,j: smallint;
  change: boolean;

  procedure getnext(var bd:single; var bi,oj,bj: smallint);
  var
    i,j: smallint;
  begin
    bd:= maxfloat; bi:= 1; {oj:= p.cell^[j]}oj:= p.cell^[1]; bj:= 1;
    for i:= 1 to n do
        for j:= 1 to nv do
            if (size.cell^[j] > 1) then
                if (dok.cell^[i]^[j] = 0) and (p.cell^[i] <> j) then
                    if d.cell^[i]^[j] < bd then begin
                        bd:= d.cell^[i]^[j];
                        bi:= i;
                        oj:= p.cell^[i];
                        bj:= j;
                    end;
  end;

  function deltacost(i,j:smallint; currentcost:single): single;
  var
    temp: smallint;
  begin
    temp:= p.cell^[i]; p.cell^[i]:= j;
    deltacost:= costof(p,ptr,err) - currentcost;
    p.cell^[i]:= temp;
  end;

  procedure initializeD;
  label cleanup,next;
  var
    i,j: smallint;
    nzero: smallint;
  begin
    currentcost:= costof(p,ptr,err);
    if err<>0 then goto cleanup;
    size.zerofill;
    for i:= 1 to n do
        if p.cell^[i] > 0 then inc(size.cell^[p.cell^[i]]);
    nzero:= 0;
    for i:= 1 to nv do
        if size.cell^[i] = 0 then inc(nzero);
    if (nzero > 0) and (n > nv) then begin
        for j:= 1 to nv do
            if size.cell^[j] = 0 then begin
                for i:= 1 to n do
                    if size.cell^[p.cell^[i]] > 1 then begin
                        p.cell^[i]:= j; goto next;
                    end;
            next:
            end;
        size.zerofill;
        for i:= 1 to n do inc(size.cell^[p.cell^[i]]);
    end;
    for i:= 1 to n do begin
        rd.cell^[i]:= maxfloat; rj.cell^[i]:= 0;
    end;
    for i:= 1 to n do
        if size.cell^[p.cell^[i]] > 1 then
            for j:= 1 to nv do
                if j <> p.cell^[i] then begin
                    d.cell^[i]^[j]:= deltacost(i,j,currentcost);
                    if err<>0 then goto cleanup;
                    if d.cell^[i]^[j] < rd.cell^[i] then begin
                        rd.cell^[i]:= d.cell^[i]^[j]; rj.cell^[i]:= j;
                    end;
                end;
  cleanup:
  end;

  procedure updateD(bi,oj,bj:smallint);
  label cleanup;
  var
    i,j: smallint;
  begin
    for i:= 1 to n do
        if (p.cell^[i] = oj) or (p.cell^[i] = bj) then begin
            for j:= 1 to nv do
                d.cell^[i]^[j]:= deltacost(i,j,currentcost);
        end;
    if err<>0 then goto cleanup;
    for i:= 1 to n do begin
        d.cell^[i]^[oj]:= deltacost(i,oj,currentcost);
        if err<>0 then goto cleanup;
    end;
    for i:= 1 to n do begin
        d.cell^[i]^[bj]:= deltacost(i,bj,currentcost);
        if err<>0 then goto cleanup;
    end;
  cleanup:
  end;

begin
  err:=0;
  p:= sivector.create; d:= smatrix.create; dok:= bmatrix.create;
  rd:= svector.create; rj:= sivector.create; size:= sivector.create;
  if p.allocsize(n) <> 0 then goto cleanup;
  if rd.allocsize(n) <> 0 then goto cleanup;
  if rj.allocsize(n) <> 0 then goto cleanup;
  if size.allocsize(nv) <> 0 then goto cleanup;
  if d.allocsize(n,nv) <> 0 then goto cleanup;
  if dok.allocsize(n,nv) <> 0 then goto cleanup;

  change:= false;
  r:= maxit;
  move(bestp.cell^,p.cell^,n*2);
  bestf:= maxfloat;
  if nv = 1 then begin
      bestf:= costof(p,ptr,err);
      goto cleanup;
  end;
  for i:= 1 to n do
      if (p.cell^[i] < 1) or (p.cell^[i] > nv) then begin
            MessageDlg('ERROR: Starting partition in TABU procedure is invalid.'
                               , mtError, [mbOK], 0);
            goto cleanup;
      end;
  initializeD;
  if err<>0 then goto cleanup;
  if currentcost < mincost then begin
      bestf:= currentcost; goto cleanup;
  end;
top:
  getnext(bd,bi,oj,bj);
  if bd >= 0.0 then dok.cell^[bi]^[oj]:= penalty;
  p.cell^[bi]:= bj;
  currentcost:= costof(p,ptr,err);
  if err<>0 then goto cleanup;
  dec(size.cell^[oj]); inc(size.cell^[bj]);
  if size.cell^[oj] <= 0 then MessageDlg('ERROR. ', mtError, [mbOK], 0);
  if size.cell^[bj] <= 0 then MessageDlg('ERROR. ', mtError, [mbOK], 0);
  // p.tbl; size.tbl;
  updateD(bi,oj,bj);
  if err<>0 then goto cleanup;
  if currentcost < bestf then begin
      bestf:= currentcost;
      move(p.cell^,bestp.cell^,n*2);
      change:= true;
  end;
  if currentcost < mincost then goto cleanup;
  dec(r);
  for i:= 1 to n do
      for j:= 1 to nv do
          if dok.cell^[i]^[j] > 0 then dec(dok.cell^[i]^[j]);
  if r > 0 then goto top;
  if change then begin
      change:= false; r:= maxit;
      goto top;
  end;
cleanup:
  dok.free;
  d.free;
  size.free;
  rj.free;
  rd.free;
  p.free;
  fasttabus:= err;
end;
{---------------------------------------------------------------------------}
function tabus(var bestp:ivector; var bestf:single; mincost:single;
  n,nv,maxit,penalty:smallint; costof:tabufunc; ptr:pointer): smallint; overload;
{prevents solutions with less than nv blocks}
{program assumes P and BESTP are smallint vectors...}
label cleanup,top;
var
  err: smallint;
  size,p: ivector;
  d: smatrix;
  dok: bmatrix;
  currentcost,bd: extended;
  bi,oj,bj: smallint;
  r,i,j: smallint;
  change: boolean;

  procedure getnext(var bd:extended; var bi,oj,bj: smallint);
  var
    i,j: smallint;
  begin
    bd:= maxfloat; bi:= 1; oj:= p.cell^[1]; bj:= p.cell^[1];
    for i:= 1 to n do
        if size.cell^[p.cell^[i]] > 1 then
            for j:= 1 to nv do begin
                if (dok.cell^[i]^[j] = 0) and (p.cell^[i] <> j) and
                   (d.cell^[i]^[j] <= bd) then begin
                     bd:= d.cell^[i]^[j]; bi:= i; oj:= p.cell^[i]; bj:= j;
                end;
            end;
  end;

  function deltacost(i,j:smallint; currentcost:single): single;
  var
    temp: smallint;
  begin
    if size.cell^[p.cell^[i]] < 2 then begin deltacost:= bna; exit; end;
    temp:= p.cell^[i]; p.cell^[i]:= j;
    deltacost:= costof(p,ptr,err) - currentcost;
    p.cell^[i]:= temp;
  end;

  procedure initializeD;
  label cleanup,next;
  var
    i,j: smallint;
    nzero: smallint;
  begin
    currentcost:= costof(p,ptr,err);
    if err<>0 then goto cleanup;
    size.zerofill;
    for i:= 1 to n do
        if p.cell^[i] > 0 then inc(size.cell^[p.cell^[i]]);
    nzero:= 0;
    for i:= 1 to nv do
        if size.cell^[i] = 0 then inc(nzero);
    if (nzero > 0) and (n > nv) then begin
        for j:= 1 to nv do
            if size.cell^[j] = 0 then begin
                for i:= 1 to n do
                    if size.cell^[p.cell^[i]] > 1 then begin
                        p.cell^[i]:= j; goto next;
                    end;
            next:
            end;
        size.zerofill;
        for i:= 1 to n do inc(size.cell^[p.cell^[i]]);
    end;
    for i:= 1 to n do
        for j:= 1 to nv do
            if j = p.cell^[i] then
                d.cell^[i]^[j]:= 0
            else
                d.cell^[i]^[j]:= deltacost(i,j,currentcost);
  cleanup:
  end;

  procedure updateD(bi,oj,bj:smallint);
  var
    i,j: smallint;
  begin
    for i:= 1 to n do
        for j:= 1 to nv do
            if j = p.cell^[i] then
                d.cell^[i]^[j]:= 0
            else
                d.cell^[i]^[j]:= deltacost(i,j,currentcost);
  end;

begin
  err:=0;
  p:= ivector.create; d:= smatrix.create; dok:= bmatrix.create; size:= ivector.create;
  if p.allocsize(n) <> 0 then goto cleanup;
  if size.allocsize(nv) <> 0 then goto cleanup;
  if d.allocsize(n,nv) <> 0 then goto cleanup;
  if dok.allocsize(n,nv) <> 0 then goto cleanup;

  {InterruptDlg.Show;}
  change:= false; r:= maxit; p.copy(bestp);
  bestf:= maxfloat;
  if nv = 1 then begin
      bestf:= costof(p,ptr,err);
      goto cleanup;
  end;
  for i:= 1 to n do
      if (p.cell^[i] < 1) or (p.cell^[i] > nv) then begin
          MessageDlg('ERROR: Starting partition in TABU procedure is invalid.'
                               , mtError, [mbOK], 0);
      goto cleanup;
  end;
  initializeD;
  if err<>0 then goto cleanup;
  if currentcost < mincost then begin
      bestf:= currentcost; goto cleanup;
  end;
top:
{  Application.ProcessMessages;
  if InterruptTest then goto cleanup;}
  getnext(bd,bi,oj,bj);
  if err<>0 then goto cleanup;
  if bd >= 0.0 then dok.cell^[bi]^[oj]:= penalty;
  p.cell^[bi]:= bj;
  currentcost:= costof(p,ptr,err);
  if err<>0 then goto cleanup;
  size.zerofill;
  for i:= 1 to n do
      if p.cell^[i] > 0 then inc(size.cell^[p.cell^[i]]);
  if size.cell^[oj] <= 0 then MessageDlg('ERROR. ', mtError, [mbOK], 0);
  if size.cell^[bj] <= 0 then MessageDlg('ERROR. ', mtError, [mbOK], 0);
  updateD(bi,oj,bj);
  if err<>0 then goto cleanup;
  if currentcost < bestf then begin
      bestf:= currentcost;
      bestp.copy(p);
      change:= true;
  end;
  if currentcost < mincost then goto cleanup;
  dec(r);
  for i:= 1 to n do
      for j:= 1 to nv do
          if dok.cell^[i]^[j] > 0 then dec(dok.cell^[i]^[j]);
  if r > 0 then goto top;

  if change then begin
      change:= false; r:= maxit;
      goto top;
  end;
cleanup:
  {InterruptDlg.Close;}
  dok.free;
  d.free;
  size.free;
  p.free;
  tabus:= err;
end;
{---------------------------------------------------------------------------}
function tabus(bestp:tivec; var bestf:double; mincost:double;
  n,nv,maxit,penalty:integer; costof:tabufunc2; ptr:pointer): smallint; overload;
{prevents solutions with less than nv blocks}
{program assumes P and BESTP are integer vectors...}
{assumes bestp has values 1 to nv}
label cleanup,top;
var
  err: smallint;
  size,p: tivec;
  d: tdmat;
  dok: timat;
  currentcost,bd: extended;
  bi,oj,bj: integer;
  r,i,j: integer;
  change: boolean;

  procedure getnext(var bd:extended; var bi,oj,bj: integer);
  var
    i,j: integer;
  begin
    bd:= maxfloat; bi:= 1; oj:= p.cell[1]; bj:= p.cell[1];
    for i:= 1 to n do
      for j:= 1 to nv do begin
        if (dok.cell[i,j] = 0) and (p.cell[i] <> j) and
           (d.cell[i,j] <= bd) then begin
             bd:= d.cell[i,j];
             bi:= i; //which node to move
             oj:= p.cell[i]; //current group
             bj:= j; //new group
             end;
           end;
  end;

  function deltacost(i,j:integer; currentcost:single): double;
  var
    temp: integer;
  begin
    if size.cell[p.cell[i]] < 2
      then begin deltacost:= 2*currentcost; exit; end;
    temp:= p.cell[i]; p.cell[i]:= j;
    deltacost:= costof(p,ptr,err) - currentcost;
    p.cell[i]:= temp;
  end;

  procedure initializeD;
  label cleanup,next;
  var
    i,j: integer;
    nzero: integer;
  begin
    currentcost:= costof(p,ptr,err);
    if err<>0 then goto cleanup;
    size.zerofill;
    for i:= 1 to n do
        if p.cell[i] > 0 then inc(size.cell[p.cell[i]]);
    nzero:= 0;
    for i:= 1 to nv do
        if size.cell[i] = 0 then inc(nzero);
    if (nzero > 0) and (n > nv) then begin
        for j:= 1 to nv do
            if size.cell[j] = 0 then begin
                for i:= 1 to n do
                    if size.cell[p.cell[i]] > 1 then begin
                        p.cell[i]:= j; goto next;
                    end;
            next:
            end;
        size.zerofill;
        for i:= 1 to n do inc(size.cell[p.cell[i]]);
    end;
    for i:= 1 to n do
      for j:= 1 to nv do
        if j = p.cell[i]
        then d.cell[i,j]:= 0
        else d.cell[i,j]:= deltacost(i,j,currentcost);
  cleanup:
  end;

  procedure updateD(bi,oj,bj:integer);
  var
    i,j: integer;
  begin
    for i:= 1 to n do
      for j:= 1 to nv do
        if j = p.cell[i]
          then d.cell[i,j]:= 0
          else d.cell[i,j]:= deltacost(i,j,currentcost);
  end;

begin
  err:=0;
  p:= tivec.create;
  d:= tdmat.create;
  dok:= timat.create;
  size:= tivec.create;
  if cant(p.allocsize(n)) then goto cleanup;
  if cant(size.allocsize(nv)) then goto cleanup;
  if cant(d.allocsize(n,nv)) then goto cleanup;
  if cant(dok.allocsize(n,nv)) then goto cleanup;

  {InterruptDlg.Show;}
  change:= false; r:= maxit;
//  p.copy(bestp);
//  bestp.renumber();
  for i:= 1 to n do p.cell[i]:= bestp.cell[i];
  bestf:= maxfloat;
  if nv = 1 then begin
      bestf:= costof(p,ptr,err);
      goto cleanup;
  end;
  for i:= 1 to n do
    assert((p.cell[i] >= 1) and (p.cell[i] <= nv),
      'ERROR: Starting partition in TABU procedure contains invalid values.');
  initializeD;
  if err<>0 then goto cleanup;
  if currentcost < mincost then begin
      bestf:= currentcost; goto cleanup;
  end;
top:
  getnext(bd,bi,oj,bj);
  if err<>0 then goto cleanup;
  if bd >= 0.0 then dok.cell[bi,oj]:= penalty;
  if size.cell[oj] > 0
    then p.cell[bi]:= bj;
  currentcost:= costof(p,ptr,err);
  if err<>0 then goto cleanup;
  size.zerofill;
  for i:= 1 to n do
      if p.cell[i] > 0 then inc(size.cell[p.cell[i]]);
  if size.cell[oj] <= 0 then MessageDlg('ERROR. ', mtError, [mbOK], 0);
  if size.cell[bj] <= 0 then MessageDlg('ERROR. ', mtError, [mbOK], 0);
  updateD(bi,oj,bj);
  if err<>0 then goto cleanup;
  if currentcost < bestf then begin
      bestf:= currentcost;
//      bestp.copy(p);
      for i:= 1 to n do bestp.cell[i]:= p.cell[i];
      change:= true;
  end;
  if currentcost < mincost
    then begin bestf:= currentcost; goto cleanup; end;
  dec(r);
  for i:= 1 to n do
    for j:= 1 to nv do
      if dok.cell[i,j] > 0 then dec(dok.cell[i,j]);
  if r > 0 then goto top;

  if change then begin
      change:= false; r:= maxit;
      goto top;
  end;
cleanup:
  {InterruptDlg.Close;}
  dok.destroy;
  d.destroy;
  size.destroy;
  p.destroy;
  tabus:= err;
end;
{---------------------------------------------------------------------------}
function tabus(bestp:tivec; var bestf:double; mincost:double;
  n,nv,maxit,penalty:integer; costof:tabufunc3; ptr:pointer): smallint; overload;
{prevents solutions with less than nv blocks}
{program assumes P and BESTP are integer vectors...}
{assumes bestp has values 1 to nv}
label cleanup,top;
var
  err: smallint;
  size,p: tivec;
  d: tdmat;
  dok: timat;
  currentcost,bd: extended;
  bi,oj,bj: integer;
  r,i,j: integer;
  change: boolean;

  procedure getnext(var bd:extended; var bi,oj,bj: integer);
  var
    i,j: integer;
  begin
    bd:= maxfloat; bi:= 1; oj:= p.cell[1]; bj:= p.cell[1];
    for i:= 1 to n do
      for j:= 1 to nv do begin
        if (dok.cell[i,j] = 0) and (p.cell[i] <> j) and
           (d.cell[i,j] <= bd) then begin
             bd:= d.cell[i,j];
             bi:= i; //which node to move
             oj:= p.cell[i]; //current group
             bj:= j; //new group
             end;
           end;
  end;

  function deltacost(i,j:integer; currentcost:single): double;
  var
    temp: integer;
  begin
    if size.cell[p.cell[i]] < 2
      then begin deltacost:= 2*currentcost; exit; end;
    temp:= p.cell[i]; p.cell[i]:= j;
    deltacost:= costof(p,ptr,err) - currentcost;
    p.cell[i]:= temp;
  end;

  procedure initializeD;
  label cleanup,next;
  var
    i,j: integer;
    nzero: integer;
  begin
    currentcost:= costof(p,ptr,err);
    if err<>0 then goto cleanup;
    size.zerofill;
    for i:= 1 to n do
        if p.cell[i] > 0 then inc(size.cell[p.cell[i]]);
    nzero:= 0;
    for i:= 1 to nv do
        if size.cell[i] = 0 then inc(nzero);
    if (nzero > 0) and (n > nv) then begin
        for j:= 1 to nv do
            if size.cell[j] = 0 then begin
                for i:= 1 to n do
                    if size.cell[p.cell[i]] > 1 then begin
                        p.cell[i]:= j; goto next;
                    end;
            next:
            end;
        size.zerofill;
        for i:= 1 to n do inc(size.cell[p.cell[i]]);
    end;
    for i:= 1 to n do
      for j:= 1 to nv do
        if j = p.cell[i]
        then d.cell[i,j]:= 0
        else d.cell[i,j]:= deltacost(i,j,currentcost);
  cleanup:
  end;

  procedure updateD(bi,oj,bj:integer);
  var
    i,j: integer;
  begin
    for i:= 1 to n do
      for j:= 1 to nv do
        if j = p.cell[i]
          then d.cell[i,j]:= 0
          else d.cell[i,j]:= deltacost(i,j,currentcost);
  end;

begin
  err:=0;
  p:= tivec.create;
  d:= tdmat.create;
  dok:= timat.create;
  size:= tivec.create;
  if cant(p.allocsize(n)) then goto cleanup;
  if cant(size.allocsize(nv)) then goto cleanup;
  if cant(d.allocsize(n,nv)) then goto cleanup;
  if cant(dok.allocsize(n,nv)) then goto cleanup;

  {InterruptDlg.Show;}
  change:= false; r:= maxit;
//  p.copy(bestp);
//  bestp.renumber();
  for i:= 1 to n do p.cell[i]:= bestp.cell[i];
  bestf:= maxfloat;
  if nv = 1 then begin
      bestf:= costof(p,ptr,err);
      goto cleanup;
  end;
  for i:= 1 to n do
    assert((p.cell[i] >= 1) and (p.cell[i] <= nv),
      'ERROR: Starting partition in TABU procedure contains invalid values.');
  initializeD;
  if err<>0 then goto cleanup;
  if currentcost < mincost then begin
      bestf:= currentcost; goto cleanup;
  end;
top:
  getnext(bd,bi,oj,bj);
  if err<>0 then goto cleanup;
  if bd >= 0.0 then dok.cell[bi,oj]:= penalty;
  if size.cell[oj] > 0
    then p.cell[bi]:= bj;
  currentcost:= costof(p,ptr,err);
  if err<>0 then goto cleanup;
  size.zerofill;
  for i:= 1 to n do
      if p.cell[i] > 0 then inc(size.cell[p.cell[i]]);
  if size.cell[oj] <= 0 then MessageDlg('ERROR. ', mtError, [mbOK], 0);
  if size.cell[bj] <= 0 then MessageDlg('ERROR. ', mtError, [mbOK], 0);
  updateD(bi,oj,bj);
  if err<>0 then goto cleanup;
  if currentcost < bestf then begin
      bestf:= currentcost;
//      bestp.copy(p);
      for i:= 1 to n do bestp.cell[i]:= p.cell[i];
      change:= true;
  end;
  if currentcost < mincost
    then begin bestf:= currentcost; goto cleanup; end;
  dec(r);
  for i:= 1 to n do
    for j:= 1 to nv do
      if dok.cell[i,j] > 0 then dec(dok.cell[i,j]);
  if r > 0 then goto top;

  if change then begin
      change:= false; r:= maxit;
      goto top;
  end;
cleanup:
  {InterruptDlg.Close;}
  dok.destroy;
  d.destroy;
  size.destroy;
  p.destroy;
  tabus:= err;
end;
{---------------------------------------------------------------------------}
{---------------------------------------------------------------------------}
End.
