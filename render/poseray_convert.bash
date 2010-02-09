#!/bin/bash

POSERAY_PATH=$HOME/.wine/drive_c/Program\ Files/poseray_install_3_12_2
POVRAY_CMD="povray +Q9 +FN +AM1 -GA -D +A -UA +H200 +W200"

if [[ -z "$1" || -z "$2" ]]; 
then 
    echo "Usage: $0 <input_filename> <output_dir>"; 
    exit 1; 
fi;

MYPATH=$(dirname "$0")

INPUT="$1"
OUTPUT=\
$(python -c "import sys, os;
print os.path.abspath(sys.argv[1])" "$2")


INPUT_DIR=$(dirname $INPUT)
INPUT_FNAME=$(basename $INPUT)
INPUT_NOEXT=\
$(python -c "import sys, os;
print os.path.split(os.path.splitext(sys.argv[1])[0])[-1]" $INPUT)

# backup previous poseray settings
cp -vf "$POSERAY_PATH"/poseraysettings.ini{,.bak}

# replace with our settings
cp -vf "$MYPATH"/poseraysettings.ini.wine "$POSERAY_PATH"/poseraysettings.ini

cd $INPUT_DIR && 
wine "$POSERAY_PATH"/PoseRay.exe -load $INPUT_FNAME -convert 1 -close && 
mkdir -p $OUTPUT &&
mv -vf "$POSERAY_PATH"/export/${INPUT_NOEXT}_POV_* $OUTPUT/ && 
$POVRAY_CMD +L${OUTPUT} +I${OUTPUT}/${INPUT_NOEXT}_POV_scene.pov +O${OUTPUT}/${INPUT_NOEXT}_POV_scene.png

# revert settings changes
cp -vf "$POSERAY_PATH"/poseraysettings.ini{.bak,}

echo Done!




