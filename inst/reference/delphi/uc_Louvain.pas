unit uc_Louvain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
    Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls,
  ucommon, ugeneral, utsmatds, utsmat3ds, utsmat, utimatds, udialogs,
  utlogfile, uti64vec, utivec,
  ustring,  uprogressdlg, ug2display, ustats,  ufn, utucdataset,
  ueigen, ucan, utnodelist, utsvec, ug2textdendrogram,
  utlouvain;


type
  TLouvainMethod = class(TForm)
    GroupBox1: TGroupBox;
    Inputfnbtn: TSpeedButton;
    evalbtn: TSpeedButton;
    SpeedButton1: TSpeedButton;
    InputFn: TLabeledEdit;
    Outputfn: TLabeledEdit;
    StartingPartitionFn: TLabeledEdit;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    GroupBox2: TGroupBox;
    MaxPartitions: TLabeledEdit;
    StartingCol: TComboBox;
    Label1: TLabel;
    symmetrize: TRadioGroup;
    procedure InputfnbtnClick(Sender: TObject);
    procedure evalbtnClick(Sender: TObject);
    procedure InputFnChange(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure speedbutton1click(sender: tobject);
    procedure StartingPartitionFnChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure run;
  end;

var
  LouvainMethod: TLouvainMethod;

implementation

{$R *.dfm}

procedure tLouvainMethod.evalbtnClick(Sender: TObject);
begin
  stdpicksavefile(startingpartitionfn);
end;

procedure tLouvainMethod.InputfnbtnClick(Sender: TObject);
begin
  stdpickopenfile(inputfn);
end;

procedure tLouvainMethod.InputFnChange(Sender: TObject);
begin
  outputfn.text:= outfile(inputfn.text,'-louv');
end;

procedure tLouvainMethod.OKBtnClick(Sender: TObject);
begin
  if ucinetfileexists(inputfn.Text)
    then run
    else begin
      showmessage('Input file not found.');
      modalresult:= mrnone;
    end;
end;

procedure tlouvainmethod.speedbutton1click(sender: TObject);
begin
  stdpickopenfile(startingpartitionfn);
end;

procedure TLouvainMethod.StartingPartitionFnChange(Sender: TObject);
begin
  if ucinetfileexists(startingpartitionfn.text)
    then begin
      getcolumnlabels(startingpartitionfn.Text,startingcol.items);
      startingcol.ItemIndex:= 0;
      end;
end;

procedure tLouvainMethod.run;
var
  log: tlogfile;
  part: timatds;
  mat,q: tsmatds;
  initial: tivec;
  k: integer;
  i: Integer;
  lou: tlouvain;
  meth,sym: integer;

  procedure loadpartition;
  begin
    loadcolumn(initial,startingcol.ItemIndex+1,startingpartitionfn.Text);
  end;

  procedure runmultiple;
  var
    k,i: integer;
    numneg: longint;
  begin
    part.allocate(mat.n,mat.nm,1,true,true);
    for k := 1 to mat.nm do begin
      mat.loaddat;
      numneg:= mat.removenegatives;
      if numneg > 0 then log.writeln('Negative values removed.');
      if sym > 0
        then if not mat.IsSymmetric()
          then mat.symmetrize(symtype(sym));
      lou.run(mat,initial,meth);
      for i:= 1 to mat.n do
        part[i,k]:= lou.hier[i,lou.npart];
      end;
    part.cdvn.copy(mat.mdvn);
    part.rdvn.copy(mat.rdvn);
  end;

  procedure runsingle;
  var
    numneg: longint;
  begin
    mat.loaddat;
    numneg:= mat.removenegatives;
    if numneg > 0 then
      log.writeln('Negative ties removed');
    if sym > 0
      then if not mat.IsSymmetric()
        then mat.symmetrize(symtype(sym));
    lou.run(mat,initial,meth);
    part.copy(lou.hier);
  end;

begin try
  mat:= tsmatds.create;
  part:= timatds.create;
  initial:= tivec.create;
  lou:= tlouvain.create;
  log:= tlogfile.stdcreate('Louvain Community Detection',copyright);
  log.putfn('Input Network dataset:',inputfn.Text);
  if startingpartitionfn.text <> '' then begin
    log.putfn('Input Network dataset:',startingpartitionfn.Text);
    log.putstr('Column:',itemstr(startingcol));
    end;
  log.putstr('Max number of partitions:',maxpartitions.text);
  log.putstr('For directed data:',itemstr(symmetrize));
  log.putfn('Output Partitions:',outputfn.text);
  log.lf;

  lou.maxpart:= strtointdef(maxpartitions.text,-1);
  sym:= symmetrize.ItemIndex;
  if startingpartitionfn.Text <> ''
    then loadpartition;
  if initial.hasval
    then meth:= -1
    else meth:= 0;
  part.title:= 'Louvain partitions';
  mat.loadhdr(inputfn.text);
  if mat.nm > 1
    then runmultiple
    else runsingle;
  part.save(outputfn.Text);
  part.displayasmatrix(log.stream);

  finally
    part.Free; mat.Free; lou.Free; initial.Free;
    log.browse();
    log.free;
  end;
end;

end.
