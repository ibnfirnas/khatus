type t =
  { node  : string
  ; modul : string
  ; time  : Khatus_time.t
  ; cache : Khatus_cache.t
  }

val init : node:string -> modul:string -> t

val update : t -> msg:Khatus_msg.t -> t
