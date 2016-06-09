
open Printf
open Unix

type direction_t =
 | Direction_in
 | Direction_out

let direction_to_string = function
 | Direction_in  -> "in"
 | Direction_out -> "out"

type edge_t =
 | Edge_none
 | Edge_rising
 | Edge_falling
 | Edge_both

let edge_to_string = function
 | Edge_none    -> "none"
 | Edge_rising  -> "rising"
 | Edge_falling -> "falling"
 | Edge_both    -> "both"

let buff_size = 64
let buff = Bytes.create buff_size

let path_sys_gpio_file name =
  sprintf "/sys/class/gpio/%s" name

let path_sys_gpio_gpio_id_file gpio_id name =
  path_sys_gpio_file (sprintf "gpio%d/%s" gpio_id name)

let open_sys_gpio_file gpio_id name flags =
  let path = path_sys_gpio_gpio_id_file gpio_id name in
  openfile path flags 0o755

let read_sys_gpio_file fd =
  let r = read fd buff 0 buff_size in
  if r > 0 then begin
    String.trim (Bytes.sub_string buff 0 r)
  end else begin
    ""
  end

let write_sys_gpio_file fd value =
  ignore (write fd (Bytes.unsafe_of_string value) 0 (String.length value))

let open_and_read_sys_gpio_file gpio_id name =
  try read_sys_gpio_file (open_sys_gpio_file gpio_id name [ O_RDONLY ])
  with Unix_error(_, _, _) -> ""

let open_and_write_sys_gpio_file gpio_id name value =
  write_sys_gpio_file (open_sys_gpio_file gpio_id name [ O_WRONLY ]) value

let exported gpio_id =
  try access (path_sys_gpio_gpio_id_file gpio_id "value") [ F_OK ] ; true
  with Unix_error(_, _, _) -> false

let export_unexport gpio_id action =
  let path = path_sys_gpio_file action in
  let fd = openfile path [ O_WRONLY ] 0o755 in
  write_sys_gpio_file fd (string_of_int gpio_id)

let export gpio_id =
  if exported gpio_id then ()
  else export_unexport gpio_id "export"

let unexport gpio_id =
  export_unexport gpio_id "unexport"

let edge gpio_id =
  let content = open_and_read_sys_gpio_file gpio_id "edge" in
       if content = "none"    then Some(Edge_none)
  else if content = "rising"  then Some(Edge_rising)
  else if content = "falling" then Some(Edge_falling)
  else if content = "both"    then Some(Edge_both)
  else None

let set_edge gpio_id edge =
  open_and_write_sys_gpio_file gpio_id "edge" (edge_to_string edge)

let can_poll gpio_id =
  match edge gpio_id with
   | None
   | Some(Edge_none) -> false
   | _               -> true

let direction gpio_id =
  let content = open_and_read_sys_gpio_file gpio_id "direction" in
       if content = "in"  then Some(Direction_in)
  else if content = "out" then Some(Direction_out)
  else None

let set_direction gpio_id dir =
  open_and_write_sys_gpio_file gpio_id "direction" (direction_to_string dir)

let value_fd gpio_id flags =
  open_sys_gpio_file gpio_id "value" flags
