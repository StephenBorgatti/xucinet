{$r-}
unit uUFILE;

interface

uses
    vcl.Dialogs, sysutils,
    ucommon, ugeneral,ualloc,ufn,ustring;
type
  ufile = class
    uf: file;
    dt: datatype;
    isopen: boolean;
    constructor create;
    procedure saveblock(var x; n:integer);
    procedure loadblock(var x; n:integer);
    procedure loadbyte(var x; m:datatype; n:integer);
    procedure loadboolean(var x; m:datatype; n:integer);
    procedure loadinteger(var x; m:datatype; n:integer);
    procedure loadnodelist(var x; m:datatype; n:integer);
    procedure loadsmallint(var x; m:datatype; n:integer);
    procedure loadsingle(var x; m:datatype; n:integer);
    procedure loadextended(var x; m:datatype; n:integer);
    procedure loadlabel(var x; m:datatype; n:integer);
    procedure savelabel(var x; m:datatype; n:integer);
    procedure loadset(var x; m:datatype; n:integer);
    procedure savebyte(var x; m:datatype; n:integer);
    procedure savesmallint(var x; m:datatype; n:integer);
    procedure saveinteger(var x; m:datatype; n:integer);
    procedure savenodelist(var x; m:datatype; n:integer);
    procedure savesingle(var x; m:datatype; n:integer);
    procedure saveextended(var x; m:datatype; n:integer);
    procedure saveset(var x; m:datatype; n:integer);
    procedure savetyped(var x; m:datatype; n:integer);
    procedure loadtyped(var x; m:datatype; n:integer);
    procedure seekmatrix(k:int64; nr,nc:int64);
    procedure seekrow(i,k:integer; nr,nc,nm:integer);
    procedure loadrow(var x; i:integer; m:datatype; nc:integer);
    procedure loadcol(var x; j:integer; m:datatype; nr,nc:integer);
    procedure loaddiag(var x; m:datatype; nr,nc:integer);
    function open(fn:string; mode:char): integer;
    procedure closeufile;
    procedure resetufile;
    destructor destroy; override;
    end;
{---------------------------------------------------------------------------}
implementation
{---------------------------------------------------------------------------}
constructor ufile.create;
begin isopen:= false; dt:= nodt; end;
{---------------------------------------------------------------------------}
procedure ufile.loadblock(var x; n:integer);
begin try
  blockread(uf,x,n);
  except
    fillchar(x,n,0);
  end;
end;
{---------------------------------------------------------------------------}
procedure ufile.saveblock(var x; n:integer);
begin blockwrite(uf,x,n); end;
{---------------------------------------------------------------------------}
function ufile.open(fn:string; mode:char): integer;
var
  msg: string[20];
begin
  try
  if pos('.',fn) = 0 then fn := dsys(fn);
  mode:= upcase(mode);
  {$i-} assignfile(uf,fn);
  error:= ioresult; {$i+}
    if isopen then closeufile;
  if error = 0 then begin

     case mode of
//          'A','W','O': begin {$i-} rewrite(uf,1); {$i+} msg:= 'OUTPUT'; end;
          'A','W','O': begin {$i-} rewrite(uf,1); {$i+} msg:= 'OUTPUT'; end;
          'R','I':     begin
            filemode:= fmopenread;
            {$i-} reset(uf,1);  msg:= 'INPUT';
            filemode:= fmopenreadwrite;
            end;
     end;
     error:= ioresult; {$i+}
     end;
  if error = 0
    then isopen:= true
    else showmessage('ERROR: Unable to open file ' + fn + ' for ' + msg + '.');
  result:= error;
  except
    raise exception.create('Unable to open file ' + fn + ': code '+istr(error));
    error:= 1;
    result:= error;
  end;
end;
{---------------------------------------------------------------------------}
procedure ufile.loadbyte(var x; m:datatype; n:integer);
var
  b: tobytevector;
  i: integer;
begin
  if m = bytedt then
    begin blockread(uf,x,n); exit; end;
  if allocvec(b,1,n) <> 0 then exit;
  blockread(uf,b^,n);
  case m of
       extendeddt:   for i:= 1 to n do extendedvector(x)[i]:= b^[i];
       singledt:     for i:= 1 to n do singlevector(x)[i]:= b^[i];
       integerdt:    for i:= 1 to n do trueintegervector(x)[i]:= b^[i];
       smallintdt:   for i:= 1 to n do smallintvector(x)[i]:= b^[i];
       worddt:       for i:= 1 to n do wordvector(x)[i]:= b^[i];
       booleandt:    for i:= 1 to n do booleanvector(x)[i]:= b^[i] > 0;
       setdt:        begin
                     byteset(x):= [];
                     for i:= 1 to n do
                         if b^[i] > 0 then byteset(x):= byteset(x) + [i];
                     end;
  else error:= 1;
  end;
  deallocvec(b,1,n);
end;
{---------------------------------------------------------------------------}
procedure ufile.loadboolean(var x; m:datatype; n:integer);
var
  b: tobooleanvector;
  i: integer;
begin
  if m = booleandt then begin blockread(uf,x,n); exit; end;
  if allocvec(b,1,n) <> 0 then exit;
  blockread(uf,b^,n);
  case m of
       extendeddt:  for i:= 1 to n do extendedvector(x)[i]:= byte(b^[i]);
       singledt:    for i:= 1 to n do singlevector(x)[i]:= byte(b^[i]);
       smallintdt:   for i:= 1 to n do smallintvector(x)[i]:= byte(b^[i]);
       integerdt:    for i:= 1 to n do trueintegervector(x)[i]:= byte(b^[i]);
       {smallintdt:  for i:= 1 to n do smallintvector(x)[i]:= byte(b^[i]); }
       worddt:      for i:= 1 to n do wordvector(x)[i]:= byte(b^[i]);
       setdt:       begin
                    byteset(x):= [];
                    for i:= 1 to n do
                        if b^[i] then byteset(x):= byteset(x) + [i];
                    end;
  else error:= 1;
  end;
  deallocvec(b,1,n);
end;
{---------------------------------------------------------------------------}
procedure ufile.loadsmallint(var x; m:datatype; n:integer);
var
  b: array of smallint;
  i: integer;
begin
  if m = smallintdt then begin blockread(uf,x,2*n); exit; end;
//  if allocvec(b,2,n) <> 0 then exit;
//  blockread(uf,b^,2*n);
  setlength(b,n+1);
  blockread(uf,b[1],dtsize[smallintdt]*n);
  case m of
       extendeddt: for i:= 1 to n do extendedvector(x)[i]:= b[i];
       singledt:   for i:= 1 to n do singlevector(x)[i]:= b[i];
       bytedt:     for i:= 1 to n do bytevector(x)[i]:= b[i];
       integerdt:    for i:= 1 to n do trueintegervector(x)[i]:= b[i];
       {smallintdt: for i:= 1 to n do smallintvector(x)[i]:= b^[i]; }
       worddt:     for i:= 1 to n do wordvector(x)[i]:= b[i];
       booleandt:  for i:= 1 to n do booleanvector(x)[i]:= b[i] > 0;
       setdt:      begin
                   byteset(x):= [];
                   for i:= 1 to n do
                       if b[i] > 0 then byteset(x):= byteset(x) + [i];
                   end;
  else error:= 1;
  end;
  b:= nil;
end;
{---------------------------------------------------------------------------}
procedure ufile.loadinteger(var x; m:datatype; n:integer);
var
  b: arrayofinteger;
  i: integer;
begin
  try
  setlength(b,n+1);
  blockread(uf,b[1],dtsize[integerdt]*n);
  case m of
       extendeddt: for i:= 1 to n do extendedvector(x)[i]:= b[i];
       integerdt:  for i:= 1 to n do integervector(x)[i]:= b[i];
       singledt:   for i:= 1 to n do singlevector(x)[i]:= b[i];
       bytedt:     for i:= 1 to n do bytevector(x)[i]:= b[i];
       smallintdt: for i:= 1 to n do smallintvector(x)[i]:= b[i];
       worddt:     for i:= 1 to n do wordvector(x)[i]:= b[i];
       booleandt:  for i:= 1 to n do booleanvector(x)[i]:= b[i] > 0;
       setdt:      begin
                   byteset(x):= [];
                   for i:= 1 to n do
                       if b[i] > 0 then byteset(x):= byteset(x) + [i];
                   end;
  else error:= 1;
  end;
  finally
  b:= nil;
  end;
end;
{---------------------------------------------------------------------------}
procedure ufile.loadnodelist(var x; m:datatype; n:integer);
var
  b: array of integer;
  i,num: integer;
begin
  try
  setlength(b,n+1);
  blockread(uf,num,sizeof(integer));
  blockread(uf,b[1],dtsize[integerdt]*num);
  fillchar(x,n*dtsize[m],0);
  case m of
       extendeddt: for i:= 1 to num do extendedvector(x)[b[i]]:= 1;
       singledt:   for i:= 1 to num do singlevector(x)[b[i]]:= 1;
       bytedt:     for i:= 1 to num do bytevector(x)[b[i]]:= 1;
       integerdt:  for i:= 1 to num do integervector(x)[b[i]]:= 1;
       smallintdt: for i:= 1 to num do smallintvector(x)[b[i]]:= 1;
       worddt:     for i:= 1 to num do wordvector(x)[b[i]]:= 1;
       booleandt:  for i:= 1 to num do booleanvector(x)[b[i]]:= true;
  else error:= 1;
  end;
  finally
  b:= nil;
  end;
end;
{---------------------------------------------------------------------------}
procedure ufile.loadlabel(var x; m:datatype; n:integer);
var
  b: tolabelvector;
  {i: integer;}
begin
  if m = labeldt then begin
      blockread(uf,x,dtsize[labeldt]*n);
      exit;
  end;
  if allocvec(b,dtsize[labeldt],n) <> 0 then exit;
  blockread(uf,b^,dtsize[labeldt]*n);
  deallocvec(b,dtsize[labeldt],n);
end;
{---------------------------------------------------------------------------}
procedure ufile.loadset(var x; m:datatype; n:integer);
var
  b: byteset;
  i: integer;
begin
  if m = setdt then begin blockread(uf,x,32); exit; end;
  blockread(uf,b,32);
  case m of
       extendeddt:  for i:= 1 to n do
                        if i in b then
                            extendedvector(x)[i]:= 1
                        else
                            singlevector(x)[i]:= 0;
       singledt:    for i:= 1 to n do
                        if i in b then
                            singlevector(x)[i]:= 1
                        else
                            singlevector(x)[i]:= 0;
       smallintdt:   for i:= 1 to n do
                        if i in b then
                            smallintvector(x)[i]:= 1
                        else
                            smallintvector(x)[i]:= 0;
       integerdt:  for i:= 1 to n do
                        if i in b then
                            trueintegervector(x)[i]:= 1
                        else
                            trueintegervector(x)[i]:= 0;
       worddt:      for i:= 1 to n do
                        if i in b then
                            wordvector(x)[i]:= 1
                        else
                            wordvector(x)[i]:= 0;
       booleandt:   for i:= 1 to n do
                        booleanvector(x)[i]:= i in b;
    else error:= 1;
    end;
end;
{---------------------------------------------------------------------------}
(* procedure ufile.loadsingle(var x; m:datatype; n:integer);
var
  b: tosinglevector;
  i: integer;
  {result: word;}
begin
  error:= 0;
  if m = singledt then begin blockread(uf,x,4*n); exit; end;
  if allocvec(b,4,n) <> 0 then exit;
                        {blockread(uf,b^,4*n,result);}
  blockread(uf,b^,4*n);
  if m = setdt then
       byteset(x):= []
  else
       fillchar(x,dtsize[m]*n,0);
  case m of
       extendeddt:  for i:= 1 to n do extendedvector(x)[i]:= b^[i];
       doubledt:  for i:= 1 to n do doublevector(x)[i]:= b^[i];
       smallintdt:   for i:= 1 to n do
                        if b^[i] > na then
                            smallintvector(x)[i]:= 0
                        else
                            if b^[i] >= high(smallint) then
                             smallintvector(x)[i]:= high(smallint)-1
                         else
                             if b^[i] <= low(smallint) then
                                 smallintvector(x)[i]:= low(smallint)+1
                             else
                                 if b^[i] > 0.5 then
                                     smallintvector(x)[i]:= round(b^[i])
                                 else
                                     if b^[i] > singleprecision then
                                         smallintvector(x)[i]:= 1;
       integerdt:  for i:= 1 to n do
                        if b^[i] > na then
                            trueintegervector(x)[i]:= 0
                        else
                            if b^[i] > high(integer) then
                                trueintegervector(x)[i]:= high(integer)-1
                            else
                                if b^[i] < low(integer) then
                                    trueintegervector(x)[i]:= low(integer)+1
                                else
                                    if b^[i] > 0.5 then
                                        trueintegervector(x)[i]:= round(b^[i])
                                    else
                                        if b^[i] > singleprecision then
                                            trueintegervector(x)[i]:= 1;
       worddt:      for i:= 1 to n do
                        if b^[i] > na then
                            wordvector(x)[i]:= 0
                        else
                            if b^[i] > high(word) then
                                wordvector(x)[i]:= high(word)-1
                            else
                                if b^[i] < 0 then
                                    wordvector(x)[i]:= 0
                                else
                                    if b^[i] > 0.5 then
                                        wordvector(x)[i]:= round(b^[i])
                                    else
                                        if b^[i] > singleprecision then
                                            wordvector(x)[i]:= 1;
       bytedt:      for i:= 1 to n do
                        if b^[i] > na then
                            bytevector(x)[i]:= 0
                        else
                            if b^[i] > high(byte) then
                                bytevector(x)[i]:= high(byte)-1
                            else
                                if b^[i] <= 0 then
                                    bytevector(x)[i]:= 0
                                else
                                    if b^[i] > 0.5 then
                                        bytevector(x)[i]:= round(b^[i])
                                    else
                                        if b^[i] > singleprecision then
                                            bytevector(x)[i]:= 1;
       setdt:       begin
                    byteset(x):= [];
                    for i:= 1 to n do
                        if (b^[i] > 0) and (b^[i] < na) then
                            byteset(x):= byteset(x) + [i];
                    end;
       booleandt:   for i:= 1 to n do
                        if b^[i] > na then
                            booleanvector(x)[i]:= false
                        else
                            booleanvector(x)[i]:= b^[i] > 0;
       else error:= 1;
  end;
  deallocvec(b,4,n);
end;            *)
{---------------------------------------------------------------------------}
procedure ufile.loadsingle(var x; m:datatype; n:integer);
var
  b: arrayofsingle;
  i: integer;
  {result: word;}
begin
  error:= 0;
  setlength(b,n+1);
  blockread(uf,b[1],dtsize[singledt]*n);
  case m of
    singledt: for i:= 1 to n do singlevector(x)[i]:= b[i];
       extendeddt:  for i:= 1 to n do extendedvector(x)[i]:= b[i];
       doubledt:  for i:= 1 to n do doublevector(x)[i]:= b[i];
       smallintdt:   for i:= 1 to n do
                        if b[i] > na then
                            smallintvector(x)[i]:= 0
                        else
                            if b[i] >= high(smallint) then
                             smallintvector(x)[i]:= high(smallint)-1
                         else
                             if b[i] <= low(smallint) then
                                 smallintvector(x)[i]:= low(smallint)+1
                             else
                                 if b[i] > 0.5 then
                                     smallintvector(x)[i]:= round(b[i])
                                 else
                                     if b[i] > singleprecision then
                                         smallintvector(x)[i]:= 1;
       integerdt:  for i:= 1 to n do
                        if b[i] > na then
                            trueintegervector(x)[i]:= 0
                        else
                            if b[i] > high(integer) then
                                trueintegervector(x)[i]:= high(integer)-1
                            else
                                if b[i] < low(integer) then
                                    trueintegervector(x)[i]:= low(integer)+1
                                else
                                    if b[i] > 0.5 then
                                        trueintegervector(x)[i]:= round(b[i])
                                    else
                                        if b[i] > singleprecision then
                                            trueintegervector(x)[i]:= 1;
       worddt:      for i:= 1 to n do
                        if b[i] > na then
                            wordvector(x)[i]:= 0
                        else
                            if b[i] > high(word) then
                                wordvector(x)[i]:= high(word)-1
                            else
                                if b[i] < 0 then
                                    wordvector(x)[i]:= 0
                                else
                                    if b[i] > 0.5 then
                                        wordvector(x)[i]:= round(b[i])
                                    else
                                        if b[i] > singleprecision then
                                            wordvector(x)[i]:= 1;
       bytedt:      for i:= 1 to n do
                        if b[i] > na then
                            bytevector(x)[i]:= 0
                        else
                            if b[i] > high(byte) then
                                bytevector(x)[i]:= high(byte)-1
                            else
                                if b[i] <= 0 then
                                    bytevector(x)[i]:= 0
                                else
                                    if b[i] > 0.5 then
                                        bytevector(x)[i]:= round(b[i])
                                    else
                                        if b[i] > singleprecision then
                                            bytevector(x)[i]:= 1;
       setdt:       begin
                    byteset(x):= [];
                    for i:= 1 to n do
                        if (b[i] > 0) and (b[i] < na) then
                            byteset(x):= byteset(x) + [i];
                    end;
       booleandt:   for i:= 1 to n do
                        if b[i] > na then
                            booleanvector(x)[i]:= false
                        else
                            booleanvector(x)[i]:= b[i] > 0;
       else error:= 1;
  end;
  b:= nil;
end;
{---------------------------------------------------------------------------}
procedure ufile.loadextended(var x; m:datatype; n:integer);
var
  b: toextendedvector;
  i: integer;
begin
  error:= 0;
  if m = extendeddt then begin blockread(uf,x,10*n); exit; end;
  if allocvec(b,10,n) <> 0 then exit;
  blockread(uf,b^,10*n);
  if m = setdt then
       byteset(x):= []
  else
       fillchar(x,dtsize[m]*n,0);
  case m of
       singledt:  for i:= 1 to n do singlevector(x)[i]:= b^[i];
       doubledt:  for i:= 1 to n do doublevector(x)[i]:= b^[i];
       smallintdt: for i:= 1 to n do
                       if b^[i] > na then
                           smallintvector(x)[i]:= 0
                       else
                           if b^[i] > high(smallint) then {***************************************}
                               smallintvector(x)[i]:= high(smallint)-1
                           else
                               if b^[i] < low(smallint) then
                                   smallintvector(x)[i]:= low(smallint)+1
                               else
                                   if b^[i] > 0.5 then
                                       smallintvector(x)[i]:= round(b^[i])
                                   else
                                       if b^[i] > singleprecision then
                                           smallintvector(x)[i]:= 1;
       integerdt: for i:= 1 to n do
                       if b^[i] > na then
                           trueintegervector(x)[i]:= 0
                       else
                           if b^[i] > high(integer) then
                               trueintegervector(x)[i]:= high(smallint)-1
                           else
                               if b^[i] < low(smallint) then
                                   trueintegervector(x)[i]:= low(smallint)+1
                               else
                                   if b^[i] > 0.5 then
                                       trueintegervector(x)[i]:= round(b^[i])
                                   else
                                       if b^[i] > singleprecision then
                                           trueintegervector(x)[i]:= 1;
       worddt:    for i:= 1 to n do
                      if b^[i] > na then
                          wordvector(x)[i]:= 0
                      else
                          if b^[i] > high(word) then
                              wordvector(x)[i]:= high(word)-1
                          else
                              if b^[i] < 0 then
                                  wordvector(x)[i]:= 0
                              else
                                  if b^[i] > 0.5 then
                                      wordvector(x)[i]:= round(b^[i])
                                  else
                                      if b^[i] > singleprecision then
                                          wordvector(x)[i]:= 1;
       bytedt:    for i:= 1 to n do
                      if b^[i] > na then
                          bytevector(x)[i]:= 0
                      else
                          if b^[i] > 255 then
                              bytevector(x)[i]:= 255
                          else
                              if b^[i] <= 0 then
                                  bytevector(x)[i]:= 0
                              else
                                  if b^[i] > 0.5 then
                                      bytevector(x)[i]:= round(b^[i])
                                  else
                                      if b^[i] > singleprecision then
                                          bytevector(x)[i]:= 1;
       setdt:     begin
                  byteset(x):= [];
                  for i:= 1 to n do
                      if (b^[i] > 0) and (b^[i] < na) then
                          byteset(x):= byteset(x) + [i];
                  end;
       booleandt: for i:= 1 to n do
                      if b^[i] > na then
                          booleanvector(x)[i]:= false
                      else
                          booleanvector(x)[i]:= b^[i] > 0;
       else error:= 1;
  end;
  deallocvec(b,10,n);
end;
{---------------------------------------------------------------------------}
procedure ufile.loadtyped(var x; m:datatype; n:integer);
begin
  error:= 0;
  case dt of
       singledt:  loadsingle(x,m,n);
       extendeddt: loadextended(x,m,n);
       smallintdt: loadsmallint(x,m,n);
       integerdt: loadinteger(x,m,n);
       nodelistdt: loadnodelist(x,m,n);
       bytedt:    loadbyte(x,m,n);
       setdt:     loadset(x,m,n);
       booleandt: loadboolean(x,m,n);
//       doubledt: loaddouble(x,m,n);
       else begin
            error:= 1;
            MessageDlg('Illegal datatype', mtError, [mbOK], 0);
       end;
  end;
end;
{---------------------------------------------------------------------------}
procedure ufile.savebyte(var x; m:datatype; n:integer);
var
  b: tobytevector;
  i: integer;
begin
  if m = bytedt then begin blockwrite(uf,x,n); exit; end;
  if allocvec(b,1,n) <> 0 then exit;
  case m of
       singledt:  for i:= 1 to n do
                      if singlevector(x)[i] > 255 then
                          b^[i]:= 0
                      else
                          b^[i]:= round(singlevector(x)[i]);
      smallintdt:  for i:= 1 to n do b^[i]:= smallintvector(x)[i];
      integerdt: for i:= 1 to n do b^[i]:= trueintegervector(x)[i];
      worddt:     for i:= 1 to n do b^[i]:= wordvector(x)[i];
      setdt:      for i:= 1 to n do if i in byteset(x) then b^[i]:= 1;
      else error:= 1;
  end;
  blockwrite(uf,b^,n);
  deallocvec(b,1,n);
end;
{---------------------------------------------------------------------------}
procedure ufile.savesmallint(var x; m:datatype; n:integer);
var
  b: tosmallintvector;
  i: integer;
begin
  if m = smallintdt then begin blockwrite(uf,x,dtsize[smallintdt]*n); exit; end;
  if allocvec(b,dtsize[smallintdt],n) <> 0 then exit;
  case m of
       singledt:   for i:= 1 to n do
                      if singlevector(x)[i] > high(smallint) then
                          b^[i]:= 0
                      else
                          b^[i]:= round(singlevector(x)[i]);
       bytedt:     for i:= 1 to n do b^[i]:= bytevector(x)[i];
       integerdt: for i:= 1 to n do b^[i]:= trueintegervector(x)[i];
       worddt:   for i:= 1 to n do b^[i]:= wordvector(x)[i];
       setdt:    for i:= 1 to n do if i in byteset(x) then b^[i]:= 1;
       else error:= 1;
  end;
  blockwrite(uf,b^,dtsize[smallintdt]*n);
  deallocvec(b,dtsize[smallintdt],n);
end;
{---------------------------------------------------------------------------}
procedure ufile.saveinteger(var x; m:datatype; n:integer);
var
  b: array of integer;
  i: integer;
begin
  if m = integerdt then begin blockwrite(uf,x,dtsize[integerdt]*n); exit; end;
  setlength(b,n+1);
  try
  case m of
       singledt:   for i:= 1 to n do
                      if singlevector(x)[i] > high(smallint) then
                          b[i]:= 0
                      else
                          b[i]:= round(singlevector(x)[i]);
       bytedt:     for i:= 1 to n do b[i]:= bytevector(x)[i];
       smallintdt: for i:= 1 to n do b[i]:= smallintvector(x)[i];
       worddt:   for i:= 1 to n do b[i]:= wordvector(x)[i];
       setdt:    for i:= 1 to n do if i in byteset(x) then b[i]:= 1;
       else error:= 1;
  end;
  blockwrite(uf,b[1],dtsize[integerdt]*n);
  finally
  b:= nil;
  end;
end;
{---------------------------------------------------------------------------}
procedure ufile.savenodelist(var x; m:datatype; n:integer);
var
  b: array of integer;
  num, i: integer;
begin
  setlength(b,n+1);
  num:= 0;
  try
  case m of
       singledt:   for i:= 1 to n do
                      if (singlevector(x)[i] > 0) and (singlevector(x)[i] < na)
                        then begin inc(num); b[num]:= i; end;
       bytedt:     for i:= 1 to n do if bytevector(x)[i] > 0 then begin inc(num); b[num]:= i; end;
       smallintdt: for i:= 1 to n do if smallintvector(x)[i] > 0 then begin inc(num); b[num]:= i; end;
       integerdt: for i:= 1 to n do if integervector(x)[i] > 0 then begin
                    inc(num); b[num]:= i; end;
       worddt:   for i:= 1 to n do if wordvector(x)[i] > 0 then begin inc(num); b[num]:= i; end;
       else error:= 1;
  end;
  blockwrite(uf,num,sizeof(integer));
  blockwrite(uf,b[1],sizeof(integer)*num);
  finally
  b:= nil;
  end;
end;
{---------------------------------------------------------------------------}
procedure ufile.saveset(var x; m:datatype; n:integer);
var
  b: byteset;
  i: integer;
begin
  if m = setdt then begin blockwrite(uf,x,32); exit; end;
  b:= [];
  case m of
       singledt:   for i:= 1 to n do
                       if (singlevector(x)[i] > 0) and (singlevector(x)[i] < na)
                       then b:= b + [i];
       smallintdt:  for i:= 1 to n do
                       if smallintvector(x)[i] > 0 then b:= b + [i];
       integerdt: for i:= 1 to n do
                       if trueintegervector(x)[i] > 0 then b:= b + [i];
       {smallintdt: for i:= 1 to n do
                       if smallintvector(x)[i] > 0 then b:= b + [i]; }
       worddt:     for i:= 1 to n do
                       if wordvector(x)[i] > 0 then b:= b + [i];
       else error:= 1;
  end;
  blockwrite(uf,b,32);
end;
{---------------------------------------------------------------------------}
procedure ufile.savesingle(var x; m:datatype; n:integer);
var
  b: tosinglevector;
  i: integer;
begin
  if m = singledt then begin blockwrite(uf,x,dtsize[singledt]*n); exit; end;
  if allocvec(b,dtsize[singledt],n) <> 0 then exit;
  case m of
       extendeddt:   for i:= 1 to n do b^[i]:= extendedvector(x)[i];
       smallintdt:   for i:= 1 to n do b^[i]:= smallintvector(x)[i];
       integerdt:    for i:= 1 to n do b^[i]:= trueintegervector(x)[i];
       worddt:       for i:= 1 to n do b^[i]:= wordvector(x)[i];
       bytedt:       for i:= 1 to n do b^[i]:= bytevector(x)[i];
       setdt:        for i:= 1 to n do if i in byteset(x) then b^[i]:= 1;
       else error:= 1;
  end;
  blockwrite(uf,b^,dtsize[singledt]*n);
  deallocvec(b,dtsize[singledt],n);
end;
{---------------------------------------------------------------------------}
procedure ufile.saveextended(var x; m:datatype; n:integer);
var
  b: toextendedvector;
  i: integer;
begin
  if m = extendeddt then begin blockwrite(uf,x,dtsize[extendeddt]*n); exit; end;
  if allocvec(b,dtsize[extendeddt],n) <> 0 then exit;
  case m of
       singledt:     for i:= 1 to n do b^[i]:= singlevector(x)[i];
       smallintdt:   for i:= 1 to n do b^[i]:= smallintvector(x)[i];
       integerdt:    for i:= 1 to n do b^[i]:= trueintegervector(x)[i];
       worddt:       for i:= 1 to n do b^[i]:= wordvector(x)[i];
       bytedt:       for i:= 1 to n do b^[i]:= bytevector(x)[i];
       setdt:        for i:= 1 to n do if i in byteset(x) then b^[i]:= 1;
       else error:= 1;
  end;
  blockwrite(uf,b^,dtsize[extendeddt]*n);
  deallocvec(b,dtsize[extendeddt],n);
end;
{---------------------------------------------------------------------------}
procedure ufile.savelabel(var x; m:datatype; n:integer);
var
  b: tolabelvector;
  i: integer;
begin
  if m = labeldt then begin blockwrite(uf,x,dtsize[labeldt]*n); exit; end;
  if allocvec(b,dtsize[labeldt],n) <> 0 then exit;
  case m of
       smallintdt:   for i:= 1 to n do str(smallintvector(x)[i]:0,b^[i]);
       integerdt:    for i:= 1 to n do str(trueintegervector(x)[i]:0,b^[i]);
       {smallintdt:  for i:= 1 to n do str(smallintvector(x)[i]:0,b^[i]); }
       worddt:      for i:= 1 to n do str(wordvector(x)[i]:0,b^[i]);
       bytedt:      for i:= 1 to n do str(bytevector(x)[i]:0,b^[i]);
       singledt:    for i:= 1 to n do
                        if singlevector(x)[i] < na then
                            str(singlevector(x)[i]:0:8,b^[i])
                        else
                            b^[i]:= 'NA';
       setdt:       for i:= 1 to n do
                        if i in byteset(x) then b^[i]:= '1';
       else error:= 1;
  end;
  blockwrite(uf,b^,dtsize[labeldt]*n);
  deallocvec(b,dtsize[labeldt],n);
end;
{---------------------------------------------------------------------------}
procedure ufile.savetyped(var x; m:datatype; n:integer);
var xdt: datatype;
begin
  if dt = nodt then xdt:= m else xdt:= dt;
  case xdt of
       extendeddt: saveExtended(x,m,n);
       singledt: savesingle(x,m,n);
       smallintdt: savesmallint(x,m,n);
       integerdt: saveinteger(x,m,n);
       bytedt:   savebyte(x,m,n);
       setdt:    saveset(x,m,n);
       labeldt:  savelabel(x,m,n);
       nodt:  writeln('error: no datatype specified');
       else begin
            error:= 1;
            MessageDlg('Internal error in SAVETYPED', mtError, [mbOK], 0);
       end;
  end;
end;
{---------------------------------------------------------------------------}
{---------------------------------------------------------------------------}
procedure ufile.seekmatrix(k:int64; nr,nc:int64);
var
  x: int64;
begin
  x:= int64(dtsize[dt])*((k-1)*nr*nc);
  seek(uf,x);
//  seek(uf,int64(dtsize[dt])*((k-1)*nr*nc));
end;
{---------------------------------------------------------------------------}
procedure ufile.seekrow(i,k:integer; nr,nc,nm:integer);
begin seek(uf,dtsize[dt]*((k-1)*nr*nc + (i-1)*nc)); end;
{---------------------------------------------------------------------------}
procedure ufile.loadrow(var x; i:integer; m:datatype; nc:integer);
begin seek(uf,dtsize[dt]*(i-1)*nc); loadtyped(x,m,nc); end;
{---------------------------------------------------------------------------}
procedure ufile.loadcol(var x; j:integer; m:datatype; nr,nc:integer);
var i: integer;
begin
  for i:= 1 to nr do begin
    seek(uf,dtsize[dt]*((i-1)*nc+j-1));
    case m of
      bytedt:     loadtyped(bytevector(x)[i],m,1);
      smallintdt: loadtyped(smallintvector(x)[i],m,1);
      integerdt:  loadtyped(trueintegervector(x)[i],m,1);
      singledt:   loadtyped(singlevector(x)[i],m,1);
      doubledt:   loadtyped(doublevector(x)[i],m,1);
      extendeddt: loadtyped(extendedvector(x)[i],m,1);
      else error:= 1;
    end;
  end;
end;
{---------------------------------------------------------------------------}
procedure ufile.loaddiag(var x; m:datatype; nr,nc:integer);
var
  n,i: integer;
begin
  if nr < nc then n:= nr else n:= nc;
  for i:= 1 to n do begin
      seek(uf,dtsize[dt]*((i-1)*nc+i-1));
      case m of
           bytedt:     loadtyped(bytevector(x)[i],m,1);
           smallintdt: loadtyped(smallintvector(x)[i],m,1);
           singledt:   loadtyped(singlevector(x)[i],m,1);
           else error:= 1;
      end;
  end;
end;
{---------------------------------------------------------------------------}
procedure ufile.closeufile;
begin
  try
    {$i-} system.closefile(uf);
     if ioresult <> 0 then; {$i+}
  finally
    isopen:= false;
  end;
end;
{---------------------------------------------------------------------------}
procedure ufile.resetufile;
begin reset(uf,1); end;
{---------------------------------------------------------------------------}
destructor ufile.destroy;
begin
  closeufile;
  inherited;
end;
{---------------------------------------------------------------------------}
end.