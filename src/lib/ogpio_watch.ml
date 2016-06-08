
open Printf
open Unix
open Ogpio_unix

type gpio_file_desc = Unix.file_descr

let buff_size = 12
let buff = Bytes.create buff_size

let open_file id =
  Ogpio_capabilities.value_fd id [ O_RDONLY ]

let open_files ids =
  List.map (open_file) ids

let seek_to_begining fds =
  List.iter (fun fd -> ignore (lseek fd 0 SEEK_SET)) fds

let rec read_value fd =
  let r = read fd buff 0 buff_size in
  if r > 0 then begin
    let content = String.trim (Bytes.sub_string buff 0 r) in
    begin try
      int_of_string content
    with
    (* Conversion to integer failed *)
     | Failure _ -> begin
        printf "Invalid format of gpio value file. (%s)\n%!" content ;
        -1
       end
    end ;
  end else if r = 0 then begin
    read_value fd
  end else begin
    failwith "Cannot read gpio value"
  end

let poll fds =
  match select [] [] fds (-1.) with
   | [], [], f' -> List.map (fun fd -> (fd, read_value fd)) f'
   | _ , _ , _  -> failwith "poll failed"

let watch_changes old_values fds =
  match select fds [] [] (-1.) with
   | notified_fds, [], [] -> begin
      let filter_values_changed () =
        List.filter (fun (_, new_value, old_value) -> new_value <> old_value)
          (List.map (fun fd ->
              let n = read_value fd in
              (fd, n, snd (List.find (fun e -> fst e = fd) old_values))
          ) notified_fds)
      in List.map
        (fun (fd, new_value, _) -> (fd, new_value))
        (filter_values_changed ())
    end
   | _ , _ , _  -> failwith "watch_changes failed"

let read_changes ~interval ~poll_enabled old_values fds =
  if poll_enabled = true then
    poll fds
  else
    (* Not really optimized, but should work for every drivers *)
    let new_values = watch_changes old_values fds in
    wait_ms interval ; (* TODO: parameter for wait interval *)
    new_values

let rec loop ~interval ~poll_enabled old_values fds callback =
  seek_to_begining fds ;
  match read_changes ~interval: interval ~poll_enabled: poll_enabled old_values fds with
   | []     -> loop ~interval: interval ~poll_enabled: poll_enabled old_values fds callback
   | values -> begin
      let merge_with_old_values () =
        List.map (fun (fd, old_value) ->
            try List.find (fun (fd', _) -> fd = fd') values
            with Not_found -> (fd, old_value))
          old_values
      in
      callback values [] (* TODO *) ;
      loop ~interval: interval ~poll_enabled: poll_enabled (merge_with_old_values ()) fds callback
    end

let observer ?(interval=0.15) gpio_ids callback =
  if gpio_ids = [] then
    failwith "gpio_ids parameter should not be empty"
  ;
  (* FIXME: we use poll only if *every* GPIO id values can be polled *)
  let can_poll = List.for_all (Ogpio_capabilities.can_poll) gpio_ids
  and fds = open_files gpio_ids in
  if can_poll = false then
    printf "Warning: polling is disabled with one of these GPIOs, please update your drivers.\n%!"
  ;
  let fds_ids = List.combine fds gpio_ids in
  let fd_to_gpio_id fd =
    snd (List.find (fun (fd', _) -> fd' = fd) fds_ids) in
  let values_to_gpio_ids values =
    List.map (fun (fd, value) -> (fd_to_gpio_id fd, value)) values in
  let base_values () =
    List.map (fun fd -> (fd, read_value fd)) fds
  and callback' values times =
    callback (values_to_gpio_ids values) times
  in
  loop ~interval: interval ~poll_enabled: can_poll (base_values ()) fds (callback')
