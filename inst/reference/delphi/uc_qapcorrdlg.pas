unit uc_qapcorrdlg;
interface
uses
  math,
  ucommon, ugeneral, Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, urandom, ufn,
  utqapsim, utsmatds, utlogfile, ustring, udialogs, umath, utsmat3ds, ug2display;
type
  Tqapcorrdlg = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    pNumPerm: TLabeledEdit;
    pRandomSeed: TLabeledEdit;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    Memo1: TMemo;
    BrowseBtn: TButton;
    Button2: TButton;
    GroupBox3: TGroupBox;
    pPermStats: TCheckBox;
    Label1: TLabel;
    pResults: TCheckBox;
    pPermStatsFn: TEdit;
    pResultsFn: TEdit;
    Label2: TLabel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    pType: TRadioGroup;
    Parallel: TCheckBox;
    pTails: TRadioGroup;
    procedure OKBtnClick(Sender: TObject);
    procedure BrowseBtnClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure pResultsFnChange(Sender: TObject);
    procedure pPermStatsFnChange(Sender: TObject);
    procedure pPermStatsClick(Sender: TObject);
    procedure pResultsClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    n: integer;
    canclose: boolean;
    procedure run;
    function examinedata(var square,equalsize:boolean; q:tqapsim): boolean;
  end;

var
  qapcorrdlg: Tqapcorrdlg;

implementation
uses
  ucinet;

{$R *.dfm}

function Tqapcorrdlg.examinedata(var square,equalsize:boolean; q:tqapsim): boolean;
label cleanup;
var
  k,i,j,oldnr,oldnc: integer;
  m: tsmatds;
begin
  m:= tsmatds.create;
  ucommon.error:= 0;
  square:= true; equalsize:= true; q.sym:= true; q.hasna:= false; q.binary:= true;
  for k:= 0 to memo1.lines.count-1 do if length(memo1.lines[k]) > 0 then begin
    if not m.load(memo1.Lines[k]) then begin ucommon.error:= 1; goto cleanup; end;
    if not m.issquare
      then begin square:= false; goto cleanup; end;
    if k = 0
      then begin oldnr:= m.nr; oldnc:= m.nc; end
      else if (m.nr <> oldnr) or (m.nc <> oldnc)
        then begin equalsize:= false; goto cleanup; end;
    if (not q.sym) and q.hasna and (not q.binary) then continue; {no need for further checking}
    for i:= 2 to m.nr do for j:= 1 to i-1 do begin
      if m.cell[i,j] >= na then q.hasna:= true;
      if not (feq(m.cell[i,j],0.0) or feq(m.cell[i,j],1.0)) then q.binary:= false;
      if not feq(m.cell[j,i],m.cell[i,j]) then begin
        q.sym:= false;
        if m.cell[j,i] >= na then q.hasna:= true;
        if not (feq(m.cell[j,i],0) or feq(m.cell[j,i],1)) then q.binary:= false;
        end;
      end;
    end;
  cleanup:
    n:= m.n;
    m.free;
    result:= ucommon.error = 0;
end;

procedure Tqapcorrdlg.run;
label cleanup;
var
  mat1,mat2: tsmatds;
  y: tsmat3ds;
  q:  tqapsim;
  k,k2,nlayers: integer;
  log: tlogfile;
  square,equalsize: boolean;
begin
  mat1:= tsmatds.create;
  mat2:= tsmatds.create;
  y:= tsmat3ds.create;
  q:= tqapsim.create;
  log:= tlogfile.stdcreate('QAP Correlation',copyright);
  for k := memo1.lines.count - 1 downto 0 do
    if length(trim(memo1.lines[k])) = 0
      then memo1.lines.delete(k);
  log.putstr('Data Matrices:',memo1.lines[0]);
  for k:= 1 to memo1.Lines.count-1 do
    log.putstr('',memo1.lines[k]);
  log.putstr('# of Permutations:',pnumperm.text);
  log.putstr('Random seed: ',prandomseed.text);
  log.putstr('Method:',itemstr(ptype));
  log.putstr('Tails:',itemstr(ptails));
  log.putstr('Parallel:',bstr(parallel.checked));
  log.lf;
  canclose:= false;
  if not examinedata(square,equalsize,q) then goto cleanup;
  if q.hasna and (ptype.ItemIndex = 0) then begin
    showmessage('Error: Data contain missing values. You must choose "Detailed" analysis type, not "Fast"');
    goto cleanup;
    end;
  if not square then begin
    showmessage('Some of your matrices are not square. The QAP technique demands square matrices.');
    goto cleanup;
    end;
  if not equalsize then begin
    showmessage('Some of your matrices are not the same size as the others. You can only QAP matrices with the same dimensions');
    goto cleanup;
    end;
  q.twotailed:= ptails.itemindex = 1;
  if q.twotailed then nlayers:= 2 else nlayers:= 3;
  if not y.allocsize(memo1.lines.count,memo1.lines.count,nlayers) then
    goto cleanup;
  q.seed:= stri(prandomseed.text);
  q.nperm:= stri(pnumperm.text);
  q.parallel:= parallel.checked;
  for k:= 1 to memo1.lines.count-1 do if memo1.lines[k] <> '' then begin
    if not mat1.load(memo1.lines[k]) then goto cleanup;
    for k2:= 0 to k-1 do if memo1.lines[k2] <> '' then begin
      if not mat2.load(memo1.lines[k2]) then goto cleanup;
      if ptype.itemindex = 0
        then q.runfastpermutations(mat1,mat2,false)
        else q.runpermutations(mat1,mat2);
      q.print(log.stream,memo1.lines[k],memo1.lines[k2]);
      y.cell[1,k+1,k2+1]:= q.results.cell[1,1];
      y.cell[1,k2+1,k+1]:= y.cell[1,k+1,k2+1];
      if q.twotailed then begin
        y.cell[2,k+1,k2+1]:= q.results.cell[1,10]; {p (2-tailed)}
        y.cell[2,k2+1,k+1]:= y.cell[2,k+1,k2+1];
      end else begin
        y.cell[2,k+1,k2+1]:= q.results.cell[1,7];  {p if predict r > 0}
        y.cell[2,k2+1,k+1]:= y.cell[2,k+1,k2+1];
        y.cell[3,k+1,k2+1]:= q.results.cell[1,8];  {p if predict r < 0}
        y.cell[3,k2+1,k+1]:= y.cell[3,k+1,k2+1];
      end;
      end;
    end;
  for k := 1 to memo1.lines.Count do
    y.cell[1,k,k]:= 1;
//  y.title:= 'QAP Statistics';
  if y.rdvn.allocsize(memo1.lines.count) then
    for k := 0 to memo1.lines.count - 1 do
      y.rdvn.sput(k+1,allbutext(extractfilename(memo1.lines[k])));
  y.cdvn.copy(y.rdvn);
  if y.mdvn.allocsize(nlayers) then begin
    y.mdvn.sput(1,'QAP Correlations');
    if q.twotailed then begin
      y.mdvn.sput(2,'P-Values (2-tailed)');
    end else begin
      y.mdvn.sput(2,'P-Values (predict r>0)');
      y.mdvn.sput(3,'P-Values (predict r<0)');
    end;
  end;
//  display3(log.f,y);
  display3(log.stream,y);
  if y.save(presultsfn.Text) then
    log.putstr('QAP statistics saved as datafile ',presultsfn.text);
  log.browse;
  canclose:= true;
  cleanup:
    log.free; y.free; mat1.free;
    mat2.free;
    q.destroy;
end;

procedure Tqapcorrdlg.OKBtnClick(Sender: TObject);
begin
  run;
  if not canclose then modalresult:= mrnone;
end;

procedure Tqapcorrdlg.BrowseBtnClick(Sender: TObject);
var
  i: integer;
  s1,s2: string;
begin
  with udialogs.OpenDatasetDlg do begin
    options:= options + [ofAllowMultiSelect];
    s1:= itemstr(mainform.currentdirectory) + '\';
  if udialogs.opendatasetdlg.execute then begin
    for i:= 0 to files.count - 1 do begin
      s2:= extractfilepath(files[i]);
      if s1 = s2
        then files[i]:= filenameonly(files[i])
        else files[i]:= allbutext(files[i]);
      end;
    memo1.Lines.addstrings(Files);
    end;
  end;
end;

procedure Tqapcorrdlg.Button2Click(Sender: TObject);
begin
  memo1.Lines.clear;
end;

procedure Tqapcorrdlg.SpeedButton1Click(Sender: TObject);
begin
  stdpicksavefile(ppermstatsfn); 
end;

procedure Tqapcorrdlg.SpeedButton2Click(Sender: TObject);
begin
  stdpicksavefile(presultsfn);
end;

procedure Tqapcorrdlg.pResultsFnChange(Sender: TObject);
begin
  if presultsfn.Text <> '' then presults.checked:= true;

end;

procedure Tqapcorrdlg.pPermStatsFnChange(Sender: TObject);
begin
  if ppermstatsfn.Text <> '' then ppermstats.checked:= true;
end;

procedure Tqapcorrdlg.pPermStatsClick(Sender: TObject);
begin
  if ppermstats.checked and (ppermstatsfn.text = '')
    then ppermstatsfn.text:= 'QAP Permutation statistics';
end;

procedure Tqapcorrdlg.pResultsClick(Sender: TObject);
begin
  if presults.checked and (presultsfn.text = '')
    then presultsfn.text:= 'QAP Correlation Results';
end;

procedure Tqapcorrdlg.FormActivate(Sender: TObject);
begin
  randomize;
  prandomseed.text:= inttostr(randomrange(1,32767));
  udialogs.opendatasetdlg.InitialDir:= getcurrentdir;
end;

end.
