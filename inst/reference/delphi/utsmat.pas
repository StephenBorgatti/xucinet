unit utsmat;
Interface
Uses
  math, variants, {dialogs,} vcl.stdctrls, sysutils, windows, rtti, classes,
  System.IOUtils, generics.collections,
(*{$IFDEF VER150}
  variants,
{$ENDIF}*)
  ucommon,utvec,utsvec,utdvec,utmat,uufile,umath, umemory, utstrvec,
  utivec, ustring, utgeneric, usys, utunivariate;
Type
  tcharacter = record
    square, onemode, valued, symmetric: boolean;
    end;
  tsmat = class(tmat)
    cell: arrayofarrayofsingle;
    constructor create;
//    destructor destroy; override;
    function allocate(xnr,xnc,xnm:integer; setsize,zfill:boolean):boolean; override;
    function allocateifneeded(xnr,xnc:integer; setsize:boolean=true;
         autofill:boolean=true; fill:single=0.0): boolean;
    function allocateonly(xnr,xnc:integer):boolean; override;
    function getaverage(diagok:boolean=false): double;
    function characterize: tcharacter;
    function copyval(m:tmat): boolean; override;
    function copyvaldsl(m:tmat): boolean; override;
    function copyvaltransposed(m:tsmat): boolean;
    function copyvalues(m:tsmat): boolean;
    function fget(i,j:integer): extended; override;
    function findcol(s:string): integer;
    function findrow(s:string): integer;
    function getcolsum(j:integer; diagok:boolean=false): double; override;
    function getrowsum(i:integer; diagok:boolean=true): double; override;
    function getsum(diagok:boolean=true): double;
    function getvalue(i,j:integer): single;
    function getvbrn(rname:string; j:integer): variant; override;
    function getvbcn(i:integer; cname:string): variant; override;
    function hasna(sym:boolean=false; diagok:boolean=false): boolean;
    function iget(i,j:integer): longint; override;
    function isna(i,j:integer): boolean; override;
    function IsSymmetric(ignorena:boolean=false): boolean; override;
    function istie(i,j:integer; op:integer=0; cut:double=0.0): boolean;
    function isvalid(i,j:integer): boolean; override;
    function isvaliddiag(i,j:integer; diagok:boolean): boolean;
    function isvalued(diagok:boolean=false):boolean; override;
    function iszero(i,j:integer): boolean; override;
    function loadmat(f:ufile): boolean; override;
    function mptr: pointer; override;
    function product(a,b:tmat; diagok:boolean=true): boolean; override;
    function removenegatives(diagok:boolean=false): longint;
    function rowsum(i:integer; diagok:boolean=true): double; override;
    function rptr(i:integer): pointer; override;
    function sameas(i1,j1,i2,j2:integer): boolean;
    function savemat(f:ufile): boolean; override;
    function savematdsl(f:ufile): boolean; override;
    function sget(i,j:integer): string; override;
    function transposeof(t:tsmat): boolean;
    function vget(i,j:integer): variant; override;
    function wholenumbers: boolean;
    function trygetvalue(i,j:integer; var x:single): boolean;
    procedure add(x:tmat);
    procedure appendrows(x:tmat); override;
    procedure appendcols(m2:tmat);
    procedure copycell(toi,toj,fromi,fromj:integer); override;
    procedure copyfrom(x:tsmat; toi,toj,fromi,fromj:integer); overload;
    procedure copycoltoarrayofsingle(arr:arrayofsingle; c:integer);
    procedure deallocate; override;
    procedure deletecols(cols: tlist<integer>); override;
    procedure deleterows(rows: tlist<integer>); override;
    procedure displaytomemo(memo1:tmemo);
    procedure faddto(i,j:integer; x:extended); override;
    procedure faddtona(i,j:integer; x:extended); override;
    procedure fillcol(j:integer; x:single; diagok:boolean=false);
    procedure fillrect(r1,c1,r2,c2:integer; f:integer=0); overload; override;
    procedure fillrect(r1,c1,r2,c2:integer; f:single=0); overload; override;
    procedure fillrow(i:integer; x:single; repna:boolean; diagok:boolean=false);
    procedure floydn;
    procedure floyd;
    procedure fput(i,j:integer; x:extended; e:extended=0); override;
    procedure getmarginals(r,c:tdvec; diagok:boolean=false); override;
    procedure iaddto(i,j:integer; x:integer); override;
    procedure incmean(i,j:integer; x:extended; num:integer);
    procedure iput(i,j:integer; x:longint); override;
    procedure loadrows<tfil>(f:ufile);
    procedure meancenter(diagok:boolean); override;
    procedure mirror(i,j:integer);
    procedure multbyconst(x:double);
    procedure nafill(diagok:boolean=true); override;
    procedure normrows(y:tsmat=nil; diagok:boolean=false);
    procedure normcols(y:tsmat=nil; diagok:boolean=false);
    procedure randrc(var rs:integer);
    procedure recode(op:tdichop; cut:double; newval:double; diagok:boolean=false); virtual;
    procedure reversevalues(indiag,outdiag:boolean; x:tsmat=nil);
    procedure saverows<tfil>(f:ufile);
    procedure setvalue(i,j:integer; x:single);
    procedure setvbrn(rname:string; j:integer; x:variant); override;
    procedure setvbcn(i:integer; cname:string; x:variant); override;
    Procedure sortbyattr(v:tvec; dim:char='r'; dir:char='a');
    Procedure sortcolsbyattr(v:tvec; dir:char='a'); {override}
    procedure sortcolsbylabel(dir:char='a'); override;
    Procedure sortrcbyattr(r,c:tvec; dir:char='a'); {override}
    Procedure sortrowsbyattr(v:tvec; dir:char='a'); {override}
    procedure sortrowsbylabel(dir:char='a'); override;
    procedure swapcells(i,j,ii,jj: integer);
    procedure swaprows(a,b:integer); override;
    procedure transpose; override;
    procedure transposeviadisk;
    procedure vaddtona(i,j:integer; x:variant);
    procedure vput(i,j:integer; x:variant); override;
    procedure zerofill(diagok:boolean=true); override;
    property  value[i,j:integer]:single read GetValue write SetValue; default;
//    property vbrn[rname:string; j:integer]:single read GetVbrn write SetVbrn;
//    property vbcn[i:integer; cname:string]:single read GetVbcn write SetVbcn;
//    procedure fill(filler:double; diagok:boolean=true); override;
    end;
{===========================================================================}
Implementation
{===========================================================================}
constructor tsmat.create;
begin
  inherited create;
  cell:= nil;
  dt:= singledt;
  vmissing:= na;
end;
{---------------------------------------------------------------------------}
function tsmat.mptr: pointer;
begin result:= @cell; end;
{---------------------------------------------------------------------------}
function tsmat.product(a,b:tmat; diagok:boolean=true): boolean;
var
  i,k,j,nk, nmiss: integer;
  s: extended;
begin
  result:= a.nc = b.nr;
  if not result then begin dealloc; exit; end;
  nk:= a.nc;
  allocsize(a.nr,b.nc); zerofill;
  if not issquare then diagok:= true;
  for i:= 1 to nr do
    for j:= 1 to nc do if (i<>j) or diagok then begin
      s:= 0; nmiss:= 0;
      for k:= 1 to nk do if a.isna(i,k) or b.isna(k,j)
        then inc(nmiss)
        else s:= s + a.fget(i,k)*b.fget(k,j);
      if nmiss = nk then fput(i,j,bna) else fput(i,j,s);
      end;
  rdvn.copy(a.rdvn);
  cdvn.copy(b.cdvn);
end;
{---------------------------------------------------------------------------}
function tsmat.isvalid(i,j:integer): boolean;
begin
  result:= inrange(i,j) and (cell[i,j] < na);
end;
{---------------------------------------------------------------------------}
function tsmat.trygetvalue(i,j:integer; var x:single): boolean;
begin
  if inrange(i,j) and (cell[i,j] < na)
    then begin result:= true; x:= cell[i,j]; end
    else result:= false;
end;
{---------------------------------------------------------------------------}
function tsmat.isvaliddiag(i,j:integer; diagok:boolean): boolean;
begin
  result:= inrange(i,j) and (cell[i,j] < na) and ((i <> j) or diagok);
end;
{---------------------------------------------------------------------------}
function tsmat.getaverage(diagok:boolean=false):double;
var
  i,j: integer;
  den: int64;
begin
  if not issquare
    then diagok:= false;
  result:= 0; den:= 0;
  for i:= 1 to nr do
    for j:= 1 to nc do if ((i<>j) or diagok) and isvalid(i,j)
      then begin
        inc(den);
        result:= result + cell[i,j];
      end;
  if den = 0
    then result:= bna
    else result:= result/den;
end;
{---------------------------------------------------------------------------}
function tsmat.characterize: tcharacter;
begin

end;
{---------------------------------------------------------------------------}
function tsmat.IsSymmetric(ignorena:boolean=false): boolean;
//missing values do not count toward asymmetry if ignorena = true
var i,j: integer;
begin
  if not issquare then exit(false);
  if ignorena
    then begin
      for i:= 2 to nr do for j:= 1 to i-1 do
        if (cell[i,j] < na) and (cell[i,j] < na) then
          if not samevalue(cell[i,j],cell[j,i],singleprecision)
            then exit(false);
      end
    else begin
      for i:= 2 to nr do for j:= 1 to i-1 do
        if not samevalue(cell[i,j],cell[j,i],singleprecision)
          then exit(false);
      end;
  result:= true;
end;
{---------------------------------------------------------------------------}
function tsmat.isvalued(diagok:boolean=false): boolean;
var
  i,j: integer;
begin
  result:= true;
  if not issquare then diagok:= true;
  for i:= 1 to nr do
    for j:= 1 to nc do if (i<>j) or diagok then
      if isvalid(i,j) then
        if fneq(cell[i,j],1.0) and fneq(cell[i,j],0.0) then exit;
  result:= false;
end;
{---------------------------------------------------------------------------}
function tsmat.rptr(i:integer): pointer;
begin
  result:= @cell[i][1];
end;
{---------------------------------------------------------------------------}
procedure tsmat.deallocate;
var
  i: integer;
begin
  try
  cell:= nil;
  (*
  if assigned(cell) then begin
    for i:= 0 to length(cell)-1 do
      if assigned(cell[i]) then
        cell[i]:= nil;
    cell:= nil;
    end; *)
  finally
    allocnr:= 0; allocnc:= 0;
  end;

end;
{---------------------------------------------------------------------------}
procedure tsmat.deleterows(rows: tlist<integer>);
var
  sorted: tlist<integer>;
  toDelete: array of boolean;
  i,src,dst,numDel: integer;
begin
  if rows.Count = 0 then exit;
  sorted:= tlist<integer>.create;
  try
    for i:= 0 to rows.Count-1 do
      if (rows[i] >= 1) and (rows[i] <= nr) and (sorted.IndexOf(rows[i]) = -1) then
        sorted.Add(rows[i]);
    if sorted.Count = 0 then exit;
    numDel:= sorted.Count;
    setlength(toDelete, nr+1);
    for i:= 0 to nr do toDelete[i]:= false;
    for i:= 0 to sorted.Count-1 do
      toDelete[sorted[i]]:= true;
    // move entire row pointers
    dst:= 0;
    for src:= 1 to nr do
      if not toDelete[src] then begin
        inc(dst);
        if dst <> src then
          cell[dst]:= cell[src];
      end;
    nr:= nr - numDel;
    // delete labels in reverse order
    if rdvn.hasval then begin
      sorted.Sort;
      for i:= sorted.Count-1 downto 0 do
        rdvn.deletejth(sorted[i]);
    end;
  finally
    sorted.Free;
  end;
end;
{---------------------------------------------------------------------------}
procedure tsmat.deletecols(cols: tlist<integer>);
var
  sorted: tlist<integer>;
  toDelete: array of boolean;
  i,src,dst,numDel: integer;
begin
  if cols.Count = 0 then exit;
  sorted:= tlist<integer>.create;
  try
    for i:= 0 to cols.Count-1 do
      if (cols[i] >= 1) and (cols[i] <= nc) and (sorted.IndexOf(cols[i]) = -1) then
        sorted.Add(cols[i]);
    if sorted.Count = 0 then exit;
    numDel:= sorted.Count;
    setlength(toDelete, nc+1);
    for i:= 0 to nc do toDelete[i]:= false;
    for i:= 0 to sorted.Count-1 do
      toDelete[sorted[i]]:= true;
    // compact columns within each row
    for i:= 1 to nr do begin
      dst:= 0;
      for src:= 1 to nc do
        if not toDelete[src] then begin
          inc(dst);
          if dst <> src then
            cell[i][dst]:= cell[i][src];
        end;
    end;
    nc:= nc - numDel;
    // delete labels in reverse order
    if cdvn.hasval then begin
      sorted.Sort;
      for i:= sorted.Count-1 downto 0 do
        cdvn.deletejth(sorted[i]);
    end;
  finally
    sorted.Free;
  end;
end;
{---------------------------------------------------------------------------}
(*procedure tsmat.dealloc;
var
  i: integer;
  mem1,mem2: integer;
begin
  mem1:= getmemavail;
  for i:= 1 to allocnr do
    if assigned(cell[i]) then
      cell[i]:= nil;
  if assigned(cell) then
    cell:= nil;
  mem2:= getmemavail;
  if mem2 - mem1 <> allocnr*allocnc then
    showmessage('Problem');
  allocnr:= 0; allocnc:= 0;
end;*)
{---------------------------------------------------------------------------}
function tsmat.allocateonly(xnr,xnc:integer):boolean;
var i: integer;
begin try
  setlength(cell,xnr+1);
  for i:= 1 to xnr do
    setlength(cell[i],xnc+1);
  allocnr:= xnr;
  allocnc:= xnc;
  result:= true;
  except
    allocnr:= 0;
    allocnc:= 0;
    result:= false;
  end;
end;
{---------------------------------------------------------------------------}
function tsmat.allocate(xnr,xnc,xnm:integer; setsize,zfill:boolean): boolean;
var
  i,j: integer;
  bytes: int64;
begin
  try
    error:= 0;
    setlength(cell,xnr+1);
    for i:= 1 to xnr do
      setlength(cell[i],xnc+1);
    allocnr:= xnr; allocnc:= xnc; allocnm:= 1;
    if setsize then setdim(xnr,xnc,xnm,false);
    vptr:= cell;
    if zfill
      then zerofill;
  except
    cell:= nil;
    error:= 1;
    allocnr:= 0; allocnc:= 0; allocnm:= 0;
  end;
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
function tsmat.allocateifneeded(xnr,xnc:integer; setsize:boolean=true; 
         autofill:boolean=true; fill:single=0.0): boolean;
var
  i,j: integer;
begin
  try
    error:= 0;
    if (allocnr < xnr) or (allocnc < xnc) then
      allocate(xnr,xnc,-1,setsize,false);
    if autofill then 
      for i:= 1 to xnr do
        for j:= 1 to xnc do
          cell[i,j]:= fill; 
  except
    cell:= nil;
    error:= 1;
    allocnr:= 0; allocnc:= 0; allocnm:= 0;
  end;
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
function tsmat.getvalue(i,j:integer): single;
begin result:= cell[i,j]; end;
{---------------------------------------------------------------------------}
procedure tsmat.setvalue(i,j:integer; x:single);
begin cell[i,j]:= x; end;
{---------------------------------------------------------------------------}
function tsmat.getvbrn(rname:string; j:integer): variant;
var i: integer;
begin
  i:= rdvn.lookupstr(rname);
  if i > 0 then result:= cell[i,j];
end;
{---------------------------------------------------------------------------}
procedure tsmat.setvbrn(rname:string; j:integer; x:variant);
var i: integer;
begin
  i:= rdvn.lookupstr(rname);
  if i > 0 then
    cell[i,j]:= single(x);
end;
{---------------------------------------------------------------------------}
function tsmat.getvbcn(i:integer; cname:string): variant;
var j: integer;
begin
  j:= cdvn.lookupstr(cname);
  if (j > 0) and (i > 0)
    then result:= cell[i,j]
    else result:= bna;
end;
{---------------------------------------------------------------------------}
function tsmat.findcol(s:string): integer;
begin
  if (assigned(cdvn)) and (cdvn.n > 0)
    then result:= cdvn.lookupstr(s)
    else if not trystrtoint(s,result)
      then result:= 0;
end;
{---------------------------------------------------------------------------}
function tsmat.findrow(s:string): integer;
begin
  if assigned(rdvn)
    then result:= rdvn.lookupstr(s)
    else if not trystrtoint(s,result)
      then result:= 0;
end;
{---------------------------------------------------------------------------}
procedure tsmat.setvbcn(i:integer; cname:string; x:variant);
var j: integer;
begin
  j:= cdvn.lookupstr(cname);
  if (j > 0) and (i > 0) and (i <= nr)
    then cell[i,j]:= single(x);
end;
{---------------------------------------------------------------------------}
procedure tsmat.copycell(toi,toj,fromi,fromj:integer);
begin cell[toi,toj]:= cell[fromi,fromj]; end;
{---------------------------------------------------------------------------}
procedure tsmat.copyfrom(x:tsmat; toi,toj,fromi,fromj:integer);
begin cell[toi,toj]:= x.cell[fromi,fromj]; end;
{---------------------------------------------------------------------------}
procedure tsmat.copycoltoarrayofsingle(arr:arrayofsingle; c:integer);
var i: integer;
begin
  for i:= 1 to nr do
    arr[i]:= cell[i,c];
end;
{---------------------------------------------------------------------------}
function tsmat.fget(i,j:integer): extended;
begin result:= cell[i,j]; end;
{---------------------------------------------------------------------------}
function tsmat.sget(i,j:integer): string;
begin
  if cell[i,j] < na
    then result:= fstr(cell[i,j],0,-3)
    else result:= '';
end;
{---------------------------------------------------------------------------}
function tsmat.iget(i,j:integer): integer;
begin
  if isna(i,j) then result:= maxint else result:= round(cell[i,j]);
end;
{---------------------------------------------------------------------------}
function tsmat.vget(i,j:integer): variant;
begin result:= cell[i,j]; end;
{---------------------------------------------------------------------------}
procedure tsmat.vput(i,j:integer; x:variant);
begin cell[i,j]:= x; end;
{---------------------------------------------------------------------------}
procedure tsmat.fput(i,j:integer; x:extended; e:extended=0);
begin cell[i][j]:= x; end;
{---------------------------------------------------------------------------}
procedure tsmat.iput(i,j:integer; x:integer);
begin cell[i][j]:= x; end;
{---------------------------------------------------------------------------}
procedure tsmat.faddto(i,j:integer; x:extended);
begin cell[i][j]:= cell[i][j] + x; end;
{---------------------------------------------------------------------------}
procedure tsmat.iaddto(i,j:integer; x:integer);
begin cell[i][j]:= cell[i][j] + x; end;
{---------------------------------------------------------------------------}
procedure tsmat.faddtona(i,j:integer; x:extended);
begin
  if x < na
    then if cell[i][j] < na
      then cell[i][j]:= cell[i][j] + x
      else cell[i][j]:= x;
end;
{---------------------------------------------------------------------------}
procedure tsmat.incmean(i,j:integer; x:extended; num:integer);
//assumes cell[i,j] starts out as zero and x is never NA
begin
  cell[i,j]:= cell[i,j] + (x-cell[i,j])/num; 
end;
{---------------------------------------------------------------------------}
procedure tsmat.vaddtona(i,j:integer; x:variant);
begin
  if (varisnull(cell[i,j])) and (cell[i][j] < na)
    then cell[i][j]:= cell[i][j] + x
    else cell[i][j]:= x;
end;
{---------------------------------------------------------------------------}
function tsmat.copyval(m:tmat): boolean;
label cleanup;
var
  i,j: integer;
  mcell: arrayofarrayofsingle;
begin
  if not allocsize(m.nr,m.nc) then goto cleanup;
  if dt = m.dt
    then begin
      mcell:= m.vptr;
      for i:= 1 to m.nr do for j:= 1 to m.nc do
        cell[i,j]:= mcell[i,j];
    end
    else for i:= 1 to nr do for j:= 1 to nc do
      cell[i,j]:= m.fget(i,j);
cleanup:
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
function tsmat.copyvaldsl(m:tmat): boolean;
label cleanup;
var
  i,j: integer;
begin
  if not m.rdsl.hasval then begin
    if m.rdsl.allocsize(m.nr) then goto cleanup;
    m.rdsl.one2n;
    end;
  if not m.cdsl.hasval then begin
    if m.cdsl.allocsize(m.nc) then goto cleanup;
    m.cdsl.one2n;
    end;
  if (allocnr < m.rdsl.n) or (allocnc < m.cdsl.n) then
    if not allocsize(m.rdsl.n,m.cdsl.n) then goto cleanup;
  for i:= 1 to m.rdsl.n do
    for j:= 1 to m.cdsl.n do
      cell[i,j]:= m.fget(m.rdsl.cell[i],m.cdsl.cell[j]);
cleanup:
     result:= error = 0;
end;
{---------------------------------------------------------------------------}
function tsmat.copyvalues(m:tsmat): boolean;
label cleanup;
var
  i,j: integer;
begin
  if (allocnr < m.nr) or (allocnc < m.nc) then
    allocate(m.nr,m.nc,-1,true,false);
  for i:= 1 to m.nr do
    move(m.cell[i,0],cell[i,0],4*(m.nc+1));
cleanup:
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
procedure tsmat.appendrows(x:tmat);
var
  i,j,oldnr: integer;
begin
  oldnr:= nr;
  reallocsize(oldnr+x.nr,nc);
  rdvn.reallocsize(nr);
  for i:= 1 to x.nr do begin
    rdvn.sput(oldnr+i,x.rdvn.labelget(i));
    for j:= 1 to nc do
      cell[oldnr+i,j]:= x.vget(i,j);
    end;
end;
{---------------------------------------------------------------------------}
function tsmat.copyvaltransposed(m:tsmat): boolean;
label cleanup;
var
  i,j: integer;
begin
  if (allocnr < m.nc) or (allocnc < m.nr) then
    if not allocsize(m.nc,m.nr) then goto cleanup;
  for i:= 1 to m.nr do for j:= 1 to m.nc do
    cell[j,i]:= m.cell[i,j];
cleanup:
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
procedure tsmat.transpose;
var
  dup: tsmat;
begin
  dup:= tsmat.create;
  if is1mode
    then transposesquarematrix
    else begin 
      dup.copy(self);
      self.copyvaltransposed(dup);
      self.copydeftransposed(dup);
      end;
  dup.destroy;
end;
{---------------------------------------------------------------------------}
procedure tsmat.transposeviadisk;
var
  a: array of single;
  s: tfilestream;
  fn: string; 
  i,j,bytesread: integer;
begin try
  setlength(a,nr);
  fn:= getwindowstemppath+'\transpose.ucx';
  s:= tfilestream.create(fn,fmcreate,fmsharedenynone);
  for j:= 1 to nc do begin
    for i:= 1 to nr do
      a[i-1]:= cell[i,j];
    s.Write(a[0],4*(nr));
    end;
  s.free;
  s:= tfilestream.create(fn,fmopenreadwrite,fmsharedenynone);
  s.position:= 0;
  allocate(nc,nr,-1,true,false);  
  for i:= 1 to nr do begin
    zeromemory(a,4*(nc));
    bytesread:= s.read(a[0],4*(nc));
    for j:= 1 to nc do 
      cell[i,j]:= a[j-1];
    end;
  swapstrvecs(rdvn,cdvn);
  swapivecs(rdsl,cdsl);
  freeandnil(s);
  finally
    a:= nil;
    sysutils.deletefile(fn);
  end;
end;
{---------------------------------------------------------------------------}
procedure tsmat.swapcells(i,j,ii,jj: integer);
var
  v: single;
begin
  v:= cell[i,j];
  cell[i,j]:= cell[ii,jj];
  cell[ii,jj]:= v;
end;
{---------------------------------------------------------------------------}
function tsmat.transposeof(t:tsmat): boolean;
label cleanup;
var
  i,j: integer;
begin
  if not allocsize(t.nc,t.nr) then goto cleanup;
  for i:= 1 to nr do
    for j:= 1 to nc do
      cell[i][j]:= t.cell[j][i];
  rdvn.copy(tvec(t.cdvn)); cdvn.copy(tvec(t.rdvn));
  rdsl.copy(tvec(t.cdsl)); cdsl.copy(tvec(t.rdsl));
  nr:= t.nc; nc:= t.nr;
  if length(title) = 0
    then title:= 'Transpose'
    else title:= 'Transpose of ' + title;
  cleanup:
    result:= error = 0;
end;
{---------------------------------------------------------------------------}
procedure tsmat.nafill(diagok:boolean=true);
var
  i,j: integer;
begin
  for i:= 1 to nr do
    for j:= 1 to nc do if (i<>j) or diagok then
      cell[i][j]:= bna;
end;
{---------------------------------------------------------------------------}
procedure tsmat.multbyconst(x:double);
var
  i,j: integer;
begin
  for i:= 1 to nr do
    for j:= 1 to nc do
      if cell[i,j] < na
        then cell[i,j]:= cell[i,j]*x;
end;
{---------------------------------------------------------------------------}
procedure tsmat.mirror(i,j:integer);
begin
  cell[j,i]:= cell[i,j];
end;
{---------------------------------------------------------------------------}
procedure tsmat.loadrows<tfil>(f:ufile);
type
  tfilarray = array of tfil;
var
  row: tfilarray;
  i,j: integer;
begin
  setlength(row,nc+1);
  for i:= 1 to nr do begin
    blockread(f.uf,row[1],nc*sizeof(tfil));
    for j:= 1 to nc do 
//      cell[i,j]:= generic.convertdef<tfil,single>(row[j],bna);
      cell[i,j]:= tvalue.from<tfil>(row[j]).asextended;
    end;
  finalize(row);
end;
{---------------------------------------------------------------------------}
function tsmat.loadmat(f:ufile): boolean;
var
  i,j: integer;
  ix: array of integer;
begin try
  if (allocnr < nr) or (allocnc < nc) then
    if not allocate(nr,nc,nm,true,false) then exit;
  case f.dt of
    singledt: loadrows<single>(f);
    doubledt: loadrows<double>(f);
    extendeddt: loadrows<extended>(f);
    bytedt: loadrows<byte>(f);
    smallintdt: loadrows<smallint>(f);
    integerdt: loadrows<integer>(f);
    nodelistdt: begin
      setlength(ix,nc+1);
      for i:= 1 to nr do begin
        blockread(f.uf,ix[0],sizeof(integer));
        blockread(f.uf,ix[1],ix[0]*sizeof(integer));
        for j:= 1 to nc do cell[i,j]:= 0;
        for j:= 1 to ix[0] do cell[i,ix[j]]:= 1;
        end;
      ix:= nil;
      end;
    end;
  error:= 0;
  except
   error:= 1;
  end;
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
(*function tsmat.loadmat(f:ufile): boolean;
var
  i,j: integer;
  num: cardinal;
  ix: array of integer;
  six: array of smallint;
  bx: array of byte;
  ex: array of extended;
  sx: array of single;
begin
  try
  if (allocnr < nr) or (allocnc < nc) then
    if not allocate(nr,nc,nm,true,false) then exit;
  case f.dt of
    singledt: begin
      num:= nc*sizeof(single);
      for i:= 1 to nr do
        blockread(f.uf,cell[i,1],num);
      end;
{    singledt: begin
      setlength(sx,nc+1);
      num:= nc*sizeof(single);
      for i:= 1 to nr do begin
         blockread(f.uf,sx[1],num);
        for j:= 1 to nc do cell[i,j]:= sx[j];
        end;
      sx:= nil;
      end;}
    integerdt: begin
      setlength(ix,nc+1);
      num:= nc*sizeof(integer);
      for i:= 1 to nr do begin
        blockread(f.uf,ix[1],num);
        for j:= 1 to nc do cell[i,j]:= ix[j];
        end;
      ix:= nil;
      end;
    extendeddt: begin
      setlength(ex,nc+1);
      num:= nc*sizeof(extended);
      for i:= 1 to nr do begin
        blockread(f.uf,ex[1],num);
        for j:= 1 to nc do cell[i,j]:= ex[j];
        end;
      ex:= nil;
      end;
    nodelistdt: begin
      setlength(ix,nc+1);
      for i:= 1 to nr do begin
        blockread(f.uf,ix[0],sizeof(integer));
        blockread(f.uf,ix[1],ix[0]*sizeof(integer));
        for j:= 1 to nc do cell[i,j]:= 0;
        for j:= 1 to ix[0] do cell[i,ix[j]]:= 1;
        end;
      ix:= nil;
      end;
    sparsedt: begin
      setlength(sx,2*nc+1);
      for i:= 1 to nr do begin
        blockread(f.uf,num,sizeof(integer));
        blockread(f.uf,ix[1],num*8);
        for j:= 1 to nc do cell[i,j]:= 0;
        for j:= 1 to num do cell[i,ix[j]]:= 1;
        end;
      ix:= nil;
      end;
    smallintdt: begin
      setlength(six,nc+1);
      num:= nc*sizeof(smallint);
      for i:= 1 to nr do begin
        blockread(f.uf,six[1],num);
        for j:= 1 to nc do cell[i,j]:= six[j];
        end;
      six:= nil;
      end;
    bytedt: begin
      setlength(bx,nc+1);
      num:= nc*sizeof(byte);
      for i:= 1 to nr do begin
        blockread(f.uf,bx[1],num);
        for j:= 1 to nc do cell[i,j]:= bx[j];
        end;
      bx:= nil;
      end;
    end;
    error:= 0;
  finally
    ix:= nil; six:= nil; bx:= nil; ex:= nil;
    result:= error = 0;
  end;
end;  *)
{---------------------------------------------------------------------------}
procedure tsmat.saverows<tfil>(f:ufile);
type
  arrayoftfil = array of tfil;
var
  row: arrayoftfil;
  i,j: integer;
  zero: tfil;
begin
  zero:= generic.convert<integer,tfil>(0);
  setlength(row,nc+1);
  for i:= 1 to nr do begin
    for j:= 1 to nc do 
      row[j]:= generic.convertdef<single,tfil>(cell[i,j],zero);
    blockwrite(f.uf,row[1],nc*sizeof(tfil));
    end;
  system.finalize(row);
end;
{---------------------------------------------------------------------------}
function tsmat.savemat(f:ufile): boolean;
var
  i,j,num: integer;
  ix: array of integer;
  six: array of smallint;
  bx: array of byte;
begin
  try
  if (allocnr < nr) or (allocnc < nc) then
    if not alloc(nr,nc) then exit;
  if f.dt = nodt then f.dt:= dt;
  case f.dt of
    singledt:
      for i:= 1 to nr do blockwrite(f.uf,cell[i][1],nc*sizeof(single));
    integerdt: begin
      setlength(ix,nc+1);
      for i:= 1 to nr do begin
        for j:= 1 to nc do ix[j]:= integerval(cell[i,j]);
        blockwrite(f.uf,ix[1],nc*sizeof(integer));
        end;
      ix:= nil;
      end;
    nodelistdt: begin
      setlength(ix,nc+1);
      for i:= 1 to nr do begin
        ix[0]:= 0;
        for j:= 1 to nc do if cell[i,j] > 0 then begin
          inc(ix[0]); ix[ix[0]]:= j; end;
        blockwrite(f.uf,ix[0],(ix[0]+1)*sizeof(integer));
        end;
      ix:= nil;
      end;
    smallintdt: begin
      setlength(six,nc+1);
      for i:= 1 to nr do begin
        for j:= 1 to nc do six[j]:= integerval(cell[i,j],smallintdt);
        blockwrite(f.uf,six[1],nc*sizeof(integer));
        end;
      six:= nil;
      end;
    bytedt: begin
      setlength(bx,nc+1);
      for i:= 1 to nr do begin
        for j:= 1 to nc do
          bx[j]:= integerval(cell[i,j],bytedt);
        blockwrite(f.uf,bx[1],nc*sizeof(byte));
        end;
      bx:= nil;
      end;
    else error:= 1;
    end;
    error:= 0;
  finally
    ix:= nil; six:= nil; bx:= nil;
    result:= error = 0;
  end;
end;
{---------------------------------------------------------------------------}
function tsmat.savematdsl(f:ufile): boolean;
var
  i,j,num: integer;
  sx: array of single;
  ix: array of integer;
  six: array of smallint;
  bx: array of byte;
begin
  try
  if (allocnr < nr) or (allocnc < nc) then
    if not alloc(nr,nc) then exit;
  if f.dt = nodt then f.dt:= dt;
  case f.dt of
    singledt: begin
      setlength(sx,cdsl.n+1);
      for i:= 1 to rdsl.n do begin
        for j:= 1 to cdsl.n do sx[j]:= cell[rdsl.cell[i],cdsl.cell[j]];
        blockwrite(f.uf,sx[1],cdsl.n*sizeof(single));
        end;
      sx:= nil;
      end;
    integerdt: begin
      setlength(ix,cdsl.n+1);
      for i:= 1 to rdsl.n do begin
        for j:= 1 to cdsl.n do
          ix[j]:= integerval(cell[rdsl.cell[i],cdsl.cell[j]]);
        blockwrite(f.uf,ix[1],cdsl.n*sizeof(integer));
        end;
      ix:= nil;
      end;
    nodelistdt: begin
      setlength(ix,cdsl.n+1);
      for i:= 1 to rdsl.n do begin
        ix[0]:= 0;
        for j:= 1 to cdsl.n do if cell[rdsl.cell[i],cdsl.cell[j]] > 0 then begin
          inc(ix[0]); ix[ix[0]]:= cdsl.cell[j]; end;
        blockwrite(f.uf,ix[0],(ix[0]+1)*sizeof(integer));
        end;
      ix:= nil;
      end;
    smallintdt: begin
      setlength(six,cdsl.n+1);
      for i:= 1 to rdsl.n do begin
        for j:= 1 to cdsl.n do
          six[j]:= integerval(cell[rdsl.cell[i],cdsl.cell[j]],smallintdt);
        blockwrite(f.uf,six[1],cdsl.n*sizeof(integer));
        end;
      six:= nil;
      end;
    bytedt: begin
      setlength(bx,cdsl.n+1);
      for i:= 1 to rdsl.n do begin
        for j:= 1 to cdsl.n do
          bx[j]:= integerval(cell[rdsl.cell[i],cdsl.cell[j]],bytedt);
        blockwrite(f.uf,bx[1],cdsl.n*sizeof(integer));
        end;
      bx:= nil;
      end;
    else error:= 1;
    end;
    error:= 0;
  finally
    ix:= nil; six:= nil; bx:= nil; sx:= nil;
    result:= error = 0;
  end;
end;
{---------------------------------------------------------------------------}
procedure tsmat.zerofill;
var
  i,xnr,xnc: integer;
  bytes: int64;
begin
  bytes:= sizeof(single)*(nc+1);
  for i:= 1 to nr do
    fillchar(cell[i][0],bytes,0);
end;
{---------------------------------------------------------------------------}
procedure tsmat.add(x:tmat);
var
  i,j: integer;
begin
  for i:= 1 to nr do for j:= 1 to nc do
    cell[i,j]:= cell[i,j] + x.fget(i,j);
end;
{---------------------------------------------------------------------------}
procedure tsmat.getmarginals(r,c:tdvec; diagok:boolean=false);
var
  i,j: integer;
begin
  r.allocate(nr,true);
  c.allocate(nc,true);
  if nr <> nc then diagok:= true;
  for i:= 1 to nr do
    for j:= 1 to nc do if (i <> j) or diagok then begin
      r.cell[i]:= r.cell[i] + cell[i,j];
      c.cell[j]:= c.cell[j] + cell[i,j];
      end;
end;
{---------------------------------------------------------------------------}
procedure tsmat.meancenter(diagok:boolean);
var
  i,j: integer;
  u: tmean;
begin
  u:= tmean.create;
  for i:= 1 to nr do
    for j:= 1 to nc do if (i<>j) or diagok then
      u.addcase(cell[i,j]);
  for i:= 1 to nr do
    for j:= 1 to nc do if (i<>j) or diagok then
      if not isna(i,j) then
        cell[i,j]:= cell[i,j] - u.mean;
  u.free;
  end;
{---------------------------------------------------------------------------}
function tsmat.sameas(i1,j1,i2,j2:integer): boolean;
begin
  result:= feq(cell[i1,j1],cell[i2,j2]);
end;
{---------------------------------------------------------------------------}
function tsmat.getsum(diagok:boolean=true): double;
var
  i: integer;
begin
  result:= 0;
  for i:= 1 to nr do
    result:= result + getrowsum(i,diagok);
end;
{---------------------------------------------------------------------------}
function tsmat.rowsum(i:integer; diagok:boolean=true): double;
begin
  result:= getrowsum(i,diagok);
end;
{---------------------------------------------------------------------------}
function tsmat.getrowsum(i:integer; diagok:boolean=true): double;
var
  j,nmiss,nposs: integer;
begin
  if is2mode then diagok:= true;
  result:= 0; nmiss:= 0; nposs:= 0;
  for j:= 1 to nc do if (i<>j) or diagok then begin
    inc(nposs);
    if isvalid(i,j)
      then result:= result + cell[i,j]
      else inc(nmiss);
   end;
  if nmiss = nposs
    then result:= bna
end;
{---------------------------------------------------------------------------}
(*function tsmat.getrowsums(s:tsvec; diagok:boolean=true): double;
var
  j,nmiss,nposs: integer;
begin
  if is2mode then diagok:= true;
  result:= 0; nmiss:= 0; nposs:= 0;
  for j:= 1 to nc do if (i<>j) or diagok then begin
    inc(nposs);
    if isvalid(i,j)
      then result:= result + cell[i,j]
      else inc(nmiss);
   end;
  if nmiss = nposs
    then result:= bna
end;
*)
{---------------------------------------------------------------------------}
function tsmat.getcolsum(j:integer; diagok:boolean=false): double;
var i: integer;
begin
  if nr <> nc then diagok:= true;
  result:= 0;
  for i:= 1 to nr do if ((i<>j) or diagok) and (cell[i,j] < na) then 
    result:= result + cell[i,j];
end;
{---------------------------------------------------------------------------}
procedure tsmat.normrows(y:tsmat=nil; diagok:boolean=false);
var
  i,j: integer;
  sum: double;
begin
  if y = nil then y:= self;
  if nr <> nc then diagok:= true;
  for i:= 1 to nr do begin
    sum:= getrowsum(i,diagok);
    if math.iszero(sum,singleprecision) 
      then y.fillrow(i,bna,diagok) 
      else for j:= 1 to nc do 
        if ((i<>j) or diagok) and (cell[i,j] < na) then
          y.cell[i,j]:= cell[i,j]/sum;
    end;
end;
{---------------------------------------------------------------------------}
procedure tsmat.normcols(y:tsmat=nil; diagok:boolean=false);
var
  i,j: integer;
  sum: double;
begin
  if y = nil then y:= self;
  if nr <> nc then diagok:= true;
  for j:= 1 to nc do begin
    sum:= getcolsum(j,diagok);
    if math.iszero(sum,singleprecision)
      then y.fillcol(j,bna,diagok)
      else for i:= 1 to nr do 
        if ((i<>j) or diagok) and (cell[i,j] < na) then
          y.cell[i,j]:= cell[i,j]/sum;
    end;
end;
{---------------------------------------------------------------------------}
procedure tsmat.recode(op:tdichop; cut:double; newval:double; diagok:boolean=false);
//opgt = 0; opge = 1; opeq = 2; ople = 3; oplt = 4; opne = 5;
var
  i,j: integer;
begin
  if nr <> nc then diagok:= true;
  for i:= 1 to nr do for j:= 1 to nc do
    if ((i<>j) or diagok) and (not isna(i,j)) then
      case op of
         opgt: if cell[i,j] > cut then cell[i,j]:= newval;
         opge: if cell[i,j] >= cut then cell[i,j]:= newval;
         opeq: if feq(cell[i,j],cut) then cell[i,j]:= newval;
         ople: if cell[i,j] <= cut then cell[i,j]:= newval;
         oplt: if cell[i,j] < cut then cell[i,j]:= newval;
         opne: if cell[i,j] <> cut then cell[i,j]:= newval;
         end;
end;
{---------------------------------------------------------------------------}
procedure tsmat.reversevalues(indiag,outdiag:boolean; x:tsmat=nil);
//X is optional input matrix. if omitted, then input is self
//output stored in self
//indiag=true means include diagonals in getting min and max
//outdiag=true means reverse values of the diagonals
var
  i,j: integer;
  lg,sm: double;
  anyvalid: boolean;
begin
  if x = nil 
    then x:= self;
  if x.nr <> x.nc then begin 
    indiag:= true;
    outdiag:= true; 
    end;
  lg:= minfloat; sm:= maxfloat; anyvalid:= false;
  for i:= 1 to nr do 
    for j:= 1 to nc do if x.isvaliddiag(i,j,indiag) then begin
      if (x.cell[i,j] > lg) then lg:= x.cell[i,j];
      if (x.cell[i,j] < sm) then sm:= x.cell[i,j];
      anyvalid:= true;
      end;
  if not anyvalid
    then raise exception.create('Matrix has no non-missing values');
  for i:= 1 to nr do 
    for j:= 1 to nc do if (i<>j) or outdiag
      then if x.isvalid(i,j) 
        then cell[i,j]:= lg - x.cell[i,j] + sm
        else cell[i,j]:= bna;
end;
{---------------------------------------------------------------------------}
procedure tsmat.fillcol(j:integer; x:single; diagok:boolean=false);
var
  i: integer;
begin
  if nr <> nc then diagok:= true;
  for i:= 1 to nr do if (i<>j) or diagok then 
    cell[i,j]:= x; 
end;
{---------------------------------------------------------------------------}
procedure tsmat.fillrow(i:integer; x:single; repna:boolean; diagok:boolean=false);
var
  j: integer;
begin
  if nr <> nc then diagok:= true;
  for j:= 1 to nr do if (i<>j) or diagok then 
    if isvalid(i,j) or repna
      then cell[i,j]:= x;
end;
{---------------------------------------------------------------------------}
procedure tsmat.displaytomemo(memo1:tmemo);
var
  i,j: integer;
  s: string;
begin
  memo1.lines.add(title); memo1.lines.add('');
  s:= '';
  for i:= 1 to nr do begin
    s:= pad(inttostr(i) + #9 + rdvn.labelget(i) + #9,15);
    for j:= 1 to nc do
      s:= s + ' ' + formatfloat('0.000',cell[i,j])+ #9;
    memo1.lines.add(s);
    end;
  memo1.lines.add('');
end;
{---------------------------------------------------------------------------}
procedure tsmat.swaprows(a,b:integer);
var
  t: arrayofsingle;
begin
  t:= cell[b];
  cell[b]:= cell[a];
  cell[a]:= t;
  if rdvn.hasval
    then rdvn.swap(a,b);
end;
{---------------------------------------------------------------------------}
procedure tsmat.randrc(var rs:integer);
var
  i,j: integer;
  r,c: tdsl;
  temp: tsmat;
begin try
  temp:= tsmat.create;
  temp.copy(self);
  r:= temp.rdsl; c:= temp.cdsl;
  r.one2n(nr); r.randomlypermute(rs);
  c.one2n(nc); c.randomlypermute(rs);
  for i:= 1 to nr do
    for j:= 1 to nc do
      cell[i,j]:= temp.cell[r.cell[i],c.cell[j]];
  finally
    temp.free;
  end;
end;
{---------------------------------------------------------------------------}
Procedure tsmat.sortbyattr(v:tvec; dim:char='r'; dir:char='a');
Label 1,3,fin;
Var
  first,m,k,i,j,im,num: integer;

  function outoforder(im,i:integer): boolean;
  begin
    case dir of
      'A': result:= v.lessthan(im,i);
      'D': result:= v.morethan(im,i);
      end;
  end;

Begin
  dim:= upcase(dim);
  dir:= upcase(dir);
  num:= nr;
  first:= 1; m:= num;
1:
  m:= m div 2;
  if m = 0 then goto fin;
  k:= num-m + first-1;
  for j:= first to k do begin
    i:= j;
3:  im:= i + m;
    if outoforder(im,i) then begin
      case dim of
        'R': swaprows(i,im);
        'C': swapcols(i,im);
        end;
      v.swap(i,im);
      i:= i-m;
      if i >= first then goto 3;
      end;
    end;
  goto 1;
  fin:
End;
{---------------------------------------------------------------------------}
Procedure tsmat.sortrowsbyattr(v:tvec; dir:char='a');
begin
  sortbyattr(v,'r',dir);
end;
{---------------------------------------------------------------------------}
Procedure tsmat.sortcolsbyattr(v:tvec; dir:char='a');
begin
  sortbyattr(v,'c',dir);
end;
{---------------------------------------------------------------------------}
procedure tsmat.sortrowsbylabel(dir:char='a');
Label 1,3,fin;
Var
  first,m,k,i,j,im,n: integer;

  function outoforder(im,i:integer): boolean;
  begin
    case dir of
      'A': result:= rdvn.lessthan(im,i);
      'D': result:= rdvn.morethan(im,i);
      end;
  end;

Begin
  dir:= upcase(dir);
  n:= nr; first:= 1; m:= n;
1:
  m:= m div 2;
  if m = 0 then goto fin;
  k:= n-m + first-1;
  for j:= first to k do begin
    i:= j;
3:  im:= i + m;
    if outoforder(im,i) then begin
      swaprows(i,im); //rdvn.swap(i,im);
      i:= i-m;
      if i >= first then goto 3;
      end;
    end;
  goto 1;
  fin:
End;
{---------------------------------------------------------------------------}
procedure tsmat.sortcolsbylabel(dir:char='a');
Label 1,3,fin;
Var
  first,m,k,i,j,im,n: integer;

  function outoforder(im,i:integer): boolean;
  begin
    case dir of
      'A': result:= rdvn.lessthan(im,i);
      'D': result:= rdvn.morethan(im,i);
      end;
  end;

Begin
  dir:= upcase(dir);
  n:= nc; first:= 1; m:= n;
1:
  m:= m div 2;
  if m = 0 then goto fin;
  k:= n-m + first-1;
  for j:= first to k do begin
    i:= j;
3:  im:= i + m;
    if cdvn.lessthan(im,i) then begin
      swapcols(i,im); //cdvn.swap(i,im);
      i:= i-m;
      if i >= first then goto 3;
      end;
    end;
  goto 1;
  fin:
End;
{---------------------------------------------------------------------------}
Procedure tsmat.sortrcbyattr(r,c:tvec; dir:char='a');
begin
  sortbyattr(r,'r',dir);
  sortbyattr(c,'c',dir);
end;
{---------------------------------------------------------------------------}
procedure tsmat.appendcols(m2:tmat);
Var
  i,j,n: integer;
Begin
  if (m2.cdsl.cell = nil) or (m2.cdsl.n = 0) then begin
    m2.cdsl.allocate(m2.nc,true,true);
    m2.cdsl.one2n();
  end;
  n:= nc + m2.cdsl.n;
  allocate(nr,n,nm,false,false);
  for i:= 1 to nr do
    for j:= nc+1 to n do
      cell[i,j]:= m2.fget(i,j-nc);
  cdvn.reallocate(n,false);
  for j:= nc+1 to n do
    cdvn.sput(j,m2.cdvn.labelget(j-nc));
  nc:= n;
End;
{---------------------------------------------------------------------------}
function tsmat.wholenumbers: boolean;
var i,j: integer;
begin
  for i:= 1 to nr do
    for j:= 1 to nc do if cell[i,j] <> na then
      if frac(abs(cell[i,j])) > 1E-9 then begin
        result:= false;
        exit;
        end;
  result:= true;
end;
{---------------------------------------------------------------------------}
function tsmat.istie(i,j:integer; op:integer=0; cut:double=0.0): boolean;
begin
  if isna(i,j)
    then exit(false);
  case op of
    0: result:= cell[i,j] > cut;
    1: result:= cell[i,j] >= cut;
    2: result:= feq(cell[i,j],cut);
    3: result:= cell[i,j] <= cut;
    4: result:= cell[i,j] < cut;
    5: result:= fneq(cell[i,j],cut);
    else result:= false;
  end;
end;
{---------------------------------------------------------------------------}
function tsmat.iszero(i,j:integer): boolean;
begin
  result:= math.iszero(cell[i,j],singleprecision);
end;
{---------------------------------------------------------------------------}
function tsmat.isna(i,j:integer): boolean;
begin
  result:= cell[i,j] >= na;
end;
{---------------------------------------------------------------------------}
function tsmat.hasna(sym:boolean=false; diagok:boolean=false): boolean;
var
  i,j: integer;
begin
  if is2mode
    then diagok:= true;
  if sym
    then begin
      for i:= 2 to n do
        for j:= 1 to i do if (i<>j) or diagok
          then if cell[i,j] >= na
            then exit(true);
      end
    else begin
      for i:= 1 to n do
        for j:= 1 to n do if (i<>j) or diagok
          then if cell[i,j] >= na
            then exit(true);
      end;
  result:= false;
end;
{---------------------------------------------------------------------------}
function tsmat.removenegatives(diagok:boolean=false): longint;
var
  i,j: integer;
begin
  result:= 0;
  for i:= 1 to n do
    for j:= 1 to n do if (i<>j) or diagok
      then if cell[i,j] < 0
        then cell[i,j]:= 0;
end;
{---------------------------------------------------------------------------}
procedure tsmat.floydn;
//input is distance matrix. e.g., replace 0s in adj matrix with n
var
  i,j,k: integer;
  s: single;
begin
  assert(issquare,'Matrix must be square');
  for i:= 1 to n do
    for j:= 1 to n do
      for k:= 1 to n do begin
        s:= cell[j,i] + cell[i,k];
        if s < cell[j,k] then cell[j,k]:= s;
        end;
end;
{===========================================================================}
procedure tsmat.floyd;
//input is adjacency
var
  i,j,k: integer;
  s: single;
begin
  assert(issquare,'Matrix must be square');
  for i:= 1 to n do
    for j:= 1 to n do
      for k:= 1 to n do begin
        s:= cell[j,i] + cell[i,k];
        if s < cell[j,k] then cell[j,k]:= s;
        end;
end;
{===========================================================================}
procedure tsmat.fillrect(r1,c1,r2,c2:integer; f:integer=0);
var
  i,j: integer;
begin
  for i:= r1 to r2 do
    for j:= c1 to c2 do
      cell[i,j]:= f;
end;
{---------------------------------------------------------------------------}
procedure tsmat.fillrect(r1,c1,r2,c2:integer; f:single=0);
var
  i,j: integer;
begin
  for i:= r1 to r2 do
    for j:= c1 to c2 do
      cell[i,j]:= f;
end;
{---------------------------------------------------------------------------}

End.
