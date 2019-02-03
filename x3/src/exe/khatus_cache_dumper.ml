open Khatus

let main ~stream ~interval ~dir =
  let dumped = Time.init in
  ignore (Msg_stream.fold stream ~init:dumped ~f:(
    fun dumped ~state:(State.({node; modul; time = now; cache;})) ~msg:_ ->
      let elapsed = Time.diff dumped now in
      if (Time.Span.is_gt_or_eq elapsed interval)
      then begin
        Cache.dump_to_dir cache ~time:now ~node ~modul ~dir;
        now
      end else
        dumped
  ))

let () =
  let modul          = __MODULE__ in
  let node           = Sys.argv.(1) in
  let dump_interval  = Sys.argv.(2) |> Time.Span.of_string in
  let dump_directory = Sys.argv.(3) in
  main
    ~stream:   (Msg_stream.init ~node ~modul)
    ~interval: dump_interval
    ~dir:      dump_directory
