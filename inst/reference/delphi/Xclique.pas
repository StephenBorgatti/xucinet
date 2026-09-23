unit xCLIQUE;
interface
uses
    math, Forms, Dialogs, Controls, CliqDlg, PlotClus, TestBins,
    ucommon, ugeneral,ualloc,ustring,uufile,ufn,ucan,uvector,usmatrix,ubmatrix,
    ukey,usimatrix,uclique,uclus,udendro,ulogfile,xclqtool,udiam,
    utsmatds, utadjlist, ug2display;
{---------------------------------------------------------------------------}
procedure cliques(var ifn:string);
{===========================================================================}
implementation
uses Ucinet;
{===========================================================================}
const
  ofn: filename = 'CliqueSets';
  vfn: filename = 'CliqueOverlap';
  pfn: filename = 'CliquePart';
  v2fn: filename = 'Clique-by-cliqueOverlap';
  p2fn: filename = 'Clique-by-partition';
  membfn: filename = 'CliqueParticipation';
  overlaps: boolean = true;
  nn: smallint = 2;
  m: smallint = 3;
  DType: string = 'Tree Diagram';
  cliquetype: integer = 1;
var
  d: bmatrix;
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
function askclique(var ifn:string): smallint;
label cleanup;
var
  s:  filename;
  CliqueDlg : TCliqueDlg;
 begin
     CliqueDlg := TCliqueDlg.Create(Application);
     with CliqueDlg do begin
          if DisplayFullPathnames = true then begin
             InputFn.Text := ifn;
             InputFn.SelStart := Length(ifn);
          end
          else InputFn.Text := FnAndExt(ifn);
          MinSize.Text := istr(m,0);
          Analyse.Text := bstr(overlaps);
          OutputClique.Text := ofn;
          DiagramType.Text := DType;
          if overlaps then s:= vfn else s:= 'NONE';
          OutputCo.Text := s;
          if overlaps then s:= pfn else s:= 'NONE';
          OutputPar.Text := s;
          outputprox.text:= membfn;
          symmet.itemindex:= cliquetype;
     end;
     CliqueDlg.Showmodal;
     if CliqueDlg.ModalResult = mrOK then begin
          with CliqueDlg do begin
               ifn := InputFn.Text;
               ofn := outdir(OutputClique.Text);
               if str2num(MinSize.Text,m,true) <> 0 then goto cleanup;
               if strb(Analyse.Text,overlaps,true) <> 0 then goto cleanup;
               if overlaps then begin
                   vfn:= outdir(OutputCo.Text);
                   pfn:= outdir(OutputPar.Text);
               end;
               cliquetype:= symmet.itemindex;
               membfn:= outputprox.text;
               DType := DiagramType.Text;
               error := 0;
          end;
     end;
     if CliqueDlg.ModalResult = mrCancel then error := 1;
cleanup:
     CliqueDlg.Free;
     askclique:= error;
end;
{---------------------------------------------------------------------------}
procedure cliques(var ifn:string);
var
  ov:  smatrix;
  lerror,k,i,j,jj,n: integer;
  log: logfile;
  num: longint;
  bin,sym: boolean;
  x:   integer;
  berror: boolean;
  ties2clique: integer;
  cliquemembers: tadjlist;
  membprop: tsmatds;
  dij,dji: integer;
label
  start,cleanup;
begin
try
start:
  if cant(askclique(ifn)) then exit;

  berror := true;
  log:= logfile.stdcreate('Cliques','ucinet');
  log.putstr('Minimum Set Size:',istr(m,0));
  log.dataset(ifn); log.lf;

  d:= bmatrix.create;
  ov:= smatrix.create;
  cset:= bmatrix.create;
  membprop:= tsmatds.create;
  cliquemembers:= tadjlist.create;
  lerror := 9;
  if cant(d.load(ifn)) then goto cleanup;

  if d.nr <> d.nc then begin
      MessageDlg('ERROR: File '+ifn+' does not contain a square matrix.',
                         mtError, [mbOK], 0);
      goto cleanup;
  end;

  n:= d.n;
  if d.checkbinsym(bin,sym,false) <> 0 then goto cleanup;
  if DataCheck then begin
     if not bin then begin
         writeln(log.f,'WARNING: Valued graph. All values > 0 treated as 1');
     end;
  end;
  
  lerror := 0;
  for i:= 2 to d.n do begin
    for j:= 1 to i-1 do begin
      if (d.cell^[i]^[j] > 0) and (d.cell^[i]^[j] <= na)
        then dij:= 1
        else dij:= d.n;
      if (d.cell^[j]^[i] > 0) and (d.cell^[j]^[i] <= na)
        then dji:= 1
        else dji:= d.n;
      case cliquetype of
        0: begin // strong cliques
             d.cell^[i]^[j]:= max(dij,dji);
             d.cell^[j]^[i]:= d.cell^[i]^[j];
             end;
        1: begin // weak cliques
             d.cell^[i]^[j]:= min(dij,dji);
             d.cell^[j]^[i]:= d.cell^[i]^[j];
             end;
        end;
      end;
  end;

  if cant(cset.allocsize(n,n*2)) then goto cleanup;
  mainform.memo1.lines.add('Starting to extract cliques.');
  if (bronkerbosch(saveclique,d,num,1,32767,m) <> 0) then goto cleanup;
  mainform.memo1.lines.add('Cliques extracted.');
  cset.nc:= num;
  cset.rdvn.copy(d.rdvn);
  cset.save(ofn);

  writeln(log.f,num,' cliques found.'); log.lf;
  if not cliquemembers.allocsize(num,d.nc) then goto cleanup;
  if not membprop.allocsize(d.nc,num) then goto cleanup;

  for i:= 1 to num do begin
      write(log.f,i:4,': ');
      for j:= 1 to d.nc do
          if cset.cell^[j]^[i] = 1 then begin
              write(log.f,' ',d.cdvn.lget(j));
              cliquemembers.addarc(i,j);
              end;
      writeln(log.f);
  end;

  for i:= 1 to d.nc do d.cell^[i]^[i]:= 1;
  for k:= 1 to num do begin
    for i:= 1 to d.nc do begin
      ties2clique:= 0;
      for j:= 1 to cliquemembers[k,0] do begin
        jj:= cliquemembers.cell[k,j];
        if d.cell^[i]^[jj] = 1 then inc(ties2clique);
        end;
      membprop.cell[i,k]:= 1.0*ties2clique/cliquemembers[k,0];
      end;
    end;
  membprop.title:= 'Clique Participation Scores: Prop. of clique members that each node is adjacent to';
  if d.rdvn.hasval then if membprop.rdvn.allocsize(d.nc) then
    for i:= 1 to d.nc do membprop.rdvn[i]:= d.rdvn.sget(i);
  if d.nc <= displaysize then
    display(log.f,membprop,pagewidth,0,3);
  membprop.save(membfn);

  if overlaps then begin
     if cant(ov.copydef(d)) then goto cleanup;
     ov.title:= 'Actor-by-Actor Clique Co-Membership Matrix';
     if can(ov.allocsize(d.n,d.n)) then begin
       constructoverlapmatrix(cset,ov);
       if clusteroverlaps(ov,log,vfn,pfn) <> 0 then goto cleanup;
       log.put('Actor-by-Actor Clique Co-Membership Matrix is no longer displayed, but it is saved on disk');
       end
     else begin
       writeln(log.f,'Unable to run cluster analysis due to lack of memory.');
       log.lf;
       end;
  end;
  log.lf;
  writeln(log.f,'Group indicator matrix saved as dataset ',ofn);
  if overlaps and (error = 0) then begin
      writeln(log.f,'Actor-by-Actor clique co-membership matrix saved as dataset ',vfn);
      writeln(log.f,'Clique co-membership partition-by-actor indicator matrix ',
                            'saved as dataset ',pfn);
  end;

  if overlaps and (cset.nc > 1) and (cset.nc <= 5000) then begin
    ov.rdvn.dealloc; ov.cdvn.dealloc;
    if can(ov.allocsize(cset.nc,cset.nc)) then begin
       ov.title:= 'Clique-by-Clique Actor Co-membership matrix';
       for i:= 1 to ov.nr do for j:= 1 to i do
         for k:= 1 to n do if (cset.cell^[k]^[i]=1) and (cset.cell^[k]^[j]=1)
           then begin
             ov.cell^[i]^[j]:= ov.cell^[i]^[j] + 1;
             ov.cell^[j]^[i]:= ov.cell^[j]^[i] + 1;
             end;
       for i:= 1 to ov.nr do ov.cell^[i]^[i]:= ov.cell^[i]^[i]/2.0;
       clusteroverlaps(ov,log,v2fn,p2fn,2);
       end;
    log.lf;
    if overlaps and (error = 0) then begin
      writeln(log.f,'Clique-by-Clique co-membership matrix saved as dataset ',v2fn);
      writeln(log.f,'Clique by clustering partition matrix saved as dataset ',p2fn);
      end;
    end;

  if MainForm.DisplayGraphicalDendrograms1.Checked = true then
     if overlaps then Create_Dendrogram(pfn,false,whichtype(DType),false);
  berror := false;

cleanup:
  log.browse;
  d.free; log.free; ov.free; cset.free; membprop.destroy; cliquemembers.destroy;
  if berror then goto start;
//  ifn := ofn;
except
  log.browse;
  log.free;
end;
end;
{---------------------------------------------------------------------------}
End.
