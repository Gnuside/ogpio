
open Printf
open Unix

let build_env gpio_ids_and_values gpio_ids_and_old_values =
  let now = gettimeofday ()
  and gpio_count = List.length gpio_ids_and_values in
  let search_old_value id =
    let (_, old_value, time) = List.find (fun (id', _, _) -> (id' = id)) gpio_ids_and_old_values
    in (old_value, now -. time)
  in
  let (_, env) = List.fold_left
    (fun (i, env) (id, value) ->
      let (old_value, duration) = search_old_value id in
      env.(i * 4)     <- sprintf "OGPIO_FILE_%d_VALUE=%d" id value ;
      env.(i * 4 + 1) <- sprintf "OGPIO_FILE_%d_DURATION_S=%d" id (int_of_float duration) ;
      env.(i * 4 + 2) <- sprintf "OGPIO_FILE_%d_DURATION_F=%f" id duration ;
      env.(i * 4 + 3) <- sprintf "OGPIO_FILE_%d_OLD_VALUE=%d" id old_value ;
      (i + 1, env)
    )
    (0, Array.make (gpio_count * 4) "")
    gpio_ids_and_values
  in env

let start_callback_script command gpio_ids_and_values gpio_ids_and_old_values =
  match Unix.fork () with
   | 0   -> ignore (execve command [||] (build_env gpio_ids_and_values gpio_ids_and_old_values))
   | pid -> ignore (waitpid [] pid)
