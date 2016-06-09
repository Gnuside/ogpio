
open Printf
open Ogpio_watch

type config_t = {
  gpio_ids      : int list ;
  update_script : string ;
  interval      : float ;
  quiet         : bool ;
}

(* Parse command line arguments *)
let parse_cmdline () =
  let open Arg in

  (* default values *)
  let conf_update_script = ref "/etc/ogpio/hook.sh"
  and conf_gpio_ids      = ref []
  and conf_interval      = ref 0.15
  and conf_quiet         = ref false
  in

  let set_gpio_id gpio_id =
    conf_gpio_ids := List.append !conf_gpio_ids [gpio_id] ;
    ()
  in

  let usage = "Usage: " ^ Sys.argv.(0) ^ " [options]\n" in
  let speclist = [
    ("--gpio"             , Int set_gpio_id               , "\t\t\t\tID of a GPIO (ex: 42)");
    ("--update-script"    , Set_string conf_update_script , "SCRIPT\t\tPath to a script called after GPIO value changed");
    ("--interval"         , Set_float conf_interval       , "\t\t\t\tInterval between read attempts (only used if polling is impossible)");
    ("--quiet"            , Set conf_quiet                , "\t\t\t\tEnable quiet mode");
  ] in
  let error_fn arg = raise (Bad ("Bad argument : " ^ arg)) in

  (* Read the arguments *)
  parse speclist error_fn usage ;

  (* Return a value, like a structure *)
  {
    gpio_ids      = !conf_gpio_ids ;
    update_script = !conf_update_script ;
    interval      = !conf_interval ;
    quiet         = !conf_quiet ;
  }

(* main entry point *)
let () =
  let config =
    try parse_cmdline ()
    with
    |  Arg.Bad arg -> failwith arg
    |  _           -> failwith "Unexpected error."
  in

  begin if config.gpio_ids = [] then
    failwith "No --gpio specified"
  end ;

  List.iter (Ogpio_capabilities.export) config.gpio_ids ;

  Sys.catch_break true ; (* Raise exceptions on user interrupt *)

  try begin
    let all_gpio_loaded = List.for_all (Ogpio_capabilities.exported) config.gpio_ids
    in

    let callback values old_values =
      if config.quiet = false then
        printf "New value\n%!"
      ;
      Ogpio_callback.start_callback_script
        config.update_script
        values old_values
    in

    if all_gpio_loaded = true then begin
      observer ~interval: config.interval config.gpio_ids callback
    end else
      failwith "GPIO driver not loaded, or GPIO_SYSFS disabled in the kernel."
    ;
  end with _ -> begin
    printf "Unexport GPIOs...\n%!" ;
    List.iter (Ogpio_capabilities.unexport) config.gpio_ids
  end ;

  exit 0
