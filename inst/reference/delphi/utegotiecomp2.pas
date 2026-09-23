unit utegotiecomp2;
interface
uses
  math,
  ucommon, utsmat, utstrvec;

type
  tegotiecomp = class
    n,nm,imap: integer;
    freq: tsmat;
    rdvn,mdvn: tstrvec;
    constructor create;
    destructor destroy; override;
    procedure addmat(mat:tsmat; whichties:integer; op:integer; cut:single; diagok:boolean=false);
    procedure calc(meas:tsmat);
    procedure clear;
  end;

implementation

procedure tegotiecomp.addmat(mat:tsmat; whichties:integer; op:integer; cut:single; diagok:boolean=false);
{
0 Both in and out
1 Undirected (OR)
2 Outgoing only
3 Incoming only
4 Reciprocated
5 Recip and x(i,j) = x(j,i)
}
var
  i,m: integer;

  procedure addtie(node:integer; value:single=1.0);
  begin
    freq.cell[node,imap]:= freq.cell[node,imap] + value;
  end;

begin
  if imap = 0 then begin
    n:= mat.nr;
    nm:= mat.nm;
    freq.allocate(n,nm,1,true,true);
    rdvn:= mat.rdvn;
    mdvn:= mat.mdvn;
  end;
  inc(imap);
  if imap > freq.allocnc
    then freq.reallocsize(freq.nr,imap);
  case whichties of
    0: for i:= 1 to n do for m:= 1 to n do if (i<>m) or diagok then begin //both
         if mat.istie(i,m,op,cut)
           then addtie(i);
         if mat.istie(m,i,op,cut)
           then addtie(i);
         end;
    1: for i:= 1 to n do for m:= 1 to n do if (i<>m) or diagok then begin //or
         if mat.istie(i,m,op,cut) or mat.istie(m,i,op,cut)
           then addtie(i);
         end;
    2: for i:= 1 to n do for m:= 1 to n do if (i<>m) or diagok then begin  //out
         if mat.istie(i,m,op,cut)
           then addtie(i);
         end;
    3: for i:= 1 to n do for m:= 1 to n do if (i<>m) or diagok then begin  //in
         if mat.istie(m,i,op,cut)
           then addtie(i);
         end;
    4: for i:= 1 to n do for m:= 1 to n do if (i<>m) or diagok then begin  //and
         if mat.istie(i,m,op,cut) and mat.istie(m,i,op,cut)
           then begin
             addtie(i);
             end;
         end;
    5: for i:= 1 to n do for m:= 1 to n do if (i<>m) or diagok then begin  //and
         if mat.istie(i,m,op,cut) and mat.istie(m,i,op,cut) and
         samevalue(mat.cell[i,m],mat.cell[m,i])
           then begin
             addtie(i);
             end;
         end;
    end;
end;

procedure tegotiecomp.calc(meas:tsmat);
//no need pre-allocate meas
var
  i,j: integer;
  tot: single;

  procedure setup;
  var
    j: integer;
  begin
    meas.allocate(n,nm*2+3,1,true,false);
    meas.nafill;
    meas.rdvn.copy(rdvn);
    meas.cdvn.allocate(nm*2 + 3,true,false);
    meas.cdvn.sput(1,'Ties');
    for j:= 1 to nm do begin
      meas.cdvn.sput(j+1,'f'+mdvn.labelget(j));
      meas.cdvn.sput(j+1+nm,'p'+mdvn.labelget(j));
      end;
    meas.cdvn.sput(2*nm+2,'Blau');
    meas.cdvn.sput(2*nm+3,'IQV');
    meas.title:= 'Node-level tie composition measures';
  end;

  procedure gethet(i:integer);
  var
    j: integer;
    sum: double;
  begin
    sum:= 0;
    for j:= 1 to nm do
      sum:= sum + sqr(meas.cell[i,j+1+nm]);
    meas.cell[i,2*nm+2]:= 1.0 - sum;
    if nm > 1
      then meas.cell[i,2*nm+3]:= (1.0-sum)/(1.0 - 1.0/nm)
      else meas.cell[i,2*nm+3]:= bna;
  end;

begin
  setup;
  for i:= 1 to n do begin
    tot:= 0;
    for j:= 1 to nm do
      tot:= tot + freq.cell[i,j];
    meas.cell[i,1]:= tot;
    for j:= 1 to nm do
      meas.cell[i,1+j]:= freq.cell[i,j];
    if tot = 0 then continue;
    for j:= 1 to nm do
      meas.cell[i,j+1+nm]:= freq.cell[i,j]/tot;
    gethet(i)
    end;
end;

procedure tegotiecomp.clear;
begin
  imap:= 0;
  freq.zerofill;
end;

constructor tegotiecomp.create;
begin
  freq:= tsmat.create;
  clear;
end;

destructor tegotiecomp.destroy;
begin
  freq.Free;
  inherited destroy;
end;

end.
