unit uc_AffiliationsDlg;
interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, math,
  system.threading, system.syncobjs, 
  ucommon, ugeneral, umath, utsmatds, utsmat, udialogs, utlogfile, ucan, umatrixtools,
  umsg, ug2display, utevec, ug2simdis, ustring, ufn, usdsm;

type
  TAffiliationsDlg = class(TForm)
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    GroupBox1: TGroupBox;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    Method: TRadioGroup;
    Mode: TRadioGroup;
    InputFn: TLabeledEdit;
    OutputFn: TLabeledEdit;
    Normalization: TRadioGroup;
    RecodeMissings: TCheckBox;
    AlphaEdit: TLabeledEdit;
    SDSMModel: TRadioGroup;
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure ModeClick(Sender: TObject);
    procedure InputFnChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure MethodClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure run(Sender: TObject);
    procedure setoutputfn;
  end;

var
  AffiliationsDlg: TAffiliationsDlg;

implementation

{$R *.dfm}

procedure TAffiliationsDlg.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(tedit(inputfn));
end;

procedure TAffiliationsDlg.SpeedButton2Click(Sender: TObject);
begin
  stdpicksavefile(tedit(outputfn));
end;

function countmissingandrecode(d:tsmat; newvalue:single): integer;
var
  i,j: integer;
begin
  result:= 0;
  for i:= 1 to d.nr do for j:= 1 to d.nc do
    if d.cell[i,j] >= na then begin
      d.cell[i,j]:= newvalue;
      inc(result);
      end;
end;
{---------------------------------------------------------------------------}
procedure TAffiliationsDlg.run(Sender: TObject);
{main routine}
var
  d,r: tsmatds;
  log: tlogfile;
  nmiss, k,i,j,norm: integer;
  sf: simdisfunc;
  recmiss,oppnorm: boolean;
  z: extended;
label
  cleanup;

(*  procedure runrows(k:integer);
  var
    i,j: integer;
  begin
    if recmiss then begin
      nmiss:= countmissingandrecode(d,0);
      if nmiss > 0 then log.put(inttostr(nmiss)+' missing values recoded to zeros.'); log.lf();
      end;
    if oppnorm then d.normcols;
    r.zerofill(true);
    TParallel.For(1, d.nr, procedure (i: Integer)
    var
      j: integer;
      z: extended;
    begin
      for j:= 1 to i do begin
        sf(d.cell[i],d.cell[j],z,d.nc);
        r.cell[i][j]:= z;
        end;
    end);
    for i:= 1 to d.nr do
      for j:= 1 to i-1 do
        r.cell[j][i]:= r.cell[i][j];
    if cant(r.savedat(outputfn.text))
      then raise exception.Create('Unable to save data in '+outputfn.text);
  end;    *)

  procedure runrows(k:integer);
  var
    i,j: integer;
    z: extended;
  begin
    if recmiss then begin
      nmiss:= countmissingandrecode(d,0);
      if nmiss > 0 then log.put(inttostr(nmiss)+' missing values recoded to zeros.'); log.lf();
      end;
    if oppnorm then d.normcols;
    r.zerofill(true);
    for i:= 1 to d.nr do
      for j:= 1 to i do begin
        sf(d.cell[i],d.cell[j],z,d.nc);
        r.cell[i,j]:= z;
        r.cell[j,i]:= z;
        end;
  end;

  procedure runbackbonesdsm(k:integer);
  const
    defaultalpha = 0.05;
  var
    sdsmres: TSDSMResults;
    sdsmmode: TSDSMMode;
    sdsmnull: TSDSMModel;
    i,j: integer;
    alpha: double;
    alphastr: string;
  begin
    {SDSM treats missings as zeros internally; oppnorm does not apply.}
    if mode.itemindex = 0 then sdsmmode:= smRows else sdsmmode:= smCols;
    if SDSMModel.itemindex = 1 then sdsmnull:= smBiCM else sdsmnull:= smLogit;
    alphastr:= trim(alphaedit.text);
    if alphastr = '' then alpha:= defaultalpha
    else begin
      alpha:= strtofloatdef(alphastr, -1);
      if (alpha <= 0) or (alpha >= 1) then begin
        log.put('Alpha "'+alphastr+'" out of range (0,1); using default '+
          floattostrf(defaultalpha, ffFixed, 10, 4)+'.');
        alpha:= defaultalpha;
      end;
    end;
    log.putfloat('Alpha (one-tailed):', alpha, 0, 4);
    sdsmres.Backbone:= nil;
    try
      SDSMBackbone(d, sdsmmode, sdsmnull, alpha, sdsmres);
      r.zerofill(true);
      for i:= 1 to sdsmres.NumNodes do
        for j:= 1 to sdsmres.NumNodes do
          r.cell[i,j]:= sdsmres.Backbone.cell[i,j];
      WriteSDSMResults(log, sdsmres);
    finally
      FreeSDSMResults(sdsmres);
    end;
  end;

  procedure runcols(k:integer);
  begin
    if recmiss then begin
      nmiss:= countmissingandrecode(d,0);
      if nmiss > 0 then log.put(inttostr(nmiss)+' missing values recoded to zeros.'); log.lf();
      end;
    if oppnorm then d.normrows;
    r.zerofill(true);
    TParallel.For(1, d.nc, procedure (i: Integer)
    var
      j: integer;
      z: extended;
      x,y: arrayofsingle;
    begin
      setlength(x,d.nr+1);
      setlength(y,d.nr+1);
      d.copycoltoarrayofsingle(x,i);
      for j:= 1 to i do begin
        d.copycoltoarrayofsingle(y,j);
        sf(x,y,z,d.nr);
        r.cell[i][j]:= z; r.cell[j][i]:= z;
        end;
      x:= nil; y:= nil;
      end);
  end;

begin
try
  errorcode:= 0;
  {create matrix objects}
  d:= tsmatds.create;
  r:= tsmatds.create;
  log:= tlogfile.stdcreate('Affiliations',copyright);
  log.putfn('Input dataset',inputfn.text);
  log.putstr('Dimension/Mode',mode.items[mode.itemindex]);
  log.putstr('Opposite-Mode normalization:',itemstr(normalization));
  log.putstr('Recode missings to zeros',bstr(recodemissings.Checked));
  log.putstr('Method',itemstr(method));
  log.putfn('Output dataset',outputfn.text);
  log.lf;

  case method.itemindex of
      0: sf:= sscp;
      1: sf:= sumcrossmin;
      2: sf:= covariance;
      3: sf:= correlation;
      4: sf:= matches;
      5: sf:= posmatches;
      6: sf:= identity;
      7: sf:= bonacich72;
      8: sf:= maxcrossmin;
      9: sf:= sscpmin;
      10: sf:= sumsqrdiff;
      11: sf:= cosine;
      12: sf:= nil; {Backbone (SDSM) — handled separately below}
      else begin
        showmessage('Not yet implemented.');
        modalresult:= mrnone;
        goto cleanup;
        end;
  end;
  norm:= normalization.ItemIndex;
  recmiss:= recodemissings.checked;
  oppnorm:= normalization.itemindex = 1;

  {read header file}
  if cant(d.loadhdr(inputfn.text)) then goto cleanup;
  {make output dataset have same number of matrices as input dataset}
  case mode.itemindex of
    0: begin 
         r.allocate(d.nr,d.nr,d.nm,true,true);
         r.rdvn.copy(d.rdvn); r.cdvn.copy(d.rdvn);
         end;
    1: begin 
         r.allocate(d.nc,d.nc,d.nm,true,true);
         r.rdvn.copy(d.cdvn); r.cdvn.copy(d.cdvn);
         end;
    end;
  r.mdvn.copy(d.mdvn);
  for k:= 1 to d.nm do begin {for each matrix in datafile}
    d.loaddat(inputfn.text); {load matrix}
    if method.itemindex = 12 then
      runbackbonesdsm(k)
    else case mode.ItemIndex of
      0: runrows(k);
      1: runcols(k);
      end;
    r.savedat(outputfn.text);
    if d.nm > 1 then log.put('Matrix: '+ r.mdvn.labelget(k));
    if r.n <= displaysize
      then r.displayasmatrix(log.stream);
    end;
  {close up output dataset and write header info}
  if cant(r.savehdr(outputfn.text)) then goto cleanup;
  if r.n > displaysize
    then log.put('To view resulting matrix, run DISPLAY on the '+outputfn.text+' dataset.');
  log.lf;
  log.putfn('1-mode matrix saved as',outputfn.text);
  defaultfn:= outputfn.text;
  cleanup:
finally
  log.browse;
  d.free; r.free; log.free;
end;
end;

procedure TAffiliationsDlg.FormActivate(Sender: TObject);
begin
  modeclick(sender);
  methodclick(sender);
end;

procedure TAffiliationsDlg.MethodClick(Sender: TObject);
const
  backbone_index = 12; {Backbone (SDSM) entry in Method radio group}
begin
  {The null-model chooser and alpha box apply only to Backbone (SDSM).}
  SDSMModel.Visible:= method.itemindex = backbone_index;
  AlphaEdit.Visible:= method.itemindex = backbone_index;
end;

procedure TAffiliationsDlg.InputFnChange(Sender: TObject);
begin
  setoutputfn;
end;

procedure TAffiliationsDlg.ModeClick(Sender: TObject);
begin
  setoutputfn;
  case mode.ItemIndex of
    0: normalization.Items[1]:= 'Weight columns inversely by column totals';
    1: normalization.Items[1]:= 'Weight rows inversely by row totals';
    end;
end;

procedure TAffiliationsDlg.OKBtnClick(Sender: TObject);
begin
  run(sender);
end;

procedure taffiliationsdlg.setoutputfn;
begin
  outputfn.Text:= outfile(inputfn.Text,itemstr(mode));
end;

end.
