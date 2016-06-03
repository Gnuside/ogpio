
open Printf
open Unix

type direction_t =
 | Direction_in
 | Direction_out

type edge_t =
 | Edge_none
 | Edge_rising
 | Edge_falling
 | Edge_both

let buff_size = 64
let buff = Bytes.create buff_size

let path_sys_gpio_file gpio_id name =
  sprintf "/sys/class/gpio/gpio%d/%s" gpio_id name

let open_sys_gpio_file gpio_id name flags =
  let path = sprintf "/sys/class/gpio/gpio%d/%s" gpio_id name in
  openfile path flags 0o755

let read_sys_gpio_file fd =
  let r = read fd buff 0 buff_size in
  if r > 0 then begin
    String.trim (Bytes.sub_string buff 0 r)
  end else begin
    ""
  end

let open_and_read_sys_gpio_file gpio_id name =
  try read_sys_gpio_file (open_sys_gpio_file gpio_id name [ O_RDONLY ])
  with Unix_error(_, _, _) -> ""

let loaded gpio_id =
  try access (path_sys_gpio_file gpio_id "value") [ F_OK ] ; true
  with Unix_error(_, _, _) -> false
;;

let edge gpio_id =
  let content = open_and_read_sys_gpio_file gpio_id "edge" in
       if content = "in"  then Some(Direction_in)
  else if content = "out" then Some(Direction_out)
  else None

let direction gpio_id =
  let content = open_and_read_sys_gpio_file gpio_id "direction" in
       if content = "none"    then Some(Edge_none)
  else if content = "rising"  then Some(Edge_rising)
  else if content = "falling" then Some(Edge_falling)
  else if content = "both"    then Some(Edge_both)
  else None

let value_fd gpio_id flags =
  open_sys_gpio_file gpio_id "value" flags
