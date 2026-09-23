unit ug2display;
Interface
Uses
  sysutils, math, classes, dialogs,
  ucommon, ugeneral,ualloc,uwd, udupdash,utvec, utivec,
  {udsl,} utmat, utsmat3,
  {umath,} ustring, uvector;
{---------------------------------------------------------------------------}
type
  tdisplayoptions = record
    pw: integer;
    w: integer;
    d: integer;
    scale: single;
    zero: string;
    tit: string;
    end;
var
  displayoptions: tdisplayoptions;

procedure blockdisplay(var outf:text; x:tmat; rp1,cp1:tivec;
  pw,w,d:integer; scale:single; zero:string; sortdir:char='a'); overload;
procedure blockdisplay(sw:tstreamwriter; x:tmat; rp1,cp1:tivec;
  pw,w,d:integer; scale:single; zero:string; sortdir:char='a'); overload;
procedure getmaxminwhole(x:tmat; rd,cd:tivec; var ma,mi:extended;
          var whole:boolean; scale:single); overload;
procedure getmaxminwhole(x:tsmat3; md,rd,cd:tivec; var ma,mi:extended;
          var whole:boolean; scale:single); overload;
procedure display(var outf:text;
                  x:tmat;
                  pw: integer = 32000;
                  w: integer = 0;
                  d: integer = -1;
                  scale:single = 1.0;
                  zero:string = '0';
                  tit:string = '.'); overload;
procedure display3(var outf:text; x:tsmat3;
                  pw: integer = 32000;
                  w: integer = 0;
                  d: integer = -1;
                  scale:single = 1.0;
                  zero:string = '0'); overload;
procedure display3(stream:tstreamwriter; x:tsmat3;
                  pw: integer = 32000;
                  w: integer = 0;
                  d: integer = -1;
                  scale:single = 1.0;
                  zero:string = '0'); overload;
procedure display(stream:tstreamwriter; x:tmat;
                  pw: integer = 32000;
                  w: integer = 0;
                  d: integer = -1;
                  scale:single = 1.0;
                  zero:string = '0';
                  tit:string = '.'); overload;
procedure display(var outf:text; x:tmat; tit:string); overload;
procedure display(var outf:text; v:tvec; tit:string = ''); overload;
procedure display(stream:tstreamwriter; x:tmat); overload;

var
  printrownum: boolean = false;
  printcolnum: boolean = false;
{---------------------------------------------------------------------------}
Implementation
{---------------------------------------------------------------------------}
procedure display(stream:tstreamwriter; x:tmat);
begin
  display(stream,x,pagewidth,0,-1,1.0);
end;
{---------------------------------------------------------------------------}
procedure display(var outf:text; v:tvec; tit:string = '');
begin
  v.display(outf);
end;
{---------------------------------------------------------------------------}
procedure getmaxminwhole(x:tmat; rd,cd:tivec; var ma,mi:extended;
          var whole:boolean; scale:single);
Var
  i,j: integer;
  z: extended;
Begin
    ma:= minfloat; mi:= maxfloat; whole:= true;
    for i:= 1 to rd.n do
        for j:= 1 to cd.n do
        begin
             z:= x.fget(rd[i],cd[j]);
             if z < na then begin
                z:= z*scale;
                if z > ma then ma:= z;
                if z < mi then mi:= z;
                if frac(abs(z)) > 1E-9 then
                   whole:= false;
             end;
        end;
    if (abs(ma) < 1.0) and (abs(mi) < 1.0) then whole:= false;
End;
{---------------------------------------------------------------------------}
procedure getmaxminwhole(x:tsmat3; md,rd,cd:tivec; var ma,mi:extended;
          var whole:boolean; scale:single);
Var
  i,j,k: integer;
  z: extended;
Begin
  ma:= minfloat; mi:= maxfloat; whole:= true;
  for k:= 1 to md.n do
    for i:= 1 to rd.n do
        for j:= 1 to cd.n do
        begin
             z:= x.vget(md.iget(k),rd.iget(i),cd.iget(j))*scale;
             if z < na then begin
                if z > ma then ma:= z;
                if z < mi then mi:= z;
                if frac(abs(z)) > 1E-9 then
                   whole:= false;
             end;
        end;
    if (abs(ma) < 1.0) and (abs(mi) < 1.0) then whole:= false;
End;
{---------------------------------------------------------------------------}
{---------------------------------------------------------------------------}
procedure display(var outf:text; x:tmat; tit:string); overload;
begin
  display(outf,x,32000,0,-1,1,'0',tit);
end;
{---------------------------------------------------------------------------}
procedure display(stream:tstreamwriter; x:tmat; tit:string); overload;
begin
//  display(stream,x,32000,0,-1,1,'0',tit);
end;
{---------------------------------------------------------------------------}
{*procedure display(var outf:text; x:tmat;
                  pw: integer = 32000;
                  w: integer = 0;
                  d: integer = -1;
                  scale:single = 1.0;
                  zero:string = '0';
                  tit:string = '.'); overload;
//procedure display(var outf:text; x:tmat; pw,w,d:integer; scale:single; zero:string);
label cleanup;
Var
  i,ii,j: integer;
  xx,max,min: extended;
  whole: boolean;
  perline,lw,left1,left2,b,e: integer;
  sp: string[1];
  deleterdsl,deletecdsl: boolean;
  rownum,colnum,s: string;

    Procedure RowMargins;
    Var i: integer;
    Begin
         lw:= -1;
//         if x.rdvn.hasval then
             for i:= 1 to x.rdsl.n do
                 if length(x.rdvn.labelget(x.rdsl.iget(i))) > lw then
                     lw:= length(x.rdvn.labelget(x.rdsl.iget(i)));
         lw:= lw + 2; left1:= 0; left2:= left1 + 3 + lw;
    End;

    Procedure SetPerLine;
    Begin
      sp:= '';
      if w = 0 then begin
         sp:= ' ';
         perline:= x.nc;
         end
      else begin
         perline:= (pw-1 - (3+lw)) div w;
         if x.nc < perline then perline:= x.nc;
      end;
      if perline < 1 then perline:= 1;
    End;

    Procedure Headings;
    Var
      j: integer;

      Procedure FancyColHead;
      Var maxdigits,i,j: integer; s: string[4]; len: integer;
      Begin
        len:= 0;
        for j:= b to e do
            if x.cdsl.iget(j) > len then len:= x.cdsl.iget(j);
        if len > 0 then maxdigits:= trunc(ln(len)/ln(10.0))+1 else maxdigits:= 1;
        for i:= maxdigits downto 1 do begin
            write(outf,'':left2);
            for j:= b to e do begin
                str(x.cdsl.iget(j),s); len:= length(s);
                if length(s) < i then
                    write(outf,sp,' ':w)
                else
                    write(outf,sp,s[len-i+1]:w);
            end;
            writeln(outf);
        end;
      End;

      Procedure SimpleColHead;
      Var j: integer;
      Begin
           write(outf,'':left2);
           for j:= b to e do write(outf,sp,x.cdsl.iget(j):w);
           writeln(outf);
      End;

    Begin
         if printcolnum
           then if (w < minwidth(x.nc,1,0)) then fancycolhead else simplecolhead;
         if (not printcolnum) or (x.cdvn.hasval) then begin
             write(outf,'':left2);
             for j:= b to e do
                 write(outf,sp,system.copy(x.cdvn.labelget(x.cdsl.iget(j)),1,w-1):w);
             writeln(outf);
         end;
         write(outf,'':left2);
         for j:= b to e do
             write(outf,sp,dup('-',w-1):w);
         writeln(outf);
    End;

    procedure frombtoe(aiai:integer);
    var
      j:integer;
      xx: single;
    begin try
     for j:= b to e do begin
       xx:= x.fget(aiai,x.cdsl.iget(j));
       if xx < na
         then
           if abs(xx) < singleprecision
             then write(outf,sp,zero:w)
         else write(outf,sp,xx*scale:w:d)
         else
           write(outf,sp,naspell:w);
       end;
     except
       raise exception.create(inttostr(b) + ' ' + inttostr(e));
      end;
    end;

  procedure for1ton;
  var
    i,ii: integer;
    s: string;
  begin try
    for i:= 1 to x.rdsl.n do begin
       ii:= x.rdsl.iget(i);
       if (ii < 1) or (ii > x.nr) then
         raise exception.Create('bad ii');
       if printrownum
         then rownum:= inttostr(ii)
         else rownum:= '';
       if (not printrownum) or x.rdvn.hasval
         then begin
           s:= x.rdvn.labelget(ii);
           try
           write(outf,'':left1,rownum:3,s+' ':lw);
           except
             raise exception.Create(inttostr(left1)+rownum+inttostr(lw));
           end;
           end
         else
           write(outf,'':left1,rownum:3,' ':lw);
       try
         frombtoe(ii);
       except
         showmessage('ii = ' + inttostr(ii));
       end;
       writeln(outf);
   end;
   except
     showmessage('ii in loop '+inttostr(ii));
    end;
  end;

Begin
       error:= 0;
       deleterdsl:= false; deletecdsl:= false;
       writeln(outf);
       if tit = '.' then tit:= x.title;
       if not x.rdsl.hasval then begin
         deleterdsl:= true;
         if not x.rdsl.allocsize(x.nr) then goto cleanup;
         x.rdsl.one2n;
         end;
       if not x.cdsl.hasval then begin
         deletecdsl:= true;
         if not x.cdsl.allocsize(x.nc) then goto cleanup;
         x.cdsl.one2n;
         end;
       printcolnum:= (not x.cdvn.ordinal) and (x.nc > 1);
       printrownum:= (not x.rdvn.ordinal) and (x.nr > 1);
       if tit <> '' then begin
         writeln(outf,tit);
         writeln(outf);
         end;
       if w < 0 then w:= defaultw;
       if d < 0 then d:= defaultd;
       if (w < 1) or (d < 0) then begin
           getmaxminwhole(x,x.rdsl,x.cdsl,max,min,whole,scale);
           if (d < 0)
             then if whole then d:= 0 else d:= abs(defaultd);
           if w < 1 then w:= math.max(minwidth(max,min,d),abs(defaultw));
       end;
       if zero = '0' then zero:= fstr(0.0,w,d);
       if pw < 0 then pw:= 32000;
       rowmargins;
       setperline;
       b:= 0; e:= 0;
       w:= abs(w);
       while e < x.cdsl.n do begin
         b:= e + 1;
         e:= e + perline;
         if x.cdsl.n < e
           then e:= x.cdsl.n;
         try
           headings;
         except
           showmessage('e = ' + inttostr(e));
         end;
         for1ton;
         writeln(outf);
         end;
       writeln(outf,'----');
  cleanup:
   if deleterdsl then x.rdsl.dealloc;
   if deletecdsl then x.cdsl.dealloc;
End; *}
{---------------------------------------------------------------------------}
procedure display(var outf:text; x:tmat;
                  pw: integer = 32000;
                  w: integer = 0;
                  d: integer = -1;
                  scale:single = 1.0;
                  zero:string = '0';
                  tit:string = '.'); overload;
label cleanup;
Var
  i,ii,j: integer;
  xx,max,min: extended;
  whole: boolean;
  perline,lw,left1,left2,b,e: integer;
  sp: string[1];
  deleterdsl,deletecdsl: boolean;
  rownum,colnum: string;

    Procedure RowMargins;
    Var i: integer;
    Begin
         lw:= -1;
//         if x.rdvn.hasval then
             for i:= 1 to x.rdsl.n do
                 if length(x.rdvn.labelget(x.rdsl.iget(i))) > lw then
                     lw:= length(x.rdvn.labelget(x.rdsl.iget(i)));
         lw:= lw + 2; left1:= 0; left2:= left1 + 6 + lw;
    End;

    Procedure SetPerLine;
    Begin
      sp:= '';
      if w = 0 then begin
         sp:= ' ';
         perline:= x.nc;
         end
      else begin
         perline:= (pw-1 - (3+lw)) div w;
         if x.nc < perline then perline:= x.nc;
      end;
      if perline < 1 then perline:= 1;
    End;

    Procedure Headings;
    Var
      j: integer;

      Procedure FancyColHead;
      Var maxdigits,i,j: integer; s: string[4]; len: integer;
      Begin
        len:= 0;
        for j:= b to e do
            if x.cdsl.cell[j] > len then len:= x.cdsl[j];
        if len > 0 then maxdigits:= trunc(ln(len)/ln(10.0))+1 else maxdigits:= 1;
        for i:= maxdigits downto 1 do begin
            write(outf,pad('',left2));
            for j:= b to e do begin
                str(x.cdsl.iget(j),s);
                len:= length(s);
                if length(s) < i
                  then write(outf,sp + pad(' ',w))
                  else write(outf,sp + pad(s[len-1+1],w));
            end;
            writeln(outf);
        end;
      End;

      Procedure SimpleColHead;
      Var j: integer;
      Begin
           write(outf,pad('',left2));
           for j:= b to e do
             write(outf,sp + pad(inttostr(x.cdsl[j]),w));
           writeln(outf);
      End;

    Begin
         if printcolnum
           then if (w < minwidth(x.nc,1,0)) then fancycolhead else simplecolhead;
         if (not printcolnum) or (x.cdvn.hasval) then begin
             write(outf,pad('',left2));
             for j:= b to e do
               write(outf,sp + pad(system.Copy(x.cdvn.labelget(x.cdsl[j]),1,w-1),w));
             writeln(outf);
         end;
         write(outf,pad('',left2));
         for j:= b to e do
           write(outf,sp + pad(dup('-',w-1),w));
         writeln(outf);
    End;

  Begin
       error:= 0;
       deleterdsl:= false; deletecdsl:= false;
       writeln(outf);
       if tit = '.' then tit:= x.title;
       if not x.rdsl.hasval then begin
         deleterdsl:= true;
         if not x.rdsl.allocsize(x.nr) then goto cleanup;
         x.rdsl.one2n;
         end;
       if not x.cdsl.hasval then begin
         deletecdsl:= true;
         if not x.cdsl.allocsize(x.nc) then goto cleanup;
         x.cdsl.one2n;
         end;
       printcolnum:= (not x.cdvn.allnumeric) and (x.nc > 1);
       printrownum:= (not x.cdvn.allnumeric) and (x.nr > 1);
       if tit <> '' then begin
         writeln(outf,tit);
         writeln(outf);
         end;
       if w < 0 then w:= abs(defaultw); //get rid of abs
       if d < 0 then d:= abs(defaultd);   //get rid of abs
       if (w < 1) or (d < 0) then begin
           getmaxminwhole(x,x.rdsl,x.cdsl,max,min,whole,scale);
           if (d < 0)
             then if whole then d:= 0 else d:= abs(defaultd);
           if w < 1 then w:= math.max(minwidth(max,min,d),abs(defaultw));
         end;
       if zero = '0' then zero:= fstr(0.0,w,d);
       if pw < 0 then pw:= 32000;
       rowmargins;
       setperline;
       b:= 0; e:= 0;
       while e < x.cdsl.n do begin
           b:= e + 1; e:= e + perline;
           if x.cdsl.n < e then e:= x.cdsl.n;
           headings;
           for i:= 1 to x.rdsl.n do begin
               ii:= x.rdsl.cell[i];
               if printrownum then rownum:= inttostr(ii) else rownum:= '';
               if (not printrownum) or x.rdvn.hasval
                 then write(outf,pad('',left1)+pad(rownum,5)+pad(x.rdvn.labelget(ii),lw)+' ')
                 else write(outf,pad('',left1)+pad(rownum,5)+pad(' ',lw) + ' ');
               for j:= b to e do begin
                   xx:= x.fget(ii,x.cdsl[j]);
                   if xx < na
                     then
                       if abs(xx) < singleprecision
                         then write(outf,sp + pad(zero,w))
                         else write(outf,sp+fstr(xx*scale,w,d))
                     else write(outf,sp+pad(naspell,w));
               end;
               writeln(outf);
           end;
           writeln(outf);
       end;
       //writeln(outf,'****************************************');
       cleanup:
         if deleterdsl then x.rdsl.dealloc;
         if deletecdsl then x.cdsl.dealloc;

    End;
{---------------------------------------------------------------------------}
procedure display(stream:tstreamwriter; x:tmat;
                  pw: integer = 32000;
                  w: integer = 0;
                  d: integer = -1;
                  scale:single = 1.0;
                  zero:string = '0';
                  tit:string = '.'); overload;
label cleanup;
Var
  i,ii,j: integer;
  xx,max,min: extended;
  whole: boolean;
  perline,lw,left1,left2,b,e: integer;
  sp: string[1];
  deleterdsl,deletecdsl: boolean;
  rownum,colnum,line: string;

  Procedure RowMargins;
  Var
    i: integer;
    s: string;
  Begin
   lw:= -1;
   for i:= 1 to x.rdsl.n do begin
     s:= x.rdvn.labelget(x.rdsl.iget(i));
     if length(s) > lw then
       lw:= length(s);
   end;
   lw:= lw + 2;
   left1:= 0;
   left2:= left1 + 3 + lw;    // ??
  End;

    Procedure SetPerLine;
    Begin
      sp:= '';
      if w = 0 then begin
         sp:= ' ';
         perline:= x.nc;
         end
      else begin
         perline:= (pw-1 - (3+lw)) div w;
         if x.nc < perline then perline:= x.nc;
      end;
      if perline < 1 then perline:= 1;
    End;

    Procedure Headings;
    Var
      j: integer;

      Procedure FancyColHead;
      Var maxdigits,i,j: integer; s: string[4]; len: integer;
      Begin
        len:= 0;
        for j:= b to e do
            if x.cdsl.cell[j] > len then len:= x.cdsl[j];
        if len > 0 then maxdigits:= trunc(ln(len)/ln(10.0))+1 else maxdigits:= 1;
        for i:= maxdigits downto 1 do begin
            stream.write(pad('',left2));
            for j:= b to e do begin
                str(x.cdsl.iget(j),s);
                len:= length(s);
                if length(s) < i
                  then stream.write(sp + pad(' ',w))
                  else stream.write(sp + pad(s[len-1+1],w));
            end;
            stream.writeline;
        end;
      End;

      Procedure SimpleColHead;
      Var j: integer;
      Begin
           stream.write(pad('',left2));
           for j:= b to e do
             stream.write(sp + pad(inttostr(x.cdsl[j]),w));
           stream.writeline;
      End;

    Begin
         if printcolnum
           then if (w < minwidth(x.nc,1,0)) then fancycolhead else simplecolhead;
         if (not printcolnum) or (x.cdvn.hasval) then begin
             stream.Write(pad('',left2));
             for j:= b to e do
               stream.Write(sp + pad(system.Copy(x.cdvn.labelget(x.cdsl[j]),1,w-1),w));
             stream.WriteLine;
         end;
         stream.write(pad('',left2));
         for j:= b to e do
           stream.Write(sp + pad(dup('-',w-1),w));
         stream.WriteLine;
    End;

  Begin
       error:= 0;
       deleterdsl:= false; deletecdsl:= false;
       stream.WriteLine;
       if tit = '.' then tit:= x.title;
       if not x.rdsl.hasval then begin
         deleterdsl:= true;
         if not x.rdsl.allocsize(x.nr) then goto cleanup;
         x.rdsl.one2n;
         end;
       if not x.cdsl.hasval then begin
         deletecdsl:= true;
         if not x.cdsl.allocsize(x.nc) then goto cleanup;
         x.cdsl.one2n;
         end;
       printcolnum:= (not x.cdvn.allnumeric) and (x.nc > 1);
       printrownum:= (not x.cdvn.allnumeric) and (x.nr > 1);
       if tit <> '' then begin
         stream.writeline(tit);
         stream.WriteLine;
         end;
       if w < 0 then w:= defaultw;
       if d < 0 then d:= defaultd;
       if (w < 1) or (d < 0) then begin
           getmaxminwhole(x,x.rdsl,x.cdsl,max,min,whole,scale);
           if (d < 0)
             then if whole then d:= 0 else d:= abs(defaultd);
           if w < 1 then w:= math.max(minwidth(max,min,d),abs(defaultw));
       end;
       if zero = '0' then zero:= fstr(0.0,w,d);
       if pw < 0 then pw:= 32000;
       rowmargins;
       setperline;
       b:= 0; e:= 0;
       while e < x.cdsl.n do begin
           b:= e + 1; e:= e + perline;
           if x.cdsl.n < e then e:= x.cdsl.n;
           headings;
           for i:= 1 to x.rdsl.n do begin
               ii:= x.rdsl.cell[i];
               if printrownum then rownum:= inttostr(ii) else rownum:= '';
               if (not printrownum) or x.rdvn.hasval
                 then line:= pad('',left1) + ' ' + pad(rownum,5) + pad(x.rdvn.labelget(ii),lw) + ' '
                 else line:= pad('',left1) + ' ' + pad(' ',5) + pad(x.rdvn.labelget(ii),lw) + ' ';
               stream.Write(line);
               for j:= b to e do begin
                   xx:= x.fget(ii,x.cdsl[j]);
                   if xx < na
                     then
                       if abs(xx) < singleprecision
                         then stream.Write(sp + pad(zero,w))
                         else stream.Write(sp+fstr(xx*scale,w,d))
                     else stream.Write(sp+pad(naspell,w));
                             xx:= x.fget(ii,x.cdsl.iget(j));
                end;
               stream.Writeline;
           end;
           stream.WriteLine;
       end;
       //writeln(outf,'****************************************');
       cleanup:
         if deleterdsl then x.rdsl.dealloc;
         if deletecdsl then x.cdsl.dealloc;

    End;
{---------------------------------------------------------------------------}
procedure display3(var outf:text; x:tsmat3;
                  pw: integer = 32000;
                  w: integer = 0;
                  d: integer = -1;
                  scale:single = 1.0;
                  zero:string = '0');
var
  i: integer;
begin
  writeln(outf,x.title);
  for i:= 1 to x.nm do begin
    x.currentmat:= i;
    if x.nm = 1
      then display(outf,x,pw,w,d,scale,zero,'')
      else display(outf,x,pw,w,d,scale,zero,x.mdvn.labelget(i));
    end;
end;
{---------------------------------------------------------------------------}
procedure display3(stream:tstreamwriter; x:tsmat3;
                  pw: integer = 32000;
                  w: integer = 0;
                  d: integer = -1;
                  scale:single = 1.0;
                  zero:string = '0');
{tsmat3.displayasmatrix already iterates over all nm layers internally;
 the prior `for i := 1 to x.nm` wrapper was rendering nm copies of the full
 output (one per layer iteration), causing duplicated matrices in the log.}
begin
  x.displayasmatrix(stream,w,d);
end;
{---------------------------------------------------------------------------}
procedure display3old(var outf:text; x:tsmat3;
                  pw: integer = 32000;
                  w: integer = 0;
                  d: integer = -1;
                  scale:single = 1.0;
                  zero:string = '0');
label cleanup;
Var
  i,ii,j,k,kk: integer;
  xx,max,min: extended;
  whole: boolean;
  perline,lw,left1,left2,b,e: integer;
  sp: string[1];
  rownum,colnum: string;

    Procedure RowMargins;
    Var i: integer;
    Begin
         lw:= -1;
         if x.rdvn.hasval then
             for i:= 1 to x.rdsl.n do
                 if length(x.rdvn.labelget(x.rdsl.iget(i))) > lw then
                     lw:= length(x.rdvn.labelget(x.rdsl.iget(i)));
         lw:= lw + 2; left1:= 0; left2:= left1 + 3 + lw;
    End;

    Procedure SetPerLine;
    Begin
      sp:= '';
      if w = 0 then begin
         sp:= ' ';
         perline:= x.nc;
         end
      else begin
         perline:= (pw-1 - (3+lw)) div w;
         if x.nc < perline then perline:= x.nc;
      end;
      if perline < 1 then perline:= 1;
    End;

    Procedure Headings;
    Var
      j: integer;

      Procedure FancyColHead;
      Var maxdigits,i,j: integer; s: string[4]; len: integer;
      Begin
        len:= 0;
        for j:= b to e do
            if x.cdsl.iget(j) > len then len:= x.cdsl.iget(j);
        if len > 0
          then maxdigits:= trunc(ln(len)/ln(10))+1
          else maxdigits:= 1;
        for i:= maxdigits downto 1 do begin
            write(outf,'':left2);
            for j:= b to e do begin
                str(x.cdsl.iget(j),s); len:= length(s);
                if length(s) < i then
                    write(outf,sp,' ':w)
                else
                    write(outf,sp,s[len-i+1]:w);
            end;
            writeln(outf);
        end;
      End;

      Procedure SimpleColHead;
      Var j: integer;
      Begin
           write(outf,'':left2);
           for j:= b to e do
             write(outf,sp,x.cdsl.iget(j):w);
           writeln(outf);
      End;

    Begin
         if printcolnum
           then if (w < minwidth(x.nc,1,0)) then fancycolhead else simplecolhead;
         write(outf,'':left2);
         for j:= b to e do
           write(outf,sp,system.copy(x.cdvn.labelget(x.cdsl.iget(j)),1,w-1):w);
         writeln(outf);
         write(outf,'':left2);
         for j:= b to e do
             write(outf,sp,dup('-',w-1):w);
         writeln(outf);
    End;

  Begin
       error:= 0; writeln(outf);
       if not x.mdsl.hasval then begin
         if not x.mdsl.allocsize(x.nm) then goto cleanup;
         x.mdsl.one2n;
         end;
       if not x.rdsl.hasval then begin
         if not x.rdsl.allocsize(x.nr) then goto cleanup;
         x.rdsl.one2n;
         end;
       if not x.cdsl.hasval then begin
         if not x.cdsl.allocsize(x.nc) then goto cleanup;
         x.cdsl.one2n;
         end;
       if x.title <> '' then begin
           writeln(outf,x.title);
           writeln(outf);
       end;
       if w < 0 then w:= defaultw;
       if d < 0 then d:= defaultd;
       if (w < 1) or (d < 0) then begin
         getmaxminwhole(x,x.mdsl,x.rdsl,x.cdsl,max,min,whole,scale);
         if (d < 0)
           then if whole then d:= 0 else d:= abs(defaultd);
         if w < 1 then w:= math.max(minwidth(max,min,d),abs(defaultw));
       end;
       if zero = '0' then zero:= fstr(0.0,w,d);
       if pw < 0 then pw:= 32000;
       rowmargins;
       setperline;
       for k:= 1 to x.mdsl.n do begin
       kk:= x.mdsl.iget(k);
       writeln(outf);
       if x.nm > 1 then begin
         x.mdvn.prefix:= 'Matrix ';
         writeln(outf,x.mdvn.labelget(kk)); writeln(outf);
         end;
       b:= 0; e:= 0;
       while e < x.cdsl.n do begin
           b:= e + 1; e:= e + perline;
           if x.cdsl.n < e then e:= x.cdsl.n;
           headings;
           for i:= 1 to x.rdsl.n do begin
               ii:= x.rdsl.iget(i);
               if printrownum
                 then rownum:= inttostr(ii)
                 else rownum:= '';
//               write(outf,'':left1,rownum:3,x.rdvn.labelget(ii)+' ':lw);}
               if (not printrownum) or x.rdvn.hasval
                 then write(outf,'':left1,rownum:3,x.rdvn.labelget(ii)+' ':lw)
                 else write(outf,'':left1,rownum:3,' ':lw);
               for j:= b to e do begin
                   xx:= x.fget(ii,x.cdsl.iget(j));
                   if xx < na then
                       if abs(xx) < singleprecision then
                           write(outf,sp,zero:w)
                       else
                           write(outf,sp,xx*scale:w:d)
                   else
                       write(outf,sp,naspell:w);
               end;
               for j:= b to e do begin
                   xx:= x.vget(kk,ii,x.cdsl.iget(j));
                   if xx < na then
                       if abs(xx) < singleprecision then
                           write(outf,sp,zero:w)
                       else
                           write(outf,sp,xx*scale:w:d)
                   else
                       write(outf,sp,naspell:w);
               end;
               writeln(outf);
           end;
           writeln(outf);
       end;
       //writeln(outf,'****************************************');
       end;
       cleanup:

    End;
{---------------------------------------------------------------------------}
procedure blockdisplay(var outf:text; x:tmat; rp1,cp1:tivec;
  pw,w,d:integer; scale:single; zero:string; sortdir:char='a');
label cleanup;
Var
  i,ii,j,jj: integer;
  xx,max,min: extended;
  whole: boolean;
  perline,lw,left1,left2,b,e: integer;
  sp: string[1];
  rp,cp,rd,cd: tivec;

  Procedure RowMargins;
  Var i: integer;
    Begin
      lw:= -1;
      if x.rdvn.hasval then
         for i:= 1 to rd.n do
             if length(x.rdvn.lget(rd.iget(i))) > lw then
                lw:= length(x.rdvn.lget(rd.iget(i)));
             lw:= lw + 2;
             left1:= 0;
             left2:= left1 + 3 + lw + 1;
    End;

    Procedure SetPerLine;
    Begin
      sp:= '';
      if w <= 0 then begin
         sp:= ' ';
         perline:= x.nc;
         end
      else
         begin
         perline:= (pw-1 - (3+lw) - 2) div w;
         if x.nc < perline then
            perline:= x.nc;
         end;
      if perline < 1 then perline:= x.nc;
    End;

    Procedure Headings;
    Var
      j: integer;

      Procedure FancyColHead;
      Var maxdigits,i,j: integer; s: string[4]; len: integer;
      Begin
           len:= 0;
           for j:= b to e do
               if cd.iget(j) > len then len:= cd.iget(j);
           maxdigits:= trunc(ln(len)/ln(10))+1;
           for i:= maxdigits downto 1 do begin
               write(outf,'':left2);
           for j:= b to e do begin
               str(cd.iget(j),s); len:= length(s);
               if length(s) < i then
                   write(outf,sp,' ':w)
               else
                   write(outf,sp,s[len-i+1]:w);
               if (j = cd.n) or (cp.cell[j+1] <> cp.cell[j]) then
                   write(outf,sp,'  ');
           end;
           writeln(outf);
           end;
      End;

      Procedure SimpleColHead;
      Var j: integer;
      Begin
           write(outf,'':left2);
           for j:= b to e do begin
               write(outf,sp,cd.iget(j):w);
               if (j = cd.n) or (cp.cell[j+1] <> cp.cell[j]) then
                   write(outf,sp,'  ');
           end;
           writeln(outf);
      End;

    Begin
         if w < minwidth(x.nc,1,0) then
             fancycolhead
         else
             simplecolhead;
         if x.cdvn.hasval then begin
             write(outf,'':left2);
             for j:= b to e do begin
                 write(outf,sp,system.copy(x.cdvn.lget(cd.iget(j)),1,w-1):w);
                 if (j = cd.n) or (cp.cell[j+1] <> cp.cell[j]) then
                     write(outf,sp,'  ');
             end;
             writeln(outf);
        end;
        write(outf,'':left2-1,' ');     {'�'}
        for j:= b to e do begin
             write(outf,sp,dup('-',w):w);   {'�'}
             if (j = cd.n) then
                 write(outf,sp,'- ')    {'Ŀ'}
             else
                 if (cp.cell[j+1] <> cp.cell[j]) then
                     write(outf,sp,'--');   {'��'}
        end;
        writeln(outf);
    End;

    procedure setupvectors(d,xd,p,p1:tivec; xn:integer);
    begin
      error:= 0;
      d.copy(xd);
      if xd.hasval
        then d.copy(xd)
        else begin
          d.allocsize(xn);
          d.one2n();
          end;
      p.copydsl(p1,d);
    end;

    procedure outputrows;
    var
      i,j,ii,jj: integer;
    begin
      for i:= 1 to rd.n do begin
        ii:= rd.iget(i);
        if x.rdvn.hasval
          then write(outf,'':left1,ii:3,x.rdvn.lget(ii)+' |':lw+1)  {' �'}
          else write(outf,'':left1,ii:3,' |':lw+1);   {' �'}
        for j:= b to e do begin
          jj:= cd.iget(j); xx:= x.fget(ii,jj);
          if xx < na
            then if abs(xx) < singleprecision
              then write(outf,sp,zero:w)
              else write(outf,sp,xx*scale:w:d)
            else write(outf,sp,naspell:w);
          if (j = cd.n) or (cp.cell[j+1] <> cp.cell[j]) then
            write(outf,sp,' |');     {' �'}
          end;
        writeln(outf);
        if (i = rd.n)
          then begin
            write(outf,'':left1,'':3,' ':lw,' ');   {'�'}
            for j:= b to e do begin
              write(outf,sp,dup('-',w):w);    {'�'}
              if (j = cd.n)
                then write(outf,sp,'--')
                else if (cp.cell[j+1] <> cp.cell[j]) then
                  write(outf,sp,'--');    {'��'}
              end;
            writeln(outf);
            end
          else if (rp.cell[i+1] <> rp.cell[i]) then begin
            write(outf,'':left1,'':3,' ':lw,'-');
            for j:= b to e do begin
              write(outf,sp,dup('-',w):w);
              if (j = cd.n)
                then write(outf,sp,'--')
                else if (cp.cell[j+1] <> cp.cell[j])
                  then write(outf,sp,'--');
              end;
            writeln(outf);
            end;
        end;
    end;

  Begin
    error:= 1;
    rd:= tivec.create;
    cd:= tivec.create;
    rp:= tivec.create;
    cp:= tivec.create;
    setupvectors(rd,x.rdsl,rp,rp1,x.nr);
    setupvectors(cd,x.cdsl,cp,cp1,x.nc);
    if error > 0 then goto cleanup;
    rp.n:= rd.n; cp.n:= cd.n;
    rp.sort(sortdir,@rd); cp.sort(sortdir,@cd);
    if x.title <> '' then begin
      writeln(outf,x.title); writeln(outf);
      end;
    if w < 0 then w:= defaultw;
    if d < 0 then d:= defaultd;
    if (w < 1) or (d < 0) then begin
      getmaxminwhole(x,rd,cd,max,min,whole,scale);
      if (d < 0)
        then if whole then d:= 0 else d:= abs(defaultd);
      if w < 1 then w:= math.max(minwidth(max,min,d),abs(defaultw));
      end;
    rowmargins; setperline; b:= 0; e:= 0;
    while e < cd.n do begin
      b:= e + 1; e:= e + perline;
      if cd.n < e then e:= cd.n;
      headings;
      outputrows;
      writeln(outf);
      end;
    writeln(outf);
       {writeln(outf,'****************************************');}
cleanup:
       rd.free; cd.free; rp.free; cp.free;
End;
{---------------------------------------------------------------------------}
procedure blockdisplay(sw:tstreamwriter; x:tmat; rp1,cp1:tivec;
  pw,w,d:integer; scale:single; zero:string; sortdir:char='a');
label cleanup;
Var
  i,ii,j,jj: integer;
  xx,max,min: extended;
  whole: boolean;
  perline,lw,left1,left2,b,e: integer;
  sp: string[1];
  rp,cp,rd,cd: tivec;
  s,xcj: string;

  Procedure RowMargins;
  Var i: integer;
    Begin
      lw:= -1;
      if x.rdvn.hasval then
         for i:= 1 to rd.n do
             if length(x.rdvn.lget(rd.iget(i))) > lw then
                lw:= length(x.rdvn.lget(rd.iget(i)));
             lw:= lw + 2;
             left1:= 0;
             left2:= left1 + 4 + lw + 1;
    End;

    Procedure SetPerLine;
    Begin
      sp:= '';
      if w <= 0 then begin
         sp:= ' ';
         perline:= x.nc;
         end
      else
         begin
         perline:= (pw-1 - (4+lw) - 2) div w;
         if x.nc < perline then
            perline:= x.nc;
         end;
      if perline < 1 then perline:= x.nc;
    End;

    Procedure Headings;
    Var
      j: integer;

      Procedure FancyColHead;
      Var
        maxdigits,i,j: integer;
        s: string[4];
        len: integer;
      Begin
           len:= 0;
           for j:= b to e do
               if cd.iget(j) > len then len:= cd.iget(j);
           maxdigits:= trunc(ln(len)/ln(10))+1;
           for i:= maxdigits downto 1 do begin
               //write(outf,'':left2);
               sw.Write(pad('',left2));
           for j:= b to e do begin
               str(cd.iget(j),s); len:= length(s);
               if length(s) < i then
//                   write(outf,sp,' ':w)
                   sw.Write(sp+pad(' ',w))
               else
//                   write(outf,sp,s[len-i+1]:w);
                   sw.Write(sp+pad(s[len-i+1],w));
               if (j = cd.n) or (cp.cell[j+1] <> cp.cell[j]) then
//                   write(outf,sp,'  ');
                   sw.Write(sp+'  ');
           end;
           sw.WriteLine;
           end;
      End;

      Procedure SimpleColHead;
      Var j: integer;
      Begin
           sw.write(pad('',left2));
           for j:= b to e do begin
               sw.write(sp+istr(cd.iget(j),w));
               if (j = cd.n) or (cp.cell[j+1] <> cp.cell[j]) then
                   sw.write(sp+'  ');
           end;
           sw.WriteLine;
      End;

    Begin
         if w < minwidth(x.nc,1,0) then
             fancycolhead
         else
             simplecolhead;
         if x.cdvn.hasval then begin
             sw.write(pad('',left2));
             for j:= b to e do begin
               sw.write(sp+pad(system.Copy(x.cdvn.lget(cd.iget(j)),1,w-1),w));
               if (j = cd.n) or (cp.cell[j+1] <> cp.cell[j]) then
                 sw.Write(sp+'  ');
               end;
             sw.WriteLine;
          end;
        sw.write(pad('',left2-1)+' ');
        for j:= b to e do begin
             sw.Write(sp+pad(dup('-',w),w));
             if (j = cd.n) then
//                 write(outf,sp,'- ')
                 sw.write(sp+ '- ')
             else
                 if (cp.cell[j+1] <> cp.cell[j]) then
//                     write(outf,sp,'--');   {'��'}
                     sw.write(sp+'--');
        end;
        sw.writeline;
    End;

    procedure setupvectors(d,xd,p,p1:tivec; xn:integer);
    begin
      error:= 0;
      d.copy(xd);
      if xd.hasval
        then d.copy(xd)
        else begin
          d.allocsize(xn);
          d.one2n();
          end;
      p.copydsl(p1,d);
    end;

    procedure outputrows;
    var
      i,j,ii,jj: integer;
    begin
      for i:= 1 to rd.n do begin
        ii:= rd.iget(i);
        if x.rdvn.hasval
//          then write(outf,'':left1,ii:3,x.rdvn.lget(ii)+' |':lw+1)
          then sw.write(space(left1)+istr(ii,4)+pad(x.rdvn.lget(ii)+' |',lw+1))
//          else write(outf,'':left1,ii:3,' |':lw+1);
          else sw.write(space(left1)+istr(ii,4)+pad(' |',lw+1));
        for j:= b to e do begin
          jj:= cd.iget(j); xx:= x.fget(ii,jj);
          if xx < na
            then if abs(xx) < singleprecision
//              then write(outf,sp,zero:w)
              then sw.write(sp+pad(zero,w))
//              else write(outf,sp,xx*scale:w:d)
              else sw.write(sp+fstr(xx*scale,w,d))
//            else write(outf,sp,naspell:w);
            else sw.write(sp+pad(naspell,w));
          if (j = cd.n) or (cp.cell[j+1] <> cp.cell[j]) then
//            write(outf,sp,' |');     {' �'}
            sw.write(sp+' |');
          end;
//        writeln(outf);
        sw.writeline;
        if (i = rd.n)
          then begin
//            write(outf,'':left1,'':3,' ':lw,' ');   {'�'}
            sw.write(space(left1)+space(3)+pad(' ',lw)+' ');
            for j:= b to e do begin
//              write(outf,sp,dup('-',w):w);    {'�'}
              sw.write(sp+dash(w,w));
              if (j = cd.n)
//                then write(outf,sp,'--')
                then sw.write(sp+'--')
                else if (cp.cell[j+1] <> cp.cell[j]) then
//                  write(outf,sp,'--');    {'��'}
                  sw.write(sp+'--');
              end;
//            writeln(outf);
            sw.writeline;
            end
          else if (rp.cell[i+1] <> rp.cell[i]) then begin
//            write(outf,'':left1,'':3,' ':lw,'-');
            sw.write(space(left1+4+lw)+'-');
            for j:= b to e do begin
//              write(outf,sp,dup('-',w):w);
              sw.write(sp+dash(w,w));
              if (j = cd.n)
//                then write(outf,sp,'--')
                then sw.write(sp+'--')
                else if (cp.cell[j+1] <> cp.cell[j])
//                  then write(outf,sp,'--');
                  then sw.write(sp+'--');
              end;
            sw.writeline;
            end;
        end;
    end;

  Begin
    error:= 1;
    rd:= tivec.create;
    cd:= tivec.create;
    rp:= tivec.create;
    cp:= tivec.create;
    setupvectors(rd,x.rdsl,rp,rp1,x.nr);
    setupvectors(cd,x.cdsl,cp,cp1,x.nc);
    if error > 0 then goto cleanup;
    rp.n:= rd.n; cp.n:= cd.n;
    rp.sort(sortdir,@rd); cp.sort(sortdir,@cd);
    if x.title <> '' then begin
      sw.writeline(x.title);
      sw.writeline;
      end;
    if w < 0 then w:= defaultw;
    if d < 0 then d:= defaultd;
    if (w < 1) or (d < 0) then begin
      getmaxminwhole(x,rd,cd,max,min,whole,scale);
      if (d < 0)
        then if whole then d:= 0 else d:= abs(defaultd);
      if w < 1 then w:= math.max(minwidth(max,min,d),abs(defaultw));
      end;
    rowmargins; setperline; b:= 0; e:= 0;
    while e < cd.n do begin
      b:= e + 1; e:= e + perline;
      if cd.n < e then e:= cd.n;
      headings;
      outputrows;
      sw.writeline;
      end;
    sw.writeline;
       {writeln(outf,'****************************************');}
cleanup:
       rd.free; cd.free; rp.free; cp.free;
End;
{---------------------------------------------------------------------------}
{---------------------------------------------------------------------------}
End.
