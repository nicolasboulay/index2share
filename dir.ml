(**  directory tree data structure
 should kep track of all entry from a starting point
This should help to scan a hd quickly
*)

type dir_ = Dir of (string * (dir_ list)) | File of (string * int64) 
type dir = { dir:dir_; root:string }

type t = dir

(*extract a directory from an other one /!\ dirname start with dir_sep ! -> that's quite stupide*)
let partition t dirname =
  match t.dir with
    | Dir (rootname, dir_list) ->
        let predicat t =
          match t with 
            | Dir (dirname_, _) when dirname_ = dirname -> true
            | _ -> false
        in
        let (dir1,dir2) = List.partition predicat dir_list in
        { dir = Dir (dirname, dir1);
         root = Filename.concat t.root dirname }, 
        { dir = Dir (rootname ,dir2);
          root = t.root}
    | _ -> assert false

(*
let root = "../"
let dir_handle = Unix.opendir root 

let get_size filename =
  let stat = Unix.LargeFile.stat filename in
  stat.Unix.LargeFile.st_size
*)

let create_dir rootname =
  let n = ref 0 in
  let rec file_to_t dirname a filename =
    let fullname = String.concat Filename.dir_sep [rootname;dirname;filename] in
    let relname = String.concat Filename.dir_sep [dirname;filename] in
    try
      ( 
        let stat = Unix.LargeFile.stat fullname in
      (*print_endline ("file :" ^ fullname);*)
        match stat.Unix.LargeFile.st_kind with
          | Unix.S_REG 
            -> n := !n + 1;File ( relname, stat.Unix.LargeFile.st_size ) :: a
          | Unix.S_DIR 
            -> ( dir_to_t relname ) :: a 
          | Unix.S_LNK | _ -> a
      )
    with _ -> a (*a link that point to nowhere generate a file not found*)
  and dir_to_t dirname =
  (*print_endline ( "dir : " ^ dirname);*)
    let fullname = String.concat Filename.dir_sep [rootname;dirname] in
    let a = Sys.readdir fullname in
    let dirlist = Array.to_list a in
  Dir ( dirname, List.fold_left (fun a f -> file_to_t dirname a f )[] dirlist ) 
  in
  ({
    dir = dir_to_t "";
    root = rootname;
  }, !n)

let create root = Unix.handle_unix_error create_dir root 

let cd t dirname =
  let rec finddir cur s =
    let predicat dir =
      match dir with
        | Dir (name , _) ->  name = s
        | _ -> false
    in
    List.filter predicat cur
  in
  match t with
    | Dir (_, dirlist) -> finddir dirlist dirname
    | _ -> assert false
        
(*execute f on each file of the dir*)
let rec iter_file_list f dir=
  match dir with 
    | Dir (_, dir_list) -> List.iter (iter_file_list f) dir_list
    | File (filename, size) -> f filename size 

(*Execute f on every file of dir, keep value only if f return "Some v"*)
let map_some_file_list f dir =
  let rec map_file_list_ a dir  =
    match dir with 
      | Dir (_, dir_list) -> List.fold_left map_file_list_ a dir_list
      | File (filename, size) -> 
          let r = (f filename size) in
          match r with 
            | None -> a
            | Some v -> v :: a 
  in
  List.rev ( map_file_list_ [] dir.dir )

(* -------------------------------------------------------------- *)

let log t filename = 
  if Command_line.option.Command_line.trace then 
    (
      print_endline ( "Dir log :" ^ filename ) ;
      let o = open_out_bin filename in
      let p s = output_string o s in
      let rec log_ front t =
        match t with
          | Dir (dirname, dirlist) -> p front;  p dirname ; p "\n" ; List.iter ( log_ (front ^ "  " ) ) dirlist 
          | File (filename, size) -> p front; p filename; p " "; p ( Int64.to_string size ) ; p "\n" 
      in
      p t.root; p "\n";
      log_ " " t.dir;
      close_out o
    )
    
let print t = 
  let rec print_ front t =
    match t with
      | Dir (dirname, dirlist) -> print_endline (front ^ dirname) ; List.iter ( print_ (front ^ "  ") )dirlist 
      | File (filename, size) -> print_endline ( front ^ filename ^ " " ^ (Int64.to_string size))
  in
  print_endline t.root; 
  print_ " " t.dir

(*let test () = print (create "..")*)

(*let _ = test ()*)

(*let rec loop () = 
  try
    let s = (Unix.readdir dir_handle) in
    print_endline (s ^  " ___  " ^ (Int64.to_string (get_size s))) ;
    ignore(Array.map print_endline (Sys.readdir s)) ;
    loop()
  with _ -> ()

let tt () = 
  let a = Sys.readdir root in
  Array.map print_endline a

let _ = loop () ; tt ()
*)
