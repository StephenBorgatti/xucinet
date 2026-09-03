{$j+}
Unit ucommon;
Interface
uses
  system.classes, sysutils, generics.collections, generics.defaults;
Type
  datatype     = (nodt,bytedt,booleandt,shortintdt,worddt,smallintdt,longintdt,
                  singledt,realdt,doubledt,compdt,extendeddt,labeldt,setdt,
                  stringdt,pointerdt,chardt,integerdt,nodelistdt,sparsedt,int64dt);
  filetype = (ft_unknown,ft_ucinet5,ft_ucinet7,ft_excel,ft_csv);
  tdichop = (opgt,opge,opeq,ople,oplt,opne,opnone);
  tmatdim = (nodim,columns,rows,levels);
  arrayof<t> = array of t;
  arrayofarrayof<t> = array of array of t;
  arrayofsingle = array of single;
  arrayofdouble = array of double;
  arrayofinteger = array of integer;
  arrayofbyte = array of byte;
  arrayofboolean = array of boolean;
  arrayofstring = array of string;
  arrayofextended = array of extended;
  arrayofarrayofinteger =  array of arrayofinteger;
  arrayofarrayofsingle =  array of arrayofsingle;
  arrayofarrayofdouble =  array of arrayofdouble;
  arrayofarrayofextended =  array of array of extended;
  arrayofarrayofboolean = array of array of boolean;
  arrayofarrayofbyte = array of array of byte;
  tintlist = tlist<integer>;
  tilist = tlist<integer>;
  tarraystring = tarray<string>;
  pairofextended = record
    x,y: extended;
  end;
  tintdict = tdictionary<integer,integer>;
  tintsingdict = tdictionary<integer,single>;
  wdrec = record
    w: integer;
    d: integer;
    end;
  symtype = (sy_none,sy_union,sy_inter,sy_avg,sy_sum);
  tegometh = (em_out,em_in,em_union,em_intersect);
  tristate = -1..1;
  complexdouble = record
    re,co: double;
    end;
  tintsingle = record
    idx: integer;
    value: single;
    end;
  tdirtype = (undirected, directed);
CONST
  epsilon      = 1E-9;
  minint = -2147483648;
  singleprecision = 1E-7;  {actually is 6E-8}
  FuzzFactor = 1000;
  SingleResolution   = 1E-7 * FuzzFactor;
  DoubleResolution   = 1E-15 * FuzzFactor;
{$IFDEF EXTENDEDIS10BYTES}
  ExtendedResolution = 1E-19 * FuzzFactor;
{$ELSE  EXTENDEDIS10BYTES}
  ExtendedResolution = DoubleResolution;
{$ENDIF EXTENDEDIS10BYTES}
  doubleprecision = 1E-15;
  singletolerance = 1E-4;  {sqrt of single precision}
  singleEPSILON = 1.19209290E-07;
  doubleEPSILON = 2.2204460492503131E-16;
  extendedEPSILON = 1.084202172485504434e-019;
  na           = 1E37;
  bna          = 1E38;
  naspell: string[8] = '';
  wna          = '1E38';
  minfloat     = -1E37;
  maxfloat     = 1E38;
  maxlongint   = 2147483647; {1200000}
  maxshortint  = 32768;
  ptrsize      = 4;
  negative = -1; positive = 1; neutral = 0;

  dtstr: array[datatype] of string[8] = ('UNKNOWN','BYTE','BOOLEAN',
          'SHORTINT','WORD','SMALLINT','LONGINT','SINGLE','REAL','DOUBLE',
          'COMP','EXTENDED','LABEL','SET','STRING','POINTER','CHAR','INTEGER',
          'NODELIST','SPARSEMATRIX','INT64');
  dtsize: array[datatype] of integer
            = (0,1,1,1,2,2,4,4,6,8,8,10,256,32,256,4,1,4,4,8,8);
  editprogram: string = 'notepad.exe';
  logfilename: string = 'ucinetlog';
  lognum: integer = 0;
  maxlognum: integer = 5000;
  defaultd: integer = -3;
  defaultw: integer = 0;
  lessthanorequalto = ople;
Var
  error: integer = 0;  {obsolete}
  errorcode: integer = 0;
  errmsg: string = '';
  waserror: boolean = false;
  scratchpath : string = 'C:';
  DefaultDir: string = 'C:\';
  defaultlabelstype: word = 3; {1 is for ucinet iv files; 2 is for long labels; 3 = unicode}
  defaultucversion: integer = 6405;
  fileversionmethod: integer = 0;
  copyright: string = 'Copyright (c) 2002-2026 Analytic Technologies';
  progname: string = '<NONE>';
  programfolder: string = '';
  displaysize: integer = 300;
  pagewidth : integer = 16384;
  prevtime: cardinal = 0;
  intsinglecomparison: tcomparison<tintsingle>;
  singlecomparer: icomparer<single>;

function oktodisplay(nr:integer; nc:integer=-1): boolean; overload;
function oktodisplay(nr,nc,nm:integer): boolean; overload;

Implementation

function oktodisplay(nr:integer; nc:integer=-1): boolean;
begin
  if nc < 0 then nc:= nr;
  result:= nr*nc <= sqr(displaysize);
end;

function oktodisplay(nr,nc,nm:integer): boolean;
begin
  result:= nr*nc*nm <= sqr(displaysize);
end;

Initialization
  singleComparer := TComparer<single>.Default;
  intsinglecomparison:=
    function(const Left, Right: tintsingle): Integer
    begin
      Result := TComparer<single>.Default.Compare(Left.value, Right.value);
    end;

End.



