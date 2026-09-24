unit utqapsim;
interface
uses
  windows, dialogs,sysutils,classes, system.threading, system.syncobjs, 
  generics.collections, math,
  ucommon,ugeneral,utsim, utsmat, utivec, urandom, upermutations, ustats, utadjlist, utsmatds,
  ug2display, utimat, utsvec, umath, ustring, ucorrmat, 
  urandomthreadsafe;

type
  tqapsim = class
    results: tsmatds;
    sym,hasna,binary,parallel,twotailed: boolean;
    seed,nperm: integer;
    sim: tsim;
    s: array of uestimator;
    constructor create;
    function getmeasures(a,b:tsmat; c:tsim; idx:tivec): boolean;
    procedure runpermutations(a,b:tsmat);
    procedure runfastpermutations(a,b:tsmat; hasna:boolean);
    procedure print(var f:textfile; var1,var2:string); overload;
    procedure print(sw:tstreamwriter; var1,var2:string); overload;
    destructor destroy; override;
    end;

implementation

constructor tqapsim.create;
var
  i: integer;
begin
  sim:= tsim.create;
  sym:= false;
  hasna:= true;
  nperm:= 20000;
  seed:= 32767;
  binary:= false;
  parallel:= false;
  twotailed:= false;
  results:= tsmatds.create;
  results.allocsize(sim.nvar,10);
  results.rdvn.copy(sim.meas.rdvn);
  results.cdvn.allocsize(10);
  results.cdvn.sput(1,'Obs Value');
  results.cdvn.sput(2,'Significance');
  results.cdvn.sput(3,'Average');
  results.cdvn.sput(4,'Std Dev');
  results.cdvn.sput(5,'Minimum');
  results.cdvn.sput(6,'Maximum');
  results.cdvn.sput(7,'Prop >= Obs');
  results.cdvn.sput(8,'Prop <= Obs');
  results.cdvn.sput(9,'N Obs');
  results.cdvn.sput(10,'Prop |perm|>=|obs|');
  setlength(s,sim.nvar+1);
  for i:= 1 to sim.nvar do s[i]:= uestimator.create;
end;

destructor tqapsim.destroy;
var i: integer;
begin
  for i:= 1 to sim.nvar do s[i].free;
  s:= nil;
  results.free;
  sim.Free;
end;

function tqapsim.getmeasures(a,b:tsmat; c:tsim; idx:tivec): boolean;
var
  i,j: integer;
begin
  c.clear;
  if sym
    then if hasna
      then begin
        for i:= 2 to a.n do for j:= 1 to i-1 do
          if not (a.isna(i,j) or b.isna(idx[i],idx[j])) then
            c.addcase(a.cell[i,j],b.cell[idx[i],idx[j]]);
        end
      else begin
        for i:= 2 to a.n do for j:= 1 to i-1 do
            c.addcase(a.cell[i,j],b.cell[idx[i],idx[j]]);
        end
    else if hasna
      then begin
        for i:= 1 to a.nr do for j:= 1 to a.nc do if i<>j then
          if not (a.isna(i,j) or b.isna(idx[i],idx[j])) then
            c.addcase(a.cell[i,j],b.cell[idx[i],idx[j]]);
        end
      else begin
        for i:= 1 to a.nr do for j:= 1 to a.nc do if i<>j then
          c.addcase(a.cell[i,j],b.cell[idx[i],idx[j]]);
        end;
    c.calc;
    result:= true;
  end;

procedure tqapsim.runpermutations(a,b:tsmat);
label cleanup;
var
  k: integer;
  x,obs: double;
  mainidx: tivec;
  i: integer;
  ngreater,nlesser,nextreme: tivec;
  randomseeds: arrayofinteger;
  localseed: integer;

  procedure runparallel;
  begin
    TParallel.For(1, nperm, procedure (kk: Integer)
    var
      x: double;
      idx: tdsl;
      c: tsim;
      i: integer;
      seed: integer;
    begin
      idx:= tdsl.create;
      c:= tsim.create;
      idx.allocate(a.n,true,true);
      randomizepermutation(idx,randomseeds[kk]);
      getmeasures(a,b,c,idx);
      for i:= 1 to c.nvar do begin
        if c.meas[i,1] >= results.cell[i,1] then tinterlocked.increment(ngreater.cell[i]);
        if c.meas[i,1] <= results.cell[i,1] then tinterlocked.increment(nlesser.cell[i]);
        if abs(c.meas[i,1]) >= abs(results.cell[i,1]) then tinterlocked.increment(nextreme.cell[i]);
        s[i].addcase(c.meas[i,1]);
        end;
      freeandnil(idx); freeandnil(c);
      end);
  end;

  procedure runregular;
  var
    k,i: integer;
    c: tsim;
    idx: tdsl;
  begin
    c:= tsim.create;
    idx:= tdsl.create;
    idx.allocate(a.n,true,true);
    for k:= 1 to nperm do begin
      idx.one2n();
      randomizepermutation(idx,randomseeds[k]);
      getmeasures(a,b,c,idx);
      for i:= 1 to c.nvar do begin
        if c.meas[i,1] >= results.cell[i,1] then inc(ngreater.cell[i]);
        if c.meas[i,1] <= results.cell[i,1] then inc(nlesser.cell[i]);
        if abs(c.meas[i,1]) >= abs(results.cell[i,1]) then inc(nextreme.cell[i]);
        s[i].addcase(c.meas[i,1]);
        end;
    end;
    freeandnil(c); freeandnil(idx);
  end;

begin
  ngreater:= tivec.create;
  nlesser:= tivec.create;
  nextreme:= tivec.create;
  mainidx:= tdsl.create;
  if not ngreater.allocsize(sim.nvar) then goto cleanup;
  if not nlesser.allocsize(sim.nvar) then goto cleanup;
  if not nextreme.allocsize(sim.nvar) then goto cleanup;
  if not mainidx.allocsize(a.nr) then goto cleanup;
  setlength(randomseeds,nperm+1);
  mainidx.one2n;
  getmeasures(a,b,sim,mainidx);
  for i:= 1 to sim.nvar do
    results.cell[i,1]:= sim.meas[i,1];
  ngreater.zerofill;
  nlesser.zerofill;
  nextreme.zerofill;
  for i:= 1 to sim.nvar do s[i].clear;
  localseed:= seed; {snapshot so q.seed isn't mutated across pairs}
  for k:= 1 to nperm do
    randomseeds[k]:= randomint(maxint,localseed);
  randseed:= localseed;
  if parallel
    then runparallel
    else runregular;
  if nperm > 0
    then for i:= 1 to sim.nvar do begin
      s[i].calc;
      results[i,3]:= s[i].mean;
      results[i,4]:= S[i].stddev;
      results[i,5]:= s[i].min;
      results[i,6]:= S[i].max;
      results.cell[i,7]:= (1.0+ngreater.cell[i])/(1.0+nperm); {prop as great}
      results.cell[i,8]:= (1.0+nlesser.cell[i])/(1.0+nperm);  {prop as small}
      results.cell[i,10]:= (1.0+nextreme.cell[i])/(1.0+nperm); {prop |perm|>=|obs|}
      if i in [2,3]
        then results.cell[i,2]:= results[i,8] {distance: always one-sided lower}
        else if twotailed
          then results.cell[i,2]:= results[i,10]
          else results.cell[i,2]:= na; {1-tailed: blank, user reads cols 7,8 directionally}
      results.cell[i,9]:= s[i].n;
      end;
cleanup:
  randomseeds:= nil;
  mainidx.destroy; ngreater.free; nlesser.free; nextreme.free;
end;

procedure tqapsim.runfastpermutations(a,b:tsmat; hasna:boolean);
label cleanup;
var
  k,i: integer;
  s: string;
  x,obs: double;
  idx: tivec;
  num,ngreater,nlesser,nextreme: integer;
  st: uestimator;
  corrs: tarray<single>;
  randoms: tivec;
  localseed: integer;

  procedure savecorrs(fn:string);
  var
    w: tstreamwriter;
    i: integer;
  begin
    w:= tstreamwriter.Create(fn+'.txt');
    for i:= 1 to nperm do begin
      w.Write(i);
      w.Write(' ');
      w.WriteLine(floattostr(corrs[i]));
      end;
    w.Free;
  end;

  procedure runparallel(seeds:tivec);
  begin
    TParallel.For(1, nperm, procedure (kk: Integer)
    var
      x: double;
      idx: tdsl;
    begin
      idx:= tdsl.create;
      idx.allocate(a.n,true,true);
      randomizepermutation(idx,seeds.cell[kk]);
      x:= corrmatidx(a,b,idx,sym,hasna,false);
      if x >= obs then tinterlocked.increment(ngreater);
      if x <= obs then tinterlocked.increment(nlesser);
      if abs(x) >= abs(obs) then tinterlocked.increment(nextreme);
      corrs[kk]:= x;
      freeandnil(idx);
      end);
  end;

  procedure runregular(seeds:tivec);
  var
    x: double;
    k: integer;
  begin
    for k:= 1 to nperm do begin
      idx.one2n();
      randomizepermutation(idx,seeds.cell[k]);
      x:= corrmatidx(a,b,idx,sym,hasna,false);
      if x >= obs then inc(ngreater);
      if x <= obs then inc(nlesser);
      if abs(x) >= abs(obs) then inc(nextreme);
      corrs[k]:= x;
    end;
  end;

begin
  st:= uestimator.create;
  idx:= tivec.create;
  randoms:= tivec.create;
  if not idx.allocsize(a.nr) then goto cleanup;
  idx.one2n;
//  results[1,1]:= c.getgamma(a,b,idx,sym);
  setlength(corrs,nperm+1);
  randoms.allocate(nperm,true,false);
  results.nr:= 1;
  obs:= corrmatidx(a,b,idx,sym,false,false);
  ngreater:= 0;
  nlesser:= 0;
  nextreme:= 0;
  localseed:= seed; {snapshot so q.seed isn't mutated across pairs}
  randseed:= localseed;
  for k:= 1 to nperm do
    randoms[k]:= randomint(maxint,localseed);
  if parallel
    then runparallel(randoms)
    else runregular(randoms);
  if (nperm > 0) then begin
    st.clear;
    for k:= 1 to nperm do begin
      st.addcase(corrs[k]);
      end;
    st.calc;
    results[1,1]:= obs;
    results[1,3]:= st.mean;
    results[1,4]:= st.stddev;
    results[1,5]:= st.min;
    results[1,6]:= st.max;
    results.cell[1,7]:= (1.0+ngreater)/(1.0+nperm); {prop as great}
    results.cell[1,8]:= (1.0+nlesser)/(1.0+nperm);  {prop as small}
    results.cell[1,10]:= (1.0+nextreme)/(1.0+nperm); {prop |perm|>=|obs|}
    if twotailed
      then results.cell[1,2]:= results[1,10]
      else results.cell[1,2]:= na; {1-tailed: blank, user reads cols 7,8 directionally}
    results.cell[1,9]:= st.n;
    end;
cleanup:
  idx.destroy; st.free; randoms:= nil; corrs:= nil;
end;

procedure tqapsim.print(var f:textfile; var1,var2:string);
var
  i: integer;
  tailstr: string;
begin
  results.rdsl.alloc(results.nr);
  results.rdsl.n:= 0;
  for i:= 1 to results.nr do
//    if not feq(results[i,5],results[i,6]) then results.rdsl.append(i);
    results.rdsl.append(i);
  if twotailed then tailstr:= '2-tailed' else tailstr:= '1-tailed';
  results.title:= 'QAP results for '+var1+' * '+var2 + ' (' + inttostr(nperm)+' permutations, '+tailstr+')';
  display(f,results,pagewidth,10,4);
  if not twotailed then begin
    writeln(f,'NOTE: 1-tailed mode. The "Significance" column is intentionally blank.');
    writeln(f,'      Use "Prop >= Obs" if your hypothesis predicted r > 0,');
    writeln(f,'      and  "Prop <= Obs" if your hypothesis predicted r < 0.');
    writeln(f,'      The direction must be chosen a priori, not after seeing the data.');
    end;
  if results.nr > 1 then begin
    writeln(f,'NOTE: When you have missing data, the significance of Hubert''s Gamma and Euclidean Distance will differ from that');
    writeln(f,'      of Pearson Correlation. Otherwise, they should be the same (unless the correlation is negative).');
    end;
end;

procedure tqapsim.print(sw:tstreamwriter; var1,var2:string);
var
  i: integer;
  tailstr: string;
begin
  results.rdsl.alloc(results.nr);
  results.rdsl.n:= 0;
  for i:= 1 to results.nr do
//    if not feq(results[i,5],results[i,6]) then results.rdsl.append(i);
    results.rdsl.append(i);
  if twotailed then tailstr:= '2-tailed' else tailstr:= '1-tailed';
  results.title:= 'QAP results for '+var1+' * '+var2 + ' (' + inttostr(nperm)+' permutations, '+tailstr+')';
  results.displayasmatrix(sw);
  if not twotailed then begin
    sw.writeline('NOTE: 1-tailed mode. The "Significance" column is intentionally blank.');
    sw.writeline('      Use "Prop >= Obs" if your hypothesis predicted r > 0,');
    sw.writeline('      and  "Prop <= Obs" if your hypothesis predicted r < 0.');
    sw.writeline('      The direction must be chosen a priori, not after seeing the data.');
    end;
  if results.nr > 1 then begin
    sw.writeline('NOTE: When you have missing data, the significance of Hubert''s Gamma and Euclidean Distance will differ from that');
    sw.writeline('      of Pearson Correlation. Otherwise, they should be the same (unless the correlation is negative).');
    end;
end;

end.
