adb.install () { adb install $1 ;}
adb.push () { adb push $1 $2 ;}
android.backup.personal () { 
	folder_root="/storage/emulated/0/"
	folders=$(adb shell ls $folder_root | grep -ie 'dcim\|pictures\|video\|download')
	for folder in $(echo -e "${folders}");do
		echo adb shell "ls -R ${folder_root}${folder}" | grep -vi '.*thumb*' | tr '\r' ' ' | while read file; do adb pull $file;done
	done
}
#@ android