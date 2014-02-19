(** For copy, also manage continuing copy *)

(*let t0 = ref  0.0

let init_t0 () =
  if (0.0 = !t0) then ( t0 := Sys.time () ) 

let tick () =
  let t1 = Sys.time () in
  let delta = (t1 -. !t0) in
  t0 := t1;
  delta
*)
let init_timer () = 
  Sys.time () 

let delta_timer t0 =
  let t1 = Sys.time () in
  let delta = (t1 -. t0) in
  delta, t1

let throttle f t0 =
  let delta, t1 = delta_timer t0 in
  (*Printf.printf "%f %f\n" (t0)(t1);*)
  if delta >= 0.1  then
      (f (); t1)
  else t0
      
let stride = 15*1024*1024 

let s = String.create stride

let abstract_cp name h_in h_out length packet_cp =
  let tstart = init_timer () in
  let stride_ = Int64.of_int stride in 
  let rec tran (remaining:Int64.t) (before:Int64.t) t0=
      let nb:Int64.t = min stride_ remaining in
        (*print_endline (";;" ^(Int64.to_string nb));*)
      match nb with 
        | i when ( i > 0L ) -> (
          let n = packet_cp h_in h_out i in
          ( match n with
            | i when i = 0 -> before (*in case that the input file is too small*)
            | _ ->
                let (r:Int64.t) = Int64.sub remaining  (Int64.of_int n) in 
                let after = Int64.add before (Int64.of_int n) in
                let f () = 
                  let after_f = ((Int64.to_float after) /. (1024. *. 1024. )) in
                  let delta = (init_timer () -. tstart) in
                  ( if delta = 0. then ( 
                    Printf.printf "\r%s %.2f MiB" name after_f)
                  else
                    let bd = after_f /. delta in
                    Printf.printf "\r%s %.2f MiB %.1f MiB/s" name after_f bd
                  );
                  flush stdout (*slowdown the copy of 20% with the flush !*)
                in
                let t0 = throttle f t0 in

                tran (r) after t0
          )
        )
        | _ -> before
  in
  tran length Int64.zero (init_timer())

let unix_file_get_size file =
  let stat = Unix.LargeFile.stat file in
  let length = stat.Unix.LargeFile.st_size in
  length

let transfer name _in _out length =
  let f h_in h_out i =
    let n = Unix.read _in s 0 (Int64.to_int i) in
    ignore (Unix.single_write _out s 0 n ); n
  in
  let n = abstract_cp name _in _out length f in
  Unix.close _out;   
  Unix.close _in;
  (*length*)
  n

let cp src dst =
  let name = Filename.basename src in
  let _out = Unix.openfile dst [Unix.O_WRONLY; Unix.O_CREAT; Unix.O_TRUNC] 0o600 in
  let _in  = Unix.openfile src [Unix.O_RDONLY] 0o600 in
  let length = unix_file_get_size src in
  transfer name _in _out length 

let continue src dst =
  let name = Filename.basename src in
  let l = unix_file_get_size dst in
  let _out = Unix.openfile dst [Unix.O_WRONLY; Unix.O_APPEND] 0o644 in
  let _in  = Unix.openfile src [Unix.O_RDONLY] 0o644 in
  let length = unix_file_get_size src in
  (*print_endline (Int64.to_string l);*)
  ignore(Unix.LargeFile.lseek _in l Unix.SEEK_SET) ;
  transfer name _in _out length 

(*let t0 = ref 0.0

let init_t0 () =
  if (0.0 = !t0) then ( t0 := Sys.time () ) 

let tick () =
  let t1 = Sys.time () in
  let delta = (t1 -. !t0) in
  t0 := t1;
  delta
*)
let cp_or_continue src dst =
  let tmp = dst ^ "~" in
  let length = 
    ( match 
        try
          Unix.access tmp [Unix.F_OK;Unix.W_OK];true
        with _ -> false
      with
        | false -> cp src tmp 
        | true -> continue src tmp
    ) in
  (try 
    Sys.remove dst  (*mandatoy under windows*)
  with _ -> ( Printf.printf "\n%s can't be replaced." dst; (*could failed if dst is a repository*) 
	      exit 1;)
  );
  Sys.rename tmp dst;
    (*let delta = tick () in
      (if delta = 0. then 
      Printf.printf " (a lot of) MiB/s\n" 
      else
      Printf.printf " %.2f MiB/s\n" ((Int64.to_float length) /. delta /. (1024. *. 1024. ))
      );*)
  length

