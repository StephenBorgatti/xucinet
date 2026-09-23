unit uc_EgoNetComposition;
interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, math,  ExtCtrls, StdCtrls, Buttons,
  ugeneral,ucommon, utsmatds, ufn, utsvec, uegocomposition, ug2display,
  ulogfile, udialogs, ustats, ustring;

type
  TEgoNetComposition = class(TForm)
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
    IgnoreOwn: TCheckBox;
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure DimensionChange(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure InputNetFnChange(Sender: TObject);
    procedure InputAttrFnChange(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure setlabels;
    function getattr(attr:tsvec): boolean;
    procedure run;
  end;

var
  EgoNetComposition: TEgoNetComposition;

implementation

{$R *.dfm}

procedure TEgoNetComposition.setlabels;
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

procedure TEgoNetComposition.DimensionChange(Sender: TObject);
begin
  if not fileexists(hsys(inputattrfn.text))
    then showmessage('Need to enter valid attribute filename.')
    else setlabels;
end;

function tegonetcomposition.getattr(attr:tsvec): boolean;
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

procedure tegonetcomposition.run;
label cleanup;
var
  meas,net,tab: tsmatds;
  attr: tsvec;
  err: string;
  log: logfile;
begin
  net:= tsmatds.create;
  meas:= tsmatds.create;
  attr:= tsvec.create;
  tab:= tsmatds.create;
  log:= logfile.stdcreate('Egonet Composition',copyright);
  log.putfn('Input Network:',inputnetfn.text);
  log.putfn('Input Attribute:',inputattrfn.text+' '+itemstr(dimension)
    +' '+inttostr(dimensionvalue.itemindex)+':'+itemstr(dimensionvalue));
  log.putstr('Ego Network Type:',egonettype.Items[egonettype.itemindex]);
  log.putfn('Output dataset:',outputfn.text);
  log.lf;
  if not net.load(inputnetfn.text) then goto cleanup;
  if not getattr(attr) then goto cleanup;
  if not egonetaltercomposition(net,egonettype.itemindex,attr,
    ignoreown.Checked,itemstr(dimensionvalue),meas,tab,err) then begin
    showmessage(err);
    goto cleanup;
    end;
  tab.displayasmatrix(log.f);
  meas.save(outputfn.text);
  display(log.f,meas);
  log.putfn('Output dataset:',outputfn.text);
  cleanup:
    log.browse;
    log.free;
    meas.free; net.free; attr.free; tab.free;
end;

procedure TEgoNetComposition.InputAttrFnChange(Sender: TObject);
begin
  if fileexists(hsys(inputattrfn.text)) then setlabels;
end;

procedure TEgoNetComposition.InputNetFnChange(Sender: TObject);
begin
  outputfn.Text:= allbutext(inputnetfn.Text)+'-EgoComposition';
end;

procedure TEgoNetComposition.OKBtnClick(Sender: TObject);
begin
  run;
end;

procedure TEgoNetComposition.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(tedit(inputnetfn));
end;

procedure TEgoNetComposition.SpeedButton2Click(Sender: TObject);
begin
  stdpickopenfile(tedit(inputattrfn));
end;

procedure TEgoNetComposition.SpeedButton3Click(Sender: TObject);
begin
  stdpicksavefile(tedit(outputfn));
end;

end.





