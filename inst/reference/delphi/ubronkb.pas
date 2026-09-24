unit ubronkb;
interface
uses
  generics.collections, math,
  ucommon, utbmat, utsmat, utnodelist, utivec, utrows;

type
  cliquefunc2 = function(num:integer; var aclique:arrayofinteger; count:integer): integer;
{proc}
  function saveclique1(num:integer; var aclique:arrayofinteger; count:integer): integer;
  function saveclique2(num:integer; var aclique:arrayofinteger; count:integer): integer;
  function BronKerbosch(saveclique:cliquefunc2; d:tbmat; minsize:integer=3): integer; overload;
  function BronKerbosch(saveclique:cliquefunc2; d:tsmat; minsize:integer=3): integer; overload;
var
  mycliques: tnodelist; {set these in the calling routine}
  cliquesets: tbmat;
  bkcliques3: tintegerlists;

implementation

function saveclique1(num:integer; var aclique:arrayofinteger; count:integer): integer;
var i: integer;
begin
  mycliques.addrows(1);
  for i:= 1 to count do
    mycliques.egos[mycliques.nr].append(aclique[i]);
end;

function saveclique2(num:integer; var aclique:arrayofinteger; count:integer): integer;
var i: integer;
begin
  if cliquesets.allocnc < num then
    cliquesets.allocate(cliquesets.nr,num,1,true,false);
  for i:= 1 to count do
    cliquesets[i,num]:= 0;
  for i:= 1 to count do
    cliquesets[aclique[i],num]:= 1;
  cliquesets.nc:= num;
end;

function saveclique3(num:integer; var aclique:arrayofinteger; count:integer): integer;
var i: integer;
begin
  bkcliques3.nrows:= bkcliques3.nrows + 1;
  for i:= 1 to count do with bkcliques3 do
    additem(nrows,aclique[i]);
end;

function BronKerbosch(saveclique:cliquefunc2; d:tbmat; minsize:integer=3): integer;
Var
  i,n,c,num: integer;
  all,compsub,diag: arrayofinteger;

  procedure ExtendVersion2(old:arrayofinteger; ne,ce:integer);
  label btc;
  Var
    nod,fixp,newne,newce,i,j,icount,pos,p,s,sel,minnod: integer;
    knew: arrayofinteger;
  Begin
    setlength(knew,n+1);
    minnod:= ce; fixp:= 0; nod:= 0;
    {determine each counter value and look for minimum}
    for i:= 1 to ce do begin
      if (minnod = 0) then goto btc;
      p:= old[i]; icount:= 0;
      {count disconnections}
      for j:= ne+1 to ce do begin
        if (icount >= minnod) then break;
        if (d[p,old[j]] = 0) or (d[p,old[j]] = 0) then begin
          inc(icount);
          pos:= j; {save position of potential candidate}
          end;
        end;
      {test new minimum}
      if icount < minnod then begin
        fixp:= p; minnod:= icount;
        if i <= ne
          then s:= pos
          else begin s:= i; nod:= 1; end;
        end;
      end; {i}
    btc:
    for nod:= minnod + nod downto 1 do begin
        p:= old[s]; old[s]:= old[ne+1];
        sel:= p; old[ne+1]:= p;
        {fill new set not}
        newne:= 0;
        for i:= 1 to ne do
          if (d[sel,old[i]] > 0) and (d[old[i],sel] > 0)then begin
            inc(newne); knew[newne]:= old[i];
            end;
        {fill new set cand}
        newce:= newne;
        for i:= ne+2 to ce do
          if (d[sel,old[i]] > 0) and (d[old[i],sel] > 0) then begin
            inc(newce); knew[newce]:= old[i];
            end;
        {add to compsub}
        inc(c); compsub[c]:= sel;
        if newce = 0
          then if c >= minsize
            then begin inc(num); saveclique(num,compsub,c); end
            else
          else if newne < newce
            then ExtendVersion2(knew,newne,newce);
        {remove from compsub}
        dec(c);
        {add to not}
        inc(ne);
        if nod > 1 then begin {select candidate disconnected to the fixed point}
          s:= ne;
          repeat
            inc(s);
          until (s > n) or (d[fixp,old[s]] = 0);
          end;
      end;

    knew:= nil;
  End;

  Begin try
    n:= d.n; num:= 0;
    setlength(diag,n+1);
    setlength(compsub,n+1);
    setlength(all,n+1);
    for i:= 1 to n do begin
      all[i]:= i;
      diag[i]:= d[i,i];
      d[i,i]:= 1;
      end;
    c:= 0;
    ExtendVersion2(all,0,n);
    for i:= 1 to n do
      d[i,i]:= diag[i];
    finally
      diag:= nil; compsub:= nil; all:= nil;
    end;
  End;
{---------------------------------------------------------------------------}
function BronKerbosch(saveclique:cliquefunc2; d:tsmat; minsize:integer=3): integer;
Var
  i,n,c,num: integer;
  all,compsub: arrayofinteger;
  diag: arrayofsingle;

  procedure ExtendVersion2(old:arrayofinteger; ne,ce:integer);
  label btc;
  Var
    nod,fixp,newne,newce,i,j,icount,pos,p,s,sel,minnod: integer;
    knew: arrayofinteger;
  Begin
    setlength(knew,n+1);
    minnod:= ce; fixp:= 0; nod:= 0;
    {determine each counter value and look for minimum}
    for i:= 1 to ce do begin
      if (minnod = 0) then goto btc;
      p:= old[i]; icount:= 0;
      {count disconnections}
      for j:= ne+1 to ce do begin
        if (icount >= minnod) then break;
        if d.iszero(p,old[j]) or d.iszero(old[j],p) then begin
          inc(icount);
          pos:= j; {save position of potential candidate}
          end;
        end;
      {test new minimum}
      if icount < minnod then begin
        fixp:= p; minnod:= icount;
        if i <= ne
          then s:= pos
          else begin s:= i; nod:= 1; end;
        end;
      end; {i}
    btc:
    for nod:= minnod + nod downto 1 do begin
        p:= old[s]; old[s]:= old[ne+1];
        sel:= p; old[ne+1]:= p;
        {fill new set not}
        newne:= 0;
        for i:= 1 to ne do
          if (d[sel,old[i]] > 0) and (d[old[i],sel] > 0)then begin
            inc(newne); knew[newne]:= old[i];
            end;
        {fill new set cand}
        newce:= newne;
        for i:= ne+2 to ce do
          if (d[sel,old[i]] > 0) and (d[old[i],sel] > 0) then begin
            inc(newce); knew[newce]:= old[i];
            end;
        {add to compsub}
        inc(c); compsub[c]:= sel;
        if newce = 0
          then if c >= minsize
            then begin inc(num); saveclique(num,compsub,c); end
            else
          else if newne < newce
            then ExtendVersion2(knew,newne,newce);
        {remove from compsub}
        dec(c);
        {add to not}
        inc(ne);
        if nod > 1 then begin {select candidate disconnected to the fixed point}
          s:= ne;
          repeat
            inc(s);
          until (s > n) or (d[fixp,old[s]] = 0);
          end;
      end;

    knew:= nil;
  End;

  Begin try
    n:= d.n; num:= 0;
    setlength(diag,n+1);
    setlength(compsub,n+1);
    setlength(all,n+1);
    for i:= 1 to n do begin
      all[i]:= i;
      diag[i]:= d.cell[i,i];
      d[i,i]:= 1;
      end;
    c:= 0;
    ExtendVersion2(all,0,n);
    for i:= 1 to n do
      d[i,i]:= diag[i];
    finally
      diag:= nil; compsub:= nil; all:= nil;
    end;
  End;
{---------------------------------------------------------------------------}
procedure bktest(x:tbmat);
type
  tilist = tlist<integer>;
var
  c,cand,ncand: tilist;
  i: integer;

  procedure saveclique(c:tilist);
  begin
    
  end;

  procedure enum(c,cand,ncand:tilist);
  var
    v: integer;
  begin
    if (cand.count = 0) and (ncand.count = 0)
      then saveclique(c)
      else begin
        for v in cand do 
          cand.Remove(v);
        end;
  end;

  begin
    c:= tilist.create;
    cand:= tilist.create;
    ncand:= tilist.create;
    for i:= 1 to x.n do
      c.add(i);
    enum(c,cand,ncand);
  end;

end.
