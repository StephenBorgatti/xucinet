unit utunivariate;
interface
uses
  sysutils, classes, math,
  ucommon, umath;
{---------------------------------------------------------------------------}
const
  nstats = 23;
  s_none = 0;
  s_min = 1; s_mean = 2; s_max = 3; s_sum = 4; s_tot = 4;
  s_sd = 5; s_variance = 6; s_ssq = 7; s_mcssq = 8; s_norm = 9;
  s_nobs = 10; s_nmiss = 11; s_estsd = 12; s_estvar = 13; s_binary = 14;
  s_numnegs = 15; s_whole = 16; s_sumwt = 17; s_numpos = 18;
  s_n = 10; s_nrm = 9; s_avgpos = 19; s_cv = 20; s_absmin = 21;
  s_absmax = 22; s_range = 23;
  s_maximum = 3;

type
  tstatsrec = record
    min,max,ssq,mcssq,tot,nrm,sd,variance,mean,n,estsd,estvar,sumwt,
      pge,ple,pext,avgpos,cv,absmin,absmax,range: extended;
    numnegs,numpos,nmiss,ge,le,ext: integer;
    whole,binary: boolean;
  end;
  tstatsarray = array[0..nstats] of extended;
  tunivariate = class(tobject)
    private
      dx: extended;
    public
    min,max,ssq,mcssq,tot,nrm,sd,variance,mean,n,estsd,estvar,sumwt,
      pge,ple,pext,avgpos,cv,absmin,absmax,range: extended;
    numnegs,numpos,nmiss,ge,le,ext: integer;
    whole,binary: boolean;
    needsreset: boolean;
    constructor create;
    destructor destroy; override;
    function asArray: tstatsarray;
    function asTstatsRec: tstatsrec;
    procedure addcase(x:extended; ref:extended=bna);
    procedure addcasewt(x:extended; wt:extended=1.0);
    procedure calc;
    procedure clear; virtual;
    property sum:extended read tot write tot;
    property avg:extended read mean write mean;
    property average:extended read mean write mean;
    property stddev:extended read sd write sd;
    end;
  tsimpleuni = class
    private
      dx: double;
    public
    min,max,ssq,mcssq,mean,sum: extended;
    n: integer;
    constructor create;
    function getsd: extended;
    function getvariance: extended;
    procedure addcase(x:extended);
    procedure clear;
    property sd:extended read getsd;
    property variance:extended read getvariance;
    end;
  tssunivariate = class
    public
    min,max,sum: extended;
    n: integer;
    constructor create;
    function getmean: extended;
    procedure addcase(x:extended);
    procedure clear;
    property mean:extended read getmean;
    end;
  tmean = class
    public
    mean,sum: extended;
    n: integer;
    constructor create;
    procedure addcase(x:extended);
    procedure clear;
    end;

{---------------------------------------------------------------------------}
implementation
{---------------------------------------------------------------------------}
constructor tunivariate.create;
begin clear; end;
{---------------------------------------------------------------------------}
procedure tunivariate.clear;
begin
  sd:= 0; variance:= 0; mean:= 0; n:= 0; nrm:= 0; tot:= 0; ssq:= 0;
  mcssq:= 0; max:= -maxextended; min:= maxextended; estsd:= 0; estvar:= 0;
  binary:= true; numnegs:= 0; nmiss:= 0; whole:= true; sumwt:= 0;
  needsreset:= true; ge:= 0; le:= 0; ext:= 0; ple:= 0; pge:= 0; pext:= 0;
  numpos:= 0; avgpos:= 0; cv:= 0;
  absmin:= min;
  absmax:= max;
  dx:= 0; range:= bna;
end;
{---------------------------------------------------------------------------}
function tunivariate.asTstatsRec: tstatsrec;
begin
  if needsreset then calc;
  result.sd:= sd;
  result.variance:= variance;
  result.mean:= mean;
  result.n:= n;
  result.nrm:= nrm;
  result.tot:= tot;
  result.ssq:= ssq;
  result.mcssq:= mcssq;
  result.max:= max;
  result.min:= min;
  result.estsd:= estsd;
  result.estvar:= estvar;
  result.binary:= binary;
  result.numnegs:= numnegs;
  result.numpos:= numpos;
  result.nmiss:= nmiss;
  result.whole:= whole;
  result.sumwt:= sumwt;
  result.le:= le;
  result.ge:= ge;
  result.ext:= ext;
  result.ple:= ple;
  result.pge:= pge;
  result.pext:= pext;
  result.avgpos:= avgpos;
  result.cv:= cv;
  result.absmin:= absmin;
  result.absmax:= absmax;
  result.range:= range;
end;
{---------------------------------------------------------------------------}
function tunivariate.asArray: tstatsarray;
begin
  if needsreset then calc;
  result[s_min]:= min;
  result[s_sd]:= sd;
  result[s_variance]:= variance;
  result[s_mean]:= mean;
  result[s_n]:= n;
  result[s_nrm]:= nrm;
  result[s_tot]:= tot;
  result[s_ssq]:= ssq;
  result[s_mcssq]:= mcssq;
  result[s_max]:= max;
  result[s_min]:= min;
  result[s_estsd]:= estsd;
  result[s_estvar]:= estvar;
  result[s_binary]:= integer(binary);
  result[s_numnegs]:= numnegs;
  result[s_numpos]:= numpos;
  result[s_nmiss]:= nmiss;
  result[s_whole]:= integer(whole);
  result[s_sumwt]:= sumwt;
  result[s_avgpos]:= avgpos;
  result[s_cv]:= cv;
  result[s_absmin]:= absmin;
  result[s_absmax]:= absmax;
  result[s_range]:= range;
end;
{---------------------------------------------------------------------------}
procedure tunivariate.addcase(x:extended; ref:extended=bna);
var
  absx: extended;
begin try
  needsreset:= true;
  if (x < na)
    then begin
      n:= n + 1; ssq:= ssq + sqr(x); tot:= tot + x; sumwt:= sumwt + 1.0;
      dx:= x - mean; mean:= mean + dx/n; mcssq:= mcssq + (x-mean)*dx;
      if x > max then max:= x; if x < min then min:= x;
      absx:= abs(x);
      if absx > absmax then absmax:= absx;
      if absx < absmin then absmin:= absx;
      if (x<>0) and (x<>1) then binary:= false;
      if x < 0 then inc(numnegs);
      if x > 0 then begin
        inc(numpos);
        avgpos:= avgpos + (x - avgpos)/numpos;
        end;
      if x <> trunc(x) then whole:= false;
      if ref < na then begin
        if x >= ref then inc(ge);
        if x <= ref then inc(le);
        if abs(x) >= abs(ref) then inc(ext);
        end;
      end
    else inc(nmiss);
  except
    //raise exception.create(floattostr(x));
  end;
end;
{---------------------------------------------------------------------------}
procedure tunivariate.addcasewt(x:extended; wt:extended=1);
// assumes case weight of zero means ignore case
begin
  needsreset:= true;
  if (x < na) and (wt > 0)
    then begin
      n:= n + 1;
      sumwt:= sumwt + wt;
      dx:= wt*(x-mean);
      mean:= mean + dx/sumwt;
      mcssq:= mcssq + (x-mean)*dx;
      if x > max then max:= x; 
      if x < min then min:= x;
      ssq:= ssq + sqr(x); tot:= tot + x;
      if (x<>0) and (x<>1) then
        binary:= false;
      if x < 0 then inc(numnegs);
      if x <> trunc(x) then whole:= false;
      end
    else inc(nmiss);
end;
{---------------------------------------------------------------------------}
procedure tunivariate.calc;
begin
  needsreset:= false;
  nrm:= sqrt(ssq);
  if n = 0 then begin
    sd:= bna; variance:= bna; mean:= bna; nrm:= bna; tot:= bna; ssq:= bna;
    mcssq:= bna; max:= bna; min:= bna; estsd:= bna; estvar:= bna; cv:= bna;
    range:= bna;
    end;
  if (sumwt > 0) and (n > 0) then begin
    ple:= le/sumwt; pge:= ge/sumwt; pext:= ext/sumwt;
    if (max < na) and (min < na)
      then range:= max - min;
    variance:= mcssq/Sumwt;
    if variance > 0 then sd:= sqrt(variance);
    if n > 1 then begin
      estvar:= mcssq/((n-1.0)*sumwt/n);
      estsd:= sqrt(estvar);
      end;
    if not iszero(mean)
      then cv:= sd/mean;
    end
    else begin
      mean:= bna;
    end;
End;
{---------------------------------------------------------------------------}
destructor tunivariate.destroy;
begin inherited destroy; end;
{---------------------------------------------------------------------------}
constructor tsimpleuni.create;
begin clear; end;
{---------------------------------------------------------------------------}
procedure tsimpleuni.clear;
begin
  mean:= 0; n:= 0; ssq:= 0;  mcssq:= 0; sum:= 0;
  max:= -maxextended; min:= maxextended;
end;
{---------------------------------------------------------------------------}
procedure tsimpleuni.addcase(x:extended);
begin
  if (x < na)
    then begin
      n:= n + 1; sum:= sum + x; ssq:= ssq + sqr(x);
      dx:= x - mean; mean:= mean + dx/n; mcssq:= mcssq + (x-mean)*dx;
      if x > max then max:= x; if x < min then min:= x;
      end;
end;
{---------------------------------------------------------------------------}
function tsimpleuni.getsd: extended;
begin
  if n > 0
    then result:= sqrt(getvariance)
    else result:= bna;
end;
{---------------------------------------------------------------------------}
function tsimpleuni.getvariance: extended;
begin
  if n > 0
    then result:= mcssq/n
    else result:= bna;
end;
{---------------------------------------------------------------------------}
constructor tssunivariate.create;
begin clear; end;
{---------------------------------------------------------------------------}
procedure tssunivariate.clear;
begin
  n:= 0; sum:= 0;
  max:= minextended; min:= maxextended;
end;
{---------------------------------------------------------------------------}
procedure tssunivariate.addcase(x:extended);
begin
  if (x < na)
    then begin
      inc(n); 
      sum:= sum + x;
      if x > max then max:= x; 
      if x < min then min:= x;
      end;
end;
{---------------------------------------------------------------------------}
function tssunivariate.getmean: extended;
begin
  if n > 0 
    then result:= sum/n
    else result:= bna;
end;
{---------------------------------------------------------------------------}
constructor tmean.create;
begin clear; end;
{---------------------------------------------------------------------------}
procedure tmean.clear;
begin
   mean:= 0; n:= 0; sum:= 0;
end;
{---------------------------------------------------------------------------}
procedure tmean.addcase(x:extended);
begin
  if (x < na) then begin
    inc(n); 
    mean:= mean + (x-mean)/n;
    sum:= sum + x;
    end;
end;
{---------------------------------------------------------------------------}
end.
