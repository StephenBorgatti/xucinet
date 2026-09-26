Unit UClus;

Interface
Uses
    Forms,UFn, {xKCore,}
    ucan,ucommon,ugeneral,ustring,ualloc,uufile,umath,
    uvector,umatrix,usmatrix,usimatrix,udendro, utlogfile; {uvmatrix,}
{===========================================================================}
Function ncd(var p:simatrix; var d:smatrix; sim:boolean; method:smallint;
  var npart:integer; var level:svector): smallint;
function JohnsonF(var uf:ufile; var d:smatrix; sim:boolean; method:smallint;
  var npart:smallint; var level:svector): smallint;
function JohnsonF2(var uf:ufile; var d:smatrix; sim:boolean; method:smallint;
  var npart:integer; var level:svector): smallint;
function Johnson2(var p:simatrix; var d:smatrix; sim:boolean; method:smallint;
  var npart:integer; var level:svector): smallint;
function mJohnsonF2(var uf:ufile; var d:matrix; sim:boolean; method:smallint;
  var npart:smallint; var level:svector; saveall:boolean): smallint;
Procedure runSingleLink(var uf:ufile; var d:imatrix; var npart:smallint; var level:ivector);
function runcluster2(var ov:smatrix; var f:text;
  sim:boolean; method:smallint; pfn:filename; tit:string;
  dchar:char; pw:smallint): smallint;
function runcluster(var ov:smatrix; var f:text;
  sim:boolean; method:smallint; pfn:filename; tit:string;
  dchar:char; pw:smallint): smallint;
function runclusternew(var ov:smatrix; log:tlogfile;
  sim:boolean; method:smallint; pfn:filename; tit:string;
  dchar:char; pw:smallint): smallint;
function vruncluster(var ov:matrix; var f:text;
  sim:boolean; method:smallint; pfn:filename; tit:string;
  dchar:char; pw:smallint): smallint;
procedure km1(var d:smatrix; var p:ivector; nb:integer; sim:boolean);
function mincomp(x,y:single; s1,s2:integer): single;
function maxcomp(x,y:single; s1,s2:integer): single;
function avgcomp(x,y:single; s1,s2:integer): single;
function simpleavgcomp(x,y:single; s1,s2:integer): single;
type
  minmaxtype = function(x,y:single; s1,s2:integer): single;
Const
  singlelink = 1; completelink = 2; averagelink = 3; wtdaveragelink = 3;
  simpleaveragelink = 4;
{===========================================================================}
Implementation
{===========================================================================}
{---------------------------------------------------------------------------}
function mincomp(x,y:single; s1,s2:integer): single;
begin
     if x > y then mincomp:= y else mincomp:= x;
end;
{---------------------------------------------------------------------------}
function maxcomp(x,y:single; s1,s2:integer): single;
begin
     if x < y then maxcomp:= y else maxcomp:= x;
end;
{---------------------------------------------------------------------------}
function avgcomp(x,y:single; s1,s2:integer): single;
begin
     avgcomp:= (x*s1 + y*s2)/(s1+s2);
end;
{---------------------------------------------------------------------------}
function simpleavgcomp(x,y:single; s1,s2:integer): single;
begin
     result:= (x + y)/2.0;
end;
{---------------------------------------------------------------------------}
function JohnsonF(var uf:ufile; var d:smatrix; sim:boolean; method:smallint;
  var npart:smallint; var level:svector): smallint;
{assumes uf is open; level may be pre-allocated, but not required}
{standard algorithm}
label cleanup;
Var
  err,n,it,ni,nj,i,j: smallint;
  size,part: tosmallintvector;
  subsumed: ^booleanvector;
  lastd,dist: single;
  comp: minmaxtype;

  Procedure GetClosestPair;
  {find closest pair among unsubsumed positions}
  Var i,j: smallint;
  Begin
    if sim then begin
       dist:= minfloat;
       for i:= 2 to n do
           if not subsumed^[i] then
              for j:= 1 to i-1 do
                  if (not subsumed^[j]) and (d.cell^[i]^[j] > dist) then begin
                     ni:= i;
                     nj:= j;
                     dist:= d.cell^[i]^[j];
                     end
                  else
                     else;
        end
    else
        begin
        dist:= maxfloat;
        for i:= 2 to n do
            if not subsumed^[i] then
               for j:= 1 to i-1 do
                   if (not subsumed^[j]) and (d.cell^[i]^[j] < dist) then begin
                      ni:= i;
                      nj:= j;
                      dist:= d.cell^[i]^[j];
                      end
                   else
                      else;
    end;
  End;

  Procedure GetNewDistances;
  {select unsubsumed positions l which are neither ni nor nj}
  {set new distance matrix according to method}
  {calculate d[ni,l] and d[l,ni]}
  Var
    l: smallint;
  Begin
    for l:= 1 to n do
        if (not subsumed^[l]) and (l<>ni) then begin
           d.cell^[ni]^[l]:= comp(d.cell^[ni]^[l],d.cell^[nj]^[l],size^[ni],size^[nj]);
           d.cell^[l]^[ni]:=  d.cell^[ni]^[l];
        end;
  End;

Begin
  n:= d.n;
  size:= nil; subsumed:= nil; part:= nil;
  err := 1;
  if allocvec(size,ssi,n) <> 0 then goto cleanup;
  if allocvec(subsumed,sb,n) <> 0 then goto cleanup;
  if allocvec(part,ssi,n) <> 0 then goto cleanup;
  if not level.hasval then
      if level.allocsize(n) <> 0 then goto cleanup;
  for i:= 1 to n do begin
       size^[i]:= 1;
       part^[i]:= i;
  end;
  npart:= 0; lastd:= na;
  case method of
       singlelink:   if sim then comp:= maxcomp else comp:= mincomp;
       completelink: if sim then comp:= mincomp else comp:= maxcomp;
       averagelink:  comp:= avgcomp;
       simpleaveragelink: comp:= simpleavgcomp;
  end;
  for it:= 1 to n-1 do begin
      if it mod 50 = 0 then begin
        end;
      getclosestpair;
      subsumed^[nj]:= true;
      size^[ni]:= size^[ni] + size^[nj];
      if dist <> lastd then begin
         inc(npart);
         if npart > 1 then uf.savesmallint(part^,smallintdt,n);
         lastd:= dist;
         level.cell^[npart]:= dist;
      end;
      for j:= 1 to n do
          if part^[j] = nj then part^[j]:= ni;
      GetNewDistances;
  end;
  uf.saveblock(part^,ssi*n);
  err := 0;
cleanup:
  deallocvec(size,ssi,n); deallocvec(subsumed,sb,n); deallocvec(part,ssi,n);
  JohnsonF := err;
End;
{===========================================================================}
Function JohnsonF2(var uf:ufile; var d:smatrix; sim:boolean; method:smallint;
  var npart:integer; var level:svector): smallint;
{assumes uf is open; level may have been allocated, but not required}
{modified algorithm: uses dsl list to reduce search space for closest pairs}
label cleanup;
Var
  err,n,it,ni,nj,i,j: smallint;
  size,part: tointvector;
  subsumed: ^booleanvector;
  lastd,dist: single;
  comp: minmaxtype;

  Procedure GetClosestPair;
  {find closest pair among unsubsumed positions}
  Var i,j: smallint;
  Begin
    if sim then begin
        dist:= minfloat;
        for i:= 2 to d.rdsl.n do
            for j:= 1 to i-1 do
                if d.cell^[d.rdsl.cell^[i]]^[d.rdsl.cell^[j]] > dist then begin
                   ni:= d.rdsl.cell^[i];
                   nj:= d.rdsl.cell^[j];
                   dist:= d.cell^[d.rdsl.cell^[i]]^[d.rdsl.cell^[j]];
                end;
        end
    else begin
        dist:= maxfloat;
        for i:= 2 to d.rdsl.n do
            for j:= 1 to i-1 do
                if d.cell^[d.rdsl.cell^[i]]^[d.rdsl.cell^[j]] < dist then begin
                   ni:= d.rdsl.cell^[i]; nj:= d.rdsl.cell^[j];
                   dist:= d.cell^[d.rdsl.cell^[i]]^[d.rdsl.cell^[j]];
                end;
    end;
  End;

  Procedure GetNewDistances;
  {select unsubsumed positions l which are neither ni nor nj}
  {set new distance matrix according to method}
  {calculate d[ni,l] and d[l,ni]}
  Var
    k,l: smallint;
  Begin
    for k:= 1 to d.rdsl.n do begin
      l:= d.rdsl.cell^[k];
      if (l<>ni) then begin
        d.cell^[ni]^[l]:= comp(d.cell^[ni]^[l],d.cell^[nj]^[l],size^[ni],size^[nj]);
        d.cell^[l]^[ni]:=  d.cell^[ni]^[l];
        end;
      end;
  End;

Begin
  n:= d.n;
  size:= nil; subsumed:= nil; part:= nil;
  err := 1;
  if allocvec(size,ssi,n) <> 0 then goto cleanup;
  if allocvec(subsumed,sb,n) <> 0 then goto cleanup;
  if allocvec(part,ssi,n) <> 0 then goto cleanup;
  if not level.hasval then
     if level.allocsize(n) <> 0 then goto cleanup;
  if d.rdsl.allocsize(n) <> 0 then goto cleanup;
  for i:= 1 to n do begin
      size^[i]:= 1;
      part^[i]:= i;
      d.rdsl.cell^[i]:= i;
  end;
  npart:= 0; lastd:= na;
  case method of
       singlelink:   if sim then comp:= maxcomp else comp:= mincomp;
       completelink: if sim then comp:= mincomp else comp:= maxcomp;
       averagelink:  comp:= avgcomp;
       simpleaveragelink: comp:= simpleavgcomp;
  end;
  for it:= 1 to n-1 do begin
      {ShowProgress(it*100 div n-1);}
      getclosestpair;
      subsumed^[nj]:= true;
      size^[ni]:= size^[ni] + size^[nj];
      if dist <> lastd then begin
         inc(npart);
         if npart > 1 then uf.savesmallint(part^,smallintdt,n);
         lastd:= dist; level.cell^[npart]:= dist;
      end;
      d.rdsl.n:= 0;
      for j:= 1 to n do begin
          if part^[j] = nj then part^[j]:= ni;
          if not subsumed^[j] then d.rdsl.append(j);
      end;
      GetNewDistances;
  end;
  uf.saveblock(part^,ssi*n);
  err := 0;
cleanup:
  JohnsonF2 := err;
  deallocvec(size,ssi,n); deallocvec(subsumed,sb,n); deallocvec(part,ssi,n);
  d.rdsl.dealloc;
End;
{===========================================================================}
Function Johnson2(var p:simatrix; var d:smatrix; sim:boolean; method:smallint;
  var npart:integer; var level:svector): smallint;
{level may have been allocated, but not required}
{modified algorithm: uses dsl list to reduce search space for closest pairs}
label cleanup;
Var
  err,n,it,ni,nj,i,j: smallint;
  size,part: tointvector;
  subsumed: ^booleanvector;
  lastd,dist: single;
  comp: minmaxtype;

  Procedure GetClosestPair;
  {find closest pair among unsubsumed positions}
  Var i,j: smallint;
  Begin
    if sim then begin
        dist:= minfloat;
        for i:= 2 to d.rdsl.n do
            for j:= 1 to i-1 do
                if d.cell^[d.rdsl.cell^[i]]^[d.rdsl.cell^[j]] > dist then begin
                   ni:= d.rdsl.cell^[i];
                   nj:= d.rdsl.cell^[j];
                   dist:= d.cell^[d.rdsl.cell^[i]]^[d.rdsl.cell^[j]];
                end;
        end
    else begin
        dist:= maxfloat;
        for i:= 2 to d.rdsl.n do
            for j:= 1 to i-1 do
                if d.cell^[d.rdsl.cell^[i]]^[d.rdsl.cell^[j]] < dist then begin
                   ni:= d.rdsl.cell^[i]; nj:= d.rdsl.cell^[j];
                   dist:= d.cell^[d.rdsl.cell^[i]]^[d.rdsl.cell^[j]];
                end;
    end;
  End;

  Procedure GetNewDistances;
  {select unsubsumed positions l which are neither ni nor nj}
  {set new distance matrix according to method}
  {calculate d[ni,l] and d[l,ni]}
  Var
    k,l: smallint;
  Begin
    for k:= 1 to d.rdsl.n do begin
      l:= d.rdsl.cell^[k];
      if (l<>ni) then begin
        d.cell^[ni]^[l]:= comp(d.cell^[ni]^[l],d.cell^[nj]^[l],size^[ni],size^[nj]);
        d.cell^[l]^[ni]:=  d.cell^[ni]^[l];
        end;
      end;
  End;

Begin
  n:= d.n;
  size:= nil; subsumed:= nil; part:= nil;
  err := 1;
  if allocvec(size,ssi,n) <> 0 then goto cleanup;
  if allocvec(subsumed,sb,n) <> 0 then goto cleanup;
  if allocvec(part,ssi,n) <> 0 then goto cleanup;
  if not level.hasval then
     if level.allocsize(n) <> 0 then goto cleanup;
  if not p.hasval then
     if p.allocsize(n,n) <> 0 then goto cleanup;
  if d.rdsl.allocsize(n) <> 0 then goto cleanup;
  for i:= 1 to n do begin
      size^[i]:= 1;
      part^[i]:= i;
      d.rdsl.cell^[i]:= i;
  end;
  npart:= 0; lastd:= na;
  case method of
       singlelink:   if sim then comp:= maxcomp else comp:= mincomp;
       completelink: if sim then comp:= mincomp else comp:= maxcomp;
       averagelink:  comp:= avgcomp;
       simpleaveragelink: comp:= simpleavgcomp
  end;
  for it:= 1 to n-1 do begin
      getclosestpair;
      subsumed^[nj]:= true;
      if dist <> lastd then begin
         inc(npart);
         if npart > 1 then for j:= 1 to n do p.cell^[npart-1]^[j]:= part^[j];
         lastd:= dist; level.cell^[npart]:= dist;
      end;
      d.rdsl.n:= 0;
      for j:= 1 to n do begin
          if part^[j] = nj then part^[j]:= ni;
          if not subsumed^[j] then d.rdsl.append(j);
      end;
      GetNewDistances;
      size^[ni]:= size^[ni] + size^[nj];
  end;
  for j:= 1 to n do p.cell^[npart]^[j]:= part^[j];
  err := 0;
cleanup:
  result := err;
  deallocvec(size,ssi,n); deallocvec(subsumed,sb,n); deallocvec(part,ssi,n);
  d.rdsl.dealloc;
End;
{===========================================================================}
Function ncd(var p:simatrix; var d:smatrix; sim:boolean; method:smallint;
  var npart:integer; var level:svector): smallint;
{level may have been allocated, but not required}
{modified algorithm: uses dsl list to reduce search space for closest pairs}
label cleanup;
Var
  err,n,it,ni,nj,i,j: smallint;
  size,part: tointvector;
  subsumed: ^booleanvector;
  lastq,q: single;
  comp: minmaxtype;
  e: arrayofarrayofsingle;
  a: arrayofsingle;

  function getchangeq(ii,jj:integer): double;
  begin
    result:= e[ii,jj] + e[jj,ii] - 2.0*a[ii]*a[jj];
  end;

  Procedure GetOptimalPair;
  {find closest pair among unsubsumed positions}
  Var
    i,j: integer;
    maxchange,changeq: double;
  Begin
    if sim then begin
        maxchange:= minfloat;
        for i:= 2 to d.rdsl.n do
            for j:= 1 to i-1 do begin
              changeQ:= getchangeq(d.rdsl.cell^[i],d.rdsl.cell^[j]);
              if changeq > maxchange then begin
                   ni:= d.rdsl.cell^[i];
                   nj:= d.rdsl.cell^[j];
                   maxchange:= changeq;
                end;
              end;
        end
    else begin
        maxchange:= maxfloat;
        for i:= 2 to d.rdsl.n do
            for j:= 1 to i-1 do begin
                changeq:= getchangeq(d.rdsl.cell^[i], d.rdsl.cell^[j]);
                if changeq < maxchange then begin
                   ni:= d.rdsl.cell^[i];
                   nj:= d.rdsl.cell^[j];
                   maxchange:= changeq;
                end;
            end;
    end;
  End;

  Procedure subsume;
  var
    j: integer;
  begin
    subsumed^[nj]:= true;
    if q <> lastq then begin
      inc(npart);
      if npart > 1 then for j:= 1 to n do p.cell^[npart-1]^[j]:= part^[j];
      lastq:= q;
    end;
    d.rdsl.n:= 0;
    for j:= 1 to n do begin
      if part^[j] = nj then part^[j]:= ni;
      if not subsumed^[j] then d.rdsl.append(j);
    end;
      size^[ni]:= size^[ni] + size^[nj];
  end;

  procedure getq;
  var
    i,j,ii,jj: integer;
    tot: double;
  begin
    for i := 1 to n do begin
      a[i]:= 0;
      for j := 1 to n do
        e[i,j]:= 0;
      end;
    tot:= 0;
    for i := 1 to n do begin
        ii:= part^[i];
      for j := 1 to n do if i<>j then begin
        jj:= part^[j];
        e[ii,jj]:= e[ii,jj] + d.cell^[i]^[j];
        tot:= tot + d.cell^[i]^[j];
        end;
      end;
    if tot > 0 then
    for i:= 1 to d.rdsl.n do begin
      ii:= d.rdsl.cell^[i];
      for j:= 1 to d.rdsl.n do begin
        jj:= d.rdsl.cell^[j];
        e[ii,jj]:= e[ii,jj]/tot;
        a[ii]:= a[ii] + e[ii,jj];
        end;
      end;
    q:= 0;
    for i := 1 to d.rdsl.n do begin
      ii:= d.rdsl.cell^[i];
      q:= q + e[ii,ii] - sqr(a[ii]);
    end;
  end;

Begin
  n:= d.n;
  size:= nil; subsumed:= nil; part:= nil;
  err := 1;
  setlength(e,n+1);
  for i:= 1 to n do
    setlength(e[i],n+1);
  setlength(a,n+1);
  if allocvec(size,ssi,n) <> 0 then goto cleanup;
  if allocvec(subsumed,sb,n) <> 0 then goto cleanup;
  if allocvec(part,ssi,n) <> 0 then goto cleanup;
  if not level.hasval then
     if level.allocsize(n) <> 0 then goto cleanup;
  if not p.hasval then
     if p.allocsize(n,n) <> 0 then goto cleanup;
  if d.rdsl.allocsize(n) <> 0 then goto cleanup;
  for i:= 1 to n do begin
      size^[i]:= 1;
      part^[i]:= i;
      d.rdsl.cell^[i]:= i;
  end;
  getq;
  npart:= 0; lastq:= na;
  for it:= 1 to n-1 do begin
      getoptimalpair;
      getq;
      subsume;
      getq;
      level.cell^[npart]:= q;
  end;
  getq;
  for j:= 1 to n do p.cell^[npart]^[j]:= part^[j];
  err := 0;
cleanup:
  result := err;
  deallocvec(size,ssi,n); deallocvec(subsumed,sb,n); deallocvec(part,ssi,n);
  d.rdsl.dealloc;
  for i:= 1 to n do
    e[i]:= nil;
  e:= nil; a:= nil;
End;
{===========================================================================}
Function mJohnsonF2(var uf:ufile; var d:matrix; sim:boolean; method:smallint;
  var npart:smallint; var level:svector; saveall:boolean): smallint;
{assumes uf is open; level may have been allocated, but not required}
{modified algorithm: uses dsl list to reduce search space for closest pairs}
label cleanup;
Var
  err,n,it,ni,nj,i,j: smallint;
  size,part: tointvector;
  subsumed: ^booleanvector;
  lastd,dist: single;
  comp: minmaxtype;

  Procedure GetClosestPair;
  {find closest pair among unsubsumed positions}
  Var i,j: smallint;
  Begin
      if sim then begin
        dist:= minfloat;
        for i:= 2 to d.rdsl.n do
            for j:= 1 to i-1 do
                if d.fget(d.rdsl.cell^[i],d.rdsl.cell^[j]) > dist then begin
                   ni:= d.rdsl.cell^[i]; nj:= d.rdsl.cell^[j];
                   dist:= d.fget(d.rdsl.cell^[i],d.rdsl.cell^[j]);
                end;
        end
      else
        begin
        dist:= maxfloat;
        for i:= 2 to d.rdsl.n do
            for j:= 1 to i-1 do
                if d.fget(d.rdsl.cell^[i],d.rdsl.cell^[j]) < dist then begin
                   ni:= d.rdsl.cell^[i]; nj:= d.rdsl.cell^[j];
                   dist:= d.fget(d.rdsl.cell^[i],d.rdsl.cell^[j]);
                end;
      end;
  End;

  Procedure GetNewDistances;
  {select unsubsumed positions l which are neither ni nor nj}
  {set new distance matrix according to method}
  {calculate d[ni,l] and d[l,ni]}
  Var
    k,l: smallint;
    x: extended;
  Begin
    for k:= 1 to d.rdsl.n do begin
      l:= d.rdsl.cell^[k];
      if (l<>ni) then begin
        x:= comp(d.fget(ni,l),d.fget(nj,l),size^[ni],size^[nj]);
        d.fput(ni,l,x); d.fput(l,ni,x);
        end;
      end;
  End;

Begin
  n:= d.n;
  size:= nil; subsumed:= nil; part:= nil;
  err := 1;
  if allocvec(size,ssi,n) <> 0 then goto cleanup;
  if allocvec(subsumed,sb,n) <> 0 then goto cleanup;
  if allocvec(part,ssi,n) <> 0 then goto cleanup;
  if not level.hasval then
     if level.allocsize(n) <> 0 then goto cleanup;
  if d.rdsl.allocsize(n) <> 0 then goto cleanup;
  for i:= 1 to n do begin
      size^[i]:= 1;
      part^[i]:= i;
      d.rdsl.cell^[i]:= i;
  end;
  npart:= 0; lastd:= na;
  case method of
       singlelink:   if sim then comp:= maxcomp else comp:= mincomp;
       completelink: if sim then comp:= mincomp else comp:= maxcomp;
       averagelink:  comp:= avgcomp;
       simpleaveragelink: comp:= simpleavgcomp;
  end;
  for it:= 1 to n-1 do begin
       getclosestpair;
       subsumed^[nj]:= true;
       size^[ni]:= size^[ni] + size^[nj];
       if (dist <> lastd) or saveall then begin
          inc(npart);
          if npart > 1 then uf.savesmallint(part^,smallintdt,n);
          lastd:= dist;
          level.cell^[npart]:= dist;
       end;
       d.rdsl.n:= 0;
       for j:= 1 to n do begin
           if part^[j] = nj then part^[j]:= ni;
           if not subsumed^[j] then d.rdsl.append(j);
       end;
       GetNewDistances;
  end;
  uf.saveblock(part^,ssi*n);
  err := 0;
cleanup:
  deallocvec(size,ssi,n); deallocvec(subsumed,sb,n); deallocvec(part,ssi,n);
  d.rdsl.dealloc;
  mJohnsonF2 := err;
End;
{===========================================================================}
Procedure runSingleLink(var uf:ufile; var d:imatrix; var npart:smallint; var level:ivector);
{assumes uf is open; level may have been allocated, but not required}
{modified algorithm: uses dsl list to reduce search space for closest pairs}
label cleanup;
Var
  n,it,ni,nj,i,j: smallint;
  size,part: tointvector;
  subsumed: ^booleanvector;
  lastd,dist: longint;

  Procedure GetClosestPair;
  {find closest pair among unsubsumed positions}
  Var i,j: smallint;
  Begin
    dist:= -32000;
    for i:= 2 to d.rdsl.n do
        for j:= 1 to i-1 do
            if d.cell^[d.rdsl.cell^[i]]^[d.rdsl.cell^[j]] > dist then begin
               ni:= d.rdsl.cell^[i]; nj:= d.rdsl.cell^[j];
               dist:= d.cell^[d.rdsl.cell^[i]]^[d.rdsl.cell^[j]];
            end;
  End;

  Procedure GetNewDistances;
  {select unsubsumed positions l which are neither ni nor nj}
  {set new distance matrix according to method}
  {calculate d[ni,l] and d[l,ni]}
  Var
    k,l: smallint;
  Begin
    for k:= 1 to d.rdsl.n do begin
      l:= d.rdsl.cell^[k];
      if (l<>ni) then begin
        d.cell^[ni]^[l]:= imax(d.cell^[ni]^[l],d.cell^[nj]^[l]);
        d.cell^[l]^[ni]:=  d.cell^[ni]^[l];
      end;
    end;
  End;

Begin
  n:= d.n;
  size:= nil; subsumed:= nil; part:= nil;
  if allocvec(size,ssi,n) <> 0 then goto cleanup;
  if allocvec(subsumed,sb,n) <> 0 then goto cleanup;
  if allocvec(part,ssi,n) <> 0 then goto cleanup;
  if not level.hasval then
     if level.allocsize(n) <> 0 then goto cleanup;
  if d.rdsl.allocsize(n) <> 0 then goto cleanup;
  for i:= 1 to n do begin
      size^[i]:= 1;
      part^[i]:= i;
      d.rdsl.cell^[i]:= i;
  end;
  npart:= 0; lastd:= 32000;
  for it:= 1 to n-1 do begin
      getclosestpair;
      subsumed^[nj]:= true;
      size^[ni]:= size^[ni] + size^[nj];
      if dist <> lastd then begin
         inc(npart);
         if npart > 1 then uf.savesmallint(part^,smallintdt,n);
         lastd:= dist;
         level.cell^[npart]:= dist;
      end;
      d.rdsl.n:= 0;
      for j:= 1 to n do begin
          if part^[j] = nj then part^[j]:= ni;
          if not subsumed^[j] then d.rdsl.append(j);
      end;
      GetNewDistances;
  end;
  uf.saveblock(part^,ssi*n);
cleanup:
  deallocvec(size,ssi,n); deallocvec(subsumed,sb,n); deallocvec(part,ssi,n);
  d.rdsl.dealloc;
End;
{---------------------------------------------------------------------------}
function runcluster(var ov:smatrix; var f:text;
  sim:boolean; method:smallint; pfn:filename; tit:string;
  dchar:char; pw:smallint): smallint;
{assumes filled-in symmetric matrix}
label cleanup;
var
  error,i: smallint;
  npart: integer;
  p: imatrix;
  bp: ivector;
  level: svector;
begin
  error := 1;
  p:= imatrix.create; bp:= ivector.create; level:= svector.create;
  if p.openoutfile(dsys(pfn)) <> 0 then goto cleanup;
  johnsonf2(p.df.outdf,ov,sim,method,npart,level);
  p.closeoutfile;
  if p.rdvn.allocsize(npart) <> 0 then goto cleanup;
  for i:= 1 to npart do
      p.rdvn.lput(i,fstr(level.cell^[i],0,3));
  p.cdvn.copy(ov.cdvn);
  p.title:= 'Partition Indicator Matrix';
  p.nr:= npart; p.nc:= ov.nc;
  if p.savehdr(hsys(pfn)) <> 0 then goto cleanup;
  if p.allocsize(npart,ov.n) <> 0 then goto cleanup;
  p.df.indf.dt:= p.df.outdf.dt;
  if p.loaddata(dsys(pfn)) <> 0 then goto cleanup;
  if bp.allocsize(ov.n) <> 0 then goto cleanup;
  if cant(getbestperm(p,bp.cell^,true)) then goto cleanup;
  if ov.n < displaysize then Text_Dendrogram(f,p,bp.cell^,'Level',tit,false,dchar,pw);
  p.transpose;
  p.save(pfn);
  error := 0;
cleanup:
  p.free; bp.free; level.free;
  runcluster:= error;
end;
{---------------------------------------------------------------------------}
function runclusternew(var ov:smatrix; log:tlogfile;
  sim:boolean; method:smallint; pfn:filename; tit:string;
  dchar:char; pw:smallint): smallint;
{assumes filled-in symmetric matrix}
label cleanup;
var
  error,i: smallint;
  npart: integer;
  p: imatrix;
  bp: ivector;
  level: svector;
begin
  error := 1;
  p:= imatrix.create; bp:= ivector.create; level:= svector.create;
  if p.openoutfile(dsys(pfn)) <> 0 then goto cleanup;
  johnsonf2(p.df.outdf,ov,sim,method,npart,level);
  p.closeoutfile;
  if p.rdvn.allocsize(npart) <> 0 then goto cleanup;
  for i:= 1 to npart do
      p.rdvn.lput(i,fstr(level.cell^[i],0,3));
  p.cdvn.copy(ov.cdvn);
  p.title:= 'Partition Indicator Matrix';
  p.nr:= npart; p.nc:= ov.nc;
  if p.savehdr(hsys(pfn)) <> 0 then goto cleanup;
  if p.allocsize(npart,ov.n) <> 0 then goto cleanup;
  p.df.indf.dt:= p.df.outdf.dt;
  if p.loaddata(dsys(pfn)) <> 0 then goto cleanup;
  if bp.allocsize(ov.n) <> 0 then goto cleanup;
  if cant(getbestperm(p,bp.cell^,true)) then goto cleanup;
  if ov.n < displaysize
    then Text_Dendrogram(log.stream,p,bp.cell^,'Level',tit,false,dchar,pw);
  p.transpose;
  p.save(pfn);
  error := 0;
cleanup:
  p.free; bp.free; level.free;
  result:= error;
end;
{---------------------------------------------------------------------------}
function runcluster2(var ov:smatrix; var f:text;
  sim:boolean; method:smallint; pfn:filename; tit:string;
  dchar:char; pw:smallint): smallint;
{assumes filled-in symmetric matrix}
label cleanup;
var
  error,i: smallint;
  npart: integer;
  p: imatrix;
  bp: ivector;
  level: svector;
begin
  error := 1;
  p:= imatrix.create; bp:= ivector.create; level:= svector.create;
  if p.allocsize(ov.n+1,ov.n) <> 0 then goto cleanup;
  johnson2(p,ov,sim,method,npart,level);
  p.nr:= npart; p.nc:= ov.nc;
  if p.rdvn.allocsize(npart) <> 0 then goto cleanup;
  for i:= 1 to npart do
    p.rdvn.lput(i,fstr(level.cell^[i],0,3));
  p.cdvn.copy(ov.cdvn);
  p.title:= 'Partition Indicator Matrix';
  if bp.allocsize(ov.n) <> 0 then goto cleanup;
  if cant(getbestperm(p,bp.cell^,true)) then goto cleanup;
  if ov.n <= displaysize then Text_Dendrogram(f,p,bp.cell^,'Level',tit,false,dchar,pw);
  p.transpose;
  p.save(pfn);
  error := 0;
cleanup:
  p.free; bp.free; level.free;
  result:= error;
end;
{---------------------------------------------------------------------------}
function vruncluster(var ov:matrix; var f:text;
  sim:boolean; method:smallint; pfn:filename; tit:string;
  dchar:char; pw:smallint): smallint;
{assumes filled-in symmetric matrix}
label cleanup;
var
  error,i: smallint;
  npart: smallint;
  {p: vimatrix;}
  p: smatrix;
  bp: ivector;
  level: svector;
begin
  error := 1;
  p:= smatrix.create; bp:= ivector.create; level:= svector.create;
  if p.openoutfile(dsys(pfn)) <> 0 then goto cleanup;
  mjohnsonf2(p.df.outdf,ov,sim,method,npart,level,false);
  p.closeoutfile;
  if p.rdvn.allocsize(npart) <> 0 then goto cleanup;
  for i:= 1 to npart do
      p.rdvn.lput(i,fstr(level.cell^[i],0,3));
  p.title:= 'Partition Indicator Matrix';
  p.nr:= npart; p.nc:= ov.nc;
  if p.savehdr(hsys(pfn)) <> 0 then goto cleanup;
  if p.allocsize(npart,ov.n) <> 0 then goto cleanup;
  p.df.indf.dt:= p.df.outdf.dt;
  if p.loaddata(dsys(pfn)) <> 0 then goto cleanup;
  if bp.allocsize(ov.n) <> 0 then goto cleanup;
  if cant(getbestperm(p,bp.cell^,true)) then goto cleanup;
  if error <> 0 then goto cleanup;
  if ov.n <= displaysize then Text_Dendrogram(f,p,bp.cell^,'Level',tit,false,dchar,pw);
  error := 0;
cleanup:
  p.free; bp.free; level.free; vruncluster:= error;
end;
{---------------------------------------------------------------------------}
procedure km1(var d:smatrix; var p:ivector; nb:integer; sim:boolean);
label cleanup;
var
  ni,nj,n: integer;
  subsumed: blvector;
  i,k: integer;

  Procedure GetMostDistantPair;
  {find closest pair among unsubsumed positions}
  Var
    i,j: integer;
    dist: single;
  Begin
    if sim then begin
        dist:= maxfloat;
        for i:= 2 to d.rdsl.n do
            for j:= 1 to i-1 do
                if d.fget(d.rdsl.cell^[i],d.rdsl.cell^[j]) < dist then begin
                   ni:= d.rdsl.cell^[i]; nj:= d.rdsl.cell^[j];
                   dist:= d.fget(d.rdsl.cell^[i],d.rdsl.cell^[j]);
                end;
        end
    else begin
        dist:= minfloat;
        for i:= 2 to d.rdsl.n do
            for j:= 1 to i-1 do
                if d.fget(d.rdsl.cell^[i],d.rdsl.cell^[j]) > dist then begin
                   ni:= d.rdsl.cell^[i]; nj:= d.rdsl.cell^[j];
                   dist:= d.fget(d.rdsl.cell^[i],d.rdsl.cell^[j]);
                end;
    end;
  End;

  Procedure GetFurthestItem;
  Var
    i,j: integer;
    dist,x: single;
  Begin
    if sim then begin
        dist:= maxfloat;
        for i:= 1 to d.rdsl.n do
            for j:= 1 to n do
                if not subsumed.cell^[j] then begin
                   x:= d.fget(d.rdsl.cell^[i],j);
                   if x < dist then begin
                      nj:= j; dist:= x;
                   end;
                end;
        end
    else begin
        dist:= minfloat;
        for i:= 1 to d.rdsl.n do
            for j:= 1 to n do
                if not subsumed.cell^[j] then begin
                   x:= d.fget(d.rdsl.cell^[i],j);
                   if x > dist then begin nj:= j; dist:= x; end;
                end;
    end;
  End;

  Procedure PutNearestCluster(i:integer);
  Var
    j,k: integer;
    dist,x: single;
  Begin
    if sim then begin
        dist:= minfloat;
        for k:= 1 to d.rdsl.n do begin
            j:= d.rdsl.cell^[k]; x:= d.fget(i,j);
            if x > dist then begin p.cell^[i]:= k; dist:= x; end;
        end;
        end
    else begin
        dist:= maxfloat;
        for k:= 1 to d.rdsl.n do begin
            j:= d.rdsl.cell^[k]; x:= d.fget(i,j);
            if x < dist then begin p.cell^[i]:= k; dist:= x; end;
        end;
    end;
  End;

begin
  n:= d.n;
  subsumed:= blvector.create;
  if subsumed.allocsize(n) <> 0 then goto cleanup;
  if d.rdsl.allocsize(n) <> 0 then goto cleanup;
  getmostdistantpair;
  d.rdsl.cell^[1]:= ni;
  d.rdsl.cell^[2]:= nj;
  d.rdsl.n:= 2;
  subsumed.cell^[ni]:= true;
  subsumed.cell^[nj]:= true;
  if nb > 2 then
     for k:= 3 to nb do begin
         getfurthestitem;
         d.rdsl.cell^[k]:= nj;
         inc(d.rdsl.n);
         subsumed.cell^[nj]:= true;
     end;
  for i:= 1 to d.rdsl.n do p.cell^[d.rdsl.cell^[i]]:= i;
  for i:= 1 to n do
      if not subsumed.cell^[i] then
         putnearestcluster(i);
cleanup:
  subsumed.free; d.rdsl.dealloc;
End;
{===========================================================================}
End.

