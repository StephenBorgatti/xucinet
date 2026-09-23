unit utminres;
(* Least-squares estimation of the continuous (multiplicative) core/periphery
   model of Borgatti & Everett (1999):  a[i,j] ~ c[i]*c[j].

   When diagvalid is false (the default), the diagonal is treated as free,
   MINRES/principal-axis style: starting from the principal singular vector of
   the symmetrized data, the diagonal is replaced by the communalities c[i]^2
   and the SVD re-run until the loadings stabilize (cf. Comrey 1962).
   When diagvalid is true, a single rank-1 SVD of the data as given is used,
   so c is the principal eigenvector scaled by sqrt of the eigenvalue.

   fit is the Pearson correlation between c[i]*c[j] and the data, excluding
   the diagonal unless diagvalid.

   Intended to eventually replace the G1 minres implementations
   (uminres.pas, ucomrey.pas). *)

interface
uses
  ucommon, utsmat, utevec, utsvec, ug2svd, umatrixtools, utcorr;

type
  tminres = class
    n: integer;
    maxit: integer;         // max communality iterations (default 100)
    tol: double;            // convergence: max abs change in loadings (default 1e-5)
    diagvalid: boolean;     // true: diagonal treated as data (no communality iteration)
    iterations: integer;
    converged: boolean;
    fit: double;
    loadings: tsvec;        // c in data scale, so c[i]*c[j] approximates a[i,j]
    constructor create; virtual;
    destructor destroy; override;
    procedure solve(a:tsmat);           // a is not modified; symmetrized (avg) internally
    procedure getcoreness(c:tsvec; absolute:boolean=false);  // loadings normalized to unit ssq
  end;

implementation

{ tminres }

constructor tminres.create;
begin
  loadings:= tsvec.create;
  maxit:= 100;
  tol:= 0.00001;
  diagvalid:= false;
end;

destructor tminres.destroy;
begin
  loadings.Free;
  inherited;
end;

procedure tminres.solve(a: tsmat);
var
  sym,w,v: tsmat;
  d: tevec;
  prev: tsvec;
  r: tcorr;
  i,j,it,rank: integer;
  scale,change,diff: double;

  procedure extractloadings;
  // after svd+svdsort, w holds u; loadings := u1 * sqrt(d1)
  var
    i,negs: integer;
  begin
    if d.cell[1] > 0 then scale:= sqrt(d.cell[1]) else scale:= 0;
    negs:= 0;
    for i:= 1 to n do begin
      loadings.cell[i]:= w.cell[i,1]*scale;
      if loadings.cell[i] < 0 then inc(negs);
      end;
    if negs > n div 2 then
      for i:= 1 to n do
        loadings.cell[i]:= -loadings.cell[i];
  end;

begin
  n:= a.n;
  sym:= tsmat.create; w:= tsmat.create; v:= tsmat.create;
  d:= tevec.create; prev:= tsvec.create; r:= tcorr.create;
  try
    loadings.allocate(n,true,false);
    loadings.name:= 'Coreness';
    prev.allocate(n,true,false);
    v.allocate(n,n,1,true,true);
    d.allocate(n,true,true);
    sym.copy(a);
    for i:= 1 to n do
      for j:= 1 to n do
        if sym.isna(i,j) then sym.cell[i,j]:= 0;
    sym.symmetrize(sy_avg);

    iterations:= 0;
    converged:= false;
    // first pass uses the data's own diagonal as the initial communality estimate
    w.copy(sym);
    svd(w,v,d,rank);
    svdsort(w,v,d);
    extractloadings;
    if diagvalid or (scale = 0)
      then converged:= true
      else for it:= 1 to maxit do begin
        iterations:= it;
        for i:= 1 to n do prev.cell[i]:= loadings.cell[i];
        w.copy(sym);
        for i:= 1 to n do w.cell[i,i]:= sqr(loadings.cell[i]);
        svd(w,v,d,rank);
        svdsort(w,v,d);
        extractloadings;
        change:= 0;
        for i:= 1 to n do begin
          diff:= abs(loadings.cell[i] - prev.cell[i]);
          if diff > change then change:= diff;
          end;
        if change < tol then begin
          converged:= true;
          break;
          end;
        end;

    for i:= 1 to n do
      for j:= 1 to n do
        if diagvalid or (i <> j) then
          r.addcase(loadings.cell[i]*loadings.cell[j],sym.cell[i,j]);
    r.calc;
    fit:= r.corr;
    if fit >= na then fit:= 0;
  finally
    sym.Free; w.Free; v.Free; d.Free; prev.Free; r.Free;
  end;
end;

procedure tminres.getcoreness(c: tsvec; absolute:boolean=false);
var
  i: integer;
  total: double;
begin
  c.allocate(n,true,false);
  c.name:= 'Coreness';
  total:= 0;
  for i:= 1 to n do total:= total + sqr(loadings.cell[i]);
  if total > 0 then total:= sqrt(total);
  for i:= 1 to n do
    if total > 0
      then c.cell[i]:= loadings.cell[i]/total
      else c.cell[i]:= 0;
  if absolute then
    for i:= 1 to n do c.cell[i]:= abs(c.cell[i]);
end;

end.
