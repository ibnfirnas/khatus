module Hashtbl = MoreLabels.Hashtbl

module Msg  = Khatus_msg
module Time = Khatus_time

type t =
  { values : ((string * string * string list), string) Hashtbl.t
  ; mtimes : ((string * string * string list), Time.t) Hashtbl.t
  }

let create () =
  { values = Hashtbl.create 256
  ; mtimes = Hashtbl.create 256
  }

let update {values; mtimes} ~node ~modul ~key ~value:data ~time =
  let key = (node, modul, key) in
  Hashtbl.replace values ~key ~data;
  Hashtbl.replace mtimes ~key ~data:time

let update_if_data t ~msg ~time =
  match msg with
  | Msg.({content = Data {key; value}; node; modul}) ->
      update t ~node ~modul ~key ~value ~time
  | {Msg.content = Msg.Alert      _; _}
  | {Msg.content = Msg.Cache      _; _}
  | {Msg.content = Msg.Error      _; _}
  | {Msg.content = Msg.Log        _; _}
  | {Msg.content = Msg.Status_bar _; _}
  ->
      ()

let dump {values; mtimes} ~node ~modul ~oc =
  Hashtbl.iter values ~f:(fun ~key ~data:value ->
    let mtime =
      match Hashtbl.find_opt mtimes key with
      | Some mtime -> mtime
      | None       -> assert false  (* Implies update was incorrect *)
    in
    let (node', modul', key) = key in
    let msg =
      Msg.(to_string
          { node
          ; modul
          ; content = Cache {mtime; node = node'; modul = modul'; key; value}
          }
        )
    in
    output_string
      oc
      (msg ^ "\n")
  )
