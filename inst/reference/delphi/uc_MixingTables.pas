unit uc_MixingTables;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons,
  ucommon, utsmatds, ufn, utsvec, utfrequencies5, ug2display, utivec,
  utlogfile, udialogs, ustats, ustring, unetmixingmodels,
  uc_selectvaluelabelsdlg;

type
  TMixingTables = class(TForm)
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
    oFn: TLabeledEdit;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    TreatTies: TRadioGroup;
    ExpectedModel: TRadioGroup;
    efn: TLabeledEdit;
    dfn: TLabeledEdit;
    rfn: TLabeledEdit;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    AddLabelsBtn: TButton;
    procedure OKBtnClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure InputNetFnChange(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure InputAttrFnChange(Sender: TObject);
    procedure DimensionChange(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
    procedure AddLabelsBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    vlabels: tstringlist;
  public
    { Public declarations }
    function getattr(attr:tivec): boolean;
    procedure run;
    procedure setlabels;
  end;

var
  MixingTables: TMixingTables;

implementation

{$R *.dfm}

procedure TMixingTables.DimensionChange(Sender: TObject);
begin
  if not fileexists(hsys(inputattrfn.text))
    then showmessage('Need to enter valid attribute filename.')
    else setlabels;
end;

function TMixingTables.getattr(attr: tivec): boolean;
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
           attr.cell[i]:= round(m.cell[i,k]);
         end;
    1: begin
         if not attr.allocsize(m.nc) then goto cleanup;
         for j:= 1 to m.nc do
           attr.cell[i]:= round(m.cell[k,j]);
         end;
    end;
  result:= true;
  cleanup:
    m.free;
end;

procedure TMixingTables.InputAttrFnChange(Sender: TObject);
begin
  if ucinetfileexists(inputattrfn.text) then setlabels;
end;

procedure TMixingTables.InputNetFnChange(Sender: TObject);
begin
  ofn.Text:= allbutext(inputnetfn.Text)+'-mtobs';
  efn.Text:= allbutext(inputnetfn.Text)+'-mtexp';
  dfn.Text:= allbutext(inputnetfn.Text)+'-mtden';
  rfn.Text:= allbutext(inputnetfn.Text)+'-mtratio';
end;

procedure TMixingTables.OKBtnClick(Sender: TObject);
begin
  if ucinetfileexists(inputnetfn.Text)
    and ucinetfileexists(inputattrfn.Text)
      then run
      else begin
        showmessage('One of the input files is not right.');
        modalresult:= mrnone;
        end;
end;

procedure TMixingTables.run;
var
  x,o,e,d,r: tsmatds;
  f,p: tivec;
  n,ng,i,j,k: integer;
  log: tlogfile;
  directed: boolean;
begin try
  x:= tsmatds.create;
  o:= tsmatds.create;
  e:= tsmatds.create;
  d:= tsmatds.create;
  r:= tsmatds.create;
  f:= tivec.create;
  p:= tivec.create;
  log:= tlogfile.stdcreate('Mixing Tables',copyright);
  log.putfn('Input Network:',inputnetfn.text);
  log.putfn('Input Attribute:',inputattrfn.text+' '+itemstr(dimension)
    +' '+inttostr(dimensionvalue.itemindex)+':'+itemstr(dimensionvalue));
  log.putstr('(for undirected data) Treat ties as:',itemstr(treatties));
  log.putstr('Model for expected values:',itemstr(expectedmodel));
  log.putfn('Output observed mixing matrix:',ofn.text);
  log.putfn('Output expected mixing matrix:',efn.text);
  log.putfn('Output density matrix:',dfn.text);
  log.putfn('Output observed/expected ratio:',rfn.text);
  log.lf;

  x.loadhdr(inputnetfn.Text);
  o.mdvn.copy(x.mdvn); o.title:= 'Observed mixing table';
  e.mdvn.copy(x.mdvn); e.title:= 'Expected mixing table - ' + itemstr(expectedmodel) + ' model';
  d.mdvn.copy(x.mdvn); d.title:= 'Density table';
  r.mdvn.copy(x.mdvn); r.title:= 'Observed/expected ratio';
  getattr(p);
  getgroupsizes(f,p);
  ng:= f.n;
  for k:= 1 to x.nm do begin
    if x.nm > 1 then begin
      log.writeln('Matrix: ' + x.mdvn.getlabel(k));
      log.lf;
    end;
    x.loaddat;
    directed:= not x.IsSymmetric;
    if not directed
      then directed:= treatties.ItemIndex = 0;
    getobsmixingmatrix(o,x,p,f,directed);
    getexpmixingmatrix(e,x,p,f,directed,expectedmodel.ItemIndex);
    getdensitymatrix(d,x,p,f);
    r.allocateifneeded(ng,ng,true,false);
    r.rdvn.copy(o.rdvn); r.cdvn.copy(o.cdvn);
    for i:= 1 to ng do
      for j:= 1 to ng do
        if e.cell[i,j] > 0
          then r.cell[i,j]:= o.cell[i,j]/e.cell[i,j]
          else r.cell[i,j]:= bna;
    if vlabels.Count > 0 then
      for i:= 1 to ng do if i <= vlabels.Count then begin
        o.rdvn.sput(i,vlabels[i-1]); o.cdvn.sput(i,vlabels[i-1]);
        e.rdvn.sput(i,vlabels[i-1]); e.cdvn.sput(i,vlabels[i-1]);
        d.rdvn.sput(i,vlabels[i-1]); d.cdvn.sput(i,vlabels[i-1]);
        r.rdvn.sput(i,vlabels[i-1]); r.cdvn.sput(i,vlabels[i-1]);
        end;
    o.savedat(ofn.Text);
    e.savedat(efn.Text);
    d.savedat(dfn.Text);
    r.savedat(rfn.Text);
    o.displayasmatrix(log.stream);
    e.displayasmatrix(log.stream);
    d.displayasmatrix(log.stream);
    r.displayasmatrix(log.stream);
  end;
  o.savehdr(ofn.Text);
  e.savehdr(efn.Text);
  d.savehdr(dfn.Text);
  r.savehdr(rfn.Text);
  finally
    log.browse; log.Free;
    o.Free; e.Free; d.Free; r.Free; x.Free; p.Free; f.Free;
  end;
end;

procedure TMixingTables.setlabels;
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


procedure TMixingTables.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(inputnetfn);
end;

procedure TMixingTables.SpeedButton2Click(Sender: TObject);
begin
  stdpickopenfile(inputattrfn);
end;

procedure TMixingTables.SpeedButton3Click(Sender: TObject);
begin
  stdpicksavefile(ofn);
end;

procedure TMixingTables.SpeedButton4Click(Sender: TObject);
begin
  stdpicksavefile(efn);
end;

procedure TMixingTables.SpeedButton5Click(Sender: TObject);
begin
  stdpicksavefile(dfn);
end;

procedure TMixingTables.SpeedButton6Click(Sender: TObject);
begin
  stdpicksavefile(rfn);
end;

procedure TMixingTables.FormCreate(Sender: TObject);
begin
  vlabels:= tstringlist.create;
end;

procedure TMixingTables.FormDestroy(Sender: TObject);
begin
  vlabels.Free;
end;

procedure TMixingTables.AddLabelsBtnClick(Sender: TObject);
begin
  selectvaluelabels.showmodal;
  if selectvaluelabels.ModalResult = mrok
    then vlabels.Assign(selectvaluelabels.listoflabels.Lines);
end;

end.
