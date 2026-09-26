unit uc_sbmvdlg;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ComCtrls, ExtCtrls, udialogs;

type
  TSbmvDlg = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Label12: TLabel;
    InputFn: TEdit;
    SpeedButton3: TSpeedButton;
    Label2: TLabel;
    NoBlocks: TEdit;
    Label11: TLabel;
    OutputSets: TEdit;
    SpeedButton2: TSpeedButton;
    Label10: TLabel;
    OutputFn: TEdit;
    SpeedButton1: TSpeedButton;
    BitBtn2: TBitBtn;
    BitBtn1: TBitBtn;
    BitBtn3: TBitBtn;
    Label5: TLabel;
    Diagonal: TComboBox;
    Label3: TLabel;
    MaxIterations: TEdit;
    Label9: TLabel;
    RandomSeed: TEdit;
    Label4: TLabel;
    Penalty: TEdit;
    Label8: TLabel;
    RandomStarts: TEdit;
    procedure FormActivate(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SbmvDlg: TSbmvDlg;

implementation

{$R *.DFM}

procedure TSbmvDlg.FormActivate(Sender: TObject);
begin
  pagecontrol1.activepage:= tabsheet1;

end;

procedure TSbmvDlg.SpeedButton3Click(Sender: TObject);
begin
  stdpickopenfile(inputfn);
end;

procedure TSbmvDlg.SpeedButton2Click(Sender: TObject);
begin
  stdpicksavefile(outputsets);
end;

procedure TSbmvDlg.SpeedButton1Click(Sender: TObject);
begin
  stdpicksavefile(outputfn);
end;

end.

