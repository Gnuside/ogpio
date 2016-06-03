
open Printf
open Unix

type gpio_file_desc = Unix.file_descr

let buff_size = 64
let buff = Bytes.create buff_size

let open_file id =
  let path = sprintf "/sys/class/gpio/gpio%d/value" id in
  openfile path [ O_RDONLY ] 0o755

let open_files ids =
  List.map (open_file) ids

let seek_to_begining fds =
  List.iter (fun fd -> ignore (lseek fd 0 SEEK_SET)) fds

let read_value fd =
  printf "read_value" ;
  let r = read fd buff 0 buff_size in
  if r > 0 then begin
    let content = String.trim (Bytes.sub_string buff 0 r) in
    begin try
      int_of_string content
    with
     | Failure str -> begin
        printf "Invalid format of gpio value file. (%s)" content ;
        -1
       end
    end ;
  end else begin
    -1
  end

let rec read_changes fds =
  match select [] [] fds (-1.) with
   | [], [], f' -> List.map (read_value) f'
   | _ , _ , _  -> read_changes fds (* Should not happen *)

let rec loop fds callback =
  printf "Truc\n%!" ;
  seek_to_begining fds ;
  printf "Test\n%!" ;
  match read_changes fds with
  | [] -> ()
  | values -> callback values [] (* TODO *)
  ; loop fds callback
