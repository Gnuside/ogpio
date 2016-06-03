
open Core.Std
open Printf

open Ogpio_watch

type config_t = {
  gpio_ids         : int list ;

  update_script    : string ;

} [@@deriving sexp]

(* Parse command line arguments *)
let parse_cmdline () =
  let open Arg in

  (* default values *)
  let conf_update_script             = ref "/etc/ogpio/hook.sh"
  and conf_gpio_ids                  = ref []
  in

  let set_gpio_id gpio_id =
    conf_gpio_ids := List.append !conf_gpio_ids [gpio_id] ;
    ()
  in

  let usage = "Usage: " ^ Sys.argv.(0) ^ " [options]\n" in
  let speclist = [
    ("--gpio"             , Int set_gpio_id               , "\t\t\t\tID of a GPIO (ex: 42)");
    ("--update-script"    , Set_string conf_update_script , "SCRIPT\t\tPath to a script called after GPIO value changed");
  ] in
  let error_fn arg = raise (Bad ("Bad argument : " ^ arg)) in

  (* Read the arguments *)
  parse speclist error_fn usage ;

  (* Return a value, like a structure *)
  {
    gpio_ids                  = !conf_gpio_ids ;

    update_script             = !conf_update_script ;
  }

let callback values times =
  printf "Salut"

(* main entry point *)
let () =
  let config =
    try parse_cmdline ()
    with
    |  Arg.Bad arg -> never_returns @@ failwith arg
    |  _           -> never_returns @@ failwith "Unexpected error."
  in

  begin if List.is_empty config.gpio_ids then
    never_returns @@ failwith "No --gpio specified"
  end ;

  loop (open_files config.gpio_ids) callback ;

  exit 0
