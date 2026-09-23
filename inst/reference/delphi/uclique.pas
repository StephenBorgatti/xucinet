unit uCLIQUE;
interface
uses
    Waiting, Dialogs,sysutils,
    ucommon, ugeneral,ualloc,uufile,uvector,ubmatrix,udiam,
    uadjlist, utivec, usimatrix, usmatrix, ucan;
type
  cliquefunc = function(nodelist:sivector; num:longint): smallint;
  cliquefunc2 = function(nodelist:tivec): integer;
var
  cset: bmatrix;
{proc}
  function saveclique(c:ivector; num:longint): smallint;
  procedure constructoverlapmatrix(cset:bmatrix; ov:smatrix);
  Procedure nonmaximalcliques(var df:ufile; d:bmatrix; var num:longint;
    maxd,m,msgnum:smallint);
  function BronKerbosch(saveclique:cliquefunc; d:bmatrix; var num:longint;
    maxd,maxdi,minsize:integer): integer;
  function KPlex(var f:file; d:bmatrix; var num:longint;
    k,m,msgnum:integer): integer;
{---------------------------------------------------------------------------}
implementation
{---------------------------------------------------------------------------}
procedure constructoverlapmatrix(cset:bmatrix; ov:smatrix);
var
  i,j,k: integer;
begin
  for i:= 1 to cset.nr do for j:= 1 to i do begin
    ov.cell^[i]^[j]:= 0;
    for k:= 1 to cset.nc do
      if (cset.cell^[i]^[k]=1) and (cset.cell^[j]^[k]=1) then
        ov.cell^[i]^[j]:= ov.cell^[i]^[j] + 1;
    ov.cell^[j]^[i]:= ov.cell^[i]^[j];
    end;
end;
{---------------------------------------------------------------------------}
function saveclique(c:ivector; num:longint): smallint;
label cleanup;
var
  j: integer;
begin
  if num > cset.allocnc then
    if cant(cset.reallocsize(cset.nr,num*2)) then goto cleanup;
  for j:= 1 to cset.nr do cset.cell^[j]^[num]:= 0;
  for j:= 1 to c.n do
      cset.cell^[c.cell^[j]]^[num]:= 1;
  cleanup:
  result := error;
end;
{---------------------------------------------------------------------------}
  function BronKerbosch(saveclique:cliquefunc; d:bmatrix; var num:longint;
    maxd,maxdi,minsize:integer): integer;
  {d is a DISTANCE matrix. (or n/1 coded adjacency matrix)
   maxd=maximum distance allowed within clique;
   maxid=maximum distance within clique-induced subgraph}
  label cleanup,cleanup2;
  Var
    error,i,n,c: integer;
    all: arrayofinteger;  {important: if ivector, then must initialize values}
    compsub,diag: ivector;
    sg: bmatrix;

    Procedure Save;
    Var
      i,j: integer;
    Begin
      if c < minsize then exit;
      if maxdi < c then begin
         if sg.hasval then sg.dealloc;
         if sg.allocsize(c,c) <> 0 then begin
             MessageDlg('Insufficient memory: Clique too large.', mtError,
                                     [mbOK], 0);
             exit;
         end;
         for i:= 1 to c do
             for j:= 1 to c do
                 if d.cell^[compsub.cell^[i]]^[compsub.cell^[j]] = 1 then
                     sg.cell^[i]^[j]:= 1
                 else
                     sg.cell^[i]^[j]:= 0;
         if diameter(sg,false) > maxdi then exit;
      end;
      inc(num);
      compsub.n:= c;
      saveclique(compsub,num)
    End;

    Function ExtendVersion2(old:arrayofinteger; ne,ce:integer):integer;
    Label btc,newmin,look,cleanup;
    Var
      err,nod,fixp,newne,newce,i,j,icount,pos,p,s,sel,minnod: integer;
      knew: arrayofinteger;
    Begin
      err:=0;
//      knew:= ivector.create; if knew.allocsize(n) <> 0 then goto cleanup;
      setlength(knew,n+1);
      minnod:= ce; nod:= 0; fixp:= 0;
      {determine each counter value and look for minimum}
      try
      for i:= 1 to ce do begin
          if (minnod = 0) then goto btc;
          p:= old[i]; icount:= 0;
          {count disconnections}
          for j:= ne+1 to ce do begin
              if (icount >= minnod) then goto newmin;
              if d.cell^[p]^[old[j]] > maxd then begin
                  icount:= icount + 1;
                  {save position of potential candidate}
                  pos:= j;
              end;
          end;
          {test new minimum}
          newmin:
          if icount < minnod then begin
              fixp:= p; minnod:= icount;
              if i <= ne then
                   s:= pos
              else begin
                   s:= i; nod:= 1;
              end;
          end;
      end; {i}
      {back track cycle}
      btc:
      except
        showmessage(inttostr(i)+' '+inttostr(p)+' '+inttostr(minnod));
      end;
      for nod:= minnod + nod downto 1 do begin
          {interchange}
          p:= old[s]; old[s]:= old[ne+1];
          sel:= p; old[ne+1]:= p;
          {fill new set not}
          newne:= 0;
          for i:= 1 to ne do
              if d.cell^[sel]^[old[i]] <= maxd then begin
                  newne:= newne + 1; knew[newne]:= old[i];
              end;
          {fill new set cand}
          newce:= newne;
          for i:= ne+2 to ce do
              if d.cell^[sel]^[old[i]] <= maxd then begin
                  newce:= newce + 1; knew[newce]:= old[i];
              end;
          {add to compsub}
          c:= c + 1; compsub.cell^[c]:= sel;
          if newce = 0 then
              save
          else
              if newne < newce then
                  ExtendVersion2(knew,newne,newce);
          {remove from compsub}
          c:= c - 1;
          {add to not}
          ne:= ne + 1;
          if nod > 1 then begin
              {select candidate disconnected to the fixed point}
              s:= ne;
              {look for candidate}
              look:
              s:= s + 1;
              if d.cell^[fixp]^[old[s]] <= maxd then goto look;
          end;
      end; {btc}
    cleanup:
      knew:= nil;
      ExtendVersion2 := err;
    End;

  Begin
    error := 1;
    n:= d.n; sg:= bmatrix.create; diag:= sivector.create; compsub:= sivector.create; 
    if diag.allocsize(n) <> 0 then goto cleanup;
    if compsub.allocsize(n) <> 0 then goto cleanup; {set to 0}
    setlength(all,n+1);
    for i:= 1 to n do
      all[i]:= i;
    for i:= 1 to n do begin
        diag.cell^[i]:= d.cell^[i]^[i];
        d.cell^[i]^[i]:= 0;
    end;
    num:= 0; c:= 0;
    if cant(ExtendVersion2(all,0,n)) then goto cleanup2;
    for i:= 1 to n do
        d.cell^[i]^[i]:= diag.cell^[i];
    error := 0;
  cleanup2:
  cleanup:
    sg.free; diag.free; compsub.free; all:= nil;
    bronkerbosch:= error;
  End;
{---------------------------------------------------------------------------}
function BronKerbosch2(saveclique:cliquefunc2; d:simatrix; var num:longint;
    minsize:integer): integer;
label cleanup;
Var
  error,i,n: integer;
  all: tivec;  {important: if ivector, then must initialize values}
  compsub,diag: tivec;
  sg: bmatrix;

  Function ExtendVersion2(old:tivec; ne,ce:integer): integer;
  Label btc,newmin,look,cleanup;
  Var
      err,nod,fixp,newne,newce,i,j,icount,pos,p,s,sel,minnod: integer;
      knew: tivec;
  Begin
    err:=0;
    knew:= tivec.create;
    if knew.allocsize(n) then goto cleanup;
    minnod:= ce; nod:= 0; fixp:= 0;
    {determine each counter value and look for minimum}
    for i:= 1 to ce do begin
      if (minnod = 0) then goto btc;
      p:= old[i]; icount:= 0;
      {count disconnections}
      for j:= ne+1 to ce do begin
        if (icount >= minnod) then goto newmin;
        if d.cell^[p]^[old[j]] = 0 then begin
          icount:= icount + 1;
          {save position of potential candidate}
          pos:= j;
          end;
        end;
      {test new minimum}
      newmin:
      if icount < minnod then begin
        fixp:= p; minnod:= icount;
        if i <= ne
          then s:= pos
          else begin s:= i; nod:= 1; end;
        end;
      end; {i}
    {back track cycle}
    btc:
    for nod:= minnod + nod downto 1 do begin
          {interchange}
          p:= old[s]; old[s]:= old[ne+1];
          sel:= p; old[ne+1]:= p;
          {fill new set not}
          newne:= 0;
          for i:= 1 to ne do
              if d.cell^[sel]^[old[i]] = 1 then begin
                  newne:= newne + 1; knew[newne]:= old[i];
              end;
          {fill new set cand}
          newce:= newne;
          for i:= ne+2 to ce do
              if d.cell^[sel]^[old[i]] = 1 then begin
                  newce:= newce + 1; knew[newce]:= old[i];
              end;
          {add to compsub}
          compsub.append(sel);
          if newce = 0
            then saveclique(compsub)
            else if newne < newce
              then ExtendVersion2(knew,newne,newce);
          {remove from compsub}
          compsub.n:= compsub.n - 1;
          {add to not}
          ne:= ne + 1;
          if nod > 1 then begin
              {select candidate disconnected to the fixed point}
              s:= ne;
              {look for candidate}
              look:
              s:= s + 1;
              if d.cell^[fixp]^[old[s]] = 1 then goto look;
          end;
      end; {btc}
    cleanup:
      knew.destroy;
      result := err;
  End;

Begin
  n:= d.n; sg:= bmatrix.create;
  compsub:= tivec.create;
  all:= tivec.create;
  if compsub.allocsize(n) then goto cleanup; {set to 0}
  if all.allocsize(n) then goto cleanup;  {set to index value}
  for i:= 1 to n do all[i]:= i;
  if cant(ExtendVersion2(all,0,n)) then goto cleanup;
  cleanup:
    sg.free; compsub.destroy; all.destroy;
    result:= error;
  End;
{---------------------------------------------------------------------------}
  Procedure oldBronKerbosch(var df:ufile; d:bmatrix; var num:longint;
    maxd,maxdi,minsize,msgnum:smallint);
  {d is a DISTANCE matrix. (or n/1 coded adjacency matrix)
   maxd=maximum distance allowed within clique;
   maxid=maximum distance within clique-induced subgraph}
  Var
    i,n,c: smallint;
    all,compsub: intvector;
    diag: intvector;
    sg: bmatrix;

    Procedure Save;
    Var
      i,j: smallint;
      temp: bytevector;
    Begin
      if c < minsize then exit;
      if maxdi < c then begin
          if sg.allocsize(c,c) <> 0 then exit;
          for i:= 1 to c do
              for j:= 1 to c do
                  if d.cell^[compsub[i]]^[compsub[j]] = 1 then
                      sg.cell^[i]^[j]:= 1;
          if diameter(sg,true) > maxdi then exit;
      end;
      inc(num);
      {if msgnum > 0 then}
          {if num mod msgnum = 0 then write(num:4);}
      fillchar(temp,n,0);
      for i:= 1 to c do
          temp[compsub[i]]:= 1;
      blockwrite(df.uf,temp,n);
    End;

    Procedure ExtendVersion2(old:intvector; ne,ce:smallint);
    Label btc,newmin,look;
    Var
      nod,fixp,newne,newce,i,j,icount,pos,p,s,sel,minnod: smallint;
      knew: intvector;

    Begin
      minnod:= ce; nod:= 0; fixp:= 0;
      {determine each counter value and look for minimum}
      for i:= 1 to ce do begin
          if (minnod = 0) then goto btc;
          p:= old[i]; icount:= 0;
          {count disconnections}
          for j:= ne+1 to ce do begin
              if (icount >= minnod) then goto newmin;
              if d.cell^[p]^[old[j]] > maxd then begin
                 icount:= icount + 1;
                 {save position of potential candidate}
                 pos:= j;
              end;
          end;
          {test new minimum}
          newmin:
          if icount < minnod then begin
             fixp:= p; minnod:= icount;
             if i <= ne then s:= pos else begin s:= i; nod:= 1; end;
          end;
      end; {i}
      {back track cycle}
      btc:
      for nod:= minnod + nod downto 1 do begin
          {interchange}
          p:= old[s]; old[s]:= old[ne+1];
          sel:= p; old[ne+1]:= p;
          {fill new set not}
          newne:= 0;
          for i:= 1 to ne do
              if d.cell^[sel]^[old[i]] <= maxd then begin
                  newne:= newne + 1; knew[newne]:= old[i];
              end;
          {fill new set cand}
          newce:= newne;
          for i:= ne+2 to ce do
              if d.cell^[sel]^[old[i]] <= maxd then begin
                  newce:= newce + 1; knew[newce]:= old[i];
              end;
          {add to compsub}
          c:= c + 1; compsub[c]:= sel;
          if newce = 0 then
              save
          else
              if newne < newce then ExtendVersion2(knew,newne,newce);
          {remove from compsub}
          c:= c - 1;
          {add to not}
          ne:= ne + 1;
          if nod > 1 then begin
             {select candidate disconnected to the fixed point}
             s:= ne;
             {look for candidate}
             look:
             s:= s + 1;
             if d.cell^[fixp]^[old[s]] <= maxd then goto look;
          end;
      end; {btc}
    End;

  Begin
    n:= d.n; sg:= bmatrix.create;
    for i:= 1 to n do begin
        diag[i]:= d.cell^[i]^[i]; d.cell^[i]^[i]:= 0;
    end;
    for i:= 1 to n do
        all[i]:= i;
    fillchar(compsub,n*ssi,0);
    num:= 0;
    c:= 0; ExtendVersion2(all,0,n);
    for i:= 1 to n do
        d.cell^[i]^[i]:= diag[i];
    sg.free;
    {if msgnum > 0 then writeln;}
  End;
{---------------------------------------------------------------------------}
  Procedure nonmaximalcliques(var df:ufile; d:bmatrix; var num:longint;
    maxd,m,msgnum:smallint);
  {Algorithm by Borgatti }
  {Coding by Borgatti 1990}
  {maxd=maximum distance allowed within clique}
  Var
    n: smallint;
    temp,clique: bytevector;

    function isclique(p,lev:smallint): boolean;
    var
      i: smallint;
    begin
      isclique:= false;
      clique[lev]:= p;
      if lev > 1 then
         for i:= 1 to lev-1 do
             if d.cell^[clique[i]]^[p] > maxd then exit;
      isclique:= true;
    end;

    Procedure Loop(next,lev:smallint);
    Var i,j: smallint;
    Begin
      inc(lev); inc(next);
      if lev <= n then
         for i:= next to n do
             if isclique(i,lev) then begin
                 if (lev >= m) then begin
                     inc(num);
                     {if msgnum > 0 then}
                         {if num mod msgnum = 0 then write(' ',num);}
                     fillchar(temp,n,0);
                     for j:= 1 to lev do temp[clique[j]]:= 1;
                     blockwrite(df.uf,temp,n);
                 end;
             loop(i,lev);
             end;
    End;

  begin
    n:= d.n;
    num:= 0; loop(0,0);
    {if msgnum > 0 then writeln;}
  end;
{---------------------------------------------------------------------------}
  function KPlex(var f:file; d:bmatrix; var num:longint;
    k,m,msgnum:integer): integer;
  {Algorithm by Borgatti & Everett 1990)}
  {Coding by Borgatti 1990}
  label
    cleanup;
  Var
    merr,n,found: integer;
    temp: bvector;
    absent,plex: ivector;
    present: blvector;

    function iskplex(p,lev:integer): boolean;
    var
      i,j,t: integer;
    begin
      iskplex:= false;
      plex.cell^[lev]:= p;
      if lev > 2 then
          for i:= 1 to lev do begin
              t:= 0;
              for j:= 1 to lev do
                  if i<>j then
                      if d.cell^[plex.cell^[i]]^[plex.cell^[j]] > 0 then inc(t);
              if t < lev-k then exit;
          end;
      iskplex:= true;
    end;

    function oldisnew(lev:integer): boolean;
    var
      b,i: integer;

        procedure doit(a,p:integer);
        begin
          while a < p do begin
            inc(b); absent.cell^[b]:= a; inc(a);
            end;
        end;

    begin
      oldisnew:= false; b:= 0;
      doit(1,plex.cell^[1]);
      if lev > 1 then
          for i:= 2 to lev do
              doit(plex.cell^[i-1]+1,plex.cell^[i]);
      if b > 0 then
          for i:= 1 to b do
              if iskplex(absent.cell^[i],lev+1) then exit;
      oldisnew:= true;
    end;

    function isnew(lev:integer): boolean;
    var
      i: integer;
    begin
      isnew:= false;
      present.zerofill;
      for i:= 1 to lev do
          present.cell^[plex.cell^[i]]:= true;
      for i:= 1 to {lev} n do
          if not present.cell^[i] then
              if iskplex(i,lev+1) then exit;
      isnew:= true;
    end;

    function Loop(next,lev:integer):integer;
    Var err,i,j: integer;
    label cleanup;
    Begin
      err := 0;
      inc(lev); inc(next);
      if lev <= n then begin
          for i:= next to n do begin
              if err = 0 then begin
                  if iskplex(i,lev) then begin
                      found:= lev;
                      loop(i,lev);
                      if (found = lev) and (lev >= m) and isnew(lev) then begin
                          inc(num); plex.n:= lev;
                          saveclique(plex,num);
                          end;
                  end;
              end;
          end;
      end;
    cleanup:
      loop := err;
    End;

  begin
    merr := 1;
    temp:= bvector.create; present:= blvector.create; absent:= sivector.create; plex:= sivector.create;
    n:= d.n;
    if temp.allocsize(n) <> 0 then goto cleanup;
    if present.allocsize(n) <> 0 then goto cleanup;
    if absent.allocsize(n) <> 0 then goto cleanup;
    if plex.allocsize(n) <> 0 then goto cleanup;
    num:= 0;
    if cant(loop(0,0)) then goto cleanup;
    merr := 0;
  cleanup:
    WaitingEnd;
    temp.free; present.free; absent.free; plex.free;
    KPlex:= merr;
  end;
{---------------------------------------------------------------------------}
End.