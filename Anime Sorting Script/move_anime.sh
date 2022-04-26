#!/bin/sh
#Written by 42Kmi.com
#Move anime: Moves anime MKVs from download folder to their respective series folder based on folder name located in anime folder.
IFS=$'\n'

#Runs relative to directory containing the script
SUBFOLDER="anime" #Name of subfolder

#Get names of series folders from subfolder
getseriesfromsubfolder(){
	FOLDER_NAME_LIST="$(find "${SUBFOLDER}/" -maxdepth 1 -name '*'|sed -E "/\.mkv/d"|sed -E "s/^${SUBFOLDER}\///g")"
}
#Get names of new files, make unique
getnewfiles(){
	FOLDER_NAME_From_File_LIST="$(find . -maxdepth 1 -name '*.mkv'|sed -E "s/^\.\///g"|grep -E "(\[[a-zA-Z0-9]{8}\])?\.mkv$"|grep -E ".? - \b(([0-9]{2,})|(((ONA)|(S))[0-9]*E[0-9]*))\b.*\.mkv"|sed -E "s/^\[([a-zA-Z0-9.\-]|[a-zA-Z0-9. ]){3,}\] //g"|sed -E "s/\.? - (([0-9]{2,})|(((ONA)|(S))[0-9]*E[0-9]*)).*\.mkv//g"|sed -E "/\b([0-9]{2,})\b.*\.mkv/d"|awk '!a[$0]++'|sed -E "s/(\.){1,}$//g")"
}
#Get names of non-series/movies
getmovies(){
	MOVIE_LIST="$(find . -maxdepth 1 -name '*.mkv'|sed -E "s/^\.\///g"|grep -E "(\[[a-zA-Z0-9]{8}\])?\.mkv$"|grep -E "^\[([a-zA-Z0-9.\-]|[a-zA-Z0-9. ]){3,}\]"|sed -E "/- [0-9]{2,}.*\.mkv$/d"|awk '!a[$0]++')"
}
IFS=$'\n'

#Get mkv files
{
	getseriesfromsubfolder
	getnewfiles
	#Remove existing series with similar names from FOLDER_NAME_From_File_LIST
	for folder in $FOLDER_NAME_LIST; do
		if echo "$FOLDER_NAME_From_File_LIST"|grep -Eoq "^($folder)" &> /dev/null; then
			FOLDER_NAME_From_File_LIST="$(echo "${FOLDER_NAME_From_File_LIST}"|sed -E "/^($folder)/d")"
		fi
	done

	wait $!

	#Make folders
	FOUND_NEW_FILE_NO_FOLDER="0"

	for file_tofolder_name in $FOLDER_NAME_From_File_LIST; do
		if [ ! -d "${SUBFOLDER}/$file_tofolder_name" ]; then
			if  [ $FOUND_NEW_FILE_NO_FOLDER != 1 ]; then
				FOUND_NEW_FILE_NO_FOLDER=1
				echo "Found new anime, making folder(s)"
			fi
			mkdir "${SUBFOLDER}/$file_tofolder_name" &
		fi
	done

	#Display if no new series found
	if  [ -z $FOUND_NEW_FILE_NO_FOLDER ] || [ $FOUND_NEW_FILE_NO_FOLDER != 1 ]; then
		echo "No new anime series found"
	fi
	sleep 1
	wait $!
}
#-----

#Move anime
{
	getseriesfromsubfolder
	echo "Moving anime to their respective folder."
	sleep 1

	for folder in $FOLDER_NAME_LIST; do
		GET_FILES_LIST="$(find . -maxdepth 1 -name '*.mkv'|grep "${folder}")"
		for file in $GET_FILES_LIST; do
			mv "$file" "${SUBFOLDER}/$folder" &
		done
	done &> /dev/null
}

#Move non-series/movies to subfolder
{
	getmovies
	FOUND_NEW_MOVIE="0"
	
	if  [ -n "$MOVIE_LIST" ]; then
		if  [ $FOUND_NEW_MOVIE != 1 ]; then
			FOUND_NEW_MOVIE=1
			echo "Found non-series anime, moving to ${SUBFOLDER} subfolder"
		fi
	fi
			
	for file in $MOVIE_LIST; do
		mv "$file" "${SUBFOLDER}/$file" &
	done &> /dev/null
	sleep 2
}