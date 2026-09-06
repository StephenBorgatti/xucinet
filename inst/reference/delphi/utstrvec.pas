unit utstrvec;
interface
uses
  sysutils, classes, math, types, generics.collections,
  ucommon, ustring, utvec, ukey;
type
  tarrayofstring = array of string;
  tstrvec = class(tvec)
    delims: string;
    compareasnumbers,casesensitive: boolean;
    cell: tarrayofstring;
    dict: tdictionary<string,integer>;
    constructor create; override;
    destructor destroy; override;
    function add(x:variant): integer; override;
    function addstr(x:string): integer;
    function addtostrings(s:tstrings): integer;
    function allocate(num:integer; zero:boolean): boolean; override;
    function allnumeric: boolean;
    function append(x:variant): integer; virtual;
    function appendifnew(x:variant): integer; virtual;
    function appendstr(x:string): integer;
    function appendifnewstr(x:string): integer;
    function copy(x:tvec): boolean; override;
    function copydsl(x:tvec; dsl:tvec): integer; override;
    function copyfromstrings(list:tstrings): boolean;
    function copystringlist(list:tstringlist): boolean;
    procedure copytostrings(list:tstrings; fakeit:boolean; num:integer);
    function copytstrvec(x:tstrvec): boolean;
    function count(x:variant): integer;
    function equal(i,j:integer): boolean; override;
    function equalsv(i:integer; x:variant): boolean; override;
    function fget(j:integer): extended; override;
    function fillrange(items:array of string): integer;
    function fillwith(s:string; delim:char='|'): integer;
    function formatted(j:integer): string; override;
    function getallocn: integer; override;
    function getdelimitedtext: string;
    function getlabel(j:integer; len:integer=0): string;
    function getmaxlength(num:integer=0): integer;
    function getvalue(i:integer): string;
    function hashlookup(s:string): integer;
    function hasval(num:integer=0): boolean; override;
    function iget(j:integer): integer; override;
    function insertbefore(k:integer; x:variant): integer; override;
    function insertbeforestr(k:integer; x:string): integer;
    function labelget(j:integer; len:integer=0): string;
    function lessthan(i,j:integer): boolean; override;
    function lget(j:integer): string;
    function lookup(x:variant): integer; override;
    function lookupkeystr(x:string): integer;
    function lookupstr(x:string; casesensitive:boolean=true): integer;
    function morethan(i,j:integer): boolean; override;
    function ordinal: boolean;
    function reallocate(num:integer; zero:boolean): boolean; override;
    function sget(j:integer): string; override;
    function sortedappend(x:variant): integer; override;
    function sortedappendifnew(x:variant): integer; override;
    function sortedappendstr(x:string): integer;
    function sortedappendifnewstr(x:string): integer;
    function sortedlookup(x:variant): integer; override;
    function sortedlookupstr(x:string): integer;
    function vget(j:integer): variant; override;
    function vptr: pointer; override;
    procedure Assign(ListA:tstrvec; AOperator:TListAssignOp; ListB:tstrvec=nil);
    procedure binbywidth(list:tlist; w:integer; num:integer=0); overload;
    procedure binbywidth(list:tlist; widths:tvec; num:integer=0); overload;
    procedure dealloc; override;
    procedure deletejth(j: Integer); override;
    procedure fput(j:integer; x:extended); override;
    procedure hashclear;
    procedure hashset(clear:boolean=true);
    procedure iput(j:integer; x:integer; e:integer=0); override;
    procedure put(j:integer; var x); override;
    procedure safesetvalue(j:integer; s:string);
    procedure setallocn(x:integer); override;
    procedure setdelimitedtext(s:string);
    procedure setvalue(i:integer; x:string);
    procedure sput(j:integer; s:string; e:string='0'); override;
    procedure swap(i,j:integer); override;
    procedure vput(j:integer; x:variant); override;
    procedure zerofill(num:integer=-1); override;
    property delimitedtext:string read getdelimitedtext write setdelimitedtext;
    property value[i:integer]:string read getvalue write SetValue; default;
    end;
  tsortedstrvec = class(tstrvec)
    function lookup(x:variant): integer; override;
    function appendifnew(x:variant): integer; override;
    function append(x:variant): integer; override;
    end;
  procedure swapstrvecs(x,y:tstrvec);

{---------------------------------------------------------------------------}
implementation
{---------------------------------------------------------------------------}
procedure swapstrvecs(x,y:tstrvec);
var z: tstrvec;
begin
  z:= tstrvec.create;
  z.copy(x);
  x.copy(y);
  y.copy(z);
  z.free;
end;
{---------------------------------------------------------------------------}
constructor tstrvec.create;
begin
  inherited create;
  dict:= tdictionary<string,integer>.create;
  compareasnumbers:= false;
  dt:= stringdt;
  cell:= nil;
  prefix:= '';
  returnblank:= false;
  delims:= #9 + #10 + #13 + ' ' + ',' + '|';
  casesensitive:= true;
end;
{---------------------------------------------------------------------------}
destructor tstrvec.destroy;
begin
  dict.free;
  inherited destroy;
end;
{---------------------------------------------------------------------------}
function tstrvec.allocate(num:integer; zero:boolean): boolean;
var
  i: integer;
begin
  result:= true;
  if num < 1
    then cell:= nil
    else try
      setlength(cell,num+1);
      if zero then zerofill(num);
    except
      raise exception.create('Unable to allocate memory.');
      result:= false;
    end;
end;
{---------------------------------------------------------------------------}
function tstrvec.reallocate(num:integer; zero:boolean): boolean;
var
  oldallocn,i: integer;
begin
  oldallocn:= allocn;
  result:= allocate(num,false);
  if zero and (num > oldallocn) then
    for i:= oldallocn+1 to num do
      cell[i]:= '';
end;
{---------------------------------------------------------------------------}
function tstrvec.getallocn: integer;
begin
  if assigned(cell)
    then result:= length(cell) - 1
    else result:= -1;
end;
{---------------------------------------------------------------------------}
procedure tstrvec.setallocn(x:integer);
begin
  if x > 0
    then setlength(cell,x+1)
    else cell:= nil;
  if n > x then n:= x;
end;
{---------------------------------------------------------------------------}
procedure tstrvec.dealloc;
begin
  cell:= nil;
  n:= 0;
  inherited;
end;
{---------------------------------------------------------------------------}
function tstrvec.vptr: pointer;
begin
  result:= @cell[1];
end;
{---------------------------------------------------------------------------}
procedure tstrvec.deletejth(j: Integer);
var k: integer;
begin
  Dec(n);
  if j <= n then
    for k:= j to n do
      cell[k]:= cell[k+1];
end;
{---------------------------------------------------------------------------}
procedure tstrvec.Assign(ListA:tstrvec; AOperator:TListAssignOp; ListB:tstrvec=nil);
var
  I: Integer;
  LTemp, LSource: tstrvec;
begin
  // ListB given?
  if ListB <> nil then
  begin
    LSource := ListB;
    copy(ListA);
  end
  else
    LSource := ListA;

  // on with the show
  case AOperator of
    // 12345, 346 = 346 : only those in the new list
    laCopy: begin
      allocn:= lsource.allocn;
      clear;
      for i:= 1 to lsource.n do
        cell[i]:= lsource.cell[i];
      end;
    // 12345, 346 = 34 : intersection of the two lists
    laAnd:
      for I := n downto 1 do
        if LSource.lookupstr(cell[I]) = 0 then
          Deletejth(I);
    // 12345, 346 = 123456 : union of the two lists
    laOr:
      for I := 1 to LSource.n do
        if lookupstr(LSource[I]) = 0 then
          Add(LSource[I]);
//    laAdd:
 //     for I := 1 to LSource.n do
 //       Add(LSource[I]);

    // 12345, 346 = 1256 : only those not in both lists
    laXor:
      begin
        LTemp := Tstrvec.Create; // Temp holder
        try
          LTemp.allocn := LSource.allocn;
          for I := 1 to LSource.n do
            if lookupstr(LSource[I]) = 0 then
              LTemp.Add(LSource[I]);
          for I := n downto 1 do
            if LSource.lookupstr(cell[I]) <> 0 then
              Deletejth(I);
          I := n + LTemp.n;
          if allocn < I then
            allocn := I;
          for I := 1 to LTemp.n do
            Add(LTemp[I]);
        finally
          LTemp.free;
        end;
      end;

    // 12345, 346 = 125 : only those unique to source
    laSrcUnique:
      for I := n downto 1 do
        if LSource.lookupstr(cell[I]) <> 0 then
          Deletejth(I);

    // 12345, 346 = 6 : only those unique to dest
    laDestUnique:
      begin
        LTemp := Tstrvec.Create;
        try
          LTemp.allocn := LSource.allocn;
          for I := LSource.n downto 1 do
            if lookupstr(LSource[I]) = 0 then
              LTemp.Add(LSource[I]);
          copy(LTemp);
        finally
          LTemp.free;
        end;
      end;
  end;
end;
{---------------------------------------------------------------------------}
function tstrvec.hasval(num:integer=0): boolean;
begin result:= assigned(cell) and (length(cell) > num); end;
{---------------------------------------------------------------------------}
function tstrvec.allnumeric: boolean;
var
  i: integer;
  x: double;
begin
  if hasval
    then result:= false
    else begin result:= true; exit; end;
  for i:= 1 to n do
    if not trystrtofloat(cell[i],x) then begin result:= false; exit; end;
  result:= true;
end;
{---------------------------------------------------------------------------}
function tstrvec.ordinal: boolean;
var
  i: integer;
  x: integer;
begin
  if not hasval then begin result:= true; exit; end;
  for i:= 1 to n do begin
    result:= false;
    if trystrtoint(cell[i],x)
      then if x = i then continue else exit
      else exit;
    end;
  result:= true;
end;
{---------------------------------------------------------------------------}
function tstrvec.lessthan(i,j:integer): boolean;
var x,y: double;
begin
  if compareasnumbers and trystrtofloat(cell[i],x) and trystrtofloat(cell[j],y)
    then result:= x < y
    else result:= cell[i] < cell[j];
end;
{---------------------------------------------------------------------------}
function tstrvec.morethan(i,j:integer): boolean;
var x,y: double;
begin
  if compareasnumbers and trystrtofloat(cell[i],x) and trystrtofloat(cell[j],y)
    then result:= x > y
    else result:= cell[i] > cell[j];
end;
{---------------------------------------------------------------------------}
function tstrvec.equal(i,j:integer): boolean;
begin result:= cell[i] = cell[j]; end;
{---------------------------------------------------------------------------}
function tstrvec.equalsv(i:integer; x:variant): boolean;
begin result:= cell[i] = x; end;
{---------------------------------------------------------------------------}
function tstrvec.vget(j:integer): variant;
begin result:= cell[j]; end;
{---------------------------------------------------------------------------}
function tstrvec.fget(j:integer): extended;
begin fget:= strtofloatdef(cell[j],bna); end;
{---------------------------------------------------------------------------}
procedure tstrvec.fput(j:integer; x:extended);
begin
  cell[j]:= floattostr(x);
end;
{---------------------------------------------------------------------------}
function tstrvec.getvalue(i:integer): string;
begin result:= cell[i]; end;
{---------------------------------------------------------------------------}
procedure tstrvec.setvalue(i:integer; x:string);
begin cell[i]:= x; end;
{---------------------------------------------------------------------------}
procedure tstrvec.put(j:integer; var x);
begin cell[j]:= string(x); end;
{---------------------------------------------------------------------------}
procedure tstrvec.vput(j:integer; x:variant);
begin cell[j]:= x; end;
{---------------------------------------------------------------------------}
function tstrvec.iget(j:integer): integer;
begin iget:= strtoint(cell[j]); end;
{---------------------------------------------------------------------------}
procedure tstrvec.iput(j:integer; x:integer; e:integer=0);
begin
try
  cell[j]:= inttostr(x);
except
  on EInvalidOp do cell[j]:= inttostr(e);
end;
end;
{---------------------------------------------------------------------------}
function tstrvec.sget(j:integer): string;
begin result:= cell[j];end;
{---------------------------------------------------------------------------}
function tstrvec.getdelimitedtext: string;
var
  j: integer;
begin
  if n = 0
    then begin result:= ''; exit; end
    else result:= cell[1];
  for j:= 2 to n do
    result:= result + delims + cell[j];
end;
{---------------------------------------------------------------------------}
procedure tstrvec.setdelimitedtext(s:string);
var
  i,nd: integer;
begin
  clear;
  if length(s) = 0 then exit;
  if delims = '' then begin
    appendstr(s); exit;
    end;
  for i:= 2 to length(delims) do
    stringreplace(s,delims[i],delims[1],[rfReplaceAll]);
  if s[length(s)] <> delims[1]
    then s:= s + delims[1];
  nd:= 0;
  for i:= 1 to length(s) do
    if s[i] = delims[1] then inc(nd);
  if nd > allocn then allocn:= nd;
  while length(s) > 0 do begin
    nd:= pos(delims[1],s);
    appendstr(system.copy(s,0,nd-1));
    s:= system.copy(s,nd+1,length(s));
  end;
end;
{---------------------------------------------------------------------------}
function tstrvec.fillwith(s:string; delim:char='|'): integer;
var
  dels: string;
begin
  dels:= delims;
  delims:= '|';
  setdelimitedtext(s);
  delims:= dels;
  result:= n;
end;
{---------------------------------------------------------------------------}
function tstrvec.fillrange(items: array of string): integer;
var
  item: string;
  i: integer;
begin
  allocate(length(items),true,false);
  for i:= low(items) to high(items) do 
    cell[i+1]:= items[i];
  result:= n;
end;
{---------------------------------------------------------------------------}
function tstrvec.formatted(j:integer): string;
var
  ix: integer;
  sx: single;
begin
  if str2num(cell[j],ix) = 0
    then result:= format('%7d',[ix])
    else if str2num(cell[j],sx) = 0
      then result:= format('%10.3f',[sx])
      else result:= cell[j];
end;
{---------------------------------------------------------------------------}
procedure tstrvec.binbywidth(list:tlist; w:integer; num:integer=0);
var
  ml,nl,i,j,b: integer;
  s: string;
begin
  if n > 0 then num:= n;
  ml:= getmaxlength(num);
  nl:= ml div w;
  if ml mod w > 0 then inc(nl);
  for i:= 0 to nl-1 do begin
    list.add(tstrvec.create);
    tstrvec(list[i]).allocsize(num);
    end;
  for j:= 1 to num do begin
    s:= getlabel(j);
    b:= 1;
    for i:= 0 to nl - 1 do begin
      tstrvec(list[i])[j]:= system.copy(s,b,w);
      inc(b,w);
      end;
    end;
end;
{---------------------------------------------------------------------------}
procedure tstrvec.binbywidth(list:tlist; widths:tvec; num:integer=0);
var
  ml,nl,i,j,b: integer;
  s: string;

  function getnumlines: integer;
  var
    j, len,numlines,w: integer;
  begin
    result:= 0;
    for j:= 1 to n do begin
      len:= length(getlabel(j));
      w:= widths.iget(j);
      if w > 0 then begin
        numlines:= len div w;
        if len mod w > 0 then inc(numlines);
      end
      else numlines:= 1;
      if numlines > result
        then result:= numlines;
      end;
  end;

begin
  if n > 0 then num:= n;
  nl:= getnumlines;
  for i:= 0 to nl-1 do begin
    list.add(tstrvec.create);
    tstrvec(list[i]).allocsize(num);
    end;
  for j:= 1 to num do begin
    s:= getlabel(j);
    b:= 1;
    for i:= 0 to nl - 1 do begin
      tstrvec(list[i])[j]:= system.copy(s,b,widths.iget(j));
      inc(b,widths.iget(j));
      end;
    end;
end;
{---------------------------------------------------------------------------}
function tstrvec.getmaxlength(num:integer=0): integer;
var
  i,len: integer;
begin
  if num = 0 then num:= n;
  result:= 0;
  for i:= 1 to num do begin
    len:= length(getlabel(i));
    if len > result
      then result:= len;
    end;
end;
{---------------------------------------------------------------------------}
function tstrvec.getlabel(j:integer; len:integer=0): string;
begin
  if hasval and (j > 0) and (j <= n)
    then result:= cell[j]
    else if returnblank
      then result:= ''
      else result:= prefix + inttostr(j);
  if len > 0 then
    if length(result) > len
      then result:= system.copy(result,1,len)
      else result:= pad(result,len);
  result:= trim(result);
end;
{---------------------------------------------------------------------------}
//for backward compatibility
function tstrvec.labelget(j:integer; len:integer=0): string;
begin result:= getlabel(j,len); end;
{---------------------------------------------------------------------------}
function tstrvec.lget(j:integer): string;
begin
  result:= getlabel(j);
end;
{---------------------------------------------------------------------------}
procedure tstrvec.sput(j:integer; s:string; e:string='0');
begin
  if allocn < j then
    allocate(max(j,n),false);
  cell[j]:= s;
  if j > n then n:= j;
end;
{---------------------------------------------------------------------------}
procedure tstrvec.safesetvalue(j:integer; s:string);
begin
  if allocn < j
    then allocn:= j;
  cell[j]:= s;
  if j > n then n:= j;
end;
{---------------------------------------------------------------------------}
function tstrvec.insertbefore(k:integer; x:variant): integer;
var i: integer;
begin
  k:= abs(k);
  if (n >= allocn)
    then allocn:= appendconstant + n;
  for i:= n downto k do
    cell[i+1]:= cell[i];
  cell[k]:= x;
  inc(n);
  result:= k;
end;
{---------------------------------------------------------------------------}
function tstrvec.sortedappend(x:variant): integer;
begin
  result:= insertbefore(abs(sortedlookup(x)),x);
end;
{---------------------------------------------------------------------------}
function tstrvec.sortedappendifnew(x:variant): integer;
begin
  result:= sortedlookup(x);
  if result < 0
    then result:= insertbefore(result,x);
end;
{---------------------------------------------------------------------------}
function tstrvec.sortedlookup(x:variant): integer;
var i: integer;
begin
  for i:= 1 to n do
    if cell[i] >= string(x) then begin
      if cell[i] > string(x) then result:= -i else result:= i;
      exit;
      end;
  result:= -(n+1);
end;
{---------------------------------------------------------------------------}
function tstrvec.sortedlookupstr(x:string): integer;
var i: integer;
begin
  for i:= 1 to n do
    if cell[i] >= x then begin
      if cell[i] > x then result:= -i else result:= i;
      exit;
      end;
  result:= -(n+1);
end;
{---------------------------------------------------------------------------}
function tstrvec.lookup(x:variant): integer;
var i: integer;
begin
  if n > 0 then
    for i:= 1 to n do if samestring(cell[i],string(x),casesensitive) then begin
      result:= i; exit; end;
  result:= 0;
end;
{---------------------------------------------------------------------------}
function tstrvec.count(x:variant): integer;
var
  i: integer;
begin
  result:= 0;
  if n > 0 then
    for i:= 1 to n do if cell[i] = string(x)
      then inc(result);
end;
{---------------------------------------------------------------------------}
procedure tstrvec.swap(i,j:integer);
var t: string;
begin
  t:= cell[i];
  cell[i]:= cell[j];
  cell[j]:= t;
end;
{---------------------------------------------------------------------------}
function tstrvec.copy(x:tvec): boolean;
var i: integer;
begin
  if x.hasval
    then begin
      result:= allocsize(x.n);
      if not result then exit;
      for i:= 1 to n do cell[i]:= x.labelget(i);
      end
    else result:= false;
end;
{---------------------------------------------------------------------------}
function tstrvec.copydsl(x:tvec; dsl:tvec): integer;
var
  i: integer;
begin
  if x.hasval
    then if allocsize(dsl.n,false)
      then begin
        for i:= 1 to n do sput(i,x.sget(dsl.iget(i)));
        result:= dsl.n;
        end
      else result:= -1
    else result:= 0;
end;
{---------------------------------------------------------------------------}
function tstrvec.copystringlist(list:tstringlist): boolean;
var s: string;
begin
  clear;
  for s in list do
    add(s);
  result:= true;
end;
{---------------------------------------------------------------------------}
function tstrvec.copyfromstrings(list:tstrings): boolean;
var s: string;
begin
  clear;
  for s in list do
    add(s);
  result:= true;
end;
{---------------------------------------------------------------------------}
procedure tstrvec.copytostrings(list:tstrings; fakeit:boolean; num:integer);
var i: integer;
begin
  list.clear;
  if hasval
    then for i:= 1 to n do
      list.Add(cell[i])
    else if fakeit then for i:= 1 to num do
      list.Add(labelget(i));
end;
{---------------------------------------------------------------------------}
function tstrvec.copytstrvec(x:tstrvec): boolean;
var i: integer;
begin
  if x.hasval
    then begin
      result:= allocsize(x.allocn);
      if not result then exit;
      for i:= 1 to n do cell[i]:= x.cell[i];
      end
    else result:= false;
end;
{---------------------------------------------------------------------------}
procedure tstrvec.zerofill(num:integer=-1);
var i: integer;
begin
  if num = -1 then
    if n = 0 then num:= allocn else num:= n;
  for i:= 1 to num do cell[i]:= '';
end;
{---------------------------------------------------------------------------}
function tstrvec.lookupstr(x:string; casesensitive:boolean=true): integer;
var
  i: integer;
begin
  result:= 0;
  if not hasval then exit;
  if casesensitive
    then begin
      if n > 0 then for i:= 1 to n do if cell[i] = x
        then exit(i);
      end
    else begin
      if n > 0 then
        for i:= 1 to n do if samestring(cell[i],x,casesensitive)
          then exit(i);
      end;
end;
{---------------------------------------------------------------------------}
function tstrvec.lookupkeystr(x:string): integer;
var i: integer;
begin
  if n > 0 then for i:= 1 to n do if iskey(cell[i],x,true) then begin
    result:= i; exit; end;
  result:= 0;
end;
{---------------------------------------------------------------------------}
function tstrvec.addtostrings(s:tstrings): integer;
var i: integer;
begin
  for i:= 1 to n do
    s.add(getlabel(i));
  result:= s.count;
end;
{---------------------------------------------------------------------------}
function tstrvec.add(x:variant): integer;
begin
  result:= appendstr(string(x));
end;
{---------------------------------------------------------------------------}
function tstrvec.addstr(x:string): integer;
begin
  result:= appendstr(x);
end;
{---------------------------------------------------------------------------}
function tstrvec.appendstr(x:string): integer;
begin
  inc(n);
  if n > allocn
    then allocn:= n;
  cell[n]:= x;
  result:= n;
end;
{---------------------------------------------------------------------------}
function tstrvec.appendifnewstr(x:string): integer;
begin
  result:= lookupstr(x);
  if (result = 0) and (x <> '')
    then result:= appendstr(x);
end;
{---------------------------------------------------------------------------}
function tstrvec.append(x:variant): integer;
begin
  result:= appendstr(x);
end;
{---------------------------------------------------------------------------}
function tstrvec.appendifnew(x:variant): integer;
begin
  result:= appendifnewstr(x);
end;
{---------------------------------------------------------------------------}
function tstrvec.insertbeforestr(k:integer; x:string): integer;
var
  i: integer;
begin
  result:= 0;
  if (n >= allocn)
    then if not realloc(appendconstant+n) then exit;
  for i:= n downto abs(k) do cell[i+1]:= cell[i];
  cell[abs(k)]:= x;
  inc(n);
  result:= k;
end;
{---------------------------------------------------------------------------}
function tstrvec.sortedappendstr(x:string): integer;
begin
  result:= insertbeforestr(abs(sortedlookupstr(x)),x);
end;
{---------------------------------------------------------------------------}
function tstrvec.sortedappendifnewstr(x:string): integer;
begin
  result:= sortedlookupstr(x);
  if result < 0
    then result:= insertbeforestr(abs(result),x);
end;
{---------------------------------------------------------------------------}
procedure tstrvec.hashset(clear:boolean=true);
var i: integer;
begin
  if clear then dict.clear;
  for i:= 1 to n do
    if not dict.ContainsKey(cell[i])
      then dict.Add(cell[i],i);
end;
{---------------------------------------------------------------------------}
procedure tstrvec.hashclear;
begin
  dict.clear;
end;
{---------------------------------------------------------------------------}
function tstrvec.hashlookup(s:string): integer;
begin
  if not dict.TryGetValue(s,result)
    then result:= 0;
end;
{---------------------------------------------------------------------------}
function tsortedstrvec.append(x:variant): integer;
begin
  result:= sortedappend(x);
end;
{---------------------------------------------------------------------------}
function tsortedstrvec.appendifnew(x:variant): integer;
begin
  result:= sortedappendifnew(x);
end;
{---------------------------------------------------------------------------}
function tsortedstrvec.lookup(x:variant): integer;
begin
  result:= sortedlookup(x);
end;
{---------------------------------------------------------------------------}
end.

