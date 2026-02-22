#!/usr/bin/env bash

set -o noclobber -o noglob -o nounset -o pipefail
IFS=$'\n'

## Script arguments
FILE_PATH="${1}"         # Full path of the highlighted file
PV_WIDTH="${2}"          # Width of the preview pane (number of fitting characters)
PV_HEIGHT="${3}"         # Height of the preview pane (number of fitting characters)
IMAGE_CACHE_PATH="${4}"  # Full path that should be used to cache image preview
PV_IMAGE_ENABLED="${5}"  # 'True' if image previews are enabled, 'False' otherwise.

FILE_EXTENSION="${FILE_PATH##*.}"
FILE_EXTENSION_LOWER="$(printf "%s" "${FILE_EXTENSION}" | tr '[:upper:]' '[:lower:]')"

## Settings
HIGHLIGHT_SIZE_MAX=262143  # 256KiB
HIGHLIGHT_TABWIDTH="${HIGHLIGHT_TABWIDTH:-8}"
HIGHLIGHT_STYLE="${HIGHLIGHT_STYLE:-pablo}"
HIGHLIGHT_OPTIONS="--replace-tabs=${HIGHLIGHT_TABWIDTH} --style=${HIGHLIGHT_STYLE} ${HIGHLIGHT_OPTIONS:-}"
BAT_STYLE="${BAT_STYLE:-plain}"

# Portable file size function (works on both macOS and Linux)
file_size() {
    if stat --version >/dev/null 2>&1; then
        stat --printf='%s' -- "$1"
    else
        stat -f '%z' -- "$1"
    fi
}

handle_extension() {
    case "${FILE_EXTENSION_LOWER}" in
        ## Archive
        a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|\
        rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)
            atool --list -- "${FILE_PATH}" && exit 5
            bsdtar --list --file "${FILE_PATH}" && exit 5
            exit 1;;
        rar)
            unrar lt -p- -- "${FILE_PATH}" && exit 5
            exit 1;;
        7z)
            7z l -p -- "${FILE_PATH}" && exit 5
            exit 1;;

        ## PDF
        pdf)
            pdftotext -l 10 -nopgbrk -q -- "${FILE_PATH}" - | \
              fmt -w "${PV_WIDTH}" && exit 5
            mutool draw -F txt -i -- "${FILE_PATH}" 1-10 | \
              fmt -w "${PV_WIDTH}" && exit 5
            exiftool "${FILE_PATH}" && exit 5
            exit 1;;

        ## OpenDocument
        odt|sxw)
            odt2txt "${FILE_PATH}" && exit 5
            pandoc -s -t markdown -- "${FILE_PATH}" && exit 5
            exit 1;;
        ods|odp)
            odt2txt "${FILE_PATH}" && exit 5
            exit 1;;

        ## XLSX
        xlsx)
            xlsx2csv -- "${FILE_PATH}" && exit 5
            exit 1;;

        ## HTML
        htm|html|xhtml)
            w3m -dump "${FILE_PATH}" && exit 5
            lynx -dump -- "${FILE_PATH}" && exit 5
            pandoc -s -t markdown -- "${FILE_PATH}" && exit 5
            ;;

        ## JSON
        json)
            jq --color-output . "${FILE_PATH}" && exit 5
            python -m json.tool -- "${FILE_PATH}" && exit 5
            ;;

        ## Jupyter Notebooks
        ipynb)
            jupyter nbconvert --to markdown "${FILE_PATH}" --stdout | env COLORTERM=8bit bat --color=always --style=plain --language=markdown && exit 5
            jupyter nbconvert --to markdown "${FILE_PATH}" --stdout && exit 5
            jq --color-output . "${FILE_PATH}" && exit 5
            ;;

        ## Audio metadata
        dff|dsf|wv|wvc)
            mediainfo "${FILE_PATH}" && exit 5
            exiftool "${FILE_PATH}" && exit 5
            ;;
    esac
}

handle_image() {
    local DEFAULT_SIZE="1920x1080"

    local mimetype="${1}"
    case "${mimetype}" in
        ## SVG
        image/svg+xml|image/svg)
            rsvg-convert --keep-aspect-ratio --width "${DEFAULT_SIZE%x*}" "${FILE_PATH}" -o "${IMAGE_CACHE_PATH}.png" \
                && mv "${IMAGE_CACHE_PATH}.png" "${IMAGE_CACHE_PATH}" \
                && exit 6
            exit 1;;

        ## DjVu
        image/vnd.djvu)
            ddjvu -format=tiff -quality=90 -page=1 -size="${DEFAULT_SIZE}" \
                  - "${IMAGE_CACHE_PATH}" < "${FILE_PATH}" \
                  && exit 6 || exit 1;;

        ## Image
        image/*)
            local orientation
            orientation="$( identify -format '%[EXIF:Orientation]\n' -- "${FILE_PATH}" )"
            if [[ -n "$orientation" && "$orientation" != 1 ]]; then
                convert -- "${FILE_PATH}" -auto-orient "${IMAGE_CACHE_PATH}" && exit 6
            fi
            exit 7;;

        ## Font
        application/font*|application/*opentype)
            preview_png="/tmp/$(basename "${IMAGE_CACHE_PATH%.*}").png"
            if fontimage -o "${preview_png}" \
                         --pixelsize "120" \
                         --fontname \
                         --pixelsize "80" \
                         --text "  ABCDEFGHIJKLMNOPQRSTUVWXYZ  " \
                         --text "  abcdefghijklmnopqrstuvwxyz  " \
                         --text "  0123456789.:,;(*!?') ff fl fi ffi ffl  " \
                         --text "  The quick brown fox jumps over the lazy dog.  " \
                         "${FILE_PATH}";
            then
                convert -- "${preview_png}" "${IMAGE_CACHE_PATH}" \
                    && rm "${preview_png}" \
                    && exit 6
            else
                exit 1
            fi
            ;;
    esac
}

handle_mime() {
    local mimetype="${1}"
    case "${mimetype}" in
        ## RTF and DOC
        text/rtf|*msword)
            catdoc -- "${FILE_PATH}" && exit 5
            exit 1;;

        ## DOCX, ePub, FB2 (using markdown)
        *wordprocessingml.document|*/epub+zip|*/x-fictionbook+xml)
            pandoc -s -t markdown -- "${FILE_PATH}" && exit 5
            exit 1;;

        ## Text
        text/* | */xml)
            if [[ "$( file_size "${FILE_PATH}" )" -gt "${HIGHLIGHT_SIZE_MAX}" ]]; then
                exit 2
            fi
            if [[ "$( tput colors )" -ge 256 ]]; then
                local highlight_format='xterm256'
            else
                local highlight_format='ansi'
            fi
            env HIGHLIGHT_OPTIONS="${HIGHLIGHT_OPTIONS}" highlight \
                --out-format="${highlight_format}" \
                --force -- "${FILE_PATH}" && exit 5
            env COLORTERM=8bit bat --color=always --style="${BAT_STYLE}" \
                -- "${FILE_PATH}" && exit 5
            exit 2;;

        ## DjVu
        image/vnd.djvu)
            djvutxt "${FILE_PATH}" | fmt -w "${PV_WIDTH}" && exit 5
            exiftool "${FILE_PATH}" && exit 5
            exit 1;;

        ## Image
        image/*)
            exiftool "${FILE_PATH}" && exit 5
            exit 1;;

        ## Video and audio
        video/* | audio/*)
            mediainfo "${FILE_PATH}" && exit 5
            exiftool "${FILE_PATH}" && exit 5
            exit 1;;
    esac
}

handle_fallback() {
    echo '----- File Type Classification -----' && file --dereference --brief -- "${FILE_PATH}" && exit 5
}


MIMETYPE="$( file --dereference --brief --mime-type -- "${FILE_PATH}" )"
if [[ "${PV_IMAGE_ENABLED}" == 'True' ]]; then
    handle_image "${MIMETYPE}"
fi
handle_extension
handle_mime "${MIMETYPE}"
handle_fallback

exit 1
