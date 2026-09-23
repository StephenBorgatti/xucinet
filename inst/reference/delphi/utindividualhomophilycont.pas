unit utindividualhomophilycont;
interface
uses
  classes, generics.collections, sysutils,
  ucommon, umath, utcorr, utsmatds;
type
  tihcmethod = (ihczegers,ihcminmax,ihcabsdiff,ihcdiffsqrd,ihcprod,ihcnegabsdiff);
  txy = record
    x,y: single;
    end;
  tindividualhomophilycont = class
    c: tcorr;
    sim: binaryfunction;
    method: integer;
    constructor create;
    destructor destroy; override;
    function gethomophily: double;
    function getsimilarity(x,y:single): double;
    procedure clear;
    procedure addcase(tie,similarity:single); overload;
    procedure addcase(tie,x,y:single); overload;
    procedure setsimilarity(meth:integer);
    property homophily:double read gethomophily;
    end;

implementation

constructor tindividualhomophilycont.create;
begin
  sim:= fzegers;
  c:= tcorr.create;
  clear;
end;

destructor tindividualhomophilycont.destroy;
begin
  c.Free;
end;

procedure tindividualhomophilycont.clear;
begin
  c.clear;
end;

procedure tindividualhomophilycont.addcase(tie,similarity:single);
begin
  c.addcase(tie,similarity);
end;

procedure tindividualhomophilycont.addcase(tie,x,y:single);
begin
  c.addcase(tie,sim(x,y));
end;

procedure tindividualhomophilycont.setsimilarity(meth:integer);
begin
  case tihcmethod(meth) of
    ihczegers: sim:= fzegers;
    ihcminmax: sim:= fminovermaxh; //includes guard against zeros
    ihcabsdiff: sim:= fabsdiff;
    ihcdiffsqrd: sim:= fsqrdiff;
    ihcprod: sim:= fprod;
    ihcnegabsdiff: sim:= fnegabsdiff;
    end;
  method:= meth;
end;

function tindividualhomophilycont.getsimilarity(x,y:single): double;
begin
  result:= sim(x,y);
end;

function tindividualhomophilycont.gethomophily: double;
begin
  c.calc;
  result:= c.corr;
end;

end.
