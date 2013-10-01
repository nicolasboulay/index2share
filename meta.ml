(* meta file is an index of real file
   it's written inside the ./list directory
   be careful to not mix t.path and path of the metafile 
*)

type t =  { size : Int64.t ; path : string list }

(*create a meta object with it's size and a path*)
let create s p =
  let f path =
    match Filename.is_relative path with
      | true -> Filename.concat ((Sys.getcwd () )) path
      | false -> path
  in
  { 
    size = s;
    path = List.map f p 
  }

(*Include e in list if e is not already present*)
let uniq e list =
  let predicat a =
    a = e
  in 
  match List.filter predicat list with
    | [] -> e :: list
    | _ -> list
      
(*
  merge 2 meta file : this happen when the same file came from 2 different directory, 
  this is the case at each copie of a real file
  path are classed by alphabetical order
*)
let merge_update old new_ =
    { 
      new_ with (* keep the latest size*)
      path = List.sort compare (uniq (List.hd new_.path) old.path )
    }

(*
  this is used to encode real path into metafile, metafile structure are line by line,
  so "\n" must be encoded (it's valid inside a path)
  \n -> #n
  # -> ##
*)
let buffer= Buffer.create 270

let encode s =
  if String.contains s '#' then (
    if String.contains s '\n' then (
      Buffer.clear buffer;
      let encode_ c =
        match c with
          | '#' -> Buffer.add_string buffer "##"
          | '\n' -> Buffer.add_string buffer "#n"
          | _ -> Buffer.add_char buffer c
      in
      String.iter encode_ s ;
      Buffer.contents buffer
    ) else s      
  ) else s

let decode s =
  if String.contains s '#' then (
    let length = String.length s in 
    Buffer.clear buffer;
    let rec decode_ i =
      match i with 
        | j when i = length - 1 -> Buffer.add_char buffer s.[i]       
        | j when i > length - 1 -> ()
        | _ -> 
            match s.[i], s.[i+1] with
              | '#', '#' -> Buffer.add_char buffer '#';decode_ (i+2)
              | '#', 'n' -> Buffer.add_char buffer '\n';decode_ (i+2)
              | c, _ -> Buffer.add_char buffer c;          decode_ (i+1)
    in
    decode_ 0 ;
    Buffer.contents buffer 
  ) else
    s

(*/!\ keep retro compatiblity of existing file in case of format evolution*)
let magic_number = "IndexFile"
let version = "1"

(*write each string with a "\n" of string_list into filename*)
let write_string_list string_list filename =
  (*print_endline filename;*)
  let _ = Path.mkdirp ( Filename.dirname filename ) in
  let _out = open_out filename in
  let w s = output_string _out s ; output_string _out "\n" in
  List.iter w string_list;
  close_out _out

(*dump a data structure of meta into a file*)
let write t filename =
  let strings = [
    magic_number;
    version;
    Int64.to_string t.size;
  ] @ (List.map encode t.path) 
  in
  write_string_list strings filename  

(*put into a list of line the content of ic*)
let read_ic ic =
  try 
    (let lines = ref [] in
     try
       while true do
         let line = input_line ic in
         lines := line :: !lines
       done; assert false
     with End_of_file -> close_in ic ; 
       List.rev !lines
    )
  with _ -> []

let fast_read ic =
  ignore(input_line ic) ;
  let second_line = input_line ic in
  if ( second_line = version) then (
    try
      (
        let size = Int64.of_string (input_line ic) in
        let path_list = read_ic ic in
        Some {
          size = size ;
          path = List.map decode path_list ;
        } 
      ) with _ -> None
  ) else None

(*
  read a file and create a meta object
  quickly check if a file is a metafile : very performance sensitive operation
  then quickly read the file, this is also time sensitive.
*)
let golden_value = magic_number 
let golden_value_length = String.length golden_value
let buf = String.create golden_value_length 

let read filename =
  try  
    let l = String.length filename in
    let s = filename in
    if ( s.[l-3] = 'i' & s.[l-2] = 'd' & s.[l-1] = 'x' ) then (
      let ic = open_in filename in
      really_input ic buf 0 golden_value_length;
      if buf = golden_value then 
        (let r = fast_read ic in
         close_in ic;
        r)
      else 
        (close_in ic; None)           
    ) else 
      None
  with _ 
      -> None

let number_of_new_index = ref 0
let number_of_updated_index = ref 0

(*if the file does not exist "write t", if the file exist (same size) update it*)
let write_or_update t filename =
  let r = read filename in     
  match r with
    | None -> number_of_new_index := !number_of_new_index + 1; 
        write t filename
    | Some t1 -> let tt = merge_update t1 t in
                 if tt <> t1 then (
                   number_of_updated_index := !number_of_updated_index + 1; 
                   write tt filename )

let come o =
  match o with 
    | None -> assert false
    | Some v -> v

(*use to qualify a bunch of file, with the data inside*)
type filetype = 
  | Meta of t    (* the meta information are computed for the file*)
  | Already of t (* the file is a metafile *)

(*create the meta file of a file or return file if it's 
 already a meta file *)
let create_if_not_meta_file size path=
  let t = read path in 
  match t with
    | None -> Meta ( create size [path] )
    | Some t -> Already t 

let get_valid_path_list t =
  let f p =
    try
      (*Sys.file_exists does not work for file > 2GB !*)
      Unix.access p [Unix.F_OK;Unix.R_OK];
      true
    with Unix.Unix_error _ -> false
  in
  try
    [ List.find f t.path ]
  with Not_found -> 
    match Sys.os_type with 
    | "Win32" -> let l = Win.try_rewrite_file t.path in
      (try 
	[ List.find f l ]
      with Not_found -> []	  
      )
    | _ -> []

let get_size t =
  t.size

let to_string t =
  String.concat "" [ 
    Filename.basename ( List.hd t.path ) ; "  ";
    Int64.to_string t.size;   
  ]
    
