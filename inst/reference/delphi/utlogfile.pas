unit utlogfile;
interface
uses
    windows, Forms, Controls, Dialogs, Math, sysutils, shellapi,
    winapi.messages,
    dbclient, db,
    ucommon, classes, utfile, uversion,
    ustring, UFn, stdctrls, ushell;
type
  tlogfiledb = class
    cds: tclientdataset;
    currentrec: integer;
    constructor create(fn:string='logfilesdb.dat');
    destructor destroy; override;
    function insert(fn,title,ft:string): tbookmark;
    function count: integer;
    procedure clear;
    procedure loadfromfile(fn:string='');
    procedure addclosinginfo(elapsed:single; bookmark:tbookmark);
    procedure savetofile(fn:string='');
  end;
  tlogfile = class
    stream: tstreamwriter;
    logdb: tlogfiledb;
    bookmark: tbookmark;
    filename: string;
    footer: string;
    addclosing: boolean;
    starttime: extended;
    pwidth: integer;
    constructor create(s:string='');
    constructor stdcreate(s:string; ft:string='Ucinet'; lfdb:tlogfiledb=nil);
    procedure appendtomemo(memo:tmemo);
    procedure browse(fn:string='ucinetlog');
    procedure closelog;
    procedure lf(lines:integer=1);
    procedure loadfromfile(fn:string);
    procedure dataset(fn:string);
    procedure outfile(prompt,ofn:string);
    procedure put(s:string; dashes:tsetofdashlines=[]);
    procedure putbool(s:string; b:boolean; truestr:string='Yes';falsestr:string='False');
    procedure putint(s1:string; x:integer; w:integer=0; pw:integer=-1);
    procedure putfloat(s1:string; x:double; w:integer=0; d:integer=-3; pw:integer=-1);
    procedure putfn(s1,s2:string);
    procedure putstr(s1:string; s2:string=''; pw:integer=-1);
    procedure title(s:string);
    procedure write(s:string);
    procedure writeln(s:string='');
    destructor destroy; override;
    end;
  procedure deletelogfiles;
var
  outputlogdb: tlogfiledb;
{===========================================================================}
implementation
{===========================================================================}
procedure deletelogfiles;
var
  s: string;
begin try
  repeat
    dec(lognum);
    s:= scratchpath + '\'+logfilename + inttostr(lognum) + '.txt';
    sysutils.deletefile(s);
  until lognum < 1;
  finally
    lognum:= 0;
  end;
end;
{---------------------------------------------------------------------------}
constructor tlogfile.create(s:string='');

  function createfile: boolean;
  var
    fn: string;
  begin try
    while lognum < maxlognum do begin
      inc(lognum);
      fn:= scratchpath + '\'+logfilename + inttostr(lognum) + '.txt';
      if fileexists(fn)
        then continue
        else filename:= fn;
      stream:= tstreamwriter.create(filename,false,TEncoding.unicode,1024);
      exit(true);
      end;
    except
      result:= false;
    end;
  end;
  
begin
  logdb:= nil;
  pwidth:= 40;
  starttime:= now;
  if not createfile
    then begin     
      deletelogfiles;
      lognum:= 0;
      if not createfile
        then raise exception.Create('Unable to create log file. May need to close and restart.');
      end;
  addclosing:= false;
  if logdb <> nil then
    bookmark:= logdb.insert(filename,s,footer);
end;
{---------------------------------------------------------------------------}
constructor tlogfile.stdcreate(s:string; ft:string='Ucinet'; lfdb:tlogfiledb=nil);

  function createfile: boolean;
  var
    fn: string;
  begin try
    while lognum < maxlognum do begin
      inc(lognum);
      fn:= scratchpath + '\'+logfilename + inttostr(lognum) + '.txt';
      if fileexists(fn)
        then continue
        else filename:= fn;
      stream:= tstreamwriter.create(filename,false,TEncoding.unicode,1024);
      exit(true);
      end;
    except
      result:= false;
    end;
  end;

begin
  logdb:= nil;
  pwidth:= 40;
  starttime:= now;
  if not createfile
    then begin
      deletelogfiles;
      lognum:= 0;
      if not createfile
        then raise exception.Create('Unable to create log file. May need to close and restart.');
      end;
  addclosing:= true;
  if s <> '' then title(s);
  if lowercase(ft) = 'ucinet'
    then footer:= copyright
    else footer:= ft;
//  footer:= 'UCINET ' + majorbuild(application.exename) + ' ' + copyright;
  if logdb <> nil then begin
    bookmark:= logdb.insert(filename,s,footer);
  end;
end;
{---------------------------------------------------------------------------}
procedure tlogfile.closelog;
var
  elapsed: double;
  elapsedstr: string;
begin
  if addclosing then begin
    stream.WriteLine;
    stream.Writeline('--------------------------------------');
    elapsed:= max(now - starttime,0.00001);
    elapsed := max(now - starttime,1.0/(60*60*24));
    elapsedstr := formatdatetime('hh:mm:ss',elapsed) + ' seconds.';
    stream.Writeline('Running time: ' + elapsedstr);
    stream.Writeline('Output generated: ' + formatdatetime('dd mmm yy hh:mm:ss',now));
    if footer <> ''
      then stream.Writeline(footer);
    if logdb <> nil then
      logdb.addclosinginfo(elapsed,bookmark);
    end;
  stream.Flush;
  stream.close;
end;
{---------------------------------------------------------------------------}
procedure tlogfile.loadfromfile;
var
  sr: tstreamreader;
begin
  sr:= tstreamreader.Create(fn);
  while not sr.EndOfStream do
    stream.WriteLine(sr.ReadLine);
  sr.Free;
end;
{---------------------------------------------------------------------------}
procedure tlogfile.title(s:string);
begin
  stream.WriteLine(uppercase(s));
  stream.writeline(dash(80));
  stream.WriteLine;
end;
{---------------------------------------------------------------------------}
procedure tlogfile.put(s:string; dashes:tsetofdashlines=[]);
begin
  if lineabove in dashes then
    stream.WriteLine(dash(length(s)));
  stream.WriteLine(s);
  if linebelow in dashes then
    stream.WriteLine(dash(length(s)));
end;

procedure tlogfile.putbool(s:string; b: boolean; truestr, falsestr: string);
begin
  if b
    then putstr(s,truestr)
    else putstr(s,falsestr);
end;

{---------------------------------------------------------------------------}
procedure tlogfile.write(s:string);
begin
  stream.Write(s);
end;
{---------------------------------------------------------------------------}
procedure tlogfile.writeln(s:string='');
begin
  stream.Writeline(s);
end;
{---------------------------------------------------------------------------}
procedure tlogfile.dataset(fn:string); //backward compatibility
begin
  putfn('Input dataset',fn);
end;
{---------------------------------------------------------------------------}
procedure tlogfile.outfile(prompt,ofn:string);    //backward compatibility
begin
  putfn(prompt, ofn);
end;
{---------------------------------------------------------------------------}
procedure tlogfile.lf(lines:integer=1);
var i: integer;
begin
  for i:= 1 to lines do
     stream.writeline;
end;
{---------------------------------------------------------------------------}
procedure tlogfile.putstr(s1:string; s2:string=''; pw:integer=-1);
begin
  if s2 = ''
    then stream.writeline(s1)
    else begin
      if pw < 0
        then pw:= pwidth;
      if (s1 <> '') and (not (lastchar(s1) in [':','=','-']))
        then s1:= s1 + ':';
      stream.WriteLine(rpad(s1,pw) +s2);
      end;
end;
{---------------------------------------------------------------------------}
procedure tlogfile.putint(s1:string; x:integer; w:integer=0; pw:integer=-1);
begin putstr(s1,istr(x,w),pw); end;
{---------------------------------------------------------------------------}
procedure tlogfile.putfloat(s1:string; x:double; w:integer=0; d:integer=-3; pw:integer=-1);
begin
  putstr(s1,fstr(x,w,d),pw);
end;
{---------------------------------------------------------------------------}
procedure tlogfile.putfn(s1,s2:string);
var
  longname: string;
begin
  longname:= allbutext(dequoted(expandfilename(s2)));
  if trim(s1) = ''
    then put(s1+longname)
    else putstr(s1,filenameonly(s2) + ' (' + longname);
end;
{---------------------------------------------------------------------------}
procedure tlogfile.browse;
begin
  closelog;
  if logdb <> nil
    then logdb.savetofile;
  if not fileexists(filename)
    then raise exception.create('File does not exist: '+filename);   
  filename:= inquotes(filename); 
//  executefile(editprogram,filename,getcurrentdir,sw_shownormal);
  execute(editprogram,filename);
end;
{---------------------------------------------------------------------------}
procedure tlogfile.appendtomemo(memo:tmemo);
var
  lines: tstringlist;
begin try
  lines:= tstringlist.Create;
  closelog;
  if logdb <> nil
    then logdb.savetofile();
  lines.LoadFromFile(filename);
  memo.Lines.AddStrings(lines);
  SendMessage(memo.Handle,EM_linescroll,0,memo.lines.count);      
finally
  lines.Free;
end;
end;
{---------------------------------------------------------------------------}
destructor tlogfile.destroy;
begin
  closelog;
  stream.free;
  inherited;
end;
{---------------------------------------------------------------------------}
constructor tlogfiledb.create(fn:string='logfilesdb.dat');
begin
  cds:= tclientdataset.Create(application);
  cds.filename:= scratchpath + '\' + fn;
  if fileexists(cds.FileName) then begin
    cds.Open;
    exit;
  end;
  cds.fielddefs.Clear;
  with cds.fielddefs.AddFieldDef do begin
    name:= 'ID';
    datatype:= ftInteger;
  end;
  with cds.fielddefs.AddFieldDef do begin
    name:= 'Title';
    datatype:= ftString;
    size:= 255;
  end;
  with cds.fielddefs.AddFieldDef do begin
    name:= 'Footer';
    datatype:= ftString;
    size:= 255;
  end;
  with cds.fielddefs.AddFieldDef do begin
    name:= 'Date';
    datatype:= ftDatetime;
  end;
  with cds.fielddefs.AddFieldDef do begin
    name:= 'Filename';
    datatype:= ftString;
    size:= max_path;
  end;
  with cds.fielddefs.AddFieldDef do begin
    name:= 'Contents';
    datatype:= ftMemo;
  end;
  with cds.fielddefs.AddFieldDef do begin
    name:= 'Elapsed';
    datatype:= ftSingle;
  end;
  cds.CreateDataSet;
end;
{---------------------------------------------------------------------------}
destructor tlogfiledb.destroy;
begin
  cds.free;
end;
{---------------------------------------------------------------------------}
function tlogfiledb.insert(fn,title,ft:string): tbookmark;
begin
  if not cds.Active then cds.Open;
  cds.Insert;
  cds.fieldbyname('ID').value:= cds.recordcount;
  cds.fieldbyname('Date').AsDatetime:= now;
  cds.FieldByName('Filename').AsString:= fn;
  cds.FieldByName('Title').AsString:= title;
  cds.FieldByName('Footer').AsString:= ft;
  cds.Post;
  currentrec:= cds.RecordCount;
  result:= cds.getbookmark;
end;
{---------------------------------------------------------------------------}
function tlogfiledb.count: integer;
begin result:= cds.recordcount; end;
{---------------------------------------------------------------------------}
procedure tlogfiledb.clear;
begin
  cds.first;
  while not cds.eof do begin
    cds.Delete;
  end;
end;
{---------------------------------------------------------------------------}
procedure tlogfiledb.loadfromfile(fn:string='');
begin
  if fn <> '' then cds.FileName:= fn;
  cds.LoadFromFile;
end;
{---------------------------------------------------------------------------}
procedure tlogfiledb.savetofile(fn:string='');
begin
  if fn <> '' then cds.FileName:= fn;
  cds.savetofile;
end;
{---------------------------------------------------------------------------}
procedure tlogfiledb.addclosinginfo(elapsed:single; bookmark:tbookmark);
begin
  if not cds.Active
    then cds.Open;
  cds.Edit;
  if cds.BookmarkValid(bookmark)
    then cds.gotobookmark(bookmark)
    else showmessage('Not valid');
  cds.Edit;
//  cds.fieldbyname('Elapsed').asSingle:= elapsed;
  cds.post;
end;
{---------------------------------------------------------------------------}

End.

