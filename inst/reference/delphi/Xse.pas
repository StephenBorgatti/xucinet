unit xSE;

interface
uses
    Forms,Waiting,Dialogs,Controls,ProfDlg,UFn, sysutils,
    ucommon, ugeneral,ualloc,ucan,umatrix,ustring,uitem,ukey,
    ug2sim,unetcorr,xtools,uvector,ubmatrix,udataset, PlotClus,
    utsmat, utsmat3, utsmat3ds, utsmatds, utevec, utsvec, ug2display,
    utransition, utlogfile, ujohnsonhiclus, utimat, utimatds,
    ug2textdendrogram;
{---------------------------------------------------------------------------}
function lilsim(r:tsmat; m:tsmat3; simdis:simfunc;
         transp,usedist:boolean; diag:integer): boolean;
procedure structuralequivalence;
{===========================================================================}
implementation
uses Ucinet;
{===========================================================================}
const
  ofn: filename = 'SE';
  pfn: filename = 'SEPart';
  ifn: filename = '';
  transp: boolean = true;
  diag: smallint = 4;
  usedist: boolean = false;
  meas: smallint = 1;
  DType: string = 'Dendrogram';
  measstr: array[1..7] of string = (
    'EUCLIDEAN DISTANCE','CORRELATION','MATCHES','POSITIVE MATCHES','OVERLAPS','SUM OF CROSS-PRODUCTS','COVERAGE');
  meassyn: array[1..7] of string = (
    'E|D','COR|PE','M','PO|PM','O','S','COV');
{---------------------------------------------------------------------------}
function whichtype(s:string): smallint;
begin
  if iskey(s,'D') then whichtype:= 1
  else
      if iskey(s,'T') then whichtype:= 2
      else
          whichtype:= 0;
end;
{---------------------------------------------------------------------------}
  function askparameters(var ifn:string): smallint;
  label cleanup;
  var
     ProfileDlg : TProfileDlg;
  begin
     ProfileDlg := TProfileDlg.Create(Application);
     with ProfileDlg do begin
          if DisplayFullPathnames = true then begin
             InputFn.Text := ifn;
             InputFn.SelStart := Length(ifn);
          end
          else InputFn.Text := FnAndExt(ifn);
          Measure.Text := measstr[meas];
          Method.itemindex := diag-1;
          Transpose.itemindex := byte(transp);
          Convert.Text := bstr(usedist);
          OutputFn.Text := ofn;
          OutputPar.Text := pfn;
          DiagramType.Text := DType;
     end;
     ProfileDlg.Showmodal;
     if ProfileDlg.ModalResult = mrOK then begin
          meas:= whichitem(ProfileDlg.Measure.Text,meassyn,7);
          if strb(ProfileDlg.Transpose.Text,transp,true) = 0 then;
          diag:= profiledlg.Method.ItemIndex + 1;
          if (not transp) and (diag in [2,3]) then diag:= 6;
          if (not transp) and (diag in [4,5]) then diag:= 7;
          if strb(ProfileDlg.Convert.Text,usedist,true) = 0 then;
          ifn := ProfileDlg.InputFn.Text;
          ofn := outdir(ProfileDlg.OutputFn.Text);
          pfn := outdir(ProfileDlg.OutputPar.Text);
          DType := ProfileDlg.DiagramType.Text;
          error := 0;
     end;
     if ProfileDlg.ModalResult = mrCancel then error := 1;
     askparameters:= error;
     ProfileDlg.Free;
  end;
{---------------------------------------------------------------------------}
(*  function oldlilsim(fn:filename; var r:smatrix; simdis:simfunc;
    transp,usedist:boolean; diag:smallint): smallint;
  label cleanup;
  type
    varray = array[1..100] of ^smatrix;
  var
    m: varray;
    err,nrel,n,nn,i,j,k,l: smallint;
    x,y: evector;
    z: extended;
    nmiss: longint;
    id: boolean;

    procedure build(l,a,b,c,d:smallint);
    begin
      inc(nn);
      x.cell^[nn]:= m[l]^.cell^[a]^[b];
      y.cell^[nn]:= m[l]^.cell^[c]^[d];
      if (x.cell^[nn] >= na) or (y.cell^[nn] >= na) then dec(nn);
    end;

  begin
    err:=0;
    nrel:= r.df.nl; n:= r.n;
    if nrel > 100 then begin
      MessageDlg('ERROR: Too many relations in dataset.', mtError, [mbOK], 0);
      lilsim := 1;
      exit;
    end;
    x.init; y.init;
    for l:= 1 to nrel do begin
        new(m[l],init);
        if m[l]^.allocsize(n,n) <> 0 then goto cleanup;
    end;
    if r.openinfile(dsys(fn)) <> 0 then goto cleanup;
    WaitinggaugeStart('Calculating ...',n); id := true;
    for l:= 1 to nrel do begin
        if m[l]^.loadfile(r.df.indf) <> 0 then goto cleanup;
        if usedist then mfloyd(m[l]^,nmiss);
    end;

    r.closeinfile;

    nn:= longint(n)*nrel; if transp then nn:= longint(nn)*2;
    if x.allocsize(nn) <> 0 then goto cleanup;
    if y.allocsize(nn) <> 0 then goto cleanup;

    for i:= 1 to n do begin
//        ShowProgressbinned(i);
        for j:= 1 to i do begin
            nn:= 0;
            for l:= 1 to nrel do begin
                for k:= 1 to n do
                    if (k <> i) and (k <> j) or (diag = valid) then
                        build(l,i,k,j,k);
                if diag = recip then begin
                    build(l,i,j,j,i);
                    if i <> j then build(l,i,i,j,j);
                end;
                if transp then begin
                    for k:= 1 to n do
                        if ((k <> i) and (k <> j)) or (diag = valid) then
                            build(l,k,i,k,j);
                    if diag = recip then begin
                        build(l,i,j,j,i);
                        if i <> j then build(l,i,i,j,j);
                    end;
                end;
            end;
            x.n:= nn; y.n:= nn;
            simdis(x,y,z);
            r.cell^[i]^[j]:= z; r.cell^[j]^[i]:= z;
        end;
    end;

    WaitingEnd;

  cleanup:
    y.dealloc; x.dealloc;
    for l:= nrel downto 1 do begin
        m[l]^.dealloc;
        dispose(m[l],done);
    end;
    if id then begin WaitingEnd; id := false; end;
    lilsim:= err;
  end; *)
{---------------------------------------------------------------------------}
  Function mfloyd(d:tsmat3; rel:integer):smallint;
  {input is adjacency matrix. output is geodesic distance matrix}
  Label cleanup;
  Var
    s: single;
    i,j,k: integer;
  Begin
    for i:= 1 to d.n do d.cell[rel,i,i]:= 0;
    for i:= 1 to d.n do begin
      for j:= 1 to d.n do
            if d.cell[rel,j,i] > 0 then
               for k:= 1 to d.n do
                   if (d.cell[rel,i,k] > 0) then begin
                      s:= d.cell[rel,j,i] + d.cell[rel,i,k];
                      if (d.cell[rel,j,k] = 0) or (s < d.cell[rel,j,k]) then
                         d.cell[rel,j,k]:= s;
                   end;
      end;
    for i:= 1 to d.n do
      for j:= 1 to d.n do if i = j
          then d.cell[rel,i,j]:= 0
          else if d.cell[rel,i,j] = 0
            then d.cell[rel,i,j]:= d.n;
  cleanup:
    mFloyd := error;
  End;
{---------------------------------------------------------------------------}
  function lilsim(r:tsmat; m:tsmat3; simdis:simfunc;
    transp,usedist:boolean; diag:integer): boolean;
  label cleanup;
  var
    err,nrel,n,nn,i,j,k,l,top: integer;
    x,y: tevec;
    z: extended;
    nmiss: longint;
    id,sym: boolean;

    procedure build(l,a,b,c,d: integer);
    begin
      if (m.cell[l,a,b] < na) and (m.cell[l,c,d] < na) then begin
        inc(nn);
        x.cell[nn]:= m.cell[l,a,b];
        y.cell[nn]:= m.cell[l,c,d];
        end;
    end;

  begin
    err:=0;
    x:= tevec.create;
    y:= tevec.create;
    nrel:= m.nm; n:= m.n;
    for l:= 1 to nrel do begin
      if usedist then mfloyd(m,l);
    end;
    nn:= longint(n)*nrel;
    if transp then nn:= longint(nn)*2;
    if not x.allocsize(nn) then goto cleanup;
    if not y.allocsize(nn) then goto cleanup;

    for i:= 1 to n do begin
      if sym
        then top:= i
        else top:= n;
        for j:= 1 to i do begin
            nn:= 0;
            for l:= 1 to nrel do begin
                for k:= 1 to n do
                    if (k <> i) and (k <> j) or (diag = valid) then
                        build(l,i,k,j,k);
                if diag = recip then begin
                    build(l,i,j,j,i);
                    if i <> j then build(l,i,i,j,j);
                end;
                if transp then begin
                    for k:= 1 to n do
                        if ((k <> i) and (k <> j)) or (diag = valid) then
                            build(l,k,i,k,j);
                    if diag = recip then begin
                        build(l,i,j,j,i);
                        if i <> j then build(l,i,i,j,j);
                    end;
                end;
            end;
            x.n:= nn; y.n:= nn;
            simdis(x,y,z);
            r.cell[i][j]:= z;
            if sym then r.cell[j][i]:= z;
        end;
    end;

  cleanup:
    y.dealloc; x.dealloc;
    lilsim:= err = 0;
  end;
{---------------------------------------------------------------------------}
(*
procedure LilStructuralEquivalence;
label
  start,cleanup;
var
  log: logfile;
  r: tsmatds;
  m: tsmat3ds;
  sf: simfunc;
  err: smallint;
  berror,sym: boolean;

  function clustering: boolean;
  label cleanup;
  var
    r2: smatrix;
    i,j: integer;
  begin
    r2:= smatrix.create;
    if cant(r2.allocsize(r.nr,r.nc)) then goto cleanup;
    for i:= 1 to r.nr do for j:= 1 to r.nc do
      r2.cell^[i]^[j]:= r.cell[i,j];
    copytolvector(r2.rdvn,r.rdvn);
    copytolvector(r2.cdvn,r.cdvn);
    if cant(runcluster(r2,log.f,meas > 1,averagelink,pfn,
      'Hierarchical Clustering of Equivalence Matrix',dendrochar,pagewidth))
      then goto cleanup;
    cleanup:
      r2.free;
      result:= error = 0;
    end;

begin
try
start:
  { 64-bit guard removed 2026-07-05 (stale): this unit already mixes G1 basic
    ops with G2 units and/or uses shared engines (uclus/utabu/ugenetic/usvd/
    ubetween/udsl) that are pointer-size-clean and proven by unguarded,
    64-bit-working routines.  Full G2 migration deferred with those engines. }
  if askparameters(ifn) <> 0 then exit;

  berror := true;
  err:=1;
  m:= tsmat3ds.create;
  r:= tsmatds.create;
  log:= logfile.stdcreate('Profile Structural Equivalence',copyright);
  case meas of
    1: log.putstr('Measure:','Euclidean Distance');
    2: log.putstr('Measure:','Pearson Correlation');
    3: log.putstr('Measure:','Percent of Exact Matches');
    4: log.putstr('Measure:','Percent of Positive Matches');
    5: log.putstr('Measure:','Number of Overlaps');
  end;
  log.putstr('Include transpose',bstr(transp));
  log.putstr('Diagonal:',methstr(diag));
  log.putstr('Use geodesics?',bstr(usedist));
  log.dataset(ifn); log.lf;

  if not m.load(hsys(ifn)) then goto cleanup;
  if m.nr <> m.nc then begin
      MessageDlg('ERROR: File '+ifn+' does not contain a square matrix.',
                         mtError, [mbOK], 0);
      goto cleanup;
  end;
  if not r.allocsize(m.nr,m.nr) then goto cleanup;
  r.rdvn.copy(m.rdvn); r.cdvn.copy(m.rdvn);

  sym:= true;
  case meas of
    1: sf:= euclid;
    2: sf:= correlation;
    3: sf:= matches;
    4: sf:= posmatches;
    5: sf:= overlaps;
    6: sf:= sscp;
    7: begin sym:= false; sf:= coverage; end;
  end;

  if cant(sesim2(r,m,sf,sym,transp,usedist,diag)) then
      goto cleanup;
  log.lf;
  r.title:= 'Structural Equivalence Matrix';
  if r.n <= displaysize
    then display(log.f,r,pagewidth,6,2)
    else writeln(log.f,'Display suppressed due to large size.');
  if cant(r.save(ofn)) then goto cleanup;
  case meas of
    1..6: begin
            if not clustering then goto cleanup;
            if MainForm.DisplayGraphicalDendrograms1.Checked then
              Create_Dendrogram(pfn,false,whichtype(DType),false);
            end;
    else
    end;

  log.outfile('Output actor-by-actor equivalence matrix saved as dataset ',ofn);
  log.outfile('Output partition-by-actor indicator matrix saved as dataset ',pfn);

  WaitingEnd;

  err := 0;
  berror := false;

cleanup:
 log.browse;
  MainForm.Enabled := true;
  r.free; m.free;
  log.free;
  if berror then goto start;
//  ifn := ofn;
except
  log.free;
  WaitingEnd;
end;
end;
*)
{---------------------------------------------------------------------------}
procedure LilStructuralEquivalence2;
label
  start,cleanup;
var
  log: tlogfile;
  r: tsmatds;
  m: tsmat3ds;
  sf: simfunc;
  err: smallint;
  berror,sym: boolean;

  function clustering: boolean;
  var
    d: tsmat;
    p: timat;
    pds: timatds;
    level: tsvec;
    npart, i: integer;
  begin
    result:= false;
    d:= tsmat.create;
    p:= timat.create;
    pds:= timatds.create;
    level:= tsvec.create;
    try
      // work on a copy since johnson modifies the matrix
      d.allocate(r.n, r.n, -1, true, false);
      d.copyval(r);
      d.rdvn.copy(r.rdvn); d.cdvn.copy(r.cdvn);
      if not JohnsonHiclus(d, p, meas > 1, wtdaveragelink, level) then exit;
      npart:= p.nc;
      // set partition labels from merge levels
      p.cdvn.allocate(npart, true, false);
      for i:= 1 to npart do
        p.cdvn.setvalue(i, formatfloat('0.###', level.cell[i]));
      p.rdvn.copy(r.rdvn);
      p.title:= 'Partition Indicator Matrix';
      // display dendrogram
      if r.n <= displaysize then
        textdendrogram(log, p);
      // save via timatds
      pds.allocate(p.nr, p.nc, 1, true, true);
      pds.copyval(p);
      pds.rdvn.copy(p.rdvn); pds.cdvn.copy(p.cdvn);
      pds.title:= p.title;
      pds.save(pfn);
      result:= true;
    finally
      d.free; p.free; pds.free; level.free;
    end;
  end;

begin
try
start:
  if askparameters(ifn) <> 0 then exit;

  berror := true;
  err:=1;
  m:= tsmat3ds.create;
  r:= tsmatds.create;
  log:= tlogfile.stdcreate('Profile Structural Equivalence',copyright);
  case meas of
    1: log.putstr('Measure:','Euclidean Distance');
    2: log.putstr('Measure:','Pearson Correlation');
    3: log.putstr('Measure:','Percent of Exact Matches');
    4: log.putstr('Measure:','Percent of Positive Matches');
    5: log.putstr('Measure:','Number of Overlaps');
  end;
  log.putstr('Include transpose',bstr(transp));
  log.putstr('Diagonal:',methstr(diag));
  log.putstr('Use geodesics?',bstr(usedist));
  log.dataset(ifn); log.lf;

  if not m.load(hsys(ifn)) then goto cleanup;
  if m.nr <> m.nc then begin
      MessageDlg('ERROR: File '+ifn+' does not contain a square matrix.',
                         mtError, [mbOK], 0);
      goto cleanup;
  end;
  if not r.allocsize(m.nr,m.nr) then goto cleanup;
  r.rdvn.copy(m.rdvn); r.cdvn.copy(m.rdvn);

  sym:= true;
  case meas of
    1: sf:= euclid;
    2: sf:= correlation;
    3: sf:= matches;
    4: sf:= posmatches;
    5: sf:= overlaps;
    6: sf:= sscp;
    7: begin sym:= false; sf:= coverage; end;
  end;

  if cant(sesim2(r,m,sf,sym,transp,usedist,diag)) then
      goto cleanup;
  log.lf;
  r.title:= 'Structural Equivalence Matrix';
  if r.n <= displaysize
    then r.displayasmatrix(log.stream)
//    then display(log.f,r,pagewidth,6,2)
    else log.writeln('Display suppressed due to large size.');
  if cant(r.save(ofn)) then goto cleanup;
  case meas of
    1..6: begin
            if not clustering then goto cleanup;
            if MainForm.DisplayGraphicalDendrograms1.Checked then
              Create_Dendrogram(pfn,false,whichtype(DType),false);
            end;
    else
    end;

  log.outfile('Output actor-by-actor equivalence matrix saved as dataset ',ofn);
  log.outfile('Output partition-by-actor indicator matrix saved as dataset ',pfn);

  WaitingEnd;
  log.browse;

  err := 0;
  berror := false;

cleanup:
  MainForm.Enabled := true;
  r.free; m.free;
  log.free;
  if berror then goto start;
//  ifn := ofn;
except
  log.free;
  WaitingEnd;
end;
end;
{---------------------------------------------------------------------------}
procedure structuralequivalence;
begin
  lilstructuralequivalence2;
end;
{---------------------------------------------------------------------------}
End.
