unit uc_DegreeCentrality;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  udialogs, ufn, ug2centralitymeasures, utsmat3ds, utsvec,
  utnodelist, utivec, utvec, utlogfile, ucommon, ugeneral, ug2display, ustring,
  utsmatds, ComCtrls, math, ug2stats;
type
  TDegreeCentrality = class(TForm)
    Label8: TLabel;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    GraphType: TRadioGroup;
    GroupBox1: TGroupBox;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    InputFn: TLabeledEdit;
    OutputFn: TLabeledEdit;
    GroupBox2: TGroupBox;
    EdgeWeights: TCheckBox;
    GroupBox3: TGroupBox;
    Raw: TCheckBox;
    Normalized: TCheckBox;
    Centralizationfn: TLabeledEdit;
    SpeedButton3: TSpeedButton;
    ExcludeDiagonal: TCheckBox;
    wtdnormalization: TCheckBox;
    procedure SpeedButton1Click(Sender: TObject);
    procedure InputFnChange(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    m,cz: tsmatds;
    c: tsmat3ds;
    directed,diagok: boolean;
    n: integer;
    maxval: single;
    procedure run;
    procedure rundegree(r:integer);
  end;

var
  DegreeCentrality: TDegreeCentrality;

implementation

{$R *.dfm}

procedure TDegreeCentrality.InputFnChange(Sender: TObject);
begin
  outputfn.text:= filenameonly(inputfn.text) + '-deg';
  centralizationfn.text:= filenameonly(inputfn.text) + '-degcz';
end;

procedure TDegreeCentrality.OKBtnClick(Sender: TObject);
begin
  run;
end;

procedure TDegreeCentrality.run;
label cleanup;
var
  r: integer;
  log: tlogfile;
begin try
  m:= tsmatds.create;
  cz:= tsmatds.create;
  c:= tsmat3ds.create;
  log:= tlogfile.stdcreate('FREEMAN DEGREE CENTRALITY',copyright);
  log.putfn('Input dataset:',inputfn.text);
  log.putfn('Output degree dataset:',outputfn.text);
  log.putfn('Output centralization dataset:',centralizationfn.text);
  log.putstr('Treat data as:',graphtype.items[graphtype.itemindex]);
  log.putstr('Output raw totals:',bstr(raw.Checked));
  log.putstr('Output averages (normalized):',bstr(normalized.Checked));
  log.putstr('Allow edge weights:',bstr(edgeweights.Checked));
  log.putstr('Weighted normalization:',bstr(wtdnormalization.Checked));
  log.putstr('Exclude diagonal:',bstr(excludediagonal.Checked));
  log.lf;

  if not m.loadhdr(inputfn.text) then goto cleanup;
  if not m.IsSquare then begin
    log.stream.WriteLine('ERROR: Matrix is not square.');
    goto cleanup;
    end;
  n:= m.n;
  diagok:= not excludediagonal.checked;
  cz.allocate(m.nm,2,1,true,true);
  cz.nc:= 0;
  cz.rdvn.copy(m.mdvn);
  if not c.allocate(n,4,m.nm,true,false) then goto cleanup;
  c.nafill();
  c.rdvn.copy(m.rdvn);
  c.mdvn.copy(m.mdvn);
  c.cdvn.clear;
  for r:= 1 to m.nm do begin
    if not m.loaddat(inputfn.text) then goto cleanup;
    m.recodena();
    if edgeweights.checked
      then maxval:= summarizematrix(m,diagok).max
      else begin
        m.dichotomize(opgt,0);
        maxval:= 1;
        end;
    case graphtype.itemindex of
      0: directed:= true;
      1: begin m.symmetrize(sy_union); directed:= false; end;
      2: begin directed:= not m.issymmetric;
           log.stream.WriteLine('Network '+m.mdvn.labelget(r)+' is directed? '+bstr(directed));
           log.lf();
           end;
      end;
    rundegree(r);
    end;
  c.nc:= c.cdvn.n;
  c.title:= 'Degree Measures';
  c.displayasmatrix(log.stream,-1,-1);
//  display3(log.stream,c,pagewidth,-1,max(1,defaultd));
  c.save(outputfn.text);
  cz.nc:= cz.cdvn.n;
  log.lf();
  cz.title:= 'Graph Centralization -- as proportion, not percentage';
  if m.mdvn.hasval 
    then cz.rdvn.copy(m.mdvn)
    else if m.nm = 1 then cz.rdvn.add(filenameonly(inputfn.Text));
  cz.displayasmatrix(log.stream,0,4);
  cz.save(centralizationfn.text);
  cleanup:
    log.browse;
    m.free;
    c.free;
    cz.free;
    log.free;
  except
    showmessage('problem with matrix '+inttostr(r));
    end;
end;

procedure TDegreeCentrality.rundegree(r:integer);
var
  i,j: integer;
  rv,cv: tsvec;
  den: single;

  procedure store(prefix:string='');
  begin
  if directed
    then begin
      c.storecolumn(r,prefix+'Outdeg',rv);
      c.storecolumn(r,prefix+'Indeg',cv);
      end
    else c.storecolumn(r,prefix+'Degree',rv);
  end;

  function getcentralization(v:tsvec): double;
  var
    maxv,sumv,diff,wt: double;
    i: integer;
  begin
    maxv:= 0; sumv:= 0;
    for i:= 1 to n do begin
      if v.cell[i] > maxv then maxv:= v.cell[i];
      sumv:= sumv + v.cell[i];
      end;
    diff:= n*maxv - sumv;
    if wtdnormalization.checked
      then wt:= maxval
      else wt:= 1;
    if directed
      then result:= diff/(wt*(n-1)*(n-1))
      else result:= diff/(wt*(n-1)*(n-2));
  end;

  procedure runcentralization;
  var
    j: integer;
  begin
    if directed
      then begin
        j:= cz.storevariable('Out-Centralization',nil);
        if j > 0 then cz.cell[r,j]:= getcentralization(rv);
        j:= cz.storevariable('In-Centralization',nil);
        if j > 0 then cz.cell[r,j]:= getcentralization(cv);
        end
      else begin
        j:= cz.storevariable('Centralization',nil);
        if j > 0 then cz.cell[r,j]:= getcentralization(rv);
        end;
  end;

begin try
  rv:= tsvec.create;
  cv:= tsvec.create;
  rv.allocate(n,true,true);
  cv.allocate(n,true,true);
  for i:= 1 to n do
    for j:= 1 to n do if (i<>j) or diagok then begin
      rv[i]:= rv[i] + m.cell[i,j];
      cv[j]:= cv[j] + m.cell[i,j];
      end;
  if raw.Checked then begin
    store;
    runcentralization;
    end;
  if normalized.checked then begin
    if wtdnormalization.checked 
      then den:= maxval*(n-1)
      else den:= n-1;
    for i:= 1 to n do begin
      rv[i]:= rv[i]/den;
      cv[i]:= cv[i]/den;
      end;
    store('n');
    end;
  finally
    rv.free; cv.free;
  end;
end;
 
procedure TDegreeCentrality.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(inputfn);
end;

procedure TDegreeCentrality.SpeedButton2Click(Sender: TObject);
begin
  stdpicksavefile(centralizationfn);
end;

end.
