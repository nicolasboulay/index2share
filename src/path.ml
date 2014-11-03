(** a path with type which is not a simple string, for static check*)

type dir_path_names = string list  
type abs_dir = dir_path_names 
type relative = Current | Index
type rel_dir = relative * dir_path_names 
type dir = Abs of abs_dir | Rel of rel_dir
type abs_file = abs_dir * string
type rel_file = rel_dir * string
type file = Abs of abs_file | Rel of rel_file
type path = | Dir of dir (*/!\ very few case where both possibility are mainingfull, to be deleted ?*)
            | File of file

(*a generic string.fold_left*)
let buffer= Buffer.create 270
let string_fold_left f (s:string) =
  let acc = ref [] in
  for i = 0 to String.length s - 1 do 
    acc := f !acc (String.unsafe_get s i) ;
  done;
    !acc

(*dir_sep a char, not a string*)
let dir_sep = 
  let s = Filename.dir_sep in
  String.unsafe_get s 0

let abs_dir_to_string dir =
  String.concat Filename.dir_sep (List.rev dir)

(*convert /plop/plip in ["plip";"plop"]*)
let extract_dir_name dir_string =
  Buffer.reset buffer;
  let f_ acc c =
    match c with
      | c when c = dir_sep  
          -> let s = Buffer.contents buffer in  
             Buffer.reset buffer;
             s :: acc;
      | _ -> Buffer.add_char buffer c; acc
  in
  let dir_list = string_fold_left f_ dir_string in
  match Buffer.length buffer with
    | 0 -> dir_list
    | _ ->
        let s = Buffer.contents buffer in  
        s :: dir_list

let create_abs_dir dir_string =
 (* Buffer.reset buffer;*)
  let filter_ current acc =
    match current, acc with
      | ".", [] -> extract_dir_name (Unix.getcwd()) 
      | ".", _ -> acc
      | "..",_ -> List.tl acc
      | _ -> current :: acc
  in
  let dir_list = extract_dir_name dir_string in
  let start = 
    match Filename.is_relative dir_string with
      | true -> extract_dir_name (Unix.getcwd()) 
      | false -> []
  in
  let dir_list_filtered = List.fold_right filter_  dir_list start in
  dir_list_filtered

let concat_abs_dir_to_string dir_path name =
  name :: dir_path

let concat dir rel_file = ()
let add_suffix file sfx = ()
let remove_suffix file = ()

let read file = ()
let write file data_list = ()

(*type t = {str: string option; split : string list }


let set p =
  { 
    str = None;
    split = p;
  }

let to_string t =
  match t with
    | { Null, } String
  
*)
(*
int mkpath(const char *path, mode_t mode)
{
    char           *pp;
    char           *sp;
    int             status;
    char           *copypath = STRDUP(path);

    status = 0;
    pp = copypath;
    while (status == 0 && (sp = strchr(pp, '/')) != 0)
    {
        if (sp != pp)
        {
            /* Neither root nor double slash in path */
            *sp = '\0';
            status = do_mkdir(copypath, mode);
            *sp = '/';
        }
        pp = sp + 1;
    }
    if (status == 0)
        status = do_mkdir(path, mode);
    FREE(copypath);
    return (status);
}
*)

(* like mkdir -p create all subdirectory if needed*)
let zero =  char_of_int 0
let mkdirp path =
  if not Command_line.option.Command_line.neutral then (
    let s = String.copy path in
    let rec f j =
      try
        let i = String.index_from s j (Filename.dir_sep).[0] in
        s.[i] <- zero;
        let _ = 
          try      
            Unix.mkdir s 0o777;
          with _ -> () in
        s.[i] <- (Filename.dir_sep).[0];
        f (i+1)
      with Not_found -> Unix.mkdir s 0o777
    in       
    try
      f 0
    with _ -> ()
  )
(*
let _ = Unix.handle_unix_error ( Unix.mkdir s ) 0o750 in
()
*)
