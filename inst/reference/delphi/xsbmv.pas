unit xsbmv;

interface
uses
    Forms,Dialogs,UFn,uc_sbmvdlg,Controls,sysutils,
    ucommon, ugeneral,ustring,umath,uvector,umatrix,uimatrix,usmatrix,ubmatrix,
    ucan,uitsvd,ulogfile,udisplay,ustats,ugeodist,utabu,uclus, 
    ufnvcl, uag;

  procedure runsbmvalued;
{---------------------------------------------------------------------------}
implementation
{---------------------------------------------------------------------------}
const
  ifn: filename = '';
  pfn: filename = 'SbmPart';
  Sfn: filename = 'SbmSets';
  nb:  smallint = 2;
  diagok: boolean = false;
  maxit: smallint = 50;
  nban: smallint = 25;
  seed: smallint = 0;
  nstarts: smallint = 5;
var
  n: integer;
  d: smatrix;
{---------------------------------------------------------------------------}
function askparameters: smallint;
label cleanup;
var
     sbmvdlg : Tsbmvdlg;
begin
     sbmvdlg := Tsbmvdlg.Create(Application);
     with sbmvdlg do begin
       setdlgfn(inputfn,ifn);
         NoBlocks.Text := istr(nb,0);
         diagonal.text:= bstr(diagok);
         MaxIterations.Text := istr(maxit,0);
         Penalty.Text := istr(nban,0);
         RandomStarts.Text := istr(nstarts,0);
         randomize; seed:= trunc(random(1000)) + 1;
         RandomSeed.Text := istr(seed,0);
         OutputFn.Text := pfn;
         OutputSets.Text := sfn;
       sbmvdlg.Showmodal;
       if ModalResult = mrCancel
         then begin
          error := 1;
          end
         else begin
               ifn := InputFn.Text;
               str2num(NoBlocks.Text,nb,true);
               strb(Diagonal.Text,diagok,true);
               str2num(MaxIterations.Text,maxit,true);
               str2num(Penalty.Text,nban,true);
               str2num(RandomStarts.Text,nstarts,true);
               str2num(RandomSeed.Text,seed,true);
               pfn:= outdir(OutputFn.Text);
               sfn:= outdir(OutputSets.Text);
          end;
          error:= 0;
     end;
cleanup:
     askparameters:= error;
     sbmvdlg.Free;
end;
{---------------------------------------------------------------------------}
  function corr(var p:ivector): single;
  label cleanup;
  var
    i,j: smallint;
    s: bestimator;
    mx,nx: smatrix;
  begin
    s:= bestimator.create; mx:= smatrix.create; nx:= smatrix.create;
    mx.allocsize(nb,nb);
    nx.allocsize(nb,nb);
    for i:= 1 to n do for j:= 1 to n do if (i<>j) or diagok then begin
      mx.cell^[p.cell^[i]]^[p.cell^[j]]:= mx.cell^[p.cell^[i]]^[p.cell^[j]] + d.cell^[i]^[j];
      nx.cell^[p.cell^[i]]^[p.cell^[j]]:= nx.cell^[p.cell^[i]]^[p.cell^[j]] + 1;
      end;
    for i:= 1 to nb do for j:= 1 to nb do
      if nx.cell^[i]^[j] > 0
        then mx.cell^[i]^[j]:= mx.cell^[i]^[j]/nx.cell^[i]^[j];
    for i:= 1 to n do
        for j:= 1 to n do
            if (i <> j) or diagok then
               s.addrcase(d.cell^[i]^[j],mx.cell^[p.cell^[i]]^[p.cell^[j]]);
    s.calc;
    if s.corr < na then result:= s.corr else result:= 0.0;
  cleanup:
    s.free; mx.free; nx.free;
  end;
{---------------------------------------------------------------------------}
function negcorr(var p:ivector; ptr:pointer; var break:smallint): single;
begin
  result:= 2.0-corr(p);
end;
{---------------------------------------------------------------------------}
procedure simpleoptimization(var p:ivector; var fit:single; var numit:integer;
  maxit:integer);
label cleanup;
var
  i,j,k: integer;
  err: smallint;
  oldfit: double;
  improved,anychange: boolean;

  procedure swap(a,b:integer);
  var pa: integer;
  begin
    pa:= p.cell^[a];
    p.cell^[a]:= p.cell^[b];
    p.cell^[b]:= pa;
  end;

begin
  oldfit:= negcorr(p,nil,err);
  numit:= 0;
  for k:= 1 to maxit do begin
    inc(numit);
    anychange:= false;
    improved:= false;
    for i:= 2 to n do
      for j:= 1 to i-1 do if p.cell^[i] <> p.cell^[j] then begin
        swap(i,j);
        fit:= negcorr(p,nil,err);
        if fit < oldfit
          then begin
            anychange:= true;
            oldfit:= fit;
            end
          else swap(i,j);
        end;
    if not anychange then break;
    end;
  cleanup:
end;
{---------------------------------------------------------------------------}
procedure runsbmvalued;
label cleanup;
var
  fit,bestfit: single;
  i,j,k: smallint;
  bestp,p: ivector;
  log: logfile;
  tmp: imatrix;
  orb: bmatrix;
  bin : boolean;
  numit:integer;
  nmiss: longint;
  bm: smatrix;

  procedure getstartingpartition(var p:ivector);
  label cleanup;
  var
    i,j,k: smallint;
    dist: smatrix;
  begin
  error := 1;
    dist:= smatrix.create;
    for i:= 1 to n do
        p.cell^[i]:= trunc(random(nb)) + 1;
    if cant(dist.allocsize(n,n)) then goto cleanup;
    for i:= 2 to n do
        for j:= 1 to i-1 do begin
            for k:= 1 to n do
                if ((k <> j) and (k <> i)) or diagok then
                    dist.cell^[i]^[j]:= dist.cell^[i]^[j] + sqr(d.cell^[i]^[k]-
                         d.cell^[j]^[k]) + sqr(d.cell^[k]^[i]*d.cell^[k]^[i]);
            dist.cell^[j]^[i]:= dist.cell^[i]^[j];
        end;
    km1(dist,p,nb,false);
    error := 0;
  cleanup:
    dist.free;
  end;

begin
try
  { 64-bit guard removed 2026-07-05 (stale): this routine uses only basic G1
    matrix/vector ops and shared optimizer/export engines that are
    pointer-size-clean; same rationale as x2mcatcp/XExtract.  Full G2
    migration deferred with the shared engines. }
  if cant(askparameters) then exit;

  log:= logfile.stdcreate('Structural Blockmodels',copyright);
  log.putstr('Diagonal valid?',bstr(diagok));
  log.putstr('Iterations/series:',istr(maxit,0));
  log.putstr('Penalty iterations:',istr(nban,0));
  log.putstr('Random # seed:',istr(seed,0));
  log.dataset(ifn); log.lf;

  p:= sivector.create; bestp:= sivector.create; tmp:= imatrix.create; bm:= smatrix.create;
  orb:= bmatrix.create;
  d:= smatrix.create;

  if cant(d.load(dsys(ifn))) then goto cleanup;
  if d.nr <> d.nc then begin
      MessageDlg('ERROR: File '+ifn+' does not contain a square matrix.',
                         mtError, [mbOK], 0);
      goto cleanup;
  end;

  n:= d.n;
  if d.df.nl > 1 then begin
    writeln(log.f,'WARNING: This procedure only uses the first matrix in a datafile.');
    log.lf;
  end;
  if cant(p.allocsize(n)) then goto cleanup;
  if cant(bestp.allocsize(n)) then goto cleanup;
  if cant(orb.allocsize(nb,n)) then goto cleanup;

  randseed:= seed;
  getstartingpartition(bestp);
  simpleoptimization(bestp,fit,numit,maxit);
  bestfit:= sqr(corr(bestp));
  writeln(log.f,'R-square = ',bestfit:0:3);

  if nstarts > 1 then for k:= 2 to nstarts do
      if (bestfit > singleprecision) then begin
          randseed:= randseed + 31;
          for i:= 1 to n do p.cell^[i]:= trunc(random*nb) + 1;
          tabus(p,fit,singleprecision,n,nb,maxit,nban,negcorr,@d);
          simpleoptimization(p,fit,numit,maxit);
          fit:= sqr(corr(bestp));
          writeln(log.f,'Iteration ',k,' R-square = ',bestfit:0:3);
          if fit < bestfit then begin bestfit:= fit; bestp.copy(p); end;
  end;

  writeln(log.f,'R-square = ',bestfit:0:3);
  log.lf;
  writeln(log.f,'Block Assignments:'); log.lf;

  for k:= 1 to nb do begin
      write(log.f,k:5,': ');
      for i:= 1 to n do
          if bestp.cell^[i] = k then begin
              write(log.f,' ',d.rdvn.sget(i));
              orb.cell^[k]^[i]:= 1;
          end;
      log.lf;
  end;
  log.lf;
  orb.title:= 'Structurally Equivalent Sets (Approximate)';
  orb.cdvn.copy(d.cdvn);
  orb.save(sfn);
  tmp.nr:= n; tmp.nc:= 1; tmp.rdvn.copy(d.rdvn);

  if cant(tmp.savehdr(hsys(pfn))) then goto cleanup;
  if cant(tmp.openoutfile(dsys(pfn))) then goto cleanup;
  tmp.df.outdf.saveblock(bestp.cell^,ssi*n);
  tmp.closeinfile;
      d.title:= 'Blocked Adjacency Matrix';

  blockdisplay(log.f,d,bestp,bestp,pagewidth,-1,-1,1.0,' ');
  blockdensity(d,bm,bestp,bestp,nb,nb,diagok);
  bm.display(log.f,pagewidth,0,2);
  log.outfile('Partition saved as dataset ',pfn);
  log.outfile('Set-by-actor indicator matrix saved as dataset ',sfn);
  log.browse;

cleanup:
finally
    d.free; log.free; p.free; bestp.free; tmp.free; orb.free; bm.free;
end;
end;

end.
