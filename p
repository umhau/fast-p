
p () {
    local DIR open CACHEDLIST PDFLIST
    PDFLIST="/tmp/fewijbbioasBBBB"
    CACHEDLIST="/tmp/fewijbbioasAAAA"
    DIR="${HOME}/.cache/pdftotext"
    mkdir -p "${DIR}"
    if [ "$(uname)" = "Darwin" ]; then
        open=open
    else
        open="gio open"
    fi

    # escale filenames
    # compute xxh sum
    # replace separator by tab character
    # sort to prepare for join
    # remove duplicates
    ag -U -g ".pdf$"| sed 's/\([ \o47()"&;\\]\)/\\\1/g;s/\o15/\\r/g'  \
        | xargs xxh64sum \
        | sed 's/  /\t/' \
        | sort \
        | awk 'BEGIN {FS="\t"; OFS="\t"}; !seen[$1]++ {print $1, $2}' \
        > $PDFLIST

    # printed (hashsum,cached text) for every previously cached output of pdftotext
    # remove full path
    # replace separator by tab character
    # sort to prepare for join
    grep "" ~/.cache/pdftotext/* \
        | sed 's=.*cache/pdftotext/==' \
        | sed 's/:/\t/' \
        | sort \
        > $CACHEDLIST

    {
        echo " "; # starting to type query sends it to fzf right away
        join -t '	' $PDFLIST $CACHEDLIST; # already cached pdfs
        # Next, apply pdftotext to pdfs that haven't been cached yet
        comm -13 \
            <(cat $CACHEDLIST | awk 'BEGIN {FS="\t"; OFS="\t"}; {print $1}') \
            <(cat $PDFLIST | awk 'BEGIN {FS="\t"; OFS="\t"}; {print $1}') \
            | join -t '	' - $PDFLIST \
            | awk 'BEGIN {FS="\t"; OFS="\t"}; !seen[$1]++ {print $1, $2}' \
            | \
            while read -r LINE; do
                local CACHE
                IFS="	"; set -- $LINE;
                CACHE="$DIR/$1"
                pdftotext -f 1 -l 2 "$2" - 2>/dev/null | tr "\n" "__" > $CACHE
                echo -e "$1	$2	$(cat $CACHE)"
            done
} | fzf --reverse -e -d '\t'  \
    --with-nth=2,3 \
    --preview-window down:80% \
    --preview '
v=$(echo {q} | tr " " "|");
echo {2} | grep -E "^|$v" -i --color=always;
echo {3} | tr "__" "\n" | grep -E "^|$v" -i --color=always;
' \
    | awk 'BEGIN {FS="\t"; OFS="\t"}; {print $2}'  \
    | sed 's/\([ \o47()"&;\\]\)/\\\1/g;s/\o15/\\r/g'  \
    | xargs $open > /dev/null 2> /dev/null

}
