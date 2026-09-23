unit Xegonet;

interface
uses
    sysutils, Forms, Dialogs, EgoNetDlg, Controls, uGEODIST,
    ucommon, ugeneral,ualloc,ucan,umath,uvector,usmatrix,
    ubmatrix, usimatrix, ubetween,
    ustats,ulogfile,uFN;

procedure EgoNetwork;

{===========================================================================}
implementation
{===========================================================================}
const
  ifn: filename = '';
  ofn: filename = 'EgoNet';
  neighb: filename = 'UNDIRECTED';
{---------------------------------------------------------------------------}
function askparameters: smallint;
label cleanup;
var
   EgoNetDialog : TEgoNetDialog;
begin
       EgoNetDialog := TEgoNetDialog.Create(Application);
       if (ifn = '') or smartdefaultnames then ifn:= defaultfn;
       if DisplayFullPathnames = true then begin
          EgoNetDialog.InputFn.Text := ifn;
          EgoNetDialog.InputFn.SelStart := Length(ifn);
       end
       else EgoNetDialog.InputFn.Text := FnAndExt(ifn);
       EgoNetDialog.EgoType.Text := neighb;
       EgoNetDialog.OutputFn.Text := ofn;
       EgoNetDialog.Showmodal;
       if EgoNetDialog.ModalResult = mrOK then begin
            ifn := EgoNetDialog.InputFn.Text;
            neighb := EgoNetDialog.EgoType.Text;
            ofn := outdir(EgoNetDialog.OutputFn.Text);
            error := 0;
            end
       else
            error := 1;
cleanup:
       EgoNetDialog.Free;
       askparameters:= error;
end;
{---------------------------------------------------------------------------}
  procedure getweakcomponents(var m:bmatrix; var c:ivector; var num:smallint);
  var
    n,v: smallint;
    {cnt: smallint;}

    Procedure Loop(x:smallint);
    Var i: smallint;
    Begin
         c.cell^[x]:= num;
         for i:= 1 to n do
             if (c.cell^[i] = 0) then
                if ((m.cell^[x]^[i] > 0) or (m.cell^[i]^[x] > 0)) then loop(i);
    End;

  Begin
       n:= m.n; num:= 0; c.n:= n; c.zerofill; {cnt:= 0;}
       for v:= 1 to n do begin
           if c.cell^[v] = 0 then begin inc(num); loop(v); end;
       end;
  End;
{---------------------------------------------------------------------------}
Procedure densitydsl(ego:smallint; var m:bmatrix; var x:smatrix);
{assumes X is already allocated}
label
  cleanup;
var
  temp,i,j,ii,jj: smallint;
  degsum,nlist: longint;
  nweak: smallint;
  t: bmatrix;
  enet: simatrix;
  bet: smatrix;
  deg,p: ivector;
  list: dslvector;
  nmiss: longint;
  nties,npairs,density,avgdist,avgrdist,diam,numweak,pweak,reach,efficiency,
    broker,egobet,negobet,cratio: single;
begin
  { 64-bit guard removed 2026-07-05 (stale): basic G1 matrix/vector ops +
    floyd/brandes1 (the same ubetween machinery that ran for years in the
    64-bit node-betweenness routine).  Full G2 migration deferred. }
  t:= bmatrix.create; p:= ivector.create; deg:= ivector.create; list:= dslvector.create;
  enet:= simatrix.create; bet:= smatrix.create;
  nties:= 0; npairs:= 0; density:= bna; nweak:= 0; avgdist:= bna; diam:= bna;
  reach:= 0; efficiency:= bna; pweak:= bna; numweak:= 0; broker:= 0; egobet:= 0;
  negobet:= 0;
  if m.rdsl.n = 0 then begin
    npairs:= bna;
    avgdist:= bna;
    avgrdist:= bna;
    diam:= bna;
    numweak:= bna;
    pweak:= bna;
    efficiency:= bna;
    cratio:= bna;
    goto cleanup;
    end;
  if cant(t.allocsize(m.rdsl.n,m.rdsl.n)) then goto cleanup;
  if cant(enet.allocsize(m.rdsl.n+1,m.rdsl.n+1)) then goto cleanup;
  if cant(bet.allocsize(m.rdsl.n+1,2)) then goto cleanup;
  if cant(p.allocsize(m.rdsl.n)) then goto cleanup;
  if cant(list.alloc(m.n)) then goto cleanup; {list.n:= 0;}
  if cant(deg.allocsize(m.rdsl.n)) then goto cleanup;
  list.n:= 0;
  for i:= 1 to m.rdsl.n do begin
    ii:= m.rdsl.cell^[i];
    list.appendifnew(ii,nlist);
    for j := 1 to m.n do
      if j <> ego then
        if (m.cell^[ii]^[j] > 0) or (m.cell^[j]^[ii] > 0) then begin
          inc(deg.cell^[i]);
          temp := j;
          list.appendifnew(temp,nlist);
          end;
    for j:= 1 to m.rdsl.n do
      if (i<>j) then begin
        jj:= m.rdsl.cell^[j];
        if m.cell^[ii]^[jj] > 0
          then begin
            t.cell^[i]^[j]:= 1;
            enet.cell^[i]^[j]:= 1;
            end
          else broker:= broker + 1;
        nties:= nties + m.cell^[ii]^[jj];
        npairs:= npairs + 1.0;
        end;
    end;
  for j:= 1 to m.rdsl.n do begin
    enet.cell^[enet.nr]^[j]:= m.cell^[ego]^[m.rdsl.cell^[j]];
    enet.cell^[j]^[enet.nr]:= m.cell^[m.rdsl.cell^[j]]^[ego];
    end;
  broker:= broker/2.0;
  degsum:= 0;
  for i:= 1 to m.rdsl.n do degsum:= degsum + deg.cell^[i];
  reach:= 100*list.n/(m.n-1);
  if degsum > 0 then efficiency:= 100*list.n/(degsum+m.rdsl.n);
  if npairs > 0 then density:= 100.0*nties/npairs;
  getweakcomponents(t,p,nweak);
  numweak:= nweak;
{  if m.rdsl.n > 1 then pweak:= 100.0*(numweak-1.0)/(m.rdsl.n-1.0);}
  if m.rdsl.n > 0 then
    pweak:= 100.0*(numweak)/(m.rdsl.n);
  if m.rdsl.n > 1 then
    cratio:= 100.0*(numweak - 1)/(m.rdsl.n - 1);
  calculatebrandesbetweenness(enet,bet);
  egobet:= bet.cell^[bet.nr]^[1];
  negobet:= bet.cell^[bet.nr]^[2];
  bfloyd(t,nmiss,true,true);
  diam:= 0; avgdist:= 0; avgrdist:= 0;
    for i:= 1 to t.n do
      for j:= 1 to t.n do
        if (i<>j) then begin
          avgdist:= avgdist + t.cell^[i]^[j];
          if t.cell^[i]^[j] < t.n
            then avgrdist:= avgrdist + 1.0/t.cell^[i]^[j];
          if t.cell^[i]^[j] > diam
            then diam:= t.cell^[i]^[j];
          end;
    if npairs > 0 then begin
      avgdist:= avgdist/npairs;
      avgrdist:= avgrdist/npairs;
      end;
    if nmiss > 0 then begin avgdist:= bna; diam:= bna; end;
  x.cell^[ego]^[1]:= m.rdsl.n;
  x.cell^[ego]^[2]:= nties;
  x.cell^[ego]^[3]:= npairs;
  x.cell^[ego]^[4]:= density;
  x.cell^[ego]^[5]:= avgrdist;
  x.cell^[ego]^[6]:= diam;
  x.cell^[ego]^[7]:= numweak;
  x.cell^[ego]^[8]:= cratio;
  x.cell^[ego]^[9]:= list.n;
  x.cell^[ego]^[10]:= reach;
  x.cell^[ego]^[11]:= efficiency;
  x.cell^[ego]^[12]:= broker;
  if npairs > 0
    then x.cell^[ego]^[13]:= 2.0*broker/npairs
    else x.cell^[ego]^[13]:= bna;
  x.cell^[ego]^[14]:= nties;
  x.cell^[ego]^[15]:= egobet;
  x.cell^[ego]^[16]:= negobet;
//  if m.rdsl.n > 0
//    then x.cell^[ego]^[14]:= nmiss
//    else x.cell^[ego]^[14]:= bna;
cleanup:
    t.free; p.free; list.free; deg.free; enet.free; bet.free;
end;
{---------------------------------------------------------------------------}
procedure addcolumndata(var big,small:smatrix);
label
  cleanup;
var
  i,j: smallint;
  oldnc,newnc: smallint;
begin
     if big.nr > big.nc then begin error:= 1; goto cleanup; end;
     oldnc:= big.nc; newnc:= big.nc + small.nc;
     if cant(big.reallocsize(big.nr,newnc)) then goto cleanup;
     for i:= 1 to big.nr do
         for j:= 1 to small.nc do
             big.cell^[i]^[oldnc+j]:= small.cell^[i]^[j];
     if cant(big.cdvn.reallocsize(newnc)) then goto cleanup;
     for j:= 1 to small.nc do
         big.cdvn.sput(oldnc+j,small.cdvn.sget(j));
cleanup:
end;
{---------------------------------------------------------------------------}
procedure EgoNetwork;
var
  x,big: smatrix;
  m: bmatrix;
  log: logfile;
  bin: boolean;
  nvar,n: smallint;
  i,j,ii: smallint;
  berror: boolean;
  npairs,nties,density,avgdist,diam,numweak,pweak,reach,efficiency: single;
label
  start,cleanup;
begin
try
start:
  { 64-bit guard removed 2026-07-05 (stale): basic G1 matrix/vector ops +
    floyd/brandes1 (the same ubetween machinery that ran for years in the
    64-bit node-betweenness routine).  Full G2 migration deferred. }
      askparameters; if error <> 0 then exit;

      berror := true;
      log:= logfile.stdcreate('Ego Networks: Basic Measures',copyright);
      log.dataset(ifn); log.lf;

      m:= bmatrix.create; x:= smatrix.create; big:= smatrix.create;
      if cant(m.load(ifn)) then goto cleanup;
      n:= m.nr;

      if m.nr <> m.nc then begin
          MessageDlg('ERROR: Matrix '+ifn+' is not square.',
                                 mtError, [mbOK], 0);
          error:= 1; goto cleanup;
      end;
      bin:= true;
      for i:= 1 to m.nr do for j:= 1 to m.nc do
        if m.cell^[i]^[j] > 1 then begin
          m.cell^[i]^[j]:= 1;
          bin:= false;
          end;
      if not bin then begin writeln(log.f,'WARNING: Data matrix was dichotomized.'); log.lf; end;
      nvar:= 16;
      if cant(m.rdsl.allocsize(n)) then goto cleanup;
      if cant(x.allocsize(m.nr,nvar)) then goto cleanup;
      x.rdvn.copy(m.rdvn);
      if cant(x.cdvn.allocsize(nvar)) then goto cleanup;
      x.cdvn.sput(1,'Size');
      x.cdvn.sput(2,'Ties');
      x.cdvn.sput(3,'Pairs');
      x.cdvn.sput(4,'Density');
      x.cdvn.sput(5,'AvgRecipDist');
      x.cdvn.sput(6,'Diameter');
      x.cdvn.sput(7,'nWeakComp');
      x.cdvn.sput(8,'CompRatio');
      x.cdvn.sput(9,'2StepReach');
      x.cdvn.sput(10,'2StepPct');
      x.cdvn.sput(11,'ReachEffic');
      x.cdvn.sput(12,'Broker');
      x.cdvn.sput(13,'nBroker');
      x.cdvn.sput(14,'nClosed');
      x.cdvn.sput(15,'EgoBetween');
      x.cdvn.sput(16,'nEgoBetween');
//      x.cdvn.sput(15,'UnReach');
      for i:= 1 to n do begin
          m.rdsl.n:= 0;
          case upcase(neighb[1]) of
          'O': for j:= 1 to n do
                   if i<>j then
                       if m.cell^[i]^[j] > 0 then m.rdsl.append(j);
          'I': for j:= 1 to n do
                   if i<>j then
                       if m.cell^[j]^[i] > 0 then m.rdsl.append(j);
          'U': for j:= 1 to n do
                   if i <> j then
                       if (m.cell^[j]^[i] > 0) or (m.cell^[i]^[j] > 0) then
                           m.rdsl.append(j);
          end;
          ii:= i;
          densitydsl(ii,m,x);
      end;
      x.title:= 'Density Measures';
      if cant(x.save(ofn)) then goto cleanup;
      x.display(log.f,pagewidth,7,2);
      writeln(log.f,'1.  Size. Size of ego network.');
      writeln(log.f,'2.  Ties. Number of directed ties.');
      writeln(log.f,'3.  Pairs. Number of ordered pairs.');
      writeln(log.f,'4.  Density. Ties divided by Pairs.');
      writeln(log.f,'5.  AvgRecipDist. Average of the reciprocal of geodesic distances between alters.');
      writeln(log.f,'6.  Diameter. Longest distance in egonet. Missing if disconnected.');
      writeln(log.f,'7.  nWeakComp. Number of weak components.');
      writeln(log.f,'8.  CompRatio. (NWeakComp-1)/(Size-1).');
      writeln(log.f,'9.  2StepReach. # of nodes within 2 links of ego.');
      writeln(log.f,'10. 2StepPct. 2stepreach/(N-1).');
      writeln(log.f,'11. ReachEffic. 2StepReach divided max possible given degrees of alters.');
      writeln(log.f,'12. Broker. # of pairs not directly connected.');
      writeln(log.f,'13. Normalized Broker. Broker divided by number of pairs.');
      writeln(log.f,'14. nClosed. The number of closed triads ego is involved in.');
      writeln(log.f,'15. Ego Betweenness. Betweenness of ego in own network.');
      writeln(log.f,'16. Normalized Ego Betweenness. Betweenness of ego in own network.');
//      writeln(log.f,'14. UnReach. # of ordered pairs with infinite distance.');
      log.lf;
      log.outfile('Ego network measures saved as dataset ',ofn);
      log.browse;
      berror := false;
      defaultfn:= ofn;

cleanup:
      m.free; log.free; x.free; big.free;
      if berror then goto start;
except
      m.free; log.free; x.free; big.free;
end;
end;
{---------------------------------------------------------------------------}
end.
