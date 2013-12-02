(* Take a dir repository and make a list of meta and write in into list.
   return Some (pathfile, t) if this is already a metafile
   return None if it's not a meta file
   don't list temporary file ("*~")
 *)
let log_metafiles = Log.create (Filename.concat ".." "process_write_metafile.log")
let number_of_index = ref 0

(*let create_write_metafile_r pathfile size path_metafile =*)
let create_write_metafile_r rootpath file_relpath size list_path =
  number_of_index := !number_of_index +1;
  let pathfile = rootpath ^ file_relpath in 
  let path_metafile = list_path ^ file_relpath ^ ".idx" in
  let l = String.length pathfile in
  match pathfile.[l-1] with
  | '~' -> None
  | _ ->
      let meta = Meta.create_if_not_meta_file size pathfile in
      match meta with
      | Meta.Already t -> 
          Log.output_endline log_metafiles ["metafile : " ; pathfile]; 
          Log.output_endline log_metafiles ["  " ; Meta.to_string t];
          Some ( pathfile, t, rootpath, file_relpath, list_path ) (* it's a metafile *)
      | Meta.Meta meta_value -> 
          Log.output_endline log_metafiles ["regular file : " ; pathfile];
          Log.output_endline log_metafiles ["  " ; Meta.to_string meta_value];  
          Meta.write_or_update meta_value path_metafile ; None

(*
  Take a full directory dir, and tranform it in metafile wrote into list_path
  If a metafile already exist it is update if the size is ok
  return the list of meta file present outside of ./list
  TODO: limit to 100 the number of path per metafile ?
*)
let write_list_meta_file list_path dir =
  let f path size =
(*
    print_endline ("list_path : " ^ list_path);
    print_endline ("path : " ^ path);
    print_endline ( list_path ^ path ) ;
    print_endline ( Int64.to_string size );*)       
    create_write_metafile_r  dir.Dir.root path size list_path  
  in
  let res = Dir.map_some_file_list f dir in
  Log.close log_metafiles;
  res

let int64_to_humain_readable_byte i =
  let r = Int64.to_float i in
  Printf.sprintf "%.2f MiB" (r /. (1024. *. 1024. )) 

(* print the needed size what ever copy are or will be done*)
let file_list_size file_list =
  let rec f (acc:Int64.t) file_list =  
      match file_list with
        | [] -> acc
        | (_, meta, _, _, _)::tl -> 
            f ( Int64.add acc ( Meta.get_size meta ) ) tl
  in
  f 0L file_list

(* Take a list of meta file with it's path,
   Try to find an existing file inside the path list
   Copy the file beside the metafile with filename~
   Remove "filename" and rename "filename~" in "filename"
   Update the "./list" with the meta file
   Print the size of the meta file that can't be replaced by real file
*)
let number_of_copied_files = ref 0
let number_of_files_not_found = ref 0
let log_cp = Log.create (Filename.concat ".." "process_write_cp.log")
let write_cp_file_list file_list =
  let rec f (acc:Int64.t) file_list =  
      match file_list with
        | [] -> Log.output_endline log_cp ["end of process"];acc
        | (metafile_path, meta, rootpath, file_relpath, list_path)::tl -> 
            Log.output_endline log_cp [metafile_path];
            let org_path_list = 
              Meta.get_valid_path_list meta in 
            match org_path_list with
              | [] -> 
                  Log.output_endline log_cp ["  File not found "; "\n  "; (Meta.to_string meta)];
                  print_endline ( " File not found " ^ (Meta.to_string meta) );
                  number_of_files_not_found := !number_of_files_not_found +1;
                  f ( Int64.add acc ( Meta.get_size meta ) ) tl
              | _ -> let org_path = List.hd org_path_list in
                     (*take the basename inside the index file, the true name of the index file does not matter*)
                     let path = Filename.concat 
                       (Filename.dirname metafile_path) 
                       (Filename.basename org_path) in
                     (*print_endline (":::" ^ metafile_path);
                     print_endline (":::" ^ org_path);
                     print_endline (":::" ^ path);*)
                     Log.output_endline log_cp 
                       ["  cp "; org_path; " "; path ; "# size ="; Int64.to_string( Meta.get_size meta )];
                     (
                       try                         
                         let size = Filecopy.cp_or_continue org_path path in
                         number_of_copied_files := !number_of_copied_files +1;
                           (*create metafile into ./list*)
                         let metafile_listpath = list_path ^ file_relpath in
                         let alone = Meta.create size [path] in 
                         let new_meta = Meta.merge_update meta alone in
                         Meta.write new_meta metafile_listpath;
                         (*remove the metafile from the normal dir*)
                         (try Sys.remove metafile_path with _ -> ()); 
                       with Unix.Unix_error(e,s1,s2) 
                           -> print_string (Unix.error_message e);
                             print_endline ( " with " ^ s1 ^ " " ^ s2)
                     );
                     f acc tl
  in
  let total_size = f 0L file_list in
  Printf.printf " %i copie(s) done, index updated\n" 
    !number_of_copied_files ;
  
  print_endline (String.concat " " [ "";
    string_of_int !number_of_files_not_found;
    "copies failed"; 
    int64_to_humain_readable_byte total_size;
    "missing" 
  ])
