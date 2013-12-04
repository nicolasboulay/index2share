type t 
type filetype = Meta of t | Already of t
val create : Int64.t -> string list -> t

val write : t -> string -> unit
val read : string -> t option

val write_or_update : t -> string -> unit
val create_if_not_meta_file: Int64.t -> string -> filetype
val get_valid_path_list: t -> string list
val get_size : t -> Int64.t
val to_string : t -> string

val merge_update : t -> t -> t
val write : t -> string -> unit

val number_of_new_index : int ref
val number_of_updated_index : int ref
val is_dot_idx_filename: string -> bool
