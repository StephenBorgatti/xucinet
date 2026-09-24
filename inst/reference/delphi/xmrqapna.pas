unit xmrqapna;

interface
uses
    classes, Forms,Dialogs, Controls, sysutils,Waiting, QAP2Dlg, UFn,
    ucommon, ugeneral,ucan,ustring,udupdash,uvector,usmatrix,uematrix,ubmatrix,
    urandom,ulogfile,uparser,usvd,ulude,uufile,uheader,ustats,ug2stats,umsg,
    utunivariate,ufnvcl;

procedure networkregressionna;
{===========================================================================}
implementation
{===========================================================================}
const
  xfn: string = '';
  yfn: string = '';
  efn: string = 'mrqap-predicted';
  nperm: integer = 2000;
  diagok: boolean = false;
  seed: integer = 0;
  runmed: boolean = false;
var
  symmetric: boolean;
type
  xmatstype = array of array of array of single;
{---------------------------------------------------------------------------}
function askparameters: smallint;
label cleanup;
var
     QAP2Dialog : TQAP2Dialog;
 begin
     QAP2Dialog := TQAP2Dialog.Create(Application);
     error := 0;
     with QAP2Dialog do begin
          setdlgifn(inputdep,yfn,'');
          setdlgfn(inputind,xfn);
          NoPerms.Text := istr(nperm,0);
          randomize; seed:= trunc(random(1000)) + 1;
          RandomSeed.Text := istr(seed,0);
          dlg_efn.text:= efn;
          runmediation.Checked:= runmed;
     end;
     QAP2Dialog.Showmodal;
     if QAP2Dialog.ModalResult = mrOK then begin
          with QAP2Dialog do begin
               yfn:= allbutext(InputDep.Text);
               xfn:= InputInd.Text;
               if isnullstr(xfn) then goto cleanup;
               if cant(str2num(NoPerms.Text,nperm,true)) then goto cleanup;
               if cant(strb(Diagonal.Text,diagok,true)) then goto cleanup;
               if cant(str2num(RandomSeed.Text,seed,true)) then goto cleanup;
               efn:= outdir(dlg_efn.text);
               runmed:= runmediation.Checked;
          end;
     end;
     if QAP2Dialog.ModalResult = mrCancel then error := 1;
cleanup:
     askparameters := error;
     QAP2Dialog.Free;
end;
{---------------------------------------------------------------------------}
function lureg(var xtx:ematrix; var index:ivector; var xty,b:evector;
               var first:boolean): smallint;
var
  d: extended;
  i: integer;
begin
  if first then begin lud(xtx,index,d); first:= false; end;
  for i:= 1 to b.n do
    b.cell^[i]:= xty.cell^[i];
  lubacksub(xtx,index,b);
  lureg:= error;
end;
{---------------------------------------------------------------------------}
function getlistofxfilenames(var xfn:string; var w:integer;
                              var xlist:strvector): integer;
label cleanup;
var
  t: parser;
  nx: integer;
begin
  t:= parser.create;
  t.setbuffer(xfn);
  if cant(xlist.alloc(maxndim)) then goto cleanup;
  nx:= 0; w:= 0;
  while (t.nexttoken <> '') and (nx < maxndim) do begin
    inc(nx); xlist.cell^[nx]:= allbutext(t.lasttoken);
    if length(t.lasttoken) > w then w:= length(t.lasttoken);
    end;
  xlist.n:= nx;
  cleanup:
    t.free;
    getlistofxfilenames:= error;
end;
{---------------------------------------------------------------------------}
  function ijok(i,j:integer): boolean;
  begin
    result:= (i <> j) or diagok;
    if symmetric
      then result:= result and (i >= j);
  end;
{---------------------------------------------------------------------------}
function readdata(var log:logfile; var xmats:xmatstype; var ymat:smatrix; var n,nx,nx1:integer;
                  var xlist:strvector; yfn:string; var valid:bmatrix): smallint;
label cleanup;
var
  nobs,i,j,k: integer;
  tmp: smatrix;
  numna: longint;
  temp: boolean;
begin
  tmp:= smatrix.create; error:= 0;
  nx:= xlist.n; nx1:= nx + 1;
  if cant(ymat.load(yfn)) then goto cleanup;
  tmp.checksymmetry(temp);
  symmetric:= temp;
  if ymat.nr <> ymat.nc then begin
    errormsg('ERROR: QAP may only be used on square matrices.');
    error:= 1;
    goto cleanup;
    end;
  n:= ymat.n;
  if cant(valid.allocsize(n,n)) then goto cleanup;
  setlength(xmats,nx1+1,n+1,n+1);
  for k:= 1 to nx do begin
    if cant(tmp.load(xlist.cell^[k])) then goto cleanup;
    tmp.checksymmetry(temp);
    if not temp
      then symmetric:= false;
    if (tmp.nr <> n) or (tmp.nc <> n) then begin
      errormsg('Not all X matrices are the same size.');
      error:= 1;
      goto cleanup;
      end;
    for i:= 1 to n do for j:= 1 to n do
      xmats[k,i,j]:= tmp.cell^[i]^[j];
    end;
  for i:= 1 to n do for j:= 1 to n do xmats[nx1,i,j]:= 1;
  valid.zerofill;
  for i:= 1 to n do for j:= 1 to n do if ijok(i,j) then begin
    numna:= 0;
    {if ymat.cell^[i]^[j] >= na then inc(numna);}
    for k:= 1 to nx do
      if xmats[k,i,j] >= na then inc(numna);
    if numna = 0 then valid.cell^[i]^[j]:= 1;
    end;
  valid.save(outdir('mrqap-valid'));
  nobs:= 0;
  for i:= 1 to n do for j:= 1 to n do if ijok(i,j) then
    nobs:= nobs + valid.cell^[i]^[j];
  writeln(log.f,'Number of valid observations among the X variables = ',nobs);
  writeln(log.f);
cleanup:
  result:= error;
  tmp.free;
end;
{---------------------------------------------------------------------------}
function createcolumnvars(var log:logfile; var x:smatrix; var y:svector; var xmats:xmatstype;
                          var ymat:smatrix; var valid:bmatrix; var dsl:dslvector; n,nx1:integer): integer;
label cleanup;
var
  i,ii,j,jj,k,ij: integer;
begin
  ij:= 0;
  for i:= 1 to n do for j:= 1 to n do if ijok(i,j) then begin
    ii:= dsl.cell^[i]; jj:= dsl.cell^[j];
    {if (ii > n) or (ii < 1) or (jj > n) or (jj < 1) then errormsg(istr(ii)+' '+istr(jj));}
    if ((ii<>jj) or diagok) and (valid.cell^[ii]^[jj] = 1) and (ymat.cell^[i]^[j] < na) then begin
        inc(ij);
        for k:= 1 to nx1 do x.cell^[ij]^[k]:= xmats[k,ii,jj];
        y.cell^[ij]:= ymat.cell^[i]^[j];
        end;
    end;
  x.nr:= ij; x.nc:= nx1;
  y.n:= ij;
  cleanup:
    result:= error;
end;
{---------------------------------------------------------------------------}
  function getySD(var sdy:extended; var y:svector): smallint;
  label cleanup;
  var
    i: integer;
    u: uestimator;
  begin
    u:= uestimator.create;
    for i:= 1 to y.n do u.addcase(y.cell^[i]);
    u.calc;
    sdy:= u.stddev;
  cleanup:
    getysd:= error; u.free;
  end;
{---------------------------------------------------------------------------}
function run1regression(var log:logfile; var b:evector; var indirect:extended; var rsqr:extended; var x:smatrix; var y:svector): integer;
label cleanup;
var
  nx1,nobs: integer;
  yk,toty,d,sst,yty,btxty,sse,ssr: extended;
  j,k,l,m:integer;
  w,xty: evector;
  vmat,xtx: smatrix;
  index: ivector;
begin
  xty:= evector.create; xtx:= smatrix.create; index:= ivector.create; vmat:= smatrix.create; w:= evector.create;
  error:= 0;
  nx1:= x.nc; nobs:= y.n;
  if cant(xty.allocsize(nx1)) then goto cleanup;
  if cant(w.allocsize(nx1)) then goto cleanup;
  if cant(index.allocsize(nx1)) then goto cleanup;
  if cant(xtx.allocsize(nx1,nx1)) then goto cleanup;
  if cant(vmat.allocsize(nx1,nx1)) then goto cleanup;
  yty:= 0; toty:= 0;
  for k:= 1 to nobs do begin
    for l:= 1 to nx1 do for m:= 1 to nx1 do
      xtx.cell^[l]^[m]:= xtx.cell^[l]^[m]+x.cell^[k]^[l]*x.cell^[k]^[m];
    yk:= y.cell^[k];
    yty:= yty + sqr(yk);
    toty:= toty + yk;
    for l:= 1 to nx1 do xty.cell^[l]:= xty.cell^[l] + x.cell^[k]^[l]*yk;
    end;
  sst:= yty - toty*(toty/nobs);
  for j:= 1 to nx1 do
    b.cell^[j]:= xty.cell^[j];
  if cant(svdreg(xtx,vmat,w,b,b,true)) then goto cleanup;
  btxty:= 0;
  for j:= 1 to nx1 do
    btxty:= btxty + b.cell^[j]*xty.cell^[j];
  sse:= yty - btxty;
  ssr:= sst - sse;
  rsqr:= ssr/sst;
  indirect:= b.cell^[1]*b.cell^[2];
  cleanup:
    result:= error;
    xty.free; xtx.free; index.free; vmat.free; w.free;
end;
{---------------------------------------------------------------------------}
procedure writesignificances(var log:logfile; w,gtrsqr,nperm,nobs:integer;
                       rsqr,sdy:extended; var b,sdx:evector;
                       var ltbeta,gtbeta:ivector; var xlist:strvector; sl:tlist);
var
  i: integer;
  nx,nx1: integer;
  adjrsqr,v: extended;
begin
  nx:= xlist.n; nx1:= nx + 1;
//  adjrsqr:= rsqr - (1.0-rsqr)*(nx-1.0)/(nobs-nx);
  adjrsqr:= 1.0 - (1.0-rsqr)*(1.0*nobs-1)/(1.0*nobs-nx-1.0);
  log.lf;
  writeln(log.f,'Number of permutations performed: ',nperm); log.lf; log.lf;
  writeln(log.f,'MODEL FIT'); log.lf;
  writeln(log.f,'R-square':8,'Adj R-Sqr':10,'Probability':12,'# of Obs':12);
  writeln(log.f,dash(8):8,dash(9):10,dash(11):12,dash(11):12);
  writeln(log.f,rsqr:8:3,adjrsqr:10:3,1.0*gtrsqr/nperm:12:3,nobs:12);

  log.lf; log.lf;
  if w < 12 then w:= 12;
  writeln(log.f,'REGRESSION COEFFICIENTS'); log.lf;
  writeln(log.f,' ':w,'Un-stdized':12,'Stdized':12,
    '':13,'Proportion':12,'Proportion':12);
  writeln(log.f,'Independent':w,'Coefficient':12,'Coefficient':12,
    'Significance':13,'As Large':12,'As Small':12,'Std Dev':12);
  writeln(log.f,dash(w-1):w,dash(11):12,dash(11):12,
    dash(12):13,dash(11):12,dash(11):12,dash(11):12);
  if b.cell^[nx1] < 0
    then writeln(log.f,'Intercept':w,b.cell^[nx1]:12:6,0.0:12:6,
      1.0*ltbeta.cell^[nx1]/nperm:13:3,1.0*gtbeta.cell^[nx1]/nperm:12:3,1.0*ltbeta.cell^[nx1]/nperm:12:3)
    else writeln(log.f,'Intercept':w,b.cell^[nx1]:12:6,0.0:12:6,
      1.0*gtbeta.cell^[nx1]/nperm:13:3,1.0*gtbeta.cell^[nx1]/nperm:12:3,1.0*ltbeta.cell^[nx1]/nperm:12:3);
  for i:= 1 to nx do begin
    if sdy > 0 then v:= b.cell^[i]*sdx.cell^[i]/sdy else v:= 0.0;
      if b.cell^[i] < 0
        then writeln(log.f,xlist.cell^[i]:w,b.cell^[i]:12:6,v:12:6,
          1.0*ltbeta.cell^[i]/nperm:13:3,
          1.0*gtbeta.cell^[i]/nperm:12:3,
          1.0*ltbeta.cell^[i]/nperm:12:3,
          tunivariate(sl.Items[i]).stddev:12:3)
        else writeln(log.f,xlist.cell^[i]:w,b.cell^[i]:12:6,v:12:6,
          1.0*gtbeta.cell^[i]/nperm:13:3,
          1.0*gtbeta.cell^[i]/nperm:12:3,
          1.0*ltbeta.cell^[i]/nperm:12:3,
          tunivariate(sl.Items[i]).stddev:12:3);
    end;
  log.lf;
end;
{---------------------------------------------------------------------------}
procedure writesimpleresults(var log:logfile; w,nobs:integer;
                       rsqr,sdy:extended; var vbeta,sdx:evector;
                       var xlist:strvector);
var
  i: integer;
  nx,nx1: integer;
  adjrsqr,v: extended;
begin
  nx:= xlist.n; nx1:= nx + 1;
//  adjrsqr:= rsqr - (1.0-rsqr)*(nx-1.0)/(nobs-nx);
  adjrsqr:= 1.0 - (1.0-rsqr)*(1.0*nobs-1)/(1.0*nobs-nx-1.0);
  log.lf;
  writeln(log.f,'MODEL FIT'); log.lf;
  writeln(log.f,'R-square':8,'Adj R-Sqr':12,'# of Obs':12);
  writeln(log.f,dash(8):8,dash(11):12,dash(11):12);
  writeln(log.f,rsqr:8:3,adjrsqr:8:3,nobs:12);
  log.lf; log.lf;
  if w < 12 then w:= 12;
  writeln(log.f,'REGRESSION COEFFICIENTS'); log.lf;
  writeln(log.f,' ':w,'Un-stdized':12,'Standardized':13);
  writeln(log.f,'Independent':w,'Coefficient':12,'Coefficient':13);
  writeln(log.f,dash(11):w,dash(11):12,dash(12):13);
  writeln(log.f,'Intercept':w,vbeta.cell^[nx1]:12:6,0.0:13:6);
  for i:= 1 to nx do begin
    if sdy > 0 then v:= vbeta.cell^[i]*sdx.cell^[i]/sdy else v:= 0.0;
    writeln(log.f,xlist.cell^[i]:w,vbeta.cell^[i]:12:6,v:13:6);
    end;
  log.lf;
end;
{---------------------------------------------------------------------------}
procedure lineartransformofmatrix(var ymat,x:smatrix; var b:evector);
var
  i,j,k,m: integer;
  yhat: extended;
begin
  k:= 0;
  for i:= 1 to ymat.nr do
    for j:= 1 to ymat.nc do
      if (i <> j) or diagok then begin
        inc(k); yhat:= 0;
        for m:= 1 to x.nc do
          yhat:= yhat + x.cell^[k]^[m]*b.cell^[m];
        ymat.cell^[i]^[j]:= yhat;
        end;
end;
{---------------------------------------------------------------------------}
procedure networkregressionNA;
var
  x,ymat: smatrix;
  y: svector;
  xmats: xmatstype;
  valid: bmatrix;
  vpbeta,vbeta,sdx,ab: evector;
  gtbeta,ltbeta: ivector;
  dsl: dslvector;
  log: logfile;
  p,w,gtrsqr: integer;
  i,j: smallint;
  nx1,nx,n: integer;
  xlist: strvector;
  sdy,prsqr,rsqr,indirect,pindirect,lower,upper: extended;
  numskip, numit,geindirect: integer;
  nobs: integer;
  sl: tlist;
label
  cleanup;

  procedure getconfidenceintervals;
  var
    total,sum: double;
    k,i,j: integer;
  begin
    ab.sort('a',nil);
    i:= round(0.005*nperm*5.0); if i < 0 then i:= 1;
    lower:= ab.cell^[i];
    j:= round(nperm*(1-0.005*5)); if (j > nperm) then j:= nperm;
    upper:= ab.cell^[j];
  end;

begin
  { 64-bit guard removed 2026-07-05 (stale): this unit already mixes G1 basic
    ops with G2 units and/or uses shared engines (uclus/utabu/ugenetic/usvd/
    ubetween/udsl) that are pointer-size-clean and proven by unguarded,
    64-bit-working routines.  Full G2 migration deferred with those engines. }
  if cant(askparameters) then exit; error:= 0;
  ab:= evector.create;
  xlist:= strvector.create; dsl:= dslvector.create; ymat:= smatrix.create;
  x:= smatrix.create; valid:= bmatrix.create;
  vbeta:= evector.create; vpbeta:= evector.create; ltbeta:= ivector.create; gtbeta:= ivector.create;
  sdx:= evector.create; y:= svector.create;
  sl:= tlist.Create;

  log:= logfile.stdcreate('Multiple Regression QAP via Permutation Method w/ Missing Values',copyright);

  if nperm < 1 then nperm:= 1;
  log.putstr('# of permutations:',istr(nperm,0));
  log.putstr('Diagonal valid?',bstr(diagok));
  log.putstr('Random seed:',istr(seed,0));
  log.putstr('Dependent variable:',yfn);
  log.putfn('Expected values:',efn);

  if cant(getlistofxfilenames(xfn,w,xlist)) then goto cleanup;
  log.putstr('Independent variables:',xlist.cell^[1]);
  if xlist.n > 1 then for i:= 2 to xlist.n do log.putstr('',xlist.cell^[i]);
  log.lf; log.lf;


  if cant(readdata(log,xmats,ymat,n,nx,nx1,xlist,yfn,valid)) then goto cleanup;

  if cant(dsl.allocsize(n)) then goto cleanup;
  if cant(gtbeta.allocsize(nx1)) then goto cleanup;
  if cant(ltbeta.allocsize(nx1)) then goto cleanup;
  if cant(vbeta.allocsize(nx1)) then goto cleanup;
  if cant(vpbeta.allocsize(nx1)) then goto cleanup;
  if cant(x.allocsize(n*n,nx1)) then goto cleanup;
  if cant(y.allocsize(n*n)) then goto cleanup;
  if cant(ab.allocsize(nperm)) then goto cleanup;

  for i:= 1 to n do if dsl.cell^[i] <> i then errormsg(istr(dsl.cell^[i]));
  if cant(createcolumnvars(log,x,y,xmats,ymat,valid,dsl,n,nx1)) then goto cleanup;
  sl.Add(nil);
  for i:= 1 to nx1 do
    sl.Add(tunivariate.create);
  if x.nr < 3 then begin
    errormsg('There are only '+istr(x.nr)+' valid observations.');
    goto cleanup;
    end;
  if cant(run1regression(log,vbeta,indirect,rsqr,x,y)) then goto cleanup;
  ab.cell^[1]:= indirect;
  if rsqr > 1.0 then begin
    errormsg('Ill-conditioned matrix. Cannot complete computation.');
    goto cleanup;
    end;

  if cant(getcolsd(sdx,x,diagok)) then goto cleanup;
  if cant(getysd(sdy,y)) then goto cleanup;
  nobs:= x.nr;
  writeln(log.f,'N = ',nobs);

  if nperm < 1 then nperm:= 1;

  WaitinggaugeStart('Calculating ....',nperm);
  randseed:= seed; gtrsqr:= 0; numit:= 0; numskip:= 0; geindirect:= 0;
  if nperm > 1 then
    for p:= 2 to nperm do begin
      if ShowProgressbinned(p) then break;
      for i:= 1 to n do if (dsl.cell^[i]<1) or (dsl.cell^[i]>n) then errormsg(istr(dsl.cell^[i]));
      randperm(dsl);
      for i:= 1 to n do if (dsl.cell^[i]<1) or (dsl.cell^[i]>n) then errormsg(istr(dsl.cell^[i]));
      {randperm(dsl);}
      if cant(createcolumnvars(log,x,y,xmats,ymat,valid,dsl,n,nx1)) then {goto cleanup};
      if x.nr < 3 then begin
        numskip:= numskip + 1;
        continue;
        end;
      run1regression(log,vpbeta,pindirect,prsqr,x,y);
      ab.cell^[p]:= pindirect;
      inc(numit);
      if prsqr >= rsqr then inc(gtrsqr);
      for j:= 1 to nx1 do begin
        if vpbeta.cell^[j] >= vbeta.cell^[j] then inc(gtbeta.cell^[j]);
        if vpbeta.cell^[j] <= vbeta.cell^[j] then inc(ltbeta.cell^[j]);
        if abs(pindirect) >= abs(indirect) then inc(geindirect);
        tunivariate(sl.Items[j]).addcase(vpbeta.cell^[j]);
        end;
      end;
  for i:= 1 to nx1 do
    tunivariate(sl.Items[i]).calc;
  WaitingEnd;

  if numskip > 0 then begin
    writeln(log.f,'Number of regressions skipped due to having fewer than 3 observations: ',numskip);
    log.lf;
    end;

  if numit > 1
    then writesignificances(log,w,gtrsqr,numit,nobs,rsqr,sdy,vbeta,sdx,ltbeta,gtbeta,xlist,sl)
    else writesimpleresults(log,w,nobs,rsqr,sdy,vbeta,sdx,xlist);

  if runmed then begin
    getconfidenceintervals;
    writeln(log.f,'MEDIATION ANALYSIS');
    log.put('Sobel indirect effect (ab): ' + floattostr(indirect));
    log.put('Permutation-based p-value:' + floattostr(geindirect/nperm) );
    writeln(log.f,'95% confidence interval = [',lower:0:3,',',upper:0:3,']');
    log.lf();
    end;

  lineartransformofmatrix(ymat,x,vbeta);
  ymat.title:= 'Expected values based on multiple regression QAP';
  ymat.save(efn);
  writeln(log.f,'Expected values saved as dataset ',efn);
  writeln(log.f,'Valid observations saved as dataset ','mrqap-valid');
  log.browse;

  defaultfn:= yfn;
cleanup:
  log.free;
  WaitingEnd;
  dsl.free;
  ymat.free;
  x.free;
  gtbeta.free;
  ltbeta.free;
  xlist.free;
  vpbeta.free;
  vbeta.free;
  valid.free;
  y.free;
  finalize(xmats);
  for i:= 0 to sl.Count - 1 do
    if sl.items[i] <> nil
      then tunivariate(sl.Items[i]).free;
  sl.Free;
end;
{---------------------------------------------------------------------------}
End.
