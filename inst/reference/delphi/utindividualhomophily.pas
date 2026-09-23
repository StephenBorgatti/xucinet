unit utindividualhomophily;
interface
uses
  math, ucommon, utstrvec, utdvec;
type
tindividualhomophily = class
private
  procedure calckappa;
  procedure copymeasures;
public
  a,b,c,d,n,nmeas: integer;
  ad,bc: double;
  h,hstar,coleman: double;
  corr,match,jac,ht,ei,coverage,yules,odds,logodds,cohen,bonacich,htnorm: double;
  measlabels: tstrvec;
  measures: tdvec;
  constructor create; virtual;
  destructor destroy; override;
  procedure clear;
  procedure addcase(istie,samegroup:boolean);
  procedure calc;
end;

implementation

constructor tindividualhomophily.create;
begin
  measures:= tdvec.create;
  measlabels:= tstrvec.create;
  measlabels.fillrange(['H','H*','Coleman','EI','Jaccard','Yules Q','Kappa','Phi',
                       'Bona','Odds_Ratio','Log_Odds','fInGroup','fOutGroup']);
  nmeas:= measlabels.n;
  measures.allocate(nmeas,true,true);
  clear;
end;

destructor tindividualhomophily.destroy;
begin
  measlabels.Free;
  measures.free;
end;

procedure tindividualhomophily.clear;
begin
  a:= 0; b:= 0; c:= 0; d:= 0; n:= 0;
  ad:= bna; bc:= bna;
  match:= bna; ei:= bna; coverage:= bna; yules:= bna; corr:= bna;
  odds:= bna; logodds:= bna; jac:= bna; ht:= bna; cohen:= bna;
  bonacich:= bna; htnorm:= bna; h:= bna; hstar:= bna; coleman:= bna;
  measures.fill(bna);
end;

procedure tindividualhomophily.addcase(istie,samegroup:boolean);
//a = has tie and same group
//b = has tie and different group
//c = no tie and same group
//d = no tie and different group
begin
  if istie
    then if samegroup
      then inc(a)
      else inc(b)
    else if samegroup
      then inc(c)
      else inc(d);
  inc(n);
end;

procedure tIndividualHomophily.calcKappa;
var
  g1,g2,f1,f2: double;
  e,o,den,adja,adjb,adjrs,mx: extended;
begin
  g1:= a + b;
  g2:= c + d;
  f1:= a + c;
  f2:= b + d;
  o:= 1.0*a/n;
  e:= 1.0*g1*f1/sqr(n);
  mx:= min(g1,f1)/n;
  if (e < 1.0) then cohen:= (o-e)/(mx-e);
  den:= 1.0*f1*f2*g1*g2;
  if den > 0
    then corr:= 1.0*(a*d-b*c)/sqrt(den);
  if f1 > 0 then begin
    adja:= a/f1;
    if f2 > 0 then begin
      adjb:= b/f2;
      adjrs:= adja + adjb;
      if adjrs > 0
        then htnorm:= adja/adjrs;
      end;
    end;
end;

procedure tIndividualHomophily.calc;
var
  aplusb,aplusc: integer;
  hexp: double;
begin
  aplusb:= a + b;
  aplusc:= a + c;
  ad:= a*d;
  bc:= b*c;
  if aplusb > 0 then begin
    h:= 1.0*a/aplusb;
    hexp:= aplusc/n;
    hstar:= h - hexp;
    if h >= hexp
      then coleman := hstar/(1.0 - hexp)
      else coleman := hstar/hexp;
    ei:= 1.0*(b-a)/aplusb;
    if aplusc > 0 then
      coverage:= 1.0*a/(aplusc);
    if n > 0 then
      match:= 1.0*(a+d)/n;
    if a+b+c > 0 then
      jac:= 1.0*a/(a+b+c);
    if (bc > 0) and (ad > 0) then begin
      odds:= ad/bc;
      if odds > 0 then logodds:= ln(odds);
      end;
    if ad + bc > 0
      then yules:= (ad - bc)/(ad + bc);
    if not samevalue(ad,bc)
      then bonacich:= (a*d - sqrt(a*b*c*d))/(ad-bc);
    calckappa;
    copymeasures;
    end;
end;

procedure tindividualhomophily.copymeasures;
begin
  measures.cell[1]:= h;
  measures.cell[2]:= hstar;
  measures.cell[3]:= coleman;
  measures.cell[4]:= ei;
  measures.cell[5]:= jac;
  measures.cell[6]:= yules;
  measures.cell[7]:= cohen;
  measures.cell[8]:= corr;
  measures.cell[9]:= bonacich;
  measures.cell[10]:= odds;
  measures.cell[11]:= logodds;
  measures.cell[12]:= a;
  measures.cell[13]:= b;
end;


end.
