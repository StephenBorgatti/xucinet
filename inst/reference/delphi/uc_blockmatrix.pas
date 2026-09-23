unit uc_blockmatrix;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtDlgs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Buttons,
  ucommon, UFn, ugeneral,udupdash,ustring, utlogfile, udialogs, ulabels,
  utstrvec, utsmat3ds, ucategoricalautocorrelation, utcorr,
  ug2display,utunivariate,ug2dsl,utivec, utsmatds, ucan,
  ukey,
  uc_selectgroupsdlg, utsvec, uaggregate, utfrequencies5;

type
  Tblockmatrix = class(TForm)
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    GroupBox1: TGroupBox;
    Label9: TLabel;
    inputfnspeedbutton: TSpeedButton;
    Label2: TLabel;
    RowSpeedButton: TSpeedButton;
    Label3: TLabel;
    ColumnSpeedButton: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    InputFn: TEdit;
    RowFn: TEdit;
    ColFn: TEdit;
    RowLabels: TComboBox;
    ColLabels: TComboBox;
    Outputfn: TLabeledEdit;
    Button2: TButton;
    Button4: TButton;
    GroupBox3: TGroupBox;
    Diagonal: TCheckBox;
    Button1: TButton;
    OpenTextFileDialog1: TOpenTextFileDialog;
    MatchBy: TRadioGroup;
    Method: TRadioGroup;
    SpeedButton1: TSpeedButton;
    procedure inputfnspeedbuttonClick(Sender: TObject);
    procedure RowFnChange(Sender: TObject);
    procedure RowSpeedButtonClick(Sender: TObject);
    procedure RowLabelsChange(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure ColFnChange(Sender: TObject);
    procedure ColumnSpeedButtonClick(Sender: TObject);
    procedure ColLabelsChange(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure InputFnChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    m: tsmatds;
    rl,cl: tstringlist;
    log: tlogfile;
    procedure run;
    function setlabels(dvn:tstrvec; fn:string; labs:tcombobox): boolean;
    function loadattr(fn:string; idx,dim:integer; p:tivec; var np:integer): boolean;
  end;
  tpartitiontype = (pcomplete,pfile,pidentity,punknown);

var
  blockmatrix: Tblockmatrix;



implementation
uses
  ucinet;

{$R *.dfm}

function tblockmatrix.setlabels(dvn:tstrvec; fn:string; labs:tcombobox): boolean;
label cleanup;
var
  v: tsmatds;
  i,j: integer;
begin
  try
  v:= tsmatds.create;
  result:= false;
  if fileexists(hsys(fn)) then begin
    if not v.loadhdr(fn) then goto cleanup;
    labs.Clear;
    v.cdvn.prefix:= 'C';
    if v.cdvn.allnumeric
      then for j:= 1 to v.nc do labs.items.add('C'+v.cdvn.labelget(j))
      else for j:= 1 to v.nc do labs.items.add(v.cdvn.labelget(j));
    labs.ItemIndex:= 0;
    end;
  result:= true;
  cleanup:
  finally
    v.free;
    end;
end;

procedure tblockmatrix.RowFnChange(Sender: TObject);
begin
  if (upstring(rowfn.text) = 'IDENTITY') or (upstring(rowfn.text) = 'COMPLETE')
    then begin
      rowlabels.visible:= false;
      end
    else begin
      rowlabels.visible:= true;
      if fileexists(hsys(rowfn.text)) then begin
        setlabels(m.rdvn,rowfn.text,rowlabels);
        if m.nr = m.nc then begin
          colfn.text:= rowfn.text;
          collabels.Clear; collabels.items.AddStrings(rowlabels.items);
          collabels.itemindex:= rowlabels.itemindex;
          end;
        end;
      end;
end;

procedure tblockmatrix.RowLabelsChange(Sender: TObject);
begin
  collabels.itemindex:= rowlabels.itemindex;
end;

procedure tblockmatrix.RowSpeedButtonClick(Sender: TObject);
begin
  stdpickopenfile(rowfn);
end;



function getpartitiontype(fn:string): tpartitiontype;
begin
  if (fn = '') or iskey(fn,'identity')
    then result:= pidentity
    else if iskey(fn,'complete')
      then result:= pcomplete
      else if ucinetfileexists(fn)
        then result:= pfile
        else result:= punknown;
end;

function tblockmatrix.loadattr(fn:string; idx,dim:integer; p:tivec; var np:integer): boolean;
var
  map: tstrvec;
  freq: tivec;
  i,ii,n: Integer;
  x: tsmatds;
  v: tsvec;
  dvn: tstrvec;
  dimstr: string;
begin try
  x:= tsmatds.create;
  v:= tsvec.create;
  map:= tstrvec.create;
  freq:= tivec.create;
  x.load(fn);
  case dim of
    0: begin n:= m.nc; dimstr:= 'Col'; dvn:= m.cdvn; end;
    1: begin n:= m.nr; dimstr:= 'Row'; dvn:= m.rdvn; end;
    end;
  if dvn = nil
    then raise exception.create('You have chosen match by labels, but your data matrix has no labels.');
  v.allocate(n,true,false);
  if x.nr <> n then
    raise exception.create('Dimensions of '+dimstr+' partition attribute must match matrix.');
  if matchby.itemindex = 0
    then for i:= 1 to x.nr do v.cell[i]:= x.cell[i,idx]
    else begin
      assert(x.rdvn.hasval,'If you choose Match by Label, the attribute matrix must have labels');
      for i:= 1 to x.nr do begin
        ii:= x.rdvn.lookupstr(dvn[i]);
        if ii = 0
          then raise exception.create('Labels in '+dimstr+' attribute don''t match matrix.');
        v.cell[i]:= x.cell[ii,idx];
        end;
      end;
  utfrequencies5.renumberwithfreq(p,freq,map,v);
  np:= map.n;
  DisplayClassMembersWithFreq(log.stream,p,freq,dimstr,map,x.rdvn);
  v.renumber;
  p.copy(v);
  finally
    v.free; x.free; map.free; freq.free;
  end;
end;

procedure tblockmatrix.run;
var
  nrp,ncp,i,j,k,ii,jj,aii,ajj,mii,mjj: integer;
  rp,cp: tdsl;
  rpdvn,cpdvn,rlab,clab,dvn: tstrvec;
  sd,f,p: tsmatds;
  wden: tsmat3ds;
  diagok: boolean;
  meth: integer;
  denfn,sumfn,sdfn,wdenfn: string;
  onemode,valued: boolean;
  autocorr: double;
  meas: integer;
label
  cleanup;

  procedure getautocorr;
  var
    i,j,ii,jj: integer;
    b: tcorr;
  begin
    b:= tcorr.create;
    for i:= 1 to m.nr do begin
      ii:= rp.cell[i];
      for j:= 1 to m.nc do if (i <> j) or diagok then begin
        jj:= cp.cell[j];
        b.addcase(f.cell[ii,jj],m.cell[i,j]);
        end;
      end;
    b.calc;
    autocorr:= b.corr;
    b.destroy;
  end;

  procedure fixlabelsandprint;
  begin
    f.title:= 'Aggregated matrix';
    if (nrp*ncp) = 1
      then begin
        log.put(f.title+' = '+fstr(f.cell[1][1],0,4));
        end
      else begin
        if rl.Count > 0 then begin
          f.rdvn.copystringlist(rl);
          end;
        if cl.Count > 0 then begin
          f.cdvn.copystringlist(cl);
          end;
        f.displayasmatrix(log.stream);
        end;
      log.lf;
  end;

procedure getrowpart;
var
  i: integer;
begin
  case getpartitiontype(rowfn.text) of
    pidentity: begin
      for i:= 1 to m.nr do rp.cell[i]:= i;
      nrp:= m.nr;
      end;
    pcomplete: begin
      for i:= 1 to m.nr do rp.cell[i]:= 1;
      nrp:= 1;
      end;
    pfile: loadattr(rowfn.text,rowlabels.ItemIndex+1,1,rp,nrp);
    else raise exception.Create('Problem getting row partition.');
  end;
end;

procedure getcolpart;
var
  i: integer;
begin
  case getpartitiontype(colfn.text) of
    pidentity: begin
      for i:= 1 to m.nc do cp.cell[i]:= i;
      ncp:= m.nc;
      end;
    pcomplete: begin
      for i:= 1 to m.nc do cp.cell[i]:= 1;
      ncp:= 1;
      end;
    pfile: loadattr(colfn.text,collabels.ItemIndex+1,0,cp,ncp);
    else raise exception.Create('Problem getting col partition.');
  end;
end;

begin
try
  m:= tsmatds.create;
  rp:= tdsl.create; rpdvn:= tstrvec.create;
  cp:= tdsl.create; cpdvn:= tstrvec.create;
  f:= tsmatds.create; p:= tsmatds.create;
  sd:= tsmatds.create;
  wden:= tsmat3ds.create;
  rlab:= tstrvec.create;
  clab:= tstrvec.create;
  dvn:= tstrvec.create;
  log:= tlogfile.stdcreate('Densities or Average Tie Strengths Within/Between Groups',copyright);
  log.putfn('Input dataset: ',inputfn.text);
  log.putfn('Row partition:',rowfn.Text+' '+itemstr(rowlabels));
  log.putfn('Column partition:',colfn.text+' '+itemstr(collabels));
  log.putstr('Method:',itemstr(method));
  log.putstr('Diagonal valid?',bstr(diagonal.checked));
  log.putfn('Output matrix:',outputfn.text);
  log.lf;

  if not m.loadhdr(inputfn.text)
    then exception.Create('Unable to open dataset '+inputfn.text);
  if (matchby.itemindex = 1)
    then if not (m.rdvn.hasval and m.cdvn.hasval)
      then begin
      log.writeln('Input Matrix doesn''t have row/col labels, so matching will be done by position.');
      matchby.ItemIndex := 0;
      end;
  if not rp.allocsize(m.nr) then goto cleanup;
  if not cp.allocsize(m.nc) then goto cleanup;

  onemode:= rowfn.Text = colfn.Text;
  getrowpart;
  getcolpart;
  diagok:= (m.nr <> m.nc) or diagonal.checked;
  if cant(f.allocsize(nrp,ncp)) then goto cleanup;
  if cant(p.allocsize(nrp,ncp)) then goto cleanup;
  if cant(sd.allocsize(nrp,ncp)) then goto cleanup;
  if cant(wden.allocsize(nrp,2,m.nm)) then goto cleanup;
  f.nm:= m.nm; p.nm:= m.nm; sd.nm:= m.nm;
  f.rdvn.copy(rpdvn); f.cdvn.copy(cpdvn); f.mdvn.copy(m.mdvn);
  p.copydef(f); sd.copydef(f);
  wden.rdvn.copy(rpdvn); wden.mdvn.copy(m.mdvn);
  wden.cdvn.allocsize(2); wden.cdvn.sput(1,'Number'); wden.cdvn.sput(2,'Density');
  f.title:= 'Number of ties (sum of tie-strengths)';
  p.title:= 'Density (prop of ties or average tie strength)';
  sd.title:= 'Standard Deviations within blocks';
  wden.title:= 'Ties within each group';
  case method.ItemIndex of
    0: meas:= s_mean;
    1: meas:= s_numpos;
    2: meas:= s_max;
    3: meas:= s_min;
    4: meas:= s_sd;
    5: meas:= s_sum;
    end;

  for k:= 1 to m.nm do begin
    if cant(m.loaddat(inputfn.text)) then goto cleanup;
    valued:= m.isvalued;
    log.lf();
    if m.nm > 1
      then log.put('Relation: ' + m.mdvn.labelget(k));
    log.lf();
    if ((nrp <> 1) and (ncp <> 1)) and (m.nr < 200) and (m.nc < 200)
        then blockdisplay(log.stream,m,rp,cp,pagewidth,-1,-1,1.0,' ');
    aggbygroups(f,m,rp,cp,nrp,ncp,meas,diagok);
    fixlabelsandprint;
    f.savedat(outputfn.text);
    try
      getautocorr;
      log.put('Autocorrelation: '+fstr(autocorr,8,3));
      log.lf();
    except
    end;
  end;
  if cant(f.savehdr(outputfn.text)) then goto cleanup;

cleanup:
  log.browse;
  log.free; m.free; rp.free; cp.free; f.free; p.free; sd.free; wden.free;
  rpdvn.free; cpdvn.free; rlab.free; clab.free; dvn.free;
except
  log.browse;
  log.free; m.free; rp.free; cp.free; f.free; p.free; sd.free; wden.free;
  rpdvn.free; cpdvn.free; rlab.free; clab.free; dvn.free;
end;
end;

procedure tblockmatrix.Button1Click(Sender: TObject);
begin
  selectgroupsdlg.showmodal;
end;



procedure tblockmatrix.Button2Click(Sender: TObject);
begin
  if opentextfiledialog1.execute
    then begin
      rl.LoadFromFile(opentextfiledialog1.filename);
      if (rowfn.Text = colfn.Text)
        then cl.Assign(rl);
      end;
end;

procedure tblockmatrix.Button4Click(Sender: TObject);
begin
  if opentextfiledialog1.execute
    then cl.LoadFromFile(opentextfiledialog1.filename);
end;



procedure tblockmatrix.ColFnChange(Sender: TObject);
begin
  if (upstring(colfn.text) = 'IDENTITY') or (upstring(colfn.text) = 'COMPLETE')
    then begin collabels.visible:= false; end
    else begin
      collabels.visible:= true;
      if fileexists(hsys(colfn.text))
        then setlabels(m.cdvn,colfn.text,collabels);
      end;
end;


procedure tblockmatrix.ColLabelsChange(Sender: TObject);
begin
//  colfnchange(sender);
end;

procedure tblockmatrix.ColumnSpeedButtonClick(Sender: TObject);
begin
  stdpickopenfile(colfn);
end;


procedure tblockmatrix.FormActivate(Sender: TObject);
begin
  m:= tsmatds.create;
  if fileexists(hsys(inputfn.text)) then
    if not m.loadhdr(inputfn.text) then
      showmessage('Unable to open dataset '+filenameonly(inputfn.text));
end;



procedure tblockmatrix.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  m.free;
end;


procedure tblockmatrix.FormCreate(Sender: TObject);
begin
  rl:= tstringlist.Create;
  cl:= tstringlist.Create;
end;



procedure tblockmatrix.FormDeactivate(Sender: TObject);
begin
//  m.free;
end;

procedure tblockmatrix.FormDestroy(Sender: TObject);
begin
  rl.Free; cl.Free;
end;



procedure tblockmatrix.InputFnChange(Sender: TObject);
begin
  outputfn.Text:= outfile(inputfn.Text,'-blk');
  if fileexists(hsys(inputfn.text)) then
    if m.loadhdr(inputfn.text) then begin
      rowfn.Text:= '';
      colfn.text:= '';
      end
      else
        showmessage('Unable to open dataset '+filenameonly(inputfn.text));
end;

procedure tblockmatrix.inputfnspeedbuttonClick(Sender: TObject);
begin
  stdpickopenfile(inputfn);
end;

procedure tblockmatrix.OKBtnClick(Sender: TObject);
begin
  run;
end;


procedure Tblockmatrix.SpeedButton1Click(Sender: TObject);
begin
  stdpicksavefile(outputfn);
end;

procedure tblockmatrix.SpeedButton2Click(Sender: TObject);
begin
  rowfn.text:= 'COMPLETE';
end;

procedure tblockmatrix.SpeedButton4Click(Sender: TObject);
begin
  rowfn.text:= 'IDENTITY';
end;

procedure tblockmatrix.SpeedButton5Click(Sender: TObject);
begin
  colfn.text:= 'COMPLETE';
end;

procedure tblockmatrix.SpeedButton6Click(Sender: TObject);
begin
  colfn.text:= 'IDENTITY';
end;





end.
