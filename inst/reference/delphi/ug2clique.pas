unit ug2clique;
interface
uses
  ucommon, utbmat, utsmat, utbmatds, utnodelist, utivec, ubronkb;

procedure getcliques(cliques,net:tbmat; minsize:integer=3); overload;
procedure getcliques(cliques:tbmat; net:tsmat; minsize:integer=3); overload;
procedure getncliques(cliques:tbmat; net:tnodelist; maxdist:integer=2; minsize:integer=3);
procedure getcliqueoverlap(o:tsmat; cliques:tbmat; method:integer=0; minsize:integer=3);

implementation

procedure getcliques(cliques,net:tbmat; minsize:integer=3);
begin
  cliquesets:= cliques;
  bronkerbosch(saveclique2,net,minsize);
end;

procedure getcliques(cliques:tbmat; net:tsmat; minsize:integer=3);
begin
  cliquesets:= cliques;
  bronkerbosch(saveclique2,net,minsize);
end;

procedure getncliques(cliques:tbmat; net:tnodelist; maxdist:integer=2; minsize:integer=3);
var
  d: tbmat;
begin try
  d:= tbmat.create();
  cliques.allocate(net.nr,1,1,true,false);
  net.getwithindist(d,maxdist);
  getcliques(cliques,d,minsize);
  finally
    d.free;
  end;
end;

procedure getcliqueoverlap(o:tsmat; cliques:tbmat; method:integer=0; minsize:integer=3);
var
  d: tbmat;
  cliquesize: array of integer;

  procedure getcliquesize;
  var
    i,j: integer;
  begin
    for j:= 1 to cliques.nc do begin
      cliquesize[j]:= 0;
      for i:= 1 to cliques.nr do
        if cliques[i,j] = 1 then inc(cliquesize[j]);
      end;
  end;
  
  procedure xxt;
  var
    i,j,k: integer;
    x: double;
  begin
    for i:= 1 to cliques.nr do
      for j:= 1 to i do begin
        x:= 0;
        for k:= 1 to cliques.nc do
          if (cliques.cell[i,k] = 1) and (cliques.cell[j,k] = 1)
            then case method of 
              -1: x:= x + 1.0/cliquesize[k];
               0: x:= x + 1.0;
               1: x:= x + cliquesize[k];
              end;
        o.cell[i,j]:= x;
        o.cell[j,i]:= x;
        end;
  end;
  
begin 
  o.allocate(cliques.nc,1,1,true,false);
  getcliquesize;
  xxt;
end;


end.
