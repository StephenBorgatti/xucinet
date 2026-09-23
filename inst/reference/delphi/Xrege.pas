unit xREGE;

interface
uses
    Forms,Dialogs, ContDlg, Controls, Waiting, sysutils,
    ucommon, ugeneral,ualloc,ustring,ufn,ucan,ubmatrix,usmatrix,urege,ugeodist,
    ukey,utlogfile,uclus, PlotClus, umsg;
{---------------------------------------------------------------------------}
function rege(var ifn:string):smallint;
{===========================================================================}
implementation
{===========================================================================}
uses ucinet;
const
  usedist: boolean = false;
  diagok: boolean = false;
  maxit: integer = 3;
  ofn: filename = 'Rege';
  pfn: filename = 'RegePart';
  one: single = 1.0;
  DType: string = 'Dendrogram';
{---------------------------------------------------------------------------}
function whichtype(s:string): smallint;
begin
  if iskey(s,'D') then whichtype:= 1
  else
      if iskey(s,'T') then whichtype:= 2
      else
          whichtype:= 0;
end;
{---------------------------------------------------------------------------}
  function askparameters(var ifn:string): integer;
  label cleanup;
  var
     ContinuousDlg : TContinuousDlg;
  begin
       ContinuousDlg := TContinuousDlg.Create(Application);
       with ContinuousDlg do begin
            if DisplayFullPathnames = true then begin
               InputFn.Text := ifn;
               InputFn.SelStart := Length(ifn);
            end
            else InputFn.Text := FnAndExt(ifn);
            MaxIteration.Text := istr(maxit,0);
            Convert.Text := bstr(usedist);
            DiagramType.Text := DType;
            OutputSim.Text := ofn;
            OutputPar.Text := pfn;
       end;
       ContinuousDlg.Showmodal;
       if ContinuousDlg.ModalResult = mrOK then begin
            with ContinuousDlg do begin
                 if strb(Convert.Text,usedist,true) <> 0 then goto cleanup;
                 if str2num(MaxIteration.Text,maxit,true) <> 0 then
                                                             goto cleanup;
                 ofn:= outdir(OutputSim.Text);
                 ifn:= InputFn.Text;
                 pfn:= outdir(OutputPar.Text);
                 DType := DiagramType.Text;
            end;
            error := 0;
            end
       else
            error := 1;
  cleanup:
       askparameters:= error;
       ContinuousDlg.Free;
  end;
{---------------------------------------------------------------------------}
function rege(var ifn:string):smallint;
var
  e:   smatrix;
  d:   smatrix;
  i,j,n: integer;
  log: tlogfile;
  berror: boolean;
label
  start,cleanup;
begin
try
start:
  {$ifdef WIN64}
    raise exception.create('This procedure is not available in the 64-bit version of UCINET.');
  {$endif}
  askparameters(ifn); if error <> 0 then exit;

  berror := true;
  d:= smatrix.create;
  e:= smatrix.create;
  log:= tlogfile.stdcreate('Regular Equivalence via White/Reitz Rege Algorithm',copyright);
  log.dataset(ifn); log.lf;

  if cant(d.loadhdr(ifn)) then goto cleanup;
  if d.nr <> d.nc then begin
      MessageDlg('ERROR: File '+ifn+' does not contain a square matrix.',
                         mtError, [mbOK], 0);
      error := 9;
      goto cleanup;
  end;

  if cant(d.alloc(d.nr,d.nc)) then goto cleanup;
  if cant(e.copydef(d)) then goto cleanup; e.df.nl:= 1;
  if cant(e.alloc(e.nr,e.nc)) then goto cleanup;
  n:= e.nr;
  for i:= 1 to n do
      for j:= 1 to n
          do e.cell^[i]^[j]:= 1;
  if cant(d.openinfile(dsys(ifn))) then goto cleanup;

  //WaitingStart('Calculating ......',0,false);
  if cant(sstdrege(d,e,maxit,usedist,diagok)) then begin
    if error = 67
      then errormsg('This routine assumes the data contain no negative values.');
      //WaitingEnd;
      goto cleanup;
  end;
  d.closeinfile;
  //WaitingEnd;

  if cant(e.save(ofn)) then goto cleanup;
  for i:= 1 to n do
      for j:= 1 to n do
          e.cell^[i]^[j]:= e.cell^[i]^[j]*100;
  e.title:= 'REGE similarities (' + istr(maxit,0) + ' iterations)';
  e.display(log.stream,pagewidth,-1,0);
  log.lf;
  if cant(runclusternew(e,log,true,averagelink,pfn,
    'Hierarchical Clustering of Equivalence Matrix',dendrochar,pagewidth)) then
      error:= 0
  else
      log.writeln('Partition-by-actor matrix saved as dataset '+pfn);
  log.writeln('Equivalence matrix saved as dataset '+ofn+'.');
  log.browse;
  if MainForm.DisplayGraphicalDendrograms1.Checked = true then
     Create_Dendrogram(pfn,false,whichtype(DType),false);
  berror := false;

cleanup:
  d.free; e.free; log.free;
  if berror then goto start;
//  ifn := ofn;
  rege := 0;
except
  log.free;
  rege := 1;
  WaitingEnd;
end;
end;
{---------------------------------------------------------------------------}
End.
