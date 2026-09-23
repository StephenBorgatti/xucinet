unit uc_categoricalcoreperiphery;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls,
  math,
  ucommon, udialogs, ufn, ufnvcl, utlogfile, utsmatds, utimatds, ustring,
  utcpcat, udisplay;

type
  TCategoricalCorePeriphery = class(TForm)
    GroupBox1: TGroupBox;
    SpeedButton1: TSpeedButton;
    SpeedButton3: TSpeedButton;
    InputFn: TLabeledEdit;
    Outputfn: TLabeledEdit;
    GroupBox2: TGroupBox;
    ExcludeDiagonal: TCheckBox;
    RandomStarts: TLabeledEdit;
    MaxIterations: TLabeledEdit;
    CancelBtn: TBitBtn;
    OKBtn: TBitBtn;
    HelpBtn: TBitBtn;
    CoreToPeriphery: TLabeledEdit;
    PeripheryToCore: TLabeledEdit;
    quickanddirty: TCheckBox;
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure InputFnChange(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure run;
    procedure setrandomstarts;
  end;

var
  CategoricalCorePeriphery: TCategoricalCorePeriphery;

implementation

{$R *.dfm}

procedure TCategoricalCorePeriphery.InputFnChange(Sender: TObject);
begin
  outputfn.text:= outfile(inputfn.text,'-catcp');
  if ucinetfileexists(inputfn.Text)
    then setrandomstarts;
end;

procedure TCategoricalCorePeriphery.run;
label cleanup;
var
  k,i: integer;
  log: tlogfile;
  m: tsmatds;
  p: timatds;
  cp: tcatcp;
  s: string;

  procedure displayclasses;
  var
    k,i: integer;
    core,periph: string;

    function nameof(i:integer): string;
    begin
      result:= m.rdvn.labelget(i);
    end;
    
  begin
    log.put('Core/Periphery Class Memberships:'); log.lf;
    core:=   '       Core: ';
    periph:= '  Periphery: ';
    for i:= 1 to cp.n do
      if cp.part[i] = 1 
        then core:= core + ' ' + nameof(i)
        else periph:= periph + ' ' + nameof(i);
    log.put(core);
    log.put(periph);
    log.lf(2);
  end;
  
begin try
  cp:= tcatcp.create;
  m:= tsmatds.create;
  p:= timatds.create;
  log:= tlogfile.stdcreate('Categorical Core/Periphery',copyright);
  log.putfn('Input dataset:',inputfn.text);
  log.putfn('Output partition:',outputfn.text);
  log.putstr('Exclude diagonal:',bstr(excludediagonal.Checked));
  log.putstr('Number of random starts:',randomstarts.text);
  log.putstr('Maximum iterations:',maxiterations.text);
  log.putstr('Density of core->periphery ties:',coretoperiphery.text);
  log.putstr('Density of periphery->core ties:',peripherytocore.text);
  log.putstr('Measure of fit:','Correlation');
  log.lf;

  m.loadhdr(inputfn.text);
  assert(m.issquare,'Matrix must be square.');
  p.allocate(m.nr,m.nm,1,true,false);
  p.rdvn.copy(m.rdvn);
  p.cdvn.copy(m.mdvn);
  if not p.cdvn.hasval
    then begin
     for i:= 1 to p.nc do
      p.cdvn.sput(i,'cp'+istr(i));
     end;
  p.title:= 'Core/Periphery partition for ' + filenameonly(inputfn.text);
  cp.maxit:= strtointdef(maxiterations.Text,cp.maxit);
  cp.nstart:= strtointdef(randomstarts.text,cp.nstart);
  cp.diagok:= not excludediagonal.checked;
  if not trystrtofloat(coretoperiphery.text,cp.c2p)
    then cp.c2p:= bna;
  if not trystrtofloat(peripherytocore.text,cp.p2c)
    then cp.p2c:= bna;
  if quickanddirty.Checked
    then cp.maxit:= 1;
  log.lf;
  for k:= 1 to m.nm do begin
    m.loaddat;
    cp.run(m);
    for i:= 1 to m.nr do 
      p.cell[i,k]:= cp.part[i];
    if m.nm > 1 then begin
      log.lf();
      log.put('Matrix: ' + m.mdvn.labelget(k),[linebelow]);
      log.lf();
      end;
    log.put('Core/Periphery fit (correlation) = '+floattostrf(cp.fit,ffgeneral,4,3));
    log.lf;
    if m.smallenoughtodisplay
      then begin
        displayclasses;
        g2blockdisplay(log.stream,m,cp.part,cp.part,pagewidth,defaultw,defaultd,1,' ');
       end
      else begin
        log.put('Display suppressed due to size. Use Display to view output file.');
        end;
    log.lf;
    log.write('Iterations: ');
    for i in cp.iterations do
      log.write(' '+inttostr(i));
    log.lf;
    end;
  p.save(outputfn.text);
  finally
    log.browse;
    cp.free; m.free; p.free; log.free;
  end;
end;

procedure TCategoricalCorePeriphery.setrandomstarts;
var
  temp: tsmatds;
begin
  temp:= tsmatds.create;
  temp.loadhdr(inputfn.Text);
  if temp.n < 50
    then randomstarts.Text:= inttostr(20)
    else if temp.n < 150
      then randomstarts.Text:= inttostr(10)
      else randomstarts.Text:= '3';
  temp.Free;
end;

procedure TCategoricalCorePeriphery.OKBtnClick(Sender: TObject);
begin
  if ucinetfileexists(inputfn.Text)
    then run
    else begin
      showmessage('File does not exist.');
      modalresult:= mrnone;
      end;
end;

procedure TCategoricalCorePeriphery.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(inputfn);
end;

procedure TCategoricalCorePeriphery.SpeedButton3Click(Sender: TObject);
begin
  stdpicksavefile(outputfn);
end;

end.
