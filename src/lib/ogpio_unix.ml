
open Unix

let wait_ms time =
  ignore (select [] [] [] time)
