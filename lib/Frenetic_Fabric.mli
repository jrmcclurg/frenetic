open Core.Std
open Frenetic_Fdd
open Frenetic_Network
open Frenetic_OpenFlow
open Frenetic_NetKAT

module FieldTable : Hashtbl.S with type key = Field.t

exception IncompletePlace of string
exception NonExistentPath of string
exception NonFilterNode of policy
exception ClashException of string
exception CorrelationException of string

type condition = (Value.t option * Value.t list) FieldTable.t
type place     = (switchId * portId)
type stream    = place * place * condition * Action.t
type fabric    = (switchId, Frenetic_OpenFlow.flowTable) Hashtbl.t

(** Fabric generators, from a topology or policy *)
module Generators : sig
  val vlan_per_port : Net.Topology.t -> fabric
  val shortest_path : Net.Topology.t -> switchId list -> switchId list -> fabric
  val of_local_policy : policy -> switchId list -> fabric
  val of_global_policy : policy -> switchId list -> fabric
end

(** Topology Handling: Functions for finding adjacent nodes in a given topology *)
module Topo : sig
  val predecessors : policy -> (place, place) Hashtbl.t
  val successors : policy -> (place, place) Hashtbl.t
  val precedes : (place, place) Hashtbl.t -> place -> place -> portId option
  val succeeds :  (place, place) Hashtbl.t -> place -> place -> portId option
  val starts_at : (place, place) Hashtbl.t -> switchId -> stream -> bool
  val stops_at : (place, place) Hashtbl.t -> switchId -> stream -> bool
end


(** Condition related functions, useful for generating NetKAT programs from streams *)
module Condition  : sig
  type t = condition
  val of_pred     : pred -> t list
  val to_pred     : t -> pred
  val to_string   : t -> string

  val satisfy     : t -> policy list
  val undo        : t -> t -> policy list
  val places_only : t -> bool
  val is_subset   : t -> t -> bool
end


(** Module for dealing with policies specified as end-to-end paths directly, *)
(** instead of as NetKAT programs *)
module Path : sig
  type t

  val of_string : string -> (t list, string) Result.t
  val project   : t list -> stream list -> policy -> (policy list * policy list)

end

val dedup : policy -> policy
val streams_of_policy : policy -> stream list
val string_of_stream : stream -> string
val string_of_place  : place  -> string

val assemble : policy -> policy ->
  (switchId * portId) list -> (switchId * portId) list ->
  policy
val retarget : stream list -> stream list -> policy ->
  (policy list * policy list)
