# document

# bertdotcheater
alias cf="cheater find"

# pdfgrep
pdf.search () { ls *.pdf | grep -i "${1}" | while read book;do echo $book;pdfgrep "$2" "${book}";done; }
pdf.grep(){ pdfgrep $1 $2 ; }
pdf.pillar_daily() { 
  pdfgrep 'E\.' $1 | head -6
  echo -e "Ok which errcode do you want to search for?"
  read search_term
  pdfgrep "${search_term}" $1 | awk '{print $1,$2,$(NF-1)}' | sort -k3 -n | grep -ve '^E\.'
}

excel.read () 
{ 
    usage="usage: ${FUNCNAME[0]} [-file:<excel_file>] [-sheets:'<sheet_name>;<sheet_name>'] [-columns:<colnum>,<colnum>,colnum,...] [-rcolumns:<colnum>-<colnum>]
[-filter:<filter1,filter2,...>] [-skip_rows:<num>] [-append:<column>,<string>] [-yaml] [--info]"
    if [[ $# -lt 1 ]];then echo $usage;return 0;fi
    if [[ "$*" =~ .*--info.* ]];then process="import xlrd;import sys;file = sys.stdin.read().split(':')[1].strip();xls=xlrd.open_workbook(file);print('Available Sheets:%s' % [(i, name) for i,name in enumerate(xls.sheet_names())])";echo $1 | python -c "$process";return 0;fi
    process="import re;import sys;import yaml;import json;import xlrd;import csv;import re;
def to_s(v):
  return [d.encode('utf-8') if not isinstance(d, (int, float, complex)) else str(int(d)) for d in v]
arguments = sys.stdin.read()
# arguments = '-file:/git/viper-config-cox/rdz/current/rdz_phxn.xlsx -sheets:RDZ Stream Information -filter:8871338682467360163 -dict:yes -skip_rows:2'
arguments = dict(item.strip().replace('-','',1).split(':',1) if re.search('^-',item) else item.strip().split(':',1) for item in re.split('\s-',arguments))
write_out = False
if arguments.get('wo'):
  csv_file = open('out.csv', 'wb')
  wr = csv.writer(csv_file, quoting=csv.QUOTE_ALL)
  write_out = True
excel_files=arguments['file'].split(';')
sheets=arguments['sheets'].split(';')
if sheets[0] == '*':
  for excel_file in excel_files:
    xls=xlrd.open_workbook(excel_file)
    sheets = ['%s' % s for s in xls.sheet_names()]
no_header = False if not arguments.get('no_header') else True
to_dict = False if not arguments.get('to_dict') else True
to_yaml = False if not arguments.get('to_yaml') else True
to_json = False if not arguments.get('to_json') else True
skip_rows = 0 if not arguments.get('skip_rows') else int(arguments['skip_rows'])
columns = None if not arguments.get('columns') else [int(c) for c in arguments['columns'].split(',')]
start, end  = (None,None) if arguments.get('columns') or not arguments.get('rcolumns') else [int(c) for c in arguments['rcolumns'].split('-')]
filters = None if not arguments.get('filter') else re.split(';|,| |\n',str(arguments['filter']))
append = '' if not arguments.get('append') else arguments.get('append').split(',')
data = []
for xlsheet in sheets:
  _sh = [xlrd.open_workbook(excel_file.strip()).sheet_by_name(xlsheet) for excel_file in excel_files]
  for sh in _sh:
    _sh_data = [sh.row_values(row)[start:end] for row in [range(sh.nrows)[skip_rows:]]]
quit()
c = 0

for l in data:
  if filters:
      if any([[d for d in l if re.search(''.join(f),d)] for f in filters]):
          if append:
              print(','.join(['{}{}'.format(d[1],append[1]) if d[0] == int(append[0]) else d[1] for d in enumerate(l)]))
              if write_out:
                wr.writerow(['{}{}'.format(d[1],append[1]) if d[0] == int(append[0]) else d[1] for d in enumerate(l)])
          else:
              if to_yaml:
                print(yaml.safe_dump(dict([(l[0],l[1:])]), default_flow_style=False))
              elif to_dict:
                print(dict([(l[0],l[1:])]))
              elif to_json:
                print(json.dumps(dict([(l[0],l[1:])])))
              else:
                print(','.join(l[:end]))
              if write_out:
                wr.writerow(l[:end])
  else:
      if append:
          print(','.join(['{}{}'.format(d[1],append[1]) if d[0] == int(append[0]) else d[1] for d in enumerate(l)]))
          if write_out:
            wr.writerow(['{}{}'.format(d[1],append[1]) if d[0] == int(append[0]) else d[1] for d in enumerate(l)])
      else:
        if to_dict:
          print(dict(l[0],l[1:]))
        elif to_json:
          print(json.dumps(dict(l[0],l[1:])))
        elif to_yaml:
          print('printing out yaml')
          print(yaml.dumps(dict(l[0],l[1:])))
        else:
          print(','.join(l[:end]))
        if write_out:
          wr.writerow(l[:end])

# data=dict(zip(header.split(','),rows.split(',')))
# print '\n'.join(['{}:{}'.format(d,v) for d,v in data.iteritems() if all([d,v])])
";
    echo $* | python -c "$process"
}

xmind.convert(){
  [ $# -lt 1 ] && echo "Usage: ${FUNCNAME[0]} [/path/to/xmind_document] >" >&2 && return 1
  ruby "${XMorgPath}" -t markdown -o "${1}.md" "${1}" --pandoc-options="--atx-headers"
}

xml.to.json() {
  if [ $# -lt 1 ]; then echo "Usage: ${FUNCNAME[0]} <file>"; return 1; fi
  process="import json;import sys;import xmltodict;file=line=sys.stdin.readlines()[0].replace('\n','');
def convert(xml_file, xml_attribs=True):
    with open(xml_file, 'rb') as f:
        d = xmltodict.parse(f, xml_attribs=xml_attribs)
        print json.dumps(d, indent=4)
convert(file)
"
  echo $1 | python -c "$process"
}

document.spell-check() {
  if [ $# -lt 1 ]; then echo "Usage: ${FUNCNAME[0]} [file]"; return 1; fi
  aspell check "${1}" ${backup-'--dont-backup'}
}

document.markdown2html(){

  # Display help if insufficient args
  if [[ $# -lt 1 ]];then 
    help ${FUNCNAME[0]} "pandoc [some/path/somefile] [options]";
    return 1
  fi

  if ! [[ ($(type /usr/{,local/}{,s}bin/livereload 2> /dev/null)) || ($(which livereload)) ]];then
    echo This function requires livereload
    echo Make sure you are using python 3.6+
    return 1
  else
    while true;
      do ${@}
      sleep 10; 
    done &
    livereload . -p 9000
  fi

}

# sublime text
subl() { 
  if [[ $1 == '-w' ]];then
    "${subl_exe_path}" -a ${*}
  else
    "${subl_exe_path}" -a "${*}"
  fi
}

export EDITOR="'${subl_exe_path}' -w"