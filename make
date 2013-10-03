export OCAMLRUNPARAM=b
# ocamlcp with ocamlprof
# ocamlopt -p for gprof

files=("version.ml command_line.ml log.ml path.ml win.ml meta.mli meta.ml dir.ml filecopy.mli filecopy.ml process.ml metalist.ml") 

#compile
if [[ "$OSTYPE" == "linux-gnu" ]]; then
   #~/.wine/drive_c/OCaml/bin/ocamlc.exe unix.cma $files -o index.exe &&   
    echo linux build && 
    ocamlopt unix.cmxa $files -o index &&
    strip -s index &&
    ocamlopt -p -g  unix.cmxa $files -o index_debug &&
    ocamlcp -g unix.cma $files -o index_p 
else
    echo windows build &&
    ocamlopt.opt unix.cmxa $files -o index.exe &&
    strip -s index.exe
fi &&

#testing
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    echo test...
    cd test && ./rep.pl && cd ..
fi

