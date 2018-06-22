  /*
    -----------------------------------------------------------------
    An implementation based on techniques developed in     
    Groups acting on densors, Brooksbank, Maglione, Wilson (preprint)
    The overarching goals are automorphism group functions and
    isomorphism tests for certain p-groups.
    -----------------------------------------------------------------
  */
 
/* -------------------- subroutines ------------------ */
 
__exp := function (z)
	// Convert to associative product if necessary.
	if ISA (Type(z), AlgMatLieElt) then 
		P := Parent (z);
		MA := MatrixAlgebra (BaseRing (P), Degree (P));
		z := MA!z;
	end if;
	u := z^0;
	i := 1;
	v := z;
	while not (v eq 0) do
		u +:= v / Factorial (i);
		i +:= 1;
		v *:= z;
	end while;
return u;
end function;


__preimage := function (ms, MS, y)
    // WHAT DOES IT DO?
    k := BaseRing (ms);
    c := Coordinates (MS, MS!y);
    coords := [];
    for a in c do
         coords cat:= Eltseq (a, k);
    end for;
return &+[ coords[i] * ms.i : i in [1..Ngens (ms)] ];
end function;


__ReduceToBasis := function (X)
    // X contains a basis of the matrix space it spans
    k := BaseRing (Parent (X[1]));
    m := Nrows (X[1]);
    n := Ncols (X[1]);
    ms := KMatrixSpace (k, m , n);
    U := sub < ms | [ ms!(X[i]) : i in [1..#X] ] >;
    d := Dimension (U);
    if d eq #X then
         return [1..d];
    else
         J := [ Min ({ i : i in [1..#X] | X[i] ne 0 }) ];
         j := J[1];
         W := sub < ms | [ ms!(X[j]) : j in J ] >;
         while Dimension (W) lt d do
              j +:= 1;
              x := ms!(X[j]);
              if not x in W then
                   Append (~J, j);
                   W := sub < ms | [ ms!(X[j]) : j in J ] >;
              end if;
         end while;
         return J;
    end if;
end function;


__CentralAutos := function (p, d, e)
    // constructs generators for the central automorphisms
    gens := [];
    I := IdentityMatrix (GF (p), d + e);
    for i in [1..d] do
         for j in [1..e] do
              A := I;
              A[i][d+j] := 1;
              Append (~gens, A);
         end for;
    end for;
    G := GL (d + e, p);
return [ G!A : A in gens ];
end function;
 

/*
    INPUT:
      (1) A, a k-algebra (e.g. Lie or associative) of matrices.
      (2) S, a set of invertible linear transformations of the 
          underlying k-algebra.
    
    OUTPUT: true if, and only  if, L^S = L
*/
NormalizesMatrixAlgebra := function (A, S)  
     k := BaseRing (A);
     n := Degree (A);
     MS := KMatrixSpace (k, n, n);
     X := KMatrixSpaceWithBasis ([ MS!Matrix (x) : x in Basis (A) ]);    
return forall { s : s in S | 
          forall { i : i in [1..Ngens (X)] |
              s^-1 * X.i * s in X
                 }
              };             
end function;


// Convert GrpAuto of a p-class 2 group to a matrix group.
// Returns the restriction of Aut(G) on W along with Aut(G).
AutoToMat := function (A)
     G := A`Group;
     assert pClass (G) eq 2;
     d := Ngens(G); // number of minimal generators
     ord := Factorization (#G);
     e := ord[1][2]-d;
     p := ord[1][1];
     // basis will be G.1, G.2, ..., G.n.
     Over := GL (d+e, p);
     gens := [];
     for a in Generators (A) do
         M := [ Eltseq (G.i @ a) : i in [1..d+e] ];
         Append (~gens, Over!M);
     end for;
     Aut_Mat := sub< Over | gens >;
     Aut_W := sub< GL (e, p) | [ ExtractBlock (x, d+1, d+1, e, e) : x in gens ] >;
return Aut_W, Aut_Mat;
end function;


// Moved from "exponentiate.m" by PAB on 6/5/2018
OuterCentralAutomorphisms := function(P,U)
	T := pCentralTensor(P,1,1);
print "Computing derivations.";
	D := DerivationAlgebra(T);
	H := ExponentiateLieAlgebraSS(D);
	d := Dimension(Domain(T)[1]);
	F := BaseRing(T);
	hreps := [ExtractBlock(h,1,1,d,d) : h in Generators(H)];
	H1 := sub<GL(d,F) | hreps>;
	G := ExtendByNormalizer(H1,U);
	return G;
end function;



/* -------------------- intrinsics ------------------ */

// not sure where this should go, but I could not find it in Magma
intrinsic ElementaryMatrix (K::FldFin, m::RngIntElt, n::RngIntElt, 
                  i::RngIntElt, j::RngIntElt) -> ModMatFldElt
  { The (i,j) elementary m x n matrix over the field K }
  Eij := KMatrixSpace (K, m, n)!0;
  Eij[i][j] := 1;
return Eij;
end intrinsic;


intrinsic ExponentiateLieAlgebraSS (L::AlgMatLie) -> GrpMat
{Return the connected algebraic group of the semisimple Lie algebra of Chevalley type.}
	// require the L be semisimple for now.
     G := GL (Degree (L), BaseRing (L));
	 if Dimension (L) eq 0 then 
	     return sub<G|[]>; 
	 end if;		 
   	 gens := [];
	 Factors := DirectSumDecomposition (L);
	 for M in Factors do
		 vprint Autotopism, 1 : "Computing Chevalley Basis of simple factor by Taylor algorithm.";
		 try
			E,F,H := ChevalleyBasis (M);
			gens cat:= [G!__exp(e) : e in E];
			gens cat:= [G!__exp(f) : f in F];
		 catch e
			// Ignore, Magma only supports some characteristics.
			vprint Autotopism, 1 : e`Object;
			vprint Autotopism, 1 : "Chevalley basis could not be computed for factor, skipping";
		 end try;
	 end for;
return sub<G|gens>;
end intrinsic;

// Josh had this as an intrinsic in "exponentiate.m"
// Transferred here by PAB on 6/5/2018
intrinsic ExtendByNormalizer(H::GrpMat,U::ModTup) -> GrpMat
{}
	vprint Autotopism, 1 : "Computing normalizer of connected component.";
	N := GLNormaliser(H);
	f,NmodH := LMGCosetAction(N,H);
	vprint Autotopism, 1 : "Searching through ", Order(NmodH), " cosets";
	EI := [<i @@ f, ExteriorSquare(i @@ f)> : i in NmodH ];
	V := VectorSpace(BaseRing(H), Binomial(Degree(H),2));
	W := sub<V|U>;
	Stab := { x[1] : x in EI | W^x[2] eq W };
	return sub<N | Generators(H) join Stab>;
end intrinsic;


intrinsic Der (T::TenSpcElt) -> AlgMatLie , LagMatLie , Map
  {A version of DerivationAlgebra that returns the rep on W.}
    D := DerivationAlgebra (T);
    k := BaseRing (D);
    d := Degree (D);
    e := Dimension (Codomain (T));
    gens := [ ExtractBlock (D.i, d-e+1, d-e+1, e, e) : i in [1..Ngens (D)] ];
    DW := sub < MatrixLieAlgebra (k, e) | gens >;
    f := hom < D -> DW | x :-> DW!ExtractBlock (x, d-e+1, d-e+1, e, e) >;
return D, DW, f;
end intrinsic;



/* 
    INPUT:
      (1) L, an irreducible representation of a simple Lie algebra.
      (2) E, the part of a Chevalley basis corresponding to the
          positive fundamental roots of L. In particular, the 
          length of E is the Lie rank r of L.
      (3) F, the opposite fundamental roots.
      
    OUTPUT:
      (1) a transition matrix to a crystal basis.
      (2) a crystal basis data structure, which is a list whose
          members are tuples with the following information:
           * a vector v
           * a label for v: a word in [ F[1] ... F[r] ]
           * labelled pointers to v from previous basis elements
*/ 
intrinsic CrystalBasis (L::AlgMatLie, E::SeqEnum, F::SeqEnum) -> 
              AlgMatElt, SeqEnum
  {Finds a transition matrix to a highest weight basis for L relative to E and F.}
     
     k := BaseRing (L);
     n := Degree (L);
     r := #E;
     
     // find unique highest weight vector corresponding to E
     HW := &meet [ Nullspace (x) : x in E ];
     assert Dimension (HW) eq 1;
     lambda := HW.1;
     
     // spin up the basis using elements of F, keeping track of words as we go
     V := VectorSpace (k, n);
     B := [ V!lambda ];
     A := [* < V!lambda , [ ] , [ ]  > *];
     B_old := B;
     while #B lt n do
          P := { [i, j] : i in [1..#B_old], j in [1..r] |                     
                              B_old[i] * F[j] ne 0 };
          B_new := [ ];
          for p in P do
               b := B_old[p[1]] * F[p[2]];
               if (b * E[p[2]] ne 0) and (b * E[p[2]] in sub < V | B_old[p[1]] >) 
                  and not b in sub < V | B cat B_new > then
                    Append (~B_new, b);   
                    labs := [ [ i , j ] : i in [1..#B] , j in [1..r] | 
                        (B[i] * F[j] ne 0) and (B[i] * F[j] in sub < V | b >) and
                        (b * E[j] ne 0) and (b * E[j] in sub < V | B[i] >)
                        ];
                    labs cat:= [ [ i + #B, j ] : i in [1..#B_new] , j in [1..r] |
                        (B_new[i] * F[j] ne 0) and (B_new[i] * F[j] in sub < V | b >) and
                        (b * E[j] ne 0) and (b * E[j] in sub < V | B_new[i] >)
                        ];
                    w := Append (A[labs[1][1]][2], labs[1][2]);
                    Append (~A, < b , w , labs >);
               end if;
          end for;
          B cat:= B_new;
          B_old := B_new;
     end while;
     
     C := Matrix (B);
     
return C, A;

end intrinsic;



/*
   INPUT:  
      (1) a representation of the semisimple Lie algebra L
          of type A and Lie rank d
      (3) the subset E of a Chevalley basis of L corresponding to
          the positive fundamental roots; we assume these have been
          obtained somehow (e.g. Ryba's algorithms in theory; whatever
          is in Magma in practice).
      (4) the opposite part of F of the Chevalley basis
   
   OUTPUT: the group of similarities of the simple Lie algebra rep, which
           is also the normalizer of L in its ambient group of linear 
           transformations. 
   
*/

intrinsic SimilaritiesOfSimpleLieModule (name::MonStgElt, L::AlgMatLie :
                    E := [ ] , F := [ ] 
                                        ) -> GrpMat
  { Construct the group of similarites of the given representation.}

     k := BaseRing (L);
     r := Rank (GroupOfLieType (name, k));
      /* TO DO---insert graph auto perm for "name" */
     
     G := GL (Degree (L), k);
     /* if we somehow
     if #E eq 0 then
          E, F := ChevalleyBasis (L);
     end if;
     assert #E ge r;
       /* TO DO---check that the first r elements correspond to fundamental roots */
     E := [ E[i] : i in [1..r] ];
     F := [ F[i] : i in [1..r] ];
     C, crys := CrystalBasis (L, E, F);
     
     // compute the connected component of the similarity group by exponentiation
     X := [G!__exp (a) : a in E];
     Y := [G!__exp (a) : a in F];
     gens := X cat Y;
assert NormalizesMatrixAlgebra (L, gens); // sanity check

     // extract the type of L so that we know which autos to try to lift
     graph_autos := [ ];
     if Dimension (L) eq ((r+1)^2 - 1) then
         type := "A";
         Append (~graph_autos, Sym (r)![r + 1 - i : i in [1..r] ]);
     elif Dimension (L) eq (2*r^2 + r) then
         if Degree (Image (StandardRepresentation (LieAlgebra (name, k)))) mod 2 eq 0 then
             type := "C";
         else
             type := "B";
         end if;
     elif Dimension (L) eq (2*r^2 - r) then
         type := "D";
         Append (~graph_autos, Sym (r)!(r-1,r));
         if r eq 4 then
             Append (~graph_autos, Sym (r)!(1,3,4));
         end if;
     else
         type := "other";
     end if;
"name =", name, "    type =", type, "    rank =", r;
   
     // build the diagonal automorphism ... NEED TO ADJUST FOR NON-A TYPES?
     D0 := [ k!1 ];
     xi := PrimitiveElement (k);
     S := [ xi ] cat [ k!1 : i in [1..r] ];
     for i in [2..#crys] do
          word := crys[i][2];  // the word labelling the i-th node 
          Append (~D0, &*[ S[word[j]] / S[1+word[j]] : j in [1..#word] ]);
     end for;
     D0 := DiagonalMatrix (D0);
     D := C^-1 * D0 * C;
assert NormalizesMatrixAlgebra (L, [D]);  // sanity check
     Append (~gens, D);
     
     // build the graph automorphism
     B := [ Vector (C[i]) : i in [1..Nrows (C)] ];

     V := VectorSpaceWithBasis (B);
     gens0 := [ ];
"trying to lift", #graph_autos, "graph auto(s)...";
     for s in graph_autos do
          g0 := [ ];
          for i in [1..#crys] do
               word := crys[i][2];
               gword := [ word[j]^s : j in [1..#word] ];           
               vec := V.1;
               for j in [1..#gword] do  
                    vec := vec * F[gword[j]];
               end for;
               Append (~g0, Coordinates (V, vec));
          end for;
          g0 := Matrix (g0);
          Append (~gens0, g0);
     end for;
     
     for g0 in gens0 do
          if Rank (g0) lt Rank (C) then
               "...graph auto did not lift at all";
          else
               g := C^-1 * G!g0 * C;
               if NormalizesMatrixAlgebra (L, [g]) then
                    Append (~gens, g);
                    "...added a graph auto";
               else
                    "...graph auto did not normalize L";
               end if;
          end if;
     end for;

     Z := [ xi : i in [1..Degree (G)] ];
     Z := G!DiagonalMatrix (Z);
     Append (~gens, Z);

     N := sub < GL (Degree (L), k) | gens >;
    
assert NormalizesMatrixAlgebra (L, [N.i : i in [1..Ngens (N)]]); // final sanity check

return N;

end intrinsic;


/*
   INPUT:  
      (1) a semisimple matrix Lie algebra L, i.e. a semisimple Lie
          algebra faithfully represented on V x W.
      (2) the subset E of a Chevalley basis of L corresponding to
          the positive fundamental roots; we assume these have been
          obtained somehow (e.g. Ryba's algorithms in theory; whatever
          is in Magma in practice).
      (3) the opposite part of F of the Chevalley basis.
      (4) the dimension, d, of V.
   
   OUTPUT: the subgroup of Aut(U) x Aut(V) normalizing L.  
*/

__annihilates := function (J, U)
return forall { i : i in [1..Ngens (J)] | forall { t : t in [1..Ngens (U)] |
          U.t * J.i eq 0 } };
end function;

intrinsic SimilaritiesOfSemisimpleLieModule (L::AlgMatLie, d::RngIntElt :
                E := [ ], F := [ ], H := [ ]) -> GrpMat
{ Construct the group of similarites of the given (completely reducible) representation.}
       
     flag, LL := HasLeviSubalgebra (L);
     require (flag and (L eq LL)) : "L must be a semisimple algebra";
     
     if #E eq 0 then
         E, F, H := ChevalleyBasis (L);
     end if;
                                        
     k := BaseRing (L);
     n := Degree (L);
     G := GL (n, k);
     
     X := VectorSpace (k, n);
     V := sub < X | [ X.i : i in [1..d] ] >;
     W := sub < X | [ X.i : i in [d+1..n] ] >;
        
     M := RModule (L);
     
     indM := IndecomposableSummands (M);
"there are", #indM, "indecomposable summands   ", [ Dimension (U) : U in indM ];
     require &+ [ Dimension (S) : S in indM ] eq n : 
        "indecomposable summands do not span the space";
     indX := [ sub < X | [ Vector (M!(S.i)) : i in [1..Dimension (S)] ] > : S in indM ];
     
     // first insert indecomposable summands upon which L acts trivially
     V0subs := < U : U in indX | __annihilates (L, U) and (U subset V) >;
"V0dims:", [ Dimension (U) : U in V0subs ];
     W0subs := < U : U in indX | __annihilates (L, U) and (U subset W) >;
"W0dims", [ Dimension (U) : U in W0subs ];
     mV0 := 0;    mW0 := 0;
     if (#V0subs gt 0) then
        "L acts trivially on some summand of V";
        mV0 +:= &+[ Dimension (U) : U in V0subs ];
     end if;
     if (#W0subs gt 0) then
        "L acts trivially on some summand of W";
        mW0 +:= &+[ Dimension (U) : U in W0subs ];
     end if;
"mV0 =", mV0;
"mW0 =", mW0;
     
     indX := [ U : U in indX | not __annihilates (L, U) ];
"there are", #indX, "indecomposable summands that are not annihilated by L   ",
[ Dimension (U) : U in indX ];
     
// temporary sanity check: all summands lie in V or in W.
assert (#indX + #V0subs + #W0subs) eq #indM;
     
     // for the rest of the indecomposable summands we require the
     // support to be one single minimal ideal
     ideals := IndecomposableSummands (L);
     require forall { U : U in indX | 
                #{ J : J in ideals | not __annihilates (J, U) } le 1 } :
        "each summand of X must be an irreducible module for a minimal ideal of L";
        
     // collect together summands of V and W according to ideal
     Vsubs := < >;    Vdims := < >;
     Wsubs := < >;    Wdims := < >;
     for i in [1..#ideals] do
         J := ideals[i];
         mJV := [ ];   mJW := [ ];
         for U in indX do
             if not __annihilates (J, U) then
                 if U subset V then
                     Append (~Vsubs, U);
                     Append (~mJV, Dimension (U));
                 else
                     assert U subset W;   // again, all summands lie in V or W
                     Append (~Wsubs, U);
                     Append (~mJW, Dimension (U));
                 end if;
             end if;
         end for;
         Append (~Vdims, mJV);
         Append (~Wdims, mJW);
     end for;
"Vdims =", Vdims;
"Wdims =", Wdims;
          
     C := Matrix (
                  (&cat [ Basis (U) : U in Vsubs ]) cat
                  (&cat [ Basis (U) : U in V0subs ]) cat
                  (&cat [ Basis (U) : U in Wsubs ]) cat
                  (&cat [ Basis (U) : U in W0subs ])  
                );
     
     LL := sub < Generic (L) | [ C * Matrix (L.i) * C^-1 : i in [1..Ngens (L)] ] >;
     // start with generators for the centralizer of LL
     ModV := RModule (sub< MatrixAlgebra (k, d) | [ ExtractBlock (LL.i, 1, 1, d, d) :
               i in [1..Ngens (LL)] ] >);
"dim(ModV) =", Dimension (ModV);
     CentV := EndomorphismAlgebra (ModV);
     isit, CVtimes := UnitGroup (CentV); assert isit;
     ModW := RModule (sub< MatrixAlgebra (k, n-d) | 
              [ ExtractBlock (LL.i, d+1, d+1, n-d, n-d) : i in [1..Ngens (LL)] ] >);
"dim(ModW) =", Dimension (ModW);
     CentW := EndomorphismAlgebra (ModW);
     isit, CWtimes := UnitGroup (CentW); assert isit;
     Cent := DirectProduct (CVtimes, CWtimes);
"the centraliser of L in GL(V) x GL(W) has order", #Cent;
     gens := [ Cent.i : i in [1..Ngens (Cent)] ];
     
     II := [ sub < Generic (J) | [ C * Matrix (J.i) *C^-1 : i in [1..Ngens (J)] ] > :
                     J in ideals ];
     EE := [ C * Matrix (E[i]) * C^-1 : i in [1..#E] ];
     FF := [ C * Matrix (F[i]) * C^-1 : i in [1..#F] ];
     // exponentiate what we can
     gens cat:= [ G!__exp(e) : e in EE ] cat [ G!__exp(f) : f in FF ];
"after adding connected component, the normalizer has order", #sub<G|gens>;
                     
     // try to lift diagonal and graph automorphisms for each minimal ideal  
     posV := 1;
     posW := d + 1;
     for i in [1..#II] do
"i =", i;
          Ji := II[i];
          ti := SemisimpleType (Ji);
assert #ti eq 2;    // assuming the rank is at most 9!!
"ti =", ti;

          EEi := [ e : e in EE | Generic (Ji)!e in Ji ];
          FFi := [ f : f in FF | Generic (Ji)!f in Ji ];
          
          delta := Identity (MatrixAlgebra (k, n));  // diagonal auto
              xi := PrimitiveElement (k);
              ri := StringToInteger (ti[2]);
              Si := [ xi ] cat [ k!1 : i in [1..ri] ];
          gamma := Identity (MatrixAlgebra (k, n));  // graph auto
              GAi := [ ];
              if (ti[1] eq "A") and (ri ge 2) then
                  Append (~GAi, Sym (ri)![ri + 1 - i : i in [1..ri] ]);
              elif (ti[1] eq "D") then
                  Append (~GAi, Sym (ri)!(ri-1,ri));
                  if (ri eq 4) then
                      Append (~GAi, Sym (ri)!(1,3,4));
                  end if;
              end if;
"GAi =", GAi;
          
          // first handle the summands in V
          for s in [1..#Vdims[i]] do
              EEis := [ ExtractBlock (EEi[j], posV, posV, Vdims[i][s], Vdims[i][s]) :
                         j in [1..#EEi] ];
              FFis := [ ExtractBlock (FFi[j], posV, posV, Vdims[i][s], Vdims[i][s]) :
                         j in [1..#FFi] ];
              Jis := sub < MatrixLieAlgebra (k, Vdims[i][s]) |
                      [ ExtractBlock (Ji.j, posV, posV, Vdims[i][s], Vdims[i][s]) :
                         j in [1..Ngens (Ji)] ] >;
assert IsIrreducible (RModule (Jis));
              Cis, crys := CrystalBasis (Jis, 
                          [EEis[x] : x in [1..ri]], [FFis[x] : x in [1..ri]]
                                        );
              
              // lift diagonal auto
              D0 := [ k!1 ];
              for a in [2..#crys] do
                  word := crys[a][2];  // the word labelling the i-th node 
                  Append (~D0, &*[ Si[word[j]] / Si[1+word[j]] : j in [1..#word] ]);
              end for;
              D0 := DiagonalMatrix (D0);
              Dis := Cis^-1 * D0 * Cis;
assert NormalizesMatrixAlgebra (Jis, [Dis]);  // sanity check
              InsertBlock (~delta, Dis, posV, posV);
              
              // lift graph auto
              Bis := [ Vector (Cis[a]) : a in [1..Nrows (Cis)] ];
              Vis := VectorSpaceWithBasis (Bis);
              for s in GAi do
                  g0 := [ ];
                  for a in [1..#crys] do
                      word := crys[a][2];
                      gword := [ word[j]^s : j in [1..#word] ];           
                      vec := Vis.1;
                      for j in [1..#gword] do  
                          vec := vec * FFis[gword[j]];
                      end for;
                      Append (~g0, Coordinates (Vis, vec));
                  end for;
                  g0 := Matrix (g0);
                  if Rank (g0) eq Rank (Cis) then
                      g := Cis^-1 * GL (Nrows (g0), k)!g0 * Cis;
                      if NormalizesMatrixAlgebra (Jis, [g]) then
                          InsertBlock (~gamma, Dis, posV, posV);
                      else
"   (graph auto did not lift to summand)"; 
                      end if;
                  else
"   (graph auto did not lift to summand)"; 
                  end if;
              end for;
              
              posV +:= Vdims[i][s];
              
          end for;
          
          // next handle the summands in W
          for s in [1..#Wdims[i]] do
              EEis := [ ExtractBlock (EEi[j], posW, posW, Wdims[i][s], Wdims[i][s]) :
                         j in [1..#EEi] ];
              FFis := [ ExtractBlock (FFi[j], posW, posW, Wdims[i][s], Wdims[i][s]) :
                         j in [1..#FFi] ];
              Jis := sub < MatrixLieAlgebra (k, Wdims[i][s]) |
                      [ ExtractBlock (Ji.j, posW, posW, Wdims[i][s], Wdims[i][s]) :
                         j in [1..Ngens (Ji)] ] >;
assert IsIrreducible (RModule (Jis));
              Cis, crys := CrystalBasis (Jis, 
                          [EEis[x] : x in [1..ri]], [FFis[x] : x in [1..ri]]
                                        );
              
              // lift diagonal auto
              D0 := [ k!1 ];
              for a in [2..#crys] do
                  word := crys[a][2];  // the word labelling the i-th node 
                  Append (~D0, &*[ Si[word[j]] / Si[1+word[j]] : j in [1..#word] ]);
              end for;
              D0 := DiagonalMatrix (D0);
              Dis := Cis^-1 * D0 * Cis;
assert NormalizesMatrixAlgebra (Jis, [Dis]);  // sanity check
              InsertBlock (~delta, Dis, posW, posW);
              
              // lift graph auto
              Bis := [ Vector (Cis[a]) : a in [1..Nrows (Cis)] ];
              Vis := VectorSpaceWithBasis (Bis);
              for s in GAi do
                  g0 := [ ];
                  for a in [1..#crys] do
                      word := crys[a][2];
                      gword := [ word[j]^s : j in [1..#word] ];           
                      vec := Vis.1;
                      for j in [1..#gword] do  
                          vec := vec * FFis[gword[j]];
                      end for;
                      Append (~g0, Coordinates (Vis, vec));
                  end for;
                  g0 := Matrix (g0);
                  if Rank (g0) eq Rank (Cis) then
                      g := Cis^-1 * GL (Nrows (g0), k)!g0 * Cis;
                      if NormalizesMatrixAlgebra (Jis, [g]) then
                          InsertBlock (~gamma, Dis, posV, posV);
                      else
"   (graph auto did not lift to summand)"; 
                      end if;
                  else
"   (graph auto did not lift to summand)"; 
                  end if;
              end for;         
              
              posW +:= Wdims[i][s];
          end for;
          
          if not delta eq Identity (G) then
              Append (~gens, delta);
"added delta =", delta;
"normalizer now has order", #sub<G|gens>;
          end if;
          if not gamma eq Identity (G) then
              Append (~gens, gamma);
"added gamma =", gamma;
"normalizer now has order", #sub<G|gens>;
          end if;
"---------";
     
     end for;
  
     // throw in GL generators for the summands of V and W annihilated by L
// ACTUALLY THESE ALREADY OCCUR IN THE CENTRALIZER OF L, RIGHT?
     if mV0 gt 0 then
"adding generators for GL(nullspace) on V ...";
"posV =", posV;
         mV := &+ [ &+ Vdims[i] : i in [1..#Vdims] | #Vdims[i] gt 0 ];
"mV =", mV;
         GLmV := GL (mV0, k);
         gens cat:= [ InsertBlock (Identity (MatrixAlgebra (k, n)), GLmV.i, posV, posV) :
                        i in [1..Ngens (GLmV)] ];
[ InsertBlock (Identity (MatrixAlgebra (k, n)), GLmV.i, posV, posV) :
                        i in [1..Ngens (GLmV)] ];
     end if;
     
     if mW0 gt 0 then
"adding generators for GL(nullspace) on W ...";
"posW =", posW;
         mW := &+ [ &+ Wdims[i] : i in [1..#Wdims] | #Wdims[i] gt 0 ];  
"mW =", mW;
         GLmW := GL (mW0, k);
         gens cat:= [ InsertBlock (Identity (MatrixAlgebra (k, n)), GLmW.i, posW, posW) :
                        i in [1..Ngens (GLmW)] ];
     end if;
"normalizer now has order", #sub<G|gens>;
      
// NEED Sn ACTIONS ON ISOTYPIC COMPONENTS     
     
     NN := sub < G | gens >; 

assert NormalizesMatrixAlgebra (LL, [NN.i : i in [1..Ngens (NN)]]); // final sanity check 

     // conjugate back
     N := sub < G | [ C^-1 * gens[i] * C : i in [1..#gens] ] >;    
     
     assert NormalizesMatrixAlgebra (L, [N.i : i in [1..Ngens (N)]]); // final sanity check
     
return NN, N;     
end intrinsic;






