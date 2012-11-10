Bash Countdown Timer
--------------------

Usage
-----
	countdown.sh [-f] <duration|-d date> [-q] [-t title] [-m message] [-e command]

Options
-------
	-f          Force execute. This option must be locate before <-d date>.
	-q          Quiet. Don't print message on exit.
	-t title    Show the title at the top of the screen.
	-m message  Show the message at the bottom of the screen.
	-e command  Execute command on timeup. The command will not be executed on cancel.

Examples
--------
	countdown.sh 30        # delay 30 seconds
	countdown.sh 1:20:30   # delay 1 hour 20 minutes and 30 seconds
	countdown.sh -d 23:30  # delay until 11:30 PM
