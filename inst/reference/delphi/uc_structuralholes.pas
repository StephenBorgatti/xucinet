unit uc_structuralholes;
interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, math,
  ucommon, ugeneral, ucan, utlogfile, ufn,
  utsmatds,utsmat,utsvec,utdvec,utivec,ug2display, udialogs, ustring,
  utefficientadjlist, ucentralitymeasures, ComCtrls,utsmat3ds,
  uegonetstructuralholes,uegonetholes, uegonet;

type
  TStructuralHolesDlg = class(TForm)
    Bevel1: TBevel;
    Label9: TLabel;
    Label4: TLabel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    Label1: TLabel;
    SpeedButton3: TSpeedButton;
    Label2: TLabel;
    SpeedButton4: TSpeedButton;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    InputFn: TEdit;
    OutputFn: TEdit;
    OutputRFn: TEdit;
    OutputCFn: TEdit;
    pMethod: TComboBox;
    Label5: TLabel;
    EgoNetDefinition: TRadioGroup;
    ProgressBar1: TProgressBar;
    DiagonalValid: TCheckBox;
    GroupBox1: TGroupBox;
    ConstraintIso: TLabeledEdit;
    ConstraintPendant: TLabeledEdit;
    Effsizegroup: TGroupBox;
    EffectiveIso: TLabeledEdit;
    EffectivePendant: TLabeledEdit;
    SymmetrizeBox: TCheckBox;
    Normalization: TLabeledEdit;
    procedure pMethodChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure InputFnChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    egometh: tegometh;
    procedure runwholenetwork(Sender: TObject);
//    procedure runegonetwork(Sender: TObject);
    procedure runegonetworksingle(Sender: TObject);
    procedure buildadj(adj:tefficientadjlist; z:tsmat);
    procedure identifyegonet(z:tsmat; k:integer);
  end;

var
  StructuralHolesDlg: TStructuralHolesDlg;
  symmetrize:boolean = true;

{---------------------------------------------------------------------------}

implementation
{$R *.dfm}
uses
  ucinet;

function getredundancy(r,p,m:tsmat; effsize,effic,deg:tsvec): integer;
label cleanup;
var
  i,j,q: integer;
  es,rij: double;
begin
  for i:= 1 to p.nr do begin
    for j:= 1 to p.nr do if (i<>j) and (p.cell[i][j] > 0) then begin
      rij:= 0;
      for q:= 1 to p.nr do if (i<>q) and (j<>q) then
        rij:= rij + p.cell[i][q]*m.cell[j][q];
      r.cell[i][j]:= rij;
      end;
    es:= 0;
    for j:= 1 to p.nr do if (i<>j) and (p.cell[i][j] > 0) then
      es:= es + (1.0 - r.cell[i][j]);
    effsize.cell[i]:= es; {effective size of i's network}
    if deg.cell[i] > 0
      then effic.cell[i]:= es/deg.cell[i]; {efficiency}
    end;
  cleanup:
    getredundancy:= error;
end;
{---------------------------------------------------------------------------}
function getconstraint(con,p:tsmat; agcon,hier,ind,deg:tsvec): integer;
label cleanup;
var
  i,j,q: integer;
  sqrsum,isum,numer,relij: double;
begin
  ind.zerofill;
  for i:= 1 to p.nr do begin
    agcon.cell[i]:= 0;
    for j:= 1 to p.nr do if (i<>j) and (p.cell[i][j] > 0) then begin
//      sum:= p.cell[i][j];
      isum:= 0;
      for q:= 1 to p.nr do if (i<>q) and (j<>q) then
        isum:= isum + p.cell[i][q]*p.cell[q][j];
      sqrsum:= sqr(p.cell[i,j]+isum);
      ind.cell[i]:= ind.cell[i] + isum;
      if con.hasval then con.cell[i][j]:= sqrsum;
      agcon.cell[i]:= agcon.cell[i] + sqrsum;
      end;
    end;
  if con.hasval then
    for i:= 1 to p.nr do if (agcon.cell[i] > 0.0) and (deg.cell[i] > 1)
      then begin
        numer:= 0.0;
        for j:= 1 to p.nr do if (i<>j) and (p.cell[i][j] > 0.0) then begin
          relij:= con.cell[i][j]*deg.cell[i]/agcon.cell[i];
          if relij > singletolerance then numer:= numer + relij*ln(relij);
          end;
        hier.cell[i]:= numer/(deg.cell[i]*ln(deg.cell[i]));
        end
      else hier.cell[i]:= bna;
  for i:= 1 to p.nr do if deg.cell[i] = 1 then hier.cell[i]:= 1;
  cleanup:
    getconstraint:= error;
end;
{---------------------------------------------------------------------------}
{---------------------------------------------------------------------------}
Function getpm(z,p,m:tsmat; deg:tsvec; var density:double): integer;
{assumes that z.rdsl has been filled with node index numbers}
label cleanup;
Var
  i,j,q,ii,jj,qq: integer;
  sum,zmax: tdvec;
  si,zi,di,zplus: double;
Begin
  sum:= tdvec.create;
  zmax:= tdvec.create;
  p.zerofill; m.zerofill;
  error:= 1;
  try
  if not sum.allocsize(z.rdsl.n) then goto cleanup;
  if cant(zmax.allocsize(z.rdsl.n)) then goto cleanup;
  density:= 0;
  for i:= 1 to z.rdsl.n do begin
    si:= 0; zi:= 0; di:= 0;
    ii:= z.rdsl.cell[i];
    for j:= 1 to z.rdsl.n do if i<>j then begin
      jj:= z.rdsl.cell[j];
      if symmetrize
        then zplus:= z.cell[ii][jj] + z.cell[jj][ii]
        else zplus:= z.cell[ii,jj];
      si:= si + zplus;
      if zplus > 0 then di:= di + 1.0;
      if zplus > zi then zi:= zplus;
      if (i<>1) and (j<>1)
        then density:= density + z.cell[ii,jj];
      end;
    sum.cell[i]:=  si;
    zmax.cell[i]:= zi;
    deg.cell[i]:= di;
    end;
  if z.rdsl.n > 2
    then density:= density/(sqr(z.rdsl.n)-3*z.rdsl.n+2)
    else density:= 1;
  for i:= 1 to z.rdsl.n do begin
    ii:= z.rdsl.cell[i];
    if sum.cell[i] > 0
      then for q:= 1 to z.rdsl.n do if i<>q then begin
        qq:= z.rdsl.cell[q];
        p.cell[i][q]:= (z.cell[ii][qq]+z.cell[qq][ii])/sum.cell[i];
        end;
    if zmax.cell[i] > 0 then for q:= 1 to z.rdsl.n do if i<>q then begin
      qq:= z.rdsl.cell[q];
      if symmetrize
        then zplus:= z.cell[ii][qq] + z.cell[qq][ii]
        else zplus:= z.cell[ii,qq];
      m.cell[i][q]:= zplus/zmax.cell[i];
      end;
    end;
  error:= 0;
  cleanup:
  finally
    sum.free; zmax.free; getpm:= 0;
    result:= error;
  end;
end;
{---------------------------------------------------------------------------}
procedure TStructuralHolesDlg.runwholenetwork(Sender: TObject);
var
  p,m: tsmat;
  meas: tsmatds;
  con,z,r: tsmatds;
  agcon,deg,effsize,effic,hier,ind: tsvec;
  log: tlogfile;
  n,nvar: integer;
  i,j: integer;
  density: double;
label
  cleanup;
begin
  log:= tlogfile.stdcreate('Structural Holes',copyright);
  log.putfn('Input dataset',inputfn.text);
  log.putstr('Method:','Whole Network');
  log.putstr('Egonet definition:',itemstr(egonetdefinition));
  log.putstr('Diagonal valid?',bstr(diagonalvalid.Checked));
  log.putfn('Output dataset',outputfn.text);
  log.lf;
  try
  z:= tsmatds.create;
  r:= tsmatds.create;
  p:= tsmat.create;
  m:= tsmat.create;
  con:= tsmatds.create;
  meas:= tsmatds.create;
  deg:= tsvec.create;
  agcon:= tsvec.create;
  effsize:= tsvec.create;
  effic:= tsvec.create;
  hier:= tsvec.create;
  ind:= tsvec.create;

  egometh:= whichegometh(itemstr(egonetdefinition),em_union);

  if cant(z.load(inputfn.text)) then goto cleanup;
  assert(z.IsSquare,'Matrix must be square.');
  n:= z.n;
  z.recodena(0);
  if not diagonalvalid.Checked then
    for i:= 1 to n do
      z.cell[i,i]:= 0;
  if cant(p.allocsize(z.nr,z.nr)) then goto cleanup;
  if cant(m.allocsize(z.nr,z.nr)) then goto cleanup;
  if cant(deg.allocsize(p.nr)) then goto cleanup;
  if cant(effsize.allocsize(p.nr)) then goto cleanup;
  if cant(effic.allocsize(p.nr)) then goto cleanup;
  if cant(hier.allocsize(p.nr)) then goto cleanup;
  if cant(ind.allocsize(p.nr)) then goto cleanup;
  if cant(agcon.allocsize(p.nr)) then goto cleanup;
  if not z.rdsl.allocsize(n) then goto cleanup;
  z.rdsl.one2n;

  if userbreak then goto cleanup;

  if cant(getpm(z,p,m,deg,density)) then goto cleanup;
  con.copydef(z); r.copydef(z);
  z.dealloc;
  if userbreak then goto cleanup;

  if cant(r.allocsize(p.nr,p.nr)) then goto cleanup;
  if cant(getredundancy(r,p,m,effsize,effic,deg)) then goto cleanup;
  if userbreak then goto cleanup;
  r.title:= 'Dyadic redundancy';
  if cant(r.save(outputrfn.text)) then goto cleanup;
{  if r.n < displaysize
    then if cant(r.save(outputrfn.text)) then goto cleanup else
    else begin writeln(log.f,'Dyadic redundancy too big to save on disk'); log.lf; end; }
  if r.n < displaysize
    then r.displayasmatrix(log.stream) //,r,pagewidth,-1,2)
    else log.putstr('Display of dyadic redundancy matrix automatically suppressed due to large size.');
  r.dealloc;
  if cant(con.allocsize(p.nr,p.nr)) then goto cleanup;
  if cant(getconstraint(con,p,agcon,hier,ind,deg)) then goto cleanup;
  if userbreak then goto cleanup;
  con.title:= 'Dyadic Constraint';
  if cant(con.save(outputcfn.text)) then goto cleanup;
{  if r.n < displaysize
    then if cant(con.save(outputcfn.text)) then goto cleanup else
    else begin writeln(log.f,'Dyadic constraint too big to save on disk'); log.lf; end; }
  if con.n < displaysize
    then con.displayasmatrix(log.stream) //,con,pagewidth,-1,2)
    else log.putstr('Display of dyadic constraint matrix automatically suppressed due to large size.');
  con.dealloc;
  nvar:= 5;
  if cant(meas.allocsize(p.nr,nvar)) then goto cleanup;
  for i:= 1 to p.nr do begin
    meas.cell[i][1]:= effsize.cell[i];
    meas.cell[i][2]:= effic.cell[i];
    meas.cell[i][3]:= agcon.cell[i];
    meas.cell[i][4]:= hier.cell[i];
    meas.cell[i][5]:= ind.cell[i];
    end;
  meas.rdvn.copy(z.rdvn);
  if cant(meas.cdvn.allocsize(nvar)) then goto cleanup;
  meas.cdvn.sput(1,'EffSize');
  meas.cdvn.sput(2,'Efficiency');
  meas.cdvn.sput(3,'Constraint');
  meas.cdvn.sput(4,'Hierarchy');
  meas.cdvn.sput(5,'Indirects');
  meas.title:= 'Structural Hole Measures';
  if cant(meas.save(outputfn.text)) then goto cleanup;
  meas.displayasmatrix(log.stream);//,meas,pagewidth,8,3);

  log.putfn('Structural hole measures saved as dataset ',outputfn.text);
  if con.n < displaysize then log.putfn('Dyadic redundancy measures saved as dataset ',outputrfn.text);
  if con.n < displaysize then log.putfn('Dyadic constraint measures saved as dataset ',outputcfn.text);
  log.browse;

  cleanup:
  finally
    z.free; r.free; p.free; m.free; con.free; meas.free;
    deg.free; agcon.free; effsize.free; effic.free; ind.free;
    log.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure tstructuralholesdlg.identifyegonet(z:tsmat; k:integer);
Var
  j: integer;
Begin
  z.rdsl.clear;
  z.rdsl.append(k);
  case egometh of
    em_out: for j:= 1 to z.nr do
         if (z.cell[k,j] > 0) then z.rdsl.Append(j);
    em_in: for j:= 1 to z.nr do
         if (z.cell[j,k] > 0) then z.rdsl.Append(j);
    em_union: for j:= 1 to z.nr do
         if (z.cell[k,j] > 0) or (z.cell[j,k] > 0) then z.rdsl.Append(j);
    em_intersect: for j:= 1 to z.nr do
         if (z.cell[k,j] > 0) and (z.cell[j,k] > 0) then z.rdsl.Append(j);
    end;
end;
{---------------------------------------------------------------------------}
procedure TStructuralHolesDlg.InputFnChange(Sender: TObject);
begin
  outputrfn.text:= filenameonly(inputfn.text) + '-DR';
  outputcfn.text:= filenameonly(inputfn.text) + '-DC';
  outputfn.text:= filenameonly(inputfn.text) + '-SH';
end;
{---------------------------------------------------------------------------}
Procedure tstructuralholesdlg.buildadj(adj:tefficientadjlist; z:tsmat);
var
  i,j,ii,jj: integer;
begin
  adj.clear;
  adj.nr:= z.rdsl.n; adj.nc:= z.rdsl.n;
  adj.allocsize(adj.nr,adj.nc);
  for i:= 1 to z.rdsl.n do begin
    ii:= z.rdsl.cell[i];
    for j:= 1 to z.rdsl.n do begin
      jj:= z.rdsl.cell[j];
      if (z.cell[ii,jj] > 0) and (z.cell[ii,jj] < na)
        then adj.addarc(i,j);
    end;
  end;
end;
{---------------------------------------------------------------------------}
procedure TStructuralHolesDlg.runegonetworksingle(Sender: TObject);
var
  meas,dycon,dyred,net,egonet,temp: tsmatds;
  log: tlogfile;
  n,nvar: integer;
  i,k,j,jj: integer;
  undefinedvalue: single;
  adj: tefficientadjlist;
  holes: tegonetstructuralholes;
  bet: tsvec;
  cspecial,especial: array[0..1] of single;
  deg: integer;
  norm: single;
label
  cleanup1,cleanup;

  procedure extractegonet;
  var
    i,j,ii,jj: integer;
  begin
    egonet.allocsize(net.rdsl.n,net.rdsl.n);
    egonet.zerofill;
    for i:= 1 to net.rdsl.n do begin
      ii:= net.rdsl[i];
      for j:= 1 to net.rdsl.n do begin
        jj:= net.rdsl[j];
        egonet[i,j]:= net[ii,jj];
        end;
      end;
  end;

  procedure copyback;
  begin
    meas.cell[k][1]:= holes.degree;
    meas.cell[k][2]:= holes.effectivesize;
    meas.cell[k][3]:= holes.efficiency;
    meas.cell[k][4]:= holes.constraint;
    meas.cell[k][5]:= holes.hierarchy;
    meas.cell[k][6]:= bet.cell[1];
      if (holes.constraint > 0) and (holes.constraint < na)
        then meas.cell[k][7]:= ln(holes.constraint)
        else meas.cell[k][7]:= bna;
    meas.cell[k][8]:= holes.indirect;
    meas.cell[k][9]:= holes.density;
    meas.cell[k][10]:= holes.avgdeg;
    meas.cell[k][11]:= holes.numholes;
  end;

begin
  try
  error:= 0;
  log:= tlogfile.stdcreate('Structural Holes',copyright);
  log.putfn('Input dataset',inputfn.text);
  log.putstr('Method:','Ego Network -- connections 2 links beyond ego are ignored');
  log.putstr('Constraint: isolates set to ',constraintiso.text);
  log.putstr('Constraint: pendants set to ',constraintpendant.text);
  log.putstr('Effective size: isolates set to ',effectiveiso.text);
  log.putstr('Effective size: pendants set to ',effectivependant.text);
  log.putstr('Diagonal valid?',bstr(diagonalvalid.Checked));
  log.putstr('Symmetrize (by sum):',bstr(symmetrize));
  log.putstr('Normalization of P:',normalization.text);
  log.putfn('Output dataset',outputfn.text);
  log.lf;
  net:= tsmatds.create;
  egonet:= tsmatds.create;
  dycon:= tsmatds.create;
  dyred:= tsmatds.create;
  meas:= tsmatds.create;
  adj:= tefficientadjlist.create;
  holes:= tegonetstructuralholes.create;
  bet:= tsvec.create;
  temp:= tsmatds.create;
  egometh:= whichegometh(itemstr(egonetdefinition),em_union);
  especial[0]:= strtofloatdef(effectiveiso.text,bna);
  especial[1]:= strtofloatdef(effectivependant.text,bna);
  cspecial[0]:= strtofloatdef(constraintiso.text,bna);
  cspecial[1]:= strtofloatdef(constraintpendant.text,bna);
  holes.customnorm:= strtofloatdef(normalization.Text,bna);

  if cant(net.load(inputfn.text)) then goto cleanup;
  if net.nr <> net.nc
    then raise exception.create('ERROR: File '+inputfn.text+' does not contain a square matrix.');
  net.recodena(0);
  if not diagonalvalid.Checked
    then for i:= 1 to net.n do
      net.cell[i,i]:= 0;
  meas.cdvn.fillrange(['Degree','EffSize','Efficiency','Constraint','Hierarchy','EgoBet','Ln(Constraint)','Indirects','Density','AvgDeg','Open Pairs']);
  nvar:= meas.cdvn.n;
  if cant(bet.alloc(net.n)) then goto cleanup;
  if cant(meas.allocsize(net.n,nvar)) then goto cleanup;
  if cant(dycon.allocsize(net.n,net.n)) then goto cleanup;
  dycon.zerofill;
  if cant(dyred.allocsize(net.n,net.n)) then goto cleanup;
  dyred.zerofill;
  if not net.rdsl.alloc(net.n) then goto cleanup;
  userbreak:= false;
  progressbar1.Min:= 0;
  progressbar1.max:= net.nr;

  for k:= 1 to net.n do begin
    if userbreak then break;
    progressbar1.StepBy(1);
    identifyegonet(net,k);
    extractegonet;
    holes.run(egonet,symmetrize);
{    temp.copydef(net);
    temp.allocate(egonet.n,egonet.n,1,true,true);
    for i:= 1 to n do
      for j:= 1 to n do
        temp[i,j]:= holes.p[i,j];
    temp.save('shp'+inttostr(k));}
    deg:= trunc(holes.degree);
    if holes.degree <= 1 then begin
        holes.effectivesize:= especial[deg];
        holes.constraint:= cspecial[deg];
        end;
    for j:= 1 to holes.n do begin
      jj:= net.rdsl.cell[j];
      dyred[k,jj]:= holes.pm[j];
      dycon[k,jj]:= holes.dc[j];
      end;
    adj.copyfromtsmat(egonet,0,false);
    try
      brandesbetweenness(bet,adj);
    except
      showmessage('ego '+inttostr(k));
    end;
    copyback;
    end;
  meas.rdvn.copy(net.rdvn);
  meas.title:= 'Structural Hole Measures';
  if cant(meas.save(outputfn.text)) then goto cleanup;
  meas.displayasmatrix(log.stream);
//  display(log.f,meas,pagewidth,10,3);
  dyred.rdvn.copy(net.rdvn);
  dycon.cdvn.copy(net.cdvn);
  dyred.title:= 'Dyadic Redundancy';
  dyred.save(outputrfn.Text);
  if dyred.n < displaysize
    then dyred.displayasmatrix(log.stream)
    else log.putstr('Display of dyadic redundancy matrix automatically suppressed due to large size.');
  dycon.rdvn.copy(net.rdvn);
  dycon.cdvn.copy(net.cdvn);
  dycon.title:= 'Dyadic Constraint';
  dycon.save(outputcfn.Text);
  if dycon.n < displaysize
    then dycon.displayasmatrix(log.stream)
    else log.putstr('Display of dyadic constraint matrix automatically suppressed due to large size.');
  log.putfn('Structural hole measures saved as dataset ',outputfn.Text);
  cleanup:
  finally
    log.browse;
    dycon.free; dyred.free; meas.free; holes.destroy; egonet.free;
    net.free; adj.free; bet.free; temp.Free; log.free;
  end;
end;

procedure TStructuralHolesDlg.OKBtnClick(Sender: TObject);
begin
  if not ucinetfileexists(inputfn.Text) then begin
    showmessage('Input dataset not found.');
    modalresult:= mrnone;
    exit;
  end;
  symmetrize:= symmetrizebox.Checked;
  if pmethod.itemindex = 1
    then runegonetworksingle(sender)
    else runwholenetwork(sender);
  close;
end;

procedure TStructuralHolesDlg.pMethodChange(Sender: TObject);
begin
  egonetdefinition.Visible:= pmethod.itemindex = 1;
end;

procedure TStructuralHolesDlg.FormActivate(Sender: TObject);
begin
  egonetdefinition.Visible:= pmethod.itemindex = 1;
  progressbar1.position:= 0;
end;

procedure TStructuralHolesDlg.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if key = #27
    then userbreak:= true;
end;

procedure TStructuralHolesDlg.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(inputfn);
end;

procedure TStructuralHolesDlg.SpeedButton3Click(Sender: TObject);
begin
  stdpicksavefile(outputrfn);
end;

procedure TStructuralHolesDlg.SpeedButton4Click(Sender: TObject);
begin
  stdpicksavefile(outputcfn);
end;

procedure TStructuralHolesDlg.SpeedButton2Click(Sender: TObject);
begin
  stdpicksavefile(outputfn);
end;

end.
