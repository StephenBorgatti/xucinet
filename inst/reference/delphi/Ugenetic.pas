unit ugenetic;

interface
uses
  math, 
  Waiting,ucommon, ugeneral,uvector,uimatrix,urandom;
{----------------------------------------------------------------------------}
type
  genfunc = function(var chromo:smallintvector; userptr:pointer): double;
const
  pcross: double = 0.6;
var
  numgen: integer;
function genetic(var bestp:sivector; var bestfit:double;
  getfitness:genfunc; userptr:pointer; pmutation:double;
  len,alphabetsize,maxgen,popsize,msglevel,decimals,startmeth:smallint):smallint;
function genetic2(var bestp:sivector; var bestfit:double;
  getfitness:genfunc; userptr:pointer; pmutation,maxfit:double;
  rlen,clen,absize1,absize2,maxgen,popsize,stopafter:integer):smallint;
procedure greedy(var bestp:sivector; var bestfit:double;
  getfitness:genfunc; userptr:pointer; maxfit:double;
  rlen,clen,maxgen:integer);

{----------------------------------------------------------------------------}
implementation
{----------------------------------------------------------------------------}
function genetic(var bestp:sivector; var bestfit:double;
  getfitness:genfunc; userptr:pointer; pmutation:double;
  len,alphabetsize,maxgen,popsize,msglevel,decimals,startmeth:smallint):smallint;
{bestp must be allocated and given initial values by calling program}
label cleanup;
var
  newpop,oldpop: imatrix;
  fitness: svector;
  beststr: sivector;
  t: dslvector;
  bestid,nmutation,ncross,l,i,j: smallint;
  totalfitness: double;
  tenp: smallint;

  function mutation(allele:byte): byte;
  begin
    if coinflip(pmutation) then begin
        inc(nmutation); 
        mutation:= randomrange(1,alphabetsize+1); end
    else
        mutation:= allele;
  end;

  function select: smallint;
  var
    rand,partsum: double;
    j: smallint;
  begin
    partsum:= 0; j:= 0;
    rand:= random*totalfitness;
    repeat
          inc(j);
          partsum:= partsum + fitness.cell^[j];
    until (partsum >= rand) or (j >= popsize);
    select:= j;
  end;

  procedure crossover(var parent1,parent2,child1,child2:smallintvector);
  var j,jcross: smallint;
  begin
    if coinflip(pcross) then begin
        jcross:= randomrange(1,len-1); inc(ncross); end
    else
        jcross:= len;
    for j:= 1 to jcross do begin
        child1[j]:= mutation(parent1[j]);
        child2[j]:= mutation(parent2[j]);
    end;
    if jcross <> len then
        for j:= jcross+1 to len do begin
            child1[j]:= mutation(parent2[j]);
            child2[j]:= mutation(parent1[j]);
        end;
  end;

  procedure generate;
  var
    mate1,mate2,i: smallint;
  begin
    i:= 1;
    repeat
        mate1:= select; mate2:= select;
        crossover(oldpop.cell^[mate1]^,oldpop.cell^[mate2]^,
                  newpop.cell^[i]^,newpop.cell^[i+1]^);
        inc(i,2);
    until i >= popsize;
    totalfitness:= 0; bestid:= 0;
    for i:= 1 to popsize do begin
        move(newpop.cell^[i]^,oldpop.cell^[i]^,dtsize[newpop.dt]*len);
        fitness.cell^[i]:= getfitness(newpop.cell^[i]^,userptr);
        totalfitness:= totalfitness + fitness.cell^[i];
        if fitness.cell^[i] > bestfit then begin
            bestfit:= fitness.cell^[i]; bestid:= i;
        end;
    end;
    if bestid <> 0 then
        move(oldpop.cell^[bestid]^,beststr.cell^,dtsize[newpop.dt]*len);
  end;

begin
  error := 0;
  oldpop:= imatrix.create; newpop:= imatrix.create; fitness:= svector.create;
  beststr:= dslvector.create; t:= dslvector.create;
  if odd(popsize) then inc(popsize);
  if oldpop.allocsize(popsize,len) <> 0 then goto cleanup;
  if newpop.allocsize(popsize,len) <> 0 then goto cleanup;
  if fitness.allocsize(popsize) <> 0 then goto cleanup;
{  if bestp.allocsize(len) <> 0 then goto cleanup;}
  if beststr.allocsize(len) <> 0 then goto cleanup;
  if t.allocsize(alphabetsize) <> 0 then goto cleanup;
  for j:= 1 to t.n do t.cell^[j]:= j;

  {randomize;}
  totalfitness:= 0; bestfit:= minfloat;
  for j:= 1 to len do oldpop.cell^[1]^[j]:= bestp.cell^[j];
  for i:= 2 to popsize do begin
      if startmeth = 1
        then
          for j:= 1 to len do
              oldpop.cell^[i]^[j]:= randomrange(1,alphabetsize)
        else begin
          for j:= 1 to alphabetsize do begin
              l:= trunc(j+random*(alphabetsize+1-j));
              t.swap(j,l);
          end;
          l:= 0;
          for j:= 1 to len do begin
              inc(l);
              if l > alphabetsize then l:= 1;
              oldpop.cell^[i]^[j]:= t.cell^[l];
          end;
      end;
      fitness.cell^[i]:= getfitness(oldpop.cell^[i]^,userptr);
      totalfitness:= totalfitness + fitness.cell^[i];
      if fitness.cell^[i] > bestfit then begin
          bestfit:= fitness.cell^[i]; bestid:= i;
      end;
  end;
  move(oldpop.cell^[bestid]^,beststr.cell^,2*len);
  {if msglevel > 0 then writeln('Starting fit: ',bestfit:0:decimals);}
  tenp:= maxgen div 10;
  numgen:= 0;
  repeat
      inc(numgen);
      generate;
  until (numgen >= maxgen); {or (keypressed and (readkey=#27));}
  {if msglevel > 0 then writeln;}

  for j:= 1 to len do bestp.cell^[j]:= beststr.cell^[j];

cleanup:
  oldpop.free; newpop.free; fitness.free; beststr.free; t.free;
  genetic:= error;
end;
{----------------------------------------------------------------------------}
function genetic2(var bestp:sivector; var bestfit:double;
  getfitness:genfunc; userptr:pointer; pmutation,maxfit:double;
  rlen,clen,absize1,absize2,maxgen,popsize,stopafter:integer):smallint;
label cleanup;
var
  newpop,oldpop: imatrix;
  fitness: svector;
  beststr: sivector;
  bestid,nmutation,ncross,i,j,len: smallint;
  totalfitness,prevfit: double;
  tenp: integer;
  unchanged: integer;

  function alphabetsize(j:smallint): smallint;
  begin
    if j > rlen 
       then alphabetsize:= absize2 
       else alphabetsize:= absize1; 
  end;

  function mutation(allele:byte; ab:smallint): byte;
  begin
    if coinflip(pmutation) then begin
        inc(nmutation); 
        mutation:= random(ab) + 1; end
    else
        mutation:= allele;
  end;

  function select: smallint;
  var
    rand,partsum: double;
    j: smallint;
  begin
    partsum:= 0; j:= 0;
    rand:= random*totalfitness;
    repeat
        inc(j);
        partsum:= partsum + fitness.cell^[j];
    until (partsum >= rand) or (j >= popsize);
    select:= j;
  end;

  procedure crossover(var parent1,parent2,child1,child2:integervector);
  var j,jcross: smallint;
  begin
    if coinflip(pcross) then begin
        jcross:= randomrange(1,rlen-1); inc(ncross); end
    else
        jcross:= rlen;
    for j:= 1 to jcross do begin
        child1[j]:= mutation(parent1[j],absize1);
        child2[j]:= mutation(parent2[j],absize1);
    end;
    if jcross <> rlen then
        for j:= jcross+1 to rlen do begin
            child1[j]:= mutation(parent2[j],absize1);
            child2[j]:= mutation(parent1[j],absize1);
        end;
    if coinflip(pcross) then begin
        jcross:= randomrange(rlen+1,len-1); inc(ncross); end
    else
        jcross:= len;
    for j:= rlen+1 to jcross do begin
        child1[j]:= mutation(parent1[j],absize2);
        child2[j]:= mutation(parent2[j],absize2);
    end;
    if jcross <> len then
        for j:= jcross+1 to len do begin
            child1[j]:= mutation(parent2[j],absize2);
            child2[j]:= mutation(parent1[j],absize2);
        end;
  end;

  procedure generate;
  var
    mate1,mate2,i: smallint;
  begin
    i:= 1;
    repeat
        mate1:= select; mate2:= select;
        crossover(oldpop.cell^[mate1]^,oldpop.cell^[mate2]^,
                  newpop.cell^[i]^,newpop.cell^[i+1]^);
        inc(i,2);
    until i >= popsize;
    totalfitness:= 0; bestid:= 0;
    for i:= 1 to popsize do begin
        move(newpop.cell^[i]^,oldpop.cell^[i]^,dtsize[newpop.dt]*len);
        fitness.cell^[i]:= getfitness(newpop.cell^[i]^,userptr);
        totalfitness:= totalfitness + fitness.cell^[i];
        if fitness.cell^[i] > bestfit then begin
            bestfit:= fitness.cell^[i]; bestid:= i;
        end;
    end;
    if bestid <> 0 then move(oldpop.cell^[bestid]^,beststr.cell^,2*len);
  end;

begin
  oldpop:= imatrix.create; 
  newpop:= imatrix.create; 
  fitness:= svector.create; 
  beststr:= sivector.create;
  len:= rlen + clen;
  if odd(popsize) then inc(popsize);
  if oldpop.allocsize(popsize,len) <> 0 then goto cleanup;
  if newpop.allocsize(popsize,len) <> 0 then goto cleanup;
  if fitness.allocsize(popsize) <> 0 then goto cleanup;
  if bestp.allocsize(len) <> 0 then goto cleanup;
  if beststr.allocsize(len) <> 0 then goto cleanup;

  {randomize;}
  totalfitness:= 0; bestfit:= minfloat;
  for j:= 1 to len do oldpop.cell^[1]^[j]:= bestp.cell^[j];
  for i:= 2 to popsize do begin
      for j:= 1 to len do
          oldpop.cell^[i]^[j]:= random(alphabetsize(j))+1;
      fitness.cell^[i]:= getfitness(oldpop.cell^[i]^,userptr);
      totalfitness:= totalfitness + fitness.cell^[i];
      if fitness.cell^[i] > bestfit then begin
          bestfit:= fitness.cell^[i]; bestid:= i;
      end;
  end;
  move(oldpop.cell^[bestid]^,beststr.cell^,2*len);

  WaitingStart('Calculating ...',maxgen,True);
  tenp:= maxgen div 10;
  numgen:= 0; prevfit:= 0; unchanged:= 0;
  repeat
      inc(numgen);
      if numgen mod tenp = 0 then ShowProgress(numgen);
      generate;
      if samevalue(prevfit,bestfit)
        then inc(unchanged);
  until (numgen >= maxgen) or (bestfit >= maxfit) or (unchanged >= stopafter); {or (keypressed and (readkey=#27));}
  WaitingEnd;

  for j:= 1 to len do bestp.cell^[j]:= beststr.cell^[j];

cleanup:
  oldpop.free; newpop.free; fitness.free; beststr.free;
  genetic2:= error;
end;
{----------------------------------------------------------------------------}
procedure greedy(var bestp:sivector; var bestfit:double;
  getfitness:genfunc; userptr:pointer; maxfit:double;
  rlen,clen,maxgen:integer);
var
  i,j,len: smallint;
  tenp,ego,old: integer;
  changed: boolean;
  fit: double;
begin
  len:= rlen + clen;
  tenp:= maxgen div 10;
  numgen:= 0;
  repeat
    inc(numgen);
    changed:= false;
    for ego:= 1 to len do begin
      old:= bestp.cell^[ego];
      if old = 1
        then bestp.cell^[ego]:= 2
        else bestp.cell^[ego]:= 1;
      fit:= getfitness(bestp.cell^,userptr);
      if fit > bestfit
        then begin
          bestfit:= fit;
          changed:= true;
          end
        else bestp.cell^[ego]:= old;
      end;
  until (numgen >= maxgen) or (bestfit >= maxfit) or (not changed); {or (keypressed and (readkey=#27));}
  WaitingEnd;
end;
{----------------------------------------------------------------------------}
function geneticperm(var bestp:sivector; var bestfit:double;
  getfitness:genfunc; userptr:pointer; pmutation:double;
  len,alphabetsize,maxgen,popsize,msglevel:smallint):smallint;
label cleanup;
var
  newpop,oldpop: imatrix;
  fitness: svector;
  beststr: sivector;
  bestid,nmutation,ncross,i,j: smallint;
  totalfitness: double;

  function mutation(allele:byte): byte;
  begin
    if coinflip(pmutation) then begin
        inc(nmutation); mutation:= randomrange(1,alphabetsize); end
    else
        mutation:= allele;
  end;

  function select: smallint;
  var
    rand,partsum: double;
    j: smallint;
  begin
    partsum:= 0; j:= 0;
    rand:= random*totalfitness;
    repeat
        inc(j);
        partsum:= partsum + fitness.cell^[j];
    until (partsum >= rand) or (j >= popsize);
    select:= j;
  end;

  procedure crossover(var parent1,parent2,child1,child2:integervector);
  var j,jcross: smallint;
  begin
    if coinflip(pcross) then begin
        jcross:= randomrange(1,len-1); inc(ncross); end
    else
        jcross:= len;
    for j:= 1 to jcross do begin
        child1[j]:= parent1[j];
        child2[j]:= parent2[j];
    end;
    if jcross <> len then
        for j:= jcross+1 to len do begin
            child1[j]:= parent2[j];
            child2[j]:= parent1[j];
        end;
  end;

  procedure generate;
  var
    mate1,mate2,i: smallint;
  begin
    i:= 1;
    repeat
        mate1:= select; mate2:= select;
        crossover(oldpop.cell^[mate1]^,oldpop.cell^[mate2]^,
                  newpop.cell^[i]^,newpop.cell^[i+1]^);
        inc(i,2);
    until i >= popsize;
    totalfitness:= 0; bestid:= 0;
    for i:= 1 to popsize do begin
        move(newpop.cell^[i]^,oldpop.cell^[i]^,dtsize[newpop.dt]*len);
        fitness.cell^[i]:= getfitness(newpop.cell^[i]^,userptr);
        totalfitness:= totalfitness + fitness.cell^[i];
        if fitness.cell^[i] > bestfit then begin
            bestfit:= fitness.cell^[i]; bestid:= i;
        end;
    end;
    if bestid <> 0 then
        move(oldpop.cell^[bestid]^,beststr.cell^,dtsize[newpop.dt]*len);
  end;

begin
  oldpop:= imatrix.create; newpop:= imatrix.create; fitness:= svector.create; beststr:= ivector.create;
  if odd(popsize) then inc(popsize);
  if oldpop.allocsize(popsize,len) <> 0 then goto cleanup;
  if newpop.allocsize(popsize,len) <> 0 then goto cleanup;
  if fitness.allocsize(popsize) <> 0 then goto cleanup;
  if bestp.allocsize(len) <> 0 then goto cleanup;
  if beststr.allocsize(len) <> 0 then goto cleanup;

  {randomize;}
  totalfitness:= 0; bestfit:= minfloat;
  for i:= 1 to popsize do begin
      for j:= 1 to len do
          oldpop.cell^[i]^[j]:= randomrange(1,alphabetsize);
      fitness.cell^[i]:= getfitness(oldpop.cell^[i]^,userptr);
      totalfitness:= totalfitness + fitness.cell^[i];
      if fitness.cell^[i] > bestfit then begin
          bestfit:= fitness.cell^[i]; bestid:= i;
      end;
  end;
  move(oldpop.cell^[bestid]^,beststr.cell^,2*len);
  {if msglevel > 0 then writeln('Starting fit: ',bestfit:0:3);}

  numgen:= 0;
  repeat
      inc(numgen);
      generate;
      {if msglevel > 0 then write(' ',bestfit:0:3);}
  until (numgen >= maxgen); {or (keypressed and (readkey=#27));}
  {if msglevel > 0 then writeln;}

  for j:= 1 to len do
      bestp.cell^[j]:= beststr.cell^[j];

cleanup:
  oldpop.free; newpop.free; fitness.free; beststr.free;
  geneticperm:= error;
end;
{----------------------------------------------------------------------------}
end.