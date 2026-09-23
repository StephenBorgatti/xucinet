unit uc_2modelouvain;
{ GUI dialog for bipartite Louvain community detection
  (u2modelouvain.pas). The routine chooses the number of communities;
  each community may span both row and column nodes. }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls,
  ucommon, ustring, utsmatds, utlogfile, udialogs, ufn,
  utsmat, utivec, ug2display,
  u2modelouvain;

type
  T2ModeLouvainDlg = class(TForm)
    GroupBox1: TGroupBox;
    Inputfnbtn: TSpeedButton;
    InputFn: TLabeledEdit;
    RowPartFnbtn: TSpeedButton;
    RowPartFn: TLabeledEdit;
    ColPartFnbtn: TSpeedButton;
    ColPartFn: TLabeledEdit;
    GroupBox2: TGroupBox;
    lblSeed: TLabel;
    edtSeed: TEdit;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    procedure InputFnChange(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure InputfnbtnClick(Sender: TObject);
    procedure RowPartFnbtnClick(Sender: TObject);
    procedure ColPartFnbtnClick(Sender: TObject);
  private
  public
    procedure run;
  end;

var
  TwoModeLouvainDlg: T2ModeLouvainDlg;

implementation

{$R *.dfm}

procedure T2ModeLouvainDlg.InputfnbtnClick(Sender: TObject);
begin
  stdpickopenfile(InputFn);
end;

procedure T2ModeLouvainDlg.RowPartFnbtnClick(Sender: TObject);
begin
  stdpicksavefile(RowPartFn);
end;

procedure T2ModeLouvainDlg.ColPartFnbtnClick(Sender: TObject);
begin
  stdpicksavefile(ColPartFn);
end;

procedure T2ModeLouvainDlg.InputFnChange(Sender: TObject);
begin
  RowPartFn.Text := outfile(InputFn.Text, '-2mLouRows');
  ColPartFn.Text := outfile(InputFn.Text, '-2mLouCols');
end;

procedure T2ModeLouvainDlg.OKBtnClick(Sender: TObject);
begin
  if not ucinetfileexists(InputFn.Text) then begin
    showmessage('Input dataset not found.');
    modalresult := mrnone;
    exit;
  end;
  run;
end;

procedure T2ModeLouvainDlg.run;
var
  data: tsmatds;
  log: tlogfile;
  results: T2ModeLouvainResults;
  seed, i, j: integer;
  rowpart, colpart: tsmatds;
begin
  results.RowPart := nil;
  results.ColPart := nil;
  data := nil;
  log := nil;
  rowpart := nil;
  colpart := nil;
try
  seed := StrToIntDef(edtSeed.Text, 0);

  data := tsmatds.create;
  log := tlogfile.stdcreate('2-Mode Bipartite Communities (Louvain)', copyright);
  log.putfn('Input dataset:', InputFn.Text);
  log.putfn('Row partition output:', RowPartFn.Text);
  log.putfn('Column partition output:', ColPartFn.Text);
  log.putint('Seed:', seed);
  log.lf;

  data.load(InputFn.Text);

  TwoModeLouvain(data, seed, results);

  log.putint('Number of communities:', results.NumCommunities);
  log.putint('Row-side clusters:', results.NumRowClusters);
  log.putint('Col-side clusters:', results.NumColClusters);
  log.putfloat('Bipartite modularity (Q_b):', results.Modularity, 0, 4);
  log.putint('Sweeps:', results.Sweeps);
  log.putint('Accepted moves:', results.Moves);
  log.lf;

  log.write('Blocked adjacency matrix:');
  log.lf;
  blockdisplay(log.stream, data, results.RowPart, results.ColPart,
    pagewidth, -1, -1, 1.0, ' ');
  log.lf;

  rowpart := tsmatds.create;
  rowpart.allocate(data.nr, 1, 1, true, true);
  rowpart.title := 'Bipartite Community - Row Assignment';
  rowpart.rdvn.copy(data.rdvn);
  for i := 1 to data.nr do
    rowpart.cell[i, 1] := results.RowPart.cell[i];
  rowpart.save(RowPartFn.Text);

  colpart := tsmatds.create;
  colpart.allocate(data.nc, 1, 1, true, true);
  colpart.title := 'Bipartite Community - Column Assignment';
  colpart.rdvn.copy(data.cdvn);
  for j := 1 to data.nc do
    colpart.cell[j, 1] := results.ColPart.cell[j];
  colpart.save(ColPartFn.Text);

  log.outfile('Row community saved as dataset ', RowPartFn.Text);
  log.outfile('Column community saved as dataset ', ColPartFn.Text);

finally
  if Assigned(log) then log.browse;
  FreeTwoModeLouvainResults(results);
  data.Free;
  log.Free;
  rowpart.Free;
  colpart.Free;
end;
end;

end.
