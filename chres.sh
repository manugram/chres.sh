#!/bin/bash
set -e

script_date=03.07.2020

#################
#	This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
##########
#
# Original author: Manuel Soto.
# Send bug reports and improvements to manugram.dev@gmail.com
# With the subject: CHRES
#
# The latest version of this script,
# https://github.com/manugram/chres.sh
# 
# TODO:
# - Soporte multi-monitor.
# - Soporte multi-frecuencia.
# - Controlar valores fuera de rango.
# - Agregar una rutina temporizada para revertir cambios.
# - etc.
####################
    
# Cabecera del script chres

# Minor changes from WRITER_ to AUTHOR_ and _CONTACT and _EMAIL added...
AUTHOR_NAME="Manuel Soto"
AUTHOR_CONTACT="https://github.com/manugram/chres.sh"
AUTHOR_EMAIL="manugram.dev@gmail.com"

SCRIPT_NAME='chres'
SCRIPT_VERSION="0.2.1"
BASH_TEST_VERSION="5.0.3"
XRANDR_TEST_VERSION="1.5.0"
XRANDR_SYS_VERSION="$(xrandr -v | head -n 1 | awk '{print $4}')"

#BASH_SYS_VERSION="$(bash --version | head -n 1 | awk -F' ' '{print $4}' | cut -d'(' -f 1)"
BASH_SYS_VERSION="$(echo $BASH_VERSION | awk -F'(' '{print $1}')"
SCRIPT_DESCRIPTION="Resolution changer for X, test with xrandr: v${XRANDR_TEST_VERSION} and bash: v${BASH_TEST_VERSION}"
XRANDR_DESCRIPTION="Actual version of xrandr on this system: v${XRANDR_SYS_VERSION}"
BASH_DESCRIPTION="Actual version of bash on this system: v${BASH_SYS_VERSION}"

# Fin de cabecera



# Begin of declaration and function definitions block

version_header(){
	echo "${SCRIPT_NAME}" version: v"${SCRIPT_VERSION}"
	printf "%s\n" "${SCRIPT_DESCRIPTION}"
	printf "%s\n" "${XRANDR_DESCRIPTION}"
	printf "%s\n" "${BASH_DESCRIPTION}"
	echo
}


version_footer(){
	printf "\n"
	printf "%s\n" "Written by: ${WRITER_NAME}; see"
	printf "%s\n" "${WRITER_CONTACT}"
	
}


usage () {
	echo "Usage:"
	printf "%s\n" "$SCRIPT_NAME [OPTIONS]" 
	printf "%s\n" "$SCRIPT_NAME [-a HRESxVRES[:screen]]"
	printf "%s\n" "$SCRIPT_NAME [-s HRESxVRES[@hz]]"
	printf "%s\n" "$SCRIPT_NAME [-r HRESxVRES[:screen]]"
	printf "%s\n" "$SCRIPT_NAME [-n HRESxVRES[@hz]]"
	printf "%s\n" "$SCRIPT_NAME [-v HRESxVRES[:screen]]"
	printf "\n"
	printf "%s" "Where:
-a	Add mode to [:screen] only (e.g. 1024x768).	
-c	Show current mode.
-d	Displays the current screen name.
-n	Create just a new mode (Don't add it to any screen).
-x	Show the xrandr command only output.
-r	Remove video mode.
-s	Set the video mode. If it doesn't exist, create it, add it and activate it.
-v	Verify the video mode given.
-V	Show the version of this script.

HRES	Horizontal resolution.
VRES	Vertical resolution.
hz	Refresh rate in hertz. (optional). If not given, the default is 60 hz.
screen	Screen name in xrandr. If not screen name given, default is the current
		screen. Shown with the -d flag.
"		
}

help_func () {
	version_header
	usage
	version_footer
}


# This function verify if the resolution given exist or not

xrandr_verify(){
#set -x
	local vmode="$1"
	local cmode="$(echo ${current_mode} | awk -F" " '{print $2}')"
	
	# When a mode is not assign to any screen, the mode line have more fields	
	local mode_exist="$(xrandr | tail -n +3 | grep -iw ${vmode} | awk '{print $1}')"
	
	# A mode asign to a screen have 2 fields (normaly), the mode name
	# and the refresh rate (i don't have in count the multi rate values).
	local mode_added="$(xrandr | tail -n +3 | grep -iw ${vmode} | wc -w)"
	
	if [ "${vmode}" == "${cmode}" ]
	then	
		echo 3
		
	# This is a very waek logic, because don't have in count the multirate
	# entrance for a mode. Normaly, a line compose by a mode name and a refresh
	# rate value, counts on that. Well, it works by now.
	elif [ "${mode_added}" -eq 2 ]
	then
		echo 2
	elif [ "${mode_exist}" != '' ]
	then
		echo 1
	else
		echo 0
	fi 
	
}


# This function form the line that is the argument of xrandr 
# And in a format that is more easy to parse

cvt_gen(){
	local xres="$1"
	local yres="$2"
	local hz="$3"		
	
	# This pattern is to delete a portion of the string return by cvt command
	local dhz="_${hz}.00"
	
	local cvt_out="$(cvt ${xres} ${yres} ${hz} | grep -i modeline | cut -f2- -d" " | sed "s/${dhz}//;s/\"//g")"
	
	if [ "$?" -eq 0 ]
	then
		echo "${cvt_out}"
	else
		return "$?"
	fi
}



# Create the new resolution in xrandr

xrandr_new_mode(){
	local cvt_line="$@"
	
			
	[[ "$(xrandr --newmode ${cvt_line})" ]] || return 0
	
	
	#if [ "$?" != 0 ]
	#then
		return "$?"
	#fi
	
}


# Add mode to screen (screen_name)

xrandr_add_mode(){
	local screen="$1" # Screen name
	local mode="$2"	# Resolution mode
	
	[[ "$(xrandr --addmode ${screen} ${mode})" ]] || return 0
	
#	if [ "$?" != 0 ]
#	then
		return "$?"
#	fi		
}


# Set the video mode

xrandr_set_mode(){
	local screen="$1" # screen name
	local mode="$2"	# Resolution mode
	
	[[ "$(xrandr --output ${screen} --mode ${mode})" ]] || return 0
	
	#if [ "$?" != 0 ]
	#then
		return "$?"
	#fi
}


xrandr_delete_mode(){
	local screen="$1"
	local mode="$2"
	
	[[ "$(xrandr --delmode ${screen} ${mode})"  ]] || return 0
	
	
	return "$?"
		
}


# Remove the mode from xrandr

xrandr_rm_mode(){
	local video_mode="$1"
		
	[[ "$(xrandr --rmmode ${video_mode})" ]] || return 0
	
#	if [ "$?" != 0 ]
#	then
		return "$?"
#	fi
}


# Parsing de argument line

parse_arg_line(){
	local sep=$1
	
	if [ "${sep}" == '@' ] # Determine if the @ part exist
	then
		local temp="$(echo ${video_mode} | awk -F@ '{print $1}')"
		horz="$(echo ${temp} | awk -Fx '{print $1}')"
		vert="$(echo ${temp} | awk -Fx '{print $2}')"
	
		# Try to determine if right part of the @ is a number and is not 0
    	if [ "$(echo ${video_mode} | awk -F@ '{print $2}')" -gt 0 ]
    	then
    		rate="$(echo ${video_mode} | awk -F@ '{print $2}')"
    	fi
	
		unset temp

    elif [ "${sep}" == ':' ] # Determine if the : part exist	
    then
    	local temp="$(echo ${video_mode} | awk -F: '{print $1}')"
    	horz="$(echo ${temp} | awk -Fx '{print $1}')"
    	vert="$(echo ${temp} | awk -Fx '{print $2}')"
	
    	if [ "$(echo ${video_mode} | awk -F: '{print $2}')" != '' ]
    	then
    		screen_name="$(echo ${video_mode} | awk -F: '{print $2}')"
    	fi
    	
    	unset temp	
    
    else
    	printf "%s\n" "Invalid option or argument!!"
    	help_func
    	exit 1
    fi
    
}


# Stores name of the screen according to xrandr and the current resolution mode

screen_name="$(xrandr | head -n 2 | tail -n 1 | awk '{print $1}')"
current_mode="$(xrandr | head -n 1 | awk -F, '{print $2}' | sed 's/ x /x/;s/ //')"

# Some variables for use and abuse!! xD

horz=''
vert=''
rate="${rate:-60}"
ACTIVE_MODE=0
VERIFY_MODE=0
NEW_MODE=0
ADD_MODE=0
SET_MODE=0
RM_MODE=0
FS_CHAR=""
video_mode=""
option_pattern=':s:a:dcxv:Vr:n:h'


while getopts "$option_pattern" ops
do
	case $ops in
		'a') ADD_MODE=1
			ACTIVE_MODE=1
			video_mode="${OPTARG}"			
			;;
		'c') echo "$current_mode"
			shift
			exit 0			
			;;
		'd') echo "$screen_name"
			shift
			exit 0			
			;;
		'n') NEW_MODE=1
			ACTIVE_MODE=1
			video_mode="${OPTARG}"					
			;;		
		's') SET_MODE=1
			ACTIVE_MODE=1
			video_mode="${OPTARG}"			
			;;				
		'r') RM_MODE=1
			ACTIVE_MODE=1
			video_mode="${OPTARG}"					
			;;
		'x') xrandr
			exit 0			
			;;
		'v') VERIFY_MODE=1
			ACTIVE_MODE=1
			video_mode="${OPTARG}"
			;;
		'V') version_header
			exit 0
			;;		
  		'h') help_func
  			exit 0  			
  			;;
		':') printf "%s\n\n" "$0: Argument missing!!"
			help_func
			exit 1
			;; 
		  *) printf "%s\n\n" "$0: Unrecognize option!!"
			help_func
			exit 1			
			;;
	esac
done



#set -x
shift $(($OPTIND - 1)) 

# FS_CHAR stands for CHARacter Field Separator
# Well, here is a little trick that I had to do, because, if I don't put the
# disjunction part and the echo instruction, bash stops processing the script
# abruptly, without any error message.
# This occur when no FS_CHAR is pass in the argument line.
# e.g. only when pass the mode without the @ part for the refresh rate, or the 
# colon (:) for the screen name.
FS_CHAR="$(echo ${video_mode} | grep -Eo '(@|:)')" || { echo '' ; }
#echo $?

# Extract the values from the argument line for horz,vert,rate variables!!
if [ "${ACTIVE_MODE}" -eq 1 ] && [ "$FS_CHAR" != '' ]
then
	parse_arg_line "${FS_CHAR}"
	
elif [ "${ACTIVE_MODE}" -eq 1 ] && [ "$FS_CHAR" == '' ]
then
  	horz="$(echo ${video_mode} | awk -Fx '{print $1}')"
   	vert="$(echo ${video_mode} | awk -Fx '{print $2}')"
   	   	
fi
	

if [ "${ACTIVE_MODE}" -eq 1 ]
then
	# In the form HORZxVERT (e.g. 800x600)
	mode_name="$(echo ${horz}'x'${vert})"
	
	# To generate the mode line to pass it to xrandr
	mode_line="$(cvt_gen ${horz} ${vert} ${rate})"
	
	# To Verify if a mode exist and is added to screen
	VERIFIED="$(xrandr_verify ${mode_name})"
fi



if [ "${NEW_MODE}" -eq 1 ]
then
	#set -x
	#echo "NEW_MODE: ${NEW_MODE}"
			
	if [ "${VERIFIED}" -eq 1 ]
	then
		printf "%s\n" "The mode exists but has not been added to a screen!!"
		exit 1
	elif [ "${VERIFIED}" -eq 2 ]
	then
		printf "%s\n" "The mode: $ {mode_name} exists and is added to $ {screen_name} !!"
		exit 2
	elif [ "${VERIFIED}" -eq 3 ]
	then
		printf "%s\n" "The mode: ${mode_name} exists and is the current mode in ${screen_name} !!"
		exit 3
	fi	
	
	# If all conditions are exceeded, the new video mode is created
	
	[[ "$(xrandr_new_mode ${mode_line})" ]] && \
	{ printf "%s\n" "Error $? creating mode ${mode_name}" ; exit 1 ; }
	
	printf "%s\n" "Mode ${mode_name} successfully created!!"
	
elif [ "${ADD_MODE}" -eq 1 ]
then
	#set -x
	#echo "ADD_MODE: ${ADD_MODE}"
	
	if [ "${VERIFIED}" -eq 1 ]
	then
		[[ "$(xrandr_add_mode ${screen_name} ${mode_name})" ]] && exit 1
		
		printf "%s\n" "Mode ${mode_name} added to ${screen_name} !!"
		
	else
		printf "%s\n" "Error $? adding mode ${mode_name} to ${screen_name} !!"
		exit 1
	fi

elif [ "$SET_MODE" -eq 1 ]
then
	#set -x
	#echo "SET_MODE: ${SET_MODE}"
	
	if [ "${VERIFIED}" -eq 0 ]
	then
	# I think, this work like a chain of ¿false positives? where the success
	# execution of the function return a 0 (ZERO) and thats, in term of Boolean
	# logic, means False, because of that, the second part of the disjunction
	# (||, OR) will be execute, and so on, until the conjunction part (&&, AND),
	# where show a error message, only when all the test before were fail. 	
		[[ "$(xrandr_new_mode ${mode_line})" ]] || \
		[[ "$(xrandr_add_mode ${screen_name} ${mode_name})" ]] || \
		[[ "$(xrandr_set_mode ${screen_name} ${mode_name})" ]] && \
		{ printf "%s\n" "Error $? mode ${mode_name} to ${screen_name} not set!!" ; \
			exit -1 ; }
			
		printf "%s\n" "Mode ${mode_name} fully set on ${screen_name} !!"
	
	elif [ "${VERIFIED}" -eq 1 ]
	then
		[[ "$(xrandr_add_mode ${screen_name} ${mode_name})" ]] || \
		[[ "$(xrandr_set_mode ${screen_name} ${mode_name})" ]] && \
		{ printf "%s\n" "Error $? mode ${mode_name} to ${screen_name} not set!!" ; \
			exit 1 ; }
			
		printf "%s\n" "Mode ${mode_name} added and set on ${screen_name} !!"
	
	elif [ "${VERIFIED}" -eq 2 ]
	then
		[[ "$(xrandr_set_mode ${screen_name} ${mode_name})" ]] && \
		{ printf "%s\n" "Error $? mode ${mode_name} to ${screen_name} not set!!" ; \
			exit 2 ; }
			
		printf "%s\n" "Mode ${mode_name} set on ${screen_name} !!"
		
	else
		printf "%s\n" "The mode ${mode_name} exist and is set!!"
		exit 3
	fi

elif [ "$RM_MODE" -eq 1 ]
then
	#set -x
	#echo "RM_MODE: ${RM_MODE}"

	if [ "${VERIFIED}" -eq 2 ]
	then
		[[ "$(xrandr_delete_mode ${screen_name} ${mode_name})" ]] || \
		[[ "$(xrandr_rm_mode ${mode_name})" ]] && \
		{ printf "%s\n" "Error $? removing ${mode_name} from ${screen_name} !!" ; \
			exit 2 ; }
			
		printf "%s\n" "Mode ${mode_name} successfully removed from ${screen_name} !!"
		
	elif [ "${VERIFIED}" -eq 1 ]
	then
		[[ "$(xrandr_rm_mode ${mode_name})" ]] && \
		{ printf "%s\n" "Error $? removing mode ${mode_name}" ; \
			exit 1 ; }
			
		printf "%s\n" "Mode ${mode_name} successfully removed!!"
	else
		printf "%s\n" "The mode not exist or is the current, try to delete manually!!"
		exit 1
	fi

elif [ "${VERIFY_MODE}" -eq 1 ]
then
	# This is not dificult to understand, i hope so.
	# By the way, i think the single square brackets have the same mining that 
	# doubles in the test format.
	[ "${VERIFIED}" -eq 3 ] && { echo "The mode: ${mode_name} exist, and is the current mode in ${screen_name} !!" ; exit 0 ; }
	
	[ "${VERIFIED}" -eq 2 ] && { echo "The mode: ${mode_name} exist in screen: ${screen_name}" ; exit 0 ; }
	
	[ "${VERIFIED}" -eq 1 ] && { echo "The mode: ${mode_name} exist, but not assign to a screen." ; exit 0 ; }
	
	[ "${VERIFIED}" -eq 0 ] && { echo "The mode: ${mode_name} not exist in xrandr database." ; exit 0 ;}
	
	{ echo "Bad argument or mode name" ; exit 1 ; }

else
	echo
	help_func	
fi



# END of Script !! Only for reference !!


