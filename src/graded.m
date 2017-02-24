/* code for graded algebra isomorphism */


/* 
  Given a bimap B : U x V >--> W, compute the algebra consisting of
  the sum of its left–, right–, and mid–nuclei.
*/
__Compute_LMR := function (B)
  L := LeftNucleus (B);   // subalgebra of End(U2) x End(U0)
  M := MidNucleus (B);    // subalgebra of End(U2) x End(U1)
  R := RightNucleus (B);  // subalgebra of End(U1) x End(U0)
  /* embed each as a subalgebra of End(U2) x End(U1) x End(U0) */
  c := Dimension (Domain (B)[1]);
  d := Dimension (Domain (B)[2]);
  e := Dimension (Codomain (B));
  MA := MatrixAlgebra (BaseRing (B), c + d + e);
  gens := [ ];
  for i in [1..Ngens (L)] do
      a := InsertBlock (MA!0, ExtractBlock (L.i, 1, 1, c, c), 1, 1);
      InsertBlock (~a, ExtractBlock (L.i, c+1, c+1, e, e), c+d+1, c+d+1);
      Append (~gens, a);
  end for;
  for j in [1..Ngens (M)] do
      Append (~gens, InsertBlock (MA!0, M.j, 1, 1));
  end for;
  for k in [1..Ngens (R)] do
      Append (~gens, InsertBlock (MA!0, R.k, c+1, c+1));
  end for;
return sub < MA | gens >;  
end function;

// Q for James: how to impose involution on LMR to view it as a *-algebra.

// Q for James: need to talk again about the role of "global adjoints".


/*
  Given a (full) bimap B : U x V >--> W, and a pair of linear 
  automorphisms f, g of U, V, respectively, compute the linear auto  of W induced 
  by the pair, or false if they do not factor through the tensor product.
*/
__Induce_Map := function (B, pair)

  U := Domain (B)[1];
  V := Domain (B)[2];
  W := Codomain (B);
  f := pair[1];
  g := pair[2];
  Bmat := Matrix ([ < U.i , V.j > @ B : 
                        i in [1..Dimension (U)], j in [1..Dimension (V)] ]);
  K := Nullspace (Bmat);
  f_ten_g := TensorProduct (f, g);
  
  if (K * f_ten_g subset K) then
      // find a list of dim(W) pairs (u,v) such that the <u,v> @ B are a basis for W.
      i := 1; j := 1; L := [ ]; LW := sub < W | W!0 >;
      repeat
          w := < U.i , V.j > @ B;
          if not w in LW then
              Append (~L, < U.i , V.j >);
              LW := sub < W | [ LW.k : k in [1..Ngens (LW)] ] cat [ w ] >;
          end if;
          if Dimension (LW) lt Dimension (W) then
              if (j lt Dimension (V)) then
                  j +:= 1;
              elif (i lt Dimension (U)) then
                  i +:= 1;
                  j := 1;
              else
                  error "B seems not to be full";
              end if;
          end if;
      until LW eq W;
      // change-of-basis matrix from the given basis of W to the computed one.
      COB := Matrix ([ LW.k : k in [1..Ngens (LW)] ]);
      // compute the matrix induced on W by <f,g> relative to the new basis
      hh := Matrix ([ < L[k][1] * f , L[k][2] * g > @ B : k in [1..#L] ]);
      // write it relative to the given basis
      h := COB^-1 * hh * COB;
      return true, GL (Dimension (W), BaseRing (W))!h;
      
  else
  
      return false, _;
      
  end if;
  
end function;


/*
  Given a graded algebra A, and an autotopism <Phi_1, Phi_s, Phi_(s+1)> of
  A_1 x A_s >--> A_(s+1), decide whether it extends to a full graded
  algebra automorphism of A.
*/
__Extend := function  (maps, prods)
  
  t := 1;
  
  while (t lt #maps) do
  
      t +:= 1;
      
      // determine, for each pair of existing maps on products in component:
      // (a) if the pair factors through the appropriate tensor;
      // (b) the induced matrix if it does do;
      // (c) that this equals maps[i] if maps[i] is already a GrpMatElt
      
      for i in [1..Ceiling ((t-1) / 2)] do
          j := t - i;
          f := maps[i];
          g := maps[j];
          // make sure they have been assigned matrices
          assert (Type (f) eq GrpMatElt) and (Type (g) eq GrpMatElt);
          // extract the relevant bimap
          assert exists (k){ l : l in [1..#prods] | prods[l][1] eq <[i],[j]> };
          B := prods[k][2];
          // induce map on V[t]
          isit, h := __Induce_Map (B, <f, g>);
          if not isit then   // <f,g> does not factor through the tensor
              return false, _;
          end if;
          // if maps[t] already exists, make sure it equals h
          
          // Q for James: this is one place where I'm unclear about the 
          // "fullness" of the various bimaps associated with A.
          
          if Type (maps[t]) eq GrpMat then
              if maps[t] ne h then
                  return false, _;
              end if;
          end if;
          maps[t] := h;
      end for; 
          
  end while;
  
return true, maps;

end function;


// no function of this name currently in the distributed version of Magma. 

intrinsic AutomorphismGroup (L::AlgLie) -> GrpMat

  {Compute the group of (graded) automorphisms of the Lie algebra L.}
  
  components := HomogeneousComponents (L);
  products := GradedProducts (L);
  d := &+ [ Dimension (U) : U in components ];
  
  // find best s
  dims := [ ];
  for i in [1..#components-1] do
      assert exists (k){ l : l in [1..#products] | products[l][1] eq <[1],[i]> };
      B := products[k][2];
      // rough count for the time being ...
      Append (~dims, Dimension (__Compute_LMR (B)));
  end for;
  md := Minimum (dims);
  assert exists (s){ i : i in [1..#dims] | dims[i] eq md };
  
  // initialize using the autotopism group of this product
  assert exists (k){ l : l in [1..#products] | products[l][1] eq <[1],[s]> };
  B := products[k][2];
  dimU := Dimension (Domain (B)[1]);
  dimV := Dimension (Domain (B)[2]);
  dimW := Dimension (Codomain (B));
  U := AutotopismGroup (B);
  L := sub < Generic (U) | Identity (Generic (U)) >;
  T := [ Identity (Generic (U)) ];
  G := sub < GL (d, BaseRing (L)) | Identity (GL (d, BaseRing (L))) >;
  
  INDEX := LMGOrder (U) div LMGOrder (L);
  done := false;
  
  // search exhaustively through U
  while (not done) do
  
  // probably insert some exhaustive search limit beyond which we proceed at random
   
"computing transversal for INDEX =", INDEX, "   ( |U| =", #U, "   |L| =", #L,")";          
          tran, f := Transversal (U, L);
"done";
          assert tran[1] eq Identity (U);
          i := 1;
          stop := false;
          while (i lt #tran) and (not stop) do
              i +:= 1;
              Phi := tran[i];
              // see if Phi extends ...
              maps := [* 0 : i in [1..#components] *];
              maps[1] := GL (dimU, BaseRing (L))!ExtractBlock (Phi, 1, 1, dimU, dimU);
              maps[s] := GL (dimV, BaseRing (L))!ExtractBlock (Phi, dimU+1, dimU+1, dimV, dimV);
              maps[s+1] := GL (dimW, BaseRing (L))!ExtractBlock (Phi, dimU+dimV+1, 
                                                     dimU+dimV+1, dimW, dimW);
              flag, maps := __Extend (maps, products);
              if flag then
                  maps := < maps[i] : i in [1..#maps] >;
                  G := sub < Generic (G) | [ G.i : i in [1..Ngens (G)] ] cat
                                     [ Generic (G)!DiagonalJoin (maps) ] >;
                  L := sub < Generic (L) | [ L.j : j in [1..Ngens (L)] ] cat [ Phi ] >;
                  stop := true;
              end if;
          end while;
          
          if not stop then
              assert i eq #tran;
              done := true;
          end if;
               
  end while;
  
  // check that we have graded automorphisms of L (is it as easy as this)?
  assert forall { i : i in [1..Ngens (G)] |
                  forall { s : s in [1..Ngens (L)-1] |
                     forall { t : t in [s+1..Ngens (L)] |
                        (L.s * G.i) * (L.t * G.i) eq (L.s * L.t) * G.i
                            }
                          }
                };
  
return G;

end intrinsic;





// a function with this name exists for Lie algebras in the distributed version of Magma.
/*
intrinsic IsIsomorphic (L1::AlgLie, L2::AlgLie) -> BoolElt, Map

  {Decide if there is a (graded) isomorphism from Lie algebra L1 to Lie algebra L2.}
  
return true, _;

end intrinsic;
*/

/*
// old exhaustive search ...
  while (LMGOrder (U) div LMGOrder (L) gt #T) do
      // select a new element 
      assert exists (Phi){ u : u in U | not exists { t : t in T |
                                         u in { l * t : l in L } } };
      maps := [* 0 : i in [1..#components] *];
      maps[1] := GL (dimU, BaseRing (L))!ExtractBlock (Phi, 1, 1, dimU, dimU);
      maps[s] := GL (dimV, BaseRing (L))!ExtractBlock (Phi, dimU+1, dimU+1, dimV, dimV);
      maps[s+1] := GL (dimW, BaseRing (L))!ExtractBlock (Phi, dimU+dimV+1, 
                                                     dimU+dimV+1, dimW, dimW);
      // try to extend
      flag, maps := __Extend (maps, products);
      if flag then   // add the generator to L and G
          maps := < maps[i] : i in [1..#maps] >;
          G := sub < Generic (G) | [ G.i : i in [1..Ngens (G)] ] cat
                                     [ Generic (G)!DiagonalJoin (maps) ] >;
          L := sub < Generic (L) | [ L.j : j in [1..Ngens (L)] ] cat [ Phi ] >;
      else   // augment the transversal
          Append (~T, Phi);
      end if;
  end while;
*/



