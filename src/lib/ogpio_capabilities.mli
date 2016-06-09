
type direction_t =
 | Direction_in
 | Direction_out

type edge_t =
 | Edge_none
 | Edge_rising
 | Edge_falling
 | Edge_both

val export : int -> unit

val unexport : int -> unit

val exported : int -> bool

val edge : int -> edge_t option

val edge_to_string : edge_t -> string

val set_edge : int -> edge_t -> unit

val can_poll : int -> bool

val direction : int -> direction_t option

val direction_to_string : direction_t -> string

val set_direction : int -> direction_t -> unit

val value_fd : int -> Unix.open_flag list -> Unix.file_descr
