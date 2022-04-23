# media
## imagemagick
image.split () {
  if [[ $# -lt 1 ]]; then echo "Usage: ${FUNCNAME[0]} <imagefile>";return 1;fi  
  image=$1
  BINARY=convert
  if ! [[ ($(type /usr/{,local/}{,s}bin/${BINARY} 2> /dev/null)) || ($(which $BINARY)) ]];then
    echo "This function requires $binary, brew install imagemagick"
    return 1
  else
    convert "${image}" -crop 2x3@ +repage +adjoin "${image%.*}_%d.${image#*.}"
  fi  
}

## music
mp3.play () {
  [ $# -lt 1 ] && echo "Usage: ${FUNCNAME[0]} <folderofmp3s>" && return 1
  folder=$1
  ls "${folder}"/*.mp3 | while read mp3;do echo playing $mp3;afplay "$mp3";done
}

mp3.play.next () { pkill afplay ;}

youtube.get.mp3() {

  if [ $# -lt 1 ]; then echo "Usage: ${FUNCNAME[0]} <url>";return 1;fi
  binary=youtube-dl
  if ! (which $binary || type -all $binary || [ -f $binary ]) >/dev/null 2>&1;then
    echo "This function requires $binary, see installation instructions: https://www.continuum.io/downloads"
    return 1
  else
    $binary --extract-audio --audio-format mp3 "${1}"
  fi
}

youtube.get.mp4() {
  if [[ $# -lt 1 ]]; then echo "Usage: ${FUNCNAME[0]} <url>";return 1;fi
  binary=youtube-dl
  for path in `echo $PATH | tr ':' '\n'`;do type ${path}/${binary} 2>/dev/null;done
  if ! [[ ($(type /usr/{,local/}{,s}bin/${BINARY} 2> /dev/null)) || ($(which $BINARY)) ]];then
    echo "This function requires $binary, sudo pip install youtube-dl"
    return 1
  else
    youtube-dl -f mp4 "${1}"
  fi
}

video.mux()
{
  [ $# -lt 2 ] && echo "Usage: ${FUNCNAME[0]} [video.ext] [audio.ext] [output.ext](optional) (--match_length)" && return 1
  video=$1
  audio=$2
  video_filename=${1%.**}
  video_extention=${1#**.}
  if [[ "$*" =~ .*--match_length.* ]];then
    audio_duration=$(ffprobe -i ${audio} -show_entries format=duration -v quiet -of csv="p=0")
    video_duration=$(ffprobe -i ${video} -show_entries format=duration -v quiet -of csv="p=0")
    muxed_filename="${video_filename%.**}_muxed"
    n_loops=$(echo "(${audio_duration} / ${video_duration}) + 1"|bc)
    >files.txt
    for i in $(seq 1 $n_loops); do echo -e "file ${video}"; done >> files.txt
    ffmpeg -i ${audio} -f concat -i files.txt -c:v copy -shortest ${muxed_filename}.${video_extention}
  else
    if [[ -z $3 ]];then muxed_filename="${video_filename%.**}_muxed";else muxed_filename=${3%.**}_muxed;fi
    muxed_output_file="${muxed_filename}.${video_extention}"
    if [[ ! -f "${video}" ]];then echo "I couldn't find ${video}";return 1;fi
    if [[ ! -f "${audio}" ]];then echo "I couldn't find ${audio}";return 1;fi
    ffmpeg -i "${video}" -i "${audio}" -c:v copy -shortest "${muxed_output_file}"
  fi
}


video.convert()
{
  [ $# -lt 1 ] && echo "Usage: ${FUNCNAME[0]} [file]" && return 1
  media_file=${1%.*}
  if [[ $os_is_windows ]];then
    pre=""
  else
    pre=screen.send
  fi
  if [[ "$1" =~ .*mkv ]];then
    screen.send ffmpeg -i "${$1}" -strict experimental -y -c copy -c:a aac -movflags +faststart -crf 22 "${media_file}.mp4"
  else
    screen.send ffmpeg -i $1 -vcodec h264 -acodec aac -strict -2 $media_file.mp4
  fi
}

mp4.compress()
{
  [ $# -lt 1 ] && echo "Usage: ${FUNCNAME[0]} [input_file] [output_file]" && return 1
  ffmpeg -y -i $1 -c:v libx264 -preset medium -b:v 555k -pass 1 -c:a libfdk_aac -b:a 128k -f mp4 /dev/null && \
  ffmpeg -i $1 -c:v libx264 -preset medium -b:v 555k -pass 2 -c:a libfdk_aac -b:a 128k $2
}

mp4.thumb() {
  [ $# -lt 1 ] && echo "Usage: ${FUNCNAME[0]} [input_file] [thumbnail]" && return 1  
  ffmpeg -loglevel panic -ss 00:00:01.500 -i "$1" -frames:v 1 "$2" 
}