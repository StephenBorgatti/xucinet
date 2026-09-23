unit uc_EgoNetHomophilyCont;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Buttons, math, generics.collections,
  ucommon, utsmatds, ufn, utsvec, utsmat3ds, utlogfile, utparser, udialogs,
  utindividualhomophilycont, unormalize, ustring,
  Vcl.CheckLst;

type
  TEgoNetHomophilyCont = class(TForm)
    Group: TGroupBox;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    Label1: TLabel;
    Label2: TLabel;
    SpeedButton3: TSpeedButton;
    InputNetFn: TLabeledEdit;
    InputAttrFn: TLabeledEdit;
    Dimension: TComboBox;
    DimensionValue: TComboBox;
    OutputFn: TLabeledEdit;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    EgoNetType: TRadioGroup;
    ProgressBar1: TProgressBar;
    Normalization: TRadioGroup;
    Measuresbox: TGroupBox;
    Measures: TCheckListBox;
    procedure DimensionChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure InputAttrFnChange(Sender: TObject);
    procedure InputNetFnChange(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function getattr(attr:tsvec): boolean;
    procedure run;
    procedure setlabels;
  end;

var
  EgoNetHomophilyCont: TEgoNetHomophilyCont;

implementation

{$R *.dfm}

uses uc_Display;

procedure TEgoNetHomophilyCont.DimensionChange(Sender: TObject);
begin
  if not fileexists(hsys(inputattrfn.text))
    then showmessage('Need to enter valid attribute filename.')
    else setlabels;
end;

procedure TEgoNetHomophilyCont.setlabels;
label cleanup;
var
  m: tsmatds;
  i,j: integer;
begin
  m:= tsmatds.create;
  dimensionvalue.Clear;
  if fileexists(hsys(inputattrfn.text)) then begin
    if not m.loadhdr(inputattrfn.text) then goto cleanup;
    case dimension.itemindex of
      0: for j:= 1 to m.nc do dimensionvalue.items.add(m.cdvn.labelget(j));
      1: for i:= 1 to m.nr do dimensionvalue.items.add(m.rdvn.labelget(i));
      end;
    dimensionvalue.ItemIndex:= 0;
    end;
  cleanup:
    m.free;
end;

procedure TEgoNetHomophilyCont.FormCreate(Sender: TObject);
begin
  measures.Checked[5]:= true;
end;

function tegonetHomophilycont.getattr(attr:tsvec): boolean;
var
  m: tsmatds;
  i,j,k: integer;
begin try
  result:= false;
  m:= tsmatds.create;
  if not m.load(inputattrfn.text) then exit;
  k:= dimensionvalue.itemindex + 1;
  case dimension.itemindex of
    0: begin
         if not attr.allocsize(m.nr) then exit;
         for i:= 1 to m.nr do
           attr.cell[i]:= m.cell[i,k];
         end;
    1: begin
         if not attr.allocsize(m.nc) then exit;
         for j:= 1 to m.nc do
           attr.cell[i]:= m.cell[k,j];
         end;
    end;
  result:= true;
  finally
    m.free;
  end;
end;

procedure TEgoNetHomophilyCont.InputAttrFnChange(Sender: TObject);
begin
  if fileexists(hsys(inputattrfn.text))
    then setlabels;
end;

procedure TEgoNetHomophilyCont.InputNetFnChange(Sender: TObject);
begin
  outputfn.Text:= allbutext(inputnetfn.Text)+'-EASContMeas';
end;

procedure TEgoNetHomophilyCont.OKBtnClick(Sender: TObject);
begin
  run;
end;

function massagematrix(net:tsmatds; method:integer): boolean;
var
  i,j: integer;
begin
  result:= false;
  case method of
    0: for i:= 2 to net.nr do for j:= 1 to i-1 do begin {both}
           net.cell[i,j]:= max(net.cell[i,j],net.cell[j,i]);
           net.cell[j,i]:= net.cell[i,j];
           end;
    1: begin {outgoing}
       end;
    2: if not net.transposesquarematrix then exit; {incoming}
    3: begin {reciprocated only}
         for i:= 2 to net.nr do for j:= 1 to i-1 do begin
           net.cell[i,j]:= min(net.cell[i,j],net.cell[j,i]);
           net.cell[j,i]:= net.cell[i,j];
           end;
       end;
    end;
  result:= true;
end;

procedure tegonethomophilycont.run;
var
  meas,net: tsmatds;
  tab: tsmat3ds;
  attr: tsvec;
  i,j,k,m,num: integer;
  prod: double;
  log: tlogfile;
  s: tindividualhomophilycont;
  diagok: boolean;
  list: tlist<tindividualhomophilycont>;
  temp: single;
  t: string;
  diag: tstringlist;

  procedure addstring(newstr:string);
  begin
    t:= t + ',' + newstr;
  end;

  procedure rundiag(i,j: integer);
  var t: string;
  begin
    t:= inttostr(i);
    addstring(inttostr(j));
    addstring(floattostr(net.cell[i,j]));
    addstring(floattostr(attr.cell[i]));
    addstring(floattostr(attr.cell[j]));
    addstring(floattostr(temp));
    diag.add(t);
  end;

begin try
  net:= tsmatds.create;
  meas:= tsmatds.create;
  attr:= tsvec.create;
  tab:= tsmat3ds.create;
  diag:= tstringlist.Create;
  list:= tlist<tindividualhomophilycont>.create;
  log:= tlogfile.stdcreate('Egonet Alter-Ego Similarity (e.g., homophily)',copyright);
  log.putfn('Input Network:',inputnetfn.text);
  log.putfn('Input Attribute:',inputattrfn.text+' '+dimension.text+' '+inttostr(dimensionvalue.itemindex)+':'+dimensionvalue.text);
  log.putstr('Ego Network Type:',egonettype.Items[egonettype.itemindex]);
  t:= '';
  for i:= 0 to measures.Count-2 do
    if measures.Checked[i] then
      t:= t +  measures.Items[i] + ', ';
  if measures.Checked[measures.Count-1]
    then t:= t + measures.Items[i];
  log.putstr('Measures:',t);
  log.putstr('Normalization:',itemstr(normalization));
  log.putfn('Output dataset:',outputfn.text);
  log.lf;
  if not net.loadhdr(inputnetfn.text) then exit;
  if egonettype.itemindex in [0,3] then
    if net.nr <> net.nc then
      raise exception.create('Network matrix must be square.');
  if not getattr(attr) then exit;
  if attr.n <> net.nr then
    raise exception.create('Attribute vector must be same size as matrix rows.');
  normvec(attr,normalization.ItemIndex);
//  attr.save('diag');
  meas.nafill;
  meas.nm:= net.nm;
  meas.mdvn.copy(net.mdvn);
  meas.rdvn.copy(net.rdvn);
  meas.title:= 'Node-level alter-ego similarity';
  for i:= 0 to measures.Count-1 do
    if measures.Checked[i] then begin
      meas.cdvn.addstr(trim(gettoken(1,measures.Items[i],[':'])));
      s:= tindividualhomophilycont.create;
      s.setsimilarity(i);
      list.Add(s);
      end;
  if not meas.allocsize(net.nr,meas.cdvn.n) then exit;
  diagok:= net.Is2mode;
  progressbar1.Max:= net.nm; progressbar1.position:= 0;
  for k:= 1 to net.nm do begin
    if not net.loaddat(inputnetfn.text) then exit;
    massagematrix(net,egonettype.itemindex);
    m:= 0;
    for s in list do begin
      inc(m);
      for i:= 1 to net.nr do begin
        s.clear;
        for j:= 1 to net.nc do
          if diagok or (i<>j) then begin
            temp:= s.getsimilarity(attr.cell[i],attr.cell[j]);
            s.addcase(net.cell[i,j],temp);
//            rundiag(i,j);
            end;
        meas.cell[i,m]:= s.gethomophily;
        end;
      end;
//    diag.SaveToFile('diagnostics.csv');
    meas.savedat(outputfn.text);
    log.putstr(net.mdvn.labelget(k));
    if meas.smallenoughtodisplay
      then meas.displayasmatrix(log.stream)
      else log.writeln('Use DISPLAY command to view output measures.');
    progressbar1.StepBy(1);
    end;
  if measures.Checked[2] or measures.Checked[3] then begin
    log.putstr('Note: The difference-based measures are reverse measures of ego-alter similarity or homophily.');
    log.putstr('      Positive values indicate ego-alter dissimilarity or heterophily');
    end;
  meas.savehdr(outputfn.text);
  log.putfn('Output dataset:',outputfn.text);
  finally
    log.browse;
    log.free;
    for s in list do
      s.Free;
    list.Free; meas.free; net.free; attr.free;
    diag.Free;
  end;
end;

procedure TEgoNetHomophilyCont.SpeedButton1Click(Sender: TObject);
begin
  stdpickopenfile(inputnetfn);
end;

procedure TEgoNetHomophilyCont.SpeedButton2Click(Sender: TObject);
begin
  stdpickopenfile(inputattrfn);
end;

procedure TEgoNetHomophilyCont.SpeedButton3Click(Sender: TObject);
begin
  stdpicksavefile(outputfn);
end;

end.
