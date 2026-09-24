unit xcatc2;

interface
uses
  Forms, Dialogs, waiting, CACDlg, UFn, Controls, sysutils,
  ucommon, ugeneral,ucan,ustring,udupdash,uvector,usmatrix,uematrix,urandom,
  ulogfile,ustats,ukey,uparser,udsl,uqap,ulude,umsg,uag, utsmatds;

procedure autocorranova;
{===========================================================================}
implementation
{===========================================================================}
const
  attribstr: string = '';
  nperm: integer = 5000;
  diagok: boolean = false;
  seedvalue: smallint = 0;
  method: smallint = 3;
  shouldcenter: boolean = true;
  ifn: filename = '';
  denfn: filename = 'densitytable';
  expfn: filename = 'anovadensity_expectedvalues';
  asymok: boolean = true;
{---------------------------------------------------------------------------}
function methstr(meth:smallint): string;
begin
  case meth of
    1: methstr:= 'Constant Homophily';
    2: methstr:= 'Variable Homophily';
    3: methstr:= 'Structural Blockmodel';
    4: methstr:= 'Symmetric Diagonal';
    5: methstr:= 'Non-symmetric Diagonal';
    6: methstr:= 'Core/Periphery 1';
    7: methstr:= 'Core/Periphery 2';
    9: methstr:= 'Baseline Model';
    else methstr:= 'Unknown';
    end;
end;
{---------------------------------------------------------------------------}
function wmeth(s:string): smallint;
begin
  wmeth:= 0;
  if iskey(s,'con|ch')
    then wmeth:= 1
    else if iskey(s,'v|mo')
      then wmeth:= 2
      else if iskey(s,'st|bl|p')
        then wmeth:= 3
        else if iskey(s,'sd|sy')
          then wmeth:= 4
          else if iskey(s,'non|ns|d')
            then wmeth:= 5
            else if iskey(s,'core/periphery 2|cp2|c/p 2')
              then wmeth:= 7
              else if iskey(s,'co|cp|c/p')
                then wmeth:= 6
                else if iskey(s,'ba|a|me')
                  then wmeth:= 9
                  else wmeth:= 0;
end;
{---------------------------------------------------------------------------}
function askcategoricalparameters: smallint;
label cleanup;
var
     CatAutoCDlg : TCatAutoCDlg;
begin
     CatAutoCDlg := TCatAutoCDlg.Create(Application);
     if DisplayFullPathnames = true then begin
        CatAutoCDlg.InputFn.Text := ifn;
        CatAutoCDlg.Attributes.Text := attribstr;
        CatAutoCDlg.InputFn.SelStart := Length(ifn);
        CatAutoCDlg.Attributes.SelStart := Length(attribstr);
     end
     else begin
          CatAutoCDlg.InputFn.Text := FnAndExt(ifn);
          CatAutoCDlg.Attributes.Text := FnAndExt(attribstr);
     end;
     CatAutoCDlg.OutputFn.Text := expfn;
     catautocdlg.DensityFn.text:= denfn;
     CatAutoCDlg.Model.Text := methstr(method);
     CatAutoCDlg.NoPerms.Text := istr(nperm,0);
     CatAutoCDlg.Diagonal.Text := bstr(diagok);
     randomize; seedvalue:= trunc(random(1000)) + 1;
     CatAutoCDlg.Seed.Text := istr(seedvalue,0);
     CatAutoCDlg.Showmodal;
     if CatAutoCDlg.ModalResult = mrOK then begin
         with CatAutoCDlg do begin
         ifn := InputFn.Text;
         attribstr:= Attributes.Text;
         if attribstr = '' then attribstr:= 'NONE';
         method:= wmeth(Model.Text);
         if cant(str2num(Seed.Text,seedvalue,true)) then goto cleanup;
         if cant(str2num(NoPerms.Text,nperm,true)) then goto cleanup;
         if cant(strb(Diagonal.Text,diagok,true)) then goto cleanup;
         expfn := outdir(OutputFn.Text);
         denfn:= outdir(densityfn.text);
         error := 0;
         end;
         end
     else
         error := 1;
cleanup:
     askcategoricalparameters:= error;
     CatAutoCDlg.Free;
end;
{---------------------------------------------------------------------------}
  function getmatrixSD(var sdy:extended; ymat:smatrix): smallint;
  label cleanup;
  var
    i,j: integer;
    u: uestimator;
  begin
    u:= uestimator.create;
    for i:= 1 to ymat.nr do for j:= 1 to ymat.nc do if (i<>j) or diagok then
      u.addcase(ymat.cell^[i]^[j]);
    u.calc;
    sdy:= u.stddev;
  cleanup:
    result:= error; u.free;
  end;
{---------------------------------------------------------------------------}
function mrqap(b:evector; var rsqr:extended;
          x,ymat:smatrix; xtx:ematrix; dsl:dslvector;
          index:ivector;
          first:boolean): integer;
label cleanup;
var
  nx,nx1: integer;
  yk,toty,d,sst,yty,btxty,sse,ssr: extended;
  i,j,k,l,m:integer;
  b1,b2: integer;
  xty: evector;

  procedure makextx(k:integer);
  var l,m: integer;
  begin
    for l:= 1 to nx1 do
      for m:= 1 to nx1 do
         xtx.cell^[l]^[m]:= xtx.cell^[l]^[m]+x.cell^[k]^[l]*x.cell^[k]^[m];
  end;

begin
  xty:= evector.create;
  nx:= x.nc-1; nx1:= x.nc;
  if cant(xty.allocsize(nx1)) then goto cleanup;
  if first then xtx.zerofill;
  xty.zerofill;
  k:= 0; yty:= 0; toty:= 0;
  for i:= 1 to ymat.nr do
    for j:= 1 to ymat.nc do
      if (j >= i) or asymok then
        if (i<>j) or diagok then begin
          inc(k);
          if first then makextx(k);
          b1 := dsl.cell^[i]; b2 := dsl.cell^[j];
          yk:= ymat.cell^[b1]^[b2];
          yty:= yty + sqr(yk);
          toty:= toty + yk;
          for l:= 1 to nx1 do xty.cell^[l]:= xty.cell^[l] + x.cell^[k]^[l]*yk;
          end;
  sst:= yty - toty*(toty/k);
  if first then lud(xtx,index,d);
  move(xty.cell^,b.cell^,sizeof(extended)*b.n);
  lubacksub(xtx,index,b);
  btxty:= 0;
  for j:= 1 to nx1 do btxty:= btxty + b.cell^[j]*xty.cell^[j];
  sse:= yty - btxty;
  ssr:= sst - sse;
  rsqr:= ssr/sst;
  cleanup:
    xty.free;
end;
{---------------------------------------------------------------------------}
function constructCHdata(x:smatrix; v:ivector; xlist:lvector;
  var f:text): integer;
label cleanup;
var
  i,j,h: integer;
  nx,nx1,nrow,n: integer;
begin
  nx:= 1; nx1:= nx + 1;
  n:= v.n;
  if asymok
    then if diagok then nrow:= n*n else nrow:= n*(n-1)
    else if diagok then nrow:= n+n*(n-1) div 2 else nrow:= n*(n-1) div n;
  if cant(x.allocsize(nrow,nx1)) then goto cleanup;
  h:= 0;
  for i:= 1 to n do
    for j:= 1 to n do
      if (j >= i) or asymok then
        if (i<>j) or diagok then begin
          inc(h);
          if v.cell^[i] = v.cell^[j]
            then x.cell^[h]^[1]:= 1
            else x.cell^[h]^[1]:= 0;
          end;
  x.nr:= h;
  for i:= 1 to x.nr do x.cell^[i]^[nx1]:= 1;
  if cant(xlist.allocsize(x.nc)) then goto cleanup;
  xlist.sput(x.nc,'Intercept');
  xlist.sput(1,'In-group');
cleanup:
  result:= error;
end;
{---------------------------------------------------------------------------}
function constructVHdata(x:smatrix; v:ivector; xlist:lvector;
  nb:integer; var f:text): integer;
label cleanup;
var
  i,j,k,h: integer;
  blocknum,vi,vj,nx,nx1,nrow,n: integer;
begin
  nx:= nb; nx1:= nb+1;
  n:= v.n;
  if asymok
    then if diagok then nrow:= n*n else nrow:= n*(n-1)
    else if diagok then nrow:= n+n*(n-1) div 2 else nrow:= n*(n-1) div n;
  if cant(x.allocsize(nrow,nx1)) then goto cleanup;
  h:= 0;
  for i:= 1 to n do
    for j:= 1 to n do
      if (j >= i) or asymok then
        if (i<>j) or diagok then begin
          inc(h);
          vi:= v.cell^[i]; vj:= v.cell^[j];
          for k:= 1 to nx do if (k = vi) and (k = vj)
            then x.cell^[h]^[k]:= 1
            else x.cell^[h]^[k]:= 0;
          end;
  x.nr:= h;
  for i:= 1 to x.nr do x.cell^[i]^[nx1]:= 1;
  if cant(xlist.allocsize(x.nc)) then goto cleanup;
  for i:= 1 to nb do
    xlist.sput(i,'Group '+inttostr(i));
cleanup:
  result:= error;
end;
{---------------------------------------------------------------------------}
function constructSBMdata(x:smatrix; v:ivector; xlist:lvector;
  nb:integer; var f:text): integer;
label cleanup;
var
  i,j,k,h: integer;
  blocknum,vi,vj,nx,nx1,nrow,n: integer;
begin
  nx:= nb*nb-1; nx1:= nb*nb;
  n:= v.n;
  if asymok
    then if diagok then nrow:= n*n else nrow:= n*(n-1)
    else if diagok then nrow:= n+n*(n-1) div 2 else nrow:= n*(n-1) div n;
  if cant(x.allocsize(nrow,nx1)) then goto cleanup;
  h:= 0;
  for i:= 1 to n do
    for j:= 1 to n do
      if (j >= i) or asymok then
        if (i<>j) or diagok then begin
          inc(h);
          vi:= v.cell^[i]; vj:= v.cell^[j];
          blocknum:= nb*(vi-1)+vj;
          for k:= 1 to nx do if k = blocknum
            then x.cell^[h]^[k]:= 1
            else x.cell^[h]^[k]:= 0;
          end;
  x.nr:= h;
  for i:= 1 to x.nr do x.cell^[i]^[nx1]:= 1;
  if cant(xlist.allocsize(x.nc)) then goto cleanup;
  for i:= 1 to nb do for j:= 1 to nb do begin
    blocknum:= nb*(i-1)+j;
    xlist.sput(blocknum,inttostr(i)+'-'+inttostr(j));
    end;
cleanup:
  result:= error;
end;
{---------------------------------------------------------------------------}
function constructCP1data(x:smatrix; v:ivector; xlist:lvector;
  nb:integer; var f:text): integer;
label cleanup;
var
  i,j,h: integer;
  nx,nx1,nrow,n: integer;
begin
  nx:= 1; nx1:= nx + 1;
  n:= v.n;
  if asymok
    then if diagok then nrow:= n*n else nrow:= n*(n-1)
    else if diagok then nrow:= n+n*(n-1) div 2 else nrow:= n*(n-1) div n;
  if cant(x.allocsize(nrow,nx1)) then goto cleanup;
  h:= 0;
  for i:= 1 to n do
    for j:= 1 to n do
      if (j >= i) or asymok then
        if (i<>j) or diagok then begin
          inc(h);
          if (v.cell^[i] = 1) and (v.cell^[j] = 1)
            then x.cell^[h]^[1]:= 1
            else x.cell^[h]^[1]:= 0;
          end;
  x.nr:= h;
  for i:= 1 to x.nr do x.cell^[i]^[nx1]:= 1;
  if cant(xlist.allocsize(x.nc)) then goto cleanup;
  xlist.sput(x.nc,'Intercept');
  xlist.sput(1,'Core');
cleanup:
  result:= error;
end;
{---------------------------------------------------------------------------}
function constructCP2data(x:smatrix; v:ivector; xlist:lvector;
  nb:integer; var f:text): integer;
label cleanup;
var
  i,j,h: integer;
  nx,nx1,nrow,n: integer;
begin
  nx:= 1; nx1:= nx + 1;
  n:= v.n;
  if asymok
    then if diagok then nrow:= n*n else nrow:= n*(n-1)
    else if diagok then nrow:= n+n*(n-1) div 2 else nrow:= n*(n-1) div n;
  if cant(x.allocsize(nrow,nx1)) then goto cleanup;
  h:= 0;
  for i:= 1 to n do
    for j:= 1 to n do
      if (j >= i) or asymok then
        if (i<>j) or diagok then begin
          inc(h);
          if (v.cell^[i] = 1) or (v.cell^[j] = 1)
            then x.cell^[h]^[1]:= 1
            else x.cell^[h]^[1]:= 0;
          end;
  x.nr:= h;
  for i:= 1 to x.nr do x.cell^[i]^[nx1]:= 1;
  if cant(xlist.allocsize(x.nc)) then goto cleanup;
  xlist.sput(x.nc,'Intercept');
  xlist.sput(1,'Non-Periphery');
cleanup:
  result:= error;
end;
{---------------------------------------------------------------------------}
function getwidth(var xlist:lvector): integer;
var
  w,i: integer;
begin
  w:= 0;
  for i:= 1 to xlist.n do
    if length(xlist.sget(i)) > w then w:= length(xlist.sget(i));
  result:= w;
end;
{---------------------------------------------------------------------------}
procedure writesignificances(var log:logfile; gtrsqr,nperm,nobs:integer;
                       rsqr,sdy:extended; var beta,sdx:evector;
                       var ltbeta,gtbeta:ivector; var xlist:lvector);
var
  i: integer;
  nx,nx1,w: integer;
  adjrsqr,v: extended;
begin
  nx1:= xlist.n; nx:= nx1 - 1;
  w:= getwidth(xlist);
  adjrsqr:= rsqr - (1.0-rsqr)*(nx-1.0)/(nobs-nx);
  log.lf;
  writeln(log.f,'Number of permutations performed: ',nperm); log.lf; log.lf;
  writeln(log.f,'MODEL FIT'); log.lf;
  writeln(log.f,'R-square':8,'Adj R-Sqr':10,'Probability':12,'# of Obs':12);
  writeln(log.f,dash(8):8,dash(9):10,dash(11):12,dash(11):12);
  writeln(log.f,rsqr:8:3,adjrsqr:10:3,1.0*gtrsqr/nperm:12:4,nobs:12);

  log.lf; log.lf;
  if w < 12 then w:= 12;
  writeln(log.f,'REGRESSION COEFFICIENTS'); log.lf;
  writeln(log.f,' ':w,'Un-stdized':12,'Stdized':12,
    '':13,'Proportion':12,'Proportion':12);
  writeln(log.f,'Independent':w,'Coefficient':12,'Coefficient':12,
    'Significance':13,'As Large':12,'As Small':12);
  writeln(log.f,dash(w-1):w,dash(11):12,dash(11):12,
    dash(12):13,dash(11):12,dash(11):12);
  if beta.cell^[nx1] < 0
    then writeln(log.f,'Intercept':w,beta.cell^[nx1]:12:6,0.0:12:6,
      1.0*ltbeta.cell^[nx1]/nperm:13:4,1.0*gtbeta.cell^[nx1]/nperm:12:4,1.0*ltbeta.cell^[nx1]/nperm:12:4)
    else writeln(log.f,'Intercept':w,beta.cell^[nx1]:12:6,0.0:12:6,
      1.0*gtbeta.cell^[nx1]/nperm:13:4,1.0*gtbeta.cell^[nx1]/nperm:12:4,1.0*ltbeta.cell^[nx1]/nperm:12:4);
  for i:= 1 to nx do begin
    if sdy > 0 then v:= beta.cell^[i]*sdx.cell^[i]/sdy else v:= 0.0;
      if beta.cell^[i] < 0
        then writeln(log.f,xlist.sget(i):w,beta.cell^[i]:12:6,v:12:6,
          1.0*ltbeta.cell^[i]/nperm:13:4,
          1.0*gtbeta.cell^[i]/nperm:12:4,1.0*ltbeta.cell^[i]/nperm:12:4)
        else writeln(log.f,xlist.sget(i):w,beta.cell^[i]:12:6,v:12:6,
          1.0*gtbeta.cell^[i]/nperm:13:4,
          1.0*gtbeta.cell^[i]/nperm:12:4,1.0*ltbeta.cell^[i]/nperm:12:4);
    end;
  log.lf;
end;
{---------------------------------------------------------------------------}
procedure writesimpleresults(var log:logfile; nobs:integer;
                       rsqr,sdy:extended; var beta,sdx:evector;
                       var xlist:lvector);
var
  w,i: integer;
  nx,nx1: integer;
  adjrsqr,v: extended;
begin
  nx1:= xlist.n; nx:= nx1 - 1;
  w:= getwidth(xlist);
  adjrsqr:= rsqr - (1.0-rsqr)*(nx-1.0)/(nobs-nx);
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
  writeln(log.f,'Intercept':w,beta.cell^[nx1]:12:6,0.0:13:6);
  for i:= 1 to nx do begin
    if sdy > 0 then v:= beta.cell^[i]*sdx.cell^[i]/sdy else v:= 0.0;
    writeln(log.f,xlist.sget(i):w,beta.cell^[i]:12:6,v:13:6);
    end;
  log.lf;
end;
{---------------------------------------------------------------------------}
procedure autocorranova;
var
  a,b: dslvector;
  log: logfile;
  nb: smallint;
  n,j: integer;
  hasmissing: boolean;
  x,y,den: smatrix;
  xtx: ematrix;
  p,w,gtrsqr: integer;
  pbeta,beta,sdx: evector;
  xlist: lvector;
  index,gtbeta,ltbeta: ivector;
  sdy,prsqr,rsqr: extended;
  dsl: dslvector;
  first: boolean;
label
  start,cleanup;

  procedure handleexpected;
  label cleanup;
  var
    i,j,k,l: integer;
    yhat: double;
    exp: tsmatds;
  begin
    exp:= tsmatds.create;
    if not exp.allocsize(y.nr,y.nc) then goto cleanup;
    k:= 0;
    for i:= 1 to y.nr do
      for j:= 1 to y.nc do
        if (j >= i) or asymok then
          if (i<>j) or diagok then begin
            inc(k);
            yhat:= 0;
            for l:= 1 to x.nc do
              yhat:= yhat + x.cell^[k]^[l]*beta.cell^[l];
            exp.cell[i,j]:= yhat;
            if not asymok then exp.cell[j,i]:= yhat;
            end;
    exp.title:= 'Expected values from Anova Density model (' + methstr(method) + ')';
    exp.save(expfn);
    log.lf; writeln(log.f,'Expected values saved as dataset ',expfn); log.lf;
    cleanup:
      exp.destroy;
  end;

begin
  askcategoricalparameters; if error <> 0 then exit;

  xtx:= ematrix.create; y:= smatrix.create; a:= dslvector.create; b:= dslvector.create;
  beta:= evector.create; index:= dslvector.create; dsl:= dslvector.create;
  x:= smatrix.create; pbeta:= evector.create; gtbeta:= sivector.create;
  ltbeta:= sivector.create; xlist:= lvector.create; sdx:= evector.create;
  den:= smatrix.create;
  log:= logfile.stdcreate('NETWORK AUTOCORRELATION with categorical attributes','ucinet');
  log.putfn( 'Network/Proximities: ',ifn);
  log.putstr('Attribute(s): ',attribstr);
  log.putstr('Method: ',methstr(method));
  log.putstr('# of Permutations:',istr(nperm,0));
  log.putstr('Random seed: ',istr(seedvalue,0));
  log.lf;

  if cant(y.load(ifn)) then goto cleanup;
  if y.nr <> y.nc then begin
          MessageDlg('ERROR: Proximity matrix must be square.',
                         mtError, [mbOK], 0);
          goto cleanup;
  end;
  n:= y.nr;

  if attribstr = 'NONE' then begin
    MessageDlg('ERROR: No Actor Attribute file specified.', mtError, [mbOK], 0);
    goto cleanup;
    end;
  if cant(getvector(a,attribstr)) then goto cleanup;
  if a.n <> n then begin
      MessageDlg('ERROR: Attribute '+attribstr+' must be of length '+
                 istr(n,0), mtError, [mbOK], 0);
      goto cleanup;
  end;
  renumberlistwithmap(a,b); nb:= b.n;
  codemap(log.f,b);
  den.allocsize(nb,nb);
  if can(blockdensity(y,den,a,a,nb,nb,diagok))then begin
    if can(den.rdvn.allocsize(nb)) then
      for j:= 1 to nb do den.rdvn.sput(j,inttostr(b.cell^[j]));
    den.cdvn.copy(den.rdvn);
    den.display(log.f,pagewidth,0,defaultd);
    den.title:= 'Density table';
    den.save(denfn);
    log.lf;
    writeln(log.f,'Density table saved as dataset ',denfn); log.lf;
    end;

  case method of
     1: constructchdata(x,a,xlist,log.f); {constant homophily}
     2: constructvhdata(x,a,xlist,nb,log.f); {variable homophily}
     3: constructsbmdata(x,a,xlist,nb,log.f); {structural blockmodel}
     6: constructcp1data(x,a,xlist,nb,log.f); {one 1-block c/p structure}
     7: constructcp2data(x,a,xlist,nb,log.f); {one 1-block c/p structure}
     else begin
       MessageDlg('ERROR: Unknown method', mtError, [mbOK], 0);
       goto cleanup;
       end;
     end;

  if cant(beta.allocsize(x.nc)) then goto cleanup;
  if cant(dsl.allocsize(y.nr)) then goto cleanup;
  if cant(index.allocsize(x.nc)) then goto cleanup;
  if cant(xtx.allocsize(x.nc,x.nc)) then goto cleanup;
  if cant(gtbeta.allocsize(x.nc)) then goto cleanup;
  if cant(ltbeta.allocsize(x.nc)) then goto cleanup;
  if cant(pbeta.allocsize(x.nc)) then goto cleanup;
  if cant(sdx.allocsize(x.nc)) then goto cleanup;

  if cant(getcolsd(sdx,x,diagok)) then goto cleanup;
  if cant(getmatrixsd(sdy,y)) then goto cleanup;

  mrqap(beta,rsqr,x,y,xtx,dsl,index,true);
  handleExpected;

  if nperm < 1 then nperm:= 1;
  WaitingStart('Calculating ....',nperm,true);
  randseed:= seed; gtrsqr:= 0;
  if nperm > 1 then for p:= 2 to nperm do begin
    if p mod 100 = 0 then ShowProgress(p);
    nextrandperm(dsl);
    mrqap(pbeta,prsqr,x,y,xtx,dsl,index,false);
    if prsqr >= rsqr then inc(gtrsqr);
    for j:= 1 to x.nc do begin
      if pbeta.cell^[j] >= beta.cell^[j] then inc(gtbeta.cell^[j]);
      if pbeta.cell^[j] <= beta.cell^[j] then inc(ltbeta.cell^[j]);
    end;
  end;
  WaitingEnd;

//  writeln(log.f,'rsqr = ',rsqr:0:3);

  if nperm > 1
    then writesignificances(log,gtrsqr,nperm,x.nr,rsqr,sdy,beta,sdx,ltbeta,gtbeta,xlist)
    else writesimpleresults(log,x.nr,rsqr,sdy,beta,sdx,xlist);
  log.browse;
  goto cleanup;
cleanup:
 log.free;
  xtx.free;
  y.free;
  a.free;
  b.free;
  beta.free;
  index.free;
  dsl.free;
  x.free;
  pbeta.free;
  gtbeta.free;
  ltbeta.free;
  xlist.free;
  sdx.free;
  den.free;

end;
{---------------------------------------------------------------------------}
end.
