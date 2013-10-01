(** Special code for windows : finding usb key **)

(* generate (a:\,a) to (z:\,z) *)
let letters = 
   let s = "a:\\" in
   let create a =
     String.set s 0 (char_of_int a);
     String.copy s
   in
   let a = int_of_char 'a' in
   let rec f acc i =
     if i < (a+26) then
       f ((create i, char_of_int i) :: acc) (i+1)
     else 
       acc
   in
   let  l = List.rev (f [] a) in
   l

(**generate [('c', "Windows" ); ('c'; "Mes Documents"); ('e'; "plop")...]**)
let gen_content_reference () =
   let f_ acc (f,c) =
     let dirs = Array.to_list (Sys.readdir f) in
     let g_ acc d =
       (c, d) :: acc
     in
     List.fold_left g_ acc dirs
   in
   let db = List.fold_left f_ [] letters in
   db

let db = ref []

(**find the first directory of an absolute path*)
let copy_first_dir s =
  let start = String.index_from s 0 '\\'  in
  let fin = try
    String.index_from s (start + 1) '\\' 
      with Not_found -> (String.length s) (*no second '\\' use the end of the string*)
  in
  let len = fin - start -1 in
  let dst = String.create len in
  String.blit s (start+1) dst 0 len;
  dst

(**find a candidate for a path*)
let find_letter_candidate dir =
  let predicat (c,d) =
    d = dir
  in
  List.filter predicat !db

(**take a path, check if its inside the db, rewrite it*)
let rewrite_file (acc:string list) (path:string) : string list =
  (*print_endline path;*)
  let dir = copy_first_dir path in
  (*print_endline dir;*)
  let candidate_list = find_letter_candidate dir in
   (*List.iter (fun (c,d) -> print_char c;print_endline d ) candidate_list;*)
  let f acc (c,_) =     
     let s = String.copy path in
     (String.set s 0 c) ;
     s:: acc
  in
  List.fold_left f acc candidate_list

let file_exists p =
  try
    (*Sys.file_exists does not work for file > 2GB !*)
    Unix.access p [Unix.F_OK;Unix.R_OK];
    true
  with Unix.Unix_error _ -> false
      
let check_file path =
  let l = rewrite_file [] path in
  let s = List.find file_exists l in
  let to_c = String.get s 0 in
  let from_c = String.get path 0 in
  Printf.printf "%c: file found in %c: :\n" from_c to_c;
  s

(*rewrite a list of file*)
let try_rewrite_file absolute_filename_list =
  (if !db = [] then
    db := gen_content_reference ();
  );  
  (* List.rev (List.fold_left rewrite_file [] absolute_filename_list)*)
  let rec f_ l =
    match l with
    | [] -> []
    | path::tl ->
	try
	  [ check_file path ] 
	with Not_found -> f_ tl
  in
  f_ absolute_filename_list
(*
let _ = 
  List.iter print_endline ((try_rewrite_file ["c:\\plop"]));
  List.iter print_endline ((try_rewrite_file ["c:\\plop\\"]));
  List.iter print_endline ((try_rewrite_file ["e:\\Windows"]));
  List.iter print_endline ((try_rewrite_file ["e:\\Windows\\prout"]));
  List.iter print_endline ((try_rewrite_file ["e:\\Windows\\\\prout"]));
  List.iter print_endline ((try_rewrite_file ["e:\\Windows\\prout\\"]));
  List.iter print_endline ((try_rewrite_file ["e:\\Windows\\prout\\\\"]));
  List.iter print_endline ((try_rewrite_file ["e:\\Windows\\prout\\plop"]));
  List.iter print_endline ((try_rewrite_file ["e:\\Windows\\prout\\plop\\"]));
  List.iter print_endline ((try_rewrite_file ["e:\\Windows\\prout\\plop\\\\"]));

  List.iter print_endline ((try_rewrite_file ["e:\\Windows\\prout"; "e:\\Windows"; "a:\\Windows\\src\\"]));
*)
