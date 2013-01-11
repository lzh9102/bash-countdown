#!/bin/bash
# A simple countdown timer written in bash script
# Author: Timothy Lin <lzh9102@gmail.com>
# Date: 2011-07-21

# Messages
INTERRUPT_MSG="Count down stopped by user interrupt."
TIMEUP_MSG="Time is up."

# Constants
SEC_PER_MIN=60
SEC_PER_HOUR=`expr $SEC_PER_MIN \* 60`
SEC_PER_DAY=`expr $SEC_PER_HOUR \* 24`
SEC_PER_WEEK=`expr $SEC_PER_DAY \* 7`
PAT_WDHMS="^([0-9]+):([0-9]+):([0-9]+):([0-9]+):([0-9]+)$"
PAT_DHMS="^([0-9]+):([0-9]+):([0-9]+):([0-9]+)$"
PAT_HMS="^([0-9]+):([0-9]+):([0-9]+)$"
PAT_MS="^([0-9]+):([0-9]+)$"
PAT_S="^([0-9]+)$"
NOW=`date +%s`

####################################################################

function show_hint {
	echo "Usage: $(basename $0) [-f] <duration|-d date> [-q] [-t title] [-m message] [-e command]"
	echo "Examples:"
	echo "   $(basename $0) 30        # delay 30 seconds"
	echo "   $(basename $0) 1:20:30   # delay 1 hour 20 minutes and 30 seconds"
	echo "   $(basename $0) -d 23:30  # delay until 11:30 PM"
	echo "Options:"
	echo "   -f          Force execute. This option must be locate before <-d date>."
	echo "   -q          Quiet. Don't print message on exit."
	echo "   -t title    Show the title at the top of the screen."
	echo "   -m message  Show the message at the bottom of the screen."
	echo "   -e command  Execute command on timeup. The command will not be executed on cancel."
}

####################################################################

# function to get seconds from (weeks,days,hours,minutes,seconds)
# usage: print_seconds week days hours minutes seconds
function print_seconds {
	if [ $# -ne 5 ]; then # check for error
		echo "Error: function print_seconds takes 5 parameters"
		exit 1
	fi
	# weeks, days
	result=`expr $1 \* $SEC_PER_WEEK + $2 \* $SEC_PER_DAY`
	# hours, minutes, seconds
	result=`expr $result + $3 \* $SEC_PER_HOUR + $4 \* $SEC_PER_MIN + $5`
	echo $result
}

####################################################################

# function to correct date by trying to add some time to it
# usage: correct_date_sec seconds
function correct_date_sec {
	final=$1
	if [ $final -gt 0 ]; then echo $final; return; fi
	final=`expr $1 + $SEC_PER_DAY`
	if [ $final -gt 0 ]; then echo $final; return; fi
	final=`expr $1 + $SEC_PER_WEEK`
	if [ $final -gt 0 ]; then echo $final; return; fi
	echo "0"
}

####################################################################

# Parse command line options
sec_rem=0      # remaining seconds
param_prev=""  # previous parameters
while [ $# -gt 0 ]; do
	param=$1
	shift
	
	if [ "${param:0:1}" == "-" ]; then # skip options such as -d
		if [ "$param" == "-f" ]; then # force execute
			NO_CONFIRM=true
		elif [ "$param" == "-q" ]; then # quiet, no output on exit
			NO_OUTPUT=true
		fi
		param_prev=$param
		continue
	fi
	
	case "$param_prev" in
	-d) # assign a date
		UNTIL=`date -d "$param" +%s`
		
		if [ $? -ne 0 ]; then
			exit 1
		fi
		
		sec_rem=`expr $UNTIL - $NOW`
		
		if [ $sec_rem -lt 1 ]; then
			sec_rem=`correct_date_sec $sec_rem`
			if [ $sec_rem -lt 1 ]; then
				echo "Error: The date $param is already history."
				exit 1
			fi
			
			if [ -z "$NO_CONFIRM" ]; then # there's no "-f" option
				# confirm for the correction
				echo "Warning: The given date is assumed to be: `date -d now\ +$sec_rem\ sec`"
				echo "Place an option -f before -d to suppress this warning"
				read -n 1 -p "Still proceed [Y]/n?" ch
				echo
				if [ "$ch" == "n" ] || [ "$ch" == "N" ]; then
					exit 1
				fi
				ch=""
			fi
		fi
	
		;;
	-t) # set title
		TITLE="$param"
		;;
	-m) # set message
		MESSAGE="$param"
		;;
	-e) # execute command on timeup
		EXECUTE="$param"
		;;
	*)  # assign a time
	
		# identify the time format and calculate number of seconds by print_seconds
		if [[ "$param" =~ $PAT_WDHMS ]]; then    # W:D:H:M:S
			sec_rem=`print_seconds ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]} \
				${BASH_REMATCH[4]} ${BASH_REMATCH[5]}`
		elif [[ "$param" =~ $PAT_DHMS ]]; then   # D:H:M:S
			sec_rem=`print_seconds 0 ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]} \
			${BASH_REMATCH[4]}`
		elif [[ "$param" =~ $PAT_HMS ]]; then    # H:M:S
			sec_rem=`print_seconds 0 0 ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}`
		elif [[ "$param" =~ $PAT_MS ]]; then     # M:S
			sec_rem=`print_seconds 0 0 0 ${BASH_REMATCH[1]} ${BASH_REMATCH[2]}`
		elif [[ "$param" =~ $PAT_S ]]; then      # S
			sec_rem=`print_seconds 0 0 0 0 ${BASH_REMATCH[1]}`
		else
			echo "Error: Incorrect time format: $param"
			exit 1
		fi
		
		;;
	
	esac
	
	param_prev="" # clear the previous parameter

done

####################################################################

# check whether a correct time is assigned
if [ $sec_rem -eq 0 ]; then
	show_hint
	exit 1
fi

# calculate the date when time up
until_date=`expr $NOW + $sec_rem`

####################################################################

# cleanup function
# usage: cleanup_and_exit exitcode [message]
function cleanup_and_exit {
	tput cnorm # restore cursor
	stty echo # restore keyboard echo
	clear
	if [ -z $NO_OUTPUT ] && [ ! -z "$2" ]; then # print message
		echo $2
	fi
	
	if [ $1 -eq 0 ] && [ ! -z "$EXECUTE" ]; then # execute command on timeup
		eval $EXECUTE
	fi

	exit $1
}
trap 'cleanup_and_exit 1 "$INTERRUPT_MSG"' INT  # set the cleanup function to be the Control+C handler

####################################################################

clear
tput civis # hide cursor
stty -echo # disable keyboard echo

# count down
while [ 0 -eq 0 ]; do
	
	sec_rem=`expr $until_date - $(date +%s)` # calculate remaining seconds
	if [ $sec_rem -lt 1 ]; then
		break
	fi

	# Calculate the date of timeout once
	if [ -z "$TIMEOUT_DATE" ]; then
		TIMEOUT_DATE=`date -d "now +$sec_rem sec"`
	fi
	
	interval=$sec_rem
	seconds=`expr $interval % 60`
	interval=`expr $interval - $seconds`
	minutes=`expr $interval % 3600 / 60`
	interval=`expr $interval - $minutes`
	hours=`expr $interval % 86400 / 3600`
	interval=`expr $interval - $hours`
	days=`expr $interval % 604800 / 86400`
	interval=`expr $interval - $hours`
	weeks=`expr $interval / 604800`
	
	if [ ! -z "$TITLE" ]; then # print the title if it exists
		echo "$TITLE"
	fi
	echo "Now:   $(date)" # print date
	echo "Until: $TIMEOUT_DATE" # print timeup
	echo "------------------------------------ "
	echo "Weeks:    $weeks                     "
	echo "Days:     $days                      "
	echo "Hours:    $hours                     "
	echo "Minutes:  $minutes                   "
	echo "Seconds:  $seconds                   "
	echo "                                     "
	if [ ! -z "$EXECUTE" ]; then
		echo "Programs to execute on timeup:"
		echo " $EXECUTE"
		echo
	fi
	echo "Press [q] to stop counting           "
	echo "                                     "
	if [ ! -z "$MESSAGE" ]; then # print the message
		echo "$MESSAGE"
	fi
	
	tput home # move cursor back to (0,0)
	
	# wait for 0.9 second and monitor user input
	read -n 1 -t 0.9 ch
	if [ "$ch" == "q" ]; then
		cleanup_and_exit 1 "$INTERRUPT_MSG"
	fi
	
done

cleanup_and_exit 0 "$TIMEUP_MSG"
