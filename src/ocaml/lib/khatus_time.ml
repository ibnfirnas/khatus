module Span = struct
  type t = float

  let of_string s =
    float_of_string s

  let is_gt_or_eq t1 t2 =
    t1 >= t2
end

type t = float

let init = 0.0

let diff t0 t1 =
  t1 -. t0

let to_string t =
  Printf.sprintf "%f" t
  |> String.split_on_char '.'
  |> List.hd

let of_string s =
  float_of_string s
