(*
  4010 have fixed strings of length 10 for labels; labtype=0
  4020 start with data; have fixed strings of length 20 for labels; labtype=1
  5000 start with date: and have variable length labels; labtype=2
  6000 start with date; variable length UNICODE labels; labtype=3
  6404 start with V6404; var length unicode labels; integer dims;
  6505 start with v6405; final byte is value of istable
*)
unit utucdataset;
interface
uses
  sysutils, classes, {dialogs,} generics.collections,
  ucommon, utstrvec, utmat, uufile, ufn, utmat3, utsmat, utvec,
  ukey, ustring;

  function getcolumnlabels(fn:string; sl:tstrings): boolean; overload;
  function getdimensions(fn:string; var nr,nc,nm:integer): boolean;
  function getdimensionsandtype(fn:string; var nr,nc,nm:integer; var dt:datatype): boolean;
  function getfileversion(fn:string): integer;
  function getlabels(fn:string; dvn:tstrvec; dim:char; fakeit:boolean=true): boolean;
  function getrowlabels(fn:string; sl:tstrings): boolean; overload;
  function loadcolumn(vec:tvec; c:integer; fn:string=''): boolean;
  function loadrow(vec:tvec; r:integer; fn:string=''): boolean;
  function loadvector(vec:tvec; fn:string; dim:string='c'; wrc:integer=1): boolean;
  function getmodes(fn:string): integer;

type
  drec = record year,month,day,dow,labtype:word; end;
  writelabelsfunction = procedure(outfile:ufile; lab:tstrvec; n:integer; labsize:integer=-1);
  versionrec = record
    extension: string;
    kind: integer; //1=binary system file; 2=access db
    versionstring: string;
    success,exists: boolean;
    filename: string;
    end;
  string6 =  string[6];
  listofstring6 = tlist < string6 >;
  tucdataset = class
    haslab: array of boolean;
    dims: array of integer;
    ucilist: listofstring6;
    xlab: tstrvec;
    infile,outfile: ufile;
    filetype: char;
    headerversion: integer;
    infn,outfn: string;
    hasread,mustdestroy: boolean;
    ndim: integer;
    datemodified: drec;
    constructor create; overload;
    destructor destroy; override;
    function load(fn:string; mat:tmat; ft:char='?'): boolean;
    function loadcolvec(vec:tvec; w:integer; fn:string=''): boolean;
    function loadhdr(fn:string; mat:tmat; ft:char='?'): boolean;
    function loadhdr4010(fn:string; mat:tmat; ft:char='?'): boolean;
    function loadhdr4020(fn:string; mat:tmat; ft:char='?'): boolean;
    function loadhdr5000(fn:string; mat:tmat; ft:char='?'): boolean;
    function loadhdr6000(fn:string; mat:tmat; ft:char='?'): boolean;
    function loadhdr6404(fn:string; mat:tmat; ft:char='?'): boolean;
    function loadhdr6405(fn:string; mat:tmat; ft:char='?'): boolean;
    function loadhdrold(fn:string; mat:tmat; ft:char='?'): boolean;
    function loadmat(mat:tmat; fn:string=''): boolean;
    function loadrowvec(vec:tvec; w:integer; fn:string=''): boolean;
    function oldsavehdr(fn:string; mat:tmat; outdt:datatype=nodt): boolean;
    function save(fn:string; mat:tmat; outdt:datatype=nodt): boolean;
    function savedsl(fn:string; mat:tmat; outdt:datatype=nodt): boolean;
    function savehdr(fn:string; mat:tmat; version:integer; outdt:datatype=nodt): boolean; overload;
    function savehdr(fn:string; mat:tmat; outdt:datatype=nodt): boolean; overload;
    function savehdrdsl(fn:string; mat:tmat; outdt:datatype=nodt): boolean;
    function savemat(mat:tmat; respectdsl:boolean=false): boolean;
    function savematdsl(mat:tmat): boolean;
    function saveuci(fn:string; mat:tmat; outdt:datatype=nodt): boolean;
    procedure closeall;
    procedure readdimensions(mat:tmat; small:boolean);
    procedure resetfile;
    procedure seekinputmatrix(mat:tmat; k:integer);
    end;
(*  tucdatasetplus = class(tucdataset)
    mat: tmat;
    function load(fn:string; ft:char='?'): boolean;
    function loadhdr(fn:string; ft:char='?'): boolean;
    function loadmat: boolean;
    function savehdr(fn:string; outdt:datatype=nodt): boolean;
    function savemat: boolean;
    function save(fn:string; outdt:datatype=nodt): boolean;
    function saveuci(fn:string; outdt:datatype=nodt): boolean;
    procedure seekinputmatrix(k:integer);
    end; *)
const
  defaultfiletype: char = 'P';
  uci40 = 0; uci41 = 1; uci50 = 2; uci60 = 3; uci61 = 4;
{---------------------------------------------------------------------------}
implementation
uses
  utsmatds, ucolspec;
const
  labsize0 = 10; labsize1 = 20;
{---------------------------------------------------------------------------}
function loadcolumn(vec:tvec; c:integer; fn:string=''): boolean;
var
  ds: tucdataset;
begin
  ds:= tucdataset.create;
  result:= ds.loadcolvec(vec,c,fn);
  ds.destroy;
end;
{---------------------------------------------------------------------------}
function loadrow(vec:tvec; r:integer; fn:string=''): boolean;
var
  ds: tucdataset;
begin
  ds:= tucdataset.create;
  result:= ds.loadrowvec(vec,r,fn);
  ds.destroy;
end;
{---------------------------------------------------------------------------}
function loadvector(vec:tvec; fn:string; dim:string='c'; wrc:integer=1): boolean;
var
  ds: tucdataset;
  d: char;
begin
  ds:= tucdataset.create;
  d:= lowercase(dim)[1];
  case d of
    'c': result:= ds.loadcolvec(vec,wrc,fn);
    'r': result:= ds.loadrowvec(vec,wrc,fn);
    end;
  ds.destroy;
end;
{---------------------------------------------------------------------------}
function getlabels(fn:string; dvn:tstrvec; dim:char; fakeit:boolean=true): boolean;
var
  m: tsmat;
  ds: tucdataset;
  mdvn: tstrvec;
  n,i: integer;
begin
  ds:= tucdataset.create;
  m:= tsmat.create;
  if not ds.loadhdr(fn,m)
    then exit(false);
  case dim of
    'c': begin mdvn:= m.cdvn; n:= m.nc; end;
    'r': begin mdvn:= m.rdvn; n:= m.nr; end;
    'l': begin mdvn:= m.mdvn; n:= m.nm; end;
    end;
  if not mdvn.hasval
    then if fakeit
      then for i:= 1 to n do
        dvn.sput(i,mdvn.labelget(i))
      else exit(false)
    else result:= dvn.copy(mdvn);
  ds.free; m.Free;
end;
{---------------------------------------------------------------------------}
function getcolumnlabels(fn:string; sl:tstrings): boolean;
var
  dvn: tstrvec;
begin
  dvn:= tstrvec.create;
  result:= true;
  if getlabels(fn,dvn,'c',true)
    then dvn.copytostrings(sl,true,dvn.n)
    else exit(false);
  dvn.Free;
end;
{---------------------------------------------------------------------------}
function getrowlabels(fn:string; sl:tstrings): boolean;
var
  dvn: tstrvec;
begin
  dvn:= tstrvec.create;
  result:= true;
  if getlabels(fn,dvn,'r',true)
    then dvn.copytostrings(sl,true,dvn.n)
    else exit(false);
  dvn.Free;
end;
{---------------------------------------------------------------------------}
function getmodes(fn:string): integer;
label cleanup;
var
  x: tsmatds;
begin try
  result:= -1;
  x:= tsmatds.create;
  x.loadhdr(fn);
  if x.is1mode
    then exit(1)
    else exit(2);
  finally
    x.free;
  end;
end;
{---------------------------------------------------------------------------}
function getdimensionsandtype(fn:string; var nr,nc,nm:integer; var dt:datatype): boolean;
label cleanup;
var
  x: tsmatds;
begin
  result:= false;
  x:= tsmatds.create;
  if not x.loadhdr(fn) then goto cleanup;
    nr:= x.nr;
    nc:= x.nc;
    nm:= x.nm;
    dt:= x.dt;
    result:= true;
  cleanup:
  x.free;
end;
{---------------------------------------------------------------------------}
(*function getdimensionsandtype(fn:string; var nr,nc,nm:integer; var dt:datatype): boolean;
label cleanup;
var
  i: integer;
  haslab: array of boolean;
  dim: array of smallint;
  s: string[6];
  d: drec;
  labsize: integer;
  ndim: smallint;
  p: array of char;
  infile: ufile;
  filetype: char;
begin
  try
  error:= 1;
  fillchar(d,sizeof(drec),0);
  filetype:= '?';
  if filetype = '?'
    then filetype:= findfiletype(fn);
  if filetype = 'U'
    then fn:= usys(fn)
    else fn:= hsys(fn);
//  infile.close;
  if infile.open(fn,'r') <> 0 then goto cleanup;
  infile.loadblock(s,6);
  if s = 'DATE:'
    then infile.loadblock(d,sizeof(drec))
    else infile.resetufile;
  infile.loadblock(dt,1);
  infile.loadblock(ndim,2);
  setlength(dim,ndim+1);
  infile.loadblock(dim[1],ndim*2);
  nc:= dim[1];
  nr:= dim[2];
  if ndim = 3
    then nm:= dim[3]
    else nm:= 1;
  if nm < 1 then nm:= 1;
  error:= 0;
cleanup:
  infile.closeufile;
  dim:= nil; haslab:= nil; p:= nil;
  result:= error = 0;
  except
    raise exception.create('Problem getting matrix dimensions from dataset.');
  end;
end;*)
{---------------------------------------------------------------------------}
function getdimensions(fn:string; var nr,nc,nm:integer): boolean;
var
  dt: datatype;
begin
  result:= getdimensionsandtype(fn,nr,nc,nm,dt);
end;
{---------------------------------------------------------------------------}
constructor tucdataset.create;
begin
  xlab:= tstrvec.create;
//  mat.mdvn.returnblank:= false;
  filetype:= defaultfiletype;
  infn:= ''; outfn:= '';
  infile:= ufile.create; outfile:= ufile.create;
  hasread:= false;
end;
{---------------------------------------------------------------------------}
destructor tucdataset.destroy;
begin
  xlab.destroy;
  closeall;
  ucilist.Free;
  infile.free; outfile.free;
  inherited destroy;
end;
{---------------------------------------------------------------------------}
function tucdataset.load(fn:string; mat:tmat; ft:char='?'): boolean;
begin try
  if loadhdr(fn,mat,ft)
    then loadmat(mat);
  result:= error = 0;
  finally
    closeall;
  end;
end;
{---------------------------------------------------------------------------}
function tucdataset.loadmat(mat:tmat; fn:string=''): boolean;
label
  cleanup;
var
  localerror: boolean;
begin
  localerror:= true;
  if length(fn) > 0
    then infn:= fn;
  if not infile.isopen
    then if infile.open(dsys(infn),'r') <> 0 then goto cleanup;
  mat.loadmat(infile);
  localerror:= false;
  cleanup:
    result:= (not localerror) and (error = 0);
//    infile.close;
end;
{---------------------------------------------------------------------------}
(*function tucdataset.loadcolvec(vec:tvec; c:integer; fn:string=''): boolean;
label
  cleanup;
var
  nr,nc,nm: integer;
begin
  try
  error:= 1;
  if length(fn) > 0 then infn:= fn;
  if not getdimensionsandtype(infn,nr,nc,nm,infile.dt) then goto cleanup;
  if not infile.isopen
    then if infile.open(dsys(infn),'r') <> 0 then goto cleanup;
  if not vec.loadcol(infile,c,nr,nc) then goto cleanup;
  error:= 0;
  cleanup:
  finally
  result:= error = 0;
  end;
end; *)
{---------------------------------------------------------------------------}
function tucdataset.loadcolvec(vec:tvec; w:integer; fn:string=''): boolean;
label
  cleanup;
var
  mat: tsmat;
begin
  try
  mat:= tsmat.create;
  error:= 1;
  //loadmat without fn: loadhdr has set infn, which may be a materialized colspec temp file
  if loadhdr(fn,mat) and loadmat(mat) then begin
    mat.extractcolumn(vec,w);
    error:= 0;
    end;
  cleanup:
  finally
    result:= error = 0;
    mat.free;
  end;
end;
{---------------------------------------------------------------------------}
function tucdataset.loadrowvec(vec:tvec; w:integer; fn:string=''): boolean;
label
  cleanup;
var
  mat: tsmat;
begin
  try
  mat:= tsmat.create;
  error:= 1;
  //loadmat without fn: loadhdr has set infn, which may be a materialized colspec temp file
  if loadhdr(fn,mat) and loadmat(mat) then begin
    mat.extractrow(vec,w);
    error:= 0;
    end;
  cleanup:
  finally
    result:= error = 0;
    mat.free;
  end;
end;
{---------------------------------------------------------------------------}
{function tucdataset.loadrowvec(vec:tvec; r:integer; fn:string=''): boolean;
label
  cleanup;
var
  nr,nc,nm: integer;
begin
  try
  error:= 1;
  if length(fn) > 0 then infn:= fn;
  if not getdimensionsandtype(infn,nr,nc,nm,infile.dt) then goto cleanup;
  if not infile.isopen
    then if infile.open(dsys(infn),'r') <> 0 then goto cleanup;
  if not vec.loadrow(infile,r,nc) then goto cleanup;
  error:= 0;
  cleanup:
  finally
    result:= error = 0;
  end;
end;}
{---------------------------------------------------------------------------}
function getfileversion(fn:string): integer;
label cleanup;
var
  ft: ucfilerec;
  s: string[6];
  infile: ufile;
  d: drec;
begin try
  infile:= ufile.create;
  ft:= getfiletypeinfo(fn);
  result:= -1;
//  if not ft.exists then 
//    raise exception.Create('UCINET dataset '+fn+' does not exist.');
  if ft.extension = '.ucidb' then
    goto cleanup;
  if infile.open(ft.filename,'r') <> 0
    then raise exception.Create('Unable to open file '+fn);
  infile.loadblock(s,6);
  s:= uppercase(s);
  if s[1] = 'V' then begin //variable length unicode labels and integer-sized dimensions
    if not trystrtoint(copy(s,2,4),result)
      then result:= -1;
    goto cleanup;
    end;
  if s = 'DATE:' then begin
    infile.loadblock(d,sizeof(drec));
    case d.labtype of
      0: result:= 4010; //10 char fixed length ascii labels
      1: result:= 4020; //20 char fixed length ascii labels
      2: result:= 5000; //variable length ascii labels
      3: result:= 6000; //variable length unicode labels
      end;
    goto cleanup;
    end;
  //if s is anything else, then it's a really old time file
  result:= 4010;
  cleanup:
  finally
    infile.free;
  end;
end;
{---------------------------------------------------------------------------}
procedure tucdataset.readdimensions(mat:tmat; small:boolean);
var
  smalldim: array of smallint;
  i: integer;
begin try
  setlength(dims,ndim+1);
  if small
    then begin
      setlength(smalldim,ndim+1);
      infile.loadblock(smalldim[1],ndim*2);
      for i:= 1 to ndim do
        dims[i]:= smalldim[i];
      smalldim:= nil;
      end
    else begin
      infile.loadblock(dims[1],ndim*4);
      end;
  mat.nc:= dims[1];
  mat.nr:= dims[2];
  if ndim = 2 then mat.nm:= 1 else mat.nm:= dims[3];
  if mat.nm < 1 then mat.nm:= 1;
  except
    raise exception.Create('Problems reading data dimensions in header file');
  end;
end;
{---------------------------------------------------------------------------}
function readfixedlabels(infile:ufile; lab:tstrvec; n,labsize:integer): boolean;
label cleanup;
var
  j,i: integer;
  s: string[255];
begin try
  error:= 0;
  lab.allocsize(n);
  for j:= 1 to n do begin
    infile.loadblock(s,labsize);
    lab[j]:= s;
    end;
  except
    error:= 1;
  end;
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
function readvariablelabels(infile:ufile; lab:tstrvec; n:integer): boolean;
label cleanup;
var
  j,i: integer;
  lablen: smallint;
  s: string[255];
  p: array of ansichar;
begin try
  error:= 0;
  lab.allocsize(n);
  for j:= 1 to n do begin
    infile.loadblock(lablen,sizeof(smallint));
    setlength(p,lablen+1);
    infile.loadblock(p[1],lablen);
    s:= '';
    for i := 1 to lablen do
      s:= s + p[i];
    lab[j]:= copy(s,1{2},lablen);
    p:= nil;
    end;
  except
    error:= 1;
  end;
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
function readunicodelabels(infile:ufile; lab:tstrvec; n:integer): boolean;
label cleanup;
var
  j,i: integer;
  nchar,lablen: smallint;
  st: string;
  w: array of char;
begin try
  error:= 0;
  lab.allocsize(n);
  for j:= 1 to n do begin
    infile.loadblock(lablen,sizeof(smallint));
    nchar:= lablen div 2;
    setlength(w,nchar+1);
    infile.loadblock(w[1],lablen);
    st:= '';
    for i := 1 to nchar do
      st:= st + w[i];
    lab[j]:= st;
    w:= nil;
    end;
  except
    error:= 1;
  end;
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
function readtitle(infile:ufile): string;
var
  tit: string[255];
begin
  tit:= '';
  infile.loadblock(tit[0],1);
  if length(tit) > 0 then
    infile.loadblock(tit[1],length(tit));
  result:= tit;
end;
{---------------------------------------------------------------------------}
function tucdataset.loadhdr4010(fn:string; mat:tmat; ft:char='?'): boolean;
label cleanup;
var
  i: integer;
begin try
  error:= 1;
  headerversion:= 4010;
  infn:= hsys(trim(fn));
  if infile.open(infn,'r') <> 0 then goto cleanup;
  infile.loadblock(infile.dt,1);
  infile.loadblock(ndim,2);
  readdimensions(mat,true);
  mat.title:= readtitle(infile);
  setlength(haslab,ndim+1);
  infile.loadblock(haslab[1],ndim);
  mat.cdvn.dealloc;
  mat.rdvn.dealloc;
  mat.mdvn.dealloc;
  if (ndim >= 1) and haslab[1] then readfixedlabels(infile,mat.cdvn,mat.nc,10);
  if (ndim >= 2) and haslab[2] then readfixedlabels(infile,mat.rdvn,mat.nr,10);
  if (ndim >= 3) and haslab[3] then readfixedlabels(infile,mat.mdvn,mat.nm,10);
  for i:= 4 to ndim do if haslab[i] then readfixedlabels(infile,xlab,dims[i],10);
  if upcase(ft) <> 'U'
    then infile.closeufile;
  error:= 0;
  cleanup:
  finally
    result:= error = 0;
  end;
end;
{---------------------------------------------------------------------------}
function tucdataset.loadhdr4020(fn:string; mat:tmat; ft:char='?'): boolean;
label cleanup;
var
  i: integer;
  s: string[6];
begin try
  error:= 1;
  headerversion:= 4020;
  infn:= hsys(trim(fn));
  if infile.open(infn,'r') <> 0 then goto cleanup;
  infile.loadblock(s,6);
  infile.loadblock(datemodified,sizeof(drec));
  infile.loadblock(infile.dt,1);
  infile.loadblock(ndim,2);
  readdimensions(mat,true);
  mat.title:= readtitle(infile);
  setlength(haslab,ndim+1);
  infile.loadblock(haslab[1],ndim);
  mat.cdvn.dealloc;
  mat.rdvn.dealloc;
  mat.mdvn.dealloc;
  if (ndim >= 1) and haslab[1] then readfixedlabels(infile,mat.cdvn,mat.nc,20);
  if (ndim >= 2) and haslab[2] then readfixedlabels(infile,mat.rdvn,mat.nr,20);
  if (ndim >= 3) and haslab[3] then readfixedlabels(infile,mat.mdvn,mat.nm,20);
  for i:= 4 to ndim do if haslab[i] then readfixedlabels(infile,xlab,dims[i],20);
  if upcase(ft) <> 'U'
    then infile.closeufile;
  error:= 0;
  cleanup:
  finally
    result:= error = 0;
  end;
end;
{---------------------------------------------------------------------------}
function tucdataset.loadhdr5000(fn:string; mat:tmat; ft:char='?'): boolean;
//start with DATE:; variable length ascii labels; smallint dimensions
label cleanup;
var
  i: integer;
  s: string[6];
begin try
  error:= 1;
  headerversion:= 5000;
  infn:= hsys(trim(fn));
  if infile.open(infn,'r') <> 0 then goto cleanup;
  infile.loadblock(s,6);
  infile.loadblock(datemodified,sizeof(drec));
  infile.loadblock(infile.dt,1);
  infile.loadblock(ndim,2);
  readdimensions(mat,true);
  mat.title:= readtitle(infile);
  setlength(haslab,ndim+1);
  infile.loadblock(haslab[1],ndim);
  mat.cdvn.dealloc;
  mat.rdvn.dealloc;
  mat.mdvn.dealloc;
  if (ndim >= 1) and haslab[1] then readvariablelabels(infile,mat.cdvn,mat.nc);
  if (ndim >= 2) and haslab[2] then readvariablelabels(infile,mat.rdvn,mat.nr);
  if (ndim >= 3) and haslab[3] then readvariablelabels(infile,mat.mdvn,mat.nm);
  for i:= 4 to ndim do if haslab[i] then readvariablelabels(infile,xlab,dims[i]);
  if upcase(ft) <> 'U'
    then infile.closeufile;
  error:= 0;
  cleanup:
  finally
    result:= error = 0;
  end;
end;
{---------------------------------------------------------------------------}
function tucdataset.loadhdr6000(fn:string; mat:tmat; ft:char='?'): boolean;
//start with DATE:; variable length unicode labels; smallint dimensions
label cleanup;
var
  i: integer;
  s: string[6];
begin try
  error:= 1;
  headerversion:= 6000;
  infn:= hsys(trim(fn));
  if infile.open(infn,'r') <> 0 then goto cleanup;
  infile.loadblock(s,6);
  infile.loadblock(datemodified,sizeof(drec));
  infile.loadblock(infile.dt,1);
  infile.loadblock(ndim,2);
  readdimensions(mat,true);
  mat.title:= readtitle(infile);
  setlength(haslab,ndim+1);
  infile.loadblock(haslab[1],ndim);
  mat.cdvn.dealloc;
  mat.rdvn.dealloc;
  mat.mdvn.dealloc;
  if (ndim >= 1) and haslab[1] then readunicodelabels(infile,mat.cdvn,mat.nc);
  if (ndim >= 2) and haslab[2] then readunicodelabels(infile,mat.rdvn,mat.nr);
  if (ndim >= 3) and haslab[3] then readunicodelabels(infile,mat.mdvn,mat.nm);
  for i:= 4 to ndim do if haslab[i] then readunicodelabels(infile,xlab,dims[i]);
  if upcase(ft) <> 'U'
    then infile.closeufile;
  error:= 0;
  cleanup:
  finally
    result:= error = 0;
  end;
end;
{---------------------------------------------------------------------------}
function tucdataset.loadhdr6404(fn:string; mat:tmat; ft:char='?'): boolean;
//loads ##h files formatted as version 6404
//start with V6404; variable length unicode labels; integer dimensions
//some of this stuff is just inherited from older formats
label cleanup;
var
  i: integer;
  s: string[6];
begin try
  error:= 1;
  infn:= hsys(trim(fn)); //add '.##h' to filename
  if infile.open(infn,'r') <> 0 then goto cleanup;
  infile.loadblock(s,6); //load first 6 bytes of file; older file versions use all 6
  if not trystrtoint(copy(s,2,4),headerversion) //this is silly code
    then headerversion:= 6404;
  //drec defined earlier as = record year,month,day,dow,labtype:word; end;
  //a word is a 4-byte non-negative integer
  infile.loadblock(datemodified,sizeof(drec)); //so we know when file as edited
//dt occupies 1 byte. defined as
  {datatype     = (nodt,bytedt,booleandt,shortintdt,worddt,smallintdt,longintdt,
                  singledt,realdt,doubledt,compdt,extendeddt,labeldt,setdt,
                  stringdt,pointerdt,chardt,integerdt,nodelistdt,sparsedt,int64dt);}
  infile.loadblock(infile.dt,1); //indicates type of data in ##d file
  infile.loadblock(ndim,2); //number of dimensions in matrix. normally 2 or 3. but more allowed
  readdimensions(mat,false); //read number of rows, cols and possibly levels in matrix
  mat.title:= readtitle(infile);
  setlength(haslab,ndim+1);
  infile.loadblock(haslab[1],ndim);
  mat.cdvn.dealloc;
  mat.rdvn.dealloc;
  mat.mdvn.dealloc;
  if (ndim >= 1) and haslab[1] then readunicodelabels(infile,mat.cdvn,mat.nc);
  if (ndim >= 2) and haslab[2] then readunicodelabels(infile,mat.rdvn,mat.nr);
  if (ndim >= 3) and haslab[3] then readunicodelabels(infile,mat.mdvn,mat.nm);
  for i:= 4 to ndim do if haslab[i] then readunicodelabels(infile,xlab,dims[i]);
  if upcase(ft) <> 'U'
    then infile.closeufile;
  error:= 0;
  cleanup:
  finally
    result:= error = 0;
  end;
end;
{---------------------------------------------------------------------------}
function tucdataset.loadhdr6405(fn:string; mat:tmat; ft:char='?'): boolean;
//loads ##h files formatted as version 6405
//start with V6405; variable length unicode labels; integer dimensions
//some of this stuff is just inherited from older formats
label cleanup;
var
  i: integer;
  s: string[6];
begin try
  error:= 1;
  infn:= hsys(trim(fn)); //add '.##h' to filename
  if infile.open(infn,'r') <> 0 then goto cleanup;
  infile.loadblock(s,6); //load first 6 bytes of file; older file versions use all 6
  if not trystrtoint(copy(s,2,4),headerversion) //this is silly code
    then headerversion:= 6405;
  //drec defined earlier as = record year,month,day,dow,labtype:word; end;
  //a word is a 4-byte non-negative integer
  infile.loadblock(datemodified,sizeof(drec)); //so we know when file as edited
//dt occupies 1 byte. defined as
  {datatype     = (nodt,bytedt,booleandt,shortintdt,worddt,smallintdt,longintdt,
                  singledt,realdt,doubledt,compdt,extendeddt,labeldt,setdt,
                  stringdt,pointerdt,chardt,integerdt,nodelistdt,sparsedt,int64dt);}
  infile.loadblock(infile.dt,1); //indicates type of data in ##d file
  infile.loadblock(ndim,2); //number of dimensions in matrix. normally 2 or 3. but more allowed
  readdimensions(mat,false); //read number of rows, cols and possibly levels in matrix
  mat.title:= readtitle(infile);
  setlength(haslab,ndim+1);
  infile.loadblock(haslab[1],ndim);
  mat.cdvn.dealloc;
  mat.rdvn.dealloc;
  mat.mdvn.dealloc;
  if (ndim >= 1) and haslab[1] then readunicodelabels(infile,mat.cdvn,mat.nc);
  if (ndim >= 2) and haslab[2] then readunicodelabels(infile,mat.rdvn,mat.nr);
  if (ndim >= 3) and haslab[3] then readunicodelabels(infile,mat.mdvn,mat.nm);
  for i:= 4 to ndim do if haslab[i] then readunicodelabels(infile,xlab,dims[i]);
  infile.loadblock(mat.istable,1);
  if upcase(ft) <> 'U'
    then infile.closeufile;
  error:= 0;
  cleanup:
  finally
    result:= error = 0;
  end;
end;
{---------------------------------------------------------------------------}
function tucdataset.loadhdr(fn:string; mat:tmat; ft:char='?'): boolean;
begin
  fn:= dequoted(fn);
  if (not ucinetfileexists(fn)) and colspec_enabled
    then fn:= materializecolspec(fn);
  if not ucinetfileexists(fn)
    then raise exception.create('File does not exist: '+fn);
  if not iskey(extractfileext(fn),'.##h|.##d') then
    fn:= fn + '.##h';
  headerversion:= getfileversion(fn);
  case headerversion of
    4010: result:= loadhdr4010(fn,mat,ft);
    4020: result:= loadhdr4020(fn,mat,ft);
    5000: result:= loadhdr5000(fn,mat,ft);
    6000: result:= loadhdr6000(fn,mat,ft);
    6404: result:= loadhdr6404(fn,mat,ft);
    6405: result:= loadhdr6405(fn,mat,ft);
    -1: begin result:= false; end;
    else raise exception.create('Unable to identify this type of file ('+fn+') . Was it created by a later version of UCINET?');
    end;
  if result then error:= 0 else error:= 1;
end;
{---------------------------------------------------------------------------}
function tucdataset.loadhdrold(fn:string; mat:tmat; ft:char='?'): boolean;
label cleanup;
var
  i: integer;
  haslab: array of boolean;
  dim: array of smallint;
  s: string[6];
  labsize: integer;
  ndim: smallint;
  p: array of char;
  tit: string[255];
  titlen: byte;
  fileversion: integer;

  function readlabels(lab:tstrvec; n:integer): boolean;
  label cleanup;
  var
    j,i: integer;
//    s: shortstring;
    s: string[255];
    st: string;
    lablen,nchar: smallint;
    p: array of ansichar;
    w: array of char;
  begin
    lab.zerofill;
    lab.dealloc;
    if not lab.allocsize(n) then goto cleanup;
    case datemodified.labtype of
      0,1: for j:= 1 to n do begin
             infile.loadblock(s,labsize);
             lab[j]:= s;
             end;
      2: for j:= 1 to n do begin
           infile.loadblock(lablen,sizeof(smallint));
           setlength(p,lablen+1);
           infile.loadblock(p[1],lablen);
           s:= '';
           for i := 1 to lablen do
             s:= s + p[i];
           lab[j]:= copy(s,1{2},lablen);
           p:= nil;
           end;
      3: for j:= 1 to n do begin
           infile.loadblock(lablen,sizeof(smallint));
           nchar:= lablen div 2;
           setlength(w,nchar+1);
           infile.loadblock(w[1],lablen);
           st:= '';
           for i := 1 to nchar do begin
             st:= st + w[i];
             end;
           lab[j]:= st;
           w:= nil;
           end;
      (*3: for j:= 1 to n do begin
           infile.loadblock(lablen,sizeof(smallint));
           setlength(st,lablen);
           infile.loadblock(st[1],lablen);
           lab[j]:= st;
           end;*)
      end;
    cleanup:
      p:= nil; w:= nil;
      result:= error = 0;
  end;

  procedure load2;
  var
    dim: array of smallint;
  begin
    setlength(dim,ndim+1);
    infile.loadblock(dim[1],ndim*2);
    mat.nc:= dim[1];
    mat.nr:= dim[2];
    if ndim = 2 then mat.nm:= 1 else mat.nm:= dim[3];
    if mat.nm < 1 then mat.nm:= 1;
    dim:= nil;
  end;

  procedure load4;
  var
    dim: array of integer;
  begin
    setlength(dim,ndim+1);
    infile.loadblock(dim[1],ndim*4);
    mat.nc:= dim[1];
    mat.nr:= dim[2];
    if ndim = 2 then mat.nm:= 1 else mat.nm:= dim[3];
    if mat.nm < 1 then mat.nm:= 1;
    dim:= nil;
  end;

begin
  error:= 1;
  try
  fillchar(datemodified,sizeof(drec),0);
  fn:= trim(fn);
  infn:= fn;
  filetype:= ft;
  if filetype = '?'
    then filetype:= findfiletype(fn);
  if filetype = 'U'
    then fn:= usys(fn)
    else fn:= hsys(fn);
  if infile.open(fn,'r') <> 0 then begin error:= 1; goto cleanup; end;
  infile.loadblock(s,6);
  fileversion:= uci40;
  if s = 'DATE:'
    then infile.loadblock(datemodified,sizeof(drec))
    else if s = 'uci61'
      then fileversion:= uci61
      else infile.resetufile;
  infile.loadblock(infile.dt,1);
  infile.loadblock(ndim,2);
  if fileversion >= uci61
    then load4
    else load2;
  setlength(haslab,ndim+1);
  tit:= '';
  infile.loadblock(tit[0],1);
  if length(tit) > 0 then
    infile.loadblock(tit[1],length(tit));
  mat.title:= tit;
(*   infile.loadblock(titlen,1);
  tit:= '';
  if titlen > 0
    then begin
      infile.loadblock(tit[1],titlen);
//      mat.title:= copy(tit,1,titlen);
      mat.title:= tit;
      end
    else mat.title:= ''; *)
  infile.loadblock(haslab[1],ndim);
  case datemodified.labtype of
    0: labsize:= labsize0;
    1: labsize:= labsize1;
    else labsize:= 0;
    end;
  mat.cdvn.dealloc;
  mat.rdvn.dealloc;
  mat.mdvn.dealloc;
  if (ndim >= 1) and haslab[1] then readlabels(mat.cdvn,mat.nc);
  if (ndim >= 2) and haslab[2] then readlabels(mat.rdvn,mat.nr);
  if (ndim >= 3) and haslab[3] then readlabels(mat.mdvn,mat.nm);
  for i:= 4 to ndim do if haslab[i] then readlabels(xlab,dim[i]);
  if filetype <> 'U'
    then infile.closeufile;
  error:= 0;
cleanup:
  finally
//  p:= nil;
  dim:= nil; haslab:= nil; p:= nil;
  result:= error = 0;
  end;
end;
{---------------------------------------------------------------------------}
function setdrec(version:integer=6404): drec;
var
  dat,part: ansistring;
begin
  dat := '';
  dat := FormatDateTime('dd/mm/yy',date);
  result.day := StrToInt(dat[1]+dat[2]);
  result.month := StrToInt(dat[4]+dat[5]);
  result.year := StrToInt(dat[7]+dat[8]);
  result.dow := DayOfWeek(date);
  case version of
    4010: result.labtype:= 0;
    4020: result.labtype:= 1;
    5000: result.labtype:= 2;
    6000: result.labtype:= 3;
    else result.labtype:= 3;
    end;
end;
{---------------------------------------------------------------------------}
function writesmalldimensions(outfile:ufile; mat:tmat): smallint;
var
  dim: array[1..3] of smallint;
  ndim: smallint;
  bytes: integer;
begin
  if (mat.nm > 1) or ((mat.nm > 0) and mat.mdvn.hasval) then ndim:= 3 else ndim:= 2;
  dim[1]:= mat.nc; dim[2]:= mat.nr; dim[3]:= mat.nm;
  bytes:= sizeof(smallint);
  outfile.saveblock(ndim,sizeof(ndim));
  outfile.saveblock(dim,ndim*bytes);
  result:= ndim;
end;
{---------------------------------------------------------------------------}
function writeintegerdimensions(outfile:ufile; mat:tmat): smallint;
var
  dim: array[1..3] of integer;
  ndim: smallint;
  bytes: integer;
begin
  if (mat.nm > 1) or ((mat.nm > 0) and mat.mdvn.hasval) then ndim:= 3 else ndim:= 2;
  dim[1]:= mat.nc; dim[2]:= mat.nr; dim[3]:= mat.nm;
  bytes:= sizeof(integer);
  outfile.saveblock(ndim,sizeof(ndim));
  outfile.saveblock(dim,ndim*bytes);
  result:= ndim;
end;
{---------------------------------------------------------------------------}
procedure writefixedlabels(outfile:ufile; lab:tstrvec; n:integer; labsize:integer=-1);
var
  j: integer;
  s: string[255];
begin
  for j:= 1 to n do begin
    s:= copy(lab[j],1,labsize);
    outfile.saveblock(s,labsize);
    end;
end;
{---------------------------------------------------------------------------}
procedure writevariablelabels(outfile:ufile; lab:tstrvec; n:integer; labsize:integer=-1);
var
  j,i: integer;
  el: smallint;
  pc: array of ansichar;
begin
  for j:= 1 to n do begin
    el:= length(lab.cell[j]);
    outfile.saveblock(el,sizeof(el));
    setlength(pc,el+1);
    for i := 1 to el do
      pc[i]:= ansichar(lab.cell[j][i]);
    outfile.saveblock(pc[1],el);
    pc:= nil;
    end;
end;
{---------------------------------------------------------------------------}
procedure writeunicodelabels(outfile:ufile; lab:tstrvec; n:integer; labsize:integer=-1);
var
  j: integer;
  nbyte: smallint;
  s: string;
begin
  for j:= 1 to n do begin
    s:= lab.labelget(j);
    nbyte:= bytelength(s);
    outfile.saveblock(nbyte,sizeof(nbyte));
    outfile.saveblock(s[1],nbyte);
    end;
end;
{---------------------------------------------------------------------------}
function tucdataset.savehdr(fn:string; mat:tmat; version:integer; outdt:datatype=nodt): boolean;
label cleanup;
var
  i: integer;
  lablen: integer;
  haslab: array[1..3] of boolean;
  ndim: smallint;
  tit: shortstring;
  dvn: tstrvec;
  writelabels: writelabelsfunction;

  procedure saveopening;
  var
    s: string[5];
  begin
    case version of
      4020,5000,6000: s:= 'DATE:';
      6404: s:= 'V6404';
      6405: s:= 'V6405';
      end;
    outfile.saveblock(s[0],6);
    datemodified:= setdrec(version);
    outfile.saveblock(datemodified,sizeof(drec));
  end;

  procedure saveoutdt;
  begin
    if outdt <> nodt
      then outfile.dt:= outdt;
    if outfile.dt = nodt then outfile.dt:= singledt;
    outfile.saveblock(outfile.dt,sizeof(outfile.dt));
  end;

  procedure saveistable;
  begin
    outfile.saveblock(mat.istable,sizeof(mat.istable));
  end;

  procedure copydvn(advn:tstrvec);
  var i: integer;
  begin
    dvn.allocate(advn.n,true,false);
    for i:= 1 to advn.n do
      dvn.cell[i]:= recodechars(advn.cell[i],#9);
  end;

begin try
  dvn:= tstrvec.create;
  error:= 0;
  fn:= trim(fn); outfn:= fn;
  if filetype = 'U'
    then fn:= usys(fn) else fn:= hsys(fn);
  if outfile.open(fn,'o') <> 0 then goto cleanup;
  if fileversionmethod = 1 then begin
    if (mat.nr > 32766) or (mat.nc > 32766) or (mat.nm > 32766)
      then version:= 6404
      else version:= 6000;
    end;
  if version > 4010 then saveopening;
  saveoutdt;
  if version >= 6404
    then ndim:= writeintegerdimensions(outfile,mat)
    else ndim:= writesmalldimensions(outfile,mat);
  tit:= shortstring(copy(mat.title,1,255));
  outfile.saveblock(tit,length(tit)+1);
  haslab[1]:= mat.cdvn.hasval; haslab[2]:= mat.rdvn.hasval; haslab[3]:= mat.mdvn.hasval;
  outfile.saveblock(haslab,ndim);
  case version of
    4010: begin writelabels:= writefixedlabels; lablen:= 10; end;
    4020: begin writelabels:= writefixedlabels; lablen:= 20; end;
    5000: writelabels:= writevariablelabels;
    6000: writelabels:= writeunicodelabels;
    else writelabels:= writeunicodelabels;
    end;
  if mat.cdvn.hasval then begin
    copydvn(mat.cdvn);
    writelabels(outfile,dvn,mat.nc,lablen);
  end;
  if mat.rdvn.hasval then begin
    copydvn(mat.rdvn);
    writelabels(outfile,dvn,mat.nr,lablen);
    end;
  if mat.mdvn.hasval then begin
    copydvn(mat.mdvn);
    writelabels(outfile,dvn,mat.nm,lablen);
    end;
  if version = 6405
    then saveistable;
  if filetype <> 'U' then outfile.closeufile;
cleanup:
  result:= error = 0;
except
  error:= 1; result:= false; dvn.free;
  raise exception.create('Problem saving header file '+fn);
end;
end;
{---------------------------------------------------------------------------}
function tucdataset.savehdr(fn:string; mat:tmat; outdt:datatype=nodt): boolean;
begin
  result:= savehdr(fn,mat,defaultucversion,outdt);
end;
{---------------------------------------------------------------------------}
function tucdataset.oldsavehdr(fn:string; mat:tmat; outdt:datatype=nodt): boolean;
label cleanup;
var
  i: integer;
  lablen: integer;
  haslab: array[1..3] of boolean;
  dim: array[1..3] of smallint;
  ndim: smallint;
  idim: array[1..3] of integer;
  indim: integer;
  s: string[5];
  tit: shortstring;

  procedure copyvals;
  var
    dat,part: ansistring;
  begin
    s:= 'DATE:';
    dat := '';
    dat := FormatDateTime('dd/mm/yy',date);
    part := dat[1]+dat[2]; datemodified.day := StrToInt(part);
    part := dat[4]+dat[5]; datemodified.month := StrToInt(part);
    part := dat[7]+dat[8]; datemodified.year := StrToInt(part);
    datemodified.dow := DayOfWeek(date);
//    d.labtype:= 2;
    datemodified.labtype:= defaultlabelstype;
    if (mat.nm > 1) or ((mat.nm > 0) and mat.mdvn.hasval) then ndim:= 3 else ndim:= 2;
    dim[1]:= mat.nc; dim[2]:= mat.nr; dim[3]:= mat.nm;
    haslab[1]:= mat.cdvn.hasval; haslab[2]:= mat.rdvn.hasval;
    haslab[3]:= mat.mdvn.hasval;
    if outfile.dt = nodt then outfile.dt:= singledt;
  end;

  procedure ucinet4;
  var
    i,j: integer;

    procedure writelabels(lab:tstrvec);
    var
      j: integer;
    begin
      for j:= 1 to lab.n do begin
        s:= copy(lab[j],1,labsize1);
        outfile.saveblock(s,labsize1);
        end;
    end;

  begin
    if mat.cdvn.hasval then writelabels(mat.cdvn);
    if mat.rdvn.hasval then writelabels(mat.rdvn);
    if mat.mdvn.hasval then writelabels(mat.mdvn);
  end;

  procedure ucinet5;

    procedure writelabels(lab:tstrvec; n:integer);
    var
      j,i: integer;
      el: smallint;
      pc: array of ansichar;
    begin
      for j:= 1 to n do begin
        el:= length(lab.cell[j]);
        outfile.saveblock(el,sizeof(el));
        setlength(pc,el+1);
        for i := 1 to el do
          pc[i]:= ansichar(lab.cell[j][i]);
        outfile.saveblock(pc[1],el);
        pc:= nil;
        end;
    end;

  begin
    if mat.cdvn.hasval
      then writelabels(mat.cdvn,mat.nc);
    if mat.rdvn.hasval
      then writelabels(mat.rdvn,mat.nr);
    if mat.mdvn.hasval
      then writelabels(mat.mdvn,mat.nm);
  end;

   procedure unicode;

    procedure writeunicodelabels1(lab:tstrvec; n:integer);
    var
      j,i: integer;
      nchar,nbyte: smallint;
      pc: array of char;
    begin
      for j:= 1 to n do begin
        nchar:= length(lab.cell[j]);
        nbyte:= nchar*2;
        outfile.saveblock(nbyte,sizeof(nbyte));
        setlength(pc,nchar+1);
        for i := 1 to nchar do
          pc[i]:= char(lab.cell[j][i]);
        outfile.saveblock(pc[1],nbyte);
        pc:= nil;
        end;
    end;

    procedure writeunicodelabels(lab:tstrvec; n:integer);
    var
      j: integer;
      nbyte: smallint;
    begin
      for j:= 1 to n do begin
        nbyte:= bytelength(lab.cell[j]);
        outfile.saveblock(nbyte,sizeof(nbyte));
        outfile.saveblock(lab.cell[j][1],nbyte);
        end;
    end;

  begin
    if mat.cdvn.hasval
      then writeunicodelabels(mat.cdvn,mat.nc);
    if mat.rdvn.hasval
      then writeunicodelabels(mat.rdvn,mat.nr);
    if mat.mdvn.hasval
      then writeunicodelabels(mat.mdvn,mat.nm);
  end;

begin
  error:= 0;
  if outdt <> nodt
    then outfile.dt:= outdt;
  if outfile.dt = nodt then outfile.dt:= singledt;
  fn:= trim(fn);
  outfn:= fn;
  if filetype = 'U'
    then fn:= usys(fn) else fn:= hsys(fn);
  if outfile.open(fn,'o') <> 0
    then goto cleanup;
  copyvals;
  outfile.saveblock(s[0],6);
  outfile.saveblock(datemodified,sizeof(drec));
  outfile.saveblock(outfile.dt,sizeof(outfile.dt));
  outfile.saveblock(ndim,sizeof(ndim));
  outfile.saveblock(dim,dtsize[smallintdt]*ndim);
  tit:= shortstring(mat.title);
  outfile.saveblock(tit,length(tit)+1);
  outfile.saveblock(haslab,ndim);
  case datemodified.labtype of
    1: ucinet4;
    2: ucinet5;
    3: unicode;
    end;
  if filetype = 'P' then outfile.closeufile;
cleanup:
     result:= error = 0;
end;
{---------------------------------------------------------------------------}
function tucdataset.savehdrdsl(fn:string; mat:tmat; outdt:datatype=nodt): boolean;
var
  m2: tsmat;
begin
  m2:= tsmat.create;
  m2.copydefdsl(mat);
  result:= savehdr(fn,m2,outdt);
  m2.free;
end;
{---------------------------------------------------------------------------}
function tucdataset.savemat(mat:tmat; respectdsl:boolean=false): boolean;
label cleanup;
begin
  try
    error:= 1;
    if not outfile.isopen
      then if outfile.open(dsys(outfn),'o') <> 0 then goto cleanup;
    if outfile.dt = nodt then outfile.dt:= mat.dt;
    case respectdsl of
      true: if not mat.savematdsl(outfile) then goto cleanup;
      false: if not mat.savemat(outfile) then goto cleanup;
    end;
    error:= 0;
    cleanup:
  finally
    result:= error = 0;
//    outfile.close;
  end;
end;
{---------------------------------------------------------------------------}
function tucdataset.savematdsl(mat:tmat): boolean;
begin
  result:= savemat(mat,true);
end;
{---------------------------------------------------------------------------}
function tucdataset.save(fn:string; mat:tmat; outdt:datatype=nodt): boolean;
begin
  error:= 0;
  if savehdr(fn,mat,outdt)
    then savemat(mat);
  outfile.closeufile;
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
function tucdataset.savedsl(fn:string; mat:tmat; outdt:datatype=nodt): boolean;
begin
  error:= 0; outdt:= singledt;
  if savehdrdsl(fn,mat,outdt)
    then savematdsl(mat);
  outfile.closeufile;
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
function tucdataset.saveuci(fn:string; mat:tmat; outdt:datatype=nodt): boolean;
begin
  filetype:= 'U';
  if savehdr(fn,mat,outdt) then savemat(mat);
  result:= error = 0;
end;
{---------------------------------------------------------------------------}
procedure tucdataset.seekinputmatrix(mat:tmat; k:integer);
begin
  infile.seekmatrix(k,mat.nr,mat.nc);
end;
{---------------------------------------------------------------------------}
procedure tucdataset.resetfile;
begin
  infile.resetufile;
end;
{---------------------------------------------------------------------------}
procedure tucdataset.closeall;
begin try
  infile.closeufile;
  outfile.closeufile;
  finally
  end;
end;
{---------------------------------------------------------------------------}
Begin

end.
