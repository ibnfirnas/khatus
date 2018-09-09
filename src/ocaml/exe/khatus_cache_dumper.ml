open Printf
open Khatus

let modul = __MODULE__

let (/) = Filename.concat

let mkdir_p dir =
  match Sys.command("mkdir -p " ^ dir) with
  | 0 -> ()
  | n ->
      failwith
        (sprintf "Failed to create directory: %S. mkdir status: %d\n" dir n)

let gzip path =
  match Sys.command("gzip " ^ path) with
  | 0 -> ()
  | n ->
      failwith
        (sprintf "Failed to gzip path: %S. gzip status: %d\n" path n)

let main ~node ~cache ~dump_interval:interval ~dump_directory =
  mkdir_p dump_directory;
  let dump_filename = dump_directory / "khatus-cache-dump.psv.gz" in
  let rec loop ~time ~time_dumped =
    (match read_line () with
    | exception End_of_file ->
        ()
    | line ->
        (match Msg_parser.parse_msg (Lexing.from_string line) with
        | Ok msg ->
            let time = Msg.next_time msg ~node ~time in
            Cache.update_if_data cache ~msg ~time;
            if (Time.Span.is_gt_or_eq (Time.diff time_dumped time) interval)
            then
              (
                let (tmp_filename, oc) =
                  Filename.open_temp_file "khatus-cache" "dump"
                in
                Cache.dump cache ~node ~modul ~oc;
                close_out oc;
                gzip tmp_filename;
                Sys.rename (tmp_filename ^ ".gz") dump_filename;
                loop ~time ~time_dumped:time
              )
            else
              loop ~time ~time_dumped
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
                    { location = "main:loop"
                    ; level    = `error
                    ; msg      = sprintf "Parse error %s in %s" e line
                    }
                });
            loop ~time ~time_dumped
        )
    )
  in
  loop ~time:Time.init ~time_dumped:Time.init

let () =
  main
    ~node:(Sys.argv.(1))
    ~dump_interval:(Time.Span.of_string Sys.argv.(2))
    ~dump_directory:(Sys.argv.(3))
    ~cache:(Cache.create ())
