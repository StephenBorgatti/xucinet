unit xbipart;

(* Convert a 2-mode matrix to its bipartite 1-mode representation.
   GUI: Transform > Bipartite (bipartite proc, called from ucinet.pas).
   Ported 2026-07-05 from smatrix (G1, 32-bit only) to tsmatds (G2) for the
   64-bit build; WIN64 guard removed, logfile -> tlogfile.  Logic unchanged:
   Y = [F  X; X' F] (or F in the lower-left when not symmetrizing), where F is
   the fill value.  Reads the first matrix of the dataset, as before. *)

interface
uses
  Forms, sysutils, Dialogs, Controls, bipdlg,
  ucommon, ugeneral, ustring, ucan, utlogfile, utsmatds, uFN, ufnvcl;

  procedure bipartite(var defaultfn:string);
{---------------------------------------------------------------------------}
implementation
{---------------------------------------------------------------------------}
const
  ifn: string = '';
  ofn: filename = 'bi';
  fillvalue: single = 0.0;
  sym: boolean = true;
  dslstr: string = 'All';
  rprefix: string = '';
  cprefix: string = '';
{---------------------------------------------------------------------------}
function askparameters(var defaultfn:string): smallint;
label cleanup;
var
  bipartitedlg: TbipartiteDlg;
begin
     bipartiteDlg := TbipartiteDlg.Create(Application);
     with bipartiteDlg do begin
          if fillvalue > na then
            fvalue.text := 'MISSING'
            else fvalue.text := fstr(fillvalue,0,6);
          if sym then symstr.text:= 'Yes' else symstr.text:= 'No';
          rprefix.text:= xbipart.rprefix;
          cprefix.text:= xbipart.cprefix;
          OutputFn.Text := ofn;
          setdlgifn(inputfn,ifn,ofn);
     end;
     bipartitedlg.Showmodal;
     if bipartitedlg.ModalResult = mrOK then begin
          with bipartitedlg do begin
               ifn := InputFn.Text;
               ofn := outdir(Outputfn.Text);
               xbipart.rprefix:= rprefix.text;
               xbipart.cprefix:= cprefix.text;
               if str2num(fvalue.Text,fillvalue,true) <> 0 then goto cleanup;
               if strb(symstr.text,sym,true) <> 0 then goto cleanup;
               error := 0;
          end;
     end;
     if bipartitedlg.ModalResult = mrCancel then error := 1;
cleanup:
     bipartitedlg.Free;
     askparameters:= error;
end;
{---------------------------------------------------------------------------}
procedure bipartite(var defaultfn:string);
label
  start,cleanup;
var
  log: tlogfile;
  d,y: tsmatds;
  i,j,yn: integer;
  berror: boolean;
begin
try
start:
  if cant(askparameters(defaultfn)) then exit;

  berror:= true;
  log:= tlogfile.stdcreate('Convert 2-mode to Bipartite 1-mode Representation','');
  log.dataset(ifn); log.lf;

  d:= tsmatds.create; y:= tsmatds.create;
  if not d.loadhdr(ifn) then goto cleanup;
  if not d.loaddat then goto cleanup;
  yn:= d.nr+d.nc;
  y.allocate(yn,yn,1,true,true);
  {top left}
  for i:= 1 to d.nr do for j:= 1 to d.nr do
    y.cell[i,j]:= fillvalue;
  {bottom right}
  for i:= 1 to d.nc do for j:= 1 to d.nc do
    y.cell[i+d.nr,j+d.nr]:= fillvalue;
  {top right}
  for i:= 1 to d.nr do for j:= 1 to d.nc do
    y.cell[i,j+d.nr]:= d.cell[i,j];
  {bottom left}
  if sym
    then for i:= 1 to d.nc do for j:= 1 to d.nr do
      y.cell[i+d.nr,j]:= d.cell[j,i]
    else for i:= 1 to d.nc do for j:= 1 to d.nr do
      y.cell[i+d.nr,j]:= fillvalue;

  y.alloclabels;
  for i:= 1 to d.nr do
    y.rdvn.sput(i,rprefix+d.rdvn.sget(i));
  for j:= 1 to d.nc do
    y.rdvn.sput(j+d.nr,cprefix+d.cdvn.sget(j));
  y.cdvn.copy(y.rdvn);
  y.save(ofn);
  y.displayasmatrix(log.stream);
  log.lf;
  log.browse;
  berror:= false;
  defaultfn:= ofn;

cleanup:
    d.free; y.free; log.free;
    if berror then goto start;
except
    d.free; y.free; log.free;
end;
end;

end.
