# productivity
function remind.me {
  if ! [[ "$OSTYPE" =~ .*darwin.* ]]; then echo "This works only on OSX";return 1;fi
  usage="Usage: 
  ${FUNCNAME[0]} to \"Submit TPS reports\" on $(date +%D' '%H:%M:%S%p )
  or
  ${FUNCNAME[0]} to \"Submit TPS reports\" in 30 minutes
  or
  ${FUNCNAME[0]} to \"Submit TPS reports\" in 1 hour
  or
  ${FUNCNAME[0]} to \"Submit TPS reports\" at 5:00PM
  Specifying a Reminders List:
    ${FUNCNAME[0]} to \"Submit TPS reports\" at 5:00PM --list Personal
  "
  [ $# -lt 1 ] && echo -e "${usage}" >&2 && return 1
  list="Reminders"
  while (( "$#" )); do
    if [[ "$1" =~ .*--list.* ]]; then 
      list=$2;
    else 
      args="${args} $1"
    fi    
    shift
  done  
  osascript - ${args}<<END
    on run argv
      set AppleScript's text item delimiters to " "
      set reminder_text to item 2 thru item -4 of argv as string
      if item -3 of argv equals "at" then
        set reminder_text to item 2 thru item -4 of argv as string
        set reminder_date to date (item -2 of argv & " " & item -1 of argv)
      else if item -1 of argv contains "minute" then
        set minutes to item -2 of argv * 60
        set reminder_date to (current date + minutes)
        -- display dialog reminder_date as string
      else if item -1 of argv contains "hour" then
        set minutes to item -2 of argv * 3600
        set reminder_date to (current date + minutes)
      else
        set reminder_date to date (item -2 of argv & " " & item -1 of argv)
      end if
      set current_date to (current date + 3600) as string
      tell application "Reminders"
        set Reminders_List to list "${list}"
        tell Reminders_List
          make new reminder at end with properties {name:reminder_text, due date:reminder_date, remind me date:reminder_date }
        end tell
      end tell
    end run
END
args=""
}

word.lookup () {
  PREFIX=eval
  declare -A params=(
  ["--word|-w$"]="[word]"
  ["--help|-h$"]="Display usage and exit"
  ["--dry"]="Dry Run"
  )
  # Display help if no args
  if [[ $# -lt 1 ]];then help ${FUNCNAME[0]} "${params}";return;fi
  # Parse arguments
  eval $(create_params)
  # Display help if applicable
  if [[ -n $help ]];then help ${FUNCNAME[0]} "${params}";return;fi
  # DRY RUN LOGIC
  if [[ -n $dry ]];then 
    PREFIX=echo
  fi  
  ${PREFIX} rundll32.exe WWEB32.DLL,ShowRunDLL "${word}"
}

word.translate()
{
  if [ $# -lt 1 ]; then echo "Usage: ${FUNCNAME[0]} <word> <language, e.g. es>"; return 1; fi
  process="from PyDictionary import PyDictionary;dictionary=PyDictionary();import sys;
args = sys.stdin.readlines()
word = str(args[0]).strip()
language = str(args[1]).strip() if len(args) > 1 else 'es'
print (dictionary.translate(word,language))"
  echo $1 | python -c "$process"
}

