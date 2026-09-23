{ ACTIVE: Used by CLI louvain and extendedlouvain commands (Xdpmat.runlouvain,
  Xdpmat.runextendedlouvain). }
unit utlouvain;
interface
uses
  math, generics.collections, sysutils, windows, stdctrls,
  ucommon, utpartition, utsmat, utimatds, ustring, utrows, utivec,
  utunivariate, utidlist;
Type
  tmypair = record
    cluster: integer;
    deltaq: double;
    end;
  tlouvain = class
    n: integer; //current number of nodes
    noriginal: integer; //initial number of nodes
    method: integer; // 0 = all egos; 1 = a few random egos
    initmeth: integer; //-1 = user-provided; 0 = identity; 1 = simple
    nclus: integer; //number of clusters in current phase (n of next phase)
    npart: integer; //current number of partitions
    maxpart,minclus: integer;
    currentq,sumofties: double;
    degree: array of double;
    initial: tivec;
    part: tpartition;  //the current partition
    m: arrayofarrayofsingle; //temporary storage for net
    neighboringclusters: tlist<integer>;  //list of clusters neighboring a node
    hier: timatds; //set of partitions
    net: tsmat; //input adjacency matrix;
    neighbors: tintegerlists; //like net but in nodelist form
    clustermembers: tintegerlists; //which nodes belong to each cluster
    memo: tmemo;
    constructor create;
    destructor destroy; override;
    function getbestmove(ego: integer): tmypair;
    function getdegree(ego:integer): double;
    function getq: double;
    function getdeltaq(i,clus:integer): double;
    function getsumofvalues: double;
    function nochange: boolean;
    procedure aggregate;
    procedure getdegrees;
    procedure getinitialpart;
    procedure initbycc(apart:tpartition);
    procedure movenodes;
    procedure print(s:string);
    procedure resetneighbors;
    procedure run(anet:tsmat; aninitial:tivec; aninitmeth:integer=0);
    procedure simpleinit(apart:tpartition);
    procedure storepart;
  end;

implementation

constructor tlouvain.create;
begin
  part:= tpartition.create;
  hier:= timatds.create;
  neighbors:= tintegerlists.create;
  clustermembers:= tintegerlists.create;
  neighboringclusters:= tlist<integer>.create;
  initial:= tivec.create;
  maxpart:= -1;
  minclus:= 2;
  initmeth:= 0;
  method:= 0;
end;

destructor tlouvain.destroy;
begin
  part.Free; hier.Free;
  neighbors.Free;
  neighboringclusters.Free;
  clustermembers.Free;
  m:= nil;
  degree:= nil;
end;

procedure tlouvain.print(s:string);
begin
  if assigned(memo)
    then memo.lines.add(s);
end;

function tlouvain.getdegree(ego:integer): double;
begin
  result:= net.getrowsum(ego);
end;

function tlouvain.getsumofvalues: double;
begin
  result:= net.getsum(true);
end;

procedure tlouvain.getdegrees;
var
  i: integer;
begin
  for i:= 1 to n do
    degree[i]:= net.getrowsum(i);
end;

procedure tlouvain.initbycc(apart:tpartition);
var
  i,j,node: integer;
  avail: tstack<integer>;
  cc: tidlist<single>;
  item: tmypair<single>;
  me: tmean;

  function getegonetdensity(i:integer): single;
  var
    k,m,kk,mm,num: integer;
  begin
    me.clear;
    num:= neighbors.nitems[i];
    for k:= 1 to num do begin
      kk:= neighbors.item[i,k];
      for m:= 1 to num do if m <> k then begin
        mm:= neighbors.item[i,m];
        me.addcase(net.cell[kk,mm]);
        end;
      end;
    result:= me.mean;
  end;

begin
  avail:= tstack<integer>.create;
  avail.Capacity:= n;
  for i:= 1 to n do
    cc.add(i,getegonetdensity(i));
  cc.sortdescending;
  for item in cc.items do
    avail.Push(item.id);
  apart.fill();
  while avail.Count > 0 do begin
    i:= avail.Pop;
    if apart[i] = 0 then begin
      apart[i]:= i;
      for j:= 1 to neighbors.nitems[i] do begin
        node:= neighbors.getitem(i,j);
        if apart[node] = 0 then
          apart[node]:= apart[i];
        end;
      end;
    end;
  avail.Free;
end;

procedure tlouvain.simpleinit(apart:tpartition);
var
  i,j,node: integer;
  avail: tstack<integer>;
begin
  avail:= tstack<integer>.create;
  avail.Capacity:= n;
  for i:= 1 to n do begin
    apart[i]:= 0;
    avail.push(i);
    end;
  while avail.Count > 0 do begin
    i:= avail.Pop;
    if apart[i] = 0 then begin
      apart[i]:= i;
      for j:= 1 to neighbors.nitems[i] do begin
        node:= neighbors.getitem(i,j);
        if apart[node] = 0 then
          apart[node]:= apart[i];
        end;
      end;
    end;
  avail.Free;
end;

procedure tlouvain.getinitialpart;
var
  temp: tpartition;
  i: integer;
begin
  temp:= tpartition.create;
  temp.capacity:= n;
  case initmeth of
   -1: for i:= 1 to n do
         temp[i]:= initial[i];
    0: temp.identity(n);
    1: simpleinit(temp);
    end;
  temp.renumber;
  part.copy(temp);
  temp.Free;
end;

function tlouvain.getq: double;
var
  k,i,j,ii,jj,num: integer;
begin
  clustermembers.clear;
  clustermembers.nrows:= nclus;
  for i:= 1 to n do
    clustermembers.additem(part[i],i);
  result:= 0;
  for k:= 1 to nclus do begin
    num:= clustermembers.nitems[k];
    for i:= 1 to num do begin
      ii:= clustermembers.item[k,i];
      for j:= 1 to num do begin
        jj:= clustermembers.item[k,j];
          result:= result + net.cell[ii,jj]-(degree[ii]*degree[jj])/sumofties;
        end;
      end;
  end;
  result:= result/sumofties;
end;

function tlouvain.getdeltaq(i: Integer; clus: Integer): double;
var
  oldclus: integer;
begin
  oldclus:= part[i];
  part[i]:= clus;
  result:= getq;
  part[i]:= oldclus;
end;

function tlouvain.getbestmove(ego: integer): tmypair;
var
  j,alter,cluster: integer;
  temp: double;

  procedure getadjacentclusters;
  var
    j,p: integer;
  begin
    neighboringclusters.clear;
    for j:= 1 to neighbors.nitems[ego] do begin
      p:= part[neighbors.item[ego,j]];
      if not neighboringclusters.Contains(p)
        then neighboringclusters.add(p);
      end;
  end;

begin
  result.cluster:= part[ego];
  result.deltaq:= currentq;
  getadjacentclusters;
  for cluster in neighboringclusters do begin
    temp:= getdeltaq(ego,cluster);
    if temp > result.deltaq then begin
      result.cluster:= cluster;
      result.deltaq:= temp;
      end;
    end;
end;

procedure tlouvain.movenodes;
var
  i,alter,nnodes: integer;
  anymoved,done: boolean;
  best: tmypair;

  procedure runit(node:integer);
  begin
    best:= getbestmove(node);
    if part[node] <> best.cluster then begin
      anymoved:= true;
      part[node]:= best.cluster;
      end;
  end;

begin
  anymoved:= true;
  while anymoved do begin
    anymoved:= false;
    case method of
      0: for i:= 1 to n do runit(i);
      1: begin
           nnodes:= max(1,n div 10);
           for i:= 1 to nnodes div 3 do
             runit(random(n)+1);
           end;
      end;
    end;
  //calculating full q, not deltaq
  currentq:= best.deltaq;
end;

procedure tlouvain.storepart;
var
  i,c: integer;
begin
  nclus:= part.renumber;
  inc(npart);
  for i:= 1 to noriginal do begin
    if npart = 1
      then c:= i
      else c:= hier[i,npart-1];
    hier[i,npart]:= part[c];
    end;
  hier.cdvn[npart]:= inttostr(nclus) + '|' + fstr(currentq,0,3);
end;

procedure tlouvain.aggregate;
var
  i,j,ii,jj: integer;
begin
  for i:= 1 to n do
    move(net.cell[i][0],m[i][0],4*(noriginal+1));
  net.zerofill;
  for i:= 1 to n do begin
    ii:= part[i];
    for j:= 1 to n do begin
      jj:= part[j];
      net.cell[ii,jj]:= net.cell[ii,jj] + m[i,j];
      end;
    end;
  n:= nclus;
  resetneighbors;
  getdegrees;
end;

function tlouvain.nochange: boolean;
//no longer needed
var
  i: integer;
begin
  if npart = 1 then exit(false);
  for i:= 1 to noriginal do
    if hier[i,npart-1] <> hier[i,npart]
      then exit(false);
  result:= true;
end;

procedure tlouvain.resetneighbors;
var
  i,j: integer;
begin
  neighbors.clear;
  neighbors.capacity:= n;
  for i:= 1 to n do
    for j:= 1 to n do
      if net.cell[i,j] > 0
        then neighbors.additem(i,j);
end;

procedure tlouvain.run(anet:tsmat; aninitial:tivec; aninitmeth:integer=0);
var
  q: double;
  i,j,it: integer;
  oldn: integer;
begin
  initmeth:= aninitmeth;
  initial:= aninitial;
  if (initmeth = -1) and (not initial.hasval)
    then initmeth:= 0;
  net:= anet;
  n:= net.n;
  noriginal:= net.n;
  part.n:= n;
  nclus:= n;
  setlength(m,n+1,n+1);
  setlength(degree,n+1);
  neighbors.nrows:= n;
  neighboringclusters.Capacity:= n;
  clustermembers.capacity:= n;
  if maxpart = -1
    then maxpart:= n;
  resetneighbors;
  hier.allocate(n,n,1,true,false);
  hier.rdvn.copy(net.rdvn);
  hier.cdvn.allocate(n,true,true);
  npart:= 0;
  getinitialpart;
  getdegrees;
  sumofties:= net.getsum();
  currentq:= getq;
  for it:= 1 to maxpart do begin
    movenodes;
    storepart;
    print('Iteration '+inttostr(npart)+': clusters='+inttostr(nclus)+' q='+floattostr(currentq));
    oldn:= n;
    aggregate;
    if n = oldn then begin
      dec(npart);
      break;
      end;
    if (n <= minclus) then break;
    part.identity(n);
    end;
  hier.nc:= npart; hier.cdvn.n:= npart;
end;

end.



