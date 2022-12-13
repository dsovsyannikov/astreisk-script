#!/bin/bash
# A Script to Convert FreePBX call recordings from WAV to MP3

while [ 1 ]
do
sleep 1s
wavfilenopath="$(mysql --default-character-set=utf8 -N -e "SELECT recordingfile FROM asteriskcdrdb.cdr WHERE calldate > CURDATE() AND billsec > 0 AND recordingfile LIKE '%wav' LIMIT 1" | grep wav)"
echo $wavfilenopath
if [ -z "$wavfilenopath" ]
then
  echo "\$wavfilenopath пустая."
  sleep 10s
else
  echo "\$wavfilenopath НЕ пустая."

wavfile="$(echo /var/spool/asterisk/monitor/$(date +"%Y/%m/%d")/$wavfilenopath)"

test -e "$wavfile" && {
echo "FOUND WAV FILE!"
actualsize=$(stat -c %s $wavfile)

if [ $actualsize -lt 45 ]; then
    rm -f $wavfile
    echo "DELETE EMPTY WAV FILE!"
fi
}
test -e "$wavfile" && {
echo "CONVERT TO MP3!"
mp3file="$(echo $wavfile | sed 's/wav/mp3/')"
mp3filenopath="$(echo $wavfilenopath | sed 's/wav/mp3/')"
echo $wavfile
echo $mp3file
lame -V 6 -q 0 $wavfile $mp3file
stat -c%s $wavfile
stat -c%s $mp3file
mysql --default-character-set=utf8 -D asteriskcdrdb <<<"UPDATE cdr SET recordingfile='$mp3filenopath' WHERE recordingfile='$wavfilenopath' AND calldate > CURDATE()"
rm -f $wavfile
} || {
echo "NOT FOUND WAV FILE!"
mp3filenopath="$(echo $wavfilenopath | sed 's/wav/mp3/')"
echo $mp3filenopath
mysql --default-character-set=utf8 -D asteriskcdrdb <<<"UPDATE cdr SET recordingfile='$mp3filenopath' WHERE recordingfile='$wavfilenopath' AND calldate > CURDATE()"
}

test -e "$wavfile" && {
        echo "WAV STILL EXIST!"
} || {
      	echo "WAV FILE DELETED AFTER CONVERSION!"
}
fi

done

