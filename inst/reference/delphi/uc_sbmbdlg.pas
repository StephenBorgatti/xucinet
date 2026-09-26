unit uc_sbmbdlg;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ComCtrls, ExtCtrls, udialogs;

type
  TSBMbDlg = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    HelpBtn: TBitBtn;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Label5: TLabel;
    Diagonal: TComboBox;
    Label3: TLabel;
    MaxIterations: TEdit;
    Label4: TLabel;
    Penalty: TEdit;
    Label8: TLabel;
    RandomStarts: TEdit;
    Label9: TLabel;
    RandomSeed: TEdit;
    Label12: TLabel;
    InputFn: TEdit;
    SpeedButton3: TSpeedButton;
    Label2: TLabel;
    NoBlocks: TEdit;
    Label10: TLabel;
    OutputFn: TEdit;
    SpeedButton1: TSpeedButton;
    Label11: TLabel;
    OutputSets: TEdit;
    SpeedButton2: TSpeedButton;
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SBMbDlg: TSBMbDlg;

implementation

{$R *.DFM}

procedure TSBMbDlg.SpeedButton3Click(Sender: TObject);
begin
  StdPickOpenFile(inputfn);
end;

procedure TSBMbDlg.SpeedButton2Click(Sender: TObject);
begin
  StdPickSaveFile(outputsets);

end;

procedure TSBMbDlg.SpeedButton1Click(Sender: TObject);
begin
  StdPickSaveFile(outputfn);

end;

procedure TSBMbDlg.BitBtn1Click(Sender: TObject);
begin
  modalresult:= mrcancel;
end;

procedure TSBMbDlg.FormActivate(Sender: TObject);
begin
  pagecontrol1.activepage:= tabsheet1;
end;

end.

