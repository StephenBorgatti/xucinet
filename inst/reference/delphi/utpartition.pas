unit utpartition;

interface
uses
  generics.collections,
  ucommon, utivec, utrows;

type
  tpartition = class   //1-based
    private
    num: integer; //number of items in partition
    public
    p: arrayofinteger;
    constructor create;
    destructor destroy; override;
    function getclass(i:integer): integer;
    procedure identity(size:integer);
    function getcapacity: integer;
    function getnumberofmembers(i:integer): integer;
    function getnumclasses: integer;
    function isidentity: boolean;
    function renumber: integer;
    procedure copy(apart:tpartition);
    procedure copytotivec(v:tivec);
    procedure fill(aval:integer=0);
    procedure setcapacity(acap:integer);
    procedure setclass(i:integer; c:integer);
    procedure setsize(asize:integer);
    property capacity:integer read getcapacity write setcapacity;
    property n:integer read num write setsize;
    property classof[i:integer]:integer read getclass write setclass; default;
  end;
  tclasses = class(trows<integer>)
    constructor createp(p:arrayofinteger; num:integer);
    function setup(p:arrayofinteger; num:integer): integer;
    procedure setnclasses(nclass:integer);
    property nclasses:integer read fnrows write setnclasses;
//    property jthmember[i,j:integer]:integer read getitem write setitem;
  end;

implementation

procedure tpartition.copytotivec(v: tivec);
var
  i: integer;
begin
  v.allocifneeded(n,true,false);
  for i:= 1 to n do
    v.cell[i]:= p[i];
end;

constructor tpartition.create;
begin

end;

destructor tpartition.destroy;
begin
  p:= nil;
end;

procedure tpartition.fill(aval: Integer=0);
var
  i: integer;
begin
  for i:= 1 to n do
    p[i]:= aval;
end;

procedure tpartition.copy(apart: tpartition);
begin
  num:= apart.num;
  capacity:= apart.capacity;
  p:= system.copy(apart.p);
end;

function tpartition.getnumclasses: integer;
var
  list: tlist<integer>;
  j: integer;
begin
  list:= tlist<integer>.create;
  for j:= 1 to num do
    if not list.contains(p[j])
      then list.Add(p[j]);
  result:= list.Count;
  list.Free;
end;

function tpartition.getnumberofmembers(i:integer): integer;
var
  j: integer;
begin
  result:= 0;
  for j:= 1 to n do
    if p[j] = i
      then inc(result);
end;

function tpartition.renumber: integer;
var
  uniq: tivec;
  i: Integer;
  list: tlist<integer>;
begin
  list:= tlist<integer>.create;
  for i:= 1 to num do
    if not list.Contains(p[i])
      then list.Add(p[i]);
  list.Sort;
  for i:= 1 to num do
    p[i]:= list.indexof(p[i]) + 1;
  result:= list.count;
  list.Free;
end;

function tpartition.getcapacity;
begin
  result:= high(p);
end;

function tpartition.getclass(i:integer): integer;
begin
  result:= p[i];
end;

procedure tpartition.setclass(i: Integer; c: Integer);
begin
  p[i]:= c;
end;

procedure tpartition.setcapacity(acap: Integer);
// 1-based
begin
  setlength(p,acap+1);
end;

procedure tpartition.setsize(asize: Integer);
begin
  num:= asize;
  if num > high(p)
    then setcapacity(num);
end;

procedure tpartition.identity(size:integer);
var
  i: integer;
begin
  setsize(size);
  for i:= 1 to num do
    p[i]:= i;
end;

function tpartition.isidentity: boolean;
var
  i: integer;
begin
  for i:= 1 to num do
    if p[i] <> i then exit(false);
  result:= true;
end;

constructor tclasses.createp(p: arrayofinteger; num:integer);
begin
  inherited create;
  setup(p,num);
end;

procedure tclasses.setnclasses(nclass:integer);
begin
  nrows:= nclass;
end;

function tclasses.setup(p:arrayofinteger; num:integer): integer;
var
  list: tlist<integer>;
  j,aclass: integer;
begin
  list:= tlist<integer>.create;
  for j:= 1 to num do  //make list of unique class identifiers
    if not list.contains(p[j])
      then list.Add(p[j]);
  list.Sort;
  nclasses:= list.Count;
  for j:= 1 to num do begin //place nodes in classes numbered 1...list.count
    aclass:= list.IndexOf(p[j]) + 1;
    additem(aclass,j);
    end;
  result:= nclasses;
  list.Free;
end;

end.

