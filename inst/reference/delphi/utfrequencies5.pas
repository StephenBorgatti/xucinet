unit utfrequencies5;
interface
uses
  generics.collections, generics.defaults, classes, sysutils, rtti,
  math,
  ucommon, utvec, utsmat, utsvec, utivec, utstrvec;
type
  tsortby = (sNone, sKey, sFreq);
  thetmeas = record
    het,iqv,entropy,nentropy,cr: double;
  end;
  tfrequencies<t> = class
    dict: tdictionary<t,single>;  //frequency of each value, indexed by value
    list: tlist<t>;  //list of unique values in order of encountering them
    appendifnew: boolean;
    tot,avg: double;
    constructor create;
    destructor destroy; override;
    function getdsl(v:t): integer;
    function getdvn(i:integer): string;
    function getfreq(i:integer): single;
    function getheterogeneity(ncat:integer=0): thetmeas; overload;
    function getheterogeneity2(ig:t; ncat:integer=0): thetmeas;
    function getprop(i:integer): single;
    function getcount: integer;
    function getvalue(i:integer): t;
    function mostfrequentvalue(var freq:single): t;
    function tostring(v:t): string;
    procedure addcase(v:t; wt:single=1.0); virtual;
    procedure clear; virtual;
    procedure clearfreq;
    procedure copydvn(dvn:tstrvec);
    procedure getheterogeneity(var het,iqv:double; ncat:integer=0); overload;
    procedure maketable(tab:tsmat; sortby:tsortby); //1-based
    procedure sortbyvalue(dir:char='a');
    procedure sortbyfreq(dir:char='d');
    property  n:integer read getcount;
    property  count:integer read getcount;
    property dsl[v:t]:integer read getdsl;        //1=smallest value, 2=next smallest, etc
    property dvn[i:integer]:string read getdvn;  //1-based array of strings
    property freq[i:integer]:single read getfreq;  //1-based array of frequencies
    property prop[i:integer]:single read getprop;  //1-based array of proportions
    property value[i:integer]:t read getvalue;  //1-based array. returns original value of ith item in list
  end;
  tfreqnumeric<t> = class(tfrequencies<t>)
    mean: double;
    function getlargestvalue: t;
    function getmode: t;
    function getsingle(aval:t): single;
    procedure addcase(v:t; wt:single=1.0); override;
    procedure clear; override;
    end;
  tfreqinteger = class(tfrequencies<integer>)

  end;

procedure getfrequencies(tab:tsmat; v:tivec; sortby:tsortby);
function renumber(y:tivec; x:tsvec): integer;
function renumberwithold(y:tivec; old,x:tsvec): integer;
function renumberwithfreq(y,f:tivec; dvn:tstrvec; x:tsvec): integer;
function renumbermatwithfreq(y:tsmat; f:tivec; dvn:tstrvec; x:tsmat; diagok:boolean=false):integer;

implementation

type
  TsingleComparer = TComparer<single>;

procedure getfrequencies(tab:tsmat; v:tivec; sortby:tsortby);
var
  f: tfreqinteger;
  i: integer;
begin
  f:= tfreqinteger.create;
  for i:= 1 to v.n do
    f.addcase(v.cell[i]);
  f.maketable(tab,sortby);
  f.Free;
end;

function renumber(y:tivec; x:tsvec): integer;
var
  i: integer;
  f: tfrequencies<single>;
begin
  f:= tfrequencies<single>.create;
  for i:= 1 to x.n do
    f.addcase(x.cell[i]);
  f.sortbyvalue;
  y.allocate(x.n,true,true);
  for i:= 1 to x.n do
    y.cell[i]:= f.dsl[x.cell[i]];
  result:= f.n;
  f.Free;
end;

function renumberwithold(y:tivec; old,x:tsvec): integer;
var
  i: integer;
  f: tfrequencies<single>;
begin
  f:= tfrequencies<single>.create;
  for i:= 1 to x.n do
    f.addcase(x.cell[i]);
  f.sortbyvalue;
  y.allocate(x.n,true,true);
  old.allocate(f.n,true,true);
  for i:= 1 to f.n do
    old.cell[i]:= f.value[i];
  for i:= 1 to x.n do
    y.cell[i]:= f.dsl[x.cell[i]];
  result:= f.n;
  f.Free;
end;

function renumberwithfreq(y,f:tivec; dvn:tstrvec; x:tsvec): integer;
var
  i: integer;
  freq: tfrequencies<single>;
begin
  freq:= tfrequencies<single>.create;
  for i:= 1 to x.n do
    freq.addcase(x.cell[i]);
  freq.sortbyvalue;
  y.allocate(x.n,true,true);
  for i:= 1 to x.n do
    y.cell[i]:= freq.dsl[x.cell[i]];
  f.allocate(freq.n,true,true);
  dvn.allocate(freq.n,true,true);
  for i:= 1 to freq.n do begin
    f.cell[i]:= round(freq.freq[i]);
    dvn.cell[i]:= freq.dvn[i];
    end;
  result:= freq.n;
  freq.Free;
end;

function renumbermatwithfreq(y:tsmat; f:tivec; dvn:tstrvec; x:tsmat; diagok:boolean=false):integer;
var
  i,j: integer;
  freq: tfrequencies<single>;
begin
  freq:= tfreqnumeric<single>.create;
  if not x.IsSquare
    then diagok:= true;
  for i:= 1 to x.nr do
    for j:= 1 to x.nc do if (i <> j) or diagok
      then freq.addcase(x.cell[i,j]);
  freq.sortbyvalue;
  y.allocate(x.nr,x.nc,1,true,true);
  for i:= 1 to x.nr do
    for j:= 1 to x.nc do if (i <> j) or diagok
      then y.cell[i,j]:= freq.dsl[x.cell[i,j]];
  f.allocate(freq.n,true,true);
  dvn.allocate(freq.n,true,true);
  for i:= 1 to freq.n do begin
    f.cell[i]:= round(freq.freq[i]);
    dvn.cell[i]:= freq.dvn[i];
    end;
  result:= freq.n;
  freq.Free;
end;

constructor tfrequencies<t>.create;
begin
  dict:= tdictionary<t,single>.create;
  list:= tlist<t>.create;
  appendifnew:= true;
  clear;
end;

destructor tfrequencies<t>.destroy;
begin
  dict.Free;
  list.Free;
end;

procedure tfrequencies<t>.clear;
begin
  dict.clear;
  list.clear;
  tot:= 0;
end;

procedure tfreqnumeric<t>.clear;
begin
  inherited clear;
  mean:= 0;
end;

procedure tfrequencies<t>.clearfreq;
var
  key: t;
begin
  for key in dict.Keys do
    dict[key]:= 0;
  tot:= 0;
end;

procedure tfrequencies<t>.addcase(v:t; wt:single=1.0);
//remember: location of items in dict moves as other items are found
//but list keeps them in order encountered
var
  f: single;
begin
  if dict.trygetvalue(v,f)
    then begin
      f:= f + wt;
      dict[v]:= f;
      tot:= tot + wt;
    end
    else if appendifnew then begin
      dict.Add(v,wt);
      tot:= tot + wt;
      list.add(v);
    end;
end;

procedure tfreqnumeric<t>.addcase(v:t; wt:single=1.0);
//remember: location of items moves as other items are found
var
  x: double;
begin
  inherited addcase(v,wt);
  x:= tvalue.from<t>(v).asextended;
  mean:= mean + wt*(x-mean)/tot;
end;

procedure tfrequencies<t>.sortbyvalue(dir:char='a');
//sorts distinct values
var
  key: t;
begin
  list.Sort;
  if dir in ['d','D']
    then list.Reverse;
end;

procedure tfrequencies<t>.sortbyfreq(dir:char='d');
var
  key: t;
  comparison: tcomparison<t>;
begin
  list.Clear;
  for key in dict.Keys do
    list.Add(key);
  Comparison :=
    function(const Left, Right: t): Integer
    begin
      if dict[right] > dict[left]
        then result:= 1
        else if dict[left] > dict[right]
          then result:= -1
          else result:= 0;
    end;
  List.Sort(TComparer<t>.Construct(Comparison));
  if dir in ['a','A']
    then list.Reverse;
end;

function tfrequencies<t>.tostring(v:t): string;
var
  x: extended;
begin
  result:= tvalue.from<t>(v).ToString;
  if trystrtofloat(result,x) and (x >= na)
    then result:= 'NA';
end;

procedure tfrequencies<t>.maketable(tab:tsmat; sortby:tsortby);
label cleanup;
var
  i: integer;
  key: t;
begin
  tab.allocate(n,2,1,true,false);
  tab.title:= 'Frequencies';
  tab.cdvn.fillwith('Freq|Prop');
  tab.rdvn.allocsize(n);
  case sortby of
    sKey: sortbyvalue;
    sFreq: sortbyfreq;
    end;
  i:= 0;
  for key in list do begin
    inc(i);
    tab.rdvn[i]:= tostring(key);
    tab.cell[i,1]:= dict[key];
    if tot <> 0
      then tab.cell[i,2]:= tab.cell[i,1]/tot
      else tab.cell[i,2]:= bna;
    end;
end;

function tfrequencies<t>.getdsl(v:t): integer;
//1-based
begin
  result:= list.IndexOf(v) + 1;
end;

function tfrequencies<t>.getdvn(i:integer): string;
//1-based
begin
  result:= tostring(list[i-1]);
end;

function tfrequencies<t>.getvalue(i:integer): t;
//1-based
begin
  result:= list[i-1];
end;

procedure tfrequencies<t>.copydvn(dvn:tstrvec);
var
  s: t;
begin
  dvn.allocate(n,false); dvn.n:= 0;
  for s in list do
    dvn.addstr(tostring(s)); 
end;

function tfrequencies<t>.getfreq(i:integer): single;
//1-based; returns frequency of the ith value encountered
begin
  result:= dict[list[i-1]];
end;

function tfrequencies<t>.getprop(i:integer): single;
//1-based
begin
  if tot <> 0
    then result:= dict[list[i-1]]/tot
    else result:= bna;
end;

function tfrequencies<t>.getcount: integer;
begin result:= dict.count; end;

function tfrequencies<t>.mostfrequentvalue(var freq:single): t;
var
  key: t;
  val: single;
begin
  freq:= -1E38;
  for key in list do begin
    val:= dict[key];
    if val > freq then begin
      result:= key;
      freq:= val;
      end;
    end;
end;

function tfreqnumeric<t>.getsingle(aval:t): single;
begin
  result:= tvalue.from<t>(aval).astype<single>;
end;

function tfreqnumeric<t>.getmode: t;
var
  key,lg: t;
  maxfreq,mindiff,diff: single;
  modes: tlist<t>;
begin
  modes:= tlist<t>.create;
  result:= mostfrequentvalue(maxfreq);
  maxfreq:= dict[result];
  for key in list do
    if dict[key] = maxfreq
      then modes.Add(key);
  if modes.Count = 1 then exit;
  //find the mode that is closest to average
  mindiff:= abs(getsingle(list[1])-mean);
  result:= list[1];
  for key in modes do begin
    diff:= abs(getsingle(key)-mean);
    if diff < mindiff then begin
      mindiff:= diff;
      result:= key;
      end;
    end;
  modes.Free;
end;

function tfreqnumeric<t>.getlargestvalue: t;
var
  key,lg: t;
  maxfreq,mindiff,diff: single;
  modes: tlist<t>;
begin
  sortbyvalue;
  result:= list[list.Count-1];
end;

procedure tfrequencies<t>.getheterogeneity(var het,iqv:double; ncat:integer=0);
var
  meas: thetmeas;
begin
  meas:= getheterogeneity(ncat);
  het:= meas.het;
  iqv:= meas.iqv;
end;

function tfrequencies<t>.getheterogeneity(ncat:integer=0): thetmeas;
var
  key: t;
  hom,freq,prop: double;
begin with result do begin
  if (dict.count = 0) or (tot <= 0) then begin
    het:= bna; iqv:= bna; 
    entropy:= bna; nentropy:= bna;
    cr:= bna;
    exit;
    end;
  if ncat = 0
    then ncat:= dict.count;
  cr:= (dict.count - 1)/(tot-1);
  hom:= 0; entropy:= 0; nentropy:= 0;
  for key in dict.Keys do begin
    freq:= dict[key];
    prop:= freq/tot;
    hom:= hom + sqr(prop);
    entropy:= entropy + (prop)*ln(prop);
    end;
  entropy:= -entropy;
  nentropy:= entropy/ln(ncat);
  het:= 1.0 - hom;
  if dict.count > 1
    then iqv:= het/(1.0-1.0/ncat)
    else iqv:= 0;
  end;
end;

function tfrequencies<t>.getheterogeneity2(ig:t; ncat:integer=0): thetmeas;
var
  key: t;
  hom,freq,prop: double;
begin with result do begin
  if (dict.count = 0) or (tot <= 0) then begin
    het:= bna; iqv:= bna;
    entropy:= bna; nentropy:= bna;
    cr:= bna;
    exit;
    end;
  if ncat = 0
    then ncat:= dict.count;
  cr:= (dict.count - 1)/(tot-1);
  hom:= 0; entropy:= 0; nentropy:= 0;
  for key in dict.Keys do begin
    freq:= dict[key];
    prop:= freq/tot;
    hom:= hom + sqr(prop);
    entropy:= entropy + (prop)*ln(prop);
    end;
  entropy:= -entropy;
  nentropy:= entropy/ln(ncat);
  het:= 1.0 - hom;
  if dict.count > 1
    then iqv:= het/(1.0-1.0/ncat)
    else iqv:= 0;
  end;
end;


end.

