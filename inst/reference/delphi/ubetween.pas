unit ubetween;
{---------------------------------------------------------------------------}
interface
uses
  comctrls,dialogs,
  ucommon, ugeneral,uvector,usimatrix,usmatrix,{ueigen,}ucan,ugraphtraversal,utimat,
  utadjlist,utdvec,utsmat,utivec,utsmat3,utsvec,utmat,utdmat, utnodelist,
  utfile;
type
  singlecube = array of array of array of single;
  doublecube = array of array of array of double;
var
  edge:   array of array of integer;
  degree: array of integer;
{---------------------------------------------------------------------------}
procedure calculatebrandesbetweenness(var m:simatrix; var bet:smatrix);
procedure calculateEdgebetweenness(var m:simatrix; var edgebet,bet:smatrix);
procedure calculateEdgebetweenness1(var m:simatrix; var edgebet,bet:smatrix);
//procedure calculatecentralities(var m:simatrix; var cent:smatrix; var disconnected:boolean);
procedure brandes1(var edge:int2way; var cb:doublearray; nvert:integer); overload;
//procedure brandes1(edge:tadjlist; cb:tdvec); overload;
procedure brandes1(cb:tsvec; edge:tadjlist); overload;
procedure proxbetweenness(cb:tsvec; edge:tadjlist);
procedure brandes2(edge:tadjlist; eb:tsmat; cb:tdvec); overload;
procedure brandes2(edge:tadjlist; eb:tdmat; cb:tdvec); overload;
procedure brandes2(var edge:int2way; var eb:smatrix; var cb:doublearray; nvert:integer); overload;
procedure GeodesicCountCube(edge:tadjlist; dep:tsmat3);
procedure dependencycube(var edge:int2way; var cb:doublearray; var dep:singlecube; nvert:integer);
procedure distancecounts(var edge:int2way; dist,count:timat; nvert:integer); overload;
procedure distancecounts(edge:tadjlist; dist,count:timat); overload;
procedure calcsymgeodesicmeasures(edge:tnodelist; cb,cc,ch:tsvec; pb:tprogressbar; missingdistancevalue:single=0.0); overload;
procedure calcsymgeodesicmeasures(edge:tadjlist; cb,cc,ch:tsvec;
          pb:tprogressbar; missingdistancevalue:single=0.0); overload;
procedure calcasymgeodesicmeasures(edge:tadjlist; cb,cc,incc,ch,inch:tsvec;
          pb:tprogressbar; missingdistancevalue:single=0.0);
procedure calcdistbet(edge:tadjlist; dist:timat; cb:tsvec); overload;
procedure calcdistbet(edge:tadjlist; dist:tmat; cb:tsvec); overload;
{---------------------------------------------------------------------------}
implementation
{---------------------------------------------------------------------------}
(*procedure copyback(var data:smatrix);
{assumes edge and degree allocated by caller}
var
  i,j,jj: integer;
begin
//  data.zerofill;
  for i:= 0 to data.nr-1 do
    if degree[i] > 0 then for j:= 0 to degree[i]-1 do begin
      jj:= edge[i][j];
      data.cell^[i+1]^[jj+1]:= 1;
      end;
end;*)
{---------------------------------------------------------------------------}
(* procedure calculatecentralities(var m:simatrix; var cent:smatrix; var disconnected:boolean);
{assumes cent is allocated by caller}
label cleanup;
var
  i,j: integer;
  totbet,totdist,paths: doublearray;
  xn,den,bet: single;
  d: array of integer;
  i0: integer;
  tmp: smatrix;
  nvert,rank: integer;
  v: evector;
begin
  tmp.init; v.init;
  nvert:= m.nr;
  if cant(v.allocsize(nvert)) then goto cleanup;
  try
    setlength(totbet,nvert);
    setlength(totdist,nvert);
    setlength(paths,nvert);
    setlength(d,nvert);
    setlength(component,nvert); for i:= 0 to nvert-1 do component[i]:= 0;
    setlength(pred,nvert); for i:= 0 to nvert-1 do setlength(pred[i].x,nvert);
    setlength(edge,nvert); for i:= 0 to nvert-1 do setlength(edge[i],nvert);
    setlength(degree,nvert);
  except
    error:=1;
    end;
  if error = 1 then goto cleanup;
  alt.copyfromsmatrixsym(m);
  m.dealloc;
  for j:= 0 to nvert-1 do begin
    totbet[j]:= 1.0;
    totdist[j]:= 0;
    end;
  disconnected:= false;
  for i:= 0 to nvert-1 do begin
    runbet(i,paths,d);
    for j:= 0 to nvert-1 do begin
      totbet[j]:= totbet[j] + paths[j];
      if d[j] > -1
        then totdist[i]:= totdist[i] + d[j]
        else begin
          disconnected:= true;
          totdist[i]:= totdist[i] + nvert;
          end;
      end;
    end;
  xn:= nvert;
  den:= 2.0 + xn*xn - 3.0*xn;
  for i:= 1 to nvert do begin
    i0:= i - 1;
    cent.cell^[i]^[1]:= 100.0*degree[i0]/(xn-1.0);
    if totdist[i0] > 0 then cent.cell^[i]^[2]:= 100.0*(xn-1.0)/totdist[i0];
    bet:= totbet[i0]/2.0 - component[i0];
    if den > 0
      then cent.cell^[i]^[3]:= 200.0*bet/den
      else cent.cell^[i]^[3]:= bna;
    end;
  if cant(tmp.allocsize(nvert,nvert)) then goto cleanup;
  copyback(tmp);
  if cant(tred2tqli(tmp,v,rank,true)) then goto cleanup;
  if tmp.cell^[1]^[1] < 0
    then for i:= 1 to nvert do cent.cell^[i]^[4]:= -100.0*tmp.cell^[i]^[1]/sqrt(0.5)
    else for i:= 1 to nvert do cent.cell^[i]^[4]:=  100.0*tmp.cell^[i]^[1]/sqrt(0.5);
  cleanup:
    totbet:= nil; totdist:= nil; paths:= nil; component:= nil;
    for i:= 0 to nvert-1 do begin pred[i].x:= nil; end;
    for i:= 0 to nvert-1 do begin edge[i]:= nil; end;
    pred:= nil; degree:= nil; d:= nil;
    tmp.free; v.free;
end; *)
{---------------------------------------------------------------------------}
procedure brandes1(var edge:int2way; var cb:doublearray; nvert:integer);
label cleanup;
var
  d: array of integer;
  del,sig: array of double;
  p: int2way;
  st: istack;
  q: iqueue;
  i,v,w,s: integer;
begin
  st:= istack.create; q:= iqueue.create;
  setlength(p,nvert+1); for i:= 1 to nvert do setlength(p[i],nvert+1);
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
  for i:= 1 to nvert do cb[i]:= 0.0;
  for s:= 1 to nvert do begin
    st.empty;
    for i:= 1 to nvert do p[i][0]:= 0;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge[v][0] do begin
        w:= edge[v][i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          inc(p[w][0]);
          p[w][p[w][0]]:= v;
          end;
        end;
      end;
    for i:= 1 to nvert do del[i]:= 0;
    while not st.isempty do begin
      w:= st.pop;
      for i:= 1 to p[w][0] do begin
        v:= p[w][i];
        del[v]:= del[v] + (sig[v]/sig[w])*(1.0+del[w]);
        end;
      if w <> s then cb[w]:= cb[w] + del[w];
      end;
    end;
  cleanup:
    del:= nil; d:= nil; sig:= nil;
    for i:= 1 to nvert do p[i]:= nil; p:= nil;
    st.free; q.free;
end;
{---------------------------------------------------------------------------}
(*procedure brandes1(var edge:int2way; var cb:doublearray; nvert:integer);
label
  cleanup;
var
  d: array of integer;
  del,sig: array of double;
  p: int2way;
  st: istack;
  q: iqueue;
  i,v,w,s: integer;
begin
  st.init; q:= queue.create;
  setlength(p,nvert+1); for i:= 1 to nvert do setlength(p[i],nvert+1);
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
  for i:= 1 to nvert do cb[i]:= 0.0;
  for s:= 1 to nvert do begin
    st.empty;
    for i:= 1 to nvert do p[i][0]:= 0;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge[v][0] do begin
        w:= edge[v][i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          inc(p[w][0]);
          p[w][p[w][0]]:= v;
          end;
        end;
      end;
    for i:= 1 to nvert do del[i]:= 0;
    while not st.isempty do begin
      w:= st.pop;
      for i:= 1 to p[w][0] do begin
        v:= p[w][i];
        del[v]:= del[v] + (sig[v]/sig[w])*(1.0+del[w]);
        end;
      if w <> s then cb[w]:= cb[w] + del[w];
      end;
    end;
  cleanup:
    del:= nil; d:= nil; sig:= nil;
    for i:= 1 to nvert do p[i]:= nil; p:= nil;
    st.free; q.free;
end; *)
{---------------------------------------------------------------------------}
procedure brandes1(cb:tsvec; edge:tadjlist);
{april 14 2010 something wrong with this routine. don't know what}
label cleanup;
var
  d: array of integer;
  del,sig: array of double;
  p: int2way;
  st: tistack;
  q: tiqueue;
  nvert,i,v,w,s: integer;
begin
  try
  error:= 1;
  st:= tistack.create; q:= tiqueue.create;
  nvert:= edge.nr;
  setlength(p,nvert+1);
//  for i:= 1 to nvert do setlength(p[i],nvert+1);
{  for i:= 1 to nvert do
    setlength(p[i],edge[i,edge[i,0]]+1);}
  for i:= 1 to nvert do
    setlength(p[i],nvert+1);
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
{  if not cb.hasval
    then if cant(cb.allocsize(nvert)) then goto cleanup;}
  cb.allocsize(nvert);
  cb.zerofill;
  for s:= 1 to nvert do begin
    st.empty;
    for i:= 1 to nvert do p[i][0]:= 0;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge.cell[v,0] do begin
        w:= edge.cell[v,i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          inc(p[w][0]);
          p[w][p[w][0]]:= v;
          end;
        end;
      end;
    for i:= 1 to nvert do del[i]:= 0;
    while not st.isempty do begin
      w:= st.pop;
      for i:= 1 to p[w][0] do begin
        v:= p[w][i];
        del[v]:= del[v] + (sig[v]/sig[w])*(1.0+del[w]);
        end;
      if w <> s then cb.cell[w]:= cb.cell[w] + del[w];
      end;
    end;
  error:= 0;
  cleanup:
  finally
    try
      for i:= 1 to nvert do
        finalize(p[i]);
      finalize(p);
    except
      showmessage('Something strange happened during this computation. But what you dont know wont hurt you. Right?');
    end;
    del:= nil; d:= nil; sig:= nil;
    st.free; q.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure proxbetweenness(cb:tsvec; edge:tadjlist);
label cleanup;
var
  d: array of integer;
  del,sig: array of double;
  p: int2way;
  st: istack;
  q: iqueue;
  nvert,i,v,w,s: integer;
begin
  try
  error:= 1;
  st:= istack.create; q:= iqueue.create;
  nvert:= edge.nr;
  setlength(p,nvert+1);
  for i:= 1 to nvert do setlength(p[i],nvert+1);
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
  if not cb.hasval
    then if cant(cb.allocsize(nvert)) then goto cleanup;
  cb.zerofill;
  for s:= 1 to nvert do begin
    st.empty;
    for i:= 1 to nvert do p[i][0]:= 0;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge.cell[v,0] do begin
        w:= edge.cell[v,i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          inc(p[w][0]);
          p[w][p[w][0]]:= v;
          end;
        end;
      end; //i loop
    for i:= 1 to nvert do del[i]:= 0;
    while not st.isempty do begin
      w:= st.pop;
      for i:= 1 to p[w][0] do begin
        v:= p[w][i];
        del[v]:= del[v] + (sig[v]/sig[w])*(1.0+del[w]);
        if (v = s)
          then cb.cell[w]:= cb.cell[w] + del[w];
        end;
      end;
    end;
//  for i:= 1 to nvert do cb.cell[i]:= cb.cell[i]-1;
  error:= 0;
  cleanup:
  finally
    del:= nil; d:= nil; sig:= nil;
    for i:= 1 to nvert do p[i]:= nil; p:= nil;
    st.free; q.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure calcsymgeodesicmeasures(edge:tadjlist; cb,cc,ch:tsvec; pb:tprogressbar; missingdistancevalue:single=0.0);
{brandes algorithm}
label cleanup;
var
  d: array of integer;
  del,sig: array of double;
  p: int2way;
  st: istack;
  q: iqueue;
  nvert,i,v,w,s: integer;
begin
  st:= istack.create; q:= iqueue.create;
  nvert:= edge.nr;
  setlength(p,nvert+1); for i:= 1 to nvert do setlength(p[i],nvert+1);
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
  if not cb.hasval then if cant(cb.allocsize(nvert)) then goto cleanup;
  if not cc.hasval then if cant(cc.allocsize(nvert)) then goto cleanup;
  if not ch.hasval then if cant(ch.allocsize(nvert)) then goto cleanup;
  cb.zerofill; cc.zerofill; ch.zerofill;
  if pb <> nil then begin
    pb.Position:= pb.min;
    pb.Max:= nvert;
    end;
  for s:= 1 to nvert do begin
    if s mod 500 = 0 then if pb <> nil then pb.stepby(500);
    st.empty;
    for i:= 1 to nvert do p[i][0]:= 0;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge[v,0] do begin
        w:= edge[v,i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          inc(p[w][0]);
          p[w][p[w][0]]:= v;
          end;
        end;
      end;
    for i:= 1 to nvert do del[i]:= 0;
    while not st.isempty do begin
      w:= st.pop;
      for i:= 1 to p[w][0] do begin
        v:= p[w][i];
        del[v]:= del[v] + (sig[v]/sig[w])*(1.0+del[w]);
        end;
      if w <> s then cb[w]:= cb[w] + del[w];
      end;
    for i:= 1 to nvert do if (i<>s) then if (d[i] > -1)
      then begin
        cc[s]:= cc[s] + d[i];
        ch[s]:= ch[s] + 1/d[i];
        end
      else cc[s]:= cc[s] + missingdistancevalue
      else
    end;
    if pb <> nil then pb.Position:= pb.Max;
  cleanup:
    del:= nil; d:= nil; sig:= nil;
    for i:= 1 to nvert do p[i]:= nil; p:= nil;
    st.free; q.free;
end;
{---------------------------------------------------------------------------}
procedure calcsymgeodesicmeasures(edge:tnodelist; cb,cc,ch:tsvec; pb:tprogressbar; missingdistancevalue:single=0.0);
{brandes algorithm}
label cleanup;
var
  d: array of integer;
  del,sig: array of double;
  p: int2way;
  st: istack;
  q: iqueue;
  nvert,i,v,w,s: integer;
begin
  st:= istack.create; q:= iqueue.create;
  nvert:= edge.nr;
  setlength(p,nvert+1); for i:= 1 to nvert do setlength(p[i],nvert+1);
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
  if not cb.hasval then if cant(cb.allocsize(nvert)) then goto cleanup;
  if not cc.hasval then if cant(cc.allocsize(nvert)) then goto cleanup;
  if not ch.hasval then if cant(ch.allocsize(nvert)) then goto cleanup;
  cb.zerofill; cc.zerofill; ch.zerofill;
  if pb <> nil then begin
    pb.Position:= pb.min;
    pb.Max:= nvert;
    end;
  for s:= 1 to nvert do begin
    if s mod 500 = 0 then if pb <> nil then pb.stepby(500);
    st.empty;
    for i:= 1 to nvert do p[i][0]:= 0;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge.numalters[v] do begin
        w:= edge.alter(v,i);
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          inc(p[w][0]);
          p[w][p[w][0]]:= v;
          end;
        end;
      end;
    for i:= 1 to nvert do del[i]:= 0;
    while not st.isempty do begin
      w:= st.pop;
      for i:= 1 to p[w][0] do begin
        v:= p[w][i];
        del[v]:= del[v] + (sig[v]/sig[w])*(1.0+del[w]);
        end;
      if w <> s then cb[w]:= cb[w] + del[w];
      end;
    for i:= 1 to nvert do if (i<>s) then if (d[i] > -1)
      then begin
        cc[s]:= cc[s] + d[i];
        ch[s]:= ch[s] + 1/d[i];
        end
      else cc[s]:= cc[s] + missingdistancevalue
      else
    end;
    if pb <> nil then pb.Position:= pb.Max;
  cleanup:
    del:= nil; d:= nil; sig:= nil;
    for i:= 1 to nvert do p[i]:= nil; p:= nil;
    st.free; q.free;
end;
{---------------------------------------------------------------------------}
procedure calcasymgeodesicmeasures(edge:tadjlist; cb,cc,incc,ch,inch:tsvec;
                               pb:tprogressbar; missingdistancevalue:single=0.0);
label cleanup;
var
  d: array of integer;
  del,sig: array of double;
  p: int2way;
  st: istack;
  q: iqueue;
  nvert,i,v,w,s: integer;
begin
  st:= istack.create; q:= iqueue.create;
  nvert:= edge.nr;
  setlength(p,nvert+1); for i:= 1 to nvert do setlength(p[i],nvert+1);
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
  if not cb.hasval then if cant(cb.allocsize(nvert)) then goto cleanup;
  if not cc.hasval then if cant(cc.allocsize(nvert)) then goto cleanup;
  cb.zerofill; cc.zerofill; incc.zerofill; ch.zerofill; inch.zerofill;
  if pb <> nil then begin
    pb.Position:= pb.min;
    pb.Max:= nvert;
    end;
  for s:= 1 to nvert do begin
    if s mod 500 = 0 then if pb <> nil then pb.stepby(500);
    st.empty;
    for i:= 1 to nvert do p[i][0]:= 0;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge[v,0] do begin
        w:= edge[v,i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          inc(p[w][0]);
          p[w][p[w][0]]:= v;
          end;
        end;
      end;
    for i:= 1 to nvert do del[i]:= 0;
    while not st.isempty do begin
      w:= st.pop;
      for i:= 1 to p[w][0] do begin
        v:= p[w][i];
        del[v]:= del[v] + (sig[v]/sig[w])*(1.0+del[w]);
        end;
      if w <> s then cb[w]:= cb[w] + del[w];
      end;
    for i:= 1 to nvert do if (i<>s) then
      if d[i] > 0
      then begin
        cc[s]:= cc[s] + d[i];
        incc[i]:= cc[i] + d[i];
        ch[s]:= ch[s] + 1.0/d[i];
        inch[i]:= inch[i] + 1.0/d[i];
        end
      else begin
        cc[s]:= cc[s] + missingdistancevalue;
        incc[i]:= incc[i] + missingdistancevalue;
        end;
    end;
    if pb <> nil then pb.Position:= pb.Max;
  cleanup:
    del:= nil; d:= nil; sig:= nil;
    for i:= 1 to nvert do p[i]:= nil; p:= nil;
    st.free; q.free;
end;
{---------------------------------------------------------------------------}
procedure calcdistbet(edge:tadjlist; dist:timat; cb:tsvec);
{brandes algorithm}
label cleanup;
var
  d: array of integer;
  del,sig: array of double;
  p: int2way;
  st: istack;
  q: iqueue;
  nvert,i,v,w,s: integer;
begin
  st:= istack.create; q:= iqueue.create;
  nvert:= edge.nr;
  setlength(p,nvert+1); for i:= 1 to nvert do setlength(p[i],nvert+1);
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
  if not cb.hasval then if cant(cb.allocsize(nvert)) then goto cleanup;
  cb.zerofill; 
  for s:= 1 to nvert do begin
    st.empty;
    for i:= 1 to nvert do p[i][0]:= 0;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge[v,0] do begin
        w:= edge[v,i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          inc(p[w][0]);
          p[w][p[w][0]]:= v;
          end;
        end;
      end;
    for i:= 1 to nvert do del[i]:= 0;
    while not st.isempty do begin
      w:= st.pop;
      for i:= 1 to p[w][0] do begin
        v:= p[w][i];
        del[v]:= del[v] + (sig[v]/sig[w])*(1.0+del[w]);
        end;
      if w <> s then cb[w]:= cb[w] + del[w];
      end;
    for i:= 1 to nvert do dist.cell[s,i]:= d[i];
    end;
  cleanup:
    del:= nil; d:= nil; sig:= nil;
    for i:= 1 to nvert do p[i]:= nil; p:= nil;
    st.free; q.free;
end;
{---------------------------------------------------------------------------}
procedure calcdistbet(edge:tadjlist; dist:tmat; cb:tsvec);
{brandes algorithm}
label cleanup;
var
  d: array of integer;
  del,sig: array of double;
  p: int2way;
  st: istack;
  q: iqueue;
  nvert,i,v,w,s: integer;
begin
  st:= istack.create; q:= iqueue.create;
  nvert:= edge.nr;
  setlength(p,nvert+1); for i:= 1 to nvert do setlength(p[i],nvert+1);
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
  if not cb.hasval then if cant(cb.allocsize(nvert)) then goto cleanup;
  cb.zerofill;
  for s:= 1 to nvert do begin
    st.empty;
    for i:= 1 to nvert do p[i][0]:= 0;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge[v,0] do begin
        w:= edge[v,i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          inc(p[w][0]);
          p[w][p[w][0]]:= v;
          end;
        end;
      end;
    for i:= 1 to nvert do del[i]:= 0;
    while not st.isempty do begin
      w:= st.pop;
      for i:= 1 to p[w][0] do begin
        v:= p[w][i];
        del[v]:= del[v] + (sig[v]/sig[w])*(1.0+del[w]);
        end;
      if w <> s then cb[w]:= cb[w] + del[w];
      end;
    for i:= 1 to nvert do dist.iput(s,i,d[i]);
    end;
  cleanup:
    del:= nil; d:= nil; sig:= nil;
    for i:= 1 to nvert do p[i]:= nil; p:= nil;
    st.free; q.free;
end;
{---------------------------------------------------------------------------}
procedure brandes2(var edge:int2way; var eb:smatrix; var cb:doublearray; nvert:integer);
label cleanup;
var
  d: array of integer;
  del,sig: array of extended;
  p: int2way;
  st: istack;
  q: iqueue;
  i,j,v,w,s: integer;
  t: extended;
begin
  st:= istack.create; q:= iqueue.create;
  setlength(p,nvert+1); for i:= 1 to nvert do setlength(p[i],nvert+1);
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  eb.zerofill;
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
  for i:= 1 to nvert do cb[i]:= 0.0;
  for s:= 1 to nvert do begin
    st.empty;
    for i:= 1 to nvert do p[i][0]:= 0;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge[v][0] do begin
        w:= edge[v][i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          inc(p[w][0]); p[w][p[w][0]]:= v;
          end;
        end;
      end;
    for i:= 1 to nvert do del[i]:= 0;
    while not st.isempty do begin
      w:= st.pop;
      for i:= 1 to p[w][0] do begin
        v:= p[w][i];
        t:= (sig[v]/sig[w])*(1.0+del[w]);
        del[v]:= del[v] + t;
        eb.cell^[v]^[w]:= eb.cell^[v]^[w] + t;
        end;
      if w <> s then cb[w]:= cb[w] + del[w];
      end;
    end;
  cleanup:
    del:= nil; d:= nil; sig:= nil;
    for i:= 1 to nvert do p[i]:= nil; p:= nil;
    st.free; q.free;
end;
{---------------------------------------------------------------------------}
procedure brandes2(edge:tadjlist; eb:tsmat; cb:tdvec);
{caller must allocated eb and cb}
label cleanup;
var
  d: array of integer;
  del,sig: array of double;
  p: arrayofarrayofinteger;
  st: tistack;
  q: tiqueue;
  i,j,v,w,s,nvert: integer;
  t: single;
begin
  st:= tistack.create;
  q:= tiqueue.create;
  nvert:= edge.nr;
  setlength(p,nvert+1); for i:= 1 to nvert do setlength(p[i],nvert+1);
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  eb.zerofill;
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
  for i:= 1 to nvert do cb[i]:= 0.0;
  for s:= 1 to nvert do begin
    st.empty;
    for i:= 1 to nvert do p[i][0]:= 0;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge.cell[v][0] do begin
        w:= edge.cell[v][i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          inc(p[w][0]); p[w][p[w][0]]:= v;
          end;
        end;
      end;
    for i:= 1 to nvert do del[i]:= 0;
    while not st.isempty do begin
      w:= st.pop;
      for i:= 1 to p[w][0] do begin
        v:= p[w][i];
        t:= (sig[v]/sig[w])*(1.0+del[w]);
        del[v]:= del[v] + t;
        eb.cell[v][w]:= eb.cell[v][w] + t;
        end;
      if w <> s then cb[w]:= cb[w] + del[w];
      end;
    end;
  cleanup:
    del:= nil; d:= nil; sig:= nil;
    for i:= 1 to nvert do p[i]:= nil; p:= nil;
    st.destroy; q.destroy;
end;
{---------------------------------------------------------------------------}
procedure brandes2(edge:tadjlist; eb:tdmat; cb:tdvec);
{caller must allocated eb and cb}
label cleanup;
var
  d: array of integer;
  del,sig: array of double;
  p: arrayofarrayofinteger;
  st: tistack;
  q: tiqueue;
  i,j,v,w,s,nvert: integer;
  t: single;
begin
  st:= tistack.create;
  q:= tiqueue.create;
  nvert:= edge.nr;
  setlength(p,nvert+1); for i:= 1 to nvert do setlength(p[i],nvert+1);
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  eb.zerofill;
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
  for i:= 1 to nvert do cb[i]:= 0.0;
  for s:= 1 to nvert do begin
    st.empty;
    for i:= 1 to nvert do p[i][0]:= 0;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge.cell[v][0] do begin
        w:= edge.cell[v][i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          inc(p[w][0]); p[w][p[w][0]]:= v;
          end;
        end;
      end;
    for i:= 1 to nvert do del[i]:= 0;
    while not st.isempty do begin
      w:= st.pop;
      for i:= 1 to p[w][0] do begin
        v:= p[w][i];
        t:= (sig[v]/sig[w])*(1.0+del[w]);
        del[v]:= del[v] + t;
        eb.cell[v][w]:= eb.cell[v][w] + t;
        end;
      if w <> s then cb[w]:= cb[w] + del[w];
      end;
    end;
  cleanup:
    del:= nil; d:= nil; sig:= nil;
    for i:= 1 to nvert do p[i]:= nil; p:= nil;
    st.destroy; q.destroy;
end;
{---------------------------------------------------------------------------}
procedure calculatebrandesbetweenness(var m:simatrix; var bet:smatrix);
{data passed through edge, which is allocated by caller}
label cleanup;
var
  i,j: integer;
  nvert: integer;
  edge: int2way;
  xnvert,den: single;
  sym: boolean;
  cb: doublearray;
begin
  nvert:= m.nr; xnvert:= nvert;
  error:= 0;
  try
    setlength(edge,nvert+1); for i:= 1 to nvert do setlength(edge[i],nvert+1);
    setlength(cb,nvert+1);
  except
    error:= 1;
  end;
  if error = 1 then goto cleanup;
  simat2adjlist(m,edge,sym);
  brandes1(edge,cb,nvert);
  if sym
    then den:= (2.0 + xnvert*xnvert - 3.0*xnvert)
    else den:= (xnvert-1)*(xnvert-2);
  for i:= 1 to bet.nr do begin
    if sym
      then bet.cell^[i]^[1]:= cb[i]/2.0
      else bet.cell^[i]^[1]:= cb[i];
    if den > 0
      then bet.cell^[i]^[2]:= 100.0*cb[i]/den
      else bet.cell^[i]^[2]:= bna;
    end;
  cleanup:
    cb:= nil;
    for i:= 1 to nvert do edge[i]:= nil; edge:= nil;
end;
{---------------------------------------------------------------------------}
procedure calculateEdgebetweenness(var m:simatrix; var edgebet,bet:smatrix);
{ulrik's method}
{data passed through edge, which is allocated by caller}
label cleanup;
var
  i,j: integer;
  edge: int2way;
  xnvert,den: single;
  sym: boolean;
  cb: doublearray;
  nvert: integer;
begin
  nvert:= m.nr; xnvert:= nvert;
  error:= 0;
  try
    setlength(edge,nvert+1); for i:= 1 to nvert do setlength(edge[i],nvert+1);
    setlength(cb,nvert+1);
  except
    error:= 1;
  end;
  if error = 1 then goto cleanup;
  simat2adjlist(m,edge,sym);
  edgebet.zerofill;
  brandes2(edge,edgebet,cb,nvert);
  if sym
    then den:= (2.0 + xnvert*xnvert - 3.0*xnvert)
    else den:= (xnvert-1)*(xnvert-2);
  for i:= 1 to bet.nr do begin
    if sym
      then bet.cell^[i]^[1]:= cb[i]/2.0
      else bet.cell^[i]^[1]:= cb[i];
    if den > 0
      then bet.cell^[i]^[2]:= 100.0*cb[i]/den
      else bet.cell^[i]^[2]:= bna;
    end;
  cleanup:
    cb:= nil;
    for i:= 1 to nvert do edge[i]:= nil; edge:= nil;
end;
{---------------------------------------------------------------------------}
procedure calculateEdgebetweenness1(var m:simatrix; var edgebet,bet:smatrix);
{ulrik's method}
{data passed through edge, which is allocated by caller}
label cleanup;
var
  i,j: integer;
  edge: tadjlist;
  xnvert,den: single;
  sym: boolean;
  cb: tdvec;
  nvert: integer;
  eb: tsmat;
begin
  nvert:= m.nr; xnvert:= nvert;
  error:= 0;
  edge:= tadjlist.create;
  cb:= tdvec.create;
  eb:= tsmat.create;
  if cant(edge.allocsize(nvert,nvert)) then goto cleanup;
  if not eb.hasval then
    if cant(eb.allocsize(nvert,nvert)) then goto cleanup;
  if cant(cb.allocsize(nvert)) then goto cleanup;
  if error = 1 then goto cleanup;
  edge.copyfromsimatrix(m,sym);
  brandes2(edge,eb,cb);
  for i:= 1 to nvert do for j:= 1 to nvert do
    edgebet.cell^[i]^[j]:= eb.cell[i,j];
  if sym
    then den:= (2.0 + xnvert*xnvert - 3.0*xnvert)
    else den:= (xnvert-1)*(xnvert-2);
  for i:= 1 to bet.nr do begin
    if sym
      then bet.cell^[i]^[1]:= cb[i]/2.0
      else bet.cell^[i]^[1]:= cb[i];
    if den > 0
      then bet.cell^[i]^[2]:= 100.0*cb[i]/den
      else bet.cell^[i]^[2]:= bna;
    end;
  cleanup:
    cb.destroy; edge.destroy; eb.destroy;
end;
{---------------------------------------------------------------------------}
procedure dependencycube(var edge:int2way; var cb:doublearray; var dep:singlecube; nvert:integer);
label cleanup;
var
  d: array of integer;
  del,sig: array of double;
  p: int2way;
  st: istack;
  q: iqueue;
  i,v,w,s: integer;
begin
  st:= istack.create; q:= iqueue.create;
  setlength(p,nvert+1); for i:= 1 to nvert do setlength(p[i],nvert+1);
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
  for i:= 1 to nvert do cb[i]:= 0.0;
  for s:= 1 to nvert do begin
    st.empty;
    for i:= 1 to nvert do p[i][0]:= 0;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge[v][0] do begin
        w:= edge[v][i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          inc(p[w][0]);
          p[w][p[w][0]]:= v;
          end;
        end;
      end;
    for i:= 1 to nvert do del[i]:= 0;
    while not st.isempty do begin
      w:= st.pop;
      for i:= 1 to p[w][0] do begin
        v:= p[w][i];
        dep[v,s,w]:= dep[v,s,w] + (sig[v]/sig[w])*(1.0+del[w]);
        del[v]:= del[v] + (sig[v]/sig[w])*(1.0+del[w]);
        end;
      if w <> s then cb[w]:= cb[w] + del[w];
      end;
    end;
  cleanup:
    del:= nil; d:= nil; sig:= nil;
    for i:= 1 to nvert do p[i]:= nil; p:= nil;
    st.free; q.free;
end;
{---------------------------------------------------------------------------}
procedure distancecounts(var edge:int2way; dist,count:timat; nvert:integer);
label cleanup;
var
  d: array of integer;
  sig: array of integer;
  st: istack;
  q: iqueue;
  i,j,v,w,s: integer;
begin
  st:= istack.create; q:= iqueue.create;
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
  for s:= 1 to nvert do begin
    st.empty;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge[v][0] do begin
        w:= edge[v][i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          end;
        end;
      end;
    for j:= 1 to nvert do begin
      dist[s,j]:= d[j];
      count[s,j]:= sig[j];
      end;
    end;
  cleanup:
    d:= nil; sig:= nil;
    st.free; q.free;
end;
{---------------------------------------------------------------------------}
procedure distancecounts(edge:tadjlist; dist,count:timat);
label cleanup;
var
  d: array of integer;
  sig: array of integer;
  st: istack;
  q: iqueue;
  nvert,i,j,v,w,s: integer;
begin
  st:= istack.create; q:= iqueue.create;
  nvert:= edge.nr;
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
  for s:= 1 to nvert do begin
    st.empty;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge.cell[v][0] do begin
        w:= edge.cell[v][i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          end;
        end;
      end;
    for j:= 1 to nvert do begin
      dist[s,j]:= d[j];
      count[s,j]:= sig[j];
      end;
    end;
  cleanup:
    d:= nil; sig:= nil;
    st.free; q.free;
end;
{---------------------------------------------------------------------------}
procedure distancecube(var edge:int2way; var cb:doublearray; var dep:singlecube; nvert:integer);
label cleanup;
var
  d: array of integer;
  del,sig: array of double;
  num: singlecube;
  p: int2way;
  st: istack;
  q: iqueue;
  i,j,k,v,w,s: integer;
begin
  st:= istack.create; q:= iqueue.create;
  setlength(p,nvert+1); for i:= 1 to nvert do setlength(p[i],nvert+1);
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  if cant(st.allocsize(nvert)) then goto cleanup;
  if cant(q.allocsize(nvert)) then goto cleanup;
  setlength(num,nvert+1);
  for i:= 1 to nvert do setlength(num[i],nvert+1);
  for i:= 1 to nvert do for j:= 1 to nvert do
    setlength(num[i,j],nvert+1);
  for i:= 1 to nvert do cb[i]:= 0.0;
  for s:= 1 to nvert do begin
    st.empty;
    for i:= 1 to nvert do p[i][0]:= 0;
    for i:= 1 to nvert do sig[i]:= 0;
    sig[s]:= 1;
    for i:= 1 to nvert do d[i]:= -1;
    d[s]:= 0;
    q.empty;
    q.enqueue(s);
    while not q.isempty do begin
      v:= q.dequeue;
      st.push(v);
      for i:= 1 to edge[v][0] do begin
        w:= edge[v][i];
        if d[w] < 0 then begin
          q.enqueue(w);
          d[w]:= d[v] + 1;
          end;
        if d[w] = d[v] + 1 then begin
          sig[w]:= sig[w] + sig[v];
          inc(p[w][0]);
          p[w][p[w][0]]:= v;
          end;
        end;
      end;
    for i:= 1 to nvert do del[i]:= 0;
    while not st.isempty do begin
      w:= st.pop;
      for i:= 1 to p[w][0] do begin
        v:= p[w][i];
        dep[v,s,w]:= dep[v,s,w] + d[w];
        num[v,s,w]:= num[v,s,w] + d[w];
        del[v]:= del[v] + (sig[v]/sig[w])*(1.0+del[w]);
        end;
      if w <> s then cb[w]:= cb[w] + del[w];
      end;
    end;
  for i:= 1 to nvert do for j:= 1 to nvert do for k:= 1 to nvert do
    if num[k,i,j] > 0
      then dep[k,i,j]:= dep[k,i,j]/num[k,i,j]
      else dep[k,i,j]:= nvert;
  cleanup:
    del:= nil; d:= nil; sig:= nil;
    for i:= 1 to nvert do p[i]:= nil; p:= nil;
    st.free; q.free;
  for i:= 1 to nvert do for j:= 1 to nvert do
    num[i,j]:= nil;
  for i:= 1 to nvert do num[i]:= nil;
  num:= nil;
end;
{---------------------------------------------------------------------------}
procedure getvaluelist(var m:smatrix; v:tdvec);
var
  i,j: integer;
  id: longint;
  x: single;
begin
  v.alloc(m.nr*m.nc);
  v.n:= 0;
  for i:= 1 to m.nr do for j:= 1 to m.nc do if (i<>j) then begin
    x:= m.cell^[i]^[j];
    id:= v.appendifnew(x);
    end;
  v.sort('d',nil);
end;
{---------------------------------------------------------------------------}
procedure GeodesicCountCube(edge:tadjlist; dep:tsmat3);
{on output Dep(k,i,j) gives the proportion of geodesics from i to j that pass through k);}
label cleanup;
var
  d,c: timat;
  n,i,j,k: integer;
begin
  d:= timat.create;
  c:= timat.create;
  n:= edge.nr;
  if not d.allocsize(n,n) then goto cleanup;
  if not c.allocsize(n,n) then goto cleanup;
  if not dep.allocsize(n,n,n) then goto cleanup;
  dep.rdvn.copy(edge.rdvn);
  dep.cdvn.copy(edge.cdvn);
  dep.mdvn.copy(edge.rdvn);
  distancecounts(edge,d,c);
  for j:= 1 to n do
    for i:= 1 to n do if i<>j then
      for k:= 1 to n do if (k<>i) and (k<>j) and (d.cell[i][k] > 1) and
        (d.cell[i][k] = d.cell[i][j] + d.cell[j][k]) then
           dep.cell[j,i,k]:= 1.0*c.cell[i][j]*c.cell[j][k]/c.cell[i][k];
  cleanup:
    d.destroy; c.destroy;
end;
{---------------------------------------------------------------------------}
(*procedure edgebetdecomposition(eb:tsmat; p:timat);
label cleanup;
var
  a: tadjlist;
  vlist: tdvec;
  c: tivec;
  bp: ivector;
  p: simatrix;
  k,i,n,num: integer;

  procedure copydown(cutoff:double);
  var
    i,j: integer;
    dij,dji: double;

    procedure addtie(i,j:integer);
    begin
      inc(a.cell[i][0]); a.cell[i,a.cell[i][0]]:= j;
      inc(a.cell[j][0]); a.cell[j,a.cell[j][0]]:= i;
    end;

  begin
    for i:= 1 to d.nr do for j:= 0 to d.nc do a.cell[i][j]:= 0;
    for i:= 2 to d.nr do
      for j:= 1 to i-1 do if (d.cell^[i]^[j] > 0) or (d.cell^[i]^[j] > 0) then begin
        dij:= eb.cell^[i]^[j]; dji:= eb.cell^[j]^[i];
        if (dij < na) and (dji < na) then
          if (dij < cutoff) or (dji < cutoff) then addtie(i,j);
        end;
  end;

begin
  p:= timat.create;
  vlist:= tdvec.create;
  c:= tivec.create;
  a:= tadjlist.create;
  n:= eb.nr;
  if cant(bp.allocsize(n)) then goto cleanup;

  getvaluelist(eb,vlist);
  if cant(p.allocsize(vlist.n,n)) then goto cleanup;
  if cant(p.rdvn.allocsize(vlist.n)) then goto cleanup;
  a.allocsize(d.nr,d.nc);
  p.cdvn.copy(d.cdvn);

  for k:= 1 to vlist.n do begin
    copydown(vlist.cell[k]{+singletolerance});
    weakcomponent(a,c,num);
    for i:= 1 to n do p.cell^[k]^[i]:= c[i];
    p.rdvn.sput(k,fstr(vlist.cell[k],0,3));
    end;
  if cant(getbestperm(p,bp.cell^,false)) then goto cleanup;

  log.lf;
  Text_Dendrogram(log.f,p,bp.cell^,'Value','Hierarchical Components',true,dendrochar,
             pagewidth);
  log.lf;
  p.transpose;
  if cant(p.save(pfn)) then goto cleanup;
  cleanup:
    a.destroy; vlist.destroy; c.destroy;
    bp.free; p.free;
end; *)
{---------------------------------------------------------------------------}
end.
