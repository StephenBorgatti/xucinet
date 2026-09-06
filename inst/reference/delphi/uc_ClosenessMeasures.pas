unit uc_ClosenessMeasures;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons, math,
  ucommon, ugeneral, udialogs,
  ufn, utsmatds, utivec, utsvec, ustring, utlogfile, ug2display, umath, utimat,
  utnodelist, utsmat3ds, ug2svd, utimatds, utunivariate, ucloseness;

type
  TClosenessMeasures = class(TForm)
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    GroupBox1: TGroupBox;
    SpeedButton1: TSpeedButton;
    SpeedButton3: TSpeedButton;
    Ifn: TLabeledEdit;
    OutputFn: TLabeledEdit;
    GroupBox2: TGroupBox;
    FreemanMissing: TRadioGroup;
    FreemanOutput: TRadioGroup;
    GroupBox3: TGroupBox;
    ValenteMissing: TRadioGroup;
    ValenteOutput: TRadioGroup;
    GroupBox4: TGroupBox;
    ReciprocalOutput: TRadioGroup;
    ReciprocalMissing: TRadioGroup;
    procedure IfnChange(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure FreemanMissingClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure run;
  end;

var
  ClosenessMeasures: TClosenessMeasures;

implementation

{$R *.dfm}

function getmax(d:timat): single;
var
  i,j,n: integer;
  u: tunivariate;
begin
  u:= tunivariate.create;
  n:= d.n;
  for i:= 1 to n do
    for j:= 1 to n do if (i<>j) and (d.cell[i,j] < n)
      then u.addcase(d.cell[i,j]);
  result:= u.max;
  u.free;
end;

procedure tClosenessMeasures.run;
label cleanup;
var
  log: tlogfile;
  n,n1,nmissing,nsym: integer;
  k,i,j: integer;
  net: tnodelistds;
  d: timatds;
  cent: tsmat3ds;
  r,c: tsvec;
  directed: boolean;
  missval,maxdist: single;
  u: tunivariate;
begin try
  net:= tnodelistds.create;
  cent:= tsmat3ds.create;
  d:= timatds.create;
  r:= tsvec.create;
  c:= tsvec.create;
  log:= tlogfile.stdcreate('Closeness Centrality Measures',copyright);
  log.putfn('Input network dataset:',ifn.text);
  log.putfn('Output measures:',outputfn.text);
  log.putstr('(Freeman) Set undefined distances to:',itemstr(freemanmissing));
  log.putstr('(Freeman) Output options:',itemstr(freemanoutput));
  log.putstr('(Valente-Forman) Handle undefined distances:',itemstr(valentemissing));
  log.putstr('(Valente-Forman) Output options:',itemstr(valenteoutput));
  log.putstr('(Reciprocal) Handle undefined distances:',itemstr(reciprocalmissing));
  log.putstr('(Reciprocal) Output options:',itemstr(reciprocaloutput));
  log.lf();

  if not net.loadhdr(ifn.text) then
    raise exception.Create('Unable to open data file');
  n:= net.nr; n1:= n - 1;
  r.allocate(n,true);
  c.allocate(n,true);
  cent.allocate(n,6,net.nm,true,true);
  nsym:= 0;
  for k:= 1 to net.nm do begin
    net.loaddat();
    if net.IsSymmetric then inc(nsym);
    end;
  net.ds.closeall;
  directed:= nsym < net.nm;
  for k:= 1 to net.nm do begin
    net.loaddat();
    nmissing:= net.getdistances(d);
    maxdist:= getmax(d);
    case freemanmissing.itemindex of
      0: missval:= n;
      1: missval:= getmax(d) + 1;
      2: missval:= bna;
      end;
    freemancloseness(r,c,d,missval,freemanoutput.ItemIndex);
    if directed
      then begin
        cent.storecolumn(k,'OutClose',r);
        cent.storecolumn(k,'InClose',c);
        end
      else cent.storecolumn(k,'FreeClo',r);
    valentecloseness(r,c,d,maxdist,valenteoutput.ItemIndex);
    if directed
      then begin
        cent.storecolumn(k,'OutValClo',r);
        cent.storecolumn(k,'InValClo',c);
        end
      else cent.storecolumn(k,'ValClo',r);
    case reciprocalmissing.itemindex of
      0: missval:= n;
      1: missval:= getmax(d) + 1;
      2: missval:= bna;
      end;
    reciprocalcloseness(r,c,d,missval,reciprocaloutput.ItemIndex);
    if directed
      then begin
        cent.storecolumn(k,'OutRecipClo',r);
        cent.storecolumn(k,'InRecipClo',c);
        end
      else cent.storecolumn(k,'RecipClo',r);
    end;
  cent.nc:= cent.cdvn.n;
  cent.comments.Add('Centralities based on ' + filenameonly(ifn.text));
  cent.rdvn.copy(net.rdvn);
  cent.mdvn.copy(net.mdvn);
  cent.displayasmatrix(log.stream);
  cent.save(outputfn.text);
  finally
    log.browse; log.free;
    net.free; cent.free; d.free; r.free; c.free;
  end;
end;

procedure tClosenessMeasures.IfnChange(Sender: TObject);
begin
//  outputfn.Text:= allbutext(ifn.Text) + '-Clo';
  outputfn.Text:= outfile(ifn.text,'-clo');
end;

procedure tClosenessMeasures.OKBtnClick(Sender: TObject);
begin
  run;
end;

procedure TClosenessMeasures.FormActivate(Sender: TObject);
begin
  freemanmissingclick(sender);
end;

procedure TClosenessMeasures.FreemanMissingClick(Sender: TObject);
begin
  if freemanmissing.itemindex = 2
    then begin
      freemanoutput.ItemIndex:= 1;
      freemanoutput.Enabled:= false;
      end
    else freemanoutput.Enabled:= true;
end;

procedure tClosenessMeasures.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(ifn);
end;

procedure tClosenessMeasures.SpeedButton3Click(Sender: TObject);
begin
  stdpicksavefile(outputfn);
end;

end.
