#!/bin/sh

#  build_poco_macos.sh
#
#

#===============================================================================
# Functions
#===============================================================================

abort()
{
echo
echo "Aborted: $@"
exit 1
}

doneSection()
{
echo
echo "    ================================================================="
echo "    Done"
echo
}
witeMessage()
{
echo
echo "    ================================================================="
echo "    $1"
echo "    ================================================================="
echo
}
#===============================================================================


POCO=$1
POCO_VERSION=$2

buildFramework()
{
DEBUG=$1
if [ "$DEBUG" == 'DEBUG' ]; then
echo "Will be building a DEBUG framework..."
DEBUG='d'
elif [ "$DEBUG" == 'RELEASE' ]; then
echo "Will be building a RELEASE framework..."
DEBUG=''
else
echo "You need to choose DEBUG or RELEASE as first param to buildFramework()"
exit 1
fi

VERSION_TYPE=Alpha
FRAMEWORK_NAME=Poco
FRAMEWORK_VERSION=A


FRAMEWORK_CURRENT_VERSION=$POCO_VERSION
FRAMEWORK_COMPATIBILITY_VERSION=$POCO_VERSION

CURRENT_DIR=${PWD}
FRAMEWORKDIR=$2/Darwin/framework
PATH_T0_LIBS=$2/Darwin/x86_64

FRAMEWORK_BUNDLE=$FRAMEWORKDIR/$FRAMEWORK_NAME.framework

rm -rf $FRAMEWORK_BUNDLE

witeMessage "Framework: Creating $FRAMEWORK_NAME framework"

witeMessage "Framework: Setting up directories..."
mkdir -p $FRAMEWORK_BUNDLE
mkdir -p $FRAMEWORK_BUNDLE/Versions
mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION
mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/Resources
mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/Headers
mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/Documentation

witeMessage "Framework: Creating symlinks..."
ln -s $FRAMEWORK_VERSION               $FRAMEWORK_BUNDLE/Versions/Current
ln -s Versions/Current/Headers         $FRAMEWORK_BUNDLE/Headers
ln -s Versions/Current/Resources       $FRAMEWORK_BUNDLE/Resources
ln -s Versions/Current/Documentation   $FRAMEWORK_BUNDLE/Documentation
ln -s Versions/Current/$FRAMEWORK_NAME $FRAMEWORK_BUNDLE/$FRAMEWORK_NAME

witeMessage "Decomposing each architecture's .a files"
for file in {Foundation$DEBUG,Util$DEBUG,XML$DEBUG,Net$DEBUG,NetSSL$DEBUG,Crypto$DEBUG,Data$DEBUG,DataSQLite$DEBUG}
do
echo "Decomposing $file ..."
mkdir -p $PATH_T0_LIBS/${file}
(cd $PATH_T0_LIBS/$file; ar -x ../libPoco$file.a );
done
doneSection

witeMessage "Linking into a libPoco${DEBUG}.a"
(cd $PATH_T0_LIBS; ar crus libPoco${DEBUG}.a Foundation$DEBUG/*.o Util$DEBUG/*.o XML$DEBUG/*.o Net$DEBUG/*.o NetSSL$DEBUG/*.o Crypto$DEBUG/*.o Data$DEBUG/*.o DataSQLite$DEBUG/*.o );
doneSection

for file in {Foundation$DEBUG,Util$DEBUG,XML$DEBUG,Net$DEBUG,NetSSL$DEBUG,Crypto$DEBUG,Data$DEBUG,DataSQLite$DEBUG}
do
echo "Cleaning $file..."
rm -rf $PATH_T0_LIBS/${file}
done

cd $CURRENT_DIR

FRAMEWORK_INSTALL_NAME=$FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/$FRAMEWORK_NAME

xcrun lipo \
-create \
-arch x86_64 "$PATH_T0_LIBS/libPoco${DEBUG}.a" \
-o "$FRAMEWORK_INSTALL_NAME" \
|| abort "Lipo $1 failed"

witeMessage "Framework: Copying includes..."
for i in {Foundation,Util,XML,Net,NetSSL_OpenSSL,Crypto,Data,Data/SQLite}
do
cp -r $POCO/$i/include/Poco/*  $FRAMEWORK_BUNDLE/Headers/
done

witeMessage "Framework: Creating plist..."
cat > $FRAMEWORK_BUNDLE/Resources/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>CFBundleDevelopmentRegion</key>
<string>English</string>
<key>CFBundleExecutable</key>
<string>${FRAMEWORK_NAME}</string>
<key>CFBundleIdentifier</key>
<string>org.poco</string>
<key>CFBundleInfoDictionaryVersion</key>
<string>$IPHONE_SDK_VERSION</string>
<key>CFBundlePackageType</key>
<string>FMWK</string>
<key>CFBundleSignature</key>
<string>????</string>
<key>CFBundleVersion</key>
<string>${FRAMEWORK_CURRENT_VERSION}</string>
</dict>
</plist>
EOF

doneSection

}

#Execution starts here
cd $POCO

./configure \
--config=Darwin-gcc \
--static \
--no-tests \
--no-samples \
--omit=CppUnit,CppParser,CodeGeneration,PageCompiler,Remoting,Data/MySQL,Data/ODBC

make -j32

#buildFramework "RELEASE" ${PWD}/lib

#Copy includes
echo "Framework: Copying includes..."
mkdir -p lib/Darwin/include/Poco
for i in {Foundation,Util,XML,Net,NetSSL_OpenSSL,Crypto,Data,Data/SQLite}
do
cp -r $POCO/$i/include/Poco/*  lib/Darwin/include/Poco
done


