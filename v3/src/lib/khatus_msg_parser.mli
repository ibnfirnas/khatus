type error =
  [ `Bad_format_of_msg_head
  | `Bad_format_of_msg_content
  ]

val parse_msg : Lexing.lexbuf -> (Khatus_msg.t, error) result
