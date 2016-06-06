
open Printf
open Unix

let build_env gpio_ids_and_values times =
  let gpio_count = List.length gpio_ids_and_values in
  let (_, env) = List.fold_left
    (fun (i, env) (id, value) ->
      env.(i * 2)     <- sprintf "OGPIO_FILE_%d_VALUE=%d" id value ;
      env.(i * 2 + 1) <- sprintf "OGPIO_FILE_%d_DURATION=" id ; (* FIXME *)
      (i + 1, env)
    )
    (0, Array.make (gpio_count * 2) "")
    gpio_ids_and_values
  in env

let start_callback_script command gpio_ids_and_values times =
  match Unix.fork () with
   | 0   -> ignore (execve command [||] (build_env gpio_ids_and_values times))
   | pid -> ignore (waitpid [] pid)
