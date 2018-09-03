val parse_msg
  : Lexing.lexbuf
  ->
    ( Khatus_msg.t
    , [ `Bad_format_of_msg_head
      | `Bad_format_of_msg_content
      ]
    ) result
