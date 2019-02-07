#!/bin/bash

# convert a git log command into CSV format
# run it as follows
# cd MariaDB/server
# ../mariadb.org-tools/reporting/git-log-to-csv.sh 10.4 --after=2018-01-01 --until=2018-12-31
# note: this is a somewhat fragile and situation specific bit of scripting

# git wants the absolute path to the mailmap file
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )" # as per https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself
git config mailmap.file $SCRIPTPATH/mailmap

# Output csv headers
echo "Datetime,Name,Organization,Email,Files Changed,Insertions,Deletions"
git log \
  --use-mailmap \
  --no-merges   \
  --pretty="%cI,%cN,%cE"  \
  --shortstat \
  "$@" \
| sed -E '/^$/d' \
| sed -E -n '/^2[0-9]{3}-/h;n;/^ [0-9]+ file/{H;x;s/\n/,/;p;}' \
| sed -E -e 's/ \(([^)]+)\)/,\1/' \
         -e 's/ ([0-9]+) files? changed,/\1,/' \
         -e 's/ ([0-9]+) insertions?\(\+\)(, ([0-9]+) deletions?\(-\))?/\1,\3/' \
         -e 's/ ([0-9]+) deletions?\(-\)/,\1/'

git config --unset mailmap.file

# Most of this is fairly straightforward
# However, there's one set of sed commands that I probably won't remember unless I document them
#   sed -E -n '/^[0-9]{4}-/h;n;/^ [0-9]+ file/{H;x;s/\n/,/;p;}'
#
# Piece by piece, we have:
# -n              # don't print out lines by default. Instead use an explicit 'p' command to print contents of the pattern buffer
# /^20[0-9]{3}-/h # if the line starts with date fragment (well, up until 2999), put the line in the hold buffer
# n               # skip to the next line
# /^ [0-9]+ file/ # if the line starts with the output from the --shortstat flag, the run the braced commands that follow
# { ... }         # run these commands as a group, in sequence
# H               # add a newline and the current line to the hold buffer
# x               # exchange the contents of the hold buffer and pattern buffer
# s/\n/,/         # replace the newline in the pattern buffer with a comma
# p               # print the pattern buffer
