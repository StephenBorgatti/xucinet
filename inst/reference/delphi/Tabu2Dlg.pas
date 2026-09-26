unit Tabu2Dlg;

interface

uses WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls, Dialogs, ExtCtrls, UGeneral, uFN, udialogs;

type
  {Declare a Factions Dialog Box type}
  TTabuSearch2Dlg = class(TForm)
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    Bevel1: TBevel;
    Label7: TLabel;
    NoBlocks: TEdit;
    Label5: TLabel;
    Label3: TLabel;
    MaxIterations: TEdit;
    Label4: TLabel;
    Penalty: TEdit;
    Label8: TLabel;
    RandomStarts: TEdit;
    Label9: TLabel;
    RandomSeed: TEdit;
    Label10: TLabel;
    OutputFn: TEdit;
    Label11: TLabel;
    OutputSets: TEdit;
    Label12: TLabel;
    InputFn: TEdit;
    CutOff: TEdit;
    Label1: TLabel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    Diagonal: TComboBox;
    procedure FormActivate(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure InputFnDblClick(Sender: TObject);
    procedure OutputFnDblClick(Sender: TObject);
    procedure OutputSetsDblClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TabuSearch2Dlg: TTabuSearch2Dlg;

implementation

uses Ucinet;
{$R *.DFM}

procedure TTabuSearch2Dlg.FormActivate(Sender: TObject);
begin
     {Reset listboxes to first options
     Diagonal.ItemIndex := 1;}
end;

procedure TTabuSearch2Dlg.OKBtnClick(Sender: TObject);
begin
     {Close dialog box and return OK code if OK was clicked}
     ModalResult := mrOK;
end;

procedure TTabuSearch2Dlg.CancelBtnClick(Sender: TObject);
begin
     {Close dialog box and return Cancel code if Cancel was clicked}
     ModalResult := mrCancel;
end;

procedure TTabuSearch2Dlg.InputFnDblClick(Sender: TObject);
begin
  stdpickopenfile(inputfn);
end;

procedure TTabuSearch2Dlg.OutputFnDblClick(Sender: TObject);
begin
  stdpicksavefile(outputfn);
end;

procedure TTabuSearch2Dlg.OutputSetsDblClick(Sender: TObject);
begin
  stdpicksavefile(outputsets);
end;

procedure TTabuSearch2Dlg.SpeedButton1Click(Sender: TObject);
begin
     InputFnDblClick(Sender);
end;

procedure TTabuSearch2Dlg.SpeedButton2Click(Sender: TObject);
begin
     OutputFnDblClick(Sender);
end;

procedure TTabuSearch2Dlg.SpeedButton3Click(Sender: TObject);
begin
     OutputSetsDblClick(Sender);
end;

end.
