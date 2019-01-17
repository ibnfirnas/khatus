module Cache = Khatus_cache
module Msg   = Khatus_msg
module Time  = Khatus_time

type t =
  { node  : string
  ; modul : string
  ; time  : Time.t
  ; cache : Cache.t
  }

let init ~node ~modul =
  { node
  ; modul
  ; time  = Time.init
  ; cache = Cache.create ()
  }

(* TODO: Should probably wrap state update in result. *)
let update ({node; modul = _; time; cache} as t) ~msg =
  Msg.handle_data msg ~otherwise:t ~f:(fun ~node:src_node ~modul ~key ~value ->
    let time =
      match (modul, key) with
      | ("khatus_sensor_datetime", ["epoch"]) when src_node = node ->
          Time.of_string value  (* Raises if value is not a number *)
      | (_, _) ->
          time
    in
    Cache.update cache ~node:src_node ~modul ~key ~value ~time;
    {t with time}
  )
