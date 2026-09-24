unit uc_QaPDekkerRegression;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Buttons, Vcl.ExtCtrls, math,
  udialogs, ufn, ucommon, ugeneral, ustring, umath,
  utsmat, utsmatds, utstrvec, utivec, utdvec, utlogfile,
  utnodelist, ufloyd, utsmat3ds, umrqapdekker,
  urandomthreadsafe, uc_progresswindow;

type
  TQapDeckerRegression = class(TForm)
    Label1: TLabel;
    SpeedButton1: TSpeedButton;
    Label2: TLabel;
    SpeedButton2: TSpeedButton;
    SpeedButton7: TSpeedButton;
    Label5: TLabel;
    InputInd: TMemo;
    inputdep: TLabeledEdit;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    inputindedit: TEdit;
    StaticText1: TStaticText;
    ProgressBar1: TProgressBar;
    GroupBox2: TGroupBox;
    Label6: TLabel;
    Label7: TLabel;
    AttribBtn: TSpeedButton;
    Label8: TLabel;
    Label9: TLabel;
    Source: TComboBox;
    Effect: TComboBox;
    AddBtn: TButton;
    attribfn: TLabeledEdit;
    AttribSource: TComboBox;
    AttribEffect: TComboBox;
    AttribAddBtn: TButton;
    GroupBox3: TGroupBox;
    PartitionBtn: TSpeedButton;
    Label10: TLabel;
    Label11: TLabel;
    PartitionFn: TLabeledEdit;
    noperms: TEdit;
    randomseed: TEdit;
    pMethod: TRadioGroup;
    UseParallel: TCheckBox;
    GroupBox1: TGroupBox;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    dlg_efn: TLabeledEdit;
    dlg_rfn: TLabeledEdit;
    ModelFitFn: TLabeledEdit;
    CoefficientsFn: TLabeledEdit;
    pvalues: TRadioGroup;
    procedure OKBtnClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
    procedure SpeedButton7Click(Sender: TObject);
    procedure PartitionBtnClick(Sender: TObject);
    procedure AttribBtnClick(Sender: TObject);
    procedure inputdepChange(Sender: TObject);
    procedure InputIndChange(Sender: TObject);
    procedure attribfnChange(Sender: TObject);
    procedure AddBtnClick(Sender: TObject);
    procedure AttribAddBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
  public
    log: tlogfile;
    maxperm: integer;
    diagok, loadedattributes: boolean;
    xmats: tsmat3ds;
    ymat: tsmatds;
    attr: tsmatds;
    procedure att2mat(c: integer; e: string; meth: integer; f: binaryfunction);
    procedure buildaicin(s, e: string);
    procedure buildaicout(s, e: string);
    procedure buildclosure(s, e: string);
    procedure buildcyclicity(s, e: string);
    procedure buildindegreeAttachment(s, e: string);
    procedure buildreciprocity(s, e: string);
    procedure buildmonadic(c: integer; e: string; method: integer);
    procedure buildcountindyad(c: integer; e: string; v: single);
    procedure buildrecipdist(s, e: string);
    procedure loadxmats;
    procedure run;
    procedure setuplogfile;
  end;

var
  QapDeckerRegression: TQapDeckerRegression;

implementation

{$R *.dfm}

{ Unit-level state: persists across dialog invocations within one session }
const
  saved_yfn: string = '';
  saved_xfn: string = '';   // IV filenames, one per line
  saved_pfn: string = '';
  saved_noperms: string = '2000';
  saved_pmethod: integer = 1;
  saved_pvalues: integer = 1;
  saved_efn: string = '';
  saved_rfn: string = '';
  saved_fitfn: string = '';
  saved_coeffn: string = '';
  saved_attrfn: string = '';
  saved_parallel: boolean = false;

{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.FormCreate(Sender: TObject);
begin
  xmats := tsmat3ds.create;
  attr := tsmatds.create;
  loadedattributes := false;
  diagok := false;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.FormDestroy(Sender: TObject);
begin
  xmats.free;
  attr.free;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.FormActivate(Sender: TObject);
begin
  // Restore previous session values
  inputind.Lines.Text := saved_xfn;
  inputdep.Text := saved_yfn;  // triggers inputdepChange -> auto-names outputs

  // Overwrite auto-generated output names with saved values (if any)
  if saved_efn <> '' then dlg_efn.Text := saved_efn;
  if saved_rfn <> '' then dlg_rfn.Text := saved_rfn;
  if saved_fitfn <> '' then modelfitfn.Text := saved_fitfn;
  if saved_coeffn <> '' then coefficientsfn.Text := saved_coeffn;

  partitionfn.Text := saved_pfn;
  noperms.Text := saved_noperms;
  pmethod.ItemIndex := saved_pmethod;
  pvalues.ItemIndex := saved_pvalues;
  useparallel.Checked := saved_parallel;
  if saved_attrfn <> '' then attribfn.Text := saved_attrfn;

  // Always generate a fresh random seed
  randseed := randomrange(1, 32000);
  randomseed.Text := inttostr(randseed);
  progressbar1.Position := 0;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.OKBtnClick(Sender: TObject);
var
  k: integer;
begin
  inputind.Lines.BeginUpdate;
  for k := inputind.lines.count - 1 downto 0 do
    if inputind.lines[k] = ''
      then inputind.Lines.Delete(k);
  inputind.Lines.EndUpdate;

  // Save current field values for next invocation
  saved_yfn := inputdep.Text;
  saved_xfn := inputind.Lines.Text;
  saved_pfn := partitionfn.Text;
  saved_noperms := noperms.Text;
  saved_pmethod := pmethod.ItemIndex;
  saved_pvalues := pvalues.ItemIndex;
  saved_efn := dlg_efn.Text;
  saved_rfn := dlg_rfn.Text;
  saved_fitfn := modelfitfn.Text;
  saved_coeffn := coefficientsfn.Text;
  saved_attrfn := attribfn.Text;
  saved_parallel := useparallel.Checked;

  run;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(inputdep);
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.SpeedButton2Click(Sender: TObject);
var
  i: integer;
begin
  stdpickopenfile(inputindedit, [ofAllowMultiSelect]);
  with udialogs.OpenDatasetDlg do begin
    for i := 0 to files.count - 1 do
      files[i] := filenameonly(files[i]);
    inputind.Lines.addstrings(Files);
  end;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.SpeedButton3Click(Sender: TObject);
begin
  stdpicksavefile(dlg_efn);
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.SpeedButton4Click(Sender: TObject);
begin
  stdpicksavefile(dlg_rfn);
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.SpeedButton5Click(Sender: TObject);
begin
  stdpicksavefile(modelfitfn);
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.SpeedButton6Click(Sender: TObject);
begin
  stdpicksavefile(coefficientsfn);
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.SpeedButton7Click(Sender: TObject);
begin
  inputind.Lines.Clear;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.PartitionBtnClick(Sender: TObject);
begin
  stdpickopenfile(partitionfn);
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.AttribBtnClick(Sender: TObject);
begin
  stdpickopenfile(attribfn);
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.inputdepChange(Sender: TObject);
begin
  dlg_efn.Text := filenameonly(inputdep.text) + '-mrpred';
  dlg_rfn.Text := filenameonly(inputdep.text) + '-mrresid';
  modelfitfn.Text := filenameonly(inputdep.text) + '-mrfit';
  coefficientsfn.Text := filenameonly(inputdep.text) + '-mrcoef';
  inputindchange(sender);
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.InputIndChange(Sender: TObject);
var
  s: string;
  idx: integer;
begin
  idx := source.itemindex;
  source.Clear;
  source.Items.Add(filenameonly(inputdep.Text));
  for s in inputind.Lines do
    source.Items.Add(filenameonly(s));
  if idx < 0
    then source.ItemIndex := source.Items.Count - 1
    else source.ItemIndex := idx;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.attribfnChange(Sender: TObject);
var
  idx: integer;
begin
  try
    loadedattributes := false;
    if ucinetfileexists(attribfn.Text) then begin
      attr.load(attribfn.Text);
      idx := attribsource.itemindex;
      attribsource.Clear;
      attr.cdvn.copytostrings(attribsource.Items, true, attr.nc);
      if idx < 0
        then attribsource.ItemIndex := attribsource.Items.Count - 1
        else attribsource.ItemIndex := idx;
      loadedattributes := true;
    end;
  except
    raise exception.Create('Unable to load the attribute file ' + attribfn.text);
  end;
end;
{---------------------------------------------------------------------------}
{ Effect-building methods, ported from uc_lrqap.pas }
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.buildmonadic(c: integer; e: string; method: integer);
var
  y: tsmatds;
  i, j: integer;
begin
  try
    y := tsmatds.create;
    y.rdvn.copy(attr.rdvn);
    y.cdvn.copy(attr.rdvn);
    y.allocate(attr.nr, attr.nr, 1, true, true);
    for i := 1 to attr.nr do
      for j := 1 to attr.nr do if i <> j then begin
        if attr.isna(i, c)
          then y.cell[i, j] := bna
          else if method = 1
            then y.cell[i, j] := attr.cell[i, c]
            else y.cell[i, j] := attr.cell[j, c];
      end;
    y.save(e);
  finally
    y.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.buildcountindyad(c: integer; e: string; v: single);
{Symmetric: M[i,j] = (attr[i,c]=v) + (attr[j,c]=v).}
var
  y: tsmatds;
  i, j, ci, cj: integer;
begin
  try
    y := tsmatds.create;
    y.rdvn.copy(attr.rdvn);
    y.cdvn.copy(attr.rdvn);
    y.allocate(attr.nr, attr.nr, 1, true, true);
    for i := 1 to attr.nr do
      for j := 1 to attr.nr do if i <> j then begin
        if attr.isna(i, c) or attr.isna(j, c)
          then y.cell[i, j] := bna
          else begin
            if attr.cell[i, c] = v then ci := 1 else ci := 0;
            if attr.cell[j, c] = v then cj := 1 else cj := 0;
            y.cell[i, j] := ci + cj;
          end;
      end;
    y.save(e);
  finally
    y.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.att2mat(c: integer; e: string; meth: integer; f: binaryfunction);
var
  y: tsmatds;
  i, j: integer;
begin
  try
    y := tsmatds.create;
    y.rdvn.copy(attr.rdvn);
    y.cdvn.copy(attr.rdvn);
    y.allocate(attr.nr, attr.nr, 1, true, true);
    for i := 1 to attr.nr do
      for j := 1 to i do begin
        if attr.isna(j, c) or attr.isna(i, c)
          then y.cell[i, j] := bna
          else y.cell[i, j] := f(attr.cell[i, c], attr.cell[j, c]);
        case meth of
          2, 3, 5, 6, 7: y.cell[j, i] := y.cell[i, j];
          4: y.cell[j, i] := -y.cell[i, j];
        end;
      end;
    y.save(e);
  finally
    y.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.buildreciprocity(s, e: string);
var
  x, y: tsmatds;
  k: integer;
begin
  try
    x := tsmatds.create;
    y := tsmatds.create;
    x.loadhdr(s);
    y.copydef(x);
    y.allocate(x.nr, x.nc, x.nm, true, true);
    for k := 1 to x.nm do begin
      x.loaddat(s);
      y.copyvaltransposed(x);
      y.savedat(e);
    end;
    y.savehdr(e);
  finally
    x.free;
    y.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.buildclosure(s, e: string);
var
  x: tnodelistds;
  y: tsmatds;
  k: integer;
begin
  try
    x := tnodelistds.create;
    y := tsmatds.create;
    x.loadhdr(s);
    y.copydef(x);
    y.allocate(x.nr, x.nc, x.nm, true, true);
    for k := 1 to x.nm do begin
      x.loaddat(s);
      x.getclosure(y);
      y.savedat(e);
    end;
    y.savehdr(e);
  finally
    x.free;
    y.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.buildcyclicity(s, e: string);
var
  x: tnodelistds;
  y: tsmatds;
  k: integer;
begin
  try
    x := tnodelistds.create;
    y := tsmatds.create;
    x.loadhdr(s);
    y.copydef(x);
    y.allocate(x.nr, x.nc, x.nm, true, true);
    for k := 1 to x.nm do begin
      x.loaddat(s);
      x.getcyclicity(y);
      y.savedat(e);
    end;
    y.savehdr(e);
  finally
    x.free;
    y.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.buildindegreeattachment(s, e: string);
var
  x: tsmatds;
  k, i, j: integer;
  d: double;
begin
  try
    x := tsmatds.create;
    x.loadhdr(s);
    for k := 1 to x.nm do begin
      x.loaddat(s);
      for j := 1 to x.nc do begin
        d := 0;
        for i := 1 to x.nr do if (i <> j) and (x.cell[i, j] < na) then
          d := d + x.cell[i, j];
        for i := 1 to x.nr do if (i <> j) then
          x.cell[i, j] := d;
      end;
      x.savedat(e);
    end;
    x.savehdr(e);
  finally
    x.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.buildaicout(s, e: string);
var
  x, y: tsmatds;
  k, i, j, m: integer;
  d: double;
begin
  try
    x := tsmatds.create;
    y := tsmatds.create;
    x.loadhdr(s);
    y.copydef(x);
    y.allocate(x.nr, x.nr, x.nm, true, false);
    for k := 1 to x.nm do begin
      x.loaddat(s);
      for i := 1 to x.nr do begin
        d := x.getrowsum(i, false);
        for j := 1 to x.nr do if i <> j then begin
          y.cell[i, j] := 0;
          for m := 1 to x.nc do if (i <> m) and (j <> m) then
            if x.cell[i, m] > 0
              then y.cell[i, j] := y.cell[i, j] + min(x.cell[j, m], x.cell[i, m]);
          if d > 0
            then y.cell[i, j] := y.cell[i, j] / d
            else y.cell[i, j] := bna;
        end;
      end;
      y.savedat(e);
    end;
    y.savehdr(e);
  finally
    x.free;
    y.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.buildaicin(s, e: string);
var
  x, y: tsmatds;
  k, i, j, m: integer;
  d: double;
begin
  try
    x := tsmatds.create;
    y := tsmatds.create;
    x.loadhdr(s);
    y.copydef(x);
    y.allocate(x.nr, x.nr, x.nm, true, false);
    for k := 1 to x.nm do begin
      x.loaddat(s);
      x.transposesquarematrix;
      for i := 1 to x.nr do begin
        d := x.getrowsum(i, false);
        for j := 1 to x.nr do if i <> j then begin
          y.cell[i, j] := 0;
          for m := 1 to x.nc do if (i <> m) and (j <> m) then
            if x.cell[i, m] > 0
              then y.cell[i, j] := y.cell[i, j] + min(x.cell[j, m], x.cell[i, m]);
          if d > 0
            then y.cell[i, j] := y.cell[i, j] / d
            else y.cell[i, j] := bna;
        end;
      end;
      y.savedat(e);
    end;
    y.savehdr(e);
  finally
    x.free;
    y.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.buildrecipdist(s, e: string);
var
  x: tsmatds;
  k: integer;
begin
  try
    x := tsmatds.create;
    x.loadhdr(s);
    for k := 1 to x.nm do begin
      x.loaddat(s);
      reciprocalfloyd(x, 0);
      x.savedat(e);
    end;
    x.savehdr(e);
  finally
    x.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.AddBtnClick(Sender: TObject);
var
  s, e: string;
begin
  try
    if source.ItemIndex < 0 then
      raise exception.Create('Need to select a source variable.');
    s := itemstr(source);
    e := s + '-' + itemstr(effect);
    case effect.ItemIndex of
      0: buildreciprocity(s, e);
      1: buildclosure(s, e);
      2: buildcyclicity(s, e);
      3: buildindegreeattachment(s, e);
      4: buildaicout(s, e);
      5: buildaicin(s, e);
      6: buildrecipdist(s, e);
    end;
    inputind.Lines.Add(e);
  finally
  end;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.AttribAddBtnClick(Sender: TObject);
var
  e: string;
  c: integer;
  v: single;
begin
  try
    if not loadedattributes then
      attribfnchange(sender);
    if not loadedattributes then
      raise exception.Create('You must load an attribute dataset first.');
    if attribsource.ItemIndex < 0 then
      raise exception.Create('You need to select an attribute.');
    if attribeffect.ItemIndex < 0 then
      raise exception.Create('You need to select an attribute effect.');
    e := itemstr(attribsource) + ' ' + itemstr(attribeffect);
    c := attribsource.ItemIndex + 1;
    case attribeffect.ItemIndex of
      0: buildmonadic(c, e, 1);
      1: buildmonadic(c, e, 2);
      2: att2mat(c, e, attribeffect.ItemIndex, identical);
      3: att2mat(c, e, attribeffect.ItemIndex, fabsdiff);
      4: att2mat(c, e, attribeffect.ItemIndex, fdiff);
      5: att2mat(c, e, attribeffect.ItemIndex, fsqrdiff);
      6: att2mat(c, e, attribeffect.ItemIndex, fsum);
      7: att2mat(c, e, attribeffect.ItemIndex, fprod);
      8: begin
           if (attr.nr < 1) or attr.isna(1, c) then
             raise exception.Create('Cannot determine target value: first node has missing or no attribute value.');
           v := attr.cell[1, c];
           e := itemstr(attribsource) + '_count_' + floattostr(v);
           buildcountindyad(c, e, v);
         end;
    end;
    inputind.Lines.Add(e);
  finally
  end;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.setuplogfile;
var
  i: integer;
begin
  log := tlogfile.stdcreate('Multiple Regression QAP via Double Dekker Semi-Partialling', copyright);
  log.putfn('Dependent Variable:', inputdep.Text);
  log.putstr('Independent Variables:', inputind.Lines[0]);
  for i := 1 to inputind.Lines.Count - 1 do
    log.putstr('', inputind.Lines[i]);
  log.putstr('# of permutations:', noperms.Text);
  log.putstr('Random seed:', randomseed.text);
  log.putstr('Statistics to track:', itemstr(pmethod));
  log.putstr('P-values:', itemstr(pvalues));
  log.putstr('Partition variable (if any):', partitionfn.text);
  log.putfn('Predicted values:', dlg_efn.text);
  log.putfn('Residual values:', dlg_rfn.text);
  log.putfn('Model fit stats:', modelfitfn.text);
  log.putfn('Model coefficients:', coefficientsfn.text);
  log.lf;
  log.put('This procedure uses the Double-Dekker semi-partialling method.');
  log.lf;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.loadxmats;
var
  mat: tsmatds;
  i, j, k, m, nmats, nn: integer;

  procedure examinedata;
  var
    kk, mm: integer;
  begin
    try
      nmats := 0;
      for kk := 0 to inputind.Lines.Count - 1 do begin
        inputind.Lines[kk] := trim(inputind.Lines[kk]);
        if inputind.Lines[kk] = '' then begin
          inputind.Lines.Delete(kk);
          continue;
        end;
        if not mat.loadhdr(inputind.Lines[kk]) then begin
          log.stream.WriteLine('Unable to open ' + inputind.lines[kk]);
          inputind.Lines.Delete(kk);
          continue;
        end;
        if mat.n <> nn then begin
          log.stream.writeline('Matrix ' + inputind.Lines[kk] + ' not the same size as the previous one.');
          inputind.Lines.Delete(kk);
          continue;
        end;
        mat.mdvn.prefix := filenameonly(inputind.Lines[kk]);
        for mm := 1 to mat.nm do begin
          inc(nmats);
          if mat.nm = 1
            then xmats.mdvn.sput(nmats, mat.mdvn.prefix)
            else xmats.mdvn.sput(nmats, mat.mdvn.labelget(mm));
        end;
      end;
    finally
    end;
  end;

begin
  try
    mat := tsmatds.create;
    nn := ymat.n;
    examinedata;
    xmats.allocsize(nn, nn, nmats);
    inputind.Lines.BeginUpdate;
    nmats := 0;
    for k := 0 to inputind.Lines.Count - 1 do begin
      if not mat.loadhdr(inputind.Lines[k])
        then raise exception.Create('Unable to open ' + inputind.Lines[k]);
      for m := 1 to mat.nm do begin
        mat.loaddat(inputind.Lines[k]);
        inc(nmats);
        for i := 1 to nn do
          for j := 1 to nn do
            xmats.cell[nmats, i, j] := mat.cell[i, j];
      end;
    end;
    xmats.nm := nmats;
    xmats.mdvn.n := nmats;
  finally
    inputind.Lines.EndUpdate;
    mat.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure TQapDeckerRegression.run;
var
  ftab, ctab, predmat, residmat: tsmatds;
  i, j, k: integer;
  // Engine data structures
  eng_xmats: array of tsmat;
  eng_ismissing: tboolmatrix;
  eng_map: tivec;
  eng_ncat: integer;
  eng_cat: array of tivec;
  nn, nxmissing, nymissing: integer;
  parallel_flag, onetailed_flag, hasmissing: boolean;
  tmp: tsmatds;
  list: tstrvec;
  grp: string;
begin
  try
    ymat := tsmatds.create;
    ftab := tsmatds.create;
    ctab := tsmatds.create;
    predmat := tsmatds.create;
    residmat := tsmatds.create;
    eng_map := tivec.create;

    setuplogfile;

    // Load dependent variable
    ymat.load(inputdep.text);
    if not ymat.is1mode then begin
      log.writeln('MRQAP is for square, 1-mode matrices. Your data are not 1-mode.');
      exit;
    end;
    nn := ymat.n;

    // Load independent variables
    loadxmats;

    // Parse parameters
    if not trystrtoint(noperms.Text, maxperm) then maxperm := 1;
    if not trystrtoint(randomseed.Text, randseed) then begin
      randomize;
      randomseed.text := inttostr(randseed);
    end;

    parallel_flag := useparallel.Checked;
    onetailed_flag := pvalues.ItemIndex = 0;

    // Build engine xmats array [1..nx]
    setlength(eng_xmats, xmats.nm + 1);
    for k := 1 to xmats.nm do begin
      eng_xmats[k] := tsmat.create;
      eng_xmats[k].allocate(nn, nn, 1, true, true);
      for i := 1 to nn do
        for j := 1 to nn do
          eng_xmats[k].cell[i, j] := xmats.cell[k, i, j];
    end;

    // Build ismissing array
    setlength(eng_ismissing, nn + 1);
    for i := 1 to nn do
      setlength(eng_ismissing[i], nn + 1);
    nxmissing := 0; nymissing := 0;
    for i := 1 to nn do
      for j := 1 to nn do if (i <> j) then begin
        eng_ismissing[i, j] := false;
        // Check Y
        if ymat.cell[i, j] >= na then begin
          eng_ismissing[i, j] := true;
          inc(nymissing);
        end;
        // Check all X
        for k := 1 to xmats.nm do
          if eng_xmats[k].cell[i, j] >= na then begin
            eng_ismissing[i, j] := true;
            inc(nxmissing);
          end;
      end;

    if (nxmissing > 0) or (nymissing > 0) then begin
      log.stream.writeline(inttostr(nxmissing) + ' values missing among the independent data values.');
      log.stream.writeline(inttostr(nymissing) + ' values missing among the dependent data values.');
    end;

    // Load partition file and build class structure
    eng_ncat := 0;
    if (partitionfn.Text <> '') and ucinetfileexists(partitionfn.Text) then begin
      tmp := tsmatds.create;
      try
        tmp.load(partitionfn.Text);
        // Build map and cat from partition data (first column)
        list := tstrvec.create;
        try
          eng_map.allocsize(nn);
          for i := 1 to nn do begin
            if tmp.nc >= 1
              then grp := floattostr(tmp.cell[i, 1])
              else grp := '1';
            eng_map[i] := list.appendifnewstr(grp);
          end;
          eng_ncat := list.n;
          setlength(eng_cat, eng_ncat + 1);
          for i := 1 to eng_ncat do
            eng_cat[i] := tivec.create;
          for i := 1 to nn do
            eng_cat[eng_map[i]].add(i);
        finally
          list.free;
        end;
      finally
        tmp.free;
      end;
    end else begin
      // No partition: all nodes in one class
      eng_map.allocsize(nn);
      for i := 1 to nn do eng_map[i] := 1;
      eng_ncat := 1;
      setlength(eng_cat, 2);
      eng_cat[1] := tivec.create;
      for i := 1 to nn do eng_cat[1].add(i);
    end;

    // Show progress window
    progresswin.Memo.Clear;
    progresswin.show;
    progresswin.memo.lines.add('Running MRQAP Dekker semi-partialling...');
    application.processmessages;

    // Call the engine
    hasmissing := false;
    mrqapdekker(ftab, ctab, predmat, residmat,
      ymat, eng_xmats, eng_ismissing, eng_map, eng_ncat, eng_cat,
      hasmissing, onetailed_flag, pmethod.itemindex, maxperm,
      randseed, parallel_flag);

    // Set labels on output matrices (only network matrices get ymat labels)
    predmat.copylabels(ymat);
    residmat.copylabels(ymat);

    // Set row labels on coefficient table (column labels already set by engine)
    ctab.rdvn.clear;
    for k := 1 to xmats.nm do
      ctab.rdvn.addstr(filenameonly(inputind.lines[k - 1]));
    ctab.rdvn.addstr('Intercept');

    // Save results
    ftab.save(modelfitfn.Text);
    ctab.save(coefficientsfn.Text);
    predmat.save(dlg_efn.Text);
    residmat.save(dlg_rfn.Text);

    // Display results in log
    ftab.displayasmatrix(log.stream, 12, 5);
    if hasmissing then
      log.writeln('NOTE: Your data have missing values.');
    log.lf(2);
    ctab.displayasmatrix(log.stream, 12, 5);
    log.lf;

    // Collinearity diagnostics (VIF). The engine fills ctab cols 11/12/13
    // from each DSP regression of an IV on the other IVs.
    log.put('COLLINEARITY DIAGNOSTICS');
    log.stream.writeline(format('%-30s %12s %12s %12s',
      ['Variable', 'Collin R-Sqr', 'Tolerance', 'VIF']));
    for k := 1 to xmats.nm do
      log.stream.writeline(format('%-30s %12.3f %12.3f %12.3f',
        [ctab.rdvn.labelget(k), ctab.cell[k, 11], ctab.cell[k, 12], ctab.cell[k, 13]]));
    log.lf;

    progresswin.close;

  finally
    log.browse;
    ftab.free; ctab.free; predmat.free; residmat.free; ymat.free;
    // Free engine xmats
    for k := 1 to length(eng_xmats) - 1 do
      eng_xmats[k].free;
    eng_xmats := nil;
    // Free ismissing
    for i := 1 to length(eng_ismissing) - 1 do
      eng_ismissing[i] := nil;
    eng_ismissing := nil;
    // Free cat arrays
    for k := 1 to eng_ncat do
      eng_cat[k].free;
    eng_cat := nil;
    eng_map.free;
    log.free;
  end;
end;
{---------------------------------------------------------------------------}
end.
