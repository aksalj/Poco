#!/bin/sh

#  build_poco_android.sh
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
ABI=armeabi


#Execution starts here
cd $POCO

./configure \
--config=Android \
--static \
--no-tests \
--no-samples \
--omit=CppUnit,CppParser,CodeGeneration,PageCompiler,Remoting,Data/MySQL,Data/ODBC,Zip,XML

make -j32 ANDROID_ABI=$ABI

HOME_DIR=${PWD}

#Make libPoco.a
witeMessage "Preping libPoco.a..."
for file in {Foundation$DEBUG,Util$DEBUG,XML$DEBUG,Net$DEBUG,NetSSL$DEBUG,Crypto$DEBUG,Data$DEBUG,DataSQLite$DEBUG}
do
echo "Framework: Decomposing $file..."
mkdir -p lib/Android/$ABI/${file}
(cd lib/Android/$ABI/${file}; arm-linux-androideabi-ar -x ../libPoco$file.a );
done
cd $HOME_DIR;
echo "Framework: Archiving objects into libPoco${DEBUG}.a"
(cd lib/Android/$ABI; arm-linux-androideabi-ar crus libPoco${DEBUG}.a Foundation$DEBUG/*.o Util$DEBUG/*.o XML$DEBUG/*.o Net$DEBUG/*.o NetSSL$DEBUG/*.o Crypto$DEBUG/*.o Data$DEBUG/*.o DataSQLite$DEBUG/*.o );
cd $HOME_DIR;
for file in {Foundation$DEBUG,Util$DEBUG,XML$DEBUG,Net$DEBUG,NetSSL$DEBUG,Crypto$DEBUG,Data$DEBUG,DataSQLite$DEBUG}
do
echo "Framework: Cleaning $file..."
rm -rf lib/Android/$ABI/${file}
done
doneSection


#Copy includes
witeMessage "Framework: Copying includes..."
mkdir -p lib/Android/include/Poco
for i in {Foundation,Util,XML,Net,NetSSL_OpenSSL,Crypto,Data,Data/SQLite}
do
cp -r $POCO/$i/include/Poco/*  lib/Android/include/Poco
done
doneSection
