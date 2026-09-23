unit uegocomposition;
(*
  Egonet alter composition (categorical).
  For each ego, tabulates the frequency and (tie-strength weighted) proportion
  of its alters falling into each category of a categorical attribute, plus
  Blau heterogeneity and IQV. Extracted from uc_EgoNetComposition so the GUI
  dialog and the CLI share one implementation.
*)
interface
uses
  math, ucommon, utsmatds, utsvec, utfrequencies5;

const
  ecBoth  = 0;  //both incoming and outgoing ties (max symmetrize)
  ecOut   = 1;  //outgoing ties only
  ecIn    = 2;  //incoming ties only (transpose)
  ecRecip = 3;  //reciprocated ties only (min symmetrize)

//net is modified in place according to tietype (symmetrized/transposed).
//attr holds each node's category value; attrname labels the first output column.
//meas gets one row per node: own value, f<cat>..., p<cat>..., Heterogeneity, IQV.
//tab gets the overall frequency table of attr categories.
function egonetaltercomposition(net:tsmatds; tietype:integer; attr:tsvec;
  ignoreown:boolean; attrname:string; meas,tab:tsmatds; var err:string): boolean;

implementation
{---------------------------------------------------------------------------}
function massagematrix(net:tsmatds; tietype:integer; var err:string): boolean;
var
  i,j: integer;
begin
  result:= false;
  if net.nr <> net.nc then begin
    err:= 'Network matrix must be square.';
    exit;
    end;
  case tietype of
    ecBoth:
      for i:= 2 to net.nr do for j:= 1 to i-1 do begin
        net.cell[i,j]:= max(net.cell[i,j],net.cell[j,i]);
        net.cell[j,i]:= net.cell[i,j];
        end;
    ecOut: ;
    ecIn:
      if not net.transposesquarematrix then begin
        err:= 'Unable to transpose network matrix.';
        exit;
        end;
    ecRecip:
      for i:= 2 to net.nr do for j:= 1 to i-1 do begin
        net.cell[i,j]:= min(net.cell[i,j],net.cell[j,i]);
        net.cell[j,i]:= net.cell[i,j];
        end;
    end;
  result:= true;
end;
{---------------------------------------------------------------------------}
function egonetaltercomposition(net:tsmatds; tietype:integer; attr:tsvec;
  ignoreown:boolean; attrname:string; meas,tab:tsmatds; var err:string): boolean;
var
  s: tfrequencies<single>;
  i,j,phet,piqv: integer;
  het,iqv: double;
begin
  result:= false;
  err:= '';
  s:= tfrequencies<single>.create;
  try
    if not massagematrix(net,tietype,err) then exit;
    if attr.n <> net.nr then begin
      err:= 'Attribute vector must be same size as matrix rows.';
      exit;
      end;
    s.clear;
    for j:= 1 to attr.n do if attr.cell[j] < na then
      s.addcase(attr.cell[j]);
    s.maketable(tab,skey);
    if not meas.allocsize(net.nr,2*s.n+3) then begin
      err:= 'Unable to allocate output matrix.';
      exit;
      end;
    phet:= 2*s.n + 2;
    piqv:= 2*s.n + 3;
    if meas.cdvn.allocsize(meas.nc) then begin
      meas.cdvn.sput(1,attrname);
      for j:= 1 to s.n do begin
        meas.cdvn.sput(j+1,'f'+s.getdvn(j));
        meas.cdvn.sput(j+1+s.n,'p'+s.getdvn(j));
        end;
      meas.cdvn.sput(phet,'Heterogeneity');
      meas.cdvn.sput(piqv,'IQV');
      end;
    s.appendifnew:= false; //ensure that each ego has same categories
    for i:= 1 to net.nr do begin
      s.clearfreq; //don't clear items, just frequencies
      for j:= 1 to net.nc do
        if (i<>j) and (net.cell[i,j] > 0) and (net.cell[i,j] < na) and (attr.cell[j] < na) then
          if not (ignoreown and attr.equal(i,j))
            then s.addcase(attr.cell[j],net.cell[i,j]);
      meas.cell[i,1]:= attr.cell[i];
      for j:= 1 to s.n do begin
        meas.cell[i,j+1]:= s.freq[j];
        meas.cell[i,j+1+s.n]:= s.prop[j];
        end;
      s.getheterogeneity(het,iqv);
      meas.cell[i,phet]:= het;
      meas.cell[i,piqv]:= iqv;
      end;
    meas.rdvn.copy(net.rdvn);
    meas.title:= 'Ego Net Composition';
    result:= true;
  finally
    s.free;
    end;
end;
{---------------------------------------------------------------------------}
end.
