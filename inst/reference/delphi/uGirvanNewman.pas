unit uGirvanNewman;
interface
uses
  sysutils,Generics.Collections,math,
  ucommon, utnodelist, utimat, utivec, utsmat, utdvec, ubetween,
  utlogfile;

procedure girvannewmanclustering(p:timat; adj:tnodelist; maxc:integer);

implementation

procedure getedgebetweenness(eb:tsmat; cb:tdvec; net:tnodelist; log:tlogfile=nil);
label cleanup;
var
  d: arrayofinteger;
  del,sig: arrayofdouble;
  p: arrayofarrayofinteger;
  st: tistack;
  q: tiqueue;
  i,j,v,w,s,nvert: integer;
  t: double;
begin
  st:= tistack.create;
  q:= tiqueue.create;
  nvert:= net.n;
  eb.allocsize(nvert,nvert);
  cb.allocsize(nvert);
  setlength(p,nvert+1,nvert+1);
  setlength(sig,nvert+1);
  setlength(d,nvert+1);
  setlength(del,nvert+1);
  eb.zerofill;
  st.allocsize(nvert);
  q.allocsize(nvert);
  cb.allocsize(nvert,true);
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
      net.resetnextalter(v);
      while net.getnextalter(v) > 0 do begin
        w:= net.alterof[v];
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
        eb.cell[v,w]:= eb.cell[v,w] + t;
        end;
      if w <> s then cb[w]:= cb[w] + del[w];
      end;
    end;
  cleanup:
    del:= nil; d:= nil; sig:= nil; p:= nil;
    st.destroy; q.destroy;
end;

(*function getbetweennesspartition(part:tivec; var nclus:integer; adj:tnodelist; log:tlogfile=nil): boolean;
var
  eb: tsmat;
  cb: tdvec;
  i,j,ii,jj: integer;
  maxval: single;
begin
  eb:= tsmat.create;
  cb:= tdvec.create;
  getedgebetweenness(eb,cb,adj);
  fill;
  for k:= 0 to list.count-1 do begin
    adj.removeedge(ii,jj);
    part.cell:= adj.getcomponents(nclus);
  repeat
    if log <> nil then begin
      eb.displayasmatrix(log.stream);
      log.lf;
      end;
    maxval:= minfloat;
    for i:= 2 to adj.n do
      for j:= 1 to i-1 do
        if eb.cell[i,j] > maxval then begin
          maxval:= eb.cell[i,j];
          ii:= i; jj:= j;
          end;
    if log <> nil then begin
      log.stream.WriteLine(inttostr(ii)+' '+inttostr(jj)+' '+floattostr(maxval));
      log.lf;
      end;
  result:= maxval > 0.0;
  if result then begin
    adj.removeedge(ii,jj);
    part.cell:= adj.getcomponents(nclus);
    end;
  eb.free; cb.free;
end;*)

function getbetweennesspartition(part:tivec; var nclus:integer; adj:tnodelist; log:tlogfile=nil): boolean;
label cleanup;
type
  tpair = record
    ii,jj: integer;
    end;
var
  eb: tsmat;
  cb: tdvec;
  i,j,narcs: integer;
  maxval: single;
  pair: tpair;
  list: tlist<tpair>;
begin
  eb:= tsmat.create;
  cb:= tdvec.create;
  list:= tlist<tpair>.create;
  getedgebetweenness(eb,cb,adj);
  if log <> nil then begin
    eb.displayasmatrix(log.stream);
    log.lf;
    end;
  maxval:= 0;
  for i:= 2 to adj.n do
    for j:= 1 to i-1 do begin
      eb.cell[i,j]:= roundto(eb.cell[i,j],-4);
      if (eb.cell[i,j] > maxval) then
        maxval:= eb.cell[i,j];
      end;
  result:= maxval > 0;
  if not result then goto cleanup;
  list.Clear;
  for i:= 2 to adj.n do
    for j:= 1 to i-1 do
      if (eb.cell[i,j] >= maxval) then begin
        pair.ii:= i; pair.jj:= j;
        list.Add(pair);
        end;
  for pair in list do begin
    adj.removeedge(pair.ii,pair.jj);
    if log <> nil then begin
      narcs:= adj.countarcs;
      log.stream.WriteLine(inttostr(pair.ii)+' '+inttostr(pair.jj)+' '+floattostr(maxval)+' '+inttostr(narcs));
      log.lf;
      end;
  end;
  part.cell:= adj.getcomponents(nclus);
  if log <> nil
    then log.putstr('Components',inttostr(nclus));
  cleanup:
  eb.free; cb.free; list.free;
end;

procedure girvannewmanclustering(p:timat; adj:tnodelist; maxc:integer);
var
  n,maxit,nclus: integer;
  it: integer;
  i: integer;
  part: tivec;
  name: string;
  log: tlogfile;
begin
  log:= tlogfile.stdcreate('eb');
  part:= tivec.create;
  n:= adj.n;
  nclus:= 0;
  part.allocsize(n);
  maxit:= n*(n-1) div 2;
  p.allocsize(n,n); p.nc:= 0;
  it:= 0;
  log.stream.writeline(inttostr(adj.countarcs)+' arcs');
  repeat
    inc(it);
    try
      if not getbetweennesspartition(part,nclus,adj,nil)
        then break;
    except
      raise exception.Create('Difficulty running edge betweenness');
    end;
    name:= 'C'+inttostr(nclus);
    if p.cdvn.lookup(name) = 0 then begin
      p.copyvec2col(part,p.nc+1);
      p.cdvn.appendstr(name);
      end;
  until (nclus >= maxc) or (it >= maxit);
  part.free;
  log.destroy;
end;

end.
