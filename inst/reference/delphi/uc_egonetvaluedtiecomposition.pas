unit uc_egonetvaluedtiecomposition;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons,
  ucommon, ugeneral, udialogs, math,
  ufn, utsmatds, utivec, utsvec, ustring, utlogfile, ug2display, umath, utimat,
  utnodelist, utsmat3ds, ug2svd, utimatds, utunivariate, uvectools, utparser,
  uheterogeneity, utransform, unormalize, utegotiecomp,
  uc_selectvariables;

type
  TValuedTieComposition = class(TForm)
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    GroupBox1: TGroupBox;
    ifnbrowse: TSpeedButton;
    ofnbrowse: TSpeedButton;
    Ifn: TLabeledEdit;
    ofn: TLabeledEdit;
    GroupBox2: TGroupBox;
    EgoNetwork: TRadioGroup;
    DiagonalOk: TCheckBox;
    Label1: TLabel;
    ValidOperator: TComboBox;
    ValidValue: TLabeledEdit;
    procedure ifnbrowseClick(Sender: TObject);
    procedure IfnChange(Sender: TObject);
    procedure ofnbrowseClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure run;
  end;

var
  ValuedTieComposition: TValuedTieComposition;

implementation

{$R *.dfm}

procedure TValuedTieComposition.ifnbrowseClick(Sender: TObject);
begin
  stdpickopenfile(ifn);
end;

procedure TValuedTieComposition.IfnChange(Sender: TObject);
begin
  ofn.Text:= outfile(ifn.Text,'-vtc');
end;

procedure TValuedTieComposition.ofnbrowseClick(Sender: TObject);
begin
  stdpicksavefile(ofn);
end;

procedure TValuedTieComposition.OKBtnClick(Sender: TObject);
begin
  if ucinetfileexists(ifn.Text)
    then run
    else begin
      showmessage('Network file not found');
      modalresult:= mrnone;
    end;
end;

procedure TValuedTieComposition.run;
var
  log: tlogfile;
  i,k,direction,op,n: integer;
  cut: single;
  meas,net: tsmatds;
  rs: tstatsrec;
  uni: tunivariate;
  diagok: boolean;

  procedure analyzer(i:integer);
  var
    m: integer;
  begin
    uni.clear;
    case direction of
      0: for m:= 1 to n do if (i<>m) or diagok then begin //or
           if net.istie(i,m,op,cut)
             then uni.addcase(net.cell[i,m]);
           if net.istie(m,i,op,cut)
             then uni.addcase(net.cell[i,m]);
           end;
      1: for m:= 1 to n do if (i<>m) or diagok then begin  //out
           if net.istie(i,m,op,cut)
             then uni.addcase(net.cell[i,m]);
           end;
      2: for m:= 1 to n do if (i<>m) or diagok then begin  //in
           if net.istie(m,i,op,cut)
             then uni.addcase(net.cell[m,i]);
           end;
      3: for m:= 1 to n do if (i<>m) or diagok then begin  //and
           if net.istie(i,m,op,cut) and net.istie(m,i,op,cut)
             then begin
               uni.addcase(net.cell[i,m]);
               uni.addcase(net.cell[m,i]);
               end;
           end;
      4: for m:= 1 to n do if (i<>m) or diagok then begin  //and
           if net.istie(i,m,op,cut) and net.istie(m,i,op,cut) and
           samevalue(net.cell[i,m],net.cell[m,i])
             then begin
               uni.addcase(net.cell[i,m]);
               uni.addcase(net.cell[m,i]);
               end;
           end;
      end;
    uni.calc;
    meas.cell[i,1]:= uni.n;  //# ties
    meas.cell[i,2]:= uni.tot;
    meas.cell[i,3]:= uni.mean;
    meas.cell[i,4]:= uni.sd;
    meas.cell[i,5]:= uni.min;
    meas.cell[i,6]:= uni.max;
    meas.cell[i,7]:= uni.range;
  end;

begin try
  log:= tlogfile.stdcreate('Egonet Valued Tie Composition Measures');
  meas:= tsmatds.create;
  net:= tsmatds.create;
  uni:= tunivariate.create;
  log.putfn('Input network',ifn.Text);
  log.putstr('Which ties define egonet?',itemstr(egonetwork));
  log.putstr('Valid ties operator:',itemstr(validoperator));
  log.putstr('Valid ties value:',validvalue.text);
  log.putstr('Include ties to self?',bstr(diagonalok.Checked));
  log.putfn('Output measures',ofn.Text);
  log.lf;
  op:= validoperator.ItemIndex;
  cut:= strf(validvalue.text);
  direction:= egonetwork.ItemIndex;
  diagok:= diagonalok.Checked;
  net.loadhdr(ifn.text);
  n:= net.n;
  meas.cdvn.fillrange(['# of ties','Sum of values','Mean','Std Dev','Min','Max','Range']);
  meas.allocate(net.nr,meas.cdvn.n,net.nm,true,false);
  meas.rdvn.copy(net.rdvn);
  meas.mdvn.copy(net.mdvn);
  for k:= 1 to net.nm do begin
    net.loaddat;
    net.recode(opeq,0,bna);
    //chooseties(net,egonetwork.ItemIndex);
    for i:= 1 to n do
      analyzer(i);
    meas.savedat(ofn.Text);
    if meas.smallenoughtodisplay then begin
      log.writeln('Matrix ' + net.mdvn.labelget(k));
      meas.displayasmatrix(log.stream);
      end;
    end;
  log.writeln('Note: the program assumes all non-zero values are ties.');
  meas.savehdr(ofn.Text);
  finally
    log.browse;
    log.Free; meas.Free; net.Free; uni.Free;
  end;
end;


end.
