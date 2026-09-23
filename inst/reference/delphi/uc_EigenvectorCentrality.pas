unit uc_EigenvectorCentrality;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  udialogs, ufn, ug2centralitymeasures, utefficientadjlistds, utsmat3ds, utdvec,
  utnodelist, utivec, utvec, utlogfile, ucommon, ugeneral, ug2display, ustring,
  utsmatds, ComCtrls, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls,
  ug3la, utunivariate, ug2stats, utDisconnectedEigenvector;
type
  TEigenvectorCentrality = class(TForm)
    GroupBox1: TGroupBox;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    InputFn: TLabeledEdit;
    OutputFn: TLabeledEdit;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    Label1: TLabel;
    Normalization: TRadioGroup;
    makepositive: TCheckBox;
    ConvertData: TCheckBox;
    procedure SpeedButton1Click(Sender: TObject);
    procedure InputFnChange(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure run;
  end;

var
  EigenvectorCentrality: TEigenvectorCentrality;

implementation

{$R *.dfm}

procedure TEigenvectorCentrality.InputFnChange(Sender: TObject);
begin
  outputfn.text:= outfile(inputfn.text,'-eig');
end;

procedure TEigenvectorCentrality.OKBtnClick(Sender: TObject);
begin
  if ucinetfileexists(inputfn.Text)
    then run
    else begin
      showmessage('Input file not found.');
      modalresult:= mrnone;
    end;
end;

procedure makeevalstable(t:tsmatds; evals:tdvec; title:string='Positive Eigenvalues');
var
  i,lastpos: integer;
  tot,cum: double;
begin
  tot:= 0; lastpos:= 0;
  for i:= 1 to evals.n do begin
    if evals.cell[i] < 0 then break;
    inc(lastpos);
    tot:= tot + evals.cell[i];
    end;
  t.allocate(lastpos,3,1,true,true);
  t.title:= title;
  t.cdvn.fillwith('Eigenvalue|Pct Variance|Cum Pct');
  cum:= 0;
  for i:= 1 to lastpos do begin
    cum:= cum + evals.cell[i];
    t.cell[i,1]:= evals.cell[i];
    t.cell[i,2]:= 100*evals.cell[i]/tot;
    if i = 1
      then t.cell[i,3]:= t.cell[i,2]
      else t.cell[i,3]:= t.cell[i-1,3] + t.cell[i,2];
    end;
end;

procedure normalize(v:tdvec; method:integer=0);
var
  i: integer;
  tot,cum,maxposs: double;
  u: tunivariate;
begin
  u:= tunivariate.create;
  for i:= 1 to v.n do
    u.addcase(v.cell[i]);
  u.calc;
  maxposs:= sqrt(2)/2;
  case method of
    0: if u.nrm > 0 then
         for i:= 1 to v.n do 
           v.cell[i]:= v.cell[i]/u.nrm;
    1: if u.tot <> 0 then
         for i:= 1 to v.n do 
           v.cell[i]:= v.n*v.cell[i]/u.tot;
    2: for i:= 1 to v.n do 
         v.cell[i]:= v.cell[i]/maxposs;
    3: if u.max <> 0
         then for i:= 1 to v.n do 
           v.cell[i]:= v.cell[i]/u.max;
    4: if u.nrm > 0 then
         for i:= 1 to v.n do
           v.cell[i]:= v.cell[i]*v.n/u.nrm;
    end;
  u.Free;
end;

function getcentralization(v:tdvec): double;
var
  i: integer;
  u: tunivariate;
begin try
  u:= tunivariate.create; 
  for i:= 1 to v.n do
    u.addcase(v.cell[i]);
  result:= 0;
  for i:= 1 to v.n do 
    result:= result + u.max - v[i];
  result:= 100.0*result/((v.n-1.0)*(sqrt(0.5)-sqrt(1.0/(2.0*(v.n-1.0)))));
  finally
    u.free;
  end;
end;

procedure runpositive(v:tdvec);
var
  i: integer;
  u: tunivariate;
begin try
  u:= tunivariate.create; 
  for i:= 1 to v.n do
    u.addcase(v.cell[i]);
  if u.numnegs > v.n div 2
    then for i:= 1 to v.n do 
      v.cell[i]:= -v.cell[i];
  finally
    u.free;
  end;
end;

procedure TEigenvectorCentrality.run;
var
  m,c,left,right,t,s,cz,compstruc: tsmatds;
  evals,v: tdvec;
  log: tlogfile;
  k,i,nontrivial: integer;
  complex,disconnected: boolean;
  varname,eigfn: string;
  de: tDisconnectedEigenvector;

  procedure rundistances;
  var
    nl: tnodelist;
    i,j: integer;
  begin
    nl:= tnodelist.create;
    nl.CopyFromTmat(m);
    nl.getdistances(m);
    for i:= 1 to m.n do
      for j:= 1 to m.n do if i = j
        then m.cell[i,j]:= 1
        else m.cell[i,j]:= 1.0/m.cell[i,j];
    nl.Free;
  end;

  function countNontrivialComponents: integer;
  var kk: integer;
  begin
    result := 0;
    for kk := 1 to de.ncomp do
      if de.members.nitems[kk] > 1 then
        inc(result);
  end;

begin try
  m:= tsmatds.create;
  s:= tsmatds.create;
  t:= tsmatds.create;
  c:= tsmatds.create;
  cz:= tsmatds.create;
  compstruc:= tsmatds.create;
  left:= tsmatds.create;
  right:= left;
  evals:= tdvec.create;
  v:= tdvec.create;
  de:= nil;
  log:= tlogfile.stdcreate('Eigenvector centrality',copyright);
  log.putfn('Input dataset:',inputfn.text);
  log.putfn('Output centrality scores:',outputfn.text);
  eigfn:= outfile(inputfn.text,'-eigval');
  log.putfn('Output eigenvalues:',eigfn);
  log.lf;

  log.put('Important note: This routine automatically symmetrizes by maximum.');
  log.lf;
  m.loadhdr(inputfn.text);
  assert(m.issquare,'Matrix must be square.');
  cz.allocate(1,m.nm,1,true,true);
  cz.cdvn.copy(m.mdvn);
  cz.rdvn.fillwith('Centralization');
  c.allocate(m.n,m.nm,1,false,false);
  c.nr:= m.nr; c.nc:= 0;
  for k:= 1 to m.nm do begin
    m.loaddat;
    m.symmetrize;
    if convertdata.checked
      then rundistances;

    // Check for disconnected graph
    de:= tDisconnectedEigenvector.create;
    de.run(m);
    nontrivial := countNontrivialComponents;
    disconnected := nontrivial > 1;

    if disconnected then begin
      // Use beta matching method (Everett & Borgatti)
      log.lf;
      log.put('NOTE: Network is disconnected (' + inttostr(de.ncomp) +
        ' components, ' + inttostr(nontrivial) + ' non-trivial).');
      log.put('Using the Everett-Borgatti beta matching method to handle disconnectedness.');
      log.lf;
      de.buildcompstruc(compstruc);
      compstruc.displayasmatrix(log.stream);
      // Extract beta matching scores (column 9 = BetaMatch1)
      v.allocate(m.n,true,true);
      for i := 1 to m.n do
        v.cell[i] := de.scores.cell[i, 11];
      if makepositive.checked then
        runpositive(v);
      cz.cell[1,k] := getcentralization(v);
      normalize(v, normalization.itemindex);
    end
    else begin
      // Connected graph: standard eigenvector centrality
      eigen(complex,left,right,evals,m);
      left.extractcolumn(v,1);
      if makepositive.checked
        then runpositive(v);
      cz.cell[1,k]:= getcentralization(v);
      normalize(v,normalization.itemindex);
      if m.nm = 1
        then varname:= 'Positive eigenvalues of ' +filenameonly(inputfn.text)
        else varname:= 'Positive eigenvalues of ' + m.mdvn.labelget(k);
      makeevalstable(t,evals,varname);
      t.displayasmatrix(log.stream);
      t.savedat(eigfn);
    end;
    if m.nm = 1
      then varname:= 'Eigenvector'
      else varname:= 'e' + m.mdvn.labelget(k);
    c.storevariable(varname,v);
    m.mdvn.prefix:= filenameonly(inputfn.text);
    freeandnil(de);
  end;
  if not disconnected then begin
    t.nm:= m.nm;
    t.savehdr(eigfn);
  end;
  c.rdvn.copy(m.rdvn);
  c.title:= 'Eigenvector centrality of ' + filenameonly(inputfn.Text);
  c.save(outputfn.text);
  c.displayasmatrix(log.stream);
  getcolumnstats(s,c,true);
  s.displayasmatrix(log.stream);
  cz.title:= 'Eigenvector centralization percentages';
  cz.displayasmatrix(log.stream);
  log.browse;
  finally
    c.free;
    cz.free;
    compstruc.free;
    freeandnil(left);
    v.free;
    m.free;
    t.free;
    evals.free;
    s.free;
    de.Free;
    log.free;
  end;
end;

procedure TEigenvectorCentrality.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(inputfn);
end;

procedure TEigenvectorCentrality.SpeedButton2Click(Sender: TObject);
begin
  stdpicksavefile(outputfn);
end;

end.
