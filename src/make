export OCAMLRUNPARAM=b

source ./files

#compile
if [[ "$OSTYPE" == "linux-gnu" ]]; then
   #~/.wine/drive_c/OCaml/bin/ocamlc.exe unix.cma $files -o index2share.exe &&   
   ./make_unix &&
    # debug with -g and profiling with ocamlopt -p for gprof 
    ocamlopt -p -g  unix.cmxa $files -o index2share_debug &&
    # profiling with ocamlcp with ocamlprof
    ocamlcp -g unix.cma $files -o index2share_p 
else
    ./make_win
fi 

#testing
#if [[ "$OSTYPE" == "linux-gnu" ]]; then
#    echo test...
#    cd test && ./rep.pl && cd ..
#fi

