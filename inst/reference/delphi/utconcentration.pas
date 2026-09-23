unit utconcentration;
(* G2 port of the core/periphery concentration diagnostics in G1
   uconcentration.getconcentration2. Given a continuous coreness vector,
   reports, for each candidate core size k (nodes taken in descending order
   of coreness), separation and density statistics that help pick a discrete
   core. Used by the continuous coreness routine (uc_continuouscoreness);
   the G1 unit remains for the CONCENT CLI function. *)

interface
uses
  ucommon, utsmat, utsvec, utivec, utbivariate;

function ginicoefficient(cent:tsvec): double;
function heterogeneity(cent:tsvec): double;
procedure getcorenessconcentration(var gini,hetero:double; conc:tsmat;
            net:tsmat; cent:tsvec; dsl:tivec);
(* conc gets n-1 rows (core sizes 1..n-1) by 8 columns:
   Diff, nDiff, Corr, Ident, CoreDen, PerDen, DenDiff, F
   (nc is set to 7 so the F column is allocated but not displayed, as in G1).
   dsl is filled with node indices in descending coreness order. *)

implementation

const
  eps = 0.000001;

{---------------------------------------------------------------------------}
function ginicoefficient(cent:tsvec): double;
// trapezoid Lorenz-curve gini over ascending coreness
var
  n,i: integer;
  asc: tivec;
  total,sum,prevy,cy: double;
begin
  result:= bna;
  n:= cent.n;
  if n < 2 then exit;
  asc:= tivec.create;
  try
    asc.allocate(n,true,true);
    asc.one2n;
    asc.sortby('a',cent);
    total:= 0;
    for i:= 1 to n do total:= total + cent.cell[asc[i]];
    if total <= 0 then exit;
    sum:= 0; prevy:= 0; cy:= 0;
    for i:= 1 to n do begin
      cy:= cy + cent.cell[asc[i]]/total;
      sum:= sum + (prevy + cy)/n;
      prevy:= cy;
      end;
    result:= 1.0 - sum;
  finally
    asc.Free;
  end;
end;
{---------------------------------------------------------------------------}
function heterogeneity(cent:tsvec): double;
var
  n,i: integer;
  sum,hom: double;
begin
  result:= bna;
  n:= cent.n;
  if n < 2 then exit;
  sum:= 0; hom:= 0;
  for i:= 1 to n do begin
    sum:= sum + cent.cell[i];
    hom:= hom + sqr(cent.cell[i]);
    end;
  if sum = 0 then exit;
  hom:= hom/sqr(sum);
  result:= (hom - 1.0/n)/(1.0 - 1.0/n);
end;
{---------------------------------------------------------------------------}
procedure getcorenessconcentration(var gini,hetero:double; conc:tsmat;
            net:tsmat; cent:tsvec; dsl:tivec);
const
  nvar = 8;
var
  n,i,j,k: integer;
  cs,c01: array of double;    // coreness in descending order: raw and 0-1 normalized
  part: array of integer;     // 1 = in core, original node indexing
  a,b: tbivariate;
  umin,umax,range: double;
  csum,psum,pai: double;
  ccount,pcount: integer;
  mincore,maxperiph,avgdiffmaxperiph,avgdiffmincore: double;
begin
  n:= cent.n;
  gini:= ginicoefficient(cent);
  hetero:= heterogeneity(cent);
  dsl.allocate(n,true,true);
  dsl.one2n;
  dsl.sortby('d',cent);
  if n < 2 then exit;

  a:= tbivariate.create;
  b:= tbivariate.create;
  try
    setlength(cs,n+1);
    setlength(c01,n+1);
    setlength(part,n+1);
    umin:= cent.cell[dsl[n]];
    umax:= cent.cell[dsl[1]];
    range:= umax - umin;
    for i:= 1 to n do begin
      cs[i]:= cent.cell[dsl[i]];
      if range > eps
        then c01[i]:= (cs[i] - umin)/range
        else c01[i]:= cs[i];
      part[i]:= 0;
      end;

    conc.allocsize(n-1,nvar);
    conc.cdvn.allocate(nvar,true);
    conc.cdvn.sput(1,'Diff');
    conc.cdvn.sput(2,'nDiff');
    conc.cdvn.sput(3,'Corr');
    conc.cdvn.sput(4,'Ident');
    conc.cdvn.sput(5,'CoreDen');
    conc.cdvn.sput(6,'PerDen');
    conc.cdvn.sput(7,'DenDiff');
    conc.cdvn.sput(8,'F');
    conc.title:= 'Concentration scores for different sizes of core';

    for k:= 1 to n-1 do begin
      part[dsl[k]]:= 1;

      // correlation and identity between the top-k indicator and coreness
      a.clear; b.clear;
      for i:= 1 to n do begin
        if i <= k then pai:= 1.0 else pai:= 0.0;
        a.addcase(pai,cs[i]);
        b.addcase(pai,c01[i]);
        end;
      a.calc; b.calc;

      // core-core and periphery-periphery densities
      csum:= 0; psum:= 0; ccount:= 0; pcount:= 0;
      for i:= 1 to n do
        for j:= 1 to n do if i <> j then
          if (part[i] = 1) and (part[j] = 1)
            then begin csum:= csum + net.cell[i,j]; inc(ccount); end
            else if (part[i] = 0) and (part[j] = 0)
              then begin psum:= psum + net.cell[i,j]; inc(pcount); end;

      // separation of the boundary in normalized coreness
      mincore:= c01[k];
      maxperiph:= c01[k+1];
      avgdiffmaxperiph:= 0;
      for i:= 1 to k do
        avgdiffmaxperiph:= avgdiffmaxperiph + c01[i] - maxperiph;
      avgdiffmaxperiph:= avgdiffmaxperiph/k;
      avgdiffmincore:= 0;
      for i:= k+1 to n do
        avgdiffmincore:= avgdiffmincore + mincore - c01[i];
      avgdiffmincore:= avgdiffmincore/(n-k);

      conc.cell[k,1]:= (avgdiffmaxperiph + avgdiffmincore)/2.0;
      conc.cell[k,2]:= conc.cell[k,1]*sqrt(k);
      conc.cell[k,3]:= a.corr;
      conc.cell[k,4]:= b.identity;
      if ccount > 0 then conc.cell[k,5]:= csum/ccount else conc.cell[k,5]:= bna;
      if pcount > 0 then conc.cell[k,6]:= psum/pcount else conc.cell[k,6]:= bna;
      if (ccount > 0) and (pcount > 0)
        then conc.cell[k,7]:= conc.cell[k,5] - conc.cell[k,6]
        else conc.cell[k,7]:= bna;
      if range > eps
        then conc.cell[k,8]:= conc.cell[k,1]/range
        else conc.cell[k,8]:= bna;
      end;
    conc.nc:= nvar-1;
  finally
    a.Free; b.Free;
    cs:= nil; c01:= nil; part:= nil;
  end;
end;
{---------------------------------------------------------------------------}
end.
