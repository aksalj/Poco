#!/bin/sh

#  build.sh
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

POCO_VER=$1
POCO_DIR=${PWD}/Poco/poco-$POCO_VER
IOS_VER=$2

BUILD=$3
FRESH_BUILD=$4

cleanFiles()
{
witeMessage "Cleaning Poco $POCO_VER"
pushd ${PWD}
cd $POCO_DIR
make clean
rm -f -R lib
popd

rm -f -R Platform/Android/lib

rm -f -R Platform/iOS/lib

rm -f -R Platform/MacOS/lib

rm -f -R Build/iOS

rm -f -R Build/Android

rm -f -R Build/Darwin

doneSection
}

buildMacOS()
{
witeMessage "Building Poco $POCO_VER for Mac OS"
pushd ${PWD}

cd Platform/MacOS
./build_macos.sh $POCO_DIR

popd

#Move built libs and headers to Output dir
mv $POCO_DIR/lib/Darwin Build/

doneSection
}

buildAndroid()
{
witeMessage "Building Poco $POCO_VER for Android"
pushd ${PWD}

cd Platform/Android
./build_android.sh $POCO_DIR

popd

#Move built libs and headers to Output dir
mv $POCO_DIR/lib/Android Build/

doneSection
}

buildiOS()
{
witeMessage "Building Poco $POCO_VER for iOS $IOS_VER"
pushd ${PWD}

cd Platform/iOS
./build_ios.sh $IOS_VER $POCO_DIR $POCO_VER

popd

#Move built libs and headers to Output dir
mv $POCO_DIR/lib/iOS Build/
mv $POCO_DIR/lib/iPhoneOS Build/iOS/
mv $POCO_DIR/lib/iPhoneSimulator Build/iOS/

doneSection
}

#Execution begins here
if [ $# -eq 0 ]
then
witeMessage "Usage: build.sh POCO_VERSION [IOS_VERSION] (ALL|Mobile|iOS|Android|MacOS) [CLEAN|CLEAN-ONLY]\n"
exit 1
fi

if [ "$FRESH_BUILD" == 'CLEAN' ]; then
cleanFiles
elif [ "$FRESH_BUILD" == 'CLEAN-ONLY' ]; then
cleanFiles 
exit 1
fi

#Go ahead
if [ "$BUILD" == 'ALL' ]; then
buildAndroid
buildiOS
buildMacOS
elif [ "$BUILD" == 'Mobile' ]; then
buildAndroid
buildiOS
elif [ "$BUILD" == 'iOS' ]; then
buildiOS
elif [ "$BUILD" == 'Android' ]; then
buildAndroid
elif [ "$BUILD" == 'MacOS' ]; then
buildMacOS
#witeMessage "MacOS build needs some work..."
exit 1
else
witeMessage "No target platform(ALL, iOS, Android or MacOS) specified."
exit 1
fi
