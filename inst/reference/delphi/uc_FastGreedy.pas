unit uc_FastGreedy;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls,
  math,
  ugeneral,ucommon, utsmatds, ufn, utsvec, utivec, utvvec, ug2display, utlogfile,
  udialogs,
  utsmat3ds, ustats, ustring, utquickclus, utimatds, uq, uttracker,
  ucomponents, ufastgreedy3, ufastgreedies, ucliquetools;

type
  TFastGreedy = class(TForm)
    Group: TGroupBox;
    SpeedButton1: TSpeedButton;
    SpeedButton3: TSpeedButton;
    InputNetFn: TLabeledEdit;
    OutputFn: TLabeledEdit;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    InitialPartition: TRadioGroup;
    procedure InputNetFnChange(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure run;
  end;

var
  FastGreedy: TFastGreedy;

implementation

{$R *.dfm}

procedure TFastGreedy.InputNetFnChange(Sender: TObject);
begin
  outputfn.Text:= outfile(inputnetfn.Text,'-fg');
end;

procedure TFastGreedy.OKBtnClick(Sender: TObject);
begin
  if ucinetfileexists(inputnetfn.Text)
    then run
    else begin
      showmessage('Network dataset does not exist. Check and try again.');
      modalresult:= mrnone;
    end;
end;

procedure TFastGreedy.run;
var
  net: tsmatds;
  part: tivec;
  partmat: timatds;
  i,j,k,ng: integer;
  q: double;
  log: tlogfile;
  s: string;
  cliquepart: boolean;

  procedure clean;
  var
    i,j: integer;
  begin
    for i:= 2 to net.n do
      for j:= 1 to i-1 do
        if net.isna(i,j) or net.isna(j,i)
          then begin net.cell[i,j]:= 0; net.cell[j,i]:= 0; end
          else begin
            net.cell[i,j]:= max(net.cell[i,j],net.cell[j,i]);
            net.cell[j,i]:= net.cell[i,j];
            end;
    for i:= 1 to net.n do
      net.cell[i,i]:= 0;
  end;

begin try
  net:= tsmatds.create;
  partmat:= timatds.create;
  part:= tivec.create;
  log:= tlogfile.stdcreate('FastGreedy Community Detection',copyright);
  log.putfn('Input network:',inputnetfn.text);
  log.putfn('Initial partition:',itemstr(initialpartition));
  log.putfn('Output partition:',outputfn.text);
  log.lf;

  cliquepart:= initialpartition.ItemIndex = 1;
  net.loadhdr(inputnetfn.text);
  if net.is2mode() then
    raise exception.Create('Network must be 1-mode.');
  partmat.allocate(net.n,net.nm,1,true,false);

  for k:= 1 to net.nm do begin
    net.loaddat;
    clean;
    if cliquepart
      then ng:= getcliquestart(part,net);
    if net.n <= 100
      then ng:= runfastgreedy(part,net)
      else fglouvain(ng,part,net,cliquepart);
    q:= getfgmodularity(part,net,ng);
    partmat.copyvec2col(part,k);
    if net.nm > 1 then begin
      log.lf;
      log.writeln('Network: '+net.mdvn.labelget(k));
      end;
    log.writeln(inttostr(ng) + ' groups found.');
    log.writeln('Modularity = ' + fstr(q,0,4));
    partmat.copyvec2col(part,k);
    if net.nm > 1
      then s:= net.mdvn.labelget(k)
      else s:= 'fg' + inttostr(ng) + '(' + fstr(q,0,4) + ')';
    partmat.cdvn.sput(k,s);
    end;
  partmat.rdvn.copy(net.rdvn);
  partmat.title:= 'Fast Greedy Partitions';
  partmat.save(outputfn.text);
  partmat.displayasmatrix(log.stream);
  log.lf;
  finally
    log.browse;
    log.free;
    partmat.free; net.free; part.Free;
    end;
end;

procedure TFastGreedy.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(inputnetfn);
end;

procedure TFastGreedy.SpeedButton3Click(Sender: TObject);
begin
  stdpicksavefile(outputfn);
end;

end.
