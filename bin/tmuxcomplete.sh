#!/bin/sh

# Usage: Get a list of all words visible in current window
#     sh tmuxcomplete
#
# Words visible in current window, excluding current pane
#     sh tmuxcomplete -e
#
# Words visible in specified pane in current window
# (can't be used alongside the -e option)
#     sh tmuxcomplete -t <pane_idex>
#
# Words visible in current session
#     sh tmuxcomplete -l '-s'
#
# Words visible in all sessions
#     sh tmuxcomplete -l '-a'
#
# Words containing 'foo'
#     sh tmuxcomplete -p 'foo'
#
# List of lines
#     sh tmuxcomplete -s lines
#
# Words containing 'foo', ignoring case
#     sh tmuxcomplete -p 'foo' -g '-i'
#
# Words beginning with 'foo'
#     sh tmuxcomplete -p '^foo'
#
# Words including 2000 lines of history per pane
#     sh tmuxcomplete -c '-S -2000'

if ! tmux info > /dev/null 2>&1; then
    echo "[tmux-complete.vim]"
    echo "No tmux found!"
    exit 0
fi

EXCLUDE='0'
NOSORT='0'
TARGET='-1'
PATTERN=''
SPLITMODE=words
LISTARGS=''
CAPTUREARGS=''
GREPARGS=''
while getopts enp:s:t:l:c:g: name
do case $name in
    e) EXCLUDE="1";;
    n) NOSORT="1";; # internal/undocumented, don't use, might be changed in the future
    t) TARGET="$OPTARG";;
    p) PATTERN="$OPTARG";;
    s) SPLITMODE="$OPTARG";;
    l) LISTARGS="$OPTARG";;
    c) CAPTUREARGS="$OPTARG";;
    g) GREPARGS="$OPTARG";;
    *) echo "Usage: $0 [-t <pane_index>] [-p pattern] [-s splitmode] [-l listargs] [-c captureargs] [-g grepargs]\n"
        exit 2;;
esac
done

listpanes() {
    tmux list-panes $LISTARGS -F '#{pane_active}#{window_active}-#{session_id} #{pane_id}'
}

excludecurrent() {
    if [ "$EXCLUDE" = "1" ]; then
        currentpane=$(tmux display-message -p '11-#{session_id} ')
        # echo 1>&2 'current' "$currentpane"
        # use -F to match $ in session id
        grep -v -F "$currentpane"
    elif ! [ "$TARGET" = "-1" ]; then
        echo $(tmux display-message -p '01-#{session_id} ')$TARGET
    else
        cat
    fi
}

paneids() {
    cut -d' ' -f2
}

capturepanes() {
    panes=$(cat)
    if [ -z "$panes" ]; then
        # echo 'no panes' 1>&2
        return
    elif tmux capture-pane -p >/dev/null 2>&1; then
        # tmux capture-pane understands -p -> use it
        echo "$panes" | xargs -n1 tmux capture-pane $CAPTUREARGS -p -t
    else
        # tmux capture-pane doesn't understand -p (like version 1.6)
        # -> capture to paste-buffer, echo it, then delete it
        echo "$panes" | xargs -n1 -I{} sh -c "tmux capture-pane $CAPTUREARGS -t {} && tmux show-buffer && tmux delete-buffer"
    fi
}

split() {
    if [ "$SPLITMODE" = "ilines,words" ]; then
        # this is most reabable, but not posix compliant
        # tee >(splitilines) >(splitwords)

        # from https://unix.stackexchange.com/a/43536
        # this has some issues with trailing whitespace sometimes
        # tmp_dir=$(mktemp -d)
        # mkfifo "$tmp_dir/f1" "$tmp_dir/f2"
        # splitilines <"$tmp_dir/f1" & pid1=$!
        # splitwords  <"$tmp_dir/f2" & pid2=$!
        # tee "$tmp_dir/f1" "$tmp_dir/f2"
        # rm -rf "$tmp_dir"
        # wait $pid1 $pid2

        splitilinesandwords
    elif [ "$SPLITMODE" = "lines" ]; then
        splitlines
    elif [ "$SPLITMODE" = "ilines" ]; then
        splitilines
    elif [ "$SPLITMODE" = "words" ]; then
        splitwords
    fi
}

splitilinesandwords() {
    # print full line to duplicate it
    # on the duplicate substitute all spaces with newlines
    # duplicate that result again
    # in that duplicate replace all non word characters by linebreaks 
    sed -e 'p;s/[[:space:]]\{1,\}/\
        /g;p;s/[^a-zA-Z0-9_]\{1,\}/\
        /g' |
    # remove surrounding non-word characters
    grep -o "\\w.*\\w"
}

splitlines() {
    # remove surrounding whitespace
    grep -o "\\S.*\\S"
}

splitilines() {
    # starts at first word character
    grep -o "\\w.*\\S"
}

# returns both WORDS and words of each given line
splitwords() {
    # use sed like this instead of tr?
    # substitute all spaces with newlines
    # duplicate that line
    # in the duplicate replace all non word characters by linebreaks 
    # sed -e 's/[[:space:]]\{1,\}/\
    #     /g;p;s/[^a-zA-Z0-9_]/ /g;s/[[:space:]]\{1,\}/\
    #     /g' |

    # copy lines and split words
    sed -e 'p;s/[^a-zA-Z0-9_]/ /g' |
    # split on spaces
    tr -s '[:space:]' '\n' |
    # remove surrounding non-word characters
    grep -o "\\w.*\\w"
}

sortu() {
    if [ "$NOSORT" = "1" ]; then
        cat
    else
        sort -u
    fi
}

# list all panes
listpanes |
# filter out current pane
excludecurrent |
# take the pane id
paneids |
# capture panes
capturepanes |
# split words or lines depending on splitmode
split |
# filter out items not matching pattern
grep -e "$PATTERN" $GREPARGS |
# sort and remove duplicates
sortu
