#!/bin/bash
# A Script to Convert FreePBX call recordings from WAV to MP3

# delete empty directory
find /var/spool/asterisk/monitor/ -type d -empty -delete

# delete old files
find /var/spool/asterisk/monitor/ -type f -mtime +700 -exec rm -rf {} \;

# delete small empty wav files
find /var/spool/asterisk/monitor -type f -name *.wav -size -45c -delete


while [ 1 ]
do
sleep 1s
result="$(mysql -B -N -e "SELECT recordingfile,uniqueid,date(calldate) FROM asteriskcdrdb.cdr WHERE calldate < CURDATE() AND recordingfile LIKE '%wav' ORDER BY calldate DESC LIMIT 1")"
echo $result
wavfilenopath="$(echo $result | awk '{ print $1;}')"
id="$(echo $result | awk '{ print $2;}' | sed -r 's/\..+//')"
dirdate="$(echo $result | awk '{ print $3;}' | sed 's/-/\//g')"
dt="$(echo $result | awk '{ print $3;}')"
echo $dirdate
echo $wavfilenopath
if [ -z "$wavfilenopath" ]
then
  echo "\$wavfilenopath empty."
  exit 1
else
  echo "\$wavfilenopath NOT empty."
wavfile="$(find /var/spool/asterisk/monitor/$dirdate/ -name $wavfilenopath -print)"

test -e "$wavfile" && {
mp3file="$(echo $wavfile | sed 's/wav/mp3/')"
mp3filenopath="$(echo $wavfilenopath | sed 's/wav/mp3/')"
echo $wavfile
echo $mp3file
lame -V 6 -q 0 $wavfile $mp3file
stat -c%s $wavfile
stat -c%s $mp3file
# update CDR record after convert from wav to mp3
mysql -D asteriskcdrdb <<<"UPDATE cdr SET recordingfile='$mp3filenopath' WHERE uniqueid LIKE '$id%' AND recordingfile='$wavfilenopath'"
rm -f $wavfile
} || {
mp3filenopath="$(echo $wavfilenopath | sed 's/wav/mp3/')"
echo $mp3filenopath
# update CDR record without convert from wav to mp3
mysql -D asteriskcdrdb <<<"UPDATE cdr SET recordingfile='$mp3filenopath' WHERE uniqueid LIKE '$id%' AND recordingfile='$wavfilenopath'"
}

test -e "$wavfile" && {
        echo "WAV STILL EXIST!"
} || {
        echo "WAV FILE DELETED AFTER CONVERSION!"
}
fi

done