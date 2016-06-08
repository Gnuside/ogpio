
type gpio_file_desc = Unix.file_descr

val open_file: int -> gpio_file_desc

(* From GPIO ids, returns a list of opened file descriptors *)
val open_files : int list -> gpio_file_desc list

(* Watch a list of GPIO value file constructed by GPIO ids. Async *)
val observer : ?interval:float -> int list -> ((int * int) list -> (int * int * float) list -> unit) -> unit
