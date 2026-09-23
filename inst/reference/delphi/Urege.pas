unit urege;

interface
uses
    Forms,Dialogs, Waiting,
    ucommon, ugeneral,uvector,ustring,ubmatrix,umatrix,usmatrix,uimatrix,
    umath,ucan,ugeodist;
{---------------------------------------------------------------------------}
Function sStdrege(var d:smatrix; var e:smatrix; maxit:smallint;
         usedist,diagok:boolean): smallint;
Function Stdrege(var d:bmatrix; var e:smatrix; maxit:smallint;
         usedist,diagok:boolean): smallint;
{---------------------------------------------------------------------------}
implementation
{---------------------------------------------------------------------------}
Function sStdrege(var d:smatrix; var e:smatrix; maxit:smallint;
         usedist,diagok:boolean): smallint;
label cleanup;
type
  relarray = array[1..30] of smatrixptr;
Var
  err,p,k,nrel: integer;
  xp: single;
  it,i,j,n: integer;
  r:     relarray;
  sum:   smatrix;
  deg:   svector;
  id:    boolean;
  nmiss: longint;
  hasneg: boolean;
  maxval: single;

  Function CM(ii,jj:smallint): single;
  Var
    xcm: single;
    k: smallint;

    Function XMax(k,i,j:smallint): single;
    Label cleanup;
    Var
      cmikjm,xxmax: single;
      m: integer;
      int1: single;
      kr: integer;
    Begin
      xxmax:=0; int1:=0;
      for m:= 1 to n do
          if sum.cell^[j]^[m] > 0 then begin
              int1:=0;
              for kr:= 1 to nrel do
                  with r[kr]^ do begin
                  int1:= int1 + fmin(cell^[j]^[m],cell^[i]^[k]);
                  int1:= int1 + fmin(cell^[m]^[j],cell^[k]^[i]);
                  end;
              if k > m
                then cmikjm:= e.cell^[k]^[m]*int1
                else cmikjm:= e.cell^[m]^[k]*int1;
              if cmikjm > xxmax then xxmax:= cmikjm;
              if feq(xxmax,sum.cell^[i]^[k]) then goto cleanup;
          end;
    cleanup:
      result:= xxmax;
    End;

  Begin
    xcm:= 0;
    for k:= 1 to n do
       if sum.cell^[ii]^[k] > 0 then xcm:= xcm+xmax(k,ii,jj);
    for k:= 1 to n do
        if sum.cell^[jj]^[k] > 0 then xcm:= xcm+xmax(k,jj,ii);
    result:= xcm;
  End;

  Begin
    id := false; error:= 0;
    sum:= smatrix.create; deg:= svector.create; nrel:= d.df.nl; n:= d.n;
    err := 1;
    for i:= 1 to nrel do begin
      new(r[i]);
      r[i]^:= smatrix.create;
      end;
    for i:= 1 to nrel do
      if cant(r[i]^.allocsize(n,n)) then goto cleanup;
    if cant(sum.allocsize(n,n)) then goto cleanup;
    if cant(deg.allocsize(n)) then goto cleanup;
    if not e.hasval then
        if cant(e.allocsize(n,n)) then goto cleanup;

    WaitingStart('Calculating ...',0,false); id := true;
    for k:= 1 to nrel do
      if cant(r[k]^.loadfile(d.df.indf))
        then begin
          MessageDlg('ERROR reading datafile.', mtError, [mbOK], 0);
          goto cleanup;
          end
        else begin
          if usedist then begin
            for i:= 1 to n do for j:= 1 to n do
              if r[k]^.cell^[i]^[j] > 0
                then r[k]^.cell^[i]^[j]:= 1.0
                else r[k]^.cell^[i]^[j]:= 0.0;
            if cant(sfloyd(r[k]^,nmiss)) then goto cleanup;
           (* maxval:= 0;
            for i:= 1 to n do for j:= 1 to n do
              if r[k]^.cell^[i]^[j] > maxval then
                maxval:= r[k]^.cell^[i]^[j];
            if maxval > 0 then for i:= 1 to n do for j:= 1 to n do
              r[k]^.cell^[i]^[j]:= 100*r[k]^.cell^[i]^[j]/maxval; *)
          end;
        hasneg:= false;
        for i:= 1 to n do
            for j:= 1 to n do
                if (i<>j) or diagok then begin
                    xp:= r[k]^.cell^[i]^[j];
//                    xp:= (r[k]^.cell^[i]^[j] + r[k]^.cell^[j]^[i])/2.0;
                    if xp < 0 then begin hasneg:= true; error:= 67; goto cleanup; end;
                    sum.cell^[i]^[j]:= sum.cell^[i]^[j] + xp;
                    sum.cell^[j]^[i]:= sum.cell^[j]^[i] + xp;
                    deg.cell^[i]:= deg.cell^[i] + xp;
                    deg.cell^[j]:= deg.cell^[j] + xp;
                end;
    end;
    d.closeinfile;

//    for i:= 1 to n do for j:= 1 to n do e.cell^[i]^[j]:= 1;
    for i:= 1 to n do e.cell^[i]^[i]:= 1;
    for i:= 1 to n-1 do
        for j:= i+1 to n do begin
            if (deg.cell^[i] > 0) xor (deg.cell^[j] > 0) then
                e.cell^[i]^[j]:= 0 else e.cell^[i]^[j]:= 1;
            e.cell^[j]^[i]:= e.cell^[i]^[j];
        end;

    for it:= 1 to maxit do begin
        for i:= 1 to n-1 do begin
            if deg.cell^[i] > 0 then
                for j:= i+1 to n do
                    if (deg.cell^[i] > 0) and (deg.cell^[j] > 0) then begin
                        e.cell^[i]^[j]:= cm(i,j)/(deg.cell^[i]+deg.cell^[j]);
                    end;
        end;
        for i:= 1 to n-1 do
            for j:= i+1 to n do
                e.cell^[j]^[i]:= e.cell^[i]^[j];
    end;

    WaitingEnd;
    e.title:= 'REGE Similarity ('+ istr(maxit,0) + ' iterations)';
    err := 0;
  cleanup:
    sum.free; deg.free;
    for k:= 1 to nrel do begin
      r[k]^.free;
      dispose(r[k]);
      end;
    if hasneg then err:= error;
    result:= err;
    if id then id := false;
    WaitingEnd;
End;
{---------------------------------------------------------------------------}
Function Stdrege(var d:bmatrix; var e:smatrix; maxit:smallint;
         usedist,diagok:boolean): smallint;
label cleanup;
type
  relarray = array[1..30] of bmatrixptr;
Var
  err,p,k,nrel: smallint;
  it,i,j,n: smallint;
  r:     relarray;
  sum:   imatrix;
  deg:   ivector;
  id,hasmiss: boolean;
  maxval: double;

  Function CM(ii,jj:smallint): extended;
  Var
    xcm: extended;
    k: smallint;

    Function XMax(i,j:smallint): extended;
    Label cleanup;
    Var
      cmikjm,xxmax: extended;
      m,int1: smallint;
      kr: smallint;
    Begin
      xxmax:=0; int1:=0;
      for m:= 1 to n do
          if sum.cell^[j]^[m] <> 0 then begin
              int1:=0;
              for kr:= 1 to nrel do
                  with r[kr]^ do begin
                  int1:= int1 + imin(cell^[j]^[m],cell^[i]^[k]);
                  int1:= int1 + imin(cell^[m]^[j],cell^[k]^[i]);
                  end;
              if k > m then
                  cmikjm:= e.cell^[k]^[m]*int1
              else
                  cmikjm:= e.cell^[m]^[k]*int1;
              if cmikjm > xxmax then xxmax:= cmikjm;
              if xxmax = sum.cell^[i]^[k] then goto cleanup;
          end;
    cleanup:
      xmax:=xxmax;
    End;

  Begin
    xcm:= 0;
    for k:= 1 to n do
        if sum.cell^[ii]^[k]<>0 then xcm:= xcm+xmax(ii,jj);
    for k:= 1 to n do
        if sum.cell^[jj]^[k]<>0 then xcm:= xcm+xmax(jj,ii);
    cm:= xcm;
  End;

  Begin
       id := false;
    sum:= imatrix.create; deg:= sivector.create; nrel:= d.df.nl; n:= d.n;
    err := 1;
    for i:= 1 to nrel do begin
      new(r[i]);
      r[i]^:= bmatrix.create;
      end;
    for i:= 1 to nrel do
        if cant(r[i]^.allocsize(n,n)) then goto cleanup;
    if cant(sum.allocsize(n,n)) then goto cleanup;
    if cant(deg.allocsize(n)) then goto cleanup;
    if not e.hasval then
        if cant(e.allocsize(n,n)) then goto cleanup;

    WaitingStart('Calculating ...',0,false); id := true;
    for k:= 1 to nrel do
        if cant(r[k]^.loadfile(d.df.indf)) then begin
        MessageDlg('ERROR reading datafile.', mtError, [mbOK], 0);
        goto cleanup;
        end
    else begin
        if usedist then begin
            if cant(floyd(r[k]^,hasmiss)) then goto cleanup;
        end;
        for i:= 1 to n do
            for j:= 1 to n do
                if (i<>j) or diagok then begin
                    p:= r[k]^.cell^[i]^[j];
                    sum.cell^[i]^[j]:= sum.cell^[i]^[j] + p;
                    sum.cell^[j]^[i]:= sum.cell^[j]^[i] + p;
                    deg.cell^[i]:= deg.cell^[i] + p;

                    deg.cell^[j]:= deg.cell^[j] + p;

                end;
    end;
    d.closeinfile;

    for i:= 1 to n-1 do
        for j:= i+1 to n do begin
            if (deg.cell^[i] > 0) xor (deg.cell^[j] > 0) then
                e.cell^[i]^[j]:= 0 else e.cell^[i]^[j]:= 1;
            e.cell^[j]^[i]:= e.cell^[i]^[j];
        end;

    for it:= 1 to maxit do begin
        for i:= 1 to n-1 do begin
            ShowProgress((it-1)*100 div maxit);
            Application.ProcessMessages;
            if InterruptTest then goto cleanup;
            if deg.cell^[i] > 0 then
                for j:= i+1 to n do
                    if (deg.cell^[i] > 0) and (deg.cell^[j] > 0) then begin
                        e.cell^[i]^[j]:= cm(i,j)/(deg.cell^[i]+deg.cell^[j]);
                    end;
        end;
        for i:= 1 to n-1 do
            for j:= i+1 to n do
                e.cell^[j]^[i]:= e.cell^[i]^[j];
    end;

    WaitingEnd;
    e.title:= 'REGE Similarity ('+ istr(maxit,0) + ' iterations)';
    err := 0;
  cleanup:
    sum.free; deg.free;
    for k:= 1 to nrel do begin
      r[k]^.free;
      dispose(r[k]);
      end;
    stdrege:= err;
    if id then id := false;
    WaitingEnd;
End;
{---------------------------------------------------------------------------}
Function oddrege(var d:bmatrix; var e:smatrix; maxit:smallint;
         usedist,diagok:boolean): smallint;
label cleanup;
type
  relarray = array[1..50] of bmatrixptr;
Var
  k,p,nrel: smallint;
  it,i,j,nvar: smallint;
  x,points: extended;
  r:     relarray;
  sum:   imatrix;
  deg:   ivector;
  hasmiss: boolean;

    Procedure AddPoints(i,j,k:byte);
    Var
      xbest,current: single;
      m,q: byte;
    Begin
      xbest:= 0;
      for m:= 1 to nvar do
          if (m<>j) and (sum.cell^[j]^[m] > 0) then begin
             current:= 0;
             for q:= 1 to nrel do
                 with r[q]^ do begin
                 current:= current + imin(cell^[i]^[k],cell^[j]^[m]);
                 current:= current + imin(cell^[k]^[i],cell^[m]^[j]);
                 end;
             if k > m then
                 current:= current*e.cell^[k]^[m]
             else
                 current:= current*e.cell^[m]^[k];
             if current > xbest then begin
                 xbest:= current;
                 if xbest = sum.cell^[i]^[k] then begin
                     points:= points+xbest; exit;
                 end;
             end;
          end;
      points:= points + xbest;
    End;

  Begin
    sum:= imatrix.create; deg:= sivector.create; nrel:= d.df.nl; nvar:= d.n;
    for i:= 1 to nrel do begin
      new(r[i]);
      r[i]^:= bmatrix.create;
      end;
    for i:= 1 to nrel do
        if cant(r[i]^.allocsize(nvar,nvar)) then goto cleanup;
    if cant(sum.allocsize(nvar,nvar)) then goto cleanup;
    if cant(deg.allocsize(nvar)) then goto cleanup;
    if not e.hasval then
        if cant(e.allocsize(nvar,nvar)) then goto cleanup;

    for k:= 1 to nrel do
        if cant(r[k]^.loadfile(d.df.indf)) then begin
            MessageDlg('ERROR reading datafile.', mtError, [mbOK], 0);
            goto cleanup;
        end
    else begin
        if usedist then begin
            if cant(floyd(r[k]^,hasmiss)) then goto cleanup;
        end;
        for i:= 1 to nvar do
            for j:= 1 to nvar do
                if (i<>j) or diagok then begin
                    p:= r[k]^.cell^[i]^[j];
                    sum.cell^[i]^[j]:= sum.cell^[i]^[j] + p;
                    sum.cell^[j]^[i]:= sum.cell^[j]^[i] + p;
                    deg.cell^[i]:= deg.cell^[i] + p;
                    deg.cell^[j]:= deg.cell^[j] + p;
                end;
    end;
    d.closeinfile;

    for it:= 1 to maxit do begin
        for i:= 1 to nvar-1 do
            for j:= i+1 to nvar do begin
                points:= 0;
                for k:= 1 to nvar do begin
                    if (sum.cell^[i]^[k] > 0) then addpoints(i,j,k);
                    if (sum.cell^[j]^[k] > 0) then addpoints(j,i,k);
                end;
                x:= points/(deg.cell^[i]+deg.cell^[j]);
                e.cell^[i]^[j]:= x; e.cell^[j]^[i]:= x;
            end;
    end;

  cleanup:
    sum.free; deg.free;
    for k:= 1 to nrel do begin
      r[k]^.free;
      dispose(r[k]);
      end;
    oddrege:= error;
  End;

End.