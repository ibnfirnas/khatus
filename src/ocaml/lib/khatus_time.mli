module Span : sig
  type t

  val of_string : string -> t

  val is_gt_or_eq : t -> t -> bool
end

type t

val init : t

val diff : t -> t -> Span.t

val to_string : t -> string

val of_string : string -> t
