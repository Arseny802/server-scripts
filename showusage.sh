#!/bin/bash
# ------------------------------------------------------------------
# [Ravin A.] ShowUsager
#            Shows server usage by apache access log files
#            Prints requests amount with client's IP per day
# ------------------------------------------------------------------

# Summary
VERSION=0.2.0
TITLE=showusager
SUBJECT=$TITLE-$VERSION-process

# Default arguments
year=$(date +"%Y")
file="access.*"
invalid_verbosity=-1
available_verbosity=2
verbosity_level=0
specific_month=0
specific_day=0

# Usage long read message
USAGE="Usage: command -yfhv args\n\n"
USAGE="$USAGE\t -v -- [no arguments] display script version and exit;\n"
USAGE="$USAGE\t -h -- show this help message and exit;\n"
USAGE="$USAGE\t -y -- use specific year to filter result;\n"
USAGE="$USAGE\t -m -- use specific month to filter result, available: 1 - 12;\n"
USAGE="$USAGE\t -d -- use specific day to filter result, available: 1 - 31;\n"
USAGE="$USAGE\t -v -- verbosity level, available: 0 - 2 or 'v' or 'vv';\n"
USAGE="$USAGE\t -f -- use specific file to get statistics;\n\n"
USAGE="$USAGE\tExample: $0 -d 2 -y 2019 -f access.ssl.log"

# --- Options processing -------------------------------------------
function ParseVerbosity {
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        # integer
        if [ "$1" -le "$available_verbosity" ]; then
            if [ "$1" -ge "0" ] ; then
                echo "$1"
                return 0
            fi
        fi
        echo "-1"
        return 0
    else
        # string
        if [ "$1" = "v" ]; then
            echo "1"
            return 0
        fi
        if [ "$1" = "vv" ]; then
            echo "2"
            return 0
        fi
        echo "-1"
        return 0
    fi
}

while getopts ":y:m:d:f:v:h" optname; do
    case "$optname" in
      "y")
        echo "Filtering by year: $OPTARG."
        year=$OPTARG
        ;;
      "m")
        if [ "$specific_month" -ge "13" ] ; then
            echo "Specified month is not valid!"
            exit 0;
        fi
        echo "Filtering by month: $OPTARG."
        specific_month=$OPTARG
        ;;
      "d")
        if [ "$specific_month" -ge "32" ] ; then
            echo "Specified day is not valid!"
            exit 0;
        fi
        echo "Filtering by day: $OPTARG."
        specific_day=$OPTARG
        ;;
      "f")
        echo "Using file: '$OPTARG'."
        file=$OPTARG
        if ! [ -f "$file" ]; then
            echo "Specified file does not exist!"
            exit 0;
        fi
        ;;
      "v")
        verbosity_level=$(ParseVerbosity $OPTARG)
        if [ "$verbosity_level" -eq "$invalid_verbosity" ]; then
            echo "Invalid verbosity version specified!"
            exit 0;
        fi
        echo "Using verbosity level: $verbosity_level."
        ;;
      "h")
        echo -e $USAGE
        exit 0;
        ;;
      "?")
        echo "Unknown option '$OPTARG'."
        exit 0;
        ;;
      ":")
        if [ "$OPTARG" = "v" ]; then
            echo "Version $VERSION"
            exit 0;
        else
            echo "No argument value for option '$OPTARG'"
            exit 0;
        fi
        ;;
      *)
        echo "Unknown error while processing options"
        exit 0;
        ;;
    esac
done

shift $(($OPTIND - 1))

# --- Locks -------------------------------------------------------
LOCK_FILE=/tmp/$SUBJECT.lock
if [ -f "$LOCK_FILE" ]; then
   echo "Script is already running"
   exit
fi

trap "rm -f $LOCK_FILE" EXIT
touch $LOCK_FILE

# --- Body --------------------------------------------------------
#  SCRIPT LOGIC GOES HERE

function ShowStatistics {
    local command="cat $file | grep \"$1\" | awk '{ print \$1 }'"
    command="$command | sort | uniq -c | sort -n"
    local result=$(eval "$command")
    if [ "$verbosity_level" -gt "0" ] ; then
        if test -z "$result"; then
            if [ "$verbosity_level" -ge "2" ] ; then
                printf "No result for date $date\n"
            fi
        else
            printf "Date $date:\n$result\n"
        fi
    else
        if ! test -z "$result"; then
            printf "$result\n"
        fi
    fi
}

function ShowUsageByDay {
    local MONTHS=(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
    local date="$3/${MONTHS[$(($2-1))]}/$1"
    ShowStatistics $date
}

function ShowUsageByMonth {
    local year=$1
    local month=$2
    if [ "$specific_day" -gt "0" ] ; then
        ShowUsageByDay $year $month $specific_day
    else
        for (( day=1; day <= 31; ++day )); do
            ShowUsageByDay $year $month $day
        done
    fi
}

function ShowUsageByYear {
    year=$1
    if [ "$specific_month" -gt "0" ] ; then
        ShowUsageByMonth $year $specific_month
    else
        for (( month=1; month <= 12; ++month )); do
            ShowUsageByMonth $year $month
        done
    fi
}

function Main {
    ShowUsageByYear $year
}

Main
# -----------------------------------------------------------------
