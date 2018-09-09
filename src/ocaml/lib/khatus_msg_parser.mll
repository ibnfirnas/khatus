{
  module Msg  = Khatus_msg
  module Time = Khatus_time
  let sep_2    = ':'
}

let alphnumdash  = ['a'-'z' 'A'-'Z' '0'-'9' '_' '-']+
let snake = ['a'-'z' '_']+

let sep_1    = '|'
let node     = alphnumdash
let modul    = snake
let key      = ['a'-'z' 'A'-'Z' '0'-'9' '_' '-' ':']+
let level    = ("info" | "error")
let priority = ("low" | "med" | "hi")
let subject  = alphnumdash

rule parse_msg = parse
  | (node as node) sep_1 (modul as modul) sep_1 {
      match parse_content lexbuf with
      | Ok content     -> Ok Msg.({node; modul; content : content})
      | (Error _) as e -> e
  }
  | _ {
    parse_msg lexbuf
  }
  | eof {
      Error (`Bad_format_of_msg_head)
  }

and parse_content = parse
  | "status_bar" sep_1 {
      Ok (Msg.Status_bar (tl lexbuf))
  }
  | "cache"
      sep_1 (['0'-'9']+ as mtime)
      sep_1 (node as node)
      sep_1 (modul as modul)
      sep_1 (key as key)
      sep_1
  {
    let key = String.split_on_char sep_2 key in
    let mtime = Time.of_string mtime in
    Ok (Msg.Cache {mtime; node; modul; key; value = tl lexbuf})
  }
  | "data" sep_1 (key as key) sep_1 {
      Ok (Msg.Data {key = String.split_on_char sep_2 key; value = tl lexbuf})
  }
  | "error" sep_1 {
      Ok (Msg.Error (tl lexbuf))
  }
  | "alert" sep_1 (priority as priority) (subject as subject) sep_1 {
      let priority =
        match priority with
        | "low" -> `low
        | "med" -> `med
        | "hi"  -> `hi
        | _     -> assert false
      in
      Ok (Msg.Alert {priority; subject; body = tl lexbuf})
  }
  | "log" sep_1 (snake as location) (level as level) sep_1 {
      let level =
        match level with
        | "info"  -> `info
        | "error" -> `error
        | _       -> assert false
      in
      Ok (Msg.Log {location; level; msg = tl lexbuf})
  }
  | _ {
    parse_content lexbuf
  }
  | eof {
      Error (`Bad_format_of_msg_content)
  }

and tl = parse
  | (_* as tail) eof {tail}
