unit uEgonet;
interface
uses
  classes,
  ucommon, utsmat, utivec, ug2key;

procedure getegonet(enet,net:tsmat; ego:integer; method:tegometh=em_union);
function  getalters(dsl:tivec; x:tsmat; ego:integer; method:tegometh=em_union; includeego:boolean=true): integer;
function  istie(a,b:integer; x:tsmat; method:tegometh): boolean;
function  whichegometh(s:string; default:tegometh): tegometh; overload;
function  whichegometh(s:string): integer; overload;
procedure getTerm3(var term3:double; t3mat,enet:tsmat);
procedure getalterdeg(deg:tivec; enet:tsmat);

implementation

function whichegometh(s:string): integer;
//0-based
begin
  result:= whichkeyrange(s,['out','@in|inc','un|bot|any|either','int|rec']);
end;

function whichegometh(s:string; default:tegometh): tegometh;
var
  temp: integer;
begin
  result:= default;
  temp:= whichegometh(s);
  if temp > -1 then result:= tegometh(temp);
end;

function istie(a,b:integer; x:tsmat; method:tegometh): boolean;
begin
  case method of
    em_out: result:= x.nonzero(a,b);
    em_in: result:= x.nonzero(b,a);
    em_union: result:= x.nonzero(a,b) or x.nonzero(b,a);
    em_intersect: result:= x.nonzero(a,b) and x.nonzero(b,a);
    end;
end;

function getalters(dsl:tivec; x:tsmat; ego:integer; method:tegometh=em_union; includeego:boolean=true): integer;
//if includeego=true then it will be the first row/col
var
  i,j: integer;
begin
  dsl.allocate(x.n,false,true);
  dsl.n:= 0;
  if includeego then dsl.add(ego);
  for j:= 1 to x.n do if j <> ego then
    if istie(ego,j,x,method) then dsl.add(j);
  result:= dsl.n;
end;

procedure getegonet(enet,net:tsmat; ego:integer; method:tegometh=em_union);
//in output matrix, first node is always ego
begin
  getalters(net.rdsl,net,ego,method,true);
  net.cdsl.copy(net.rdsl);
  enet.copydsl(net);
end;

procedure getalterdeg(deg:tivec; enet:tsmat);
//ego is node 1, so we ignore
var
  i,j: integer;
begin
  deg.allocate(enet.n,true,true);
  for i:= 2 to enet.n do
    for j:= 2 to enet.n do if i<>j then
      if enet.cell[i,j] > 0
        then inc(deg.cell[i]);
end;

procedure getTerm3(var term3:double; t3mat,enet:tsmat);
var
  q,j: integer;
  deg: tivec;
  temp: double;
begin
  deg:= tivec.create;
  t3mat.allocateifneeded(enet.n,enet.n,true,false);
  t3mat.zerofill;
  getalterdeg(deg,enet);
  term3:= 0;
  for j:= 2 to enet.n do begin
    temp:= 0;
    for q:= 2 to enet.n do if j <> q then
      if enet.cell[j,q] > 0 then begin
        t3mat.cell[j,q]:= 1/(deg.cell[q] + 1);
        temp:= temp + t3mat.cell[j,q];
        end;
    term3:= term3 + sqr(temp);
    end;
  term3:= term3/sqr(enet.n-1);
  deg.Free;
end;

end.
