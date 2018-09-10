open Printf

module Msg        = Khatus_msg
module Msg_parser = Khatus_msg_parser
module State      = Khatus_state

type t =
  { state  : State.t
  ; stream : Msg.t Stream.t
  }

let init ~node ~modul =
  let line_stream =
    Stream.from (fun _ ->
      match read_line () with
      | exception End_of_file ->
          None
      | line ->
          Some line
    )
  in
  let rec parse_next msg_count =
    (match Stream.next line_stream with
    | exception Stream.Failure ->
        None
    | line ->
        (match (Msg_parser.parse_msg (Lexing.from_string line)) with
        | Ok msg ->
            Some msg
        | Error e ->
            let e =
              match e with
              | `Bad_format_of_msg_head    -> "Bad_format_of_msg_head"
              | `Bad_format_of_msg_content -> "Bad_format_of_msg_content"
            in
            eprintf
              "%s\n%!"
              Msg.(to_string
                { node
                ; modul
                ; content = Log
                    { location = "khatus_msg_stream:fold"
                    ; level    = `error
                    ; msg      = sprintf "Parse error %s in %s" e line
                    }
                });
            parse_next msg_count
        )
    )
  in
  { state  = State.init ~node ~modul
  ; stream = Stream.from parse_next
  }

let rec fold ({state; stream} as t) ~f ~init =
  match Stream.next stream with
  | exception Stream.Failure ->
      init
  | msg ->
      let state = State.update state ~msg in
      fold {t with state} ~f ~init:(f init ~state ~msg)
