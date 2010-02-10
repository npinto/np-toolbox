#!/bin/bash 

POSERAY_PATH=$HOME/.wine/drive_c/Program\ Files/poseray_install_3_12_2
POVRAY_CMD="povray +Q9 +FN +AM1 -GA -D +A -UA +H200 +W200"

if [[ -z "$1" || -z "$2" ]]; 
then 
    echo "Usage: $0 <input_filename> <output_dir>"; 
    exit 1; 
fi;

MYPATH=$(dirname "$0")

TMP_SUFFIX=$(mktemp -d)
TMP_POSERAY_PATH="${POSERAY_PATH}${TMP_SUFFIX}"
mkdir -p "$TMP_POSERAY_PATH"
cp -vf "$POSERAY_PATH"/PoseRay.exe "$TMP_POSERAY_PATH"/PoseRay.exe

INPUT="$1"
OUTPUT=\
$(python -c "import sys, os;
print os.path.abspath(sys.argv[1])" "$2")

INPUT_DIR=$(dirname $INPUT)
INPUT_FNAME=$(basename $INPUT)
INPUT_NOEXT=\
$(python -c "import sys, os;
print os.path.split(os.path.splitext(sys.argv[1])[0])[-1]" $INPUT)
INPUT_NOEXT=$(echo $INPUT_NOEXT | sed 's/\./_/') # Replace . with _
INPUT_NOEXT=$(echo $INPUT_NOEXT | sed 's/-/_/') # Replace - with _

# replace with our settings
#sed "s/export/export\/$INPUT_FNAME/" poseraysettings.ini.wine > "$TMP_POSERAY_PATH"/poseraysettings.ini
sed "s|export|$TMP_SUFFIX/export/$INPUT_FNAME|g" poseraysettings.ini.wine > "$TMP_POSERAY_PATH"/poseraysettings.ini
grep savetodir "$TMP_POSERAY_PATH"/poseraysettings.ini
EXPORT_DIR="$TMP_POSERAY_PATH/export/$INPUT_FNAME"
mkdir -p "$EXPORT_DIR"
#exit 99

echo Wine temporary $(grep savetodir "$TMP_POSERAY_PATH"/poseraysettings.ini)
echo "OUTPUT=$OUTPUT"
#exit 99

echo Processing ...

set -x 

cd $INPUT_DIR && 
wine "$TMP_POSERAY_PATH"/PoseRay.exe -load $INPUT_FNAME -convert 1 -close < /dev/null && 
mkdir -p $OUTPUT &&
mv -f "$EXPORT_DIR"/* $OUTPUT/ &> /dev/null && 
cd $OUTPUT && ls -alF &&
for pov in *_POV_scene.pov;
do sed 's/^background .*/background { color rgb<.5,.5,.5>  }/' $pov > $pov.new &&
mv -f $pov{.new,} &&
#$POVRAY_CMD +L./ +I./${INPUT_NOEXT}_POV_scene.pov +O./${INPUT_NOEXT}_POV_scene.png 
$POVRAY_CMD +L./ +I./$pov +O./$pov.png;
done;

rm -rvf "$TMP_POSERAY_PATH"

set -

echo Done!




