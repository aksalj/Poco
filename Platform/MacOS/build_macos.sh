#!/bin/sh

#  build_poco_macos.sh
#
#

POCO=$1
POCO_VERSION=$2


#Execution starts here
cd $POCO

./configure \
--config=Darwin-gcc \
--static \
--no-tests \
--no-samples \
--omit=CppUnit,CppParser,CodeGeneration,PageCompiler,Remoting,Data/MySQL,Data/ODBC

make -j32

#Copy includes
echo "Framework: Copying includes..."
mkdir -p lib/Darwin/include/Poco
for i in {Foundation,Util,XML,Net,NetSSL_OpenSSL,Crypto,Data,Data/SQLite,Zip}
do
cp -r $POCO/$i/include/Poco/*  lib/Darwin/include/Poco
done


