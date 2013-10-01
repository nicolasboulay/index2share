(** Log for debugging of internal data structure *)

let create filename =
  if Command_line.option.Command_line.trace then (
    print_endline ( "log :" ^ filename ) ;
    Some (open_out_bin filename)
  ) else None

let close t =
  match t with
    | Some o -> close_out o
    | None -> ()

let output_endline t string_list =
  match t with 
    | Some o ->
        List.iter (output_string o ) string_list;
        output_string o "\n";
    | None -> ()
