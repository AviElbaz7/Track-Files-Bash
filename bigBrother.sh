#!/bin/bash

folderTrack="folder_track_arr.txt"
f_f="$1"
args=( "$@" )

# helper functions
find_added_strings() {
    local array1=("$1[@]")
    local array2=("$2[@]")
    local added=()

    for element in "${!array2}"; do
        if [[ ! " ${!array1} " =~ " $element " ]]; then
            added+=("$element")
        fi
    done

    echo "${added[@]}"
}



if [[ ! -d "$f_f" && ! -e "$folderTrack" ]]; then
	>&2 echo "Must include valid path"
else
	
	if [ ! -e "$folderTrack" ]; then
		touch "$folderTrack"
		if [[ "${#args[@]}" == 1 ]]; then
			echo "$f_f" >> "$folderTrack"
			# Use find command to get folder names
			folders_pre=$(find "$f_f" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
			# Use command substitution to process each line
			folders=""
			while IFS= read -r line; do
			    # Add ".txt" to the beginning of each word and print the result
			    folders+="$f_f/$line"$'\n'
			done <<< "$folders_pre"
			
			# Use find command to get file names
			files_pre=$(find "$f_f" -maxdepth 1 -type f -exec basename {} \;)
			# Use command substitution to process each line
			files=""
			while IFS= read -r line; do
			    # Add ".txt" to the beginning of each word and print the result
			    files+="$f_f/$line"$'\n'
			done <<< "$files_pre"
			echo "$files" >> "all_files.txt"
			echo "$folders" >> "all_folders.txt"
			echo "Welcome to the Big Brother"
			
		else
			echo "$f_f" >> "$folderTrack"
			# Use find command to get folder names
			
			folders_pre=$(find "$f_f" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
			folders=""
			for element in "${args[@]:1}"; do
				exists=0
				while IFS= read -r line; do
			    		if [ "$element" == "$line" ]; then
			    			exists=1
			    			
			    		fi
			    	done <<< "$folders_pre"
			    	folders+="$f_f/$element/$exists"$'\n'
			done
			files_pre=$(find "$f_f" -maxdepth 1 -type f -exec basename {} \;)
			files=""
			for element in "${args[@]:1}"; do
				exists=0
				while IFS= read -r line; do
			    		if [ "$element" == "$line" ]; then
			    			exists=1
			    			
			    		fi
			    	done <<< "$files_pre"
			    	files+="$f_f/$element/$exists"$'\n'
			done
			echo "$files" >> "all_files.txt"
			echo "$folders" >> "all_folders.txt"
			echo "Welcome to the Big Brother"
		fi
	else	
		f_f=$(<"$folderTrack")
		# Use find command to get folder names
		folders_array=$(find "$f_f" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
		readarray -t folders_now <<< "$folders_array"
		# Use find command to get file names
		files_array=$(find "$f_f" -maxdepth 1 -type f -exec basename {} \;)
		readarray -t files_now <<< "$files_array"
		matching_lines_folders=$(grep "$f_f" "all_folders.txt")
		previous_folders=()
		number_slashes=1
		if [ -n "$matching_lines_folders" ]; then
			while IFS= read -r line; do
				lastPart=$(echo "$line" | awk -F'/' '{print $NF}')
				previous_folders+=("$lastPart")
				number_slashes=$(tr -cd '/' <<< "$line" | wc -c)
			done <<< "$matching_lines_folders"

		fi
		
		matching_lines_files=$(grep "$f_f" "all_files.txt")
		previous_files=()
		if [ -n "$matching_lines_files" ]; then
			while IFS= read -r line; do
				lastPart=$(echo "$line" | awk -F'/' '{print $NF}')
				previous_files+=("$lastPart")
				number_slashes=$(tr -cd '/' <<< "$line" | wc -c)
			done <<< "$matching_lines_files"
		fi
		
		if [ "$number_slashes" == 2 ]; then
			declare -A given_folders_args
			declare -A given_files_args
			while IFS= read -r line; do
				IFS='/' read -r folder arg exists <<< "$line"
				given_folders_args["$arg"]="$exists"
			done <<< "$matching_lines_folders"
			while IFS= read -r line; do
				IFS='/' read -r folder arg exists <<< "$line"
				given_files_args["$arg"]="$exists"
			done <<< "$matching_lines_files"		
			
			declare -A current_folders_args
			declare -A current_files_args
			for key in $(echo "${!given_folders_args[@]}" | tr ' ' '\n' | sort); do
				if [[ "${folders_now[@]}" =~ "$key" ]]; then 
					current_folders_args["$key"]=1
				else
					current_folders_args["$key"]=0
				fi
				if [[ "${files_now[@]}" =~ "$key" ]]; then 
					current_files_args["$key"]=1
				else
					current_files_args["$key"]=0
				fi
			done
			for key in $(echo "${!current_folders_args[@]}" | tr ' ' '\n' | sort); do
				if [[ "${given_folders_args["$key"]}" < "${current_folders_args["$key"]}" ]]; then
					echo "Folder added: $key"
				fi
				if [[ "${given_folders_args["$key"]}" > "${current_folders_args["$key"]}" ]]; then
					>&2 echo "Folder deleted: $key"
				fi

			done
			for key in $(echo "${!current_folders_args[@]}" | tr ' ' '\n' | sort); do
				if [[ "${given_files_args["$key"]}" < "${current_files_args["$key"]}" ]]; then
					if [[ "$key" != "all_folders.txt" && "$key" != "all_files.txt" ]]; then
						echo "File added: $key"
					fi
				fi
				if [[ "${given_files_args["$key"]}" > "${current_files_args["$key"]}" ]]; then
					>&2 echo "File deleted: $key"
				fi
			done
			grep -v "^$f_f" "all_folders.txt" > temp_file && mv temp_file "all_folders.txt"
			grep -v "^$f_f" "all_files.txt" > temp_file && mv temp_file "all_files.txt"
			for key in $(echo "${!current_folders_args[@]}" | tr ' ' '\n' | sort); do
			    echo "$f_f/$key/${current_folders_args[$key]}" >> "all_folders.txt"
			done

			for key in $(echo "${!current_files_args[@]}" | tr ' ' '\n' | sort); do
			    echo "$f_f/$key/${current_files_args[$key]}" >> "all_files.txt"
			done
		
		else
			folders_added=($(find_added_strings previous_folders folders_now))
			files_added=($(find_added_strings previous_files files_now))
			folders_removed=($(find_added_strings folders_now previous_folders))
			files_removed=($(find_added_strings files_now previous_files))
			
			folders_added=($(for element in "${folders_added[@]}"; do echo "$element"; done | sort))
			files_added=($(for element in "${files_added[@]}"; do echo "$element"; done | sort))
			folders_removed=($(for element in "${folders_removed[@]}"; do echo "$element"; done | sort))
			files_removed=($(for element in "${files_removed[@]}"; do echo "$element"; done | sort))	

			if [ ! ${#folders_added[@]} -eq 0 ]; then
				printf "Folder added: %s" "${folders_added[@]/%/$'\n'}"
			fi
			if [ ! ${#folders_removed[@]} -eq 0 ]; then
				>&2 printf "Folder deleted: %s" "${folders_removed[@]/%/$'\n'}"
			fi
			if [ ! ${#files_added[@]} -eq 0 ]; then
				for name in "${files_added[@]}"; do
    				# Check if the current name is not equal to the excluded names
    					if [[ "$name" != "all_folders.txt" && "$name" != "all_files.txt" ]]; then
						printf "File added: %s\n" "$name"
    					fi
				done
				#printf "File added: %s" "${files_added[@]/%/$'\n'}"
			fi
			if [ ! ${#files_removed[@]} -eq 0 ]; then
				>&2 printf "File deleted: %s" "${files_removed[@]/%/$'\n'}"
			fi

			#printf "%s\n" "${folders_removed[@]/#/Folder deleted: }" >&2 
			#printf "%s\n" "${files_added[@]/#/File added: }" 
			#printf "%s\n" "${files_removed[@]/#/File deleted: }" >&2
			
			grep -v "^$f_f" "all_folders.txt" > temp_file && mv temp_file "all_folders.txt"
			grep -v "^$f_f" "all_files.txt" > temp_file && mv temp_file "all_files.txt"
			printf "%s\n" "${folders_now[@]/#/"$f_f/"}" >> "all_folders.txt"
			printf "%s\n" "${files_now[@]/#/"$f_f/"}" >> "all_files.txt"
		fi		
	fi
fi
