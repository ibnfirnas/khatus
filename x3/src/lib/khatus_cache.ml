open Printf

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

let dump_to_channel {values; mtimes} ~node ~modul ~oc =
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
    output_string oc msg;
    output_string oc "\n"
  )

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

let dump_to_dir t ~time ~node ~modul ~dir =
  (* TODO: Just log the errors and keep it moving, instead of failing. *)
  mkdir_p dir;
  let dump_filename = dir / "khatus-cache-dump.psv.gz" in
  let tmp_filename = "khatus-cache-dump-" ^ (Time.to_string time) in
  let oc = open_out tmp_filename in
  dump_to_channel t ~node ~modul ~oc;
  close_out oc;
  gzip tmp_filename;
  Sys.rename (tmp_filename ^ ".gz") dump_filename
