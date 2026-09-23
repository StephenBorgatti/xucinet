unit uc_egonettiecomposition;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons,
  ucommon, ugeneral, udialogs, math,
  ufn, utsmatds, utivec, utsvec, ustring, utlogfile, ug2display, umath, utimat,
  utnodelist, utsmat3ds, ug2svd, utimatds, utunivariate, uvectools, utparser,
  uheterogeneity, utransform, unormalize, utegotiecomp2,
  uc_selectvariables;


type
  TEgonetTieComposition = class(TForm)
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    GroupBox1: TGroupBox;
    ifnbrowse: TSpeedButton;
    ofnbrowse: TSpeedButton;
    Ifn: TLabeledEdit;
    ofn: TLabeledEdit;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    WhichTies: TRadioGroup;
    DiagonalOk: TCheckBox;
    ValidOperator: TComboBox;
    ValidValue: TLabeledEdit;
    procedure ifnbrowseClick(Sender: TObject);
    procedure ofnbrowseClick(Sender: TObject);
    procedure IfnChange(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure run;
  end;

var
  EgonetTieComposition: TEgonetTieComposition;

implementation

{$R *.dfm}

procedure TEgonetTieComposition.ifnbrowseClick(Sender: TObject);
begin
  stdpickopenfile(ifn);
end;

procedure TEgonetTieComposition.IfnChange(Sender: TObject);
begin
  ofn.Text:= outfile(ifn.Text,'-tc');
end;

procedure TEgonetTieComposition.ofnbrowseClick(Sender: TObject);
begin
  stdpicksavefile(ofn);
end;

procedure TEgonetTieComposition.OKBtnClick(Sender: TObject);
begin
  if ucinetfileexists(ifn.Text)
    then run
    else begin
      showmessage('Network file not found');
      modalresult:= mrnone;
    end;
end;

procedure TEgonetTieComposition.run;
var
  log: tlogfile;
  i,k: integer;
  meas,net: tsmatds;
  op,n: integer;
  cut: single;
  diagok: boolean;
  etc: tegotiecomp;

  procedure setup;
  var
    j: integer;
  begin
    meas.allocate(n,net.nm*2+3,1,true,false);
    meas.nafill;
    meas.rdvn.copy(net.rdvn);
    meas.cdvn.allocate(net.nm*2 + 3,true,false);
    meas.cdvn.sput(1,'Ties');
    meas.title:= 'Tie composition';
    for j:= 1 to net.nm do begin
      meas.cdvn.sput(j+1,'f'+net.mdvn.labelget(j));
      meas.cdvn.sput(j+1+net.nm,'p'+net.mdvn.labelget(j));
      end;
    meas.cdvn.sput(2*net.nm+2,'Blau');
    meas.cdvn.sput(2*net.nm+3,'IQV');
    meas.title:= 'Node-level tie composition measures';
  end;

begin try
  log:= tlogfile.stdcreate('Node-level Tie Composition Measures');
  meas:= tsmatds.create;
  net:= tsmatds.create;
  etc:= tegotiecomp.create;
  log.putfn('Input network',ifn.Text);
  log.putstr('Which ties to count?',itemstr(whichties));
  log.putstr('Valid ties operator:',itemstr(validoperator));
  log.putstr('Valid ties value:',validvalue.text);
  log.putfn('Output measures',ofn.Text);
  log.lf;

  op:= validoperator.ItemIndex;
  cut:= strf(validvalue.Text);
  net.loadhdr(ifn.text);
  n:= net.n;
  setup;
  for k:= 1 to net.nm do begin
    net.loaddat;
    net.recode(opeq,0,bna);
    etc.addmat(net,whichties.ItemIndex,op,cut);
    end;
  etc.calc(meas);
  if meas.smallenoughtodisplay
    then meas.displayasmatrix(log.stream);
  meas.save(ofn.Text);
  finally
    log.browse;
    log.Free; meas.Free; net.Free; etc.Free;
  end;
end;

end.
