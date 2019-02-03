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

val dump_to_dir
  : t
  -> time:Khatus_time.t
  -> node:string
  -> modul:string
  -> dir:string
  -> unit
