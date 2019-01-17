type t

val init : node:string -> modul:string -> t

val fold
  : t
  -> f:('a -> state:Khatus_state.t -> msg:Khatus_msg.t -> 'a)
  -> init:'a
  -> 'a
