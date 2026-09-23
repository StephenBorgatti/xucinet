unit x2mcatcp;

interface
uses
  classes, Forms,Dialogs, Controls, math, sysutils,
  d2mcatcpdlg, Waiting, UFn,ufnvcl,
  ucommon, ugeneral,ustring,umath,uvector,umatrix,uimatrix,ubmatrix,usmatrix,
  ucan,utlogfile,udisplay,ustats,ukey,uvecio,uclus,ugenetic,uag,
  xtools, uc_2modecatcp;
{---------------------------------------------------------------------------}
procedure run2modecategoricalcp;
{---------------------------------------------------------------------------}
implementation
{---------------------------------------------------------------------------}
const
  ifn: filename = '';
  rpfn: filename = 'rowCPpart';
  cpfn: filename = 'colCPpart';
  Sfn: filename = 'CoreClasses';
  nb:  integer  = 2;
  maxit: integer = 2000;
  popsize: integer = 500;
  stopafter: integer = 2;
  auxgen: integer = 6;
  simstr: string[20] = 'Positive';
  diagok: boolean = false;
  c2p: extended = bna;
  algstr: string[10] = 'CORR';
var
  sims: boolean;
{---------------------------------------------------------------------------}
function askparameters: integer;
begin
   twomodecatcp.Showmodal;
   result:= 1;
   if twomodecatcp.ModalResult = mrOK then begin
     result:= 0;
     ifn:= allbutext(twomodecatcp.ifn.text);
     rpfn:= outfile(twomodecatcp.rfn.Text);
     cpfn:= outfile(twomodecatcp.cfn.Text);
     maxit:= strtointdef(twomodecatcp.maxiterations.Text,1000);
     popsize:= strtointdef(twomodecatcp.populationsize.Text,1000);
     stopafter:= strtointdef(twomodecatcp.StopAfter.Text,2);
     auxgen:= strtointdef(twomodecatcp.AuxiliaryGens.Text,6);
     end;
end;
{---------------------------------------------------------------------------}
(* function psclusters(var f:text; var p:sivector; nb:integer;
  var dvn:lvector; sfn:filename): integer;
{print clusters and create indicator matrix if allocated}
label cleanup;
var
  i,k: integer;
  savefile: boolean;
  orb: bmatrix;
begin
  orb.init;
  savefile:= sfn <> '';
  if savefile then
      if orb.allocsize(nb,p.n) <> 0 then goto cleanup;

  writeln(f,'Core/Periphery Class Memberships:'); writeln(f);
  writeln(f,'Row Items'); writeln(f);
  for k:= 1 to nrb do begin
      write(f,k:5,': ');
      for i:= 1 to rp.n do
          if rp.cell^[i] = k then begin
              write(f,' ',d.rdvn.sget(i));
              if savefile then orb.cell^[k]^[i]:= 1;
          end;
      writeln(f);
  end;
  writeln(f);

  if savefile then begin
      orb.title:= 'Core/Periphery classes'; orb.cdvn.copy(dvn);
      orb.save(sfn);
  end;
cleanup:
  orb.free; psclusters:= error;
end; *)
{---------------------------------------------------------------------------}
function corrfit(var p:smallintvector; d:pointer): double;
{data are similarities}
var
  nr,nc,r1,c1,i,j: integer;
  expect: extended;
  b: bestimator;
begin
     b:= bestimator.create; nr:= smatrixptr(d)^.nr; nc:= smatrixptr(d)^.nc;
     r1:= 0; c1:= 0;
     for i:= 1 to nr do if p[i] = 1 then inc(r1);
     for i:= 1 to nc do if p[nr+i] = 1 then inc(c1);
     if (r1 < 3) or (r1 > nr-3) or (c1 < 3) or (c1 > nc-3)
       then result:= 0
       else begin
         for i:= 1 to nr do
           for j:= 1 to nc do begin
             if (p[i]=1) and (p[nr+j]=1)
               then expect:= 1
               else if (p[i]<>1) and (p[nr+j]<>1)
                 then expect:= 0
                 else expect:= c2p;
             b.addcase(expect,smatrixptr(d)^.cell^[i]^[j]);
             end;
         b.calc;
         result:= fmax(b.corr,0);
         result:= (b.corr + 1)/2.0;  //don't want negative values
         end;
     b.free;
end;
{---------------------------------------------------------------------------}
function getrsqr(var bestp:sivector; var d:smatrix): extended;
begin
     getrsqr:= sqr(2*corrfit(bestp.cell^,@d)-1);
end;
{---------------------------------------------------------------------------}
procedure initialpartition(var p:sivector; var d:smatrix);
label cleanup;
var
  n,i,j: integer;
  rs,cs: svector;
  rid,cid: dslvector;
begin
     rs:= svector.create; cs:= svector.create; rid:= dslvector.create; cid:= dslvector.create;
     if cant(rs.allocsize(d.nr)) then goto cleanup;
     if cant(cs.allocsize(d.nc)) then goto cleanup;
     if cant(rid.allocsize(d.nr)) then goto cleanup;
     if cant(cid.allocsize(d.nc)) then goto cleanup;
     for i:= 1 to d.nr do
       for j:= 1 to d.nc do
         if (i<>j) or diagok then begin
           rs.cell^[i]:= rs.cell^[i] + d.cell^[i]^[j];
           cs.cell^[j]:= cs.cell^[j] + d.cell^[i]^[j];
           end;
     rs.sort('d',@rid); cs.sort('d',@cid);
     for i:= 1 to d.nr+d.nc do p.cell^[i]:= 2;
     for i:= 1 to d.nr div 3 do p.cell^[rid.cell^[i]]:= 1;
     for i:= 1 to d.nc div 3 do p.cell^[d.nr+cid.cell^[i]]:= 1;
cleanup:
     rs.free; cs.free; rid.free; cid.free;
end;
{---------------------------------------------------------------------------}
procedure run2modecategoricalcp;
label cleanup;
var
  n,nr,nc,i,j: integer;
  p: sivector;
  rp,cp: dslvector;
  log: tlogfile;
  d,den: smatrix;
  fitness: genfunc;
  fit: double;
begin
  { 64-bit guard removed 2026-07-05 (stale): uses basic smatrix cell ops, the
    ugenetic GA engine (smallint vectors + object-reference callbacks — all
    pointer-size-clean), and stream-based blockdisplay/tlogfile.  Full G2
    migration deferred with the shared ugenetic engine. }
  if cant(askparameters) then exit;

  error := 0;
  log:= tlogfile.stdcreate('2-Mode Categorical Core/Periphery Model',copyright);
  log.dataset(ifn);
  log.putfn('Output row partition:',rpfn);
  log.putfn('Output column partition:',cpfn);
  log.lf;

  d:= smatrix.create; p:= sivector.create; rp:= dslvector.create; cp:= dslvector.create; den:= smatrix.create;
  if cant(d.load(ifn)) then goto cleanup;
  nr:= d.nr; nc:= d.nc; n:= nr+nc;
  if cant(p.allocsize(n)) then goto cleanup;
  if cant(rp.allocsize(nr)) then goto cleanup;
  if cant(cp.allocsize(nc)) then goto cleanup;

  for i:= 1 to d.nr do for j:= 1 to d.nc do
    if d.cell^[i]^[j] >= na then d.cell^[i]^[j]:= 0;
  fitness:= corrfit;

  randomize;
//  for i:= 1 to n do p.cell^[i]:= random(2) + 1;
  initialpartition(p,d);
  fit:= fitness(p.cell^,@d);
  log.writeln('Starting fitness: '+fstr(2*fit-1,0,3));
  d.title:= 'Initial partition';
  for i:= 1 to nr do rp.cell^[i]:= p.cell^[i];
  for j:= 1 to nc do cp.cell^[j]:= p.cell^[j+nr];
//  blockdisplay(log.stream,d,rp,cp,maxint,-1,-1,1.0,' ');

  genetic2(p,fit,fitness,@d,0.025,1.0,nr,nc,2,2,maxit,popsize,stopafter);
  log.writeln('Number of generations: '+ istr(numgen));
  greedy(p,fit,fitness,@d,1.0,nr,nc,auxgen);
  fit:= fitness(p.cell^,@d);
  log.writeln('Final fitness: '+fstr(2*fit-1,0,3));
  log.writeln('Number of auxiliary iterations: '+ istr(numgen));
  log.lf;
  for i:= 1 to nr do rp.cell^[i]:= p.cell^[i];
  for j:= 1 to nc do cp.cell^[j]:= p.cell^[j+nr];
  //psclusters(log.f,bestp,nb,d.cdvn,sfn);
  savevector(rpfn,rp,rp.dt,'c',d.rdvn,'Row PARTITION','Core/Periphery Row Partition');
  savevector(cpfn,cp,cp.dt,'c',d.cdvn,'Column PARTITION','Core/Periphery Column Partition');

  d.title:= 'Blocked Adjacency Matrix -- Final';
  blockdisplay(log.stream,d,rp,cp,maxint,-1,-1,1.0,' ');
//  blockdisplay(log.f,d,rp,cp,9999,-1,-1,1.0,' ');

  if can(blockdensity(d,den,rp,cp,2,2,diagok)) then begin
    den.title:= 'Density matrix';
    den.displaytostream(log.stream,pagewidth,0,3);
    end;
  log.outfile('Row partition saved as dataset ',rpfn);
  log.outfile('Column partition saved as dataset ',cpfn);
  log.browse;
  defaultfn:= ifn;

cleanup:
  d.free; 
  log.free; 
  p.free; 
  rp.free; 
  cp.free; 
  den.free;
end;

end.
