unit utbivariate;
interface
uses
  ucommon, math, umath;
{---------------------------------------------------------------------------}
type
  bistatsrec = record
    cov,corr: extended;
    end;
  tbivariate = class(tobject)
    private
      dx,dy: extended;
    public
    sx,sy,sxy,vx,vy,mx,my,n,cov,corr,gsq,chisq,euc,jaccard,minmax,
    identity,ssqx,ssqy,absdiff,sumx,sumy,wtsum,precision,recall,
    intersection,union,maxsum,minsum,nperceived,ntrue,nimagined,nmissed,accnonties,
    wtdprecision,wtdrecall,matches,sameval: extended;
    a,b,c,d: integer;
    nummiss: integer;
    needsreset: boolean;
    constructor create;
    destructor destroy; override;
    function asRec: bistatsrec;
    procedure addcase(x,y:extended);
    procedure addcasewt(x,y:extended; wt:extended=1.0);
    procedure calc;
    procedure clear;
    end;
{---------------------------------------------------------------------------}
implementation
{---------------------------------------------------------------------------}
constructor tbivariate.create;
begin clear; end;
{---------------------------------------------------------------------------}
procedure tbivariate.clear;
begin
  sx:= 0.0; sy:= 0; sxy:= 0; vx:= 0; vy:= 0; mx:= 0; my:= 0; n:= 0; cov:= 0; corr:= 0;
  gsq:= 0; chisq:= 0; euc:= 0; identity:= 0; ssqx:= 0; ssqy:= 0; absdiff:= 0;
  nummiss:= 0; sumx:= 0.0; sumy:= 0.0; wtsum:= 0; jaccard:= 0; intersection:= 0;
  union:= 0;  minsum:= 0.0; minmax:= 0.0; maxsum:= 0.0; precision:= 0.0;
  recall:= 0.0; nperceived:= 0.0; ntrue:= 0.0; wtdprecision:= 0.0; wtdrecall:= 0.0;
  needsreset:= true; nimagined:= 0.0; nmissed:= 0.0; accnonties:= 0.0;
  matches:= 0; sameval:= 0; a:= 0; b:= 0; c:= 0; d:= 0;
end;
{---------------------------------------------------------------------------}
function tbivariate.asRec: bistatsrec;
begin
  if needsreset then calc;
  result.cov:= cov;
  result.corr:= corr;
end;
{---------------------------------------------------------------------------}
procedure tbivariate.addcase(x,y:extended);
// for chiq, x=obs and y=exp
// for precision and recall, x=perceived, y=true
begin
  if (x < na) and (y < na) then begin
    n:= n + 1.0;
    wtsum:= wtsum + 1.0;
    ssqx:= ssqx + sqr(x);
    ssqy:= ssqy + sqr(y);
    dx:= x - mx; mx:= mx + dx/n; vx:= vx + (x-mx)*dx;
    dy:= y - my; my:= my + dy/n; vy:= vy + (y-my)*dy;
    cov:= cov + dx*(y-my); euc:= euc + sqr(x-y); sxy:= sxy + x*y;
    absdiff:= absdiff + abs(x-y);
    sumx:= sumx + x; sumy:= sumy + y;
    minsum:= minsum + min(x,y);
    maxsum:= maxsum + max(x,y);
    if samevalue(x,y,singleresolution) then sameval:= sameval + 1;
    if (x > singleresolution)
      then if y > singleresolution
        then inc(a)
        else inc(b)
      else if y > singleresolution
        then inc(c)
        else inc(d);
    intersection:= a;
    nperceived:= a + b;
    ntrue:= a + c;
    accnonties:= d;
    union:= a + b + c;
    if y > singleresolution
      then begin
        chisq:= chisq + sqr(x-y)/y;
        if x > singleresolution then gsq:= gsq + x*ln(x/y);
        end;
    end
    else inc(nummiss);
end;
{---------------------------------------------------------------------------}
procedure tbivariate.addcasewt(x,y:extended; wt:extended=1);
begin
  if (x < na) and (wt >= 0)
    then begin
      n:= n + 1;
      wtsum:= wtsum + wt;
      dx:= wt*(x-mx); mx:= mx + dx/wtsum; vx:= vx + (x-mx)*dx;
      dy:= wt*(y-my); my:= my+ dy/wtsum; vy:= vy + (y-my)*dy;
      cov:= cov + dx*(y-my);
      euc:= euc + sqr(x-y); sxy:= sxy + x*y;
      absdiff:= absdiff + abs(x-y);
      sumx:= sumx + x; sumy:= sumy + y;
      minsum:= minsum + min(x,y)*wt;
      maxsum:= maxsum + max(x,y)*wt;
      if (x > 0) and (y > 0) then intersection:= intersection + wt;
      if (x > 0) or (y > 0) then begin
        union:= union + wt;
        if x > 0 then nperceived:= nperceived + wt;
        if y > 0 then ntrue:= ntrue + wt;
        end
        else accnonties:= accnonties + wt;
      if y > 0{singleprecision}
        then begin
          chisq:= chisq + sqr(x-y)/y;
          if x > 0 {singleprecision} then gsq:= gsq + x*ln(x/y);
          end;
      end
    else inc(nummiss);
end;
{---------------------------------------------------------------------------}
procedure tbivariate.calc;
begin
  needsreset:= false;
  gsq:= gsq*2.0; euc:= sqrt(euc);
  if n < 1
    then begin
      corr:= bna;
      euc:= bna;
      matches:= bna;
      end
    else begin
      cov:= cov/wtsum;
      vx:= vx/wtsum;
      vy:= vy/wtsum;
      if vx > 0 then sx:= sqrt(vx);
      if vy > 0 then sy:= sqrt(vy);
      nimagined:= nperceived - intersection;
      nmissed:= ntrue - intersection;
      matches:= sameval/n;
      if nonzero(union)
        then jaccard:= intersection/union
        else jaccard:= bna;
      if nonzero(maxsum)
        then minmax:= minsum/maxsum
        else minmax:= bna;
      if nperceived > 0
        then precision:= intersection/nperceived
        else precision:= bna;
      if ntrue > 0
        then recall:= intersection/ntrue
        else recall:= bna;
      if sumx > 0
        then wtdprecision:= minsum/sumx
        else wtdprecision:= bna;
      if sumy > 0
        then wtdrecall:= minsum/sumy
        else wtdrecall:= bna;
      absdiff:= absdiff/wtsum;
      if ssqx+ssqy < singleprecision
        then identity:= bna
        else identity:= 2*sxy/(ssqx+ssqy);
      if (vx < singleprecision) or (vy < singleprecision)
        then corr:= bna
        else corr:= cov/(sx*sy);
      end;
End;
{---------------------------------------------------------------------------}
destructor tbivariate.destroy;
begin inherited destroy; end;
{---------------------------------------------------------------------------}

end.
