#!/bin/sh

#  build_poco_ios.sh
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

POCO_OMIT=${POCO_OMIT:-"Crypto,NetSSL_OpenSSL,CppUnit,CppParser,CodeGeneration,PageCompiler,Remoting,Data/MySQL,Data/ODBC,Zip"}

PLATFORMS=/Applications/Xcode.app/Contents/Developer/Platforms
IPHONE_SDK_VERSION=$1
POCO=$2
POCO_VERSION=$3
iPhoneARCH7=armv7
iPhoneARCH7s=armv7s
iPhoneARCH64=arm64
SIMULATOR_ARCH=i686

# Locate ar
ARM_BINARY_AR=`xcrun --sdk iphoneos -find ar`
DEV_BINARY_AR=`xcrun --sdk iphonesimulator -find ar`

VERSION_TYPE=Alpha
FRAMEWORK_NAME=Poco
FRAMEWORK_VERSION=A


FRAMEWORK_CURRENT_VERSION=$POCO_VERSION
FRAMEWORK_COMPATIBILITY_VERSION=$POCO_VERSION

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

CURRENT_DIR=${PWD}
FRAMEWORKDIR=$2/iOS/framework

PATH_TO_LIBS_i386=$3
PATH_TO_LIBS_ARM7=$4
PATH_TO_LIBS_ARM7s=$5
PATH_TO_LIBS_ARM64=$6

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
echo "Decomposing $file for iPhoneSimulator..."
#mkdir -p $PATH_TO_LIBS_i386/obj
mkdir -p $PATH_TO_LIBS_i386/${file}
(cd $PATH_TO_LIBS_i386/$file; $DEV_BINARY_AR -x ../libPoco$file.a );
done

for file in {Foundation$DEBUG,Util$DEBUG,XML$DEBUG,Net$DEBUG,NetSSL$DEBUG,Crypto$DEBUG,Data$DEBUG,DataSQLite$DEBUG}
do
echo "Decomposing $file for iPhoneOS..."
#mkdir -p $PATH_TO_LIBS_ARM7/obj
mkdir -p $PATH_TO_LIBS_ARM7/${file}
mkdir -p $PATH_TO_LIBS_ARM7s/${file}
mkdir -p $PATH_TO_LIBS_ARM64/${file}
(cd $PATH_TO_LIBS_ARM7/$file; $ARM_BINARY_AR -x ../libPoco$file.a );
(cd $PATH_TO_LIBS_ARM7s/$file; $ARM_BINARY_AR -x ../libPoco$file.a );
(cd $PATH_TO_LIBS_ARM64/$file; $ARM_BINARY_AR -x ../libPoco$file.a );
done
doneSection

witeMessage "Linking each architecture into a libPoco${DEBUG}.a"
echo "Linking objects for iPhoneSimulator..."
(cd $PATH_TO_LIBS_i386; $DEV_BINARY_AR crus libPoco${DEBUG}.a Foundation$DEBUG/*.o Util$DEBUG/*.o XML$DEBUG/*.o Net$DEBUG/*.o NetSSL$DEBUG/*.o Crypto$DEBUG/*.o Data$DEBUG/*.o DataSQLite$DEBUG/*.o );
echo "Linking objects for iPhoneOS..."
(cd $PATH_TO_LIBS_ARM7; $DEV_BINARY_AR crus libPoco${DEBUG}.a Foundation$DEBUG/*.o Util$DEBUG/*.o XML$DEBUG/*.o Net$DEBUG/*.o NetSSL$DEBUG/*.o Crypto$DEBUG/*.o Data$DEBUG/*.o DataSQLite$DEBUG/*.o );
(cd $PATH_TO_LIBS_ARM7s; $DEV_BINARY_AR crus libPoco${DEBUG}.a Foundation$DEBUG/*.o Util$DEBUG/*.o XML$DEBUG/*.o Net$DEBUG/*.o NetSSL$DEBUG/*.o Crypto$DEBUG/*.o Data$DEBUG/*.o DataSQLite$DEBUG/*.o );
(cd $PATH_TO_LIBS_ARM64; $DEV_BINARY_AR crus libPoco${DEBUG}.a Foundation$DEBUG/*.o Util$DEBUG/*.o XML$DEBUG/*.o Net$DEBUG/*.o NetSSL$DEBUG/*.o Crypto$DEBUG/*.o Data$DEBUG/*.o DataSQLite$DEBUG/*.o );
doneSection

for file in {Foundation$DEBUG,Util$DEBUG,XML$DEBUG,Net$DEBUG,NetSSL$DEBUG,Crypto$DEBUG,Data$DEBUG,DataSQLite$DEBUG}
do
echo "Cleaning $file..."
rm -rf $PATH_TO_LIBS_i386/${file}
rm -rf $PATH_TO_LIBS_ARM7/${file}
rm -rf $PATH_TO_LIBS_ARM7s/${file}
rm -rf $PATH_TO_LIBS_ARM64/${file}
done

cd $CURRENT_DIR

FRAMEWORK_INSTALL_NAME=$FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/$FRAMEWORK_NAME

xcrun -sdk iphoneos lipo \
-create \
-arch i386 "$PATH_TO_LIBS_i386/libPoco${DEBUG}.a" \
-arch armv7 "$PATH_TO_LIBS_ARM7/libPoco${DEBUG}.a" \
-arch armv7s "$PATH_TO_LIBS_ARM7s/libPoco${DEBUG}.a" \
-arch arm64 "$PATH_TO_LIBS_ARM64/libPoco${DEBUG}.a" \
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
--config=iPhoneSimulator-clang-libc++ \
--static \
--no-tests \
--no-samples \
--omit=$POCO_OMIT

make -j32

./configure \
--config=iPhone-clang-libc++ \
--static \
--no-tests \
--no-samples \
--omit=$POCO_OMIT

make -j32 POCO_TARGET_OSARCH=armv7
make -j32 POCO_TARGET_OSARCH=armv7s
make -j32 POCO_TARGET_OSARCH=arm64

buildFramework 'RELEASE' ${PWD}/lib `pwd`/lib/iPhoneSimulator/$SIMULATOR_ARCH `pwd`/lib/iPhoneOS/$iPhoneARCH7  `pwd`/lib/iPhoneOS/$iPhoneARCH7s  `pwd`/lib/iPhoneOS/$iPhoneARCH64
