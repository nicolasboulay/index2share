index2share
=====

index, choose and copy files

-----------

## Goals

Index2share is a tool that manages a 2 steps file copy, using index.
 
First, it create tiny files to represent the bigger files. User moves and sort 
this tiny files, as if it were the bigger one, but it's much faster than moving the orignal file.

Then the tiny file are replaced by the bigger one in a batch.

The tiny files could be given to another user, as list of files of interest.

There is no internet/network communication. It has almost no command line options.
![alt
text](https://github.com/adam-p/markdown-here/raw/master/src/common/images/icon48.png
"Logo Title Text 1")

## GUI under windows

GUI is simple, you could double clic on the runme.bat, if the
installation file are copied at the base of a bunch of file. The
program will run, and a console with all the action done are
displayed.

In the futur, index could be include inside the file navigator. 

##INSTALL

The executable file have no dependancies. The package is designed to be copied at the root of removable drive. 
When run by double clicking on runme.bat under windows, the program will run on the removable drive, to manage it.

The content of the ./index_/ directory should be also copied, to have some information to check if the binaries 
have been modified, to avoid malware.

##MANIFEST of compressed archive

<root to index> 
└── index2share
    ├── doc
    │   └── README.md # this file
    ├── linux
    │   ├── bin
    │   │   └── index2share # Linux 32 bit executable
    │   └── sum # hash for integrity checking
    │       ├── index2share.sha1
    │       └── index2share.sha512
    ├── runme.bat # Windows batch file that launch index2share.exe then a pause, to be able to read the output of the program
    └── win
        ├── bin
        │   └── index2share.exe # Windows 32 bits executable
        └── sum # hash for integrity checking
            ├── index2share.exe.sha1
            └── index2share.exe.sha512

##OPTIONS

The working directory, by default is ".".

[--lowmem] enable to use no garbage collection tweaking : slower (-15%) but use less memory (/8).

##Example
###WINDOWS EXAMPLE

Alice has many usb keys with many files on it. Bob wants some of these files, but Alice cannot give her keys to Bob. 
Index program will create .idx file to enable Bob to choose files with the file explorer. Then Alice will re-run 
index program, to finish a copie.

* Alice copies all the files of the install in the base of each removable drive, ( example, e:\).
* Alice double clics on e:\index2share\runme.bat. 
  e:\list\ content is created, with an .idx file for each file present in e:, with the directories recreated. 
  .idx file contains the path of the real file.
* Alice copy the e:\list\ in its document directory.
* Alice remove the removable drive, Alice do the previous steps for every usb key.
* Alice gives all .\list directories to Bob, written in an usb key, in e:\list\.
* Bob copies the index program files, in an empty usb key.
* Bob copies the few .idx files, in the usb key. Bob could move and organize .idx file as if it was the real file.
* Bob double clics on e:\runme.bat.
  .idx file are recognized, original files are not found (it's normal, the files are not present),
  the total sized necessary is displayed. Bob checks, if its usb key will have enough free space.
* Blob gives its key to Alice.
* Alice plugs her usb keys and the Bob's key (in e:\).
* Alice double clics on e:\runme.bat, the .idx file will be replaced by the original file from the keys.
* Alice gives back his key to Bob.

###LINUX EXAMPLE

Some Linux distribution removes execution right from removable drive, for security reasons. In that cases, the use of the program will  
use the directory as option.

* Alice copies all the files of the install in a removable disk (for example in /media/CORSAIR16G/)
* Alice copies all the files of the install in an executable directory
* [Alice] $ index2share /media/CORSAIR16G/
  44 new index have been created in the index directory.
* [Alice] $ cp /media/CORSAIR16G/list/* ~/idx/
* [Alice] $ tar -cvzf idx.tar.gz ~/idx
* idx.tar.gz is given to Bob.
* [Bob] $ cp plop.txt.idx /mnt/SONY4G/
* [Bob] $ index2share /mnt/SONY4G/
  There is 64419 byte ( 0.06 MiB ) of 1 unreplaced .idx file(s) by the original.
* Bob gives his key to Alice, and Alice run index :
* [Alice] $ index2share /mnt/SONY4G/
  plop.txt 20.48 MiB/s
  1 files have been effectively copied.
* Alice gives back, his key to Bob.

## Inside

###.IDX FILE FORMAT

The .ifx file contains a 4 kinds of elements, each elements are separate line by line.

* "IndexFile" a 'magic' string
* A file version number to identify this format ("1")
* file size in byte
* A list of absolute path, one by line

###PERFORMANCE

The program is fast but use lot of memory. It could index 30 000 files
in less than 3s, using around 250MB. 
When a file is copied, the limit is the slower drive. Usb key could be
slow. 
For each file, the directory have been explored, the size of file is taken, an .idx 
file is created or updated. 

### Build
#### files content

* *.ml ocaml file
* *.mli ocaml interface file
* make* sh script to create binaries
* version.pl perl script to update build version 
* build.sh sh script to make a release
* README.txt the end user "manual"
* runme.bat batch script for windows execution to see console output


#### tool Dependancies

* sh script
* perl script
* sha1sum, sha512sum
* ocaml 
