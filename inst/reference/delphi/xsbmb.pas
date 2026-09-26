unit xsbmb;

interface
uses
    sysutils, windows, Forms,Dialogs,UFn,ufnvcl, uc_sbmbdlg,Controls,Waiting,
    ucommon, ugeneral,ustring,umath,uvector,umatrix,usimatrix,usmatrix,ubmatrix,
    ucan,uitsvd,ulogfile,udisplay,ustats,ugeodist,utabu,uclus, uag;

  procedure runsbmbinary;
{---------------------------------------------------------------------------}
implementation
{---------------------------------------------------------------------------}
const
  ifn: filename = '';
  pfn: filename = 'SbmPart';
  Sfn: filename = 'SbmSets';
  nb:  integer = 2;
  diagok: boolean = false;
  usedist: boolean = false;
  maxit: smallint = 50;
  nban: smallint = 25;
  seed: smallint = 0;
  nstarts: smallint = 5;
var
  ones,cells: array of array of integer;
  d: smatrix;
  n: integer;
{---------------------------------------------------------------------------}
  function rsquare(var p:ivector): double;
  label cleanup;
  var
    bi,bj,i,j: smallint;
    s: bestimator;
    mx: smatrix;
  begin
    s:= bestimator.create; mx:= smatrix.create;
    mx.allocsize(nb,nb);
    for i:= 1 to nb do for j:= 1 to nb do
      if cells[i,j] > 0 then mx.cell^[i]^[j]:= 1.0*ones[i,j]/cells[i,j];
    for i:= 1 to n do
        for j:= 1 to n do
            if (i <> j) or diagok then
               s.addrcase(d.cell^[i]^[j],mx.cell^[p.cell^[i]]^[p.cell^[j]]);
    s.calc;
    if s.corr < na then result:= sqr(s.corr) else result:= 0;
  cleanup:
    s.free; mx.free;
  end;
{---------------------------------------------------------------------------}
function askparameters: smallint;
label cleanup;
var
     sbmbdlg : Tsbmbdlg;
begin
     sbmbdlg := Tsbmbdlg.Create(Application);
     with sbmbdlg do begin
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
       sbmbdlg.Showmodal;
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
            error:= 0;
          end;
     end;
cleanup:
     askparameters:= error;
     sbmbdlg.Free;
end;
{---------------------------------------------------------------------------}
function hammingdistance(var p:ivector; dummy:pointer; var break:smallint): single;
var
  i,j,pi,pj: integer;
  cost: integer;
begin
  for pi:= 1 to nb do for pj:= 1 to nb do begin
    ones[pi,pj]:= 0;
    cells[pi,pj]:= 0;
    end;
  for i:= 1 to n do begin
    pi:= p.cell^[i];
    for j:= 1 to n do if i<>j then begin
      pj:= p.cell^[j];
      if d.cell^[i]^[j] > 0 then inc(ones[pi,pj]);
      inc(cells[pi,pj]);
      end;
    end;
  cost:= 0;
  for pi:= 1 to nb do
    for pj:= 1 to nb do begin
      cost:= cost + imin(ones[pi,pj],cells[pi,pj]-ones[pi,pj]);
      end;
  result:= cost;
end;
{---------------------------------------------------------------------------}
procedure simpleoptimization(var p:ivector; var fit:single; var numit:integer;
  maxit:integer);
label cleanup;
var
  i,j,k: integer;
  n,pi: integer;
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
  n:= p.n;
  oldfit:= hammingdistance(p,nil,err);
  numit:= 0;
  for k:= 1 to maxit do begin
    inc(numit);
    anychange:= false;
    improved:= false;
    for i:= 2 to n do
      for j:= 1 to i-1 do if p.cell^[i] <> p.cell^[j] then begin
        swap(i,j);
        fit:= hammingdistance(p,nil,err);
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
procedure runsbmbinary;
label start,cleanup;
var
  fit,bestfit: single;
  err,i,j,k: smallint;
  bestp,p: ivector;
  orb,errors: simatrix;
  log: logfile;
  tmp: simatrix;
  bm: smatrix;
  numit:integer;

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
  { 64-bit guard removed 2026-07-05 (stale): this routine uses only basic G1
    matrix/vector ops and shared optimizer/export engines that are
    pointer-size-clean; same rationale as x2mcatcp/XExtract.  Full G2
    migration deferred with the shared engines. }
  if cant(askparameters) then exit;
try
  log:= logfile.stdcreate('Structural Blockmodels',copyright);
  log.putstr('Diagonal valid?',bstr(diagok));
  log.putstr('Iterations/series:',istr(maxit,0));
  log.putstr('Penalty iterations:',istr(nban,0));
  log.putstr('Random # seed:',istr(seed,0));
  log.dataset(ifn); log.lf;

  p:= ivector.create; bestp:= ivector.create; tmp:= simatrix.create; orb:= simatrix.create;
  errors:= simatrix.create; d:= smatrix.create;
  bm:= smatrix.create;

  if cant(d.load(ifn)) then
    raise exception.create('Unable to load file ' + ifn);
  if d.nr <> d.nc then begin
      MessageDlg('ERROR: File '+ifn+' does not contain a square matrix.',
                         mtError, [mbOK], 0);
      err := 9;
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
  if cant(errors.allocsize(nb,nb)) then goto cleanup;
  setlength(ones,nb+1); for i:= 1 to nb do setlength(ones[i],nb+1);
  setlength(cells,nb+1); for i:= 1 to nb do setlength(cells[i],nb+1);

  randseed:= seed;
  getstartingpartition(bestp);
  simpleoptimization(bestp,fit,numit,maxit);
  log.lf;
  writeln(log.f,'Initial partition');
  log.lf;
  bestfit:= hammingdistance(bestp,@d,err);
  writeln(log.f,'Number of errors: ',bestfit:0:0);
  writeln(log.f,'R-square = ',rsquare(bestp):0:3);

  if nstarts > 1 then for k:= 2 to nstarts do
      if (bestfit > singleprecision) then begin
          randseed:= randseed + 31;
          for i:= 1 to n do p.cell^[i]:= trunc(random*nb)+1;
          tabus(p,fit,singleprecision,n,nb,maxit,nban,hammingdistance,@d);
          simpleoptimization(p,fit,numit,maxit);
          fit:= hammingdistance(p,@d,err);
          writeln(log.f,'Iteration ',k,' Number of errors: ',hammingdistance(p,@d,err):0:0);
          if fit < bestfit then begin bestfit:= fit; bestp.copy(p); end;
  end;
  writeln(log.f);
  Writeln(log.f,'Results');
  log.lf;
  writeln(log.f,'Number of errors: ',hammingdistance(bestp,@d,err):0:0);
  writeln(log.f,'R-square = ',rsquare(bestp):0:3);
  for i:= 1 to nb do for j:= 1 to nb do
    errors.cell^[i]^[j]:= imin(ones[i,j],cells[i,j]-ones[i,j]);
  errors.title:= 'Errors per block';
  errors.display(log.f,pagewidth,-1,0);
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
    d.free; log.free; p.free; bestp.free; tmp.free; orb.free; errors.free;
    bm.free;
    if ones <> nil then for i:= 1 to nb do ones[i]:= nil; ones:= nil;
    if ones <> nil then for i:= 1 to nb do cells[i]:= nil; cells:= nil;
end;
end;


End.
