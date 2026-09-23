unit uc_ContinuousCoreness;
{------------------------------------------------------------------------------
  Continuous (multiplicative) core/periphery model of Borgatti & Everett
  (1999): fits a[i,j] ~ c[i]*c[j] by least squares. GUI front end for the
  shared minres engine in utminres — the same engine the CLI contcp routine
  uses. Replaces the deprecated XConcore/CoreDlg pair (G1 smatrix/evector).
------------------------------------------------------------------------------}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls,
  udialogs, ufn, ucommon, ugeneral, ustring, utlogfile,
  utsmat, utsmatds, utimatds, utsvec, utivec, ug2stats,
  utminres, utconcentration;

type
  TContinuousCorenessDlg = class(TForm)
    Group: TGroupBox;
    btnInput: TSpeedButton;
    btnOutput: TSpeedButton;
    btnPartition: TSpeedButton;
    btnConcentration: TSpeedButton;
    btnExpected: TSpeedButton;
    InputFn: TLabeledEdit;
    OutputFn: TLabeledEdit;
    PartitionFn: TLabeledEdit;
    ConcentrationFn: TLabeledEdit;
    ExpectedFn: TLabeledEdit;
    Options: TGroupBox;
    MaxIteration: TLabeledEdit;
    chkDiagValid: TCheckBox;
    chkPosOnly: TCheckBox;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    procedure btnInputClick(Sender: TObject);
    procedure btnOutputClick(Sender: TObject);
    procedure btnPartitionClick(Sender: TObject);
    procedure btnConcentrationClick(Sender: TObject);
    procedure btnExpectedClick(Sender: TObject);
    procedure InputFnChange(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
  public
    procedure run;
  end;

var
  ContinuousCorenessDlg: TContinuousCorenessDlg;

implementation

{$R *.dfm}

procedure TContinuousCorenessDlg.btnInputClick(Sender: TObject);
begin
  stdpickopenfile(InputFn);
end;

procedure TContinuousCorenessDlg.btnOutputClick(Sender: TObject);
begin
  stdpicksavefile(OutputFn);
end;

procedure TContinuousCorenessDlg.btnPartitionClick(Sender: TObject);
begin
  stdpicksavefile(PartitionFn);
end;

procedure TContinuousCorenessDlg.btnConcentrationClick(Sender: TObject);
begin
  stdpicksavefile(ConcentrationFn);
end;

procedure TContinuousCorenessDlg.btnExpectedClick(Sender: TObject);
begin
  stdpicksavefile(ExpectedFn);
end;

procedure TContinuousCorenessDlg.InputFnChange(Sender: TObject);
begin
  OutputFn.Text := filenameonly(InputFn.Text) + '-Coreness';
  PartitionFn.Text := filenameonly(InputFn.Text) + '-CorenessPart';
  ConcentrationFn.Text := filenameonly(InputFn.Text) + '-Concentration';
  ExpectedFn.Text := filenameonly(InputFn.Text) + '-Expected';
end;

procedure TContinuousCorenessDlg.OKBtnClick(Sender: TObject);
begin
  run;
end;

procedure TContinuousCorenessDlg.run;
label cleanup;
var
  log: tlogfile;
  x,cmat,stats,conc,expected: tsmatds;
  pmat: timatds;
  mr: tminres;
  c: tsvec;
  dsl: tivec;
  n,i,j,numcore: integer;
  gini,hetero,maxconc: double;
  hasmiss: boolean;
begin
  x:= tsmatds.create; cmat:= tsmatds.create; stats:= tsmatds.create;
  conc:= tsmatds.create; expected:= tsmatds.create; pmat:= timatds.create;
  mr:= tminres.create; c:= tsvec.create; dsl:= tivec.create;
  log:= tlogfile.stdcreate('CONTINUOUS CORENESS MODEL',copyright);
  try
    log.putfn('Input dataset:', InputFn.Text);
    log.putstr('Algorithm:','Minres (SVD)');
    log.putstr('Diagonal values valid:', bstr(chkDiagValid.Checked));
    log.lf;

    if not x.loadhdr(InputFn.Text) then begin
      log.put('ERROR: unable to open ' + InputFn.Text);
      goto cleanup;
      end;
    if x.nr <> x.nc then begin
      log.put('ERROR: ' + InputFn.Text + ' does not contain a square matrix.');
      goto cleanup;
      end;
    if not x.loaddat then goto cleanup;
    n:= x.nr;
    if x.nm > 1 then begin
      log.put('Note: dataset has ' + inttostr(x.nm) +
              ' relations; only the first is analyzed.');
      log.lf;
      end;

    hasmiss:= false;
    for i:= 1 to n do
      for j:= 1 to n do
        if x.isna(i,j) then hasmiss:= true;
    if hasmiss then begin
      log.put('Warning: data matrix contains missing values.');
      log.put('These have been recoded to zero.');
      log.lf;
      x.recodena(0,true);
      end;

    {estimate the model with the shared minres engine (same one the CLI contcp uses)}
    mr.maxit:= strtointdef(MaxIteration.Text,100);
    mr.diagvalid:= chkDiagValid.Checked;
    mr.solve(x);
    mr.getcoreness(c,chkPosOnly.Checked);
    if mr.converged
      then log.put('Minres concluded in ' + inttostr(mr.iterations) + ' iterations.')
      else log.put('Warning: minres did not converge in ' + inttostr(mr.iterations) + ' iterations.');
    log.lf;

    cmat.allocate(n,1,1,true,false);
    cmat.rdvn.copy(x.rdvn);
    cmat.cdvn.allocate(1,true);
    cmat.cdvn.sput(1,'Coreness');
    cmat.copyvec2col(c,1);
    cmat.title:= 'Multiplicative Coreness';
    cmat.displayasmatrix(log.stream);
    cmat.save(OutputFn.Text);

    getcolumnstats(stats,cmat,true);
    stats.displayasmatrix(log.stream);

    log.lf;
    log.putstr('Correlation between data and expected values:', fstr(mr.fit,0,3));

    getcorenessconcentration(gini,hetero,conc,x,c,dsl);
    if gini < na then begin
      log.putstr('Gini coefficient:', fstr(gini,0,3));
      log.putstr('Composite "gini-based core/peripheriness":', fstr(gini*mr.fit,0,3));
      end;
    if hetero < na then
      log.putstr('Heterogeneity:', fstr(hetero,0,3));
    log.lf;

    conc.displayasmatrix(log.stream);
    maxconc:= -bna; numcore:= 1;
    for i:= 1 to conc.nr do
      if (conc.cell[i,3] < na) and (conc.cell[i,3] > maxconc) then begin
        maxconc:= conc.cell[i,3];
        numcore:= i;
        end;
    log.put('Recommended core membership: top ' + inttostr(numcore) +
            ' nodes (concentration = ' + fstr(maxconc,0,3) + ').');
    conc.save(ConcentrationFn.Text);
    log.put('Concentration scores saved as dataset ' + ConcentrationFn.Text);
    log.lf;

    pmat.allocate(n,1,1,true,true);
    for i:= 1 to numcore do pmat.cell[dsl[i],1]:= 1;
    pmat.rdvn.copy(x.rdvn);
    pmat.cdvn.allocate(1,true);
    pmat.cdvn.sput(1,'InCore');
    pmat.title:= 'Core/Periphery partition of ' + filenameonly(InputFn.Text);
    pmat.save(PartitionFn.Text);

    expected.allocate(n,n,1,true,false);
    expected.rdvn.copy(x.rdvn);
    expected.cdvn.copy(x.rdvn);
    for i:= 1 to n do
      for j:= 1 to n do
        expected.cell[i,j]:= mr.loadings.cell[i]*mr.loadings.cell[j];
    expected.title:= 'Expected Values';
    if n <= displaysize then
      expected.displayasmatrix(log.stream);
    expected.save(ExpectedFn.Text);

    log.outfile('Coreness scores saved as dataset ', OutputFn.Text);
    defaultfn:= InputFn.Text;
  cleanup:
    log.browse;
  finally
    x.free; cmat.free; stats.free; conc.free; expected.free; pmat.free;
    mr.free; c.free; dsl.free; log.free;
  end;
end;

end.
