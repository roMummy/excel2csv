if [  $CONFIGURATION == Release ]
then
	echo 'release build'
	#exit 0
else
	echo 'debug build'
	exit 0
fi

# 获取包路径
rootPub=./build/Release-iphoneos/

if [  $EFFECTIVE_PLATFORM_NAME == -iphonesimulator ]
then
	echo '模拟器'
	rootPub=./build/Release-iphonesimulator/
    rm -rf ${rootPub}
else
	echo '真机'
    rm -rf ${rootPub}
fi

# 将包从默认输出路径复制到dist目录

mkdir -p ${rootPub}

cp -rf ${CODESIGNING_FOLDER_PATH} ${rootPub}
echo "CODESIGNING_FOLDER_PATH"
echo ${CODESIGNING_FOLDER_PATH}
