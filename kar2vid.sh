#!/usr/bin/env bash

if [ $# -eq 0 ]; then
    echo "ERROR: Input karaoke file required"
    exit -1
fi
KARFILE="$1"
KARFILEMP3=$(echo "$KARFILE" | sed -re 's/mid|midi|kar/mp3/' -)
KARFILEMP4=$(echo "$KARFILE" | sed -re 's/mid|midi|kar/mp4/' -)

for utility in timidity ffmpeg
do
    echo "[INFO] Checking for '$utility'..."
    which $utility >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "[FATAL] '$utility' was not found, aborting..."
        exit -1
    fi
done

echo "[INFO] Removing MP3 file, if any..."
/bin/rm -f "$KARFILEMP3" "$KARFILEMP4"

echo "[INFO] Extracting sound from '$KARFILE' file to MP3 file..."
timidity "$KARFILE" -Ow -o - | ffmpeg -i - -acodec libmp3lame "$KARFILEMP3"

echo "[INFO] Converting '$KARFILE' file to set of PNG images..."
python3 pykar.py --dump=frame_#####.png --dump-fps=25.00 "$KARFILE"

echo "[INFO] Merging PNG images and sound to video..."
ffmpeg -framerate 25.00 -pattern_type glob -i 'frame_*.png' \
  -i "$KARFILEMP3" -c:a copy -shortest -c:v libx264 -pix_fmt yuv420p "$KARFILEMP4"
echo "[INFO] Video is ready in '$KARFILEMP4'"

echo "[INFO] Removing temporary files..."
/bin/rm -f "$KARFILEMP3" frame_*.png
