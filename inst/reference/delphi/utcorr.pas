unit utcorr;
interface
uses
  classes, sysutils, ucommon, utvec, utsmat, utivec;

type
  tcorrrec = record
    n: int64;
    w,nmiss,dx,dy,vx,vy,mx,my,cov,sx,sy,corr: extended;
    end;
  tcorr = class
    d: tcorrrec;
    constructor create;
    destructor destroy; override;
    procedure clear;
    procedure addcasenomissing(x,y: double); inline;
    procedure addcase(x,y: double); inline;
    procedure wtdaddcase(x,y,wt: double);
    procedure freqaddcase(x,y: double; wt:integer);
    function calc: tcorrrec;
    function asrecord: tcorrrec;
    property corr: extended read d.corr;
    property cov: extended read d.cov;
    end;

function getcorrelation(x,y:tvec): extended;
function getcorr(x,y:tsmat; diagok:boolean=false): extended;
function getmatcorr(a,b:tsmat; idx:tdsl; sym:boolean=false; hasna:boolean=true): extended;
procedure correlatecols(r,x:tsmat; diagok:boolean=false);

implementation

function getcorrelation(x,y:tvec): extended;
var
  i: integer;
  c: tcorr;
begin
  c:= tcorr.create;
  for i:= 1 to x.n do
    c.addcase(x.fget(i),y.fget(i));
  c.calc;
  result:= c.corr;
  c.free;
end;

function getcorr(x,y:tsmat; diagok:boolean=false): extended;
var
  i,j: integer;
  c: tcorr;
begin
  c:= tcorr.create;
  if (x.nr <> x.nc) then diagok:= true;
  for i:= 1 to x.nr do
    for j:= 1 to x.nc do if (i<>j) or diagok then
      c.addcase(x.cell[i,j],y.cell[i,j]);
  c.calc;
  result:= c.corr;
  c.Free;
end;

function getmatcorr(a,b:tsmat; idx:tdsl; sym:boolean=false; hasna:boolean=true): extended;
var
  i,j: integer;
  c: tcorr;
  needidx: boolean;
begin
  c:= tcorr.create;
  needidx:= idx = nil;
  if needidx then begin
    idx:= tdsl.create;
    idx.allocate(a.n,true,true); //automatically populate with 1 to n
    end;
  if sym
    then if hasna
      then begin
        for i:= 2 to a.n do for j:= 1 to i-1 do
          if not (a.isna(i,j) or b.isna(idx[i],idx[j])) then
            c.addcase(a.cell[i,j],b.cell[idx[i],idx[j]]);
        end
      else begin
        for i:= 2 to a.n do for j:= 1 to i-1 do
            c.addcase(a.cell[i,j],b.cell[idx[i],idx[j]]);
        end
    else if hasna
      then begin
        for i:= 1 to a.nr do for j:= 1 to a.nc do if i<>j then
          if not (a.isna(i,j) or b.isna(idx[i],idx[j])) then
            c.addcase(a.cell[i,j],b.cell[idx[i],idx[j]]);
        end
      else begin
        for i:= 1 to a.nr do for j:= 1 to a.nc do if i<>j then
            c.addcase(a.cell[i,j],b.cell[idx[i],idx[j]]);
        end;
  c.calc;
  result:= c.corr;
  if needidx
    then freeandnil(idx);
end;

procedure correlatecols(r,x:tsmat; diagok:boolean=false);
var
  c: tcorr;
  i,j,k: integer;
begin
  c:= tcorr.create;
  r.allocate(x.nc,x.nc,1,true,false);
  if x.Is2mode then diagok:= true;
  for i:= 1 to x.nc do
    for j:= 1 to i do begin
      c.clear;
      for k:= 1 to x.nr do
        if (k<>i) and (k<>j) or diagok
          then c.addcase(x.cell[k,i],x.cell[k,j]);
      c.calc;
      r.cell[i,j]:= c.corr;
      r.cell[j,i]:= r.cell[i,j];
    end;
  c.Free;
end;

constructor tcorr.create;
begin
  clear;
end;

destructor tcorr.destroy;
begin
  inherited destroy;
end;

procedure tcorr.clear;
begin
  with d do begin
  n:= 0; dx:= 0; dy:= 0; vx:= 0; vy:= 0; mx:= 0; my:= 0; cov:= 0; 
  corr:= bna; w:= 0;
  sx:= bna; sy:= bna; nmiss:= 0;
  end;
end;

procedure tcorr.addcasenomissing(x,y: double);
begin
  with d do begin
  w:= w + 1.0;
  dx:= x - mx; mx:= mx + dx/w; vx:= vx + (x-mx)*dx;
  dy:= y - my; my:= my + dy/w; vy:= vy + (y-my)*dy;
  cov:= cov + dx*(y-my);
  end;
end;

procedure tcorr.addcase(x,y: double);
begin try
  if (x < na) and (y < na)
    then addcasenomissing(x,y)
    else d.nmiss:= d.nmiss + 1.0;
  except
    raise exception.create('x '+floattostr(x)+' y '+floattostr(y));
  end;
end;

procedure tcorr.wtdaddcase(x,y,wt: double);
begin
  if (x < na) and (y < na) then with d do begin
    inc(n); w:= w + wt;
    dx:= wt*(x - mx); 
    mx:= mx + dx/w; 
    vx:= vx + (x-mx)*dx;
    dy:= wt*(y - my); 
    my:= my + dy/w; 
    vy:= vy + (y-my)*dy;
    cov:= cov + dx*(y-my);
    end;
end;

(*
procedure tcorr.wtdaddcase(x,y,wt: double);
begin
  if (x < na) and (y < na) then with d do begin
    inc(n); w:= w + wt;
    dx:= wt*(x - mx);
    mx:= mx + dx/w;
    vx:= vx + (x-mx)*dx;
    dy:= wt*(y - my);
    my:= my + dy/w;
    vy:= vy + (y-my)*dy;
    cov:= cov + dx*(y-my)*wt;
    end;
end;
*)

procedure tcorr.freqaddcase(x,y:double; wt:integer);
var
  i: integer;
begin
  inc(d.n);
  for i:= 1 to wt do
    addcase(x,y);
end;

function tcorr.calc: tcorrrec;
begin
  with d do if w > 0 then begin
    if n = 0
      then n:= round(w);
    cov:= cov/w; vx:= vx/w; vy:= vy/w; 
    sx:= sqrt(vx); sy:= sqrt(vy);
    if (vx < doubleprecision) or (vy < doubleprecision)
      then corr:= bna
      else corr:= cov/(sx*sy);
    end;
  result:= d;
end;

function tcorr.asrecord: tcorrrec;
begin result:= d; end;

end.
