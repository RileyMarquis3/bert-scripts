# date
alias tolocaltime='python -c "import sys;import arrow;print arrow.get('{}'.format(sys.stdin.readlines()[0]), 'YYYY-MM-DDTHH:mm:ss.SSSSSSSS').to('local')"'
alias stopwatch='echo Starting stopwatch! Press ENTER to Stop!;time read'