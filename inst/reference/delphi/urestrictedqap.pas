unit urestrictedqap;
interface
uses
  dialogs,sysutils,
  ucommon, ugeneral, utcorr, utsmat, utimatds, utivec, urandom, utadjlist,
  ug2display, utsmatds, utstrvec, utvec, utunivariate, 
  urandomthreadsafe;

type
  trqapcorrrec = record
    obscorr: double;
    nperm,obsn,ngreat,nless: integer;
    avgcorr,sdcorr,pless,pgreat: double;
    end;
  trqapcorr = class
    q: trqapcorrrec;
    obs,temp: tcorr;
    s,s2: tunivariate;
    n,seed: integer;
    sym: boolean;
    map,id: tivec;
    ncat: integer;
    cat: array of tivec;
    protected
      procedure setperms(group:tvec);
      procedure correlate(c:tcorr; a,b:tsmat);
      procedure getobserved(a,b:tsmat);
      procedure getnextperm;
    published
      constructor create;
      destructor destroy; override;
      function run(a,b:tsmat; group:tvec; numperm:integer=5000): trqapcorrrec;
      procedure print(var f:textfile; var1,var2:string);
    end;

function runrestrictedqap(a,b:tsmat; group:tvec; numperm:integer=5000): trqapcorrrec; overload;
function runrestrictedqap(var f:textfile; a,b:tsmat; group:tvec; numperm:integer=5000): trqapcorrrec; overload;

implementation

function runrestrictedqap(var f:textfile; a,b:tsmat; group:tvec; numperm:integer=5000): trqapcorrrec;
var
  qap: trqapcorr;
begin
  qap:= trqapcorr.create;
  result:= qap.run(a,b,group,numperm);
  qap.print(f,'x','y');
  qap.destroy;
end;

function runrestrictedqap(a,b:tsmat; group:tvec; numperm:integer=5000): trqapcorrrec;
var
  qap: trqapcorr;
begin
  qap:= trqapcorr.create;
  result:= qap.run(a,b,group,numperm);
  qap.destroy;
end;

constructor trqapcorr.create;
begin
  s:= tunivariate.create;
  s2:= tunivariate.create;
  map:= tivec.create;
  id:= tivec.create;
  obs:= tcorr.create;
  temp:= tcorr.create;
  seed:= getrandomseed;
end;

destructor trqapcorr.destroy;
begin
  s.destroy; s2.Destroy;
  id.free; map.free;
  obs.destroy; temp.destroy;
end;

procedure trqapcorr.correlate(c:tcorr; a,b:tsmat);
//assumes id has been set
var
  i,j: integer;
begin
  c.clear;
  if sym
    then begin
        for i:= 2 to id.n do for j:= 1 to i-1 do
          if not (a.isna(i,j) or b.isna(id[i],id[j])) then
            c.addcasenomissing(a.cell[i,j],b.cell[id[i],id[j]]);
        end
    else begin
        for i:= 1 to id.n do for j:= 1 to id.n do if i<>j then
          if not (a.isna(i,j) or b.isna(id[i],id[j])) then
            c.addcasenomissing(a.cell[i,j],b.cell[id[i],id[j]]);
        end;
  c.calc;
end;

procedure trqapcorr.getobserved(a,b:tsmat);
begin
  correlate(obs,a,b);
end;

procedure trqapcorr.setperms(group:tvec);
//
var
  list: tstrvec;
  i: integer;
begin
  list:= tstrvec.create;
  map.allocsize(n);
  if group.n = 0 then begin group.allocate(n,false); group.fill(1); end;
  for i:= 1 to n do
    map[i]:= list.appendifnewstr(group.sget(i));
  ncat:= list.n;
  setlength(cat,ncat+1);
  for i:= 1 to ncat do
    cat[i]:= tivec.create;
  for i:= 1 to n do
    cat[map[i]].add(i);
  list.free;
end;

procedure trqapcorr.getnextperm;
var
  i: integer;
begin
  for i:= 1 to ncat do begin
    cat[i].randomlypermute(seed);
    cat[i].resetcurrent;
    end;
  for i:= 1 to n do // swap current id with another one from that class
    id[i]:= cat[map[i]].getnextvalue;
end;

function trqapcorr.run(a,b:tsmat; group:tvec; numperm:integer=5000): trqapcorrrec;
label cleanup;
var
  k,j: integer;
  perms: timatds;
begin
  perms:= timatds.create;
  randomize;
  n:= a.n;
  perms.allocate(numperm,n,1,true,true);
  if not id.allocsize(n) then goto cleanup;
  id.one2n;
  getobserved(a,b); //must be done when id is 1 to n
  q.obscorr:= obs.corr;
  if obs.corr >= na
    then numperm:= 0;
  q.obsn:= obs.d.n;
  setperms(group);
  sym:= a.issymmetric and b.issymmetric;
  s.clear; s2.clear;
  q.nperm:= 0;
  q.ngreat:= 0; q.nless:= 0;
  for k:= 1 to numperm do begin try
    getnextperm;
    for j:= 1 to n do 
      perms.cell[k,j]:= id.cell[j];
    correlate(temp,a,b);
    if obs.corr < bna then begin
      if temp.corr >= obs.corr then inc(q.ngreat);
      if temp.corr <= obs.corr then inc(q.nless);
      s.addcase(temp.corr);
      s2.addcase(temp.d.n);
      inc(q.nperm);
      end;
    except end;
    end;
  s.calc; s2.calc;
  q.pgreat:= (1.0+q.ngreat)/(q.nperm+1);
  q.pless:= (1.0+q.nless)/(q.nperm+1);
  q.avgcorr:= s.mean;
  q.sdcorr:= s.stddev;
  result:= q;
  perms.save('perms');
cleanup:
  perms.free;
end;

procedure trqapcorr.print(var f:textfile; var1,var2:string);
label cleanup;
var
  x: tsmatds;
begin
  x:= tsmatds.create;
  if not x.allocsize(1,6) then goto cleanup;
  if not x.cdvn.allocsize(x.nc) then goto cleanup;
  if not x.rdvn.allocsize(x.nr) then goto cleanup;
  x.rdvn.sput(1,'Pearson Correlation:');
  x.cdvn.sput(1,'Observed');
  x.cdvn.sput(2,'Significance');
  x.cdvn.sput(3,'Average');
  x.cdvn.sput(4,'Std Dev');
  x.cdvn.sput(5,'Cases');
  x.cdvn.sput(6,'SDofN');
  x.cell[1,1]:= q.obscorr;
  if q.obscorr < 0 then x.cell[1,2]:= q.pless else x.cell[1,2]:= q.pgreat;
  x.cell[1,3]:= s.mean;
  x.cell[1,4]:= s.stddev;
  x.cell[1,5]:= q.obsn;
  x.cell[1,6]:= s2.stddev;
  x.title:= 'QAP results for '+var1+' * '+var2 + ' (' + inttostr(q.nperm)+' permutations)';
  display(f,x,pagewidth,10,3);
  cleanup:
    x.free;
end;

end.
