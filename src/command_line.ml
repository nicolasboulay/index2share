
type t = {
  trace: bool; (** trace*)
  help: bool; 
  lowmem: bool; 
  neutral: bool;
  verbose: bool;
  root: string;
}

(** the default value of each function*)
let option_default = try {
  trace = false;
  help = false;
  lowmem = false;
  neutral = false;
  verbose = false;
  root = Unix.getcwd();
} with Unix.Unix_error(e,s1,s2) 
    -> print_string (Unix.error_message e);
      print_endline ( " with " ^ s1 ^ " " ^ s2);
      exit (-1)

let print t =
  match t.trace with
    | true -> print_endline ("index2share --trace " ^ t.root)
    | false -> print_endline ("index2share " ^ t.root)

let parse_argv argv0 =
  let argv0_list = Array.to_list argv0 in
  let rec parse_ option argv =
    match argv with
    | "--help"::tl | "-h"::tl -> 
          parse_ { option with help = true } tl    
    | "--trace"::tl -> parse_ { option with trace = true } tl    
    | "-n"::tl -> parse_ { option with neutral = true } tl    
    | "-v"::tl -> parse_ { option with verbose = true } tl    
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
      ("usage : " ^ (Filename.basename Sys.argv.(0)) ^ " [--lowmem] [-n] [root path]");
    print_endline
    ( "-n : blank run, nothing modified\n" ^
      "'" ^ o.root ^ "' file directory will be indexed.\n" ^
      ".idx file directory 'list/' will be created or updated.\n" ^
    ".idx file not present in the 'list/' directory are replaced by the file they point to," ^ 
    " if possible.\n" ^
    "The size of none replaced .idx file are printed."); 
    exit 0)
  else o

