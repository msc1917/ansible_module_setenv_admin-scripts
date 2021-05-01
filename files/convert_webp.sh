#! /bin/bash

###
#
# Konvertiert files bzw. verzeichnisbäume ins webP-Format
#
# Version 1.0    2021.04.30    Martin Schatz     First Version
#
#
# Todos:
#
###

# Lade Config-Parameter

function findEmptyDir {
if [ -f "${1}" ]
then
    convertFile="${1}"
    fileOwner="$(ls -ltr "${convertFile}" | cut -f 3 -d " ")"
    fileGroup="$(ls -ltr "${convertFile}" | cut -f 4 -d " ")"
    if ["${fileOwner}" = "$(whoami)" ]
    then
        cwebp -quiet -q 60 "${convertFile}" -o "${convertFile%.*}.webp"
        exitCode=${?}
    else
        sudo cwebp -quiet -q 60 "${convertFile}" -o "${convertFile%.*}.webp"
        exitCode=${?}
    fi
    oldFilesize="$(du -b "${convertFile}" | cut -f 1)"
    newFilesize="$(du -b "${convertFile%.*}.webp" | cut -f 1)"
    singleFilename="$(basename "${convertFile}")"
    singleDirname="$(dirname "${convertFile}")"
    if [ ${exitCode} -le 0 ]
    then
        echo " => Konvertiere \"${singleFilename}\" nach \"${singleFilename%.*}.webp\" im Verzeichnis \"${singleDirname}\" ($(numfmt --to iec --format "%1.2f" ${oldFilesize}) => $(numfmt --to iec --format "%1.2f" ${newFilesize}))"
        if ["${fileOwner}" = "$(whoami)" ]
        then
            rm "${convertFile}"
        else
            sudo rm "${convertFile}"
            sudo chown ${fileOwner}:${fileGroup} "${convertFile%.*}.webp"
        fi
    else
        echo " => Konvertieren von \"${singleFilename}\" nach \"${singleFilename%.*}.webp\" im Verzeichnis \"${singleDirname}\" fehlgeschlagen"
        if [ -f "${convertFile%.*}.webp" ]
        then
            if ["${fileOwner}" = "$(whoami)" ]
            then
                rm "${convertFile%.*}.webp"
            else
                sudo rm "${convertFile%.*}.webp"
            fi
        fi
fi
}

if [ "${1}" = "" ]
then
    echo "Keine Dateien angegeben"
    exit 1
elif [ -f "${1}" ]
    echo "Konvertiere Datei \"${1}\":"
    convertFile "${1}"
elif [ -d "${1}" ]
    echo "Konvertiere Verzeichnisbaum \"${1}\":"
    oldDirsize="$(du -b "${1}" | cut -f 1)"
    find "${1}" -type f | grep -Ei "\.(png|jpeg|jpg|tiff|bmp)$" | while read FILENAME
    do
        convertFile "${FILENAME}"
    done
    newDirsize="$(du -b "${1}" | cut -f 1)"
    echo " => Verzeichnis \"${1}\" wurde konvertiert ($(numfmt --to iec --format "%1.2f" ${oldDirsize}) => $(numfmt --to iec --format "%1.2f" ${newDirsize}))"
else
    echo "Weder Datei noch Verzeichnis als Parameter angegeben (\"${1}\")."
    exit 1
fi