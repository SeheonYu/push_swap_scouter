#!/bin/bash

BUILD_DIRECTORY="../push_swap"

########################################
#           ANSI Escape Code           #
########################################

LINE_CLEAR=$'\33[2K\r'

BLACK=$'\033[0;30m'
DARKGRAY=$'\033[1;30m'
RED=$'\033[0;31m'
LIGHTRED=$'\033[1;31m'
PURPLE=$'\033[0;35m'
LIGHTPURPLE=$'\033[1;35m'

UNDERBAR=$'\033[4m'
CLEAR=$'\033[0m'

########################################
#               Function               #
########################################

## Parameters
# $1 = checker name

function download_checker()
{
	local CHECKER=$1
	local CHECKER_URL

	if [ "$CHECKER" == "./checker_Mac" ]; then
		local CHECKER_URL="https://projects.intra.42.fr/uploads/document/document/3525/checker_Mac"
	elif [ "$CHECKER" == "./checker_linux" ]; then
		local CHECKER_URL="https://projects.intra.42.fr/uploads/document/document/3526/checker_linux"
	else
		return
	fi

	rm -rf $CHECKER

	if [ ! -e $CHECKER ]; then
		local SET=$(seq 0 9)
		for i in $SET
		do
			HTTP_CODE=$(curl -s -o $CHECKER -w %{http_code} $CHECKER_URL)
			if [ $HTTP_CODE -eq 200 ]; then
				break
			else
				rm $CHECKER
				echo -n $LINE_CLEAR"Downloading Checker "
				local DOTSET=$(seq 0 $i)
				for j in $DOTSET
				do
					echo -n "."
				done
				sleep 1
			fi
		done
		echo -n $LINE_CLEAR
		if [ ! -e $CHECKER ]; then
			echo $0": "$LIGHTPURPLE"warning: "$CLEAR"checker download failed"
			CHECKER=
		else
			chmod u+x $CHECKER
		fi
	elif [ ! -x $CHECKER ]; then
		chmod u+x $CHECKER
	fi

}

## Parameters
# ARG must be defined before
# $1 = push_swap file
## Return Value
# Set global_variable INSTRUCTIONS, SCORE

function run_push_swap()
{
	local PUSH_SWAP=$1

	if [ ! -x "$PUSH_SWAP" ]; then
		echo $0": "$LIGHTRED"error: "$CLEAR"script error, no push_swap exist"
		exit 1
	fi

	INSTRUCTIONS=$($PUSH_SWAP $ARG 2>&1)
	SCORE=$(echo $INSTRUCTIONS | wc | awk '{printf "%d", $2}')
}

## Parameters
# $1 = checker file
## Return Value
# OK, KO, Error

function run_checker()
{
	local CHECKER=$1

	if [ ! -x "$CHECKER" ]; then
		echo $0": "$LIGHTRED"error: "$CLEAR"script error, no checker exist"
		exit 1
	fi

	if [[ -z $INSTRUCTIONS ]]; then
		CHECK=$($CHECKER $ARG < /dev/null 2>&1)
	else
		CHECK=$(echo $INSTRUCTIONS | tr " " "\n" | $CHECKER $ARG 2>&1)
	fi

	if [ $CHECK != "OK" ] && [ $CHECK != "KO" ] && [ $CHECK != "Error" ]; then
		echo $CHECKER": "$LIGHTPURPLE"error: "$CLEAR"invalid output: "$CHECK
		exit 1
	fi

	echo $CHECK
}

## Parameters
# $1 = random scale
# $2 = limit number of instructions
# $3 = test scale
## Return Value
# 0 if successed, 1 if failed, -1 if error occured

function scale_test()
{
	SET=$(seq 1 $3)
	FAILED=0
	SUM=0
	for i in $SET
	do
		/bin/echo -n "$LINE_CLEAR"Calculating $(expr $i \* 100 / $3)% ... "(Success: $(expr $i - $FAILED), Failed: $FAILED)"
		ARG=$(ruby -e "puts (1..$1).to_a.shuffle.join(' ')")
		run_push_swap $PUSH_SWAP
		if [ "$INSTRUCTIONS" == "Error" ]; then
			echo
			echo $PUSH_SWAP": "$LIGHTRED"error: "$CLEAR"error occured with arguments:"
			if [[ "$OSTYPE" == "darwin"* ]]; then
				echo $ARG | pbcopy
				echo "Copied arguments to clipboard"
			else
				echo $ARG
			fi
			exit 1
		fi
		if [ -n "$CHECKER" ]; then
			local RESULT=$(run_checker $CHECKER)
			if [ "$RESULT" == "Error" ]; then
				echo
				echo $CHECKER": "$LIGHTRED"error: "$CLEAR"error occured with instructions:"
				echo $INSTRUCTIONS
				echo $PUSH_SWAP": "$DARKGRAY"note: "$CLEAR"arguments was "$ARG
				if [[ "$OSTYPE" == "darwin"* ]]; then
					echo $ARG | pbcopy
					echo "Copied arguments to clipboard"
				fi
				exit 1
			elif [ "$RESULT" == "KO" ]; then
				echo
				echo $PUSH_SWAP": "$LIGHTRED"error: "$CLEAR"failed to sorting values: "$ARG
				if [[ "$OSTYPE" == "darwin"* ]]; then
					echo $ARG | pbcopy
					echo "Copied arguments to clipboard"
				fi
				exit 1
			fi
		fi
		SUM=$(expr $SUM + $SCORE)
		if [[ $SCORE -ge $2 ]]; then
			FAILED=$(expr $FAILED + 1)
		fi
	done

	echo
	if [[ $FAILED -eq 0 ]]; then
		echo "   ______                __  ______"
		echo "  / ____/_______  ____ _/ /_/ / / /"
		echo " / / __/ ___/ _ \/ __ \`/ __/ / / / "
		echo "/ /_/ / /  /  __/ /_/ / /_/_/_/_/  "
		echo "\____/_/   \___/\__,_/\__(_|_|_)   "
		echo
		echo "<$1 random values> $3 times all under $2 (Average: $(echo $SUM $3 | awk '{printf "%.2f", $1 / $2}'))"
	else
		echo '                             __           '
		echo '                   _ ,___,-`",-=-.        '
		echo '       __,-- _ _,-`_)_  (""``-._\ `.      '
		echo '    _,`  __ |,` ,-` __)  ,-     /. |      '
		echo '  ,`_,--`   |     -`  _)/         `\      '
		echo ',`,`      ,`       ,-`_,`           :     '
		echo ',`     ,-`       ,(,-(              :     '
		echo '     ,`       ,-` ,    _            ;     '
		echo '    /        ,-._/`---`            /      '
		echo '   /        (____)(----. )       ,`       '
		echo '  /         (      `.__,     /\ /,        '
		echo ' :           ;-.___         /__\/|        '
		echo ' |         ,`      `--.      -,\ |        '
		echo ' :        /            \    .__/          '
		echo '  \      (__            \    |_           '
		echo '   \       ,`-, *       /   _|,\          '
		echo '    \    ,`   `-.     ,`_,-`    \         '
		echo '   (_\,-`    ,`\")--,`-`       __\        '
		echo '    \       /  // ,`|      ,--`  `-.      '
		echo '     `-.    `-/ \`  |   _,`         `.    '
		echo '        `-._ /      `--`/             \   '
		echo '           ,`           |              \  '
		echo '          /             |               \ '
		echo '       ,-`              |               / '
		echo '      /      -hrr-      |             -`  '
		echo "        ______      _ __         __       "
		echo "       / ____/___ _(_) /__  ____/ /       "
		echo "      / /_  / __ \`/ / / _ \/ __  /       "
		echo "     / __/ / /_/ / / /  __/ /_/ / _ _     "
		echo "    /_/    \__,_/_/_/\___/\__,_(_|_|_)    "
		echo
		echo "<$1 random values> $3 times"
		echo "$(expr $FAILED \* 100 / $3)% is over $2 (Average: $(echo $SUM $3 | awk '{printf "%.2f", $1 / $2}'))"
	fi
}

########################################
#              MainScript              #
########################################

make -C $BUILD_DIRECTORY re
EXIT_CODE=$?

if [ ! -x $BUILD_DIRECTORY/"push_swap" ]; then
	echo $0": "$LIGHTRED"error: "$CLEAR"build failed with exit code "$EXIT_CODE
	exit $EXIT_CODE
fi
PUSH_SWAP=$BUILD_DIRECTORY/"push_swap"

if [ -x $BUILD_DIRECTORY/"checker" ]; then
	echo $0": "$DARKGRAY"note: "$CLEAR"found your bonus checker file. We will use it during the test!"
	BONUS_CHECKER=$BUILD_DIRECTORY/"checker"
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
	CHECKER="./checker_Mac"
elif [[ "$OSTYPE" == "linux-gnu"*  ]]; then
	CHECKER="./checker_linux"
else
	echo $0": "$LIGHTPURPLE"warning: "$CLEAR"unsupported OS type"
fi

if [ ! -x $CHECKER ]; then
	download_checker $CHECKER
fi

echo -n "Loading ..."
ARG="0 1 9 2 8 3 7 4 6 5"
run_push_swap $PUSH_SWAP > /dev/null
echo -n $LINE_CLEAR

scale_test 3 3 50
scale_test 5 12 200
scale_test 100 700 250
scale_test 500 5500 100
