Require Import 
  Pattern.StdLib 
  Coq.Classes.CMorphisms 
  Coq.Classes.CRelationClasses
  Pattern.OrderC.

Set Universe Polymorphism.
Set Asymmetric Patterns.

Module L := Lattice.

Delimit Scope Frame_scope with Frame.
Infix "<=" := L.le : Frame_scope.
Infix "==" := L.eq (at level 70) : Frame_scope.
Infix "∨" := L.max (at level 55) : Frame_scope.
Infix "∧" := L.min (at level 50) : Frame_scope.

Local Open Scope Frame.

(** A frame represents the essence of the algebraic structure of topologies,
    without the requirement that this algebraic structure be formed by
    subsets of an underlying space. The frame is just the algebra itself.
    A frame has a supremum operation, which corresponds to the fact that
    topologies are closed under arbitrary union.
    We call elements of a frame "opens" to indicate that they are reminiscent
    of open sets.

    Frames are also often referred to as locales. They're the same things, but
    are used to indicate opposite categories. The category of frames is the
    opposite of the category of locales. We do this because continuous functions
    are, in a sense, "backwards". A continuous function in topology 
    [f : A -> B] is defined by its inverse image which takes open sets in
    [B] to open sets in [A]. So a continuous function from [A] to [B] corresponds
    to a frame homomorphism from the frame representing the topology of [B] to the
    frame representing the topology of [A]. A frame homomorphism is a morphism
    in the category of frames. The morphisms of the category of locales are called
    continuous maps, and since it's the opposite category, a continuous 
    function from [A] to [B] corresponds to a continuous map from the locale
    for [A] to the locale for [B].
    *)

  Inductive sigT1@{U V} {A:Type@{U}} (P:A -> Type@{V}) : Type@{V} :=
    existT : forall x:A, P x -> sigT1 P.

Module Frame.
Section Frame.
Universes UI UA.

    (** Every frame must have a top and bottom element.
      However, predicatively, we're not guaranteed to be able to produce
      the top element, so we'll ask for it explicitly. *)

  Class Ops {A : Type@{UA}} :=
   { LOps :> L.Ops A
   ; top : A
   ; sup : forall {Ix : Type@{UI}}, (Ix -> A) -> A
   }.

  Arguments Ops : clear implicits.

  Class t {A : Type@{UA}} {OA : Ops A}: Type :=
  { L :> L.t A LOps
  ; top_ok : PreO.top (le := L.le) top
  ; sup_proper : forall {Ix : Type},
     Proper (pointwise_relation _ L.eq ==> L.eq) (@sup _ _ Ix)
  ; sup_ok :  forall {Ix : Type} (f : Ix -> A), PreO.sup (le := L.le) f (sup f)
  ; sup_distr : forall x {Ix : Type} (f : Ix -> A)
    , x ∧ sup f == (sup (fun i => x ∧ f i))
  }.

  Arguments t : clear implicits.
  Section Facts.
  Context {A : Type@{UA}} {OA} {tA : t A OA}.

  Definition sup_proper_u : forall {Ix : Type@{UI}} (f g : Ix -> A),
    (forall (i : Ix), f i == g i) -> sup f == sup g.
  Proof.
  intros. apply sup_proper. unfold pointwise_relation.
  assumption.
  Qed.

  Universes T P.
  Constraint T < UA.
  Local Instance type_ops : Ops@{P P} Type@{T} :=
    {| LOps := L.type_ops@{UA T P}
     ; top := True
     ; sup := @sigT1@{UI T}
    |}.

  Local Instance type : @t _ type_ops.
  Proof. constructor; simpl; intros.
  - apply L.type.
  - unfold PreO.top, arrow. auto.
  - constructor; unfold pointwise_relation in X; simpl in X;
    intros [??]; eexists; apply X; eassumption.
  - constructor; simpl; unfold arrow; intros.
    + exists i. assumption.
    + destruct X0. apply (X x). assumption.
  - split; intros.
    + destruct X as (xa & i & fia). exists i. split; assumption.
    + destruct X as (i & xa & fia). split. assumption.
      exists i. assumption.
  Qed.  

  Definition point_splits
    {I : Type@{UI}} (cov : I -> Type@{UI}) : top (Ops := type_ops) <= sup cov ->
     {i : I & top <= cov i}.
  Proof.
  simpl. unfold arrow. intros.
  destruct X. auto. exists x. auto.
  Qed.

  Definition bottom : A := sup (fun contra : False => False_rect _ contra).

  Definition bottom_ok : PreO.bottom (le := L.le) bottom.
  Proof.
    unfold PreO.bottom. intros. 
    apply (PreO.sup_least (fun contra : False => False_rect _ contra)).
    apply sup_ok. intros; contradiction.
  Qed.

  Require Import Pattern.SetsC.
Local Open Scope Subset.
Lemma le_min (U V : A) : L.le U V <--> L.eq (L.min U V) U.
Proof.
split; intros.
- apply PO.le_antisym; eapply L.min_ok. reflexivity.
  assumption.
- transitivity (L.min U V). rewrite X. reflexivity.
  apply L.min_ok.
Qed.

Lemma max_sup (U V : A) : 
  L.eq (L.max U V) (Frame.sup (fun b : bool => if b then U else V)).
Proof.
pose proof 
  (PreO.sup_ge (A := A) (le := L.le) (I := bool) (fun b : bool => if b then U else V)
  (Frame.sup (fun b : bool => if b then U else V))).
specialize (X (Frame.sup_ok _)).
apply PO.le_antisym.
- apply L.max_ok. apply (X true). apply (X false).
- apply Frame.sup_ok. intros. destruct i; apply L.max_ok.
Qed.

  End Facts.
  Section Morph. 
  Context {A B : Type@{UA}}
    {OA} {tA : t A OA}
    {OB} {tB : t B OB}.

  Record morph {f : A -> B} : Type :=
  { f_L : L.morph LOps LOps f
  ; f_sup : forall {Ix : Type@{UI}} (g : Ix -> A), L.eq (f (sup g)) (sup (fun i => f (g i)))
  ; f_top : L.eq (f top) top
  }.

  Arguments morph : clear implicits.

  Lemma f_eq {f : A -> B} :
    morph f -> Proper (L.eq ==> L.eq) f.
  Proof. 
    intros H. apply (L.f_eq (f_L H)).
  Qed.

  Lemma f_bottom {f : A -> B} : morph f -> L.eq (f bottom) bottom.
  Proof.
  intros MF. unfold bottom. rewrite (f_sup MF). apply sup_proper.
  unfold pointwise_relation. intros. contradiction.
  Qed.

  Lemma f_cov {f : A -> B} (Hf : morph f)
    (U : A) {Ix} (V : Ix -> A)
    : U <= sup V
    -> f U <= sup (fun i : Ix => f (V i)).
  Proof.
  intros H.
  rewrite <- f_sup by assumption.
  eapply PO.f_PreO. apply Hf. assumption.
  Qed.


Lemma morph_easy (f : A -> B) : 
Proper (L.eq ==> L.eq) f
-> f Frame.top == Frame.top
-> (forall U V, f (U ∧ V) == (f U ∧ f V))
-> (forall (Ix : Type) (g : Ix -> A),
f (Frame.sup g) == Frame.sup (fun i => f (g i)))
-> morph f.
Proof.
intros. econstructor.
- econstructor.
  + econstructor.
    * unfold PreO.morph, arrow. intros.
      apply le_min. apply le_min in X3.
      rewrite <- X1. apply X. assumption.
    * unfold Proper, respectful. eassumption.
  + intros. rewrite !max_sup. etransitivity.
    apply X2. apply Frame.sup_proper.
    unfold pointwise_relation. intros. destruct a0; reflexivity.
  + assumption.
- assumption.
- assumption.
Qed. 

  End Morph.

  Arguments morph {A B} OA OB f.

  Section MorphProps.
  Context {A : Type@{UA}} {OA} {tA : t A OA}.

  Lemma morph_id : morph OA OA (fun x => x).
  Proof. 
   intros. constructor. apply L.morph_id. apply L.
   reflexivity. reflexivity.
  Qed.

  Lemma morph_compose {B : Type@{UA}} {OB} {tB : t B OB}
    {C : Type@{UA}} {OC} {tC : t C OC}
     (f : A -> B) (g : B -> C)
     : morph OA OB f 
     -> morph OB OC g 
     -> morph OA OC (fun x => g (f x)).
  Proof. intros. constructor.
  - eapply L.morph_compose; (apply L || (eapply f_L; eassumption)).
  - intros. rewrite <- (f_sup X0). rewrite (f_eq X0).
    reflexivity. rewrite (f_sup X). reflexivity.
  - rewrite <- (f_top X0). rewrite (f_eq X0).
    reflexivity. rewrite (f_top X). reflexivity.
  Qed.

  End MorphProps.

  Definition one_ops : Ops True :=
    {| LOps := L.one_ops
     ; top := I
     ; sup := fun _ _ => I
    |}.

  Definition one : t True one_ops.
  Proof. constructor; intros; auto.
  - apply L.one.
  - unfold PreO.top. simpl. auto.
  - unfold Proper, respectful. intros. reflexivity.
  - constructor; trivial.
  Qed.

  (** Propositions form a frame, where supremum is given by the
      existential quantifier. *)
  Local Instance prop_ops : Ops Prop :=
    {| LOps := L.prop_ops
     ; top := True
     ; sup := (fun _ f => exists i, f i)
    |}.

  Local Instance prop : t Prop prop_ops.
  Proof. constructor; simpl; intros.
  - apply L.prop.
  - unfold PreO.top. simpl. auto.
  - constructor; unfold pointwise_relation in X; simpl in X;
     intros [??]; eexists; apply X; eassumption.
  - constructor; simpl; intros.
    + exists i. assumption.
    + destruct H0. apply (H x). assumption.
  - split; intros. 
    + destruct H as (xa & i & fia). exists i. intuition.
    + destruct H as (i & xa & fia). split. assumption.
      exists i. assumption.
  Qed.

  Definition pointwise_ops {A B} (OB : forall a : A, Ops (B a))
    : Ops (forall a, B a) :=
    {| LOps := L.pointwise_ops (fun _ => LOps)
     ; top := fun _ => top
     ; sup := fun _ f => fun x => sup (fun i => f i x)
    |}.

  Definition pointwise {A B OB} `(forall a : A, t (B a) (OB a))
    : t (forall a, B a) (pointwise_ops OB).
  Proof. constructor.
  - apply L.pointwise. intros. apply L.
  - unfold PreO.top. simpl. unfold pointwise_op.
    intros. apply top_ok.
  - simpl. unfold Proper, respectful, pointwise_relation, pointwise_op.
    intros. apply sup_proper. unfold pointwise_relation.
    intros a'. apply X.
  - constructor; simpl; unfold pointwise_op; intros.
    pose proof (@sup_ok _ _ (H a) Ix (fun i => f i a)).
    apply X.
    pose proof (@sup_ok _ _ (H a) Ix (fun i => f i a)).
    apply X0. intros. apply X.
  - simpl. unfold pointwise_op. intros.
    apply (sup_distr (t := H a)).
  Qed.

  Lemma sup_pointwise {A} {OA} {X : t A OA} {Ix Ix'} (f : Ix -> A) (g : Ix' -> A)
  : (forall (i : Ix), { j : Ix' & f i <= g j })
  -> sup f <= sup g.
  Proof.
  intros H. eapply PreO.sup_least. apply sup_ok. intros.
  destruct (H i). eapply PreO.le_trans. eassumption.
  apply PreO.sup_ge. apply sup_ok.
  Qed.

  Definition morph_pointwise {A B C OC} {tC : t C OC} (f : B -> A)
    : morph (pointwise_ops (fun _ : A => OC)) (pointwise_ops (fun _ : B => OC))
      (fun g b => g (f b)).
  Proof.
  constructor; intros; simpl in *; intros.
  - apply L.morph_pointwise.
  - unfold pointwise_op. intros. apply PO.eq_refl.
  - unfold pointwise_op. intros. reflexivity.
  Qed. 

  Definition subset_ops A : Ops (A -> Prop) := pointwise_ops (fun _ => prop_ops).
  
  Definition subset (A : Type) : t (A -> Prop) (subset_ops A):= 
     pointwise (fun _ : A => prop).

  (** [cmap] represents a continuous map on locales. It is just a
      package for a frame homomorphism running in the opposite direction. *)
  Record cmap {A OA} {B OB} := 
  { finv :> B -> A
  ; cont : morph OB OA finv
  }.

  Arguments cmap {A} OA {B} OB.

  (** A point in [A] is a continuous map from the frame representing
      a space with one point ([Prop]) to [A]. *)
  Definition point {A} (OA : Ops A) := cmap type_ops OA.

  (** Every function [f : A -> B] is continuous on the topology
      which includes all subsets. *)
  Definition subset_map {A B} (f : A -> B) : cmap (subset_ops A) (subset_ops B).
  Proof.
  refine ( {| finv P x := P (f x) |}).
  apply morph_pointwise.
  Defined.

  Definition cmap_compose {A B C OA OB OC} 
    {tA : t A OA} {tB : t B OB} {tC : t C OC}
    (f : cmap OA OB) (g : cmap OB OC) : cmap OA OC.
  Proof. refine (
  {| finv x := finv f (finv g x) |}
  ). eapply morph_compose; eapply cont.
  Defined.

  Existing Instances type_ops type.

  Definition point_cov {A OA} {tA : t A OA}
    (f : point OA) {U : A} {Ix} {V : Ix -> A}
    : U <= sup V
    -> finv f U -> { i : Ix & finv f (V i) }.
  Proof.
  intros Hcov Hpt.
  apply (f_cov (f := finv f)) in Hcov. 2: apply f.
  assert (L.le top (f U)).
  simpl. unfold arrow.  auto.
  rewrite <- X in Hcov.
  apply point_splits in Hcov.
  destruct Hcov. exists x. apply l. simpl. auto.
  Qed.

  Definition point_cov_top {A OA} {tA : t A OA}
    (f : point OA) {Ix} {U : Ix -> A}
    : top <= sup U
    -> { i : Ix & finv f (U i) }.
  Proof.
  intros. apply point_cov with top. assumption.
  pose proof (f_top (cont f)). simpl in X0. apply X0. 
  auto.
  Qed.

End Frame.

End Frame.

Arguments Frame.t {A} OA.
Arguments Frame.morph {A B} OA OB f.
Arguments Frame.cmap {A} OA {B} OB.
