
open Printf
open Unix
open Ogpio_unix

type gpio_file_desc = Unix.file_descr

let buff_size = 64
let buff = Bytes.create buff_size

let open_file id =
  Ogpio_capabilities.value_fd id [ O_RDONLY ]

let open_files ids =
  List.map (open_file) ids

let seek_to_begining fds =
  List.iter (fun fd -> ignore (lseek fd 0 SEEK_SET)) fds

let read_value fd =
  let r = read fd buff 0 buff_size in
  if r > 0 then begin
    let content = String.trim (Bytes.sub_string buff 0 r) in
    begin try
      int_of_string content
    with
    (* Conversion to integer failed *)
     | Failure _ -> begin
        printf "Invalid format of gpio value file. (%s)" content ;
        -1
       end
    end ;
  end else begin
    -1
  end

let pool fds =
  match select [] [] fds (-1.) with
   | [], [], f' -> List.map (read_value) f'
   | _ , _ , _  -> failwith "pool failed"

let watch_changes old_values fds =
  match select fds [] [] (-1.) with
   | notified_fds, [], [] -> begin
      let filter_values_changed fds_values =
        List.filter (fun (fd, new_value, old_value) -> new_value <> old_value)
          (List.map (fun fd ->
              let n = read_value fd in
              (fd, n, snd (List.find (fun e -> fst e = fd) fds_values))
          ) notified_fds)
      in List.map
        (fun (fd, new_value, old_value) -> new_value)
        (filter_values_changed (List.combine fds old_values))
    end
   | _ , _ , _  -> failwith "watch_changes failed"

let read_changes ~pool_enabled old_values_f fds =
  if pool_enabled = true then
    pool fds
  else
    (* Not really optimized, but should work for every drivers *)
    let new_values = watch_changes (old_values_f ()) fds in
    wait_ms 0.15 ; (* TODO: parameter for wait interval *)
    new_values

let rec loop ~pool_enabled old_values_f fds callback =
  seek_to_begining fds ;
  match read_changes ~pool_enabled: pool_enabled old_values_f fds with
   | []     -> loop ~pool_enabled: pool_enabled old_values_f fds callback
   | values -> begin
      callback values [] (* TODO *) ;
      loop ~pool_enabled: pool_enabled (fun () -> values) fds callback
    end

let observer gpio_ids callback =
  if gpio_ids = [] then
    failwith "gpio_ids parameter should not be empty"
  ;
  (* FIXME: we use poll only if *every* GPIO id values can be polled *)
  let can_poll = List.for_all (Ogpio_capabilities.can_poll) gpio_ids
  and fds = open_files gpio_ids in
  if can_poll = false then
    printf "Warning: polling is disabled with one of these GPIOs, please update your drivers.\n%!"
  ;
  loop ~pool_enabled: can_poll
    (fun () -> List.map (read_value) fds)
    fds callback
