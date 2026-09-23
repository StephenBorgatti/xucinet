unit uc_EgoNetStrength;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, math,
  ugeneral,ucommon, utsmatds, ufn, utsvec, ug2display, ulogfile, udialogs,
  utunivariate, ustring, umath;

type
  TEgoNetStrength = class(TForm)
    Group: TGroupBox;
    InputNetFn: TLabeledEdit;
    SpeedButton1: TSpeedButton;
    InputAttrFn: TLabeledEdit;
    SpeedButton2: TSpeedButton;
    Dimension: TComboBox;
    Label1: TLabel;
    DimensionValue: TComboBox;
    Label2: TLabel;
    OutputFn: TLabeledEdit;
    SpeedButton3: TSpeedButton;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    EgoNetType: TRadioGroup;
    WeightedTies: TRadioGroup;
    FilterOptions: TGroupBox;
    SDabove: TLabeledEdit;
    FilterAbove: TCheckBox;
    SDbelow: TLabeledEdit;
    FilterBelow: TCheckBox;
    AndBtn: TRadioButton;
    OrBtn: TRadioButton;
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure InputNetFnChange(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure DimensionChange(Sender: TObject);
    procedure InputAttrFnChange(Sender: TObject);
    procedure SDaboveChange(Sender: TObject);
    procedure SDbelowChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure setlabels;
    function getattr(attr:tsvec): boolean;
    procedure run;
  end;

var
  EgoNetStrength: TEgoNetStrength;

implementation

{$R *.dfm}

procedure TEgoNetStrength.setlabels;
label cleanup;
var
  m: tsmatds;
  i,j: integer;
begin
  m:= tsmatds.create;
  dimensionvalue.Clear;
  if fileexists(hsys(inputattrfn.text)) then begin
    if not m.loadhdr(inputattrfn.text) then goto cleanup;
    case dimension.itemindex of
      0: for j:= 1 to m.nc do dimensionvalue.items.add(m.cdvn.labelget(j));
      1: for i:= 1 to m.nr do dimensionvalue.items.add(m.rdvn.labelget(i));
      end;
    dimensionvalue.ItemIndex:= 0;
    end;
  cleanup:
    m.free;
end;

procedure TEgoNetStrength.DimensionChange(Sender: TObject);
begin
  if not fileexists(hsys(inputattrfn.text))
    then showmessage('Need to enter valid attribute filename.')
    else setlabels;
end;

procedure TEgoNetStrength.InputAttrFnChange(Sender: TObject);
begin
  if fileexists(hsys(inputattrfn.text)) then setlabels;
end;

procedure TEgoNetStrength.InputNetFnChange(Sender: TObject);
begin
  outputfn.Text:= allbutext(inputnetfn.Text)+'-compcont';
end;

function tegonetstrength.getattr(attr:tsvec): boolean;
label cleanup;
var
  m: tsmatds;
  i,j,k: integer;
begin
  result:= false;
  m:= tsmatds.create;
  if not m.load(inputattrfn.text) then goto cleanup;
  k:= dimensionvalue.itemindex + 1;
  case dimension.itemindex of
    0: begin
         if not attr.allocsize(m.nr) then goto cleanup;
         for i:= 1 to m.nr do
           attr.cell[i]:= m.cell[i,k];
         end;
    1: begin
         if not attr.allocsize(m.nc) then goto cleanup;
         for j:= 1 to m.nc do
           attr.cell[i]:= m.cell[k,j];
         end;
    end;
  result:= true;
  cleanup:
    m.free;
end;

function massagematrix(net:tsmatds; method:integer): boolean;
var
  i,j: integer;
begin
  result:= false;
  case method of
    0: net.symmetrize();
    1: begin {outgoing}
       end;
    2: begin {incoming}
         if not net.transposesquarematrix then exit;
       end;
    3: net.symmetrize(sy_inter); {reciprocated only}
    end;
  result:= true;
end;

procedure tegonetstrength.run;
label cleanup;
const
  nvar = 8;
  avg = 1; sum = 2; min = 3; max = 4; sd = 5; estsd = 6; nobs = 7; wtdnobs = 8;
  andop = 1; orop = 2;
  twnone = 0; twanal = 1; twprod = 2;
var
  meas,net: tsmatds;
  attr: tsvec;
  i,j,num,filterop,combop: integer;
  prod,highsd,lowsd: double;
  log: logfile;
  s,s2: tunivariate;
  tieweights: integer;
  normwts,usehighfilter,uselowfilter: boolean;

  procedure runstats(i:integer; s:tunivariate);
  var j: integer;
  begin
    s.clear;
    case tieweights of
      0: for j:= 1 to net.nc do if (i<>j) and (net.cell[i,j] > 0) and (net.cell[i,j] < na) and (attr.cell[j] < na) then
          s.addcase(attr.cell[j]);
      1: for j:= 1 to net.nc do if (i<>j) and (net.cell[i,j] > 0) and (net.cell[i,j] < na) and (attr.cell[j] < na) then
          s.addcasewt(attr.cell[j],net.cell[i,j]);
      2: for j:= 1 to net.nc do if (i<>j) and (net.cell[i,j] > 0) and (net.cell[i,j] < na) and (attr.cell[j] < na) then
          s.addcase(attr.cell[j]*net.cell[i,j]);
      end;
    s.calc;
  end;

  procedure runfilteredstats(i:integer; s:tunivariate);
  var j: integer;

    function qualifies(a:double): boolean;
    var hi,lo: boolean;
    begin
      result:= false; if (a >= na) or (s2.n <= 0) then exit;
      if usehighfilter
        then if (s2.stddev > 0)
          then hi:= (a - s2.mean)/s2.stddev <= highsd
          else hi:= false
        else hi:= true;
      if uselowfilter
        then if s2.stddev > 0
          then lo:= (a - s2.mean)/s2.stddev >= -lowsd
          else lo:= false
        else lo:= true;
      case combop of
        andop: result:= hi and lo;
        orop: result:= hi or lo;
        end;
    end;

  begin
    s.clear;
    case tieweights of
      0: for j:= 1 to net.nc do if (i<>j) and (net.cell[i,j] > 0) and (net.cell[i,j] < na) and (attr.cell[j] < na) then
          s.addcase(attr.cell[j]);
      1: for j:= 1 to net.nc do if (i<>j) and (net.cell[i,j] > 0) and (net.cell[i,j] < na) and (attr.cell[j] < na) then
          s.addcasewt(attr.cell[j],net.cell[i,j]);
      2: for j:= 1 to net.nc do if (i<>j) and (net.cell[i,j] > 0) and (net.cell[i,j] < na) and (attr.cell[j] < na) then
          s.addcase(attr.cell[j]*net.cell[i,j]);
      end;
    s.calc;
  end;

begin
  s:= tunivariate.create;
  s2:= tunivariate.create;
  net:= tsmatds.create;
  meas:= tsmatds.create;
  attr:= tsvec.create;
  log:= logfile.stdcreate('Egonet Composition: Continuous Attributes',copyright);
  log.putfn('Input Network:',inputnetfn.text);
  log.putfn('Input Attribute:',inputattrfn.text+' '+dimension.text+' '+inttostr(dimensionvalue.itemindex)+':'+dimensionvalue.text);
  log.putstr('Ego Network Type:',egonettype.Items[egonettype.itemindex]);
  log.putstr('Weighted Ties:',weightedties.Items[weightedties.itemindex]);
  log.putstr('Filter alters above mean?',bstr(filterabove.Checked));
  log.putstr('Filter alters below mean?',bstr(filterbelow.Checked));
  if filterabove.Checked then
    if filterabove.Checked
      then log.putstr('Use only alters ...',sdabove.Text+' SDs above mean');
    if filterbelow.checked
      then log.putstr('Use only alters ...',sdbelow.Text+' SDs below mean');
  if andbtn.Checked
    then log.putstr('Combine criteria via','AND')
    else log.putstr('Combine criteria via','OR');
  log.putfn('Output dataset:',outputfn.text);
  log.lf;

  if not net.load(inputnetfn.text) then goto cleanup;
  if not getattr(attr) then goto cleanup;
  massagematrix(net,egonettype.itemindex);
  if attr.n <> net.nr then begin
    showmessage('Attribute vector must be same size as matrix rows.');
    goto cleanup;
    end;
  tieweights:= weightedties.itemindex;
  if andbtn.Checked then combop:= andop else combop:= orop;
  if not trystrtofloat(sdabove.Text,highsd)
    then filterabove.Checked:= false;
  if not trystrtofloat(sdbelow.Text,highsd)
    then filterbelow.Checked:= false;
  usehighfilter:= filterabove.Checked;
  uselowfilter:= filterbelow.Checked;
  meas.cdvn.fillrange(['Avg','Sum','Min','Max','StdDev','EstSD','CV','Num','WtdNum']);
  meas.allocate(net.nr,meas.cdvn.n,1,true,false);
  meas.nafill();
  meas.rdvn.copy(net.rdvn);
  for i:= 1 to net.nr do begin
    if usehighfilter or uselowfilter
      then begin
        runstats(i,s2);
        runfilteredstats(i,s);
        end
      else runstats(i,s);
    meas.cell[i,1]:= s.mean;
    meas.cell[i,2]:= s.tot;
    meas.cell[i,3]:= s.min;
    meas.cell[i,4]:= s.max;
    meas.cell[i,5]:= s.stddev;
    meas.cell[i,6]:= s.estsd;
    meas.cell[i,7]:= s.cv;
    meas.cell[i,8]:= s.n;
    meas.cell[i,9]:= s.sumwt;
    end;
  if tieweights = 0
    then meas.setdim(meas.nr,nvar-1,1,false);
  meas.save(outputfn.text);
  meas.title:= 'Ego Net Composition - Continuous Attribute measures';
  meas.displayasmatrix(log.f);
//  display(log.f,meas,pagewidth,8);
  log.putfn('Output dataset:',outputfn.text);
  cleanup:
    log.browse;
    log.free;
    meas.free; net.free; attr.free; s.free; s2.free;
end;

(*procedure tegonetstrength.run;
label cleanup;
const
  nvar = 6;
  avg = 1; sum = 2; min = 3; max = 4; sd = 5; nobs = 6;
var
  meas,net: tsmatds;
  attr: tsvec;
  i,j,num,filterop: integer;
  prod,sds: double;
  log: logfile;
  s,s2: uestimator;
  useweighted,normwts,filteron: boolean;

  procedure runstats(s:uestimator);
  var j: integer;
  begin
    s.clear;
    if useweighted
      then begin
        for j:= 1 to net.nc do if (i<>j) and (net.cell[i,j] > 0) and (net.cell[i,j] < na) and (attr.cell[j] < na) then
          s.addcase(net.cell[i,j]*attr.cell[j]);
        end
      else begin
        for j:= 1 to net.nc do if (i<>j) and (net.cell[i,j] > 0) and (net.cell[i,j] < na) and (attr.cell[j] < na) then
          s.addcase(attr.cell[j]);
        end;
    s.calc;
  end;

  procedure runfilteredstats;
  var j: integer;

    function qualifies(a:double): boolean;
    begin
      result:= false;
      if a < na
        then case filterop of
          +1: if feq(sds,0)
                then result:= a >= s2.mean
                else if s2.stddev > 0
                  then result:= (a - s2.mean)/s2.stddev >= sds;
          -1: if feq(sds,0)
                then result:= a <= s2.mean
                else if s2.stddev > 0
                  then result:= (a - s2.mean)/s2.stddev <= sds;
          end;
    end;

  begin
    s.clear;
    if useweighted
      then begin
        for j:= 1 to net.nc do if (i<>j) and (net.cell[i,j] > 0) and (net.cell[i,j] < na) then
          if qualifies(attr.cell[j]) then s.addcase(net.cell[i,j]*attr.cell[j]);
        end
      else begin
        for j:= 1 to net.nc do if (i<>j) and (net.cell[i,j] > 0) and (net.cell[i,j] < na) then
          if qualifies(attr.cell[j]) then s.addcase(attr.cell[j]);
        end;
    s.calc;
  end;

begin
  s:= uestimator.create;
  s2:= uestimator.create;
  net:= tsmatds.create;
  meas:= tsmatds.create;
  attr:= tsvec.create;
  log:= logfile.stdcreate('Egonet Strength and Heterogeneity',copyright);
  log.putfn('Input Network:',inputnetfn.text);
  log.putfn('Input Attribute:',inputattrfn.text+' '+dimension.text+' '+inttostr(dimensionvalue.itemindex)+':'+dimensionvalue.text);
  log.putstr('Ego Network Type:',egonettype.Items[egonettype.itemindex]);
  log.putstr('Weighted Ties:',weightedties.Items[weightedties.itemindex]);
  log.putstr('Filter alters?',bstr(filteralters.Checked));
  if filteralters.Checked then
    if abovemean.Checked
      then log.putstr('Use only alters ...',stddeviations.Text+' SDs '+abovemean.Caption)
      else log.putstr('Use only alters ...',stddeviations.Text+' SDs '+belowmean.Caption);
  log.putfn('Output dataset:',outputfn.text);
  log.lf;

  if not net.load(inputnetfn.text) then goto cleanup;
  if not getattr(attr) then goto cleanup;
  massagematrix(net,egonettype.itemindex);
  if attr.n <> net.nr then begin
    showmessage('Attribute vector must be same size as matrix rows.');
    goto cleanup;
    end;
  if not meas.allocsize(net.nr,nvar) then goto cleanup;
  useweighted:= weightedties.itemindex = 1;
  if abovemean.Checked then filterop:= 1 else filterop:= -1;
  if trystrtofloat(stddeviations.Text,sds)
    then filteron:= filteralters.Checked
    else filteron:= false;
  for i:= 1 to net.nr do begin
    if filteron
      then begin
        runstats(s2);
        runfilteredstats;
        end
      else runstats(s);
    meas.cell[i,avg]:= s.mean;
    meas.cell[i,sum]:= s.tot;
    meas.cell[i,min]:= s.min;
    meas.cell[i,max]:= s.max;
    meas.cell[i,sd]:= s.stddev;
    meas.cell[i,nobs]:= s.n;
    end;
  if meas.cdvn.allocsize(nvar) then begin
    meas.cdvn.sput(avg,'Avg');
    meas.cdvn.sput(sum,'Sum');
    meas.cdvn.sput(min,'Min');
    meas.cdvn.sput(max,'Max');
    meas.cdvn.sput(sd,'StdDev');
    meas.cdvn.sput(nobs,'Num');
    end;
  meas.rdvn.copy(net.rdvn);
  meas.save(outputfn.text);
  meas.title:= 'Ego Net Strength Measures';
  display(log.f,meas,pagewidth,8);
  log.putfn('Output dataset:',outputfn.text);
  cleanup:
    log.browse;
    log.free;
    meas.free; net.free; attr.free; s.free; s2.free;
end; *)

procedure TEgoNetStrength.OKBtnClick(Sender: TObject);
begin
  run;
end;

procedure TEgoNetStrength.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(tedit(inputnetfn));
end;

procedure TEgoNetStrength.SpeedButton2Click(Sender: TObject);
begin
  stdpickopenfile(tedit(inputattrfn));
end;

procedure TEgoNetStrength.SpeedButton3Click(Sender: TObject);
begin
  stdpicksavefile(tedit(outputfn));
end;

procedure TEgoNetStrength.SDaboveChange(Sender: TObject);
begin
  if sdabove.Text <> '' then filterabove.Checked:= true;
  sdbelow.Text:= sdabove.Text;
end;

procedure TEgoNetStrength.SDbelowChange(Sender: TObject);
begin
  if sdbelow.Text <> '' then filterbelow.Checked:= true;
end;

end.
