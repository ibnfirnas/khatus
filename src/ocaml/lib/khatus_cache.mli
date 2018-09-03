type t

val create : unit -> t

val update
  : t
  -> node  : string
  -> modul : string
  -> key   : (string list)
  -> value : string
  -> time  : Khatus_time.t
  -> unit

val update_if_data : t -> msg:Khatus_msg.t -> time:Khatus_time.t -> unit

val dump : t -> node:string -> modul:string -> oc:out_channel -> unit
