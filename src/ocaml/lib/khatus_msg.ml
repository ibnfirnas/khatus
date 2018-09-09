module Time = Khatus_time

type content =
  | Alert of {priority : [`low | `med | `hi]; subject : string; body : string}
  | Data of {key : string list; value : string}
  | Cache of
      { mtime : Time.t
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

let sep_1 = "|"
let sep_2 = ":"

let to_string {node; modul; content} =
  match content with
  | Alert {priority; subject; body} ->
      let priority =
        match priority with
        | `hi  -> "hi"
        | `med -> "med"
        | `low -> "low"
      in
      String.concat sep_1 [node; modul; "alert"; priority; subject; body]
  | Data {key; value} ->
      let key = String.concat sep_2 key in
      String.concat sep_1 [node; modul; "data"; key; value]
  | Cache {mtime; node=node'; modul=modul'; key; value} ->
      let key = String.concat sep_2 key in
      let mtime = Time.to_string mtime in
      String.concat
        sep_1
        [node; modul; "cache"; mtime; node'; modul'; key; value]
  | Error text ->
      String.concat sep_1 [node; modul; "error"; text]
  | Log {location; level; msg} ->
      let level =
        match level with
        | `info  -> "info"
        | `error -> "error"
      in
      String.concat sep_1 [node; modul; "log"; location; level; msg]
  | Status_bar text ->
      String.concat sep_1 [node; modul; "status_bar"; text]

let next_time t ~node ~time:time0 =
  match t with
  | { modul   = "khatus_sensor_datetime"
    ; content = Data {key = ["epoch"]; value = time1}
    ; node    = node'
    } when node' = node ->
      (* TODO: Going forawrd, perhaps throwing exceptions is the wrong way. *)
      (* TODO: Should we check this one at msg parse time? *)
      Time.of_string time1
  | {content = Data       _; _}
  | {content = Alert      _; _}
  | {content = Cache      _; _}
  | {content = Error      _; _}
  | {content = Log        _; _}
  | {content = Status_bar _; _}
  ->
      time0
