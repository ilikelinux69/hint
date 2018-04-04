#!/bin/bash
################################################################################
# hint.sh             |   version 1.01    |       GPL v3      |       2017-04-30
#	  Ilikelinux		    |   https://twitter.com/Ilikelinux69
#
#	Replaces cheat.sh   |
#   James Hendrie     |   hendrie.james@gmail.com
#
# This script is a reimplementation of a Python script written by Chris Lane:
#   https://github.com/chrisallenlane
################################################################################

##  Default 'system' directory for hint's
if [[ -d "/usr/local/share/hint" ]]; then
    HINT_SYS_DIR=/usr/local/share/hint
else
    HINT_SYS_DIR=/usr/share/hint
fi

##  Default hint viewer program
if [[ -z $HINT_TEXT_VIEWER ]]; then
    HINT_TEXT_VIEWER="cat"
fi

##  User directory for hint's
if [[ -z $DEFAULT_HINT_DIR ]]; then
    DEFAULT_HINT_DIR="${HOME}/.hint"
fi

##  Hint path
if [[ -z $HINTPATH ]]; then
    HINTPATH="${DEFAULT_HINT_DIR}"
fi

##  Variable to determine if they want to compress, 0 by default
compress=0

##  The hint's tarball file name
CSFILENAME="hints.tar.bz2"

##  Web location(s) of hint's
WEB_PATH_1="https://github.com/ilikelinux69/misc/raw/master"
LOCATION_1="$WEB_PATH_1/$CSFILENAME"


function find_image_viewer
{
    viewers=( 'eog' 'viewnior' 'feh' 'xv' 'display' 'gpicview' 'gthumb' \
        'gwenview' )

    for v in "${viewers[@]}"; do
        if which "$v" > /dev/null; then
            export HINT_IMAGE_VIEWER="$v"
            return 0
        fi
    done


    echo -n "ERROR:  Cannot find an image viewer; use HINT_IMAGE_VIEWER "
    echo "environment variable"
    exit 1
}


function find_pdf_viewer
{
    viewers=( 'evince' 'xpdf' 'qpdfview' 'mupdf' 'okular' )

    for v in "${viewers[@]}"; do
        if which "$v" > /dev/null; then
            export HINT_PDF_VIEWER="$v"
            return 0
        fi
    done

    echo -n "ERROR:  Cannot find a PDF viewer; use HINT_PDF_VIEWER environment"
    echo "variable"
    exit 1
}


function find_editor
{
    editors=( 'nano' 'vim' 'vi' 'emacs' 'ed' 'ex' 'gedit' 'kate' 'geany' )

    for e in "${editors[@]}"; do
        if which "$e" > /dev/null; then
            export EDITOR="$e"
            return 0
        fi
    done

    echo 'ERROR:  Cannot find an editor.  Use EDITOR environment variable.'
    exit 1
}


function print_help
{
    echo "Usage:  hint [OPTION] FILE[s]"
    echo -e "\nOptions:"
    echo -e "  -k:\t\t\tGrep for keyword(s) in filenames"
    echo -e "  -g:\t\t\tGrep for keyword(s) inside the files"
    echo -e "  -G:\t\t\tSame as above, but list full paths to files"
    echo -e "  -l or --link:\t\tLink to a file instead of copying it"
    echo -e "  -L:\t\t\tList all hint's with full paths"
    echo -e "  -e or --edit:\t\tEdit a hint file using EDITOR env variable"
    echo -e "  -a or --add:\t\tAdd file(s)"
    echo -e "  -A:\t\t\tAdd file(s) with gzip compression"
    echo -e "  -h or --help:\t\tThis help screen"
    echo -e "  -u or --update:\tUpdate hint's (safe, lazy method)"
    echo -e "  -U\t\t\tUpdate/overwrite hint's (non-safe)"

    echo -e "\nExamples:"
    echo -e "  hint tar:\t\tDisplay hint sheet for tar"
    echo -e "  hint -a FILE:\t\tAdd FILE to hint sheet directory"
    echo -e "  hint -a *.txt:\tAdd all .txt files in pwd to hint directory"
    echo -e "  hint -k KEYWORD:\tGrep for all filenames containing KEYWORD\n"

    echo "By default, hint's are kept in the ~/.hint directory.  See the"
    echo -e "README file for more details."
}

function print_version
{
    echo "hint.sh, version 1.21, James Hendrie: hendrie.james@gmail.com"
    echo -e "Original version by Chris Lane: chris@chris-allen-lane.com"
}

##  args:
##      $1: The file we're adding
##      $2: Whether to gzip or not (1 is yes)
function add_hint_sheet
{
    ##  Check to make sure it exists
    if [ ! -e "$1" ]; then
        echo "ERROR:  File does not exist:  $1" 1>&2
        exit 1
    fi

    ##  If the file ends in .txt, we're going to rename it
    if [ `ls $1 | tail -c5` = ".txt" ] || [ `ls $1 | tail -c5` = ".TXT" ]; then
        extension=$(ls $1 | tail -c5)
        newName="$(basename "$1")"
        newName="$(echo "$newName" | sed s/$extension//g)"
    else
        newName="$(basename "$1")"
    fi

    ##  Add the file to the directory
    if [ ! $2 -eq 1 ]; then
        cp -v "$1" "$DEFAULT_HINT_DIR/$newName"
    else
        cp -v "$1" "$DEFAULT_HINT_DIR/$newName"
        gzip -v -9 "$DEFAULT_HINT_DIR/$newName"
    fi
}


##  Args:
##      1   Filename
function add_rich_media
{
    if [[ ! -e "$1" ]]; then
        echo "ERROR:  File does not exist:  $1" 1>&2
        exit 1
    fi

    ##  Copy the file
    cp -v "$1" "$DEFAULT_HINT_DIR/$(basename "$1")"
}



##  args:
##      $1: Whether or not to overwrite all files.  0 = update only,
##          1 = overwrite all files with versions in the archive
function update_hint_sheets
{
    if [ ! -d /tmp ] || [ ! -w /tmp ]; then
        echo "ERROR:  Write access to /tmp required to update hint's" 1>&2
        exit 1
    fi

    ##  Create temporary directory and change over to it
    TEMP_DIR=$(mktemp -d)
    CUR_LOC=$PWD
    cd "$TEMP_DIR"
    
    ##  Check for download programs; if found, use them to download file
    which wget &> /dev/null
    if [ $? -ne 0 ]; then
        which curl &> /dev/null
        if [ $? -ne 0 ]; then
            echo "ERROR:  Either wget or curl required to update" 1>&2
            rm -r "$TEMP_DIR"
            exit 1
        else
            curl -sO "$LOCATION_1"
        fi
    else
        wget -q "$LOCATION_1"
    fi

    ##  Check to make sure the file exists
    if [ ! -r $CSFILENAME ]; then
        echo "ERROR:  Could not read from $TEMP_DIR/$CSFILENAME.  Aborting" 1>&2
        rm -r "$TEMP_DIR"
        exit 1
    fi

    ##  Check to make sure the file is a tarball
    if [ ! $(file -bL $CSFILENAME | cut -f1 -d' ') = "bzip2" ]; then
        echo "File $CSFILENAME is not a bzip2 file.  Aborting" 1>&2
        rm -r "$TEMP_DIR"
    fi

    ##  Extract file, then remove it
    tar -xf "$CSFILENAME"
    rm "$CSFILENAME"

    ##  If we're playing it safe, update hint dir.  Otherwise, straight copy
    if [ $1 -eq 0 ]; then
        FILES_COPIED=$(cp -vu ./* "$DEFAULT_HINT_DIR" | wc -l)
    else
        FILES_COPIED=$(cp -v ./* "$DEFAULT_HINT_DIR" | wc -l)
    fi

    ##  Go back to where the user started, remove temp dir and all its contents
    cd "$CUR_LOC"
    rm -r "$TEMP_DIR"

    ##  Echo progress
    echo "$FILES_COPIED files updated"

}


##  Greps for keywords inside of files
##  ARGS
##      1           Whether to list full paths to files.  0 = don't, 1 = do.
function grepper
{
    ##  For every directory in the HINTPATH variable
    for arg in ${@:2}; do
        if [[ $1 -eq 0 ]]; then
            echo -e "$arg:"
        fi

        echo "$HINTPATH" | sed 's/:/\n/g' | while read DIR; do


            ##  Change to directory with hint's
            cd "$DIR"

            ##  Grep through all of the hint's
            ls | while read LINE; do
                grep -i "$arg" "$LINE" &> /dev/null
                if [[ $? -eq 0 ]]; then
                    if [[ $1 -eq 0 ]]; then
                        echo "    $LINE"
                    else
                        echo "$PWD/$LINE"
                    fi
                fi
            done

            ##  Go back to previous directory
            cd - &> /dev/null

        done
    done

}


##  VIEW FILE
##      args:
##          1   The full file name, including path
function view_file
{
    ##  Text files
    if file -bL "$1" | grep text > /dev/null; then
        "$HINT_TEXT_VIEWER" "$1"
    elif file -bL "$1" | grep gzip > /dev/null; then
        gunzip --stdout "$dirName/$fileName" | "$HINT_TEXT_VIEWER" >& 1

    ##  Image files
    elif file -bL "$1" | grep image > /dev/null; then
        if [[ -z $HINT_IMAGE_VIEWER ]]; then
            find_image_viewer
        fi
        (nohup $HINT_IMAGE_VIEWER "$1" &) &> /dev/null

    ##  PDFs
    elif file -bL "$1" | grep PDF > /dev/null; then
        if [[ -z $HINT_PDF_VIEWER ]]; then
            find_pdf_viewer
        fi
        (nohup $HINT_PDF_VIEWER "$1" &) &> /dev/null
    fi

}


##  Too few args, tsk tsk
if [ $# -lt 1 ]; then
    hint -h 1>&2
    exit 1
fi


##  If they want help, give it to 'em
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_help
    exit 0
fi

##  If they're looking for version/author info
if [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
    print_version
    exit 0
fi


##  Check to make sure that their hint directory exists.  If it does, great.
##  If not, exit and tell them.
if [ ! -n "$HINTPATH" ]; then
    if [ ! -d "$HINT_SYS_DIR" ] && [ ! -d "$DEFAULT_HINT_DIR" ]; then
        echo "ERROR:  No hint directory found." 1>&2
        echo -e "\tConsult the help (hint -h) for more info" 1>&2
        exit 1
    else
        cp -r "$HINT_SYS_DIR" "$DEFAULT_HINT_DIR"
        HINTPATH="$DEFAULT_HINT_DIR"
        if [ ! -d "$DEFAULT_HINT_DIR" ]; then
            echo "ERROR:  Cannot write to $DEFAULT_HINT_DIR" 1>&2
            exit 1
        fi
    fi
fi

##  If they want to update their hint's (safe mode)
if [ "$1" = "-u" ] || [ "$1" = "--update" ]; then
    update_hint_sheets 0
    exit 0
fi

##  If they want to update hint's (non-safe mode)
if [ "$1" = "-U" ]; then
    update_hint_sheets 1
    exit 0
fi

##  If they want to add stuff
if [ "$1" = "-a" ] || [ "$1" = "--add" ]; then
    if [ "$#" -lt 2 ]; then
        echo "ERROR:  No files specified" 1>&2
        exit 1
    fi

    for arg in "${@:2}"; do
        if file -bL "$arg" | grep text > /dev/null; then
            add_hint_sheet "$arg" $compress
        else
            add_rich_media "$arg"
        fi
    done

    exit 0
fi

##  If they want to add and compress stuff
if [ "$1" = "-A" ]; then
    if [ "$#" -lt 2 ]; then
        echo "ERROR:  No files specified" 1>&2
        exit 1
    fi

    compress=1
    for arg in "${@:2}"; do
        if file -bL "$arg" | grep text > /dev/null; then
            add_hint_sheet "$arg" $compress
        else
            echo "ERROR:  Cannot add rich media '$arg' with GZIP compression"
        fi
    done

    exit 0
fi


##  If they want to edit a file
if [ "$1" = "-e" ] || [ "$1" = "--edit" ]; then
    if [ "$#" -lt 2 ]; then
        echo "ERROR:  No files specified" 1>&2
        exit 1
    fi

    ##  Find an editor for the user
    if [[ -z $EDITOR ]]; then
        find_editor
    fi

    ##  Assemble the collection of files to edit
    filesToEdit=()
    existing=0
    for arg in ${@:2}; do
        while read F; do

            ##  Check and see if we get any hits on the 'edit' search
            if [[ -e "${F}/${arg}" ]]; then
                if file -b "${F}/${arg}" | grep text > /dev/null; then
                    let existing=$(( $existing + 1 ))
                    filesToEdit+=("${F}/${arg}")
                else
                    echo "WARNING:  Not a text file:  '$arg'"
                fi
            fi
        done < <(echo "$HINTPATH" | sed 's/:/\n/g')

        ##  If we didn't get any hits, create one in default dir
        if [[ $existing -eq 0 ]]; then
            filesToEdit+=("${DEFAULT_HINT_DIR}/${arg}")
        fi

    done

    ##  Edit 'em
    "$EDITOR" ${filesToEdit[@]}


    exit 0
fi


##  If they're searching for keywords
if [[ "$1" = "-k" ]]; then

    ##  If they did not supply a keyword, list everything
    if [[ $# -eq 1 ]]; then
        echo "$HINTPATH" | sed 's/:/\n/g' | while read DIR; do
            ls -1 "$DIR"
        done

        exit 0
    fi

    ##  Grep for every subject they listed as an arg
    for arg in ${@:2}; do
        echo -e "$arg:\n"

        echo "$HINTPATH" | sed 's/:/\n/g' | while read DIR; do
            ls "$DIR" | grep -i "$arg" | while read LINE; do
                echo "  $LINE" | sed 's/.gz//g'
            done

        done

    done

    exit 0
fi


##  If they're grepping for words inside the files
if [[ "$1" = "-g" ]]; then

    ##  If they did not supply a keyword, tell them
    if [[ $# -eq 1 ]]; then
        echo "ERROR:  Keyword(s) required" 1>&2
        exit 1
    fi

    grepper 0 ${@:2}
    
    exit 0
fi

if [[ "$1" = "-G" ]]; then

    ##  If they did not supply a keyword, tell them
    if [[ $# -eq 1 ]]; then
        echo "ERROR:  Keyword(s) required" 1>&2
        exit 1
    fi

    grepper 1 ${@:2}
    
    exit 0
fi


##  If they want to link something
if [[ "$1" = "-l" ]] || [[ "$1" = "--link" ]]; then
    if [[ $# -lt 2 ]]; then
        echo "ERROR:  No files specified" 1>&2
        exit 1
    fi

    for arg in "${@:2}"; do
        if [[ -e "$arg" ]]; then
            ln -sv "$(readlink -f "$arg")" "$DEFAULT_HINT_DIR"
        fi
    done

    exit 0
fi


##  List everything with full paths
if [[ "$1" = "-L" ]]; then
    echo "$HINTPATH" | sed 's/:/\n/g' | while read DIR; do
        ls "$DIR" | while read LINE; do
            echo "${DIR}/${LINE}"
        done
    done

    exit 0
fi


#==============================     MAIN    ====================================

RESULTS=0
declare RESULTS_ARRAY=()

while read DIR; do
    ##  If we hit an 'exact' match
    if [[ -e "$DIR/$1" ]]; then
        echo -e "$1\n"
        "$HINT_TEXT_VIEWER" "$DIR/$1"
        exit 0
    elif [[ -e "$DIR/${1}.gz" ]]; then
        echo -e "$1\n"
        gunzip --stdout "$DIR/${1}.gz" | "$HINT_TEXT_VIEWER" >& 1
        exit 0
    fi

    ##   grab the number of 'hits' given by the user's query
    DIR_RESULTS=$(ls "$DIR" | grep -i "$1" | wc -l)

    if [[ $DIR_RESULTS -gt 0 ]]; then
        while read R; do
            RESULTS_ARRAY+=("${R}:${DIR}")
        done < <(ls "$DIR" | grep -i "$1")
    fi

    let RESULTS=$(( $RESULTS + $DIR_RESULTS ))

done < <(echo "$HINTPATH" | sed 's/:/\n/g')


##  If there are no results, inform the user and let the program quit
if [ $RESULTS -eq 0 ]; then
    echo "ERROR:  No file matching pattern '$1' in $HINTPATH" 1>&2
    exit 1

##  If there is 1 result, display that hint sheet
elif [ $RESULTS -eq 1 ]; then
    for R in ${RESULTS_ARRAY[@]}; do
        fileName="$(echo "$R" | cut -f1 -d':')"
        dirName="$(echo "$R" | cut -f2 -d':')"

        echo -e "$fileName\n"

        view_file "$dirName/$fileName"
    done

##  If there's more than 1, display to the user his/her possibilities
elif [ $RESULTS -gt 1 ]; then
    for arg in ${@:1}; do
        echo "$arg:"
        echo ""

        for R in ${RESULTS_ARRAY[@]}; do
            echo "  $R" | cut -f1 -d':'
        done
    done

##  I felt weird about not having an 'else' here.  Don't judge me.
else
    echo "How the hell do you have fewer than zero results?" 1>&2
    exit 1
fi

#==============================  END MAIN    ===================================

exit 0
