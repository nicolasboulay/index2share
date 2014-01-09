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
mkdir -p build/index/win/bin &&
mkdir -p build/index/win/sum &&
mkdir -p build/index/linux/bin &&
mkdir -p build/index/linux/sum &&
mkdir -p build/index/doc/ &&

cp -rp index build/index/linux/bin/ &&

cp -rp index.exe build/index/win/bin/ &&
cp -rp runme.bat build/index/ &&
cp -rp README.txt build/index/doc/ &&
cd build/ &&
sha512sum ./index/linux/bin/index > ./index/linux/sum/index.sha512 &&
sha1sum   ./index/linux/bin/index > ./index/linux/sum/index.sha1 &&
sha512sum ./index/win/bin/index.exe > index/win/sum/index.exe.sha512 &&
sha1sum   ./index/win/bin/index.exe > index/win/sum/index.exe.sha1 &&
tar -cf ../index.tar * &&
tar -czf ../index.tar.gz * &&
rm ../index.zip &&
zip -qr ../index.zip * &&
cd .. &&
rm index.tar.xz &&
xz index.tar
