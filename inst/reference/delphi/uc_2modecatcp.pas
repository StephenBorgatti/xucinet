unit uc_2modecatcp;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ExtDlgs,
  Vcl.ComCtrls, Vcl.Buttons,
  ucommon, UFn,ugeneral,udupdash,ustring, utlogfile, udialogs, ulabels,
  utstrvec, utsmat3ds, ucategoricalautocorrelation, utcorr,
  ug2display,utunivariate,ug2dsl,utivec, utsmatds, ucan,
  ukey,
  uc_selectgroupsdlg, utsvec, uaggregate, utfrequencies5;

type
  Ttwomodecatcp = class(TForm)
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    GroupBox1: TGroupBox;
    inputfnspeedbutton: TSpeedButton;
    ifn: TLabeledEdit;
    rfn: TLabeledEdit;
    SpeedButton1: TSpeedButton;
    GroupBox2: TGroupBox;
    MaxIterations: TLabeledEdit;
    PopulationSize: TLabeledEdit;
    StopAfter: TLabeledEdit;
    cfn: TLabeledEdit;
    SpeedButton2: TSpeedButton;
    AuxiliaryGens: TLabeledEdit;
    procedure inputfnspeedbuttonClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure ifnChange(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  twomodecatcp: Ttwomodecatcp;

implementation

{$R *.dfm}

procedure Ttwomodecatcp.ifnChange(Sender: TObject);
begin
  rfn.Text:= outfile(ifn.text,'-rcp');
  cfn.Text:= outfile(ifn.text,'-ccp');
end;

procedure Ttwomodecatcp.inputfnspeedbuttonClick(Sender: TObject);
begin
  stdpickopenfile(ifn);
end;

procedure Ttwomodecatcp.OKBtnClick(Sender: TObject);
begin
  if not ucinetfileexists(ifn.text)
    then modalresult:= mrcancel;
end;

procedure Ttwomodecatcp.SpeedButton1Click(Sender: TObject);
begin
  stdpicksavefile(rfn);
end;

procedure Ttwomodecatcp.SpeedButton2Click(Sender: TObject);
begin
  stdpicksavefile(cfn);
end;

end.
