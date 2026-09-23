Unit xstdize;

interface
uses
  NormDlg, Forms, SysUtils, Dialogs, Controls, UFn, ufnvcl, 
  ucommon, ugeneral,uufile,utsvec,utsmat,utsmatds,ucan,ustring,utlogfile,
  uitem,xtools, utunivariate;
{---------------------------------------------------------------------------}
procedure runnormalize;
{===========================================================================}
implementation
{===========================================================================}
const
  dm: single = 1.0;
  ifn: filename = '';
  ofn: filename = 'Normalize';
  dim: smallint = 3;
  maxit: smallint = 100;
  constant: single = 0.0;
  crit: single = 0.001;
  diagok: boolean = true;
  method: smallint = 1;
  dimstr: array[1..4] of string = (
    'Matrix','Rows','Columns','Both');
  dimsyn: array[1..4] of string = (
    'M','R','C','B');
  methstr: array[1..8] of string = (
    'Marginal','Mean','Std-Dev','Z-Score','Euclidean','Maximum','SQRT-Marginal','Correspondence');
  methsyn: array[1..8] of string = (
    'MAR|SU','ME','ST|SD','Z','E|N','MAX','SQ','C');
{---------------------------------------------------------------------------}
function askparameters: smallint;
label cleanup;
var
       NormalizeDlg : TNormalizeDlg;
begin
       NormalizeDlg := TNormalizeDlg.Create(Application);
       setdlgifn(normalizedlg.inputfn,ifn,ofn);
       NormalizeDlg.Output.Text := ofn;
       NormalizeDlg.WhichDims.Text := dimstr[dim];
       NormalizeDlg.StdMethod.Text := methstr[method];
       NormalizeDlg.Zeros.Text := floattostrf(constant,fffixed,7,6);
       if diagok then
            NormalizeDlg.Diagonal.Text := 'Yes'
       else
            NormalizeDlg.Diagonal.Text := 'No';
       NormalizeDlg.Tolerance.Text := floattostrf(crit,fffixed,7,5);
       NormalizeDlg.MaxIt.Text := istr(maxit,0);

       NormalizeDlg.Showmodal;
       if NormalizeDlg.ModalResult = mrOK then begin
            ifn := NormalizeDlg.InputFn.Text;
            ofn := outdir(NormalizeDlg.Output.Text);
            dim := whichitem(NormalizeDlg.WhichDims.Text,dimsyn,4);
            method := whichitem(NormalizeDlg.StdMethod.Text,methsyn,8);
            constant:= strtofloatdef(NormalizeDlg.Zeros.Text,0);
            strb(NormalizeDlg.Diagonal.Text,diagok,true);
            crit:= strtofloatdef(NormalizeDlg.tolerance.Text,0.001);
            maxit:= strtointdef(NormalizeDlg.maxit.Text,100);
            error := 0;
            end
       else
            error := 1;
cleanup:
       NormalizeDlg.Free;
       askparameters:= error;
end;
{---------------------------------------------------------------------------}
function runrowcols(m:tsmat):smallint;
label fin,cleanup;
var
  rerr,maxnrc,it,i,j: smallint;
  rowsok,colsok: boolean;
  a,a2,rt,ct,rt2,ct2: tsvec;

  procedure rcalc(v,v2:tsvec);
  var
    i,j: smallint;
    s: tunivariate;
  begin
    s:= tunivariate.create; rowsok:= true;
    for i:= 1 to m.nr do begin
        s.clear;
        for j:= 1 to m.nc do
            if (i<>j) or diagok then s.addcase(m.cell[i,j]);
        s.calc;
        case method of
            1,8: v.cell[i]:= s.tot;
            2: v.cell[i]:= s.mean;
            3: v.cell[i]:= s.stddev;
            4: begin v.cell[i]:= s.mean; v2.cell[i]:= s.stddev; end;
            5: v.cell[i]:= s.nrm;
            6: v.cell[i]:= s.max;
            7: v.cell[i]:= sqrt(s.tot);
        end;
        if (v.cell[i] < na) and (rt.cell[i] < na) and
           (abs(v.cell[i]-rt.cell[i]) > crit) then rowsok:= false;
        if (method = 4) then begin
            if (v2.cell[i] < na) and (rt2.cell[i] < na) and
           (abs(v2.cell[i]-rt2.cell[i]) > crit) then rowsok:= false;
        end;
    end;
    s.free;
  end;

  procedure ccalc(v,v2:tsvec);
  var
    i,j: smallint;
    s: tunivariate;
  begin
    s:= tunivariate.create; colsok:= true;
    for j:= 1 to m.nc do begin
        s.clear;
        for i:= 1 to m.nr do
            if (i<>j) or diagok then s.addcase(m.cell[i][j]);
        s.calc;
        case method of
            1,8: v.cell[j]:= s.tot;
            2: v.cell[j]:= s.mean;
            3: v.cell[j]:= s.stddev;
            4: begin v.cell[j]:= s.mean; v2.cell[j]:= s.stddev; end;
            5: v.cell[j]:= s.nrm;
            6: v.cell[j]:= s.max;
            7: v.cell[j]:= sqrt(s.tot);
        else
            MessageDlg('Big Mistake in Standardize', mtError, [mbOK], 0);
        end;
        if (v.cell[j] < na) and (ct.cell[j] < na) and
           (abs(v.cell[j]-ct.cell[j]) > crit) then colsok:= false;
        if (method = 4) then begin
           if (v2.cell[j] < na) and (ct2.cell[j] < na) and
           (abs(v2.cell[j]-ct2.cell[j]) > crit) then colsok:= false;
        end;
    end;
    s.free;
  end;

  procedure adjust(d:char; t,t2:tsvec);
  var
    i,j,k: smallint;
    x: extended;
  begin
    for i:= 1 to m.nr do
        for j:= 1 to m.nc do
            if (i<>j) or diagok then begin
                if d = 'r' then k:= i else k:= j;
                x:= m.cell[i][j];
                if x < na then begin
                    case method of
                         1,3,5,6,7,8: if a.cell[k] > 0 then
                                      x:= x*t.cell[k]/a.cell[k]
                                  else
                                      x:= bna;
                               2: x:= x+t.cell[k]-a.cell[k];
                               4: if a2.cell[k] > 0 then
                         x:= (x+t.cell[k]-a.cell[k])*t2.cell[k]/a2.cell[k]
                                  else
                                      x:= bna;
                    end;
                m.cell[i][j]:= x;
                end;
            end;
  end;

begin
  error := 0; rerr := 1;
  a:= tsvec.create; a2:= tsvec.create; rt:= tsvec.create; ct:= tsvec.create;
  rt2:= tsvec.create; ct2:= tsvec.create;
  if m.nr > m.nc then maxnrc:= m.nr else maxnrc:= m.nc;
  if cant(a.allocsize(maxnrc)) then goto cleanup;
  if cant(rt.allocsize(m.nr)) then goto cleanup;
  if cant(ct.allocsize(m.nc)) then goto cleanup;
  if method = 4 then begin
      if cant(a2.allocsize(maxnrc)) then goto cleanup;
      if cant(rt2.allocsize(m.nr)) then goto cleanup;
      if cant(ct2.allocsize(m.nc)) then goto cleanup;
  end;
  for i:= 1 to m.nr do
      case method of
           1,6,7,8: rt.cell[i]:= dm;
             2: rt.cell[i]:= 0;
           3,5: rt.cell[i]:= 1;
             4: begin rt.cell[i]:= 0; rt2.cell[i]:= 1; end;
      end;
  for i:= 1 to m.nc do
      case method of
             1: if dim = 4
                  then ct.cell[i]:= dm*m.nr/m.nc
                  else ct.cell[i]:= dm;
             2: ct.cell[i]:= 0;
           3,5: ct.cell[i]:= 1;
             4: begin ct.cell[i]:= 0; ct2.cell[i]:= 1; end;
             6,7,8: ct.cell[i]:= dm;
      end;
  if method = 8 then begin
    rcalc(a,a2); rt.copy(a); ccalc(a,a2); ct.copy(a);
    for i:= 1 to m.nr do if rt.cell[i] > 0 then for j:= 1 to m.nc do if ct.cell[j] > 0 then
      m.cell[i][j]:= m.cell[i][j]/sqrt(rt.cell[i]*ct.cell[j]);
    goto fin;
    end;

  case dim of
      2: begin rcalc(a,a2); adjust('r',rt,rt2); goto fin; end;
      3: begin ccalc(a,a2); adjust('c',ct,ct2); goto fin; end;
  end;
{  if method = 8 then begin
    rcalc(a,a2); ccalc(a,a2); adjust('r',rt,rt2); adjust('c',ct,ct2);
    goto fin;
    end;}

  ccalc(a,a2);
  adjust('c',ct,ct2); if error <> 0 then goto cleanup;
  {write('Iterations: ');}
  for it:= 1 to maxit do begin
      {write(' ',it);}
      {if keypressed and (readkey in [#27,#0]) then goto cleanup;}
      rcalc(a,a2);
      if rowsok then goto fin;
      adjust('r',rt,rt2);
      if error <> 0 then goto cleanup;
      ccalc(a,a2);
      if colsok then goto fin;
      adjust('c',ct,ct2);
      if error <> 0 then goto cleanup;
  end;
  MessageDlg('WARNING: iterative procedure has failed to converge.', mtError,
                       [mbOK], 0);
  fin:
      rerr := 0;
  cleanup:
      a.free; a2.free; rt.free; ct.free; rt2.free; ct2.free;
      runrowcols := rerr;
  end;
{---------------------------------------------------------------------------}
  procedure runmatrix(m:tsmat);
  label cleanup;
  var
    s: tunivariate;
    i,j: smallint;
    x: extended;
  begin
    s:= tunivariate.create;
    for i:= 1 to m.nr do
        for j:= 1 to m.nc do
            if (i<>j) or diagok then s.addcase(m.cell[i][j]);
    s.calc;
    for i:= 1 to m.nr do
        for j:= 1 to m.nc do
            if (i<>j) or diagok then begin
                x:= m.cell[i][j];
                if x < na then
                    case method of
                         1: if s.tot <> 0 then
                                x:= x*dm/s.tot
                            else
                                x:= bna;
                         2: x:= x-s.mean;
                         3: if s.stddev > 0 then
                                x:= x/s.stddev
                            else
                                x:= bna;
                         4: if s.stddev > 0 then
                                x:= (x-s.mean)/s.stddev
                            else
                                x:= bna;
                         5: if s.nrm > 0 then
                                x:= x/s.nrm
                            else
                                x:= bna;
                         6: if s.max <> 0 then
                                x:= x/s.max
                            else
                                x:= bna;
                    end;
                m.cell[i][j]:= x;
            end;
            error := 0;
  cleanup:
    s.free;
end;
{---------------------------------------------------------------------------}
procedure runnormalize;
label start,cleanup;
var
  log: tlogfile;
  j,i,k: smallint;
  m: tsmatds;
  berror: boolean;
begin
try
start:
  askparameters;
  if error <> 0 then exit;

  berror := true; error := 0;
  m:= tsmatds.create;
  log:= tlogfile.stdcreate('Normalize',copyright);
  log.putstr('Dimension:',dimstr[dim]);
  log.putstr('Method:',methstr[method]);

  if cant(m.loadhdr(hsys(ifn))) then goto cleanup;
  if m.nr <> m.nc then diagok:= true;

  log.putstr('Diagonal valid?',bstr(diagok));
  log.putfn('Input dataset',ifn);
  log.putfn('Output dataset',ofn);
  log.lf;

  for k:= 1 to m.nm do begin
      if cant(m.loaddat(dsys(ifn))) then goto cleanup;
      if not diagok then for i:= 1 to m.n do m.cell[i][i]:= bna;
      if constant <> 0.0 then
          for i:= 1 to m.nr do
              for j:= 1 to m.nc do
                  if abs(m.cell[i][j]) < singleprecision then
                      m.cell[i][j]:= constant;
      case dim of
           1: runmatrix(m);
       2,3,4: if cant(runrowcols(m)) then goto cleanup;
      end;
      if error <> 0 then goto cleanup;
      m.displayasmatrix(log.stream);
      if cant(m.savedat(dsys(ofn))) then goto cleanup;
  end;

  if cant(m.savehdr(hsys(ofn))) then goto cleanup;
  log.putfn('Normalized matrix saved as dataset ',ofn);

  log.browse;
  berror := false;
  defaultfn:= ofn;

cleanup:
  log.free; m.free;
  if berror then goto start;
//  ifn := ofn;
except
  log.free;
end;
end;
{===========================================================================}
End.
