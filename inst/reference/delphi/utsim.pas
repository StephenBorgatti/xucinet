unit utsim;
interface
uses
  ucommon, utivec, utsmat, utsmatds, umath;

type
  tsim = class
    n,dx,dy,vx,vy,mx,my,cov,sx,sy,sxy,euc: extended;
    nvar,a,b,c,d,match,hamm: integer;
    meas: tsmatds;
    constructor create;
    destructor destroy; override;
    procedure clear;
    function getgamma(a,b:tsmat; idx:tivec; sym:boolean): double;
    procedure addcase(x,y: double);
    procedure calc;
    end;

const
  smcorr=1; smeuc=2; smham=3; smmatch=4; smjac=5; smgkbi=6; smhub=7;
  nvar = 7;

implementation

constructor tsim.create;
begin
  meas:= tsmatds.create;
  nvar:= 7;
  meas.allocsize(nvar,1);
  meas.rdvn.allocsize(nvar);
  meas.rdvn.sput(1,'Pearson Correlation');
  meas.rdvn.sput(2,'Euclidean Distance');
  meas.rdvn.sput(3,'Hamming Distance');
  meas.rdvn.sput(4,'Match Coef');
  meas.rdvn.sput(5,'Jaccard Coef');
  meas.rdvn.sput(6,'Goodman-Kruskal Gamma');
  meas.rdvn.sput(7,'Hubert Gamma');
  if meas.cdvn.allocsize(1)
    then meas.cdvn.sput(1,'Measure');
  clear;
end;

destructor tsim.destroy;
begin
  meas.free;
end;

procedure tsim.clear;
begin
  n:= 0; dx:= 0; dy:= 0; vx:= 0; vy:= 0; mx:= 0; my:= 0; cov:= 0; 
  sx:= 0; sy:= 0; sxy:= 0; euc:= 0; match:= 0; hamm:= 0;
  a:= 0; b:= 0; c:= 0; d:= 0;
  meas.zerofill;
end;

function tsim.getgamma(a,b:tsmat; idx:tivec; sym:boolean): double;
{an alternative to the addcase-calc combination}
var
  i,j: integer;
  g: double;
begin
  g:= 0.0;
  if sym
    then for i:= 2 to a.n do for j:= 1 to i-1 do
      g:= g + a.cell[i,j]*b.cell[idx[i],idx[j]]
    else for i:= 1 to a.nr do for j:= 1 to a.nr do if i<>j then
      g:= g + a.cell[i,j]*b.cell[idx[i],idx[j]];
  result:= g;
{  if sym
    then result:= 2.0*g/(a.nr*(a.nr-1))
    else result:= g/(a.nr*(a.nr-1));}
end;

procedure tsim.addcase(x,y: double);
begin
  n:= n + 1.0;
  dx:= x - mx; mx:= mx + dx/n; vx:= vx + (x-mx)*dx;
  dy:= y - my; my:= my + dy/n; vy:= vy + (y-my)*dy;
  cov:= cov + dx*(y-my);
  euc:= euc + sqr(x-y); sxy:= sxy + x*y;
  if x = y then inc(match) else inc(hamm);
  if feq(x,0)
    then if feq(y,0) then inc(d) else inc(c)
    else if feq(y,0) then inc(b) else inc(a);
end;

procedure tsim.calc;
var i: integer;
begin
  if n < 1
    then begin
      for i:= 1 to nvar do meas.cell[i,1]:= bna;
      end
    else begin
      cov:= cov/n; vx:= vx/n; vy:= vy/n; sx:= sqrt(vx); sy:= sqrt(vy);
      if (vx < singleprecision) or (vy < singleprecision)
        then meas.cell[1,1]:= bna
        else meas.cell[1,1]:= cov/(sx*sy);  {correlation}
      meas.cell[7,1]:= sxy; {hubert's gamma}
      if a*d+b*c > 0 then meas.cell[6,1]:= 1.0*(a*d-b*c)/(a*d+b*c); {goodman & kruskal}
      if a+b+c > 0 then meas.cell[5,1]:= 1.0*a/(a+b+c); {jaccard}
      meas.cell[4,1]:= match/n;  {match coefficient}
      meas.cell[3,1]:= hamm/n;  {hamming}
      if euc > 0 then meas.cell[2,1]:= sqrt(euc); {euclidean distance}
      end;
end;

end.
