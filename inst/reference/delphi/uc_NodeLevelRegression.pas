unit uc_NodeLevelRegression;
interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons, Vcl.ComCtrls,
  generics.collections, math,
  UFn, ufnvcl, ucommon, ustring, utlogfile, udialogs, utsmatds, utsmat3ds,
  utimatds, utnodelist, Vcl.Grids, Vcl.ValEdit,
  utsvec, utregression, ug2vectools, umtxvecregression, regress, utivec,
  utunivariate, utparser;
type
  TNodeLevelRegression = class(TForm)
    GroupBox1: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    noperms: TEdit;
    randomseed: TEdit;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    ProgressBar1: TProgressBar;
    GroupBox2: TGroupBox;
    SpeedButton1: TSpeedButton;
    Label1: TLabel;
    depfn: TLabeledEdit;
    dep: TComboBox;
    GroupBox3: TGroupBox;
    Label5: TLabel;
    SpeedButton4: TSpeedButton;
    Label6: TLabel;
    SpeedButton7: TSpeedButton;
    IndepFn: TLabeledEdit;
    IndepBox: TComboBox;
    Button1: TButton;
    GroupBox4: TGroupBox;
    SpeedButton3: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    PredFn: TLabeledEdit;
    Fitfn: TLabeledEdit;
    CoefFn: TLabeledEdit;
    Memo1: TMemo;
    Resfn: TLabeledEdit;
    SpeedButton2: TSpeedButton;
    Tails: TRadioGroup;
    Method: TRadioGroup;
    Indepfile: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure depfnChange(Sender: TObject);
    procedure IndepFnChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton7Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    temp,xvars: tsmatds;
    procedure getxvars;
    procedure setoutfilenames;
    procedure run;
  end;

var
  NodeLevelRegression: TNodeLevelRegression;

implementation
{$R *.dfm}

procedure TNodeLevelRegression.Button1Click(Sender: TObject);
var
  s: string;
begin
  s:= indepfn.text + ' | ' + itemstr(indepbox);
  indepfile.lines.add(s);
end;

procedure tnodelevelregression.setoutfilenames;
var
  prefix: string;
begin
  prefix:= filenameonly(depfn.text) + '-';
  coeffn.text:= prefix + 'coef';
  fitfn.text:= prefix +  'fit';
  predfn.text:= prefix + 'pred';
  resfn.text:= prefix +  'res';
end;

procedure TNodeLevelRegression.depfnChange(Sender: TObject);
var
  i: integer;
begin
  if ucinetfileexists(depfn.Text) then begin
    temp.loadhdr(depfn.text);
    dep.Clear;
    for i:= 1 to temp.nc do
      dep.items.Add(temp.cdvn.labelget(i));
    dep.ItemIndex:= 0;
    setoutfilenames;
    end;
end;

procedure TNodeLevelRegression.FormActivate(Sender: TObject);
begin
  randomseed.Text:= inttostr(random(32767));
end;

procedure TNodeLevelRegression.FormCreate(Sender: TObject);
begin
  temp:= tsmatds.create;
  xvars:= tsmatds.create;
  indepfile.Clear;
end;

procedure TNodeLevelRegression.FormDestroy(Sender: TObject);
begin
  temp.free;
  xvars.free;
end;

procedure TNodeLevelRegression.IndepFnChange(Sender: TObject);
var
  i: integer;
begin
  if ucinetfileexists(indepfn.Text) then begin
    temp.loadhdr(indepfn.text);
    indepbox.Clear;
    for i:= 1 to temp.cdvn.n do
      indepbox.Items.Add(temp.cdvn.labelget(i));
    indepbox.ItemIndex:= 0;
    end;
end;

procedure TNodeLevelRegression.OKBtnClick(Sender: TObject);
var
  i,j: Integer;
  dup: array of boolean;
begin
  setlength(dup,indepfile.lines.count);
  for i := 0 to indepfile.Lines.count-1 do
    if trim(indepfile.Lines[i]) = '' then
      indepfile.Lines.Delete(i);
  for i:= 1 to indepfile.lines.Count-1 do
    for j:= 0 to i-1 do
      if indepfile.lines[j] = indepfile.Lines[i]
        then dup[j]:= true;
  for i:= indepfile.lines.count-1 downto 0 do
    if dup[i] then indepfile.Lines.Delete(i);
  if indepfile.lines.count = 0
    then showmessage('No independent variables have been specified')
    else run;
end;

procedure tnodelevelregression.getxvars;
var
  k,nrow,ncol: integer;
  uni: tsimpleuni;

  procedure loadone(id:integer);
  var
    i,j: integer;
    fn,cn: string;
  begin
    getpair(fn,cn,indepfile.lines[id],['|']);
    fn:= trim(fn);
    cn:= trim(cn);
    temp.load(fn);
    j:= temp.findcol(cn);
    xvars.cdvn.sput(id+1,cn);
    if id = 0
      then begin 
        nrow:= temp.nr;
        xvars.allocate(nrow,ncol,1,true,true);
        end
      else if temp.nr <> nrow
        then raise exception.create('All independent variables must have the same number of observations.');
    uni.clear;
    for i:= 1 to nrow do begin
      xvars.cell[i,id+1]:= temp.cell[i,j];
      uni.addcase(temp.cell[i,j]);
      end;
    if samevalue(uni.sd,0)
      then raise exception.Create('Variable '+cn+' has no variance.');
  end;

begin try
  uni:= tsimpleuni.create;
  ncol:= indepfile.lines.count;
  for k:= 0 to indepfile.lines.count - 1 do
    loadone(k);
  finally
  uni.Free;
  end;
end;

procedure TNodeLevelRegression.run;
Var
  m,i,j,nperm,d: integer;
  ymat,cmat: tsmatds;
  xfn,s: string;
  reg: tregression;
  overall: tsmatds;
  dsl: tivec;
  yperm,onetailed: boolean;
  log: tlogfile;

  procedure getresid;
  var
    i,j,ii: integer;
    res,pred: tsmatds;
  begin
    res:= tsmatds.create;
    pred:= tsmatds.create;
    res.allocateifneeded(xvars.nr,1,true,true,bna);
    pred.allocateifneeded(xvars.nr,1,true,true,bna);
    for i:= 1 to reg.ncase do begin
      ii:= dsl.cell[i];
      res.cell[ii,1]:= reg.resid[i-1];
      pred.cell[ii,1]:= reg.yhat[i-1];
    end;
    res.rdvn.copy(xvars.rdvn);
    res.cdvn.sput(1,'Residuals');
    pred.rdvn.copy(xvars.rdvn);
    pred.cdvn.sput(1,'Y-Hat');
    res.save(resfn.Text);
    pred.save(predfn.Text);
    res.Free; pred.Free;
  end;

begin try
  ymat:= tsmatds.create;
  cmat:= tsmatds.create;
  overall:= tsmatds.create;
  dsl:= tivec.create;
  log:= tlogfile.stdcreate('Node level regression',copyright);
  log.putstr('Method:',itemstr(method));
  log.putstr('# of permutations:',noperms.text);
  log.putstr('Random seed:',randomseed.text);
  log.putstr('Dependent variable:',depfn.text + ' | ' + itemstr(dep));
  log.putfn('Predicted values:',predfn.text);
  log.putfn('Residual values:',resfn.text);
  log.putfn('Model fit stats:',fitfn.text);
  log.putfn('Model coefficients:',coeffn.text);
  
  yperm:= method.ItemIndex = 1;
  onetailed:= tails.itemindex = 0;
  getxvars;
  reg:= tregression.create(regsolvesvd);
  ymat.load(depfn.text);
  d:= dep.itemindex + 1; 
  if (ymat.nr <> xvars.nr) {or (ymat.nm <> xvars.nm)}
    then raise exception.create('ERROR: matrices must be the same size.');
  if yperm
    then cmat.cdvn.fillrange(['Coef','Beta','SE','T','c.Sig','p.sig'])
    else cmat.cdvn.fillrange(['Coef','Beta','SE','T','c.Sig']);
  cmat.allocate(xvars.nc+1,cmat.cdvn.n,xvars.nm,true,true);
  cmat.rdvn.add('Intercept');
  for j:= 1 to xvars.nc do
    cmat.rdvn.add(xvars.cdvn.labelget(j));
  reg.setcapacities(xvars.nr,xvars.nc);
  case onetailed of
    true:  log.putstr('p-values are 1-tailed');
    false: log.putstr('p-values are 2-tailed');
    end;
  ymat.load(depfn.text);
  dsl.allocate(xvars.nr,false,false);
  for i:= 1 to xvars.nr do
    if reg.addcase(ymat[i,d],xvars.cell[i],1,xvars.nc,0)
      then dsl.iappend(i);
  try
    reg.calc(true);
  except
    showmessage('Problem computing observed regression');
  end;
  overall.rdvn.fillwith('Nobs|R-Square|Adj R-square|'+reg.fstr+'|Sig (classical)|Sig (perm)');
  overall.cdvn.fillwith('Value');
  overall.allocate(overall.rdvn.n,xvars.nm,1,true,false);
  log.lf();
  for j:= 0 to reg.nvar-1 do begin
    cmat.cell[j+1,1]:= reg.b[j];
    cmat.cell[j+1,2]:= reg.beta[j];
    cmat.cell[j+1,3]:= reg.bse[j];
    cmat.cell[j+1,4]:= reg.t[j];
    if onetailed
      then cmat.cell[j+1,5]:= reg.p[j]/2
      else cmat.cell[j+1,5]:= reg.p[j];
    end;
  getresid;
  nperm:= strtointdef(noperms.text,10000);
  overall.nr:= 5;
  if yperm then begin
    reg.getypermsig(onetailed,nperm,randseed);
    overall.nr:= 6;
    overall[6,1]:= reg.permfprob;
    for j:= 0 to reg.nvar-1 do
      cmat.cell[j+1,6]:= reg.permp[j];
    end;
  overall[1,1]:= reg.ncase;
  overall[2,1]:= reg.rsqr;
  overall[3,1]:= reg.adjrsqr;
  overall[4,1]:= reg.fstat;
  overall[5,1]:= reg.fprob;
  overall.title:= 'Overall Regression Fit Statistics' ;
  log.lf;
  overall.borders:= false;
  overall.displayasmatrix(log.stream,0,-5);
  (*
  log.putstr('Y mean and sd' + floattostr(reg.uy.mean) + ' ' + floattostr(reg.uy.sd));
  for j:= 0 to reg.nvar do begin
    log.putstr(cmat.rdvn.cell[j+1] + ' mean and sd' + floattostr(reg.uy.mean) + ' ' + floattostr(reg.uy.sd));
  end;
  *)
  cmat.title:= 'Regression coefficients - predicting ' + itemstr(dep);
  cmat.mdvn.sput(1,itemstr(dep));
  cmat.save(coeffn.text);
  cmat.displayasmatrix(log.stream);
  log.writeln('c.Sig is classical significance test. p.Sig is permutation test');
  log.browse();
  finally
  log.free;
  ymat.free;
  cmat.free;
  reg.Free;
  dsl.Free;
  end;
end;

procedure TNodeLevelRegression.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(depfn);
end;

procedure TNodeLevelRegression.SpeedButton2Click(Sender: TObject);
begin
  stdpicksavefile(resfn);
end;

procedure TNodeLevelRegression.SpeedButton3Click(Sender: TObject);
begin
  stdpicksavefile(predfn);
end;

procedure TNodeLevelRegression.SpeedButton4Click(Sender: TObject);
begin
  stdpickopenfile(indepfn);
end;

procedure TNodeLevelRegression.SpeedButton5Click(Sender: TObject);
begin
  stdpicksavefile(coeffn);
end;

procedure TNodeLevelRegression.SpeedButton6Click(Sender: TObject);
begin
  stdpicksavefile(fitfn);
end;

procedure TNodeLevelRegression.SpeedButton7Click(Sender: TObject);
begin
  indepfile.clear;
end;

end.
