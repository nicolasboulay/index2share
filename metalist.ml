(** 
    main
*)

let main () =   
  let start_time = Sys.time () in

  (** GC tweek, speed vs memory*)
  Gc.set { (Gc.get()) with Gc.allocation_policy = 1};
  (
    match Command_line.option.Command_line.lowmem with
      | true -> () (*default value*)
      | false -> Gc.set { (Gc.get()) with Gc.space_overhead=100000; }; (*use ~ 8 times more memory but 15% faster*)
  );

  (** root and list path calculation*)
  let root_path = Path.create_abs_dir Command_line.option.Command_line.root in
  let list_path = Path.concat_abs_dir_to_string root_path "list" in
  let list_dir = Path.abs_dir_to_string list_path in
  let root_dir = Path.abs_dir_to_string root_path in

  (** ./list creation if needed *)
  ( try
      Unix.mkdir list_dir 0o744
    with _ -> ()
  );

  print_endline ( "directory : \'" ^ root_dir ^ "\'");
  print_endline ( " index directory : \'" ^ list_dir ^ "\'");

  (** Read the whole tree of root *)
  let (dir,n) = Dir.create root_dir in  
  Printf.printf " %i files scanned\n" n;
  Dir.log dir ( Filename.concat ".." "dir_create.log" ) ;

  (** extraction of ./list from the rest *)  
  let (lst,root) = Dir.partition dir (Filename.dir_sep ^ "list") in
  let (_,root) = Dir.partition root (Filename.dir_sep ^ "$RECYCLE.BIN") in (* The windows recycle bin *)
  Dir.log lst ( Filename.concat ".." "dir_lst.log" ) ;
  Dir.log root ( Filename.concat ".." "dir_root.log" ) ;

  (** metafile creation for root *)
  (*-> creation of the meta file, if it's not already a meta file (to be copied later)
    save of the meta file inside ./list
    if the meta file exist, and have the same size, update it or do nothing
  *)
  print_endline "Index directory management";
  let cp_file_list = 
    Process.write_list_meta_file list_dir root in

  Printf.printf 
    " %i new index\n %i index updated (path added)\n %i files in directory ( outside of index directory )\n" 
    !Meta.number_of_new_index !Meta.number_of_updated_index !Process.number_of_index;

  let cp_size = Process.file_list_size cp_file_list in
  let l = (List.length cp_file_list) in
  print_endline "Size management";
  Printf.printf " %i cop" l;
  if  l != 0 
  then 
    (Printf.printf "ies to do (%s):\n" (Process.int64_to_humain_readable_byte cp_size)   )
  else print_string "y to do\n";

  (*Replace all metafile outside of ./list by the real file using *~ as temporary name
    if the file does not exist add there size.
  *)
  print_endline "Copy management";
  Process.write_cp_file_list cp_file_list;

  let end_time = Sys.time () in

  Printf.printf "Elapsed time : %.2f s.\n" (end_time -. start_time) 

let _ =  
  try 
    main ()
  with Unix.Unix_error(e,s1,s2) 
      -> print_string (Unix.error_message e);
        print_endline ( " with " ^ s1 ^ " " ^ s2)
