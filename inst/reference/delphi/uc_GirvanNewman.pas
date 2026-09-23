unit uc_GirvanNewman;
interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls,
  ucommon, ugeneral, utlogfile, utnodelist, utivec, utsmatds, ug2display, ufn,
  udialogs, utsvec, utimatds, ugirvannewman, ug2textdendrogram, ustring;

type
  TGirvanNewman = class(TForm)
    GroupBox1: TGroupBox;
    SpeedButton1: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton2: TSpeedButton;
    InputFn: TLabeledEdit;
    OutputFn: TLabeledEdit;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    HelpBtn: TBitBtn;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    MaxClus: TEdit;
    Label3: TLabel;
    procedure BitBtn1Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure InputFnChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure run;
  end;

var
  GirvanNewman: TGirvanNewman;

implementation

{$R *.dfm}

procedure TGirvanNewman.InputFnChange(Sender: TObject);
begin
  outputfn.text:= filenameonly(inputfn.text) + '-gn';
end;

procedure TGirvanNewman.run;
var
  log: tlogfile;
  part: timatds;
  data: tnodelistds;
begin try
  log:= tlogfile.stdcreate('Girvan-Newman',copyright);
  log.putfn('Input dataset:',inputfn.text);
  log.putstr('Maximum no. of clusters:',maxclus.text);
  log.putfn('Output dataset:',Outputfn.text);
  log.lf;
  data:= tnodelistds.create;
  part:= timatds.create;
  data.load(inputfn.text);
//  data.displayasmatrix(log.f);
  part.allocsize(data.nr,1); part.nc:= 0;
  part.rdvn.copy(data.rdvn);
  if not data.issymmetric then begin
    data.symmetrize;
    log.put('Data were symmetrized via the maximum method.');
    log.lf;
  end;
  girvannewmanclustering(part,data,stri(maxclus.text,5));
  part.title:= 'Girvan-Newman Partitions';
  part.reversecols;
  if part.nr < 100
    then textdendrogram(log,part);
  part.save(outputfn.text);
  if data.nr < 250
    then part.displayasmatrix(log.stream)
    else log.writeln('Output suppressed. Use Display or matrix editor to view.');
  log.put('Partitions saved as dataset ' + filenameonly(outputfn.text));
  finally
    log.browse;
    log.free; part.free; data.free;
  end;
end;

procedure TGirvanNewman.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(inputfn);
end;

procedure TGirvanNewman.SpeedButton5Click(Sender: TObject);
begin
  stdpicksavefile(outputfn);
end;

procedure TGirvanNewman.BitBtn1Click(Sender: TObject);
begin
  run;
end;

end.
