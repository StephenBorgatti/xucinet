unit uc_EgoNetHomophily;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  math, Dialogs, ExtCtrls, StdCtrls, Buttons,
  ugeneral,ucommon, utsmatds, ufn, utsvec, utvvec, ug2display, utlogfile, udialogs,
  utsmat3ds, ustats, ustring, utindividualhomophily, utdvec,
  ComCtrls;


type
  TEgoNetHomophily = class(TForm)
    Group: TGroupBox;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    Label1: TLabel;
    Label2: TLabel;
    SpeedButton3: TSpeedButton;
    InputNetFn: TLabeledEdit;
    InputAttrFn: TLabeledEdit;
    Dimension: TComboBox;
    DimensionValue: TComboBox;
    OutputFn: TLabeledEdit;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    EgoNetType: TRadioGroup;
    ProgressBar1: TProgressBar;
    TablesFn: TLabeledEdit;
    SpeedButton4: TSpeedButton;
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure DimensionChange(Sender: TObject);
    procedure InputAttrFnChange(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure InputNetFnChange(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure setlabels;
    function getattr(attr:tsvec): boolean;
    procedure run;
  end;

var
  EgoNetHomophily: TEgoNetHomophily;

implementation

{$R *.dfm}

procedure TEgoNetHomophily.setlabels;
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

procedure TEgoNetHomophily.DimensionChange(Sender: TObject);
begin
  if not fileexists(hsys(inputattrfn.text))
    then showmessage('Need to enter valid attribute filename.')
    else setlabels;
end;

function tegonetHomophily.getattr(attr:tsvec): boolean;
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
           attr.cell[j]:= m.cell[k,j];
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
    0: for i:= 2 to net.nr do for j:= 1 to i-1 do begin {both}
           net.cell[i,j]:= max(net.cell[i,j],net.cell[j,i]);
           net.cell[j,i]:= net.cell[i,j];
           end;
    1: begin {outgoing}
       end;
    2: if not net.transposesquarematrix then exit; {incoming}
    3: begin {reciprocated only}
         for i:= 2 to net.nr do for j:= 1 to i-1 do begin
           net.cell[i,j]:= min(net.cell[i,j],net.cell[j,i]);
           net.cell[j,i]:= net.cell[i,j];
           end;
       end;
    end;
  result:= true;
end;

procedure tegonethomophily.run;
label cleanup;
const
  avg = 1; sum = 2; min = 3; max = 4; sd = 5;
var
  meas,net: tsmatds;
  tab: tsmat3ds;
  attr: tsvec;
  i,j,k,num,nvar: integer;
  prod: double;
  log: tlogfile;
  s: tindividualhomophily;
  diagok: boolean;
begin
  s:= tindividualhomophily.create;
  net:= tsmatds.create;
  meas:= tsmatds.create;
  attr:= tsvec.create;
  tab:= tsmat3ds.create;
  log:= tlogfile.stdcreate('Egonet Alter-Ego Similarity (e.g., homophily) for categorical attributes',copyright);
  log.putfn('Input Network:',inputnetfn.text);
  log.putfn('Input Attribute:',inputattrfn.text+' '+dimension.text+' '+inttostr(dimensionvalue.itemindex)+':'+dimensionvalue.text);
  log.putstr('Ego Network Type:',egonettype.Items[egonettype.itemindex]);
  log.putfn('Output dataset:',outputfn.text);
  log.lf;
  if not net.loadhdr(inputnetfn.text) then goto cleanup;
  if egonettype.itemindex in [0,3] then
    if net.nr <> net.nc then begin
      showmessage('Network matrix must be square.');
      exit;
      end;
  if not getattr(attr) then goto cleanup;
  if attr.n <> net.nr then begin
    showmessage('Attribute vector must be same size as matrix rows.');
    goto cleanup;
    end;
  log.putstr('Note: this routine automatically dichotomizes the network data.','');
  meas.nafill;
  meas.nm:= net.nm;
  meas.mdvn.copy(net.mdvn);
  meas.rdvn.copy(net.rdvn);
  meas.title:= 'Node-level alter-ego similarity';
  meas.cdvn.copy(s.measlabels);
  nvar:= s.measlabels.n + 1;
  meas.cdvn.reallocsize(nvar);
  meas.cdvn.cell[nvar]:= itemstr(dimensionvalue);
  meas.allocate(net.nr,nvar,net.nm,true,true);
//  if not meas.allocsize(net.nr,nvar) then goto cleanup;
  if not tab.allocsize(2,2,net.nr) then goto cleanup;
  tab.mdvn.copy(net.rdvn);
  tab.cdvn.allocsize(2);
  tab.cdvn.fillwith('Same|Different');
  tab.rdvn.allocsize(2);
  tab.rdvn.fillwith('Tie|No Tie');
  tab.title:= 'Tie/No Tie by Same/Different';
  diagok:= net.Is2mode;
  progressbar1.Max:= net.nm; progressbar1.position:= 0;
  for k:= 1 to net.nm do begin
    if not net.loaddat(inputnetfn.text) then goto cleanup;
{    if attr.nm = net.nm then
      if not attr.loaddat(inputattfn.text) then goto cleanup;}
    massagematrix(net,egonettype.itemindex);
    meas.nafill;
    for i:= 1 to net.nr do begin
      if attr.isna(i) then continue;
      s.clear;
      for j:= 1 to net.nc do
        if (diagok or (i<>j)) and (net.cell[i,j] < na) and (attr.cell[j] < na) then begin
          s.addcase(net.cell[i,j]>0,samevalue(attr.cell[i],attr.cell[j]));
          end;
      s.calc;
      meas.copyvec2row(s.measures,i);
      meas.cell[i,nvar]:= attr.cell[i];
      if k = 1 then begin
      tab.cell[i,1,1]:= s.a;
      tab.cell[i,1,2]:= s.b;
      tab.cell[i,2,1]:= s.c;
      tab.cell[i,2,2]:= s.d;
      end;
      end;
    meas.savedat(outputfn.text);
    log.putstr(net.mdvn.labelget(k));
    if oktodisplay(meas.nr,meas.nc)
      then begin
        meas.displayasmatrix(log.stream);
        log.lf;
        log.writeln('The Bona measure is Bonacich''s 1972 measure "Techniques for analyzing overlapping memberships".');
        log.writeln('The H measure (aka raw homophily, realized homophily, or pctsame) is the observed proportion of ties that ingroup');
        log.writeln('The H* measure is the observed number of ingroup ties minus the expected');
        log.lf;
        end;
    progressbar1.StepBy(1);
    if k = 1
      then tab.save(tablesfn.Text);
    end;
  meas.savehdr(outputfn.text);
  if math.max(meas.nr,meas.nc) > displaysize
    then log.putstr('Log output suppressed due to size. Run Display to see results.');
  log.putfn('Output dataset:',outputfn.text);
  cleanup:
    log.browse;
    log.free;
    meas.free; net.free; attr.free; s.destroy; tab.free;
end;

procedure TEgoNetHomophily.InputAttrFnChange(Sender: TObject);
begin
  if ucinetfileexists(inputattrfn.Text) then setlabels;
end;

procedure TEgoNetHomophily.InputNetFnChange(Sender: TObject);
begin
  outputfn.Text:= allbutext(inputnetfn.Text)+'-EASCatMeas';
  tablesfn.Text:= allbutext(inputnetfn.Text)+'-EASCatTable';
end;

procedure TEgoNetHomophily.OKBtnClick(Sender: TObject);
begin
  if ucinetfileexists(inputnetfn.Text) and ucinetfileexists(inputattrfn.Text)
    then run
    else begin
      showmessage('One of your input files does not exist. Check and try again.');
      modalresult:= mrnone;
    end;
end;

procedure TEgoNetHomophily.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(tedit(inputnetfn));
end;

procedure TEgoNetHomophily.SpeedButton2Click(Sender: TObject);
begin
  stdpickopenfile(tedit(inputattrfn));
end;

procedure TEgoNetHomophily.SpeedButton3Click(Sender: TObject);
begin
  stdpicksavefile(tedit(outputfn));
end;

procedure TEgoNetHomophily.SpeedButton4Click(Sender: TObject);
begin
  stdpicksavefile(tedit(tablesfn));
end;

end.
