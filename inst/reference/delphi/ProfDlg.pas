unit Profdlg;

interface

uses WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls, Dialogs, ExtCtrls, UGeneral, uFN, udialogs, ug2sim;

type
  {Declare Profile Similarity Dialog Box type}
  TProfileDlg = class(TForm)
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    Bevel1: TBevel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    OutputFn: TEdit;
    Label6: TLabel;
    OutputPar: TEdit;
    Label9: TLabel;
    InputFn: TEdit;
    SpeedButton1: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton2: TSpeedButton;
    Measure: TComboBox;
    Method: TComboBox;
    Transpose: TComboBox;
    Convert: TComboBox;
    Label7: TLabel;
    DiagramType: TComboBox;
    procedure OKBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure InputFnDblClick(Sender: TObject);
    procedure OutputFnDblClick(Sender: TObject);
    procedure OutputParDblClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure setdiagonaloptions(sender:tobject);
  end;

var
  ProfileDlg: TProfileDlg;

implementation

uses Ucinet;
{$R *.DFM}

procedure TProfileDlg.OKBtnClick(Sender: TObject);
begin
     {Close dialog box and return OK code}
     ModalResult := mrOK;
end;

procedure TProfileDlg.CancelBtnClick(Sender: TObject);
begin
     {Close dialog box and return Cancel code}
     ModalResult := mrCancel;
end;

procedure TProfileDlg.FormActivate(Sender: TObject);
begin
     {Reset listboxes to first options
     Measure.ItemIndex := 0;
     Method.ItemIndex := 0;
     Transpose.ItemIndex := 0;
     Convert.ItemIndex := 0;}
end;

procedure TProfileDlg.InputFnDblClick(Sender: TObject);
begin
  stdpickopenfile(inputfn);
end;

procedure TProfileDlg.OutputFnDblClick(Sender: TObject);
begin
  stdpicksavefile(outputfn);
end;

procedure TProfileDlg.OutputParDblClick(Sender: TObject);
begin
  stdpicksavefile(outputpar);
end;

procedure TProfileDlg.SpeedButton1Click(Sender: TObject);
begin
     InputFnDblClick(Sender);
end;

procedure TProfileDlg.SpeedButton3Click(Sender: TObject);
begin
     OutputFnDblClick(Sender);
end;

procedure TProfileDlg.SpeedButton2Click(Sender: TObject);
begin
     OutputParDblClick(Sender);
end;

procedure tprofiledlg.setdiagonaloptions(sender:tobject);
var i: integer;
begin
  If transpose.itemindex = 0
    then begin
      if (method.Items.count < 5) or (method.items.count = 0) then begin
        method.clear;
        for i:= 1 to 5 do
          method.items.Add(methstr(i));
        end;
//        method.itemindex:= 0;
      end
    else begin
      if (method.items.count > 3)or (method.items.count = 0) then begin
        method.clear;
        method.items.CommaText:= 'Ignore, Retain, Reciprocal';
        end;
//        method.itemindex:= 0;
      end;
end;

procedure TProfileDlg.FormCreate(Sender: TObject);
var i: integer;
begin
  method.clear;
  for i:= 1 to 5 do
    method.items.Add(methstr(i));
  method.itemindex:= 0;
end;

end.
