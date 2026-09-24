unit uc_lrqap;
interface
uses
    Forms, Dialogs, Controls, stdctrls, sysutils, Waiting, classes,
    Windows, Messages, Variants, Graphics, Buttons, ExtCtrls, math,
    {QAP2Dlg,} uc_mrqapdlg, UFn, 
    ucommon, ugeneral,ucan,ustring,udupdash,uvector,usmatrix,uematrix,ubmatrix,
    urandom,utlogfile,uparser,usvd,ulude,uufile,uheader,ustats, ug2stats, ug2dsl, umsg,
    utsmat, utsmatds, utstrvec, utsvec, ug2regression, utqapcorr, utivec, utunivariate,
    upermutations, utdvec, urestrictedqap, uc_progresswindow, utsmat3ds,
    ulogisticregressionnr, udialogs, ug2vectools, ulrqap, ufloyd,
    utnodelist,umath, urandomthreadsafe,
  ComCtrls;

type
  tresultsrec = record
    coefs: tsvec;
    stderr: tsvec;
    numit: integer;
    loglik: extended;
    end;
  TLogisticQap = class(TForm)
    Label1: TLabel;
    SpeedButton1: TSpeedButton;
    Label2: TLabel;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    InputInd: TMemo;
    inputdep: TLabeledEdit;
    GroupBox1: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    noperms: TEdit;
    randomseed: TEdit;
    PredFn: TLabeledEdit;
    pMethod: TRadioGroup;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    inputindedit: TEdit;
    Fitfn: TLabeledEdit;
    CoefFn: TLabeledEdit;
    StaticText1: TStaticText;
    datatype: TRadioGroup;
    Label5: TLabel;
    SpeedButton7: TSpeedButton;
    ProgressBar1: TProgressBar;
    Source: TComboBox;
    Label6: TLabel;
    Effect: TComboBox;
    Label7: TLabel;
    AddBtn: TButton;
    attribfn: TLabeledEdit;
    AttribBtn: TSpeedButton;
    AttribSource: TComboBox;
    Label8: TLabel;
    Label9: TLabel;
    AttribEffect: TComboBox;
    AttribAddBtn: TButton;
    UseParallel: TCheckBox;
    UseNormalApprox: TCheckBox;
    pvalues: TRadioGroup;
    procedure OKBtnClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure AttribBtnClick(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
    procedure inputdepChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure SpeedButton7Click(Sender: TObject);
    procedure InputIndChange(Sender: TObject);
    procedure AddBtnClick(Sender: TObject);
    procedure attribfnChange(Sender: TObject);
    procedure AttribAddBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    log: tlogfile;
    maxperm: integer;
    diagok,loadedattributes: boolean;
    xmats: tsmat3ds;
    ymat,history: tsmatds;
    attr: tsmatds;
    procedure att2mat(c:integer; e:string; meth:integer; f:binaryfunction);
    procedure buildaicin(s,e:string);
    procedure buildaicout(s,e:string);
    procedure buildclosure(s,e:string);
    procedure buildcyclicity(s,e:string);
    procedure buildindegreeAttachment(s,e:string);
    procedure buildreciprocity(s,e:string);
    procedure buildmonadic(c:integer; e:string; method:integer);
    procedure buildrecipdist(s,e:string);
    procedure cleanupy;
    procedure loadxmats;
    procedure run;
    procedure setuplogfile;
  end;

var
  LogisticQap: TLogisticQap;

implementation

{$R *.dfm}

procedure TLogisticQap.FormActivate(Sender: TObject);
begin
  inputdepChange(sender);
//  randomize;
  randseed:= randomrange(1,32000);
  randomseed.Text:= inttostr(randseed);
  progressbar1.Position:= 0;
end;

procedure TLogisticQap.FormCreate(Sender: TObject);
begin
  xmats:= tsmat3ds.create;
  attr:= tsmatds.create;
  loadedattributes:= false;
  diagok:= false;
end;

procedure TLogisticQap.FormDestroy(Sender: TObject);
begin
  xmats.free;
  attr.free;
end;

procedure TLogisticQap.OKBtnClick(Sender: TObject);
var
  k: integer;
begin
  inputind.Lines.BeginUpdate;
  for k:= inputind.lines.count-1 downto 0 do
    if inputind.lines[k] = ''
      then inputind.Lines.Delete(k);
  inputind.Lines.EndUpdate;
  run;
end;

procedure tLogisticQap.setuplogfile;
var
  i: integer;
begin
  log:= tlogfile.stdcreate('QAP Logistic Regression',copyright);
  log.putfn('Dependent Variable:',inputdep.Text);
  log.putstr('Independent Variables:',inputind.Lines[0]);
  for i:= 1 to inputind.Lines.Count-1 do
    log.putstr('',inputind.Lines[i]);
  log.putstr('# of permutations:',noperms.Text);
  log.putstr('Random seed:',randomseed.text);
  log.putstr('Statistics to track:',itemstr(pmethod));
  log.putstr('P-values:',itemstr(pvalues));
  log.putstr('Data type:',itemstr(datatype));
//  log.putstr('Partition variable (if any):',partitionfn.text);
  log.putfn('Predicted values:',predfn.text);
  log.putfn('Model fit stats:',fitfn.text);
  log.putfn('Model coefficients:',coeffn.text);
  log.putfn('Permutation history:','history');
  log.lf;
  log.put('Important note: This procedure uses the Y-permutation method.');
  log.lf();
end;

procedure TLogisticQap.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(inputdep);
end;

procedure TLogisticQap.SpeedButton2Click(Sender: TObject);
var i: integer;
begin
  stdpickopenfile(inputindedit,[ofAllowMultiSelect]);
  with udialogs.OpenDatasetDlg do begin
    for i:= 0 to files.count - 1 do
      files[i]:= filenameonly(files[i]);
    inputind.Lines.addstrings(Files);
    end;
end;

procedure TLogisticQap.SpeedButton3Click(Sender: TObject);
begin
  stdpicksavefile(predfn);
end;

procedure TLogisticQap.buildmonadic(c:integer; e:string; method:integer);
var
  y: tsmatds;
  i,j: integer;
begin try
  y:= tsmatds.create;
  y.rdvn.copy(attr.rdvn); y.cdvn.copy(attr.rdvn);
  y.allocate(attr.nr,attr.nr,1,true,true);
  for i:= 1 to attr.nr do
    for j:= 1 to attr.nr do if i<> j then begin
      if attr.isna(i,c)
        then y.cell[i,j]:= bna
        else if method = 1
          then y.cell[i,j]:= attr.cell[i,c]
          else y.cell[i,j]:= attr.cell[j,c];
      end;
  y.save(e);
  finally
    y.free;
  end;
end;

procedure TLogisticQap.AttribAddBtnClick(Sender: TObject);
var
  e: string;
  c: integer;
begin try
  if not loadedattributes then
    attribfnchange(sender);
  if not loadedattributes then
    raise exception.Create('You must load an attribute dataset first.');
  if attribsource.ItemIndex < 0 then
    raise exception.Create('You need to select an attribute.');
  if attribeffect.ItemIndex < 0 then
    raise exception.Create('You need to select an attribute effect.');
  e:= itemstr(attribsource) + ' ' + itemstr(attribeffect);
  c:= attribsource.ItemIndex + 1;
  case attribeffect.ItemIndex of
    0: buildmonadic(c,e,1);
    1: buildmonadic(c,e,2);
    2: att2mat(c,e,attribeffect.ItemIndex,identical);
    3: att2mat(c,e,attribeffect.ItemIndex,fabsdiff);
    4: att2mat(c,e,attribeffect.ItemIndex,fdiff);
    5: att2mat(c,e,attribeffect.ItemIndex,fsqrdiff);
    6: att2mat(c,e,attribeffect.ItemIndex,fsum);
    7: att2mat(c,e,attribeffect.ItemIndex,fprod);
    end;
  inputind.Lines.Add(e);
  finally
  end;
end;

procedure TLogisticQap.AttribBtnClick(Sender: TObject);
begin
  stdpickopenfile(attribfn);
end;

procedure TLogisticQap.attribfnChange(Sender: TObject);
var
  s: string;
  idx: integer;
  i: integer;
begin try
  loadedattributes:= false;
  if ucinetfileexists(attribfn.Text) then begin
    attr.load(attribfn.Text);
    idx:= attribsource.itemindex;
    attribsource.Clear;
    attr.cdvn.copytostrings(attribsource.Items,true,attr.nc);
    if idx < 0
      then attribsource.ItemIndex:= attribsource.Items.Count-1
      else attribsource.ItemIndex:= idx;
    loadedattributes:= true;
    end;
  except
    raise exception.Create('Unable to load the attribute file '+attribfn.text);
  end;
end;

procedure TLogisticQap.SpeedButton5Click(Sender: TObject);
begin
  stdpicksavefile(fitfn);
end;

procedure TLogisticQap.SpeedButton6Click(Sender: TObject);
begin
  stdpicksavefile(coeffn);
end;

procedure TLogisticQap.SpeedButton7Click(Sender: TObject);
begin
  inputind.Lines.Clear;
end;

procedure TLogisticQap.inputdepChange(Sender: TObject);
begin
  predfn.Text:= filenameonly(inputdep.text) + '-pred';
  fitfn.Text:= filenameonly(inputdep.text)  + '-fit';
  coeffn.Text:= filenameonly(inputdep.text) + '-coef';
  inputindchange(sender);
end;

procedure TLogisticQap.InputIndChange(Sender: TObject);
var
  s: string;
  idx: integer;
begin
  idx:= source.itemindex;
  source.Clear;
  source.Items.Add(filenameonly(inputdep.Text));
  for s in inputind.Lines do
    source.Items.Add(filenameonly(s));
  if idx < 0
    then source.ItemIndex:= source.Items.Count-1
    else source.ItemIndex:= idx;
end;

procedure tLogisticQap.loadxmats;
var
  mat: tsmatds;
  i,j,k,m,nmats,n: integer;

  procedure examinedata;
  var
    k,m: integer;
  begin try
    nmats:= 0;
    for k:= 0 to inputind.Lines.Count-1 do begin
      inputind.Lines[k]:= trim(inputind.Lines[k]);
      if inputind.Lines[k] = '' then begin
        inputind.Lines.Delete(k);
        continue;
        end;
      if not mat.loadhdr(inputind.Lines[k]) then begin
        log.stream.WriteLine('Unable to open '+inputind.lines[k]);
        inputind.Lines.Delete(k);
        continue;
        end;
      if mat.n <> n then begin
        log.stream.writeline('Matrix '+inputind.Lines[k]+' not the same size as the previous one.');
        inputind.Lines.Delete(k);
        continue;
        end;
      mat.mdvn.prefix:= filenameonly(inputind.Lines[k]);
      for m:= 1 to mat.nm do begin
        inc(nmats);
        if mat.nm = 1
          then xmats.mdvn.sput(nmats,mat.mdvn.prefix)
          else xmats.mdvn.sput(nmats,mat.mdvn.labelget(m));
        end;
      end;
    finally
    end;
  end;

begin try
  mat:= tsmatds.create;
  n:= ymat.n;
  examinedata;
  xmats.allocsize(n,n,nmats);
  inputind.Lines.BeginUpdate;
  nmats:= 0;
  for k:= 0 to inputind.Lines.Count-1 do begin
    if not mat.loadhdr(inputind.Lines[k])
      then raise exception.Create('Unable to open ' +inputind.Lines[k]);
    for m:= 1 to mat.nm do begin
      mat.loaddat(inputind.Lines[k]);
      inc(nmats);
      for i:= 1 to n do for j:= 1 to n do
        xmats.cell[nmats,i,j]:= mat.cell[i,j];
      end;
    end;
  xmats.nm:= nmats;
  xmats.mdvn.n:= nmats;
  finally
    inputind.Lines.EndUpdate;
    mat.free;
  end;
end;

procedure tlogisticqap.att2mat(c:integer; e:string; meth:integer; f:binaryfunction);
var
  y: tsmatds;
  i,j: integer;
begin try
  y:= tsmatds.create;
  y.rdvn.copy(attr.rdvn); y.cdvn.copy(attr.rdvn);
  y.allocate(attr.nr,attr.nr,1,true,true);
  for i:= 1 to attr.nr do
    for j:= 1 to i do begin
      if attr.isna(j,c) or attr.isna(i,c)
        then y.cell[i,j]:= bna
        else y.cell[i,j]:= f(attr.cell[i,c],attr.cell[j,c]);
      case meth of
        2,3,5: y.cell[j,i]:= y.cell[i,j];
        4: y.cell[j,i]:= -y.cell[i,j];
        end;
      end;
  y.save(e);
  finally
    y.free;
  end;
end;

procedure tlogisticqap.buildreciprocity(s,e:string);
var
  x,y: tsmatds;
  k: integer;
begin try
  x:= tsmatds.create;
  y:= tsmatds.create;
  x.loadhdr(s);
  y.copydef(x);
  y.allocate(x.nr,x.nc,x.nm,true,true);
  for k:= 1 to x.nm do begin
    x.loaddat(s);
    y.copyvaltransposed(x);
    y.savedat(e);
    end;
  y.savehdr(e);
  finally
    x.free; y.free;
  end;
end;

procedure tlogisticqap.buildclosure(s,e:string);
var
  x: tnodelistds;
  y: tsmatds;
  k: integer;
begin try
  x:= tnodelistds.create;
  y:= tsmatds.create;
  x.loadhdr(s);
  y.copydef(x);
  y.allocate(x.nr,x.nc,x.nm,true,true);
  for k:= 1 to x.nm do begin
    x.loaddat(s);
    x.getclosure(y);
    y.savedat(e);
    end;
  y.savehdr(e);
  finally
    x.free; y.free;
  end;
end;

procedure tlogisticqap.buildcyclicity(s,e:string);
var
  x: tnodelistds;
  y: tsmatds;
  k: integer;
begin try
  x:= tnodelistds.create;
  y:= tsmatds.create;
  x.loadhdr(s);
  y.copydef(x);
  y.allocate(x.nr,x.nc,x.nm,true,true);
  for k:= 1 to x.nm do begin
    x.loaddat(s);
    x.getcyclicity(y);
    y.savedat(e);
    end;
  y.savehdr(e);
  finally
    x.free; y.free;
  end;
end;

procedure tlogisticqap.buildindegreeattachment(s,e:string);
var
  x: tsmatds;
  k,i,j: integer;
  d: double;
begin try
  x:= tsmatds.create;
  x.loadhdr(s);
  for k:= 1 to x.nm do begin
    x.loaddat(s);
    for j:= 1 to x.nc do begin
      d:= 0;
      for i:= 1 to x.nr do if (i<>j) and (x.cell[i,j] < na) then
        d:= d + x.cell[i,j];
      for i:= 1 to x.nr do if (i<>j) then
        x.cell[i,j]:= d;
      end;
    x.savedat(e);
    end;
  x.savehdr(e);
  finally
    x.free;
  end;
end;

procedure tlogisticqap.buildaicout(s,e:string);
//coverage w/respect to outgoing ties.
//if i sees that all of his ties are also j's ties, then i want's to be friends with j
//non-symmetric SE
var
  x,y: tsmatds;
  k,i,j,m: integer;
  d: double;
begin try
  x:= tsmatds.create;
  y:= tsmatds.create;
  x.loadhdr(s);
  y.copydef(x);
  y.allocate(x.nr,x.nr,x.nm,true,false);
  for k:= 1 to x.nm do begin
    x.loaddat(s);
    for i:= 1 to x.nr do begin
      d:= x.getrowsum(i,false);
      for j:= 1 to x.nr do if i<> j then begin
        y.cell[i,j]:= 0;
        for m:= 1 to x.nc do if (i<>m) and (j<>m) then
          if x.cell[i,m] > 0
            then y.cell[i,j]:= y.cell[i,j] + min(x.cell[j,m],x.cell[i,m]);
        if d > 0
          then y.cell[i,j]:= y.cell[i,j]/d
          else y.cell[i,j]:= bna;
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

procedure tlogisticqap.buildaicin(s,e:string);
//coverage w/respect to incoming ties.
//if i sees that all of his ties are also j's ties, then i want's to be friends with j
//non-symmetric SE
var
  x,y: tsmatds;
  k,i,j,m: integer;
  d: double;
begin try
  x:= tsmatds.create;
  y:= tsmatds.create;
  x.loadhdr(s);
  y.copydef(x);
  y.allocate(x.nr,x.nr,x.nm,true,false);
  for k:= 1 to x.nm do begin
    x.loaddat(s);
    x.transposesquarematrix;
    for i:= 1 to x.nr do begin
      d:= x.getrowsum(i,false);
      for j:= 1 to x.nr do if i<> j then begin
        y.cell[i,j]:= 0;
        for m:= 1 to x.nc do if (i<>m) and (j<>m) then
          if x.cell[i,m] > 0
            then y.cell[i,j]:= y.cell[i,j] + min(x.cell[j,m],x.cell[i,m]);
        if d > 0
          then y.cell[i,j]:= y.cell[i,j]/d
          else y.cell[i,j]:= bna;
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

procedure tlogisticqap.buildrecipdist(s,e:string);
//reciprocal of geodesic distance
var
  x: tsmatds;
  k,i,j: integer;
  d: double;
begin try
  x:= tsmatds.create;
  x.loadhdr(s);
  for k:= 1 to x.nm do begin
    x.loaddat(s);
    reciprocalfloyd(x,0);
    x.savedat(e);
    end;
  x.savehdr(e);
  finally
    x.free;
  end;
end;

procedure TLogisticQap.AddBtnClick(Sender: TObject);
var
  s,e: string;
begin try
  if source.ItemIndex < 0 then
    raise exception.Create('Need to select a source variable.');
//  s:= inputind.lines[source.itemindex];
  s:= itemstr(source);
  e:= s + '-' + itemstr(effect);
  case effect.ItemIndex of
    0: buildreciprocity(s,e);
    1: buildclosure(s,e);
    2: buildcyclicity(s,e);
    3: buildindegreeattachment(s,e);
    4: buildaicout(s,e);
    5: buildaicin(s,e);
    6: buildrecipdist(s,e);
    end;
  inputind.Lines.Add(e);
  finally
  end;
end;

procedure tlogisticqap.cleanupy;
var
  i,j: integer;
  cells,ones,top: integer;
  sym: boolean;
begin
  sym:= datatype.ItemIndex = 0;
  ones:= 0; cells:= 0;
  for i:= 1 to ymat.n do begin
    if sym then top:= i else top:= ymat.n;
    for j:= 1 to top do if (i<>j) and ymat.isvalid(i,j) then begin
      inc(cells);
      if (ymat.cell[i,j] > 0) then begin
        ymat.cell[i,j]:= 1;
        inc(ones);
        end;
      end;
    end;
  if (ones = 0) or (ones = cells) then
    raise exception.Create('Dependent variable is a constant.');
end;

procedure tLogisticQap.run;
var
  ftab,ctab,rmat,cov: tsmatds;
  i: integer;
  seeds: arrayofinteger;
  parallel,hasmissing,usenormal,onetailed: boolean;
begin try
  // Disable OK while running: progress reporting pumps the message queue
  // (Application.ProcessMessages), so without this a second click would
  // re-enter run while the first is still working.
  okbtn.Enabled:= false;
  ymat:= tsmatds.create;
  rmat:= tsmatds.create;
  ftab:= tsmatds.create;
  ctab:= tsmatds.create;
  cov:= tsmatds.create;
  history:= tsmatds.create;
  setuplogfile;

  ymat.load(inputdep.text);
  if not ymat.is1mode then begin
    log.writeln('LR-QAP is made for square, 1-mode matrices. Your data are not 1-mode.');
    exit;
  end;
  cleanupy;
  loadxmats;
  if not trystrtoint(noperms.Text,maxperm)
    then maxperm:= 1;
  if not trystrtoint(randomseed.Text,randseed)
    then begin
      randomize;
      randomseed.text:= inttostr(randseed);
      end;
  setlength(seeds,maxperm+1);
  for i:= 1 to maxperm do 
    seeds[i]:= randomint(maxint,randseed);
  progressbar1.position:= 0;
  parallel:= useparallel.Checked;
  usenormal:= usenormalapprox.Checked;
  onetailed:= pvalues.ItemIndex = 0;
  log.lf;
  log.putstr('Dependent variable: ',filenameonly(inputdep.text));
  log.lf;
  lrqap(ftab,ctab,rmat,cov,ymat,history,xmats,hasmissing,onetailed,pmethod.itemindex,maxperm,datatype.ItemIndex = 0,randseed,parallel,usenormal,progressbar1);
  ftab.save(fitfn.Text);
  ctab.save(coeffn.Text);
  ftab.displayasmatrix(log.stream);
  if hasmissing
    then log.writeln('NOTE: Your data have missing values. In such cases, you should not trust the overall significance of the model.');
  log.lf;
  log.writeln('The r-squared shown is McFadden''s pseudo r-squared.');
  log.lf(2);
  ctab.displayasmatrix(log.stream);
  history.rdvn.one2n();
  history.save('history');
  rmat.save(predfn.Text);
  cov.title:= 'Variance-Covariance matrix';
  cov.save('lrqap-covariance');

  finally
    okbtn.Enabled:= true;
    log.browse;
    ftab.free; ctab.free; rmat.free; ymat.free; history.free;
    log.free;
  end;

end;

end.
