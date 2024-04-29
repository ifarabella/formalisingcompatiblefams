import Mathlib.Tactic
import Mathlib.NumberTheory.Padics.PadicNumbers
import Mathlib.Topology.Algebra.ContinuousMonoidHom
import Mathlib.FieldTheory.KrullTopology
import Mathlib.Topology.Instances.Matrix
import Mathlib.Topology.Basic

/-!
# Families of p-adic Galois Representations

Given number fields `K` and `E`, a `PadicGaloisFamily` is a family of continuous
homomorphisms from Gal(Kbar/K) to GLₙ(ℚ_[p]bar) indexed by primes and
ring homomorphisms from `E` to `ℚ_[p]bar`.

## Main definitions and results

* `PadicGaloisFamily`: a family of p-adic Galois representations
* `cont_if_open_ker`: proves that if the kernel of a homomorphism between topological
  groups is open, then the homomorphism is continuous

## Notation
* `ℚ_[p]` - the p-adic numbers
-/
noncomputable section

variable {p : ℕ}[Fact (p.Prime)]

open TopologicalSpace Set Filter

/- The algebraic closure of the p-adic numbers is a normed commutative ring,
the proof of this is not yet in Mathlib so it is sorried here.-/
instance : NormedCommRing (AlgebraicClosure (ℚ_[p])) where
  norm := by sorry
  dist := by sorry
  dist_self := by sorry
  dist_comm := by sorry
  dist_triangle := by sorry
  edist_dist := by sorry
  eq_of_dist_eq_zero := by sorry
  dist_eq := by sorry
  norm_mul := by sorry
  mul_comm := by exact fun x y ↦ mul_comm x y

/--For number fields `E` and `K` and a natural number `n`, a family of p-adic Galois
representations is a family of continuous homomorphisms from a number field `K` to
`GLₙ(AlgebraicClosure(ℚ_[p]))` indexed by prime numbers `p` and the ring
homomorpisms `E` to `ℚ_[p]`-/
def PadicGaloisFamily (K : Type) [Field K] [NumberField K]
    (E : Type) [Field E] [NumberField E] (n: ℕ) :=
    ∀ (p : ℕ) [Fact p.Prime], ∀ (_ : E →+* AlgebraicClosure (ℚ_[p])),
    ContinuousMonoidHom ((AlgebraicClosure K)≃ₐ[K](AlgebraicClosure K))
    (GL  (Fin n) (AlgebraicClosure (ℚ_[p])))

/--When `n = 0`, there is a family of Galois representations-/
example (K: Type) [Field K] [NumberField K] (E : Type) [Field E] [NumberField E] :
    PadicGaloisFamily K E 0 :=
    fun p hp _ ↦ {
      toFun := fun _ ↦ 1
      map_one' := by
        rfl
      map_mul' := by
        simp only [mul_one, forall_const]
      continuous_toFun := by
        dsimp only [OneHom.toFun_eq_coe, OneHom.coe_mk]
        exact continuous_const
  }
/--We can get a `PadicGaloisFamily` out of the trivial representation-/
example (K: Type) [Field K] [NumberField K] (E : Type) [Field E] [NumberField E]
    (n : ℕ) :
    PadicGaloisFamily K E n :=
    fun p hp _ ↦ {
      toFun := fun _ ↦ 1
      map_one' := by
        rfl
      map_mul' := by
        simp only [mul_one, forall_const]
      continuous_toFun := by
        dsimp only [OneHom.toFun_eq_coe, OneHom.coe_mk]
        exact continuous_const
  }
/-Kevin gave me the following 2 lemmas + 1 instance about finite field extensions I've gone though
and added some comments + changed the last one to be an instance instead of a lemma so
I didn't have to call it later. All mistakes are my own-/

/--The subgroup of `Gal(L/K)` that fixes the top intermediate field of `L` and `K` (which is `L`)
is the bottom subgroup of `Gal(L/K)` (which is the trivial group) -/
lemma IntermediateField.fixingSubgroup_top (K L : Type) [Field K] [Field L] [Algebra K L] :
   IntermediateField.fixingSubgroup (⊤ : IntermediateField K L) = ⊥ := by
 ext g
 rw [mem_fixingSubgroup_iff]
 --the code in this lemma is mine after this which you could probably tell
 constructor
 · intro h
   have h1 : g = 1 := by
     ext x
     exact h x trivial
   exact h1
 · intro h
   have h1 : g = 1 := by
     ext x
     exact congrFun (congrArg FunLike.coe h) x
   intro x _
   rw [h1]
   simp


/-- For a finite dimensional field extenion `L/K`, `{1}` is open in `Gal(L/K)`-/
lemma isOpen_bot_of_finiteDimensional (K L : Type) [Field K] [Field L] [Algebra K L]
   [FiniteDimensional K L] : IsOpen ({1} : Set (L ≃ₐ[K] L)) := by
 convert IntermediateField.fixingSubgroup_isOpen ⊤
 · simp only [IntermediateField.fixingSubgroup_top, Subgroup.coe_bot]
 · infer_instance
--the subgroup fixing ⊤ is open so it suffices to prove that {1} is this fixing subgroup

/--For a finite dimensional field extension `L/K`, `Gal(L/K) has the discrete topology`-/
instance discreteTopology_iff_finiteDimensional (K L : Type) [Field K] [Field L] [Algebra K L]
   [FiniteDimensional K L] : DiscreteTopology (L ≃ₐ[K] L) := by
 rw [discreteTopology_iff_isOpen_singleton_one]
 apply isOpen_bot_of_finiteDimensional

open scoped Pointwise

/-- For groups `G` and `H`, a group homomorphism `χ : G →* H` a subset `A` of `H`,
an element `x` of the pre-image of `A`, the coset `x•(χ.ker)` is contained in the
pre-image of   -/
lemma elt_mul_ker_in_preimage (G H : Type) [Group G] [Group H] {χ : G →* H} {A : Set H} {x : G}
    (h : x ∈ χ ⁻¹' A ) :
    x • (χ.ker : Set G) ⊆ χ ⁻¹' A := by
  intro y hy
  rw [mem_leftCoset_iff] at hy
  have h1 : (χ (x⁻¹ * y)) = 1 := hy
  rw [map_mul, map_inv] at h1
  apply_fun (χ x * .) at h1
  simp only [mul_inv_cancel_left, mul_one, mem_preimage] at h1 h
  rw [← h1] at h
  exact h

/--A homomorphism between topological groups is continuous if its kernel is open-/
theorem cont_if_openKer (G H : Type) [TopologicalSpace G] [Group G]
    [TopologicalGroup G] [TopologicalSpace H] [Group H] [TopologicalGroup H]
    (χ : G →* H) (h : IsOpen (χ.ker : Set G)) :
    Continuous χ := by
  rw [continuous_def]
  intro U _
  apply isOpen_iff_mem_nhds.mpr
  intro x hx
  have h1 := elt_mul_ker_in_preimage G H hx
  have h2 : IsOpen (x • (χ.ker : Set G)) := by exact IsOpen.smul h x
  have h3 : x ∈ (x • (χ.ker : Set G)) := by
    rw [mem_leftCoset_iff, mul_left_inv]
    exact Subgroup.one_mem (MonoidHom.ker χ)
  rw [mem_nhds_iff]
  use x • (χ.ker : Set G)
  --proof outline : pre-image of U ⊆ H is union of cosets of ker

-- Thanks to Jujian Zhang for help on the proof of this lemma, all mistakes are my own
/--For fields K/E/L with E/L finite dimensional, the restriction map from Gal(L/K)
to Gal(E/K) has kernel equal to the fixing subgroup of E-/
lemma gal_restrict_ker_gal (K L : Type) [Field K] [Field L] [Algebra K L]
    (E : IntermediateField K L) [FiniteDimensional K E] [Normal K E]:
    (AlgEquiv.restrictNormalHom (E)).ker = E.fixingSubgroup := by
  ext b
  constructor
  · intro hb
    rw [IntermediateField.fixingSubgroup, mem_fixingSubgroup_iff]
    intro y hy
    simp only [AlgEquiv.smul_def]
    rw [MonoidHom.mem_ker] at hb
    let x : ↥E := { val := y, property := hy }
    replace hb := FunLike.congr_fun hb
    have hbx := hb x
    simp at hbx
    rw [← Subtype.val_inj] at hbx
    simp at hbx
    have : ((((AlgEquiv.restrictNormalHom ↥E) b) { val := y, property := hy }): L) = _ :=
      AlgEquiv.restrictNormal_commutes b E ⟨y, hy⟩
    erw [this] at hbx --unfurls definitions a bit and tries rw
    exact hbx
  · intro h
    rw [MonoidHom.mem_ker]
    rw [IntermediateField.fixingSubgroup, mem_fixingSubgroup_iff] at h
    ext y
    specialize h y.1 y.2 --y.1 says y : L, y.2 says y ∈ ↑E (the c)
    have : ((((AlgEquiv.restrictNormalHom ↥E) b) y): L) = _ :=
      AlgEquiv.restrictNormal_commutes b E y
    rw [this]
    exact h

/--The equality of two subgroups implies their equality as sets under certain coercions-/
lemma set_eq_if_subgp_eq (G : Type) [Group G] (H : Subgroup G) (M : Subgroup G) :
    (H = M) → (H.carrier : Set G) = (M : Set G) := fun a =>
  congrArg Subsemigroup.carrier (congrArg Submonoid.toSubsemigroup
    (congrArg Subgroup.toSubmonoid a))

/--For fields K/E/L with E/L finite dimensional, the restriction map from Gal(K/L)
to Gal(E/L) has an open kernel-/
lemma gal_restrict_ker_open (K L : Type) [Field K] [Field L] [Algebra K L]
    (E : IntermediateField K L) [FiniteDimensional K E] [Normal K E] :
    IsOpen ((((AlgEquiv.restrictNormalHom (E)).ker)).carrier : Set (L ≃ₐ[K] L)) := by
  have h1 : ((AlgEquiv.restrictNormalHom (E)).ker.carrier : Set (L ≃ₐ[K] L)) =
      (E.fixingSubgroup : Set (L ≃ₐ[K] L)) := by
    apply set_eq_if_subgp_eq (L ≃ₐ[K] L) (AlgEquiv.restrictNormalHom (E)).ker E.fixingSubgroup
    exact gal_restrict_ker_gal K L E
  rw [h1]
  exact IntermediateField.fixingSubgroup_isOpen E

/--For fields K/E/L with E/L finite dimensional, the restriction map from Gal(K/L)
to Gal(E/L) is continuous-/
lemma gal_restrict_cont (K L : Type) [Field K] [Field L] [Algebra K L]
    (E : IntermediateField K L) [FiniteDimensional K E] [Normal K E] :
    Continuous ((AlgEquiv.restrictNormalHom E : ((L)≃ₐ[K](L)) →* (E)≃ₐ[K](E))) := by
  have h1 : IsOpen ((((AlgEquiv.restrictNormalHom (E)).ker)).carrier : Set (L ≃ₐ[K] L)) := by
    exact gal_restrict_ker_open K L E
  exact cont_if_openKer (L ≃ₐ[K] L) (↥E ≃ₐ[K] ↥E) (AlgEquiv.restrictNormalHom ↥E) h1

/-- For commutative rings `R` and `S`, a natural number `n`, and `ψ : R →+* S`,
the group homomorphism `GL (Fin n) R →* GL (Fin n) S` given by applying `ψ` to every entry
of the matrix-/
def GLMap (R S : Type) (n : ℕ) [CommRing R] [CommRing S] (ψ : R →+* S) :
    GL (Fin n) R →* GL (Fin n) S := Units.map (RingHom.mapMatrix ψ).toMonoidHom

-- Jujian Zhang figured out that this was needed, Lean couldn't figure out that the
--intermediate field L was an AddCommGroup
instance (K: Type)[Field K] [NumberField K]
    (L : IntermediateField K (AlgebraicClosure K) ) :
  AddCommGroup L := inferInstanceAs (AddCommGroup L.toSubfield)

/-- For number fields `K` and `E` and `n` an natural, a finite field extension `L/K`, and a group
homomorphism `ρ : Gal(L/K) →* GLₙ(E)`, there is a family of p-adic Galois representations
given by (f∘ρ)∘g where:
f : GLₙ(E) → GLₙ(AlgebraicClosure ℚ_[p]) is (GLMap E (AlgebraicClosure (ℚ_[p])) n ψ)
g : Gal((AlgebraicClosure K)/K) → Gal(L/K) is the restriction to L
g is continuous from gal_restrict_cont
ρ∘f : Gal(L/K) → GLₙ(AlgebraicClosure ℚ_[p])is continuous because Gal(L/K) has the discrete
topology-/
example (n : ℕ) (K: Type)[Field K] [NumberField K]
    (E : Type) [Field E] [NumberField E] (L : IntermediateField K (AlgebraicClosure K) )
    [FiniteDimensional K L][IsGalois K L] [IsScalarTower K L (AlgebraicClosure K)]
    (ρ: ((L)≃ₐ[K](L)) →* (GL (Fin n) E)) :
    PadicGaloisFamily (K) (E) (n) :=
    fun p hp ψ ↦ ({
      toFun := MonoidHom.comp (MonoidHom.comp
        (GLMap E (AlgebraicClosure (ℚ_[p])) n ψ) ρ) (AlgEquiv.restrictNormalHom L)
      map_one' :=
        MonoidHom.map_one (MonoidHom.comp (MonoidHom.comp (GLMap E (AlgebraicClosure ℚ_[p]) n ψ) ρ)
            (AlgEquiv.restrictNormalHom L))
      map_mul' := fun x y =>
        map_mul (MonoidHom.comp (MonoidHom.comp (GLMap E (AlgebraicClosure ℚ_[p]) n ψ) ρ)
            (AlgEquiv.restrictNormalHom L))
          x y
      continuous_toFun :=  by
        have hg : Continuous ((AlgEquiv.restrictNormalHom L) :
            ((AlgebraicClosure K)≃ₐ[K](AlgebraicClosure K)) → (L ≃ₐ[K] L)) := by
          exact gal_restrict_cont K (AlgebraicClosure K) L
        have hcomp : Continuous (MonoidHom.comp (GLMap E (AlgebraicClosure (ℚ_[p])) n ψ) ρ) := by
          exact continuous_of_discreteTopology
        dsimp
        exact Continuous.comp hcomp hg
    } : ContinuousMonoidHom ((AlgebraicClosure K)≃ₐ[K](AlgebraicClosure K))
    (GL  (Fin n) (AlgebraicClosure (ℚ_[p]))))
