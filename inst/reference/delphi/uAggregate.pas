unit uAggregate;
//deprecated
interface
uses
  utsmat, utivec, utstrvec, utunivariate;

procedure aggbygroups(ag,m:tsmat; rp,cp:tivec; nbr,nbc:integer; meas:integer=s_mean; diagok:boolean=false); overload;
procedure aggbygroups(agsum,agmean,agsd,m:tsmat; rp,cp:tivec; nbr,nbc:integer; diagok:boolean=false); overload;

implementation

procedure aggbygroups(ag,m:tsmat; rp,cp:tivec; nbr,nbc:integer; meas:integer=s_mean; diagok:boolean=false);
//assumes rp and cp deliver values from 1 to nbr, nbc
var
  i,j: integer;
  s: array of array of tunivariate;
begin try
  if m.is2mode then diagok:= true;
  setlength(s,nbr+1,nbc+1);
  for i:= 1 to nbr do 
    for j:= 1 to nbc do 
      s[i,j]:= tunivariate.create;
  for i:= 1 to m.nr do  
    for j:= 1 to m.nc do if (i<>j) or diagok then 
      s[rp[i],cp[j]].addcase(m.cell[i,j]);
  ag.allocate(nbr,nbc,-1,true,false);
  for i:= 1 to nbr do 
    for j:= 1 to nbc do 
      ag[i,j]:= s[i,j].asArray[meas];      
  finally       
    for i:= 1 to nbr do 
      for j:= 1 to nbc do
        s[i,j].free; 
    s:= nil;
  end;
end;

procedure aggbygroups(agsum,agmean,agsd,m:tsmat; rp,cp:tivec; nbr,nbc:integer; diagok:boolean=false); overload;
//assumes rp and cp deliver values from 1 to nbr, nbc
var
  i,j: integer;
  s: array of array of tsimpleuni;
begin try
  if m.is2mode then diagok:= true;
  setlength(s,nbr+1,nbc+1);
  for i:= 1 to nbr do
    for j:= 1 to nbc do
      s[i,j]:= tsimpleuni.create;
  for i:= 1 to m.nr do
    for j:= 1 to m.nc do if (i<>j) or diagok then
      s[rp[i],cp[j]].addcase(m.cell[i,j]);
  agsum.allocate(nbr,nbc,-1,true,false);
  agmean.allocate(nbr,nbc,-1,true,false);
  agsd.allocate(nbr,nbc,-1,true,false);
  for i:= 1 to nbr do
    for j:= 1 to nbc do begin
      agsum.cell[i,j]:= s[i,j].sum;
      agmean.cell[i,j]:= s[i,j].mean;
      agsd.cell[i,j]:= s[i,j].sd;
      end;
  finally
    for i:= 1 to nbr do
      for j:= 1 to nbc do
        s[i,j].free;
    s:= nil;
  end;
end;

end.
