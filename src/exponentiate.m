/*--- USE THIS AS A TEMPORARY FILE FOR EXPERIMENTAL CODE ---/


/*-------------------------------------------------------------------*/
/*---- The following function is a first attempt at decomposing  ----*/
/*---- a matrix Lie algebra, computing the normalizer, and using ----*/
/*---- it to compute the pseudo-isometries of a tensor that has  ----*/
/*---- a substantial derivation algebra. RETURN TO THIS SOON.    ----*/
/*-------------------------------------------------------------------*/

/*
  Input: a tensor of p-group, G, of p-class 2, having p-central series
            G > Z > 1
  Output:
    (1) The pseudo-isometry group, H, of the alternating bimap of G.
    (2) The group induced by H on G/Z.
    (3) The group induced by H on Z.
    (4) The group of isometries (the subgroup of H inducing 1 on Z).
    (5) The product of the dimensions of G/Z and Z as GF(p)-spaces.
    (6) The group of pseudo-isometries and central automorphisms.
*/

intrinsic ExponentiateDerivations(T::TenSpcElt) -> GrpMat
{ Exponentiates the derivation algebra. }

vprint Autotopism, 2 : "======ExponentiateDerivations===============";

  // get the basic multilinear information for G

  k := BaseRing (T);
  DomT := Domain (T);
  assert #DomT eq 2;
  V := DomT[1];
  d := Dimension (V);
  assert Dimension (DomT[2]) eq d;
  W := Codomain (T);
  e := Dimension (W);
vprint Autotopism, 2 : "[INFO]   Dim(V) =", d;
vprint Autotopism, 2 : "[INFO]   Dim(W) =", e;
vprint Autotopism, 2 : "[INFO]   Dim(Rad) =", Dimension(Radical(T,2));
vprint Autotopism, 2 : "[INFO]   Dim(CoRad) =", Dimension(Coradical(T));
vprint Autotopism, 2 : "---------------------";

  // compute isometries  
  S := SystemOfForms (T);
vprint Autotopism, 2 : "[INFO]   here is the structure of Isom(T):";
  if GetVerbose("Autotopism") gt 0 then
    ISOM := IsometryGroup (S);
  else
    ISOM := IsometryGroup(S : DisplayStructure:=false);
  end if;
vprint Autotopism, 2 : "---------------------";
  
  
  // compute the derivation algebra for T and its restricted action on W
  DerT := DerivationAlgebra (T);
vprint Autotopism, 2 : "[INFO]   Dim(DerT) =", Dimension (DerT);
  DerTW, phi := Induce (DerT, 0);
  UDerTW := sub < MatrixAlgebra (k, e) | [ Matrix (DerTW.i) : 
                          i in [1..Ngens (DerTW)] ] >;
                  
        
    /*----- added by PAB at Oberwolfach: exponentiate what we can from Rad(DerT) -----*/
    J := NilRadical (DerT);
    N := sub < DerT | [ DerT.i * J.j : i in [1..Ngens (DerT)], j in [1..Ngens (J)] ] >;
    basN := Basis (N);
    assert forall { i : i in [1..#basN] | IsNilpotent (basN[i]) };
    UJ := [ ];
    for i in [1..#basN] do
      z := Matrix (basN[i]);
      isit, c := IsNilpotent (z);
      assert isit;
      if c lt Characteristic (k) then
        u := __exp (z);
	      Append (~UJ, u);
      else
        vprint Autotopism, 2 : "nilpotence degree exceeded characteristic";
      end if;
    end for;
    /*---------------------------------------*/
                          
  MDW := RModule (UDerTW);
vprint Autotopism, 2 : "[INFO]   Dim(DerTW) =", Dimension (DerTW);
vprint Autotopism, 2 : "[INFO]   DerTW acting irreducibly on W?", IsIrreducible (MDW);
vprint Autotopism, 2 : "---------------------";
  
  // compute Levi complement of DerT
  isit, Levi := HasLeviSubalgebra (DerT); 
  if isit and Dimension (Levi) gt 0 then
vprint Autotopism, 2 : "[INFO]   Dim(Levi) =", Dimension (Levi); 
    

  LeviWgens := [ Matrix (Levi.i @ phi) : i in [1..Ngens (Levi)] ];
  mLie := MatrixLieAlgebra (k, e);
  LeviW := sub < mLie | [ mLie!LeviWgens[i] : i in [1..#LeviWgens] ] >;
vprint Autotopism, 2 : "[INFO]   Dim(LeviW) =", Dimension (LeviW);
  ULeviW := sub < MatrixAlgebra (k, e) | LeviWgens >;
  MLW := RModule (ULeviW);
vprint Autotopism, 2 : "[INFO]   LeviW acting irreducibly on W?", IsIrreducible (MLW);


  // find simple components
vprint Autotopism, 2 : "     attempting to decompose Levi into simple ideals ...";
  simples := DirectSumDecomposition (Levi); 
vprint Autotopism, 2 : "     ... done!";  
vprint Autotopism, 2 : "=====================";
  else
    vprint Autotopism, 1 : "[WARNING] Der(G) is solvable";
    simples := [ ];
    NIL := [ ];

  end if;

  NIL := [ ];   // collect the nilpotent elements to exponentiate

  for l in [1..#simples] do

  vprint Autotopism, 2 : "  [INFO]   processing summand", l, "(out of",#simples,"simple summands)"; 
    L := simples[l];  
    try 
      sst := SemisimpleType(L);
    catch err
      sst := "Unknown";
    end try;
  vprint Autotopism, 2 : "  [INFO]   Type =", sst;
    n := Dimension (L);
  vprint Autotopism, 2 : "  [INFO]   Dim(L) =", n;
    gensLW := [ ExtractBlock (Basis (L)[i], 2*d+1, 2*d+1, e, e) : 
                         i in [1..n] ];
  
    // make sure L acts non-trivially on W
    if exists { i : i in [1..n] | gensLW[i] ne 0 } then   
      
// gensLW contains a k-basis of the space it spans: find one
// probably don't need this now, since we've reduced to simple case
// J := __ReduceToBasis (gensLW);
// assert #J eq #gensLW;
  
      LW := sub < mLie | [ mLie!(gensLW[i]) : i in [1..#gensLW] ] >;  
 
      // construct nat module for LW and use it to get Chevalley basis
      ULW := sub < MatrixAlgebra (k, e) | gensLW >;
      M := RModule (ULW);
      vprint Autotopism, 2 : "  [INFO]   LW acting on a module of dimension", Dimension (M); 
      
      // TO DO: test irreducibility and induce faithfully on an irreducible submodule.
DerWIrred := false;    
      if IsIrreducible (M) then
      
DerWIrred := true;
      
      vprint Autotopism, 2 : "  [INFO]   LW acts irreducibly";
        // we want to extend this to completely reducible, really,
        // but let's handle the simple case first.
        
        isit, Z, f := IsAbsolutelyIrreducible (M);
        
        if isit then
        vprint Autotopism, 2 : "  [INFO]   LW acts absolutely irreducibly";
          // here we use off-the-shelf function to find Chevalley basis
          vprint Autotopism, 2 : "       attempting to compute Chevalley basis of LW ...";
          X, Y, H := ChevalleyBasis (LW);
          vprint Autotopism, 2 : "       ... done!";
          U := X cat Y;
        vprint Autotopism, 2 : "  [INFO]   ad-nilpotent matrices", #X + #Y;
        vprint Autotopism, 2 : "  [INFO]   Dim(Cartan) =", #H;
          
        else
        
        vprint Autotopism, 2 : "  [INFO]   LW does not act absolutely irreducibly";
          // here we construct the natural rep and find Chevalley basis in there
          mZ := MinimalPolynomial (Z); 
          m := e div f;
          K := ext < k | mZ >;
          Zbas := [ ];
          ms := KMatrixSpace (k, e, e);
          for i in [1..(#gensLW) div f] do
            assert exists (t){ j : j in [1..#gensLW] | 
                                   not gensLW[j] in sub < ms | Zbas > };
            Zbas cat:= [ gensLW[t] * (Z^a) : a in [0..f-1] ];
          end for;
          assert #Zbas eq #gensLW;
          
          BZ := [ (W.1) * Z^a : a in [0..f-1] ];
          for i in [1..m-1] do
            assert exists (t){ j : j in [1..e] | not W.j in sub < W | BZ > };
            BZ cat:= [ (W.t) * Z^a : a in [0..f-1] ];
          end for;    
          WZ := VectorSpaceWithBasis (BZ);

          assert Dimension (WZ) eq e;
          mLieK := MatrixLieAlgebra (K, m);
          B := [ ];
          for i in [1..#Zbas] do
            z := Zbas[i];
            zz := [ ];
            for j in [1..m] do
              w := WZ.(1+(j-1)*f) * z;
              c := Coordinates (WZ, w);
              vec := [ SequenceToElement ([ c[(j-1)*f + t] :
                          t in [1..f] ], K) : j in [1..m] ];
              zz cat:= vec;
            end for;
            Append (~B, Matrix (K, m, m, zz));
          end for; 
          NatLW := sub < mLieK | B >;
        vprint Autotopism, 2 : "  [INFO]   Dim(NatLW) =", Dimension (NatLW);
         vprint Autotopism, 2 :  "       attempting to compute Chevalley basis of LW ...";
          XK, YK, HK := ChevalleyBasis (NatLW);
          vprint Autotopism, 2 : "       ... done!";
          vprint Autotopism, 2 : "  [INFO]   ad-nilpotent matrices", #XK + #YK;
          vprint Autotopism, 2 : "  [INFO]   Dim(Cartan) =", #HK;
          UK := XK cat YK;
         
          // pull back into LW
          MS := KMatrixSpace (K, m, m);
          MS := KMatrixSpaceWithBasis ([MS!B[(i-1)*f+1] : i in [1..#B div f]]);     
          ms := KMatrixSpaceWithBasis ([ms!(Zbas[i]) : i in [1..#Zbas]]);
          Usmall := [ __preimage (ms, MS, u) : u in UK ];
          U := [ LW!u : u in Usmall ];
          for i in [1..f-1] do
            Ui := [ LW!(u * Z^i) : u in Usmall ];
            U cat:= Ui;
          end for;

        end if;
    
      else
    
DerWIrred := false;
vprint Autotopism, 1 : "  [WARNING]   LW acts reducibly on W";

      /* 
         Added by PAB in Oberwolfach. 
         I've hacked this for now, but we should restrict to a 
         submodule upon which LW acts faithfully and irreducibly.
         Do this up top, actually.
      */  
try
vprint Autotopism, 1 : "\t[INFO] Attempting to compute a Chevalley Basis";
      X, Y, H := ChevalleyBasis (LW);
catch err
	vprint Autotopism, 1 : "  [WARNING]   Magma did not recognize the simple Lie algebra";
gens := [ DiagonalJoin (ISOM.i, Identity (MatrixAlgebra (k, e))) : 
                  i in [1..Ngens (ISOM)] ];
H := sub < GL (d + e, k) | gens >;
return H;
end try;

      U := X cat Y;
      vprint Autotopism, 2 : "  [INFO]   ad-nilpotent matrices", #X + #Y;
      vprint Autotopism, 2 : "  [INFO]   Dim(Cartan) =", #H;
  
      
    
      end if;  

      // pull U back into L and exponentiate
      ms := KMatrixSpace (k, e, e);
      ms := KMatrixSpaceWithBasis ([ ms!(gensLW[j]) : j in [1..#gensLW] ]);
      for u in U do
        c := Coordinates (ms, ms!u);
        n := &+ [ c[i] * Basis (L)[i] : i in [1..#c] ];
        assert IsNilpotent (n);
        Append (~NIL, n);
      end for;
    
    else
      vprint Autotopism, 2 : "  [INFO]   Summand acts trivially";
    end if;   // check simple factor is acting non-trivially on L

  vprint Autotopism, 2 : "---------------------";
  
  end for;   // simple factor loop
  
  // exponentiate the nilpotent elements to get pseudo-isometries
  gens := [ __exp (n) : n in NIL ]; 
  
  /* added by PAB in Oberwolfach ... add in the unipotent elements */
  gens cat:= UJ;
  
  Vgens := [ ExtractBlock (gens[i], 1, 1, d, d) : i in [1..#gens] ];
  Wgens := [ ExtractBlock (gens[i], 1+2*d, 1+2*d, e, e) : i in [1..#gens] ];
  
  // construct the group of pseudo-isometries acting on W
  HW := sub < GL (e, k) | Wgens >;
  
  VWgens := [ DiagonalJoin (Vgens[i], Wgens[i]) : i in [1..#gens] ];
  // throw in isometries to Vgens and VWgens
  for i in [1..Ngens (ISOM)] do
    Append (~Vgens, Matrix (ISOM.i));
    Append (~VWgens, DiagonalJoin (ISOM.i, Identity (MatrixAlgebra (k, e))));
  end for;
  
  // construct the group of pseudo-isometries acting on V 
  HV := sub < GL (d, k) | Vgens >; 
   
  // construct the full group of pseudo-isometries. 
  H := sub < GL (d + e , k) | VWgens >; 

  // construct put the pseudo-isometries together with central.
  A := sub< GL(d+e, k) | VWgens cat __CentralAutos(#k, d, e) >;
  
return H;

end intrinsic;

/*
  ----------
  IMPORTANT: 
  ----------
  The pseudo-isometry group is still missing generators.
  We have constructed a group H such that HW is sandwiched as follows:
  
  Q < HW < M < GL(W)
  
  where Q is a quasisimple group of Lie type, and M is a maximal subgroup
  of GL(W) of (C8) type.
  
  Conjecture: HW is in fact as large as it can be, i.e. it should be M.
  
  In any case we only need to build generators for M/Q and test whether they 
  lift to pseudo-isometries using the isometry test of Ivanyos-Qiao.
  
  The scalars should all occur; the square group can readily be
  inserted as we process each simple factor.
  
  ---------------------------------------
  SOME OTHER THINGS THAT NEED TO BE DONE:
  ---------------------------------------
  
  (1) Reduce to a fully-nondegenerate bimap in a systematic way.
  
  (2) Write bimap over the centroid when appropriate.
  
  (3) Induce simple ideals of Lie algebra induced by Levi on W on
      proper irreducible submodules, when this is possible, and work there.
      
  (4) Put in the other possible generators for the group induced by Aut(G)
      on W, and use Ivanyos-Qiao to see which ones lift to pseudo-isometries.
*/

