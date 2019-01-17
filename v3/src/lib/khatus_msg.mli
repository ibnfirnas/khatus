type content =
  | Alert of {priority : [`low | `med | `hi]; subject : string; body : string}
  | Data of {key : string list; value : string}
  | Cache of
      { mtime : Khatus_time.t
      ; node  : string
      ; modul : string
      ; key   : string list
      ; value : string
      }
  | Error of string
  | Log of {location : string; level : [`info | `error]; msg : string}
  | Status_bar of string

type t =
  {node : string; modul : string; content : content}

type 'a data_handler =
  (node:string -> modul:string -> key:string list -> value:string -> 'a)

val to_string : t -> string

val handle_data : t -> f:'a data_handler -> otherwise:'a -> 'a
