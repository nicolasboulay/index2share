
type t = {
  trace: bool; (** trace*)
  help: bool; 
  lowmem: bool; 
  root: string;
}

(** the default value of each function*)
let option_default = try {
  trace = false;
  help = false;
  lowmem = false;
  root = Unix.getcwd();
} with Unix.Unix_error(e,s1,s2) 
    -> print_string (Unix.error_message e);
      print_endline ( " with " ^ s1 ^ " " ^ s2);
      exit (-1)

let print t =
  match t.trace with
    | true -> print_endline ("index --trace " ^ t.root)
    | false -> print_endline ("index " ^ t.root)

let parse_argv argv0 =
  let argv0_list = Array.to_list argv0 in
  let rec parse_ option argv =
    match argv with
    | "--help"::tl | "-h"::tl -> 
          parse_ { option with help = true } tl    
    | "--trace"::tl -> parse_ { option with trace = true } tl    
    | "--lowmem"::tl ->   
        parse_ { option with lowmem = true } tl    
    | "--"::dir::tl -> parse_ { option with root = dir } tl    
    | dir::tl -> parse_ { option with root = dir } tl    
    | [] -> option
    
  in
  let option = parse_ option_default (List.tl argv0_list) in
  (*print option;*)
  option


let option = 
  let o = parse_argv Sys.argv in
  (** help line printed *)
  let s = (Filename.basename Sys.argv.(0)) ^ 
    " V" ^ (string_of_int Version.major) ^
    "." ^ (string_of_int Version.release) ^
    "." ^ (string_of_int Version.version) in
  let _ = print_endline s in
  if o.help then 
    (print_endline 
      ("usage : " ^ (Filename.basename Sys.argv.(0)) ^ " [--lowmem] [root path]");
    print_endline
    ("'" ^ o.root ^ "' file directory are read.\n" ^
    "Index file listing 'list/' are created or updated.\n" ^
    "Index file not present in the 'list/' directory are replaced by the file they point to" ^ 
    " if possible.\n" ^
    "The size of none replaced index file are printed.\n" ^
    "The indexes should be copied, with this executable."); 
    exit 0)
  else o

