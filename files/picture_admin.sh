#! /bin/bash

###
#
# Tool für den Foto-Filespace am Storage
#
# Version 1.0    2021.04.20    Martin Schatz     First Version
#
###

# Lade Config-Parameter
. ~/etc/script_config.cfg
imagepath="$(echo "${imagepath}" | sed "s/\/$//g")"
imagefspath="$(echo "${imagefspath}" | sed "s/\/$//g")"

function check_filesystems {
    echo "Pruefe Verzeichnisse:"
    # Mounte Filesystem
    if cat /proc/mounts | cut -f 2 -d " " | grep -qs "${imagefspath}"; then
      echo "  - Foto-Filesystem \"${imagefspath}\" ist gemounted."
    else
      echo "  - Foto-Filesystem \"${imagefspath}\" fehlt und wird gemounted."
      sudo mount ${imagefspath}
      if [ ${?} -ne 0 ]
      then
        echo "  - Fehler beim mounten, beende..."
        exit 10
      else
        echo "  - Filesystem wurde gemounted."
      fi
    fi
    echo ""
}

function genDir {
    if [ -d "${1}" ]
    then
        false && echo "  - Verzeichnis \"${1}\" bereits vorhanden."
    else 
        echo "  - Erstelle Verzeichnis \"${1}\"."
        sudo mkdir "${1}"
    fi
}

function delDir {
    if [ -d "${1}" ]
    then
        echo "  - Verzeichnis \"${1}\" wird entfernt."
        sudo rmdir "${1}"
    fi
}

function moveFile {
    if [ -f "${1}" ]
    then
        targetdir="$(dirname "${2}")"
        if [ -d "${targetdir}" ]
        then
            false && echo "  - Verzeichnis \"${targetdir}\" bereits vorhanden."
        else 
            echo "  - Erstelle Verzeichnis \"${targetdir}\"."
            sudo mkdir -p "${targetdir}"
        fi
    echo "  - Verschiebe File \"$(basename "${1}")\" nach \"${targetdir}/\"."
    sudo mv "${1}" "${2}"
    fi
}

function findEmptyDir {
    local base_path=${1}
    local base_year=${2}
    echo "  - Pruefe Verzeichnis \"${base_path}/${base_year}\"."
    if [ -d "${base_path}/${base_year}" ]
    then
        find "${base_path}/${base_year}" -type d -empty | while read directory
        do
            delDir "${directory}"
        done
    fi
}


function build_subdirectories {
    allMonths="01 02 03 04 05 06 07 08 09 10 11 12"
    thisMonth="$(date +%m)"
    local base_path=${1}
    local base_year=${2}
    local base_structs=${3}
    if [ ! -d "${base_path}/${base_year}" ]
    then
        genDir "${base_path}/${base_year}"
    fi

    for base_struct in ${base_structs};
    do
        genDir "${base_path}/${base_year}/${base_year}XXXX ${base_struct}"
        for month in ${allMonths};
        do
            genDir "${base_path}/${base_year}/${base_year}XXXX ${base_struct}/${base_year}${month}XX ${base_struct}"
        done
    done
}

function build_directory_tree {
if [ "${1}" = "" ]
then
    thisYear="$(date +%Y)"
else
    thisYear="${1}"
fi

find "${imagepath}" -maxdepth 1 -type d | sed -E "s#^${imagepath}/?##" | while read subPath;
do
    case "${subPath}" in
        "Audio")
            genDir "${imagepath}/${subPath}/${thisYear}"
            build_subdirectories "${imagepath}/${subPath}" "${thisYear}" "OsmoPocket"
            ;;
        "Eigene Fotos")
            genDir "${imagepath}/${subPath}/${thisYear}"
            build_subdirectories "${imagepath}/${subPath}" "${thisYear}" "360Camera Android Drohne Kompaktkamera OsmoPocket VR180"
            ;;
        "Fremde Fotos")
            genDir "${imagepath}/${subPath}/${thisYear}"
            ;;
        "Nachbearbeitete Bilder" )
            genDir "${imagepath}/${subPath}/${thisYear}"
            ;;
        "Neu")
            # genDir "${imagepath}/${subPath}/${thisYear}"
            ;;
        "Videos")
            genDir "${imagepath}/${subPath}/${thisYear}"
            build_subdirectories "${imagepath}/${subPath}" "${thisYear}" "360Camera Android Drohne Kompaktkamera OsmoPocket VR180"
            ;;
    esac;
done
}

function clear_directory_tree {
    if [ "${1}" = "" ]
    then
        allYears="$(find ${imagepath} -maxdepth 2 -type d | rev | cut -f 1 -d "/" | rev | grep -E "^[0-9]{4}$" | sort | uniq | grep -v "$(date +%Y)")"
        thisYear=""
    else
        allYears="${1}"
    fi

    for thisYear in ${allYears}
        do
        echo "  - Pruefe Jahr ${thisYear}:"
        find "${imagepath}" -maxdepth 1 -type d | sed -E "s#^${imagepath}/?##" | while read subPath;
        do
            case "${subPath}" in
                "Audio")
                    findEmptyDir "${imagepath}/${subPath}" "${thisYear}"
                    ;;
                "Eigene Fotos")
                    findEmptyDir "${imagepath}/${subPath}" "${thisYear}"
                    ;;
                "Fremde Fotos")
                    ;;
                "Nachbearbeitete Bilder" )
                    ;;
                "Neu")
                    ;;
                "Videos")
                    findEmptyDir "${imagepath}/${subPath}" "${thisYear}"
                    ;;
            esac;
        done
    done
}

function sortFiles {
find "${imagepath}" -maxdepth 1 -type d | sed -E "s#^${imagepath}/?##" | while read subPath;
    do
        case "${subPath}" in
            "Audio")
                ;;
            "Eigene Fotos")
                find "${imagepath}/${subPath}" -type f | grep -iE "(MP4|MPEG|AVI|MOV|WMV|M4V|WEBM|OGG)$" | while read sourcefile
                do
                    targetfile="$(echo "${sourcefile}" | sed "s#^${imagepath}/${subPath}#${imagepath}/Videos#")"
                    moveFile "${sourcefile}" "${targetfile}"
                done
                find "${imagepath}/${subPath}" -type f | grep -iE "(MP3|AAC)$" | while read sourcefile
                do
                    targetfile="$(echo "${sourcefile}" | sed "s#^${imagepath}/${subPath}#${imagepath}/Audio#")"
                    moveFile "${sourcefile}" "${targetfile}"
                done
                ;;
            "Fremde Fotos")
                ;;
            "Nachbearbeitete Bilder")
                ;;
            "Neu")
                ;;
            "Videos")
                find "${imagepath}/${subPath}" -type f | grep -iE "(JPG|JPEG|CR2|DMG)$" | while read sourcefile
                do
                    targetfile="$(echo "${sourcefile}" | sed "s#^${imagepath}/${subPath}#${imagepath}/Eigene Fotos#")"
                    moveFile "${sourcefile}" "${targetfile}"
                done
                ;;
        esac;
    done
}

check_filesystems

if [ "${1}" = "" ]
then
    echo "Fuehre Wartungslauf durch:"
    echo ""
    clear_directory_tree
    build_directory_tree
elif echo "${1}" | grep -qE "^[0-9]{4}$"
then
    echo "Erstelle Verzeichnisstruktur fuer das Jahr ${1}:"
    echo ""
    build_directory_tree ${1}
elif echo "${1}" | tr [A-Z] [a-z] | grep -qE "^(move|movefile)$"
then
    echo "Verschiebe falsch zugeordnete Dateitypen:"
    echo ""
    sortFiles
fi

# Test-Output
