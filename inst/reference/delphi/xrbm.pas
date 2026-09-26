unit xrbm;

interface
uses
    Forms,Waiting,Dialogs,Controls,Tabu2Dlg,UFn,TestBins,sysutils,
    ucommon, ugeneral,ustring,uswap,umath,uvector,umatrix,uimatrix,usmatrix,
    ubmatrix,ucan,uitsvd,ulogfile,udisplay,ugeodist,utabu,uclus,urege,uklfm;

procedure rbm;
{---------------------------------------------------------------------------}
implementation
uses Ucinet;
{---------------------------------------------------------------------------}
const
  ifn: filename = '';
  pfn: filename = 'RBMPart';
  sfn: filename = 'RBMSets';
  nb:  smallint = 2;
  diagok: boolean = false;
  maxit: smallint = 30;
  nban: smallint = 25;
  seed: smallint = 0;
  nstarts: smallint = 30;
  cutoffval: single = 0.01;
var
  d: bmatrix;
  num: array of integer;
  row,col: array of array of array of integer;
  nrow,ncol: array of array of integer;
{---------------------------------------------------------------------------}
function askparameters: smallint;
label cleanup;
var
     TabuSearch2Dlg : TTabuSearch2Dlg;
begin
     TabuSearch2Dlg := TTabuSearch2Dlg.Create(Application);
     with TabuSearch2Dlg do begin
          if DisplayFullPathnames = true then begin
             InputFn.Text := ifn;
             InputFn.SelStart := Length(ifn);
          end
          else InputFn.Text := FnAndExt(ifn);
          NoBlocks.Text := istr(nb,0);
          Diagonal.Text := bstr(diagok);
          MaxIterations.Text := istr(maxit,0);
          Penalty.Text := istr(nban,0);
          RandomStarts.Text := istr(nstarts,0);
          randomize; seed:= trunc(random(1000)) + 1;
          RandomSeed.Text := istr(seed,0);
          CutOff.Text := fstr(cutoffval,0,3);
          OutputFn.Text := pfn;
          OutputSets.Text := sfn;
     end;
     TabuSearch2Dlg.Showmodal;
     if TabuSearch2Dlg.ModalResult = mrCancel then begin
          error := 1;
          end
     else begin
          with TabuSearch2Dlg do begin
               ifn := InputFn.Text;
               str2num(NoBlocks.Text,nb,true);
               strb(Diagonal.Text,diagok,true);
               str2num(MaxIterations.Text,maxit,true);
               str2num(Penalty.Text,nban,true);
               str2num(RandomStarts.Text,nstarts,true);
               str2num(CutOff.Text,cutoffval,true);
               str2num(RandomSeed.Text,seed,true);
               pfn:= outdir(OutputFn.Text);
               sfn:= outdir(OutputSets.Text);
          end;
          error:= 0;
     end;
cleanup:
     TabuSearch2Dlg.Free;
     askparameters:= error;
end;
{---------------------------------------------------------------------------}
function offdiagonalsum(var p:ivector; dptr:pointer; var break:smallint): single;
label cleanup;
var
  i,j: integer;
  errsum: double;
  num: array of integer;
  n: integer;
begin
  n:= p.n;
  break:=0; setlength(num,nb+1);
  errsum:= 0;
  for i:= 1 to p.n do inc(num[p.cell^[i]]);
  for i:= 1 to nb do if num[i] = 0 then begin
    errsum:= n*n; goto cleanup; end;
  for i:= 1 to p.n do
      for j:= 1 to p.n do if (i<>j) then
        if (p.cell^[i] = p.cell^[j])
          then errsum:= errsum + 1 - smatrixptr(dptr)^.cell^[i]^[j]
          else errsum:= errsum + smatrixptr(dptr)^.cell^[i]^[j];
  cleanup:
    result:= errsum; num:= nil;
end;
{---------------------------------------------------------------------------}
//function hamming(var p:sivector): double;
function hamming(var p:ivector; dptr:pointer; var break:smallint): single;
label cleanup;
var
  i,j,k,pi,pj: integer;
  cost: integer;
  n: integer;
  bsize: array of integer;
begin
  n:= p.n;
  setlength(bsize,nb+1);
  for i:= 1 to p.n do inc(bsize[p.cell^[i]]);
  for i:= 1 to nb do if bsize[i] = 0 then begin
    cost:= n*n; goto cleanup; end;
  for i:= 1 to nb do  begin
    num[i]:= 0;
    for j:= 1 to nb do begin
      nrow[i,j]:= 0;
      ncol[i,j]:= 0;
      for k:= 1 to n do begin
        row[i,j,k]:= 0;
        col[i,j,k]:= 0;
        end;
      end;
    end;
  for i:= 1 to n do begin
    pi:= p.cell^[i];
    inc(num[pi]);
    for j:= 1 to n do begin
      pj:= p.cell^[j];
      if d.cell^[i]^[j] > 0 then begin
        if row[pi,pj][i] = 0 then begin
          row[pi,pj][i]:= 1;
          inc(nrow[pi,pj]);
          end;
        if col[pi,pj][j] = 0 then begin
          col[pi,pj][j]:= 1;
          inc(ncol[pi,pj]);
          end;
        end;
      end;
    end;
  cost:= 0;
  for i:= 1 to nb do for j:= 1 to nb do begin
    cost:= cost + imin(nrow[i,j],num[i]-nrow[i,j]);
    cost:= cost + imin(ncol[i,j],num[j]-ncol[i,j]);
    end;
  cleanup:
    result:= cost; bsize:= nil;
end;
{---------------------------------------------------------------------------}
  {$F+}
  function costof(var p:ivector; dptr:pointer; var break:smallint): single;
  label cleanup;
  var
    bi,bj,i,j: smallint;
    r1,c1,tr,tc,ncells,nties: longint;
    rset,cset,trset,tcset: set of byte;
    cost: single;
  begin
    cost:= 0;
    for bi:= 1 to nb do
        for bj:= 1 to nb do begin
            rset:= []; cset:= []; trset:= []; tcset:= [];
            r1:= 0; c1:= 0; tr:= 0; tc:= 0; ncells:= 0; nties:= 0;
            for i:= 1 to p.n do
                if p.cell^[i] = bi then
                    for j:= 1 to p.n do
                        if (p.cell^[j] = bj) and ((i<>j) or diagok) then begin
                            inc(ncells);
                            if not (i in trset) then begin
                                trset:= trset + [i]; inc(tr);
                            end;
                            if not (j in tcset) then begin
                                tcset:= tcset + [j]; inc(tc);
                            end;
                            if d.cell^[i]^[j] > 0 then begin
                                inc(nties);
                                if not (i in rset) then begin
                                    rset:= rset + [i]; inc(r1);
                                end;
                                if not (j in cset) then begin
                                    cset:= cset + [j]; inc(c1);
                                end;
                            end;
                        end;
            if (ncells > 0) then
                if (nties/ncells > cutoffval) then
                    cost:= cost + tr-r1 + tc-c1
                else
                    cost:= cost + r1 + c1;
        end;
  cleanup:
    costof:= cost;
  end;
  {$F-}
{---------------------------------------------------------------------------}
procedure simpleoptimization(var p:sivector);
label cleanup;
var
  i,j,k: integer;
  numit,n,pi: integer;
  err: smallint;
  oldfit,fit: double;
  improved,anychange: boolean;
begin
  n:= p.n;
  oldfit:= hamming(p,nil,err);
  for k:= 1 to 50 do begin
    inc(numit);
    anychange:= false;
    for i:= 1 to n do begin
      pi:= p.cell^[i];
      improved:= false;
      for j:= 1 to nb do if j <> nb then begin
        p.cell^[i]:= j;
        fit:= hamming(p,nil,err);
        if fit < oldfit then begin
          improved:= true;
          oldfit:= fit;
          break;
          end;
        end;
      if not improved then p.cell^[i]:= pi else anychange:= true;
      end;
    if not anychange then break;
    end;
  cleanup:
end;
{---------------------------------------------------------------------------}
procedure rbm;
label start,cleanup;
var
  fit,bestfit: single;
  err,n,i,j,k: smallint;
  bestp,p: ivector;
  log: logfile;
  tmp: imatrix;
  orb: bmatrix;
  sym,bin: boolean;
  berror: boolean;
  numit: integer;

  procedure getstartingpartition2(var p:ivector);
  label cleanup;
  var
    r,c: svector;
    idx: dslvector;
    num,it,i,j,k: smallint;
    e: single;
  begin
    error := 1;
    r:= svector.create; idx:= dslvector.create; c:= svector.create;
    for i:= 1 to n do p.cell^[i]:= 1;
    for i:= 2 to nb do p.cell^[trunc(random(n))+1]:= i;
    if cant(r.allocsize(n)) then goto cleanup;
    if cant(c.allocsize(n)) then goto cleanup;
    if cant(idx.allocsize(n)) then goto cleanup;
    itsvd(d,r.cell^,c.cell^,e,it,false,25);
    r.sort('a',@idx);
    num:= n div nb;
    k:= 0;
    for i:= 1 to nb do
        for j:= 1 to num do begin
            inc(k); p.cell^[idx.cell^[k]]:= i;
        end;
    if k < n then
        for i:= k+1 to n do
            p.cell^[idx.cell^[i]]:= trunc(random(nb))+1;
    for i:= 1 to n do
        if not (p.cell^[i] in [1..nb]) then
            p.cell^[i]:= 1;
    error := 0;
  cleanup:
    r.free; idx.free; c.free;
  end;

  procedure getstartingpartition(var p:ivector);
  label cleanup;
  var
    i,j: integer;
    d2,e: smatrix;
    miss: integer;
    err: smallint;
    efit: single;
  begin
    e:= smatrix.create; d2:= smatrix.create;
    for i:= 1 to n do p.cell^[i]:= trunc(random(nb)) + 1;
    writeln(log.f,'1. Number of errors: ',hamming(p,nil,err):0:3);
    if cant(d2.loadhdr(ifn)) then goto cleanup;;
    if cant(e.allocsize(n,n)) then goto cleanup;
    if cant(d2.openinfile(ifn)) then goto cleanup;
    for i:= 1 to n do for j:= 1 to n do e.cell^[i]^[j]:= 1.0;
    sstdrege(d2,e,3,false,false);
    err:=tabus(p,efit,singleprecision,n,nb,15,7,offdiagonalsum,@e);
    writeln(log.f,'2. Number of errors: ',hamming(p,nil,err):0:3);
    cleanup:
      e.free; d2.free; d.closeinfile;
  end;

begin
try
start:
  { 64-bit guard removed 2026-07-05 (stale): this unit already mixes G1 basic
    ops with G2 units and/or uses shared engines (uclus/utabu/ugenetic/usvd/
    ubetween/udsl) that are pointer-size-clean and proven by unguarded,
    64-bit-working routines.  Full G2 migration deferred with those engines. }
  if cant(askparameters) then exit;

  berror := true;
  log:= logfile.stdcreate('Regular Blockmodels via Tabu Search',copyright);
  log.putstr('Number of blocks:',istr(nb,0));
  log.putstr('Diagonal valid?',bstr(diagok));
  log.putstr('Iterations/series:',istr(maxit,0));
  log.putstr('Penalty iterations:',istr(nban,0));
  log.putstr('Random # seed:',istr(seed,0));
  log.dataset(ifn); log.lf;

  d:= bmatrix.create; p:= ivector.create; bestp:= ivector.create; tmp:= imatrix.create; orb:= bmatrix.create;
  err := 0;
  if cant(d.load(ifn)) then goto cleanup;
  if d.nr <> d.nc then begin
      MessageDlg('ERROR: File '+ifn+' does not contain a square matrix.',
                         mtError, [mbOK], 0);
      error := 9;
      goto cleanup;
  end;

  n:= d.n;
  if d.df.nl > 1 then begin
      writeln(log.f,'WARNING: This procedure only uses the first matrix in ',
                              'a datafile.');
      log.lf;
  end;
  bin:= true;
  for i:= 1 to n do
      for j:= 1 to n do
          if (i <> j) or diagok then
              if d.cell^[i]^[j] > 1 then begin
                  bin:= false; d.cell^[i]^[j]:= 1;
              end;
  if not bin then begin
      if DataCheck then
          MessageDlg('Warning: File '+ifn+' should contain only binary values.',
                         mtWarning, [mbOK], 0);
      writeln(log.f,'WARNING: Data binarized by recoding all values greater ',
                              'than zero to 1.');
      log.lf;
  end;

  if cant(p.allocsize(n)) then goto cleanup;
  if cant(bestp.allocsize(n)) then goto cleanup;
  if cant(orb.allocsize(nb,n)) then goto cleanup;
  setlength(num,nb+1);
  setlength(row,nb+1);
  for i:= 1 to nb do setlength(row[i],nb+1);
  for i:= 1 to nb do for j:= 1 to nb do setlength(row[i,j],n+1);
  setlength(col,nb+1);
  for i:= 1 to nb do setlength(col[i],nb+1);
  for i:= 1 to nb do for j:= 1 to nb do setlength(col[i,j],n+1);
  setlength(nrow,nb+1);
  for i:= 1 to nb do setlength(nrow[i],nb+1);
  setlength(ncol,nb+1);
  for i:= 1 to nb do setlength(ncol[i],nb+1);
  randseed:= seed;

  getstartingpartition(bestp);
//  bestfit:= hamming(bestp);
  bestfit:= hamming(bestp,@d,err);
  Writeln(log.f,'Initial Partition');
  writeln(log.f,'Number of errors: ',bestfit:0:0);
  simpleoptimization(bestp);
//  klfm2(pa,pb,bestfit,hamming,1,n);
  bestfit:= hamming(bestp,@d,err);
  Writeln(log.f,'Initial Partition');
  writeln(log.f,'Number of errors: ',bestfit:0:0);
  writeln(log.f);

  writeln(log.f,'Iterations:');
  for k:= 1 to nstarts do if (bestfit > 0) then begin
      randseed:= randseed + 31;
      for i:= 1 to n do p.cell^[i]:= trunc(random*nb)+1;
      err:=tabus(p,fit,singleprecision,n,nb,maxit,nban,hamming,@d);
      simpleoptimization(p);
      fit:= hamming(p,@d,err);
      writeln(log.f,'  No. of errors: ',fit:0:0);
      if fit < bestfit then begin bestfit:= fit; bestp.copy(p); end;
  end;
  writeln(log.f);
  writeln(log.f,'RESULTS:');
  writeln(log.f,'  No. of errors: ',bestfit:0:3); log.lf;
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
  orb.title:= 'Regularly Equivalent Sets (Approximate)';
  orb.cdvn.copy(d.cdvn);
  orb.save(sfn);

  tmp.nr:= n; tmp.nc:= 1; tmp.rdvn.copy(d.rdvn);
  if cant(tmp.savehdr(hsys(pfn))) then goto cleanup;
  if cant(tmp.openoutfile(dsys(pfn))) then goto cleanup;
  tmp.df.outdf.saveblock(bestp.cell^,ssi*n); tmp.closeoutfile;

  d.title:= 'Blocked Adjacency Matrix';
  blockdisplay(log.f,d,bestp,bestp,pagewidth,-1,-1,1.0,' ');
  log.outfile('Partition saved as dataset ',pfn);
  log.outfile('Role-by-actor indicator matrix saved as dataset ',sfn);

  log.browse;
  berror := false;
cleanup:
  orb.free; tmp.free; bestp.free; p.free; d.free; log.free;
  if berror then goto start;
//  ifn := pfn;
except
  log.free;
end;
end;

End.
