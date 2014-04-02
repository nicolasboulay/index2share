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
mkdir -p build/index2share/win/bin &&
mkdir -p build/index2share/win/sum &&
mkdir -p build/index2share/linux/bin &&
mkdir -p build/index2share/linux/sum &&
mkdir -p build/index2share/doc/ &&

cp -rp index2share build/index2share/linux/bin/ &&

cp -rp index2share.exe build/index2share/win/bin/ &&
cp -rp runme.bat build/index2share/ &&
cp -rp README.md build/index2share/doc/ &&
cp -rp i2s.jpg build/index2share/doc/ &&
cd build/ &&
sha512sum ./index2share/linux/bin/index2share > ./index2share/linux/sum/index2share.sha512 &&
sha1sum   ./index2share/linux/bin/index2share > ./index2share/linux/sum/index2share.sha1 &&
sha512sum ./index2share/win/bin/index2share.exe > index2share/win/sum/index2share.exe.sha512 &&
sha1sum   ./index2share/win/bin/index2share.exe > index2share/win/sum/index2share.exe.sha1 &&
tar -cf ../index2share.tar * &&
tar -czf ../index2share.tar.gz * &&
rm -f ../index2share.zip &&
zip -qr ../index2share.zip * &&
cd .. &&
rm index2share.tar.xz &&
xz index2share.tar &&
echo done
