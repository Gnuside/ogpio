
type direction_t =
 | Direction_in
 | Direction_out

type edge_t =
 | Edge_none
 | Edge_rising
 | Edge_falling
 | Edge_both

val loaded : int -> bool

val edge : int -> edge_t option

val can_poll : int -> bool

val direction : int -> direction_t option

val value_fd : int -> Unix.open_flag list -> Unix.file_descr
