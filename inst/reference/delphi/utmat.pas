unit utmat;
interface
uses
  classes, utunivariate, math, sysutils, vcl.dialogs,
  generics.collections,
  variants,
(*{$IFDEF VER150}
  variants,
{$ENDIF}*)
    ucommon, utvec, utivec, utsvec, utdvec, utstrvec, uufile,
    umath, ustring, ukey, usys;
type
  matrixtype = (mt_unknown,mt_tdmat,mt_timat,mt_tsmat,mt_tsmat3);
  tmat = class
    title: string;
    dt: datatype;
    mt: matrixtype;
    istable: boolean;
    nr,nc,nm,nd,allocnr,allocnc,allocnm,nways,nmodes: integer;
    rdvn,cdvn,mdvn,colformat: tstrvec;
    rdsl,cdsl,mdsl: tdsl;
    vptr: pointer;
    vmissing: variant;
    currentmat: integer;
    comments: tstringlist;
    similarities,binary: integer;
    diagok: boolean;
    writerownumbers,writecolnumbers,writedimensions,writetitle: boolean;
    constructor create; virtual;
    destructor destroy; override;
    function addkeypair(s:string; v:variant; i:integer=1): integer; virtual;
    function adjacent(i,j:integer): boolean; virtual;
    function alloc(xnr,xnc,xnm:integer; size:boolean): boolean; overload;
    function alloc(xnr,xnc:integer; size:boolean): boolean; overload;
    function alloc(xnr,xnc:integer): boolean; overload;
    function alloc(xn:integer): boolean; overload;
    function alloc(xnr,xnc,xnm:integer): boolean; overload;
    function allocate(xnr,xnc,xnm:integer; setsize,zfill:boolean): boolean; virtual; abstract;
    function allocateatleast(xnr,xnc:integer): boolean;
    function allocateonly(xnr,xnc:integer): boolean; virtual;
    function alloclabels(dim:integer=0): boolean;
    function allocsize(xnr,xnc,xnm: integer): boolean; overload;
    function allocsize(xnr:integer; xnc:integer=-1): boolean; overload;
    function appendcol(name:string=''; data:tvec=nil; format:string=''):integer;
    function calcn: integer;
    function copy(m:tmat): boolean; virtual;
    function copydef(m:tmat): boolean; virtual;
    function copydefdsl(m:tmat): boolean; virtual;
    function copydeftransposed(m:tmat): boolean; virtual;
    function copydsl(m:tmat): boolean; virtual;
    function copyval(m:tmat): boolean; virtual;
    function copyvaldsl(m:tmat): boolean; virtual;
    function copyvaltransposed(m:tmat): boolean; virtual;
    function correlatecols(i,j:integer; diagok:boolean=false): double; virtual;
    function correlaterows(i,j:integer; diagok:boolean=false): double; virtual;
    function countties(op:tdichop=opgt; cut:double=0.0): int64; virtual;
    function equal(i1,j1,i2,j2:integer): boolean; virtual;
    function extractcolumn(c:tvec; wc:integer): boolean; virtual;
    function extractrow(v:tvec; w:integer): boolean; virtual;
    function fget(i,j:integer): extended; virtual;
    function getaverage(diagok:boolean): double; virtual;
    function getcollabel(j:integer): string;
    function getcolstats(j:integer; diagok:boolean=false): tstatsrec;
    function getcolsum(j:integer; diagok:boolean=false): double; virtual;
    function getmatlabel(k:integer): string;
    function getminmax(var mi,ma:extended; lowerhalfonly:boolean=false; diagok:boolean=true): pairofextended;
    function getminwidth(d:integer; num:integer; diagok:boolean=true):integer;
    function getminwidthbycol(col,d:integer; diagok:boolean=true):integer;
    function getminwidthfstr(d:integer; diagok:boolean=true):integer;
    function getmodes: integer;
    function getrowlabel(i:integer): string;
    function getrowstats(i:integer; diagok:boolean=false): tstatsrec;
    function getrowsum(i:integer; diagok:boolean=true): double; virtual;
    function getstats(diagok:boolean=false): tstatsrec;
    function gettrace: double; virtual;
    function getvbcn(i:integer; cname:string): variant; virtual;
    function getvbrn(rname:string; j:integer): variant; virtual;
    function getweightedrowsum(i:integer; w:tvec; diagok:boolean=true): variant;
    function hasval: boolean; virtual;
    function identifynode(name:string): integer; virtual;
    function iget(i,j:integer): longint; virtual;
    function inrange(xnr,xnc: integer): boolean;
    function insertcol(k:integer; name:string=''; data:tvec=nil; format:string=''):integer;
    function Is1mode: boolean;
    function Is2mode: boolean;
    function isautomorphism(p:tivec): boolean; virtual;
    function isbinary(diagok:boolean=false): boolean; virtual;
    function isintegervalued(col:integer; diagok:boolean=true): boolean; overload;
    function isintegervalued(diagok:boolean=true): boolean; overload;
    function isna(i,j:integer): boolean; virtual;
    function isneighbor(i,j:integer; meth:tegometh): boolean; virtual;
    function IsSquare: boolean;
    function IsSymmetric(ignorena:boolean=false): boolean; virtual;
    function istie(i,j:integer; op:tdichop=opgt; cut:double=0.0): boolean; virtual;
    function isvalid(i,j:integer): boolean; virtual;
    function IsValued(diagok:boolean=true): boolean; virtual;
    function iszero(i,j:integer): boolean; virtual;
    function loadmat(f:ufile): boolean; virtual;
    function mptr: pointer; virtual;
    function ncells: int64;
    function nonzero(i,j:integer): boolean;
    function product(a,b:tmat; diagok:boolean=true): boolean; virtual;
    function rclabelsmatch: integer;
    function realloc(xnr,xnc:integer; size:boolean=false): boolean; virtual;
    function reallocsize(xnr,xnc: integer): boolean;
    function reordercols(var o:tivec): boolean; virtual;
    function reorderrows(var o:tivec): boolean; virtual;
    function replacecol(col:integer; data:tvec=nil; format:string=''; name:string=''): integer; virtual;
    function resizerowsto(newnc:integer; changenc:boolean=false): boolean; virtual;
    function rowsum(i:integer; diagok:boolean=false): double; virtual;
    function rptr(i:integer): pointer; virtual;
    function sameas(i1,j1,i2,j2:integer): boolean; virtual;
    function savemat(f:ufile): boolean; virtual;
    function savematdsl(f:ufile): boolean; virtual;
    function sget(i,j:integer): string; virtual;
    function smallenoughtodisplay: boolean;
    function storecol(col:integer; data:tvec=nil; format:string=''; name:string=''):integer;
    function storevariable(name:string=''; data:tvec=nil; format:string=''): integer;
    function symmetrize(method:symtype=sy_union; missings:integer=0): boolean;
    function trace: double; virtual;
    function transposesquarematrix: boolean; virtual;
    function trygetcol(const colstr:string; out col:integer): boolean;
    function vget(i,j:integer): variant; overload; virtual;
    function vget(k,i,j:integer): variant; overload; virtual;
    procedure addtie(i,j: integer); virtual;
    procedure appendrows(x:tmat); virtual;
    procedure clear; virtual;
    procedure combinecols(dsl:tdsl; method:integer=0; diagok:boolean=true); virtual;
    procedure combinenodes(dsl:tdsl; method:integer=0; diagok:boolean=true); virtual;
    procedure combinerows(dsl:tdsl; method:integer=0; diagok:boolean=true); virtual;
    procedure copy2str(buf:string); virtual;
    procedure copycell(toi,toj,fromi,fromj:integer); virtual;
    procedure copyfrom(x:tmat; toi,toj,fromi,fromj:integer); virtual;
    procedure copycol2vec(v:tvec; c:integer); virtual;
    procedure copylabels(m:tmat);
    procedure copyrow2vec(v:tvec; r:integer); virtual;
    procedure copyvec2col(v:tvec; c:integer=-1); virtual;
    procedure copyvec2row(v:tvec; r:integer); virtual;
    procedure deallocate; virtual; abstract;
    procedure dealloc;
    procedure deletecol(c:integer); virtual;
    procedure deletecols(cols: tlist<integer>); virtual;
    procedure deletenode(n: integer); virtual;
    procedure deletenodes(nodes: tlist<integer>); virtual;
    procedure deleterow(r:integer); virtual;
    procedure deleterows(rows: tlist<integer>); virtual;
//    procedure done; virtual;
    procedure destroyconstituents; virtual;
    procedure dichotomize(op:tdichop; cutoff:double; diags:integer=0; thenval:double=1.0; elseval:double=0.0);
    procedure displayasblockedmatrix(f:tstreamwriter; p:tivec; w:integer=-1; d:integer=-1; nastr:string=' '; zerostr:string='0');
    procedure displayasmatrix(var f:text; w:integer=-1; d:integer=-1); overload;
    procedure displayasmatrix(f:tstreamwriter; w:integer=-1; d:integer=-1; nastr:string=' '; zerostr:string='0'); overload;
    procedure displayasmatrix(fn:string; w:integer=-1; d:integer=-1); overload;
    procedure displayasmatrixname(f:tstreamwriter; matname:string; w:integer=-1; d:integer=-1; nastr:string=' '; zerostr:string='0');
    procedure display(f:tstreamwriter; matname:string; w:integer=-1; d:integer=-1; nastr:string=' '; zerostr:string='0'); overload;
    procedure display(f:tstreamwriter; w:integer=-1; d:integer=-1; nastr:string=' '; zerostr:string='0'); overload;
    procedure emult(a,b:tmat); virtual;
    procedure extractfrom(x:tmat; r1,c1,rn,cn:integer); virtual;
    procedure faddto(i,j:integer; x:extended); virtual;
    procedure faddtona(i,j:integer; x:extended); virtual;
    procedure fill(filler:double; diagok:boolean=true); virtual;
    procedure fillrect(r1,c1,r2,c2:integer; f:integer=0); overload; virtual;
    procedure fillrect(r1,c1,r2,c2:integer; f:single=0); overload; virtual;
    procedure fput(i,j:integer; x:extended; e:extended=0); virtual;
    procedure getmarginals(r,c:tdvec; diagok:boolean=false); virtual;
    procedure iaddto(i,j:integer; x:integer); virtual;
    procedure iput(i,j:integer; x:longint); virtual;
    procedure meancenter(diagok:boolean); virtual;
    procedure nafill(diagok:boolean=true); virtual;
    procedure recode(op:tdichop; cut:double; newval:double; diagok:boolean=false); virtual;
    procedure recodena(newval:single=0; diagok:boolean=false); virtual;
    procedure reversecols; virtual;
    procedure safeiput(i,j:integer; x:longint);
    procedure setborders(abool:boolean);
    procedure setn(n: integer);
    procedure setdiagonal(diag:double);
    procedure setdim(xnr,xnc,xnm:integer; labelstoo:boolean);
    procedure setsize(r:integer; c:integer=0);
    procedure setvbcn(i:integer; cname:string; x:variant); virtual;
    procedure setvbrn(rname:string; j:integer; x:variant); virtual;
//    procedure sortby(r,c:tvec; dir:char='a'); virtual;
    procedure sortcolsbylabel(dir:char='a'); virtual;
    procedure sortcolsbyattribute(v:tvec; dir:char='a'); virtual;
    Procedure sortdimbyattribute(v:tvec; dim:char; dir:char='a'); virtual; {override}
    Procedure sortdimbylabel(dim:char; dir:char='a'); virtual;
    Procedure sortdimsbyattributes(r,c:tvec; dir:char='a'); virtual;
    procedure sortrowsbyattribute(v:tvec; dir:char='a'); virtual;
    procedure sortrowsbycol(c:integer; dir:char='a'); virtual;
    procedure sortrowsbylabel(dir:char='a'); virtual;
    procedure standardize(diagok:boolean); virtual;
    procedure subgraph(src:tmat; vec:tsvec; op:tdichop=opgt; cut:single=0.0);
    procedure submatrix; virtual;
    procedure swapcells(i,j,ii,jj:integer); virtual;
    procedure swapcols(a,b:integer); virtual;
    procedure swaprows(a,b:integer); virtual;
    procedure transpose; virtual; abstract;
    procedure vaddtona(i,j:integer; x:variant); overload; virtual;
    procedure vaddtona(k,i,j:integer; x:variant); overload; virtual;
    procedure vput(i,j:integer; x:variant); overload; virtual;
    procedure vput(k,i,j:integer; x:variant); overload; virtual;
    procedure writecsv(var f:text);
    procedure zerofill(diagok:boolean=true); virtual;
    property borders:boolean write setborders;
    property n:integer read calcn write setn;
    property vbrn[rname:string; j:integer]:variant read GetVbrn write SetVbrn;
    property vbcn[i:integer; cname:string]:variant read GetVbcn write SetVbcn;
end;
{===========================================================================}
implementation
uses
  utcorr;
{===========================================================================}
constructor tmat.create;
begin
  istable:= false;
  nr:= 0; nc:= 0; nm:= 1; nd:= 2; nways:= 3; nmodes:= 3;
  dt:= nodt;
  mt:= mt_unknown;
  vmissing:= maxsingle;
  allocnr:= 0; allocnc:= 0; allocnm:= 0;
  rdvn:= tstrvec.create; rdvn.name:= 'row'; rdvn.compareasnumbers:= true;
  cdvn:= tstrvec.create; cdvn.name:= 'column'; cdvn.compareasnumbers:= true;
                {rdvn.prefix:= 'R'; cdvn.prefix:= 'C';}
  mdvn:= tstrvec.create; mdvn.name:= 'relation'; mdvn.compareasnumbers:= true;
  rdsl:= tdsl.create;
  cdsl:= tdsl.create;
  mdsl:= tdsl.create;
  colformat:= tstrvec.create;
  vptr:= nil;
  title:= '';               {if mptr <> nil then pointer(mptr^):= nil;}
  comments:= tstringlist.Create;
  comments.Delimiter:= '|';
  binary:= 0;
  similarities:= 0;
  writerownumbers:= true;
  writecolnumbers:= true;
  writedimensions:= true;
  writetitle:= true;
end;
{---------------------------------------------------------------------------}
procedure tmat.clear;
begin
  zerofill(true);
  nr:= 0; nc:= 0; nm:= 0; nd:= 2; diagok:= true;
  comments.Clear; title:= '';
end;
{---------------------------------------------------------------------------}
procedure tmat.copy2str(buf:string);
//copy dataset to clipboard
const
  TAB = #9;
  CR = #13;
var
  k,i,j: integer;
begin
  buf:= 'Nodes' + tab;
  for j:= 1 to nc-1 do
    buf:= buf + cdvn.labelget(j) + tab;
  buf:= buf + cdvn.labelget(nc) + cr;
  for i:= 1 to nr do begin
    buf:= buf + rdvn.labelget(i) + tab;
    for j:= 1 to nc-1 do
      buf:= buf + sget(i,j) + tab;
    buf:= buf + sget(i,nc) + cr;
    end;
end;
{---------------------------------------------------------------------------}
procedure tmat.fillrect(r1,c1,r2,c2:integer; f:integer=0);
var
  i,j: integer;
begin
  for i:= r1 to r2 do
    for j:= c1 to c2 do
      iput(i,j,f);
end;
{---------------------------------------------------------------------------}
procedure tmat.fillrect(r1,c1,r2,c2:integer; f:single=0);
var
  i,j: integer;
begin
  for i:= r1 to r2 do
    for j:= c1 to c2 do
      fput(i,j,f);
end;
{---------------------------------------------------------------------------}
procedure tmat.setborders(abool:boolean);
begin
  writerownumbers:= abool;
  writecolnumbers:= abool;
  writedimensions:= abool;
end;
{---------------------------------------------------------------------------}
function tmat.getvbrn(rname:string; j:integer): variant;
var i: integer;
begin
  i:= rdvn.lookupstr(rname);
  if (i > 0) and (i <= nr) then result:= vget(i,j);
end;
{---------------------------------------------------------------------------}
function tmat.identifynode(name:string): integer;
var i: integer;
begin
  i:= rdvn.lookupstr(name);
  if (i > 0) and (i <= nr)
    then result:= i
    else result:= strtointdef(name,0);
end;
{---------------------------------------------------------------------------}
procedure tmat.setvbrn(rname:string; j:integer; x:variant);
var i: integer;
begin
  i:= rdvn.lookupstr(rname);
  if (i > 0) and (i <= nr) then vput(i,j,x);
end;
{---------------------------------------------------------------------------}
function tmat.getvbcn(i:integer; cname:string): variant;
var j: integer;
begin
  j:= cdvn.lookupstr(cname);
  if (j > 0) and (i > 0) and (i <= nr)
    then result:= vget(i,j)
    else result:= bna;
end;
{---------------------------------------------------------------------------}
procedure tmat.setvbcn(i:integer; cname:string; x:variant);
var j: integer;
begin
  j:= cdvn.lookupstr(cname);
  if (j > 0) and (i > 0) and (i <= nr)
    then vput(i,j,x);
end;
{---------------------------------------------------------------------------}
function tmat.trygetcol(const colstr:string; out col:integer): boolean;
var temp: integer;
begin
  col:= 0;
  if iskey(colstr,'alpha|row|lab')
    then exit(true);
  if trystrtoint(colstr,col) and (not cdvn.hasval)
    then exit(col <= cdvn.n);
  temp:= cdvn.lookupstr(colstr,false);
  if temp > 0 then col:= temp;
  result:= col > 0;
end;
{---------------------------------------------------------------------------}
function tmat.addkeypair(s:string; v:variant; i:integer=1): integer;
var
  oldnr: integer;
begin
  oldnr:= nr;
  reallocsize(oldnr+1,max(nc,i));
  vput(nr,i,v);
  rdvn.reallocsize(nr);
  rdvn.cell[nr]:= s;
end;
{---------------------------------------------------------------------------}
procedure tmat.appendrows(x:tmat);
var
  i,j,oldnr: integer;
begin
  oldnr:= nr;
  reallocsize(oldnr+x.nr,nc);
  rdvn.reallocsize(nr);
  for i:= 1 to x.nr do begin
    rdvn.sput(oldnr+i,x.rdvn.labelget(i));
    for j:= 1 to nc do
      vput(oldnr+i,j, x.vget(i,j));
    end;
end;
{---------------------------------------------------------------------------}
procedure tmat.copycell(toi,toj,fromi,fromj:integer);
begin
  vput(toi,toj,vget(fromi,fromj));
end;
{---------------------------------------------------------------------------}
procedure tmat.copyfrom(x:tmat; toi,toj,fromi,fromj:integer);
begin
  vput(toi,toj,x.vget(fromi,fromj));
end;
{---------------------------------------------------------------------------}
procedure tmat.copycol2vec(v:tvec; c:integer);
var i: integer;
begin
  v.allocsize(nr);
  for i:= 1 to nr do
    v.vput(i,vget(i,c));
end;
{---------------------------------------------------------------------------}
procedure tmat.copyvec2col(v:tvec; c:integer=-1);
var
  i,n: integer;
begin
  if c < 1 then c:= nc + 1;
  if c > allocnc then
    allocate(nr,c,nm,false,false);
  nc:= max(c,nc);
  n:= min(nr,v.n);
  for i:= 1 to n do
    fput(i,c,v.vget(i));
end;
{---------------------------------------------------------------------------}
procedure tmat.deletecol(c:integer);
var i,k: integer;
begin
  Dec(nc);
  for i:= 1 to nr do begin
    if c <= nc then
      for k:= c to nc do
        vput(i,k,vget(i,k+1));
    end;
  if cdvn.hasval
    then cdvn.deletejth(c);
end;
{---------------------------------------------------------------------------}
procedure tmat.deleterow(r:integer);
var j,k: integer;
begin
  Dec(nr);
  for j:= 1 to nc do begin
    if r <= nr then
      for k:= r to nr-1 do
        vput(k,j,vget(k+1,j));
    end;
  if rdvn.hasval
    then rdvn.deletejth(r);
end;
{---------------------------------------------------------------------------}
procedure tmat.deleterows(rows: tlist<integer>);
var
  sorted: tlist<integer>;
  toDelete: array of boolean;
  i,j,src,dst,numDel: integer;
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
    // compact rows
    dst:= 0;
    for src:= 1 to nr do
      if not toDelete[src] then begin
        inc(dst);
        if dst <> src then
          for j:= 1 to nc do
            vput(dst,j,vget(src,j));
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
procedure tmat.deletecols(cols: tlist<integer>);
var
  sorted: tlist<integer>;
  toDelete: array of boolean;
  i,j,src,dst,numDel: integer;
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
    // compact columns
    for i:= 1 to nr do begin
      dst:= 0;
      for src:= 1 to nc do
        if not toDelete[src] then begin
          inc(dst);
          if dst <> src then
            vput(i,dst,vget(i,src));
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
procedure tmat.deletenode(n: integer);
begin
  deleterow(n);
  deletecol(n);
end;
{---------------------------------------------------------------------------}
procedure tmat.deletenodes(nodes: tlist<integer>);
begin
  deleterows(nodes);
  deletecols(nodes);
end;
{---------------------------------------------------------------------------}
procedure tmat.copyrow2vec(v:tvec; r:integer);
var i: integer;
begin
  v.allocsize(nr);
  for i:= 1 to nr do
    v.vput(i,vget(r,i));
end;
{---------------------------------------------------------------------------}
procedure tmat.copyvec2row(v:tvec; r:integer);
var
  n,i: integer;
begin
  if r > nr then reallocsize(r,nc);
  n:= min(nc,v.n);
  for i:= 1 to n do
    vput(r,i,v.vget(i));
end;
{---------------------------------------------------------------------------}
function tmat.insertcol(k:integer; name:string=''; data:tvec=nil; format:string=''):integer;
var
  i,j: integer;

  procedure inserthdr;
  begin
{    if k <= nc
      then cdvn.allocsize(nc+1,true)
      else cdvn.allocsize(k,true);}
    if name = ''
      then name:= cdvn.prefix + inttostr(k);
    cdvn.insertbefore(k,name);
    colformat.insertbefore(k,format);
  end;

  procedure insertdata;
  var i,j: integer;
  begin
    realloc(nr,cdvn.n);
    for j:= nc downto k do
      for i:= 1 to nr do
        copycell(i,j+1,i,j);
    if cdvn.n > nc then nc:= cdvn.n;
    if data <> nil
      then copyvec2col(data,k);
  end;

begin
  if k < 1 then exit;
  inserthdr;
  insertdata;
  result:= k;
end;
{---------------------------------------------------------------------------}
function tmat.appendcol(name:string=''; data:tvec=nil; format:string=''):integer;
begin
  storecol(n+1,data,format,name);
end;
{---------------------------------------------------------------------------}
function tmat.isintegervalued(col:integer; diagok:boolean=true): boolean;
var i: integer;
begin
  if dt in [integerdt,bytedt] then exit(true);
  if not is1mode then diagok:= true;
  for i:= 1 to nr do
    if ((i<>col) or diagok) and (not isna(i,col)) then
      if frac(abs(fget(i,col))) > 0.00001
        then begin result:= false; exit; end;
  result:= true;
end;
{---------------------------------------------------------------------------}
function tmat.isintegervalued(diagok:boolean=true): boolean;
var j: integer;
begin
  if dt in [integerdt,bytedt] then exit(true);
  for j:= 1 to nc do
    if not isintegervalued(j)
      then exit(false);
  result:= true;
end;
{---------------------------------------------------------------------------}
function tmat.getminwidth(d:integer; num:integer; diagok:boolean=true):integer;
{Returns the minimum column width needed to display values via fstr(value, w, d).
 For |value| in [0,1), the integer part is just "0" (1 char) regardless of how
 small the value is — the old formula `trunc(log10(|max|))+1` returned negative
 widths for values like 0.004 (log10 = -2.4 → trunc -2), causing headers/dashes
 to be too narrow and values to overflow them.}
Var
  ma,mi,mami: extended;
  intpart: integer;
Begin
  getminmax(mi,ma,false,diagok);
  mami:= max(abs(ma),abs(mi));
  if mami >= 1
    then intpart:= trunc(log10(mami)) + 1
    else intpart:= 1; {leading "0" for values in (-1, 1), incl. all-zero matrices}
  result:= intpart;
  if abs(d) > 0 then result:= result + abs(d) + 1; {decimal point + decimals}
  if mi < 0 then inc(result);  {sign}
  if num > 0 then result:= max(result, length(inttostr(num)));
End;
{---------------------------------------------------------------------------}
function tmat.getminwidthfstr(d:integer; diagok:boolean=true):integer;
Var
  i,j,width: integer;
Begin
  result:= 0;
  for i:= 1 to nr do
    for j:= 1 to nc do begin
      width:= length(fstr(fget(i,j),0,d));
      if width > result
        then result:= width;
      end;
End;
{---------------------------------------------------------------------------}
function tmat.getminwidthbycol(col,d:integer; diagok:boolean=true):integer;
Var
  i,j,width: integer;
Begin
  result:= 0;
  for i:= 1 to nr do begin
    width:= length(fstr(fget(i,col),0,d));
    if width > result
      then result:= width;
    end;
End;
{---------------------------------------------------------------------------}
function tmat.gettrace: double;
Var
  i: integer;
Begin
  result:= 0;
  for i:= 1 to n do
    result:= result + fget(i,i);
End;
{---------------------------------------------------------------------------}
function tmat.resizerowsto(newnc:integer; changenc:boolean=false): boolean;
begin
  {must override}
end;
{---------------------------------------------------------------------------}
function tmat.replacecol(col:integer; data:tvec=nil; format:string=''; name:string=''): integer;
var
  i: integer;
begin
  if col < 1 then col:= nc + 1;
  if col > nc then nc:= col;
  if data <> nil then if data.n > nr then nr:= data.n;
  if (nc > allocnc) or (nr > allocnr) then
    if nm > 1
      then alloc(nr,nc,nm,false)
      else alloc(nr,nc,false);
  copyvec2col(data,col);
  if format <> '' then
    colformat.safesetvalue(col,format);
  if name <> '' then
    cdvn.safesetvalue(col,name);
  result:= col;
end;
{---------------------------------------------------------------------------}
function tmat.storecol(col:integer; data:tvec=nil; format:string=''; name:string=''):integer;
var
  i: integer;
begin
  if col < 1 then col:= nc+1;
  if data <> nil then nr:= max(nr,data.n);
  try
  allocateatleast(nr,col);
  if data <> nil then
    copyvec2col(data,col);
  if format <> '' then
    colformat.safesetvalue(col,format);
  if name <> '' then
    cdvn.safesetvalue(col,name);
  if col > nc
    then nc:= col;
  result:= col;
  except
    showmessage('Unable to store results for '+name);
  end;
end;
{---------------------------------------------------------------------------}
function tmat.storevariable(name:string=''; data:tvec=nil; format:string=''): integer;
begin
  result:= storecol(cdvn.lookupstr(name),data,format,name);
end;
{---------------------------------------------------------------------------}
procedure tmat.reversecols;
var 
  i: integer;
begin
  for i:= 1 to n div 2 do
    swapcols(i,n+1-i);
end;
{---------------------------------------------------------------------------}
procedure tmat.copylabels(m:tmat);
begin
  rdvn.copy(m.rdvn); cdvn.copy(m.cdvn);
  mdvn.copy(m.mdvn); mdvn.n:= nm;
end;
{---------------------------------------------------------------------------}
function tmat.inrange(xnr,xnc: integer): boolean;
begin
  result:= (xnr <= nr) and (xnc <= nc) and (xnr > 0) and (xnc > 0);
end;
{---------------------------------------------------------------------------}
function tmat.mptr: pointer;
begin end;
{---------------------------------------------------------------------------}
function tmat.rptr(i:integer): pointer;
{must override}
begin
     {rptr:= cell^[i];}
end;
{---------------------------------------------------------------------------}
procedure tmat.dealloc;
begin deallocate; end;
{---------------------------------------------------------------------------}
//procedure tmat.deallocate;
//begin showmessage('Something''s wrong. This should not be happening. Seriously.'); end;
{---------------------------------------------------------------------------}
function tmat.alloc(xnr,xnc:integer; size:boolean): boolean;
begin result:= allocate(xnr,xnc,nm,size,true); end;
{---------------------------------------------------------------------------}
function tmat.alloc(xnr,xnc,xnm:integer): boolean;
begin result:= allocate(xnr,xnc,xnm,false,true); end;
{---------------------------------------------------------------------------}
function tmat.alloc(xnr,xnc,xnm:integer; size:boolean): boolean;
begin result:= allocate(xnr,xnc,xnm,size,true); end;
{---------------------------------------------------------------------------}
function tmat.alloc(xnr,xnc:integer): boolean;
begin result:= allocate(xnr,xnc,nm,false,true); end;
{---------------------------------------------------------------------------}
function tmat.alloc(xn:integer): boolean;
begin result:= allocate(xn,xn,nm,false,true); end;
{---------------------------------------------------------------------------}
//function tmat.allocate(xnr,xnc,xnm:integer; setsize,zfill:boolean): boolean;
//begin showmessage('ERROR: Attempting to allocate generic matrix.'); end;
{---------------------------------------------------------------------------}
function tmat.allocateatleast(xnr,xnc:integer): boolean;
begin
  if (xnr > allocnr) or (xnc > allocnc)
    then result:= allocateonly(max(xnr,allocnr),max(xnc,allocnc))
    else result:= true;
end;
{---------------------------------------------------------------------------}
function tmat.allocateonly(xnr,xnc:integer): boolean;
begin
  allocate(xnr,xnc,nm,false,false);
//  result:= FALSE;
//  raise exception.Create('Function AllocateOnly not yet implemented');
end;
{---------------------------------------------------------------------------}
function tmat.realloc(xnr,xnc:integer; size:boolean=false): boolean;
begin result:= allocate(xnr,xnc,nm,size,false); end;
{---------------------------------------------------------------------------}
function tmat.reallocsize(xnr,xnc:integer): boolean;
begin
  result:= allocate(xnr,xnc,nm,true,false); //must not zerofill
end;
{---------------------------------------------------------------------------}
function tmat.allocsize(xnr:integer; xnc:integer=-1): boolean;
begin
  if xnc < 0 then xnc:= xnr;
  result:= allocate(xnr,xnc,nm,true,true);
end;
{---------------------------------------------------------------------------}
function tmat.allocsize(xnr,xnc,xnm: integer): boolean;
begin result:= allocate(xnr,xnc,xnm,true,true); end;
{---------------------------------------------------------------------------}
function tmat.alloclabels(dim:integer=0): boolean;
label cleanup;
begin
  if dim in [0,1] then cdvn.allocsize(nc);
  if error <> 0 then goto cleanup;
  if dim in [0,2] then rdvn.allocsize(nr);
  if dim in [0,3] then mdvn.allocsize(nm);
  cleanup:
    alloclabels:= error = 0;
end;
{---------------------------------------------------------------------------}
procedure tmat.setsize(r:integer; c:integer=0);
var
  oldc,oldr,i,j: integer;
begin
  if c = 0 then c:= r;
  oldc:= self.nc; oldr:= self.nr;
  allocate(r,c,-1,true,false);
  exit;
  if (r <= oldr) and (c <= oldc) then exit;
  fillrect(1,oldc+1,r,c,0); //fill up the extra cols
  fillrect(oldr+1,1,r,c,0); //fill up the extra rows
End;
{---------------------------------------------------------------------------}
function tmat.hasval: boolean;
begin
  try
    hasval:= (pointer(mptr^) <> nil) or (allocnr > 0) or (allocnc > 0);
  except
    result:= false;
  end;
end;
{---------------------------------------------------------------------------}
function tmat.copydef(m:tmat): boolean;
label cleanup;
begin
  try
    error:= 1;
     nr:= m.nr; nc:= m.nc; nm:= m.nm;
     if dt = nodt then dt:= m.dt;
     istable:= m.istable;
     if m.rdsl.hasval then
         if not rdsl.copy(m.rdsl) then goto cleanup;
     if m.cdsl.hasval then
         if not cdsl.copy(tvec(m.cdsl)) then goto cleanup;
     if m.mdsl.hasval then
         if not mdsl.copy(tvec(m.mdsl)) then goto cleanup;
     if m.rdvn.hasval then
         if not rdvn.copy(tvec(m.rdvn)) then goto cleanup;
     if m.cdvn.hasval then
         if not cdvn.copy(tvec(m.cdvn)) then goto cleanup;
     if m.mdvn.hasval then
         if not mdvn.copy(tvec(m.mdvn)) then goto cleanup;
     comments.Assign(m.comments);
//     comment.copy(tvec(m.comment));
  error:= 0;
  cleanup:
  finally
     result:= error = 0;
  end;
end;
{---------------------------------------------------------------------------}
function tmat.copydefdsl(m:tmat): boolean;
label cleanup;
begin
  if not m.rdsl.hasval
    then begin m.rdsl.allocsize(m.nr,true); m.rdsl.one2n; end;
  if not m.cdsl.hasval
    then begin m.cdsl.allocsize(m.nc,true); m.cdsl.one2n; end;
  if not m.mdsl.hasval
    then begin m.mdsl.allocsize(m.nm,true); m.mdsl.one2n; end;
  if rdvn.copydsl(tvec(m.rdvn),tvec(m.rdsl)) = -1 then goto cleanup;
  if cdvn.copydsl(tvec(m.cdvn),tvec(m.cdsl)) = -1 then goto cleanup;
  if mdvn.copydsl(tvec(m.mdvn),tvec(m.mdsl)) = -1 then goto cleanup;
//  comment.copy(tvec(m.comment));
  comments.Assign(m.comments);
  nr:= m.rdsl.n; nc:= m.cdsl.n; nm:= m.mdsl.n;
  if dt = nodt then dt:= m.dt;
  istable:= m.istable;
  cleanup:
    result:= error = 0;
end;
{---------------------------------------------------------------------------}
function tmat.copyval(m:tmat): boolean;
label cleanup;
var
  i,j: integer;
begin
  if not allocsize(m.nr,m.nc) then goto cleanup;
  if (allocnr < m.nr) or (allocnc < m.nc)
    then allocate(m.nr,m.nc,1,false,false);
  if dt = m.dt
    then for i:= 1 to nr do
      move(m.rptr(i)^,rptr(i)^,(m.nc)*dtsize[dt])
    else for i:= 1 to nr do for j:= 1 to nc do
      fput(i,j,m.fget(i,j));
cleanup:
     copyval:= error = 0;
end;
{---------------------------------------------------------------------------}
(*function tmat.copyval(m:tmat): boolean;
label cleanup;
var
  nrow,ncol,i,j: integer;
begin
  if (allocnr < m.allocnr) or (allocnc < m.allocnc) then
    if not allocsize(m.nr,m.nc) then goto cleanup;
  if nr < m.nr then nrow:= m.nr else nrow:= nr;
  if nc < m.nc then ncol:= m.nc else ncol:= nc;
  if dt = m.dt
    then move(m.mptr^,mptr^,(nrow+1)*(ncol+1)*dtsize[dt])
      {for i:= 1 to nrow do
        move(m.rptr(i)^,rptr(i)^,ncol*dtsize[dt])}
    else for i:= 1 to nrow do for j:= 1 to ncol do
      vput(i,j,m.vget(i,j));
cleanup:
     copyval:= error = 0;
end;*)
{---------------------------------------------------------------------------}
function tmat.copydeftransposed(m:tmat): boolean;
label cleanup;
begin
     nr:= m.nc; nc:= m.nr; nm:= m.nm;
     if dt = nodt then dt:= m.dt;
     if m.cdsl.hasval then
         if not rdsl.copy(m.cdsl) then goto cleanup;
     if m.rdsl.hasval then
         if not cdsl.copy(tvec(m.rdsl)) then goto cleanup;
     if m.mdsl.hasval then
         if not mdsl.copy(tvec(m.mdsl)) then goto cleanup;
     if m.cdvn.hasval then
         if not rdvn.copy(tvec(m.cdvn)) then goto cleanup;
     if m.rdvn.hasval then
         if not cdvn.copy(tvec(m.rdvn)) then goto cleanup;
     if m.mdvn.hasval then
         if not mdvn.copy(tvec(m.mdvn)) then goto cleanup;
     comments.Assign(m.comments);
//     comment.copy(tvec(m.comment));
  cleanup:
     result:= error = 0;
end;
{---------------------------------------------------------------------------}
function tmat.copyvaltransposed(m:tmat): boolean;
label cleanup;
var
  i,j: integer;
begin
  if (allocnr < m.nc) or (allocnc < m.nr) then
    if not allocsize(m.nc,m.nr) then goto cleanup;
  for i:= 1 to m.nr do for j:= 1 to m.nc do
      vput(j,i,m.vget(i,j));
cleanup:
     result:= error = 0;
end;
{---------------------------------------------------------------------------}
function tmat.copyvaldsl(m:tmat): boolean;
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
      fput(i,j,m.fget(m.rdsl.cell[i],m.cdsl.cell[j]));
cleanup:
     result:= error = 0;
end;
{---------------------------------------------------------------------------}
function tmat.copy(m:tmat): boolean;
//if nm > 1, this routine will obviously only copy the first
begin
  if copydef(m)
    then copyval(m);
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
function tmat.copydsl(m:tmat): boolean;
begin
  if copydefdsl(m)
    then copyvaldsl(m);
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
function tmat.vget(i,j:integer): variant;
begin end;
{---------------------------------------------------------------------------}
procedure tmat.vput(i,j:integer; x:variant);
begin end;
{---------------------------------------------------------------------------}
function tmat.vget(k,i,j:integer): variant;
begin end;
{---------------------------------------------------------------------------}
procedure tmat.vput(k,i,j:integer; x:variant);
begin end;
{---------------------------------------------------------------------------}
function tmat.equal(i1,j1,i2,j2:integer): boolean;
begin
  result:= feq(fget(i1,j1),fget(i2,j2));
end;
{---------------------------------------------------------------------------}
function tmat.fget(i,j:integer): extended;
{must override}
begin
     {fget:= cell^[i]^[j];}
end;
{---------------------------------------------------------------------------}
function tmat.sget(i,j:integer): string;
begin
  if fget(i,j) < na
    then result:= fstr(fget(i,j))
    else result:= '';
end;
{---------------------------------------------------------------------------}
function tmat.isna(i,j:integer): boolean;
begin
  result:= not isvalid(i,j);
end;
{---------------------------------------------------------------------------}
function tmat.iszero(i,j:integer): boolean;
begin
  result:= math.IsZero(fget(i,j),singleprecision);
end;
{---------------------------------------------------------------------------}
function tmat.isvalid(i,j:integer): boolean;
begin
  result:= vget(i,j) < vmissing;
end;
{---------------------------------------------------------------------------}
function tmat.sameas(i1,j1,i2,j2:integer): boolean;
begin
  result:= vget(i1,j1) = vget(i2,j2);
end;
{---------------------------------------------------------------------------}
function tmat.adjacent(i,j:integer): boolean;
{should override}
begin
  result:= iget(i,j) > 0;
end;
{---------------------------------------------------------------------------}
procedure tmat.addtie(i,j:integer);
{should override}
begin iput(i,j,0); end;
{---------------------------------------------------------------------------}
procedure tmat.swapcells(i,j,ii,jj: integer);
var v:variant;
begin
  v:= vget(i,j);
  vput(i,j,vget(ii,jj));
  vput(ii,jj,v);
end;
{---------------------------------------------------------------------------}
function tmat.transposesquarematrix: boolean;
var
  i,j: integer;
begin
  result:= true;
  if not issquare then begin
    result:= false;
    raise exception.Create('Not square');
    end;
  for i:= 2 to n do for j:= 1 to i-1 do
    swapcells(i,j,j,i);
  swapstrvecs(rdvn,cdvn);
  swapivecs(rdsl,cdsl);
  if length(title) = 0
    then title:= 'Transpose'
    else title:= 'Transpose of ' + title;
end;
{---------------------------------------------------------------------------}
function tmat.iget(i,j:integer): longint;
{must override}
begin
     {iget:= round(cell^[i]^[j]);}
end;
{---------------------------------------------------------------------------}
procedure tmat.fput(i,j:integer; x:extended; e:extended=0);
{must override}
begin {cell^[i]^[j]:= x;} end;
{---------------------------------------------------------------------------}
procedure tmat.iput(i,j:integer; x:longint);
{must override}
begin {cell^[i]^[j]:= x;} end;
{---------------------------------------------------------------------------}
procedure tmat.safeiput(i,j:integer; x:longint);
begin
  if (i < 1) or (j < 1) then exit;
  if (i <= allocnr) and (j <= allocnc)
    then iput(i,j,x)
    else begin
      reallocsize(max(i,nr),max(j,nc));
      iput(i,j,x);
      end;
end;
{---------------------------------------------------------------------------}
procedure tmat.faddto(i,j:integer; x:extended);
{should override}
begin fput(i,j,fget(i,j)+x); end;
{---------------------------------------------------------------------------}
procedure tmat.iaddto(i,j:integer; x:integer);
{should override}
begin fput(i,j,fget(i,j)+x); end;
{---------------------------------------------------------------------------}
procedure tmat.faddtona(i,j:integer; x:extended);
{should override}
begin
  if fget(i,j) < na
    then fput(i,j,fget(i,j)+x)
    else fput(i,j,x);
end;
{---------------------------------------------------------------------------}
procedure tmat.vaddtona(i,j:integer; x:variant);
begin
  if (not varisnull(vget(i,j))) and (vget(i,j) < na)
    then vput(i,j,vget(i,j)+x)
    else vput(i,j,x);
end;
{---------------------------------------------------------------------------}
procedure tmat.vaddtona(k,i,j:integer; x:variant);
begin
  if (not varisnull(vget(k,i,j))) and (vget(k,i,j) < na)
    then vput(k,i,j,vget(k,i,j)+x)
    else vput(k,i,j,x);
end;
{---------------------------------------------------------------------------}
function tmat.calcn: integer;
begin
  if (nr > 0) and (nc > 0)
    then result:= min(nr,nc)
    else if nr > 0
      then result:= nr
      else result:= nc;
end;
{---------------------------------------------------------------------------}
procedure tmat.setn(n: integer);
begin setdim(n,n,-1,false); end;
{---------------------------------------------------------------------------}
function tmat.trace: double;
var
  i: integer;
begin
  result:= 0;
  for i:= 1 to n do 
    if not isna(i,i)
      then result:= result + fget(i,i);
end;
{---------------------------------------------------------------------------}
function tmat.IsSquare: boolean;
begin result:= nr = nc; end;
{---------------------------------------------------------------------------}
function tmat.rclabelsmatch: integer;
var i: integer;
begin
  result:= 0;
  if nr <> nc then exit;
  for i:= 1 to nr do
    if lowercase(trim(rdvn.labelget(i))) = lowercase(trim(cdvn.labelget(i))) 
      then inc(result) 
end;
{---------------------------------------------------------------------------}
function tmat.Is1mode: boolean;
var i: integer;
begin
  if nr = nc
    then for i:= 1 to nr do
      if rdvn.labelget(i) <> cdvn.labelget(i)
        then exit(false)
        else
    else exit(false);
  result:= true;
end;
{---------------------------------------------------------------------------}
function tmat.Is2mode: boolean;
var i: integer;
begin
  result:= not is1mode;
end;
{---------------------------------------------------------------------------}
function tmat.isautomorphism(p:tivec): boolean;
var i,j: integer;
begin
  for i:= 1 to n do
    for j:= 1 to n do
      if fneq(fget(p.cell[i],p.cell[j]),fget(i,j))
        then exit(false);
  result:= true;
end;
{---------------------------------------------------------------------------}
function tmat.IsSymmetric(ignorena:boolean=false): boolean;
var i,j: integer;
begin
  if not issquare then exit(false);
  if ignorena
    then begin
      for i:= 2 to nr do for j:= 1 to i-1 do
        if (not isna(i,j)) or (not isna(j,i)) then
          if not equal(i,j,j,i) then exit(false);
      end
    else begin
      for i:= 2 to nr do for j:= 1 to i-1 do
        if (not isna(i,j)) or (not isna(j,i)) then
          if not equal(i,j,j,i) then exit(false);
      end;
  result:= true;
end;
{---------------------------------------------------------------------------}
function tmat.getmodes: integer;
var nagree: integer;
begin
  nagree:= 0;
  if cdvn.sameness(rdvn) = 1 then inc(nagree);
  if cdvn.sameness(mdvn) = 1 then inc(nagree);
  if rdvn.sameness(mdvn) = 1 then inc(nagree);
  case nagree of
    3: result:= 1;
    1: result:= 2;
    0: result:= 1;
    else result:= -1;
    end;
end;
{---------------------------------------------------------------------------}
function tmat.smallenoughtodisplay: boolean;
begin
  result:= oktodisplay(nr,nc,nm);
end;
{---------------------------------------------------------------------------}
function tmat.isbinary(diagok:boolean=false): boolean;
begin
  result:= not isvalued(diagok);
end;
{---------------------------------------------------------------------------}
function tmat.IsValued(diagok:boolean=true): boolean;
var
  i,j: integer;
  x: extended;
begin
  if not issquare then diagok:= true;
  for i:= 1 to nr do for j:= 1 to nc do if (i<>j) or diagok then begin
    x:= fget(i,j);
    if x < na then
      if not (samevalue(x,0) or samevalue(x,1))
        then exit(true);
    end;
  result:= false;
end;
{---------------------------------------------------------------------------}
function tmat.reorderrows(var o:tivec): boolean;
var
  temp: array of variant;
  i,j: integer;
begin
  try
    setlength(temp,nr+1);
    for j:= 1 to nc do begin
      for i:= 1 to nr do temp[i]:= vget(i,j);
      for i:= 1 to nr do vput(i,j,temp[o[i]]);
      end;
  except
    error:= 1;
  end;
  temp:= nil;
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
function tmat.reordercols(var o:tivec): boolean;
var
  temp: array of variant;
  i,j: integer;
begin
  try
    setlength(temp,nc+1);
    for i:= 1 to nr do begin
      for j:= 1 to nc do temp[j]:= vget(i,j);
      for j:= 1 to nc do vput(i,j,temp[o[j]]);
      end;
  except
    error:= 1;
  end;
  temp:= nil;
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
function tmat.getcollabel(j:integer): string;
begin result:= cdvn.labelget(j); end;
{---------------------------------------------------------------------------}
function tmat.getmatlabel(k:integer): string;
begin result:= mdvn.labelget(k); end;
{---------------------------------------------------------------------------}
function tmat.getrowlabel(i:integer): string;
begin result:= rdvn.labelget(i); end;
{---------------------------------------------------------------------------}
procedure tmat.getmarginals(r,c:tdvec; diagok:boolean=false);
var
  i,j: integer;
begin
  r.allocate(nr,true);
  c.allocate(nc,true);
  if nr <> nc then diagok:= true;
  for i:= 1 to nr do
    for j:= 1 to nc do if (i <> j) or diagok then begin
      r.cell[i]:= r.cell[i] + fget(i,j);
      c.cell[j]:= c.cell[j] + fget(i,j);
      end;
end;
{---------------------------------------------------------------------------}
function tmat.getrowsum(i:integer; diagok:boolean=true): double;
var
  j: integer;
begin
  if not issquare then diagok:= true;
  result:= 0;
  for j:= 1 to nc do if (i<>j) or diagok then
    if not isna(i,j)
      then result:= result + fget(i,j);
end;
{---------------------------------------------------------------------------}
function tmat.getweightedrowsum(i:integer; w:tvec; diagok:boolean=true): variant;
var
  j: integer;
begin
  if not issquare then diagok:= true;
  result:= 0;
  for j:= 1 to nc do if (i<>j) or diagok then
    if not isna(i,j)
      then result:= result + fget(i,j)*w.fget(j);
end;
{---------------------------------------------------------------------------}
function tmat.getstats(diagok:boolean=false): tstatsrec;
var
  i,j: integer;
  u: tunivariate;
begin
  u:= tunivariate.create;
  if not is1mode then diagok:= true;
  for i := 1 to nr do
    for j := 1 to nc do if (i<>j) or diagok then
      u.addcase(fget(i,j));
  u.calc;
  result:= u.asTstatsRec;
  u.free;
end;
{---------------------------------------------------------------------------}
function tmat.getrowstats(i:integer; diagok:boolean=false): tstatsrec;
var
  j: integer;
  u: tunivariate;
begin
  u:= tunivariate.create;
  if not issquare then diagok:= true;
  for j := 1 to nc do if (i<>j) or diagok then
    u.addcase(fget(i,j));
  result:= u.asTstatsRec;
  u.free;
end;
{---------------------------------------------------------------------------}
function tmat.getcolstats(j:integer; diagok:boolean=false): tstatsrec;
var
  i: integer;
  u: tunivariate;
begin
  u:= tunivariate.create;
  if not issquare then diagok:= true;
  for i := 1 to nr do if (i<>j) or diagok then
    u.addcase(fget(i,j));
  result:= u.asTstatsRec;
  u.free;
end;
{---------------------------------------------------------------------------}
procedure tmat.submatrix;
{assumes rdsl and cdsl set by caller}
{note: rdsl and cdsl are deallocated on exit}
var
  i,j: integer;
begin
  rdsl.sort('a',nil);
  cdsl.sort('a',nil);
  for i:= 1 to rdsl.n do for j:= 1 to cdsl.n do
    vput(i,j,vget(rdsl.iget(i),cdsl.iget(j)));
  for i:= 1 to rdsl.n do rdvn[i]:= rdvn[rdsl[i]];
  for j:= 1 to cdsl.n do cdvn[j]:= cdvn[cdsl[j]];
  nr:= rdsl.n; nc:= cdsl.n;
  rdsl.dealloc; cdsl.dealloc;
end;
{---------------------------------------------------------------------------}
procedure tmat.extractfrom(x:tmat; r1,c1,rn,cn:integer);
var
  i,j: integer;
begin
  allocate(rn-r1+1,cn-c1+1,1,true,true);
  for i:= r1 to rn do
    for j:= c1 to cn do
      copyfrom(x,i-r1+1,j-c1+1,i,j);
//      fput(i-r1+1,j-c1+1,x.fget(i,j));
  rdvn.allocate(nr,true,true);
  for i:= r1 to rn do
    rdvn.sput(i-r1+1,x.rdvn.labelget(i));
  cdvn.allocate(nc,true,true);
  for j:= c1 to cn do
    cdvn.sput(j-c1+1,x.cdvn.labelget(j));
end;
{---------------------------------------------------------------------------}
procedure tmat.recode(op:tdichop; cut:double; newval:double; diagok:boolean=false);
//opgt = 0; opge = 1; opeq = 2; ople = 3; oplt = 4; opne = 5;
var
  i,j: integer;
begin
  if nr <> nc then diagok:= true;
  for i:= 1 to nr do for j:= 1 to nc do 
    if ((i<>j) or diagok) and (not isna(i,j)) then
      case op of
         opgt: if fget(i,j) > cut then fput(i,j,newval);
         opge: if fget(i,j) >= cut then fput(i,j,newval);
         opeq: if feq(fget(i,j),cut) then fput(i,j,newval);
         ople: if fget(i,j) <= cut then fput(i,j,newval);
         oplt: if fget(i,j) < cut then fput(i,j,newval);
         opne: if fget(i,j) <> cut then fput(i,j,newval);
         end;
//  displayasmatrix('test.txt');
end;
{---------------------------------------------------------------------------}
procedure tmat.recodena(newval:single=0; diagok:boolean=false);
var
  i,j: integer;
begin
  if nr <> nc then diagok:= true;
  for i:= 1 to nr do for j:= 1 to nc do if (i<>j) or diagok then
    if isna(i,j) then fput(i,j,newval);
end;
{---------------------------------------------------------------------------}
Procedure tmat.zerofill(diagok:boolean=true);
{should override}
var
  i,j: integer;
begin
  for i:= 1 to nr do for j:= 1 to nc do 
    if (i<>j) or diagok 
      then iput(i,j,0);
end;
{---------------------------------------------------------------------------}
Procedure tmat.nafill(diagok:boolean=true); {override}
Begin
  fill(bna,diagok);
End;
{---------------------------------------------------------------------------}
Procedure tmat.setdiagonal(diag:double);
var i: integer;
Begin
  if not issquare then exit;
  for i:= 1 to n do
    fput(i,i,diag);
End;
{---------------------------------------------------------------------------}
Procedure tmat.fill(filler:double; diagok:boolean=true); {override}
{should override}
var
  i,j: integer;
Begin
  for i:= 1 to nr do for j:= 1 to nc do if (i<>j) or diagok 
    then fput(i,j,filler);
End;
{---------------------------------------------------------------------------}
procedure tmat.swaprows(a,b:integer);
var j: integer;
begin try
  for j:= 1 to nc do
    swapcells(a,j,b,j);
  if rdvn.hasval then rdvn.swap(a,b);
  except
    raise exception.create('Unable to swap cells. '+inttostr(a)+' '+inttostr(b));
end;
end;
{---------------------------------------------------------------------------}
procedure tmat.swapcols(a,b:integer);
var i: integer;
begin try
  for i:= 1 to nr do
    swapcells(i,a,i,b);
  if cdvn.hasval then cdvn.swap(a,b);
  except
    raise exception.create('Unable to swap cells. '+inttostr(a)+' '+inttostr(b));
end;
end;
{---------------------------------------------------------------------------}
function tmat.correlaterows(i,j:integer; diagok:boolean=false): double;
var
  s: tcorr;
  k: integer;
begin try
  s:= tcorr.create;
  if is2mode then diagok:= true;
  for k:= 1 to nc do if ((i<>k) and (j<>k)) or diagok then 
    s.addcase(fget(i,k),fget(j,k));
  s.calc;
  result:= s.corr;
  finally
    s.free;
  end;
end;
{---------------------------------------------------------------------------}
function tmat.correlatecols(i,j:integer; diagok:boolean=false): double;
var
  s: tcorr;
  k: integer;
begin try
  s:= tcorr.create;
  if is2mode then diagok:= true;
  for k:= 1 to nr do if ((i<>k) and (j<>k)) or diagok then
    s.addcase(fget(k,i),fget(k,j));
  s.calc;
  result:= s.corr;
  finally
    s.free;
  end;
end;
{---------------------------------------------------------------------------}
Procedure tmat.sortcolsbylabel(dir:char='a'); {override}
Begin
End;
{---------------------------------------------------------------------------}
Procedure tmat.sortrowsbyattribute(v:tvec; dir:char='a'); {override}
Begin
  sortdimbyattribute(v,'r',dir);
End;
{---------------------------------------------------------------------------}
Procedure tmat.sortrowsbycol(c:integer; dir:char='a'); {override}
var
  v: tdvec;
Begin
  v:= tdvec.create;
  extractcolumn(v,c);
  sortdimbyattribute(v,'r',dir);
  v.free;
End;
{---------------------------------------------------------------------------}
Procedure tmat.sortcolsbyattribute(v:tvec; dir:char='a');
Begin
  sortdimbyattribute(v,'c',dir);
End;
{---------------------------------------------------------------------------}
Procedure tmat.sortdimsbyattributes(r,c:tvec; dir:char='a'); {override}
begin
  sortdimbyattribute(r,'r',dir);
  sortdimbyattribute(c,'c',dir);
end;
{---------------------------------------------------------------------------}
Procedure tmat.sortdimbyattribute(v:tvec; dim:char; dir:char='a');
//the attribute is sorted as well
Label 1,3,fin;
Var
  first,m,k,i,j,im,n: integer;

  function needtoswap: boolean;
  begin
    case dir of
      'a': result:= v.lessthan(im,i);
      'd': result:= v.morethan(im,i);
      end;
  end;

Begin
  case dim of
    'r': n:= nr;
    'c': n:= nc;
    end;
  first:= 1; m:= n;
1:
  m:= m div 2;
  if m = 0 then goto fin;
  k:= n-m + first-1;
  for j:= first to k do begin
    i:= j;
3:  im:= i + m;
    if needtoswap then begin
      case dim of
        'r': swaprows(i,im);
        'c': swapcols(i,im);
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
Procedure tmat.sortdimbylabel(dim:char; dir:char='a'); {override}
Label 1,3,fin;
Var
  first,m,k,i,j,im,n: integer;
  dvn: tstrvec;

  function needtoswap: boolean;
  begin
    case dir of
      'a': result:= dvn.lessthan(im,i);
      'd': result:= dvn.morethan(im,i);
      end;
  end;

Begin
  case dim of
    'r': begin n:= nr; dvn:= rdvn; end;
    'c': begin n:= nc; dvn:= cdvn; end;
    end;
  first:= 1; m:= n;
1:
  m:= m div 2;
  if m = 0 then goto fin;
  k:= n-m + first-1;
  for j:= first to k do begin
    i:= j;
3:  im:= i + m;
    if needtoswap then begin
      case dim of
        'r': swaprows(i,im);
        'c': swapcols(i,im);
        end;
      i:= i-m;
      if i >= first then goto 3;
      end;
    end;
  goto 1;
  fin:
End;
{---------------------------------------------------------------------------}
Procedure tmat.sortrowsbylabel(dir:char='a');
begin
  sortdimbylabel('r',dir);
end;
{---------------------------------------------------------------------------}
function tmat.extractcolumn(c:tvec; wc:integer): boolean;
var
  i: integer;
Begin
  result:= false;
  c.allocifneeded(nr,true,false);
  if c.dt = integerdt
    then for i:= 1 to nr do c.iput(i,iget(i,wc))
    else for i:= 1 to nr do c.fput(i,fget(i,wc));
  result:= true;
End;
{---------------------------------------------------------------------------}
function tmat.extractrow(v:tvec; w:integer): boolean;
label cleanup;
var
  i: integer;
Begin
  try
  result:= false;
  if not v.allocsize(nc) then goto cleanup;
  for i:= 1 to nc do v.fput(i,fget(i,w));
  result:= true;
  cleanup:
  finally
  end;
End;
{---------------------------------------------------------------------------}
function tmat.loadmat(f:ufile): boolean; //should override
var
  i: integer;
begin
  if (allocnr < nr) or (allocnc < nc) then
    if not alloc(nr,nc,false) then exit;
  for i:= 1 to nr do
    f.loadtyped(rptr(i)^,dt,nc);
end;
{---------------------------------------------------------------------------}
function tmat.savemat(f:ufile): boolean;
begin showmessage('Tell Steve he''s an idiot.'); end;
{---------------------------------------------------------------------------}
function tmat.savematdsl(f:ufile): boolean;
begin
  if not rdsl.hasval then rdsl.allocsize(nr);
  if not cdsl.hasval then cdsl.allocsize(nc);
  if not mdsl.hasval then mdsl.allocsize(nm);
  case dt of
    singledt,integerdt: result:= savematdsl(f);
    else showmessage('Steve is an idiot. Be sure to tell him.');
    end;
end;
{---------------------------------------------------------------------------}
procedure tmat.writecsv(var f:text);
var
  i,j: integer;
begin
  write(f,'"ID",');
  for j:= 1 to nc-1 do write(f,'"',cdvn.sget(j),'",');
  writeln(f,'"',cdvn.sget(nc),'"');
  for i:= 1 to nr do begin
    write(f,'"',rdvn.sget(i),'", ');
    for j:= 1 to nc-1 do write(f,'"',vget(i,j),'",');
    writeln(f,'"',vget(i,nc),'"');
    end;
end;
{---------------------------------------------------------------------------}
procedure tmat.destroyconstituents;
begin try
  if (classname <> 'tmat') then
    dealloc;
  if rdvn = cdvn
    then begin
      freeandnil(rdvn);
      cdvn:= nil;
      end
    else begin
      freeandnil(rdvn);
      freeandnil(cdvn);
    end;
  if mdvn <> nil
    then freeandnil(mdvn);
  if rdsl = cdsl
    then begin
      freeandnil(rdsl);
      cdsl:= nil;
      end
    else begin
      freeandnil(rdsl);
      freeandnil(cdsl);
    end;
  if mdsl <> nil
    then freeandnil(mdsl);
  if comments <> nil
    then freeandnil(comments);
  except
  end;
end;
{---------------------------------------------------------------------------}
function tmat.symmetrize(method:symtype=sy_union; missings:integer=0): boolean;
//returns true if the matrix was symmetric to start with
//missings 1 uses non-mmissing value; missings 0 makes both missing
label cleanup;
var
  i,j: integer;
  xij,xji,x: double;
begin
  if nr <> nc then exit(false);
  result:= true;
  for i:= 2 to nr do
    for j:= 1 to i-1 do begin
      xij:= fget(i,j); xji:= fget(j,i);
      if not math.samevalue(xij,xji) then result:= false;
      if (xij >= na) or (xji >= na)
        then case missings of
          0: if xij < na
               then fput(j,i,xij)
               else fput(i,j,xji);
          1: begin
               fput(i,j,bna);
               fput(j,i,bna);
               end;
          end
        else case method of
          sy_union: if xij > xji then fput(j,i,xij) else fput(i,j,xji);
          sy_inter: if xij < xji then fput(j,i,xij) else fput(i,j,xji);
          sy_avg:   begin x:= favg(xij,xji); fput(i,j,x); fput(j,i,x); end;
          sy_sum:   begin x:= xij + xji; fput(i,j,x); fput(j,i,x); end;
          end;
      end;
  cleanup:
end;
{---------------------------------------------------------------------------}
destructor tmat.destroy;
begin
  destroyconstituents;
  inherited destroy;
end;
{---------------------------------------------------------------------------}
(*procedure tmat.free;
begin
  if self <> nil then begin
    free;
    self:= nil;
    end;
end; *)
{---------------------------------------------------------------------------}
procedure tmat.displayasmatrix(var f:text; w:integer=-1; d:integer=-1);
var
  sw: tstreamwriter;
  sr: tstreamreader;
  fn: string;
begin try
  fn:= temppath + 'displayasmatrix.txt'; 
  sw:= tstreamwriter.create(fn);
  display(sw,'',w,d);
  freeandnil(sw);
  sr:= tstreamreader.Create(fn);
  while not sr.EndOfStream do
    writeln(f,sr.ReadLine);
  freeandnil(sr);
  finally
    freeandnil(sw);
    freeandnil(sr);
    end;
end;
{---------------------------------------------------------------------------}
procedure tmat.displayasmatrixname(f:tstreamwriter; matname:string; w:integer=-1; d:integer=-1; nastr:string=' '; zerostr:string='0');
//deprecated. use display instead
var
  ml,i,j,k: integer;
  specialzero: boolean;

  procedure writecolumnheaders;
  var
    i,j: integer;
    list: tlist;
    dvn: tstrvec;

    procedure writelist(topleft:string='');
    var
      i,j,k: integer;
    begin
      topleft:= system.copy(topleft,1,ml);
      //k:= currentmat;
      for i:= 0 to list.Count-1 do begin
        {if mdvn.hasval
          then f.write(pad(' ',5) + ' ' + pad(mdvn.labelget(k,ml),ml) + ' ')
          else }
//        f.write(pad(' ',6) + ' ' + pad(' ',ml) + ' ');
        if i = list.Count - 1
          then f.write(pad(' ',6) + ' ' + pad(topleft,ml) + ' ')
          else f.write(pad(' ',6) + ' ' + pad(' ',ml) + ' ');
        for j:= 1 to nc do
          f.write(pad(tstrvec(list[i]).cell[j],w)+' ');
        f.WriteLine;
        end;
    end;

    procedure writedashes;
    var j: integer;
    begin
      f.write(pad(' ',6) + ' ' + pad(' ',ml) + ' ');
      for j:= 1 to nc do
        f.Write(pad(dup('-',w),w)+' ');
      f.WriteLine;
    end;

  begin
    list:= tlist.Create;
    if cdvn.hasval then begin
      dvn:= tstrvec.create;
      dvn.allocsize(nc);
      for j:= 1 to nc do
        dvn.sput(j,inttostr(j));
      dvn.binbywidth(list,w);
      if writecolnumbers
        then writelist('');
      for i:= 0 to list.Count-1 do
        tstrvec(list[i]).free;
      list.Clear;
      dvn.free;
      end;
    cdvn.binbywidth(list,w,nc);
    writelist(matname);
    for i:= 0 to list.Count-1 do
      tstrvec(list[i]).free;
    writedashes;
    list.Free;
  end;

  procedure getwd;
  begin
    if d < 0
      then if isintegervalued
        then d:= 0
        else d:= defaultd;
    if w < 0 then w:= defaultw;
    if w = 0 then w:= getminwidthfstr(d);
//    if w = 0 then w:= getminwidthfstr(d,nc);
  end;

begin
  if writetitle then begin
    f.writeline(title);
    f.writeline;
    end;
  specialzero:= (zerostr <> '0');
  if (length(zerostr) > 0) and (zerostr[1] = '@')
    then delete(zerostr,1,1);
  if rdvn.hasval
    then ml:= rdvn.getmaxlength
    else ml:= length(inttostr(nr));
  if ml = 0 then ml:= 1;
  getwd;
  writecolumnheaders;
  for i:= 1 to nr do begin
    if rdvn.hasval and writerownumbers
      then f.write(istr(i,6) + ' ' + pad(rdvn.getlabel(i,ml),ml) + ' ')
      else f.write(pad(' ',6) + ' ' + pad(rdvn.getlabel(i,ml),ml) + ' ');
    for j:= 1 to nc do
      if isna(i,j)
        then f.write(pad(nastr,w) + ' ')
        else if (not iszero(i,j)) or (not specialzero)
          then f.write(fstr(fget(i,j),w,d)+' ')
          else f.Write(pad(zerostr,w) + ' ');
    f.writeline;
    end;
  f.writeline;
  if writedimensions then
    f.WriteLine(inttostr(nr)+' rows, '+inttostr(nc)+' columns, '+inttostr(nm)+' levels.');
  f.WriteLine;
end;
{---------------------------------------------------------------------------}
procedure tmat.displayasmatrix(f:tstreamwriter; w:integer=-1; d:integer=-1; nastr:string=' '; zerostr:string='0');
var
  matname: string;
begin
  if (mdvn.hasval) and (mdvn.n = 1)
    then matname:= mdvn.sget(1)
    else matname:= '';
  display(f,matname,w,d,nastr,zerostr);
end;
{---------------------------------------------------------------------------}
procedure tmat.display(f:tstreamwriter; w:integer=-1; d:integer=-1; nastr:string=' '; zerostr:string='0');
var
  matname: string;
begin
  if (mdvn.hasval) and (mdvn.n = 1)
    then matname:= mdvn.sget(1)
    else matname:= '';
  display(f,matname,w,d,nastr,zerostr);
end;
{---------------------------------------------------------------------------}
procedure tmat.display(f:tstreamwriter; matname:string; w:integer=-1; d:integer=-1; nastr:string=' '; zerostr:string='0');
var
  ml,i,j,k: integer;
  specialzero: boolean;
  decimals, widths: tivec;

  procedure writecolumnheaders;
  var
    i,j: integer;
    list: tlist;
    dvn: tstrvec;

    procedure writelist(topleft:string='');
    var
      i,j,k: integer;
    begin
      topleft:= system.copy(topleft,1,ml);
      //k:= currentmat;
      for i:= 0 to list.Count-1 do begin
        {if mdvn.hasval
          then f.write(pad(' ',5) + ' ' + pad(mdvn.labelget(k,ml),ml) + ' ')
          else }
//        f.write(pad(' ',6) + ' ' + pad(' ',ml) + ' ');
        if i = list.Count - 1
          then f.write(pad(' ',6) + ' ' + pad(topleft,ml) + ' ')
          else f.write(pad(' ',6) + ' ' + pad(' ',ml) + ' ');
        for j:= 1 to nc do
          f.write(pad(tstrvec(list[i]).cell[j],widths[j])+' ');
        f.WriteLine;
        end;
    end;

    procedure writedashes;
    var j: integer;
    begin
      f.write(pad(' ',6) + ' ' + pad(' ',ml) + ' ');
      for j:= 1 to nc do
        f.Write(pad(dup('-',widths[j]),widths[j])+' ');
      f.WriteLine;
    end;

  begin
    list:= tlist.Create;
    if cdvn.hasval or true then begin  //testing
      dvn:= tstrvec.create;
      dvn.allocsize(nc);
      for j:= 1 to nc do
        dvn.sput(j,inttostr(j));
      dvn.binbywidth(list,widths);
      if writecolnumbers
        then writelist('');
      for i:= 0 to list.Count-1 do
        tstrvec(list[i]).free;
      list.Clear;
      dvn.free;
      end;
    cdvn.binbywidth(list,widths,nc);
    writelist(matname);
    for i:= 0 to list.Count-1 do
      tstrvec(list[i]).free;
    writedashes;
    list.Free;
  end;

  procedure getwd;
  var j:integer;
  begin
    if d < 0
      then if isintegervalued
        then d:= 0
        else d:= defaultd;
    if w < 0 then w:= defaultw;
    if w = 0 then w:= getminwidthfstr(d);
    for j:= 1 to nc do begin
      decimals.cell[j]:= d;
      widths.cell[j]:= w;
      end;
//    if w = 0 then w:= getminwidth(d,nc);
  end;

  procedure getwdbycol;
  var
    j: integer;
  begin
    for j:= 1 to nc do begin
      decimals[j]:= d;
      if decimals[j] < 0
        then if isintegervalued(j)
          then decimals[j]:= 0
          else decimals[j]:= defaultd;
      widths[j]:= w;
      if widths[j] < 0
        then widths[j]:= defaultw;
      if widths[j] = 0
        then widths[j]:= getminwidthfstr(decimals[j]);
      end;
  end;

begin
  decimals:= tivec.create;
  widths:= tivec.create;
  decimals.allocate(nc,true,false);
  widths.allocate(nc,true,false);
  if writetitle then begin
    f.writeline(title);
    f.writeline;
    end;
  specialzero:= (zerostr <> '0');
  if (length(zerostr) > 0) and (zerostr[1] = '@')
    then delete(zerostr,1,1);
  if rdvn.hasval
    then ml:= rdvn.getmaxlength
    else ml:= length(inttostr(nr));
  if ml = 0 then ml:= 1;
  if istable
    then getwdbycol
    else getwd;
  writecolumnheaders;
  for i:= 1 to nr do begin
    if rdvn.hasval and writerownumbers
      then f.write(istr(i,6) + ' ' + pad(rdvn.getlabel(i,ml),ml) + ' ')
      else f.write(pad(' ',6) + ' ' + pad(rdvn.getlabel(i,ml),ml) + ' ');
    for j:= 1 to nc do begin
      w:= widths.cell[j];
      d:= decimals.cell[j];
      if isna(i,j)
        then f.write(pad(nastr,w) + ' ')
        else if (not iszero(i,j)) or (not specialzero)
          then f.write(fstr(fget(i,j),w,d)+' ')
          else f.Write(pad(zerostr,w) + ' ');
      end;
    f.writeline;
    end;
  f.writeline;
  if writedimensions then
    f.WriteLine(inttostr(nr)+' rows, '+inttostr(nc)+' columns, '+inttostr(nm)+' levels.');
  f.WriteLine;
  decimals.free; widths.free;
end;
{---------------------------------------------------------------------------}
procedure tmat.displayasblockedmatrix(f:tstreamwriter; p:tivec; w:integer=-1; d:integer=-1; nastr:string=' '; zerostr:string='0');
var
  ml,i,j,k: integer;
  specialzero: boolean;

  procedure writecolumnheaders;
  var
    i,j: integer;
    list: tlist;
    dvn: tstrvec;

    procedure writelist;
    var i,j,k: integer;
    begin
      //k:= currentmat;
      for i:= 0 to list.Count-1 do begin
        {if mdvn.hasval
          then f.write(pad(' ',5) + ' ' + pad(mdvn.labelget(k,ml),ml) + ' ')
          else }f.write(pad(' ',5) + ' ' + pad(' ',ml) + ' ');
        for j:= 1 to nc do
          f.write(pad(tstrvec(list[i]).cell[j],w)+' ');
        f.WriteLine;
        end;
    end;

    procedure writedashes;
    var j: integer;
    begin
      f.write(pad(' ',5) + ' ' + pad(' ',ml) + ' ');
      for j:= 1 to nc do
        f.Write(pad(dup('-',w),w)+' ');
      f.WriteLine;
    end;

  begin
    list:= tlist.Create;
    if cdvn.hasval then begin
      dvn:= tstrvec.create;
      dvn.allocsize(nc);
      for j:= 1 to nc do
        dvn.sput(j,inttostr(j));
      dvn.binbywidth(list,w);
      if writecolnumbers then writelist;
      for i:= 0 to list.Count-1 do
        tstrvec(list[i]).free;
      list.Clear;
      dvn.free;
      end;
    cdvn.binbywidth(list,w,nc);
    writelist;
    for i:= 0 to list.Count-1 do
      tstrvec(list[i]).free;
    writedashes;
    list.Free;
  end;

  procedure getwd;
  begin
    if d < 0
      then if isintegervalued
        then d:= 0
        else d:= defaultd;
    if w < 0 then w:= defaultw;
    if w = 0 then w:= getminwidth(d,nc);
  end;

begin
  f.writeline(title);
  f.writeline;
  specialzero:= (zerostr <> '0');
  if (length(zerostr) > 0) and (zerostr[1] = '@')
    then delete(zerostr,1,1);
  if rdvn.hasval
    then ml:= rdvn.getmaxlength
    else ml:= length(inttostr(nr));
  if ml = 0 then ml:= 1;
    getwd;
    writecolumnheaders;
      for i:= 1 to nr do begin
        if rdvn.hasval and writerownumbers
          then f.write(istr(i,6) + ' ' + pad(rdvn.getlabel(i,ml),ml) + ' ')
          else f.write(pad(' ',6) + ' ' + pad(rdvn.getlabel(i,ml),ml) + ' ');
        for j:= 1 to nc do
          if isna(i,j)
            then f.write(pad(nastr,w) + ' ')
            else if (not iszero(i,j)) or (not specialzero)
              then f.write(fstr(fget(i,j),w,d)+' ')
              else f.Write(pad(zerostr,w) + ' ');
        f.writeline;
        end;
      f.writeline;
  if writedimensions then
    f.WriteLine(inttostr(nr)+' rows, '+inttostr(nc)+' columns, '+inttostr(nm)+' levels.');
  f.WriteLine;
end;
{---------------------------------------------------------------------------}
procedure tmat.displayasmatrix(fn:string; w:integer=-1; d:integer=-1);
var
  sw: tstreamwriter;
begin
  sw:= tstreamwriter.Create(fn);
  displayasmatrix(sw,w,d);
  sw.Free;
end;
{---------------------------------------------------------------------------}
function tmat.getminmax(var mi,ma:extended; lowerhalfonly:boolean=false; diagok:boolean=true): pairofextended;
var
  i,j,a,d: integer;
  x: extended;
begin
  if not issquare then begin diagok:= true;
  lowerhalfonly:= false; end;
  mi:= 1E36; ma:= -1E36;
  a:= 1; d:= nc;
  if lowerhalfonly then a:= 2;
  for i:= a to nr do begin
    if lowerhalfonly then d:= i-1;
    for j:= 1 to d do if ((i<>j) or diagok) and (not isna(i,j)) then begin
      x:= fget(i,j);
      if x > ma then ma:= x;
      if x < mi then mi:= x;
      end;
    end;
  result.x:= mi;
  result.y:= ma;
end;
{---------------------------------------------------------------------------}
function tmat.nonzero(i,j:integer): boolean;
begin
//  result:= fneq(vget(i,j),0);
  result:= not math.iszero(fget(i,j),singleprecision);
end;
{---------------------------------------------------------------------------}
function tmat.isneighbor(i,j:integer; meth:tegometh): boolean;
begin
  if isna(i,j) then exit(false);
  case meth of
    em_out: result:= istie(i,j);
    em_in: result:= istie(j,i);
    em_union: result:= istie(i,j) or istie(j,i);
    em_intersect: result:= istie(i,j) and istie(j,i);
    end;
end;
{---------------------------------------------------------------------------}
function tmat.istie(i,j:integer; op:tdichop=opgt; cut:double=0.0): boolean;
begin
  if isna(i,j)
    then result:= false
    else case op of
      opgt: result:= fget(i,j) > cut;
      opge: result:= fget(i,j) >= cut;
      opeq: result:= samevalue(fget(i,j),cut);
      ople: result:= fget(i,j) <= cut;
      oplt: result:= fget(i,j) < cut;
      opne: result:= fneq(fget(i,j),cut);
      else result:= false;
      end;
end;
{---------------------------------------------------------------------------}
function tmat.countties(op:tdichop=opgt; cut:double=0.0): int64;
//assumes 1-mode matrix
var
  i,j,first,last: integer;
  sym: boolean;
begin
  sym:= issymmetric;
  if sym then first:= 2 else first:= 1;
  result:= 0;
  for i:= first to n do begin
    if sym then last:= i-1 else last:= n;
    for j:= 1 to last do if (i<>j)
      then if istie(i,j,op,cut)
        then inc(result);
    end;
end;
{---------------------------------------------------------------------------}
function tmat.ncells: int64;
begin
  result:= nr*nc*nm;
end;
{---------------------------------------------------------------------------}
procedure tmat.dichotomize(op:tdichop; cutoff:double; diags:integer=0; thenval:double=1.0; elseval:double=0.0);
var
  i,j: integer;
  x: double;
  square: boolean;
begin
  case diags of
    0: x:= 0;
    1: x:= bna;
    2: x:= thenval;
    3: x:= elseval;
    end;
  square:= issquare;
  for i:= 1 to nr do
    for j:= 1 to nc do if not isna(i,j) then begin
      if square and (i=j)
        then if diags = 4
          then if istie(i,j,op,cutoff)
            then fput(i,j,thenval)
            else fput(i,j,elseval)
          else fput(i,j,x)
        else if istie(i,j,op,cutoff)
          then fput(i,j,thenval)
          else fput(i,j,elseval);
      end;
  end;
{---------------------------------------------------------------------------}
procedure tmat.combinecols(dsl:tdsl; method:integer=0; diagok:boolean=true);
var
  i,j,jj,h: integer;
  u: tunivariate;
begin try
  u:= tunivariate.create;
  if not issquare then diagok:= false; //try not to override caller
  for i:= 1 to nr do begin
    u.clear;
    h:= dsl.cell[1];
    for j:= 1 to dsl.n do begin
      jj:= dsl.cell[j];
      if (i<>jj) or diagok then
        u.addcase(fget(i,jj));
      end;
    case method of
      0: fput(i,h,u.min);
      1: fput(i,h,u.max);
      2: fput(i,h,u.mean);
      3: fput(i,h,u.tot);
      end;   
    end;
  for j:= dsl.n downto 2 do 
    deletecol(j);
  finally
    u.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure tmat.combinerows(dsl:tdsl; method:integer=0; diagok:boolean=true);
var
  i,j,ii,h: integer;
  u: tunivariate;
begin try
  u:= tunivariate.create;
  if not issquare then diagok:= false; //try not to override caller
  for j:= 1 to nc do begin
    u.clear;
    h:= dsl.cell[1];
    for i:= 1 to dsl.n do begin
      ii:= dsl.cell[i];
      if (j<>ii) or diagok then
        u.addcase(fget(ii,j));
      end;
    case method of
      0: fput(h,j,u.min);
      1: fput(h,j,u.max);
      2: fput(h,j,u.mean);
      3: fput(h,j,u.tot);
      end;   
    end;
  for i:= dsl.n downto 2 do 
    deleterow(i);
  finally
    u.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure tmat.combinenodes(dsl:tdsl; method:integer=0; diagok:boolean=true);
begin
  combinecols(dsl,method,diagok);
  combinerows(dsl,method,diagok);
end;
{---------------------------------------------------------------------------}
procedure tmat.meancenter(diagok:boolean);
var
  i,j: integer;
  u: tsimpleuni;
begin
  u:= tsimpleuni.create;
  for i:= 1 to nr do
    for j:= 1 to nc do if (i<>j) or diagok then
      u.addcase(fget(i,j));
  for i:= 1 to nr do
    for j:= 1 to nc do if (i<>j) or diagok then
      if not isna(i,j) then
        fput(i,j,fget(i,j)-u.mean);
  u.free;
  end;
{---------------------------------------------------------------------------}
procedure tmat.standardize(diagok:boolean);
var
  i,j: integer;
  u: tunivariate;
begin
  u:= tunivariate.create;
  for i:= 1 to nr do
    for j:= 1 to nc do if (i<>j) or diagok then
      u.addcase(fget(i,j));
  u.calc;
  if u.stddev > 0 then
  for i:= 1 to nr do
    for j:= 1 to nc do if (i<>j) or diagok then
      if not isna(i,j) then
        fput(i,j,(fget(i,j)-u.mean)/u.stddev);
  u.free;
  end;
{---------------------------------------------------------------------------}
function tmat.product(a,b:tmat; diagok:boolean=true): boolean;
var
  i,k,j,nk, nmiss: integer;
  s: extended;
begin
  result:= a.nc = b.nr;
  assert(result,'Matrices not conformable');
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

procedure tmat.eMult(a,b:tmat);
var
  i,j: integer;
begin
  if (a.nc <> b.nc) or (a.nr <> b.nr)
    then raise exception.Create('Matrices must same size for elementwise multiplication');
  allocate(a.nr,a.nc,nm,true,true);
  for i:= 1 to nr do
    for j:= 1 to nc do if a.isna(i,j) or b.isna(i,j)
      then fput(i,j,bna)
      else fput(i,j,a.fget(i,j)*b.fget(i,j));
end;
{---------------------------------------------------------------------------}
procedure tmat.setdim(xnr,xnc,xnm:integer; labelstoo:boolean);
begin
  if xnr > -1 then begin
    nr:= xnr;
    if labelstoo then if rdvn.hasval then rdvn.n:= nr;
    end;
  if xnc > -1 then begin
    nc:= xnc;
    if labelstoo then if cdvn.hasval then cdvn.n:= nc;
    end;
  if xnm > -1 then begin
    nm:= xnm;
    if labelstoo then if mdvn.hasval then mdvn.n:= nm;
    end;
End;
{---------------------------------------------------------------------------}
function tmat.rowsum(i:integer; diagok:boolean=false): double;
var j: integer;
begin
  if nr <> nc then diagok:= true;
  result:= 0;
  for j:= 1 to nc do if (i<>j) or diagok
    then if isvalid(i,j)
      then result:= result + fget(i,j);
end;
{---------------------------------------------------------------------------}
function tmat.getcolsum(j:integer; diagok:boolean=false): double;
var i: integer;
begin
  if nr <> nc then diagok:= true;
  result:= 0;
  for i:= 1 to nr do if (i <> j) or diagok then
    if isvalid(i,j)
      then result:= result + fget(i,j);
end;
{---------------------------------------------------------------------------}
function tmat.getaverage(diagok:boolean): double;
var
  i,j: integer;
  den: int64;
begin
  if nr <> nc then diagok:= true;
  result:= 0; den:= 0;
  for i:= 1 to nr do if (i <> j) or diagok then
    if isvalid(i,j) then begin
      inc(den);
      result:= result + fget(i,j);
      end;
  if math.iszero(den)
    then result:= bna
    else result:= result/den;
end;
{---------------------------------------------------------------------------}
procedure tmat.subgraph(src:tmat; vec:tsvec; op:tdichop=opgt; cut:single=0.0);
// frees src rdsl and cdsl
var 
  i: integer;
begin
  if not src.IsSquare then
    raise exception.create('Subgraph procedure requires matrix to be square.');
  if src.n <> vec.n then
    raise exception.create('Subgraph procedure requires vector and matrix to be same size.');
  src.rdsl.n:= 0;
  for i:= 1 to src.n do 
    if comparevals(vec.cell[i],op,cut) 
      then src.rdsl.iappend(i);
  src.cdsl.copy(src.rdsl);
  allocate(rdsl.n,cdsl.n,-1,true,false);
  copydsl(src);
end;

End.
