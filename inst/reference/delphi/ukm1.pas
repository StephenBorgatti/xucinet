unit ukm1;
interface
uses
  math, sysutils, windows,
  ucommon, utsmat, utivec, utrows;

procedure km1(p:tivec; d:tsmat; nb:integer; sim:boolean);

implementation

type
  km1func = function(dataij,refij:single): boolean;

function leftsmaller(dataij,refij:single): boolean;
begin result:= dataij < refij; end;

function leftbigger(dataij,refij:single): boolean;
begin result:= dataij > refij; end;

procedure km1(p:tivec; d:tsmat; nb:integer; sim:boolean);
//assumes d is symmetric
var
  ni,nj,n: integer;
  subsumed: array of boolean;
  dsl: array of integer;
  i,j,k,ndsl: integer;
  moredistant,closer: km1func;
  clusters: tintegerlists;

  Procedure GetFarthestPair;
  Var
    i,j: integer;
    ref: single;
  Begin
    ref:= d.cell[1,2]; ni:= 1; nj:= 2;
    for i:= 2 to n do
      for j:= 1 to i-1 do
        if moredistant(d.cell[i,j],ref) then begin
          ni:= i; nj:= j;
          ref:= d.cell[i,j];
          end;
  End;

  function GetFurthestItem: integer;
  Var
    i,j: integer;
    tot,besttot: single;
  Begin
    result:= 0;
    for j:= 1 to n do if not subsumed[j] then begin
      result:= j;
      besttot:= 0;
      for i:= 1 to ndsl do
        besttot:= besttot + d.cell[dsl[i],j];
      break;
      end;
    for j:= 1 to n do if not subsumed[j] then begin
      tot:= 0;
      for i:= 1 to ndsl do
        tot:= tot + d.cell[dsl[i],j];
      if moredistant(tot,besttot) then begin
        besttot:= tot;
        result:= j;
        end;
      end;
  End;

  Procedure PutinNearestCluster(i:integer);
  //need to use average closeness
  Var
    k,j,item,bestc: integer;
    ref,x,avg,bestavg: single;

    function getavg(clus:integer): single;
    var
      item, j: integer;
    begin
      result:= 0;
      for j:= 1 to clusters.nitems[clus] do begin
        item:= clusters.item[clus,j];
        result:= result + d.cell[i,item];
      end;
      result:= result/clusters.nitems[clus];
    end;

  Begin
    bestavg:= getavg(1); bestc:= 1;
    for k:= 2 to nb do begin
      avg:= getavg(k);
      if closer(avg,bestavg) then begin
        bestavg:= avg;
        bestc:= k;
        end;
      end;
    clusters.additem(bestc,i);
    subsumed[i]:= true; //unnecessary
  End;

begin try
  clusters:= tintegerlists.create;
  n:= d.n;
//  assert(d.IsSymmetric());
  p.allocifneeded(n,true,true);
  setlength(subsumed,n+1);
  zeromemory(subsumed,n+1);
  setlength(dsl,n+1);
  for i:= 1 to n do 
    dsl[i]:= i;
  if sim
    then begin moredistant:= leftsmaller; closer:= leftbigger; end
    else begin moredistant:= leftbigger; closer:= leftsmaller; end;
  getfarthestpair;
  dsl[1]:= ni;
  dsl[2]:= nj;
  ndsl:= 2;
  subsumed[ni]:= true;
  subsumed[nj]:= true;
  while ndsl < nb do begin
    nj:= getfurthestitem;
    inc(ndsl);
    dsl[ndsl]:= nj;
    subsumed[nj]:= true;
    end;
  for i:= 1 to nb do
    clusters.additem(i,dsl[i]);
  for i:= 1 to n do
    if not subsumed[i] then
      putinnearestcluster(i);
  for i:= 1 to nb do
    for j:= 1 to clusters.nitems[i] do
      p.cell[clusters.item[i,j]]:= i;
  finally
    subsumed:= nil; dsl:= nil; clusters.Free;
  end;
End;

end.
