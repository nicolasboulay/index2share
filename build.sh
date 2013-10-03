#update version number
if [[ $(git diff) ]]; then
    echo update version...
    perl version.pl < version.ml > version.new &&
    cp -f version.new version.ml 
else
    echo no update version
fi

./make

# make distribution
echo build... 
rm -rf build/ &&
mkdir -p build/index_ &&
cp -rp index build/ &&
cp -rp index.exe runme.bat build/ &&
cp -rp README.txt build/index_/ &&
cd build/ &&
sha512sum index > index_/index.sha512 &&
sha1sum index > index_/index.sha1 &&
sha512sum index.exe > index_/index.exe.sha512 &&
sha1sum index.exe > index_/index.exe.sha1 &&
tar -cf ../index.tar * &&
tar -czf ../index.tar.gz * &&
cd ..
rm index.tar.xz
xz index.tar
