unit xclqtool;

interface
uses
    UFn, ucommon, ugeneral,ustring,uvector,usimatrix,usmatrix,ulogfile,udendro,uclus,ucan,
    XKCore, udisplay;
{---------------------------------------------------------------------------}
function iclus(ov:imatrix; var f:text; pfn:filename): smallint;
function clusteroverlaps(ov:smatrix; var log:logfile; vfn,pfn:filename; meth:integer=1)
         : smallint;
{---------------------------------------------------------------------------}
implementation
{---------------------------------------------------------------------------}
function clusteroverlaps(ov:smatrix; var log:logfile; vfn,pfn:filename; meth:integer=1)
         : smallint;
label cleanup;
begin
  log.lf;
//  if ov.n <= displaysize
//    then ov.display(log.f,pagewidth,-1,0);
//    then display(log.f,ov,pagewidth,-1,0,1,'0');
  ov.df.nl:= 1;
  if cant(ov.save(vfn)) then goto cleanup;
  case meth of
  1: runcluster(ov,log.f,true,averagelink,pfn,
     'Hierarchical Clustering of Overlap Matrix',dendrochar,pagewidth);
  2: runcluster2(ov,log.f,true,averagelink,pfn,
     'Hierarchical Clustering of Overlap Matrix',dendrochar,pagewidth);
  end;
//  iclus(ov,log.f,pfn);
  log.lf;
cleanup:
  clusteroverlaps:= error;
end;
{---------------------------------------------------------------------------}
function iclus(ov:imatrix; var f:text; pfn:filename): smallint;
label cleanup;
var
  i: smallint;
  npart: smallint;
  p: imatrix;
  bp,level: ivector;
begin
  p:= imatrix.create; bp:= ivector.create; level:= ivector.create;
  p.df.outdf.dt:= p.dt;
  if p.openoutfile(dsys(pfn)) <> 0 then goto cleanup;

  runsinglelink(p.df.outdf,ov,npart,level);
{    if cant(runcluster(e,log.f,true,averagelink,pfn,
    'Hierarchical Clustering of Equivalence Matrix',dendrochar,pagewidth)) }
  p.closeoutfile;
  p.cdvn.copy(ov.cdvn);
  if p.rdvn.allocsize(npart) <> 0 then goto cleanup;

  for i:= 1 to npart do
      p.rdvn.lput(i,istr(level.cell^[i],0));
  p.title:= 'Partition Indicator Matrix';
  p.nr:= npart; p.nc:= ov.nc;
  if p.savehdr(hsys(pfn)) <> 0 then goto cleanup;
  if p.allocsize(npart,ov.n) <> 0 then goto cleanup;
  p.df.indf.dt:= p.df.outdf.dt;

  if p.loaddata(dsys(pfn)) <> 0 then goto cleanup;
  if bp.allocsize(ov.n) <> 0 then goto cleanup;

  if cant(getbestperm(p,bp.cell^,true)) then goto cleanup;
  if error <> 0 then goto cleanup;

  if ov.n <= displaysize then Text_Dendrogram(f,p,bp.cell^,'Level','Single-Link Hierarchical Clustering',
             false,dendrochar,pagewidth);
  p.save(pfn);

cleanup:
  p.free; bp.free; level.free;
  iclus:= error;
end;
{---------------------------------------------------------------------------}
End.
