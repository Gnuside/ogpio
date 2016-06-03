
type gpio_file_desc = Unix.file_descr

val open_file: int -> gpio_file_desc

(* From GPIO ids, returns a list of opened file descriptors *)
val open_files : int list -> gpio_file_desc list

(* Wait change of GPIO files
 * and returns new_value
 *)
val read_changes : (gpio_file_desc list) -> int list

(* Watch a list of GPIO value file constructed by GPIO ids. Async *)
val loop : gpio_file_desc list -> (int list -> float list -> unit) -> unit
