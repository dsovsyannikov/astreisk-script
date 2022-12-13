#!/bin/bash
# A Script to Convert FreePBX call recordings from WAV to MP3

# delete empty directory
find /var/spool/asterisk/monitor/ -type d -empty -delete

# delete old files
find /var/spool/asterisk/monitor/ -type f -mtime +700 -exec rm -rf {} \;

# delete small empty wav files
find /var/spool/asterisk/monitor -type f -name *.wav -size -45c -delete
uid=0

while [ 1 ]
do
# sleep 1s
result="$(mysql --default-character-set=utf8 -B -N -e "SELECT recordingfile,uniqueid,date(calldate) FROM asteriskcdrdb.cdr WHERE uniqueid >='$uid' AND calldate < CURDATE() AND recordingfile LIKE '%wav' ORDER BY uniqueid LIMIT 1")"
echo $result
wavfilenopath="$(echo "$result" | awk -F '\t' '{ print $1;}')"
id="$(echo "$result" | awk -F '\t' '{ print $2;}' | sed -r 's/\..+//')"
uid="$(echo "$result" | awk -F '\t' '{ print $2;}')"
dirdate="$(echo "$result" | awk -F '\t' '{ print $3;}' | sed 's/-/\//g')"
dt="$(echo "$result" | awk -F '\t' '{ print $3;}')"

if [ -z "$wavfilenopath" ]
then
  echo "\$wavfilenopath not define. Exit"
  exit 1
else
  echo "\$wavfilenopath define."
wavfile="$(echo /var/spool/asterisk/monitor/$dirdate/$wavfilenopath)"

test -e "$wavfile" && {
actualsize=$(stat -c %s $wavfile)
if [ $actualsize -lt 45 ]; then
    rm -f $wavfile
else

mp3file="$(echo $wavfile | sed 's/wav/mp3/')"
mp3filenopath="$(echo $wavfilenopath | sed 's/wav/mp3/')"
echo $wavfile
echo $mp3file
lame -V 6 -q 0 $wavfile $mp3file
stat -c%s $wavfile
stat -c%s $mp3file
# update CDR record after convert from wav to mp3
mysql --default-character-set=utf8 -D asteriskcdrdb <<<"UPDATE cdr SET recordingfile='$mp3filenopath' WHERE uniqueid LIKE '$id%' AND recordingfile='$wavfilenopath'"
rm -f $wavfile
fi

} || {

mp3filenopath="$(echo $wavfilenopath | sed 's/wav/mp3/')"
echo $mp3filenopath
# update CDR record without convert from wav to mp3
mysql --default-character-set=utf8 -D asteriskcdrdb <<<"UPDATE cdr SET recordingfile='$mp3filenopath' WHERE uniqueid LIKE '$id%' AND recordingfile='$wavfilenopath'"
}

test -e "$wavfile" && {
        echo "WAV STILL EXIST!"
} || {
        echo "WAV FILE DELETED AFTER CONVERSION!"
}
fi

done

#mysql -B -N -e "SELECT recordingfile,uniqueid FROM asteriskcdrdb.cdr WHERE calldate < CURDATE() AND recordingfile LIKE '%wav' ORDER BY calldate DESC LIMIT 1" | awk '{ wavfilenopath = $0; id = $1 }'
