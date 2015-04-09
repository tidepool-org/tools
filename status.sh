#! /bin/bash
# checks status in all the git repositories below this one
# only prints status for those that aren't on master with no changes since the last tag

alltags() {
    git tag | egrep "v[0-9]+\.[0-9]+\.[0-9]+(-.+)?" |tr '.-' ' *' |sort --numeric-sort --key 1.1 --key 2 --key 3 |tr ' *' '.-'
}

lasttag() {
    alltags |tail -1
}

gitlog1() {
    git log --max-count 1 --pretty=oneline --abbrev-commit --no-merges $1
}

if [ -f runservers ]; then
  cd ..
fi

if [ ! -d tools ]; then
  echo "You should be in the tools directory or its immediate parent directory to run this."
  exit 1
fi

BAD='\x1b[22;31m'       # red
GOOD='\x1b[22;32m'      # green
NOCOL='\x1b[0m'
PRINTALL="false"
REPOLIST=$(find . -name ".git" -depth 2 |sed s/\.git// |sed s@\./@@ |sed s@/@@)

while [ -n "$1" ]; do
    if [ /$1/ == /--nocolor/ ]; then
        BAD=''
        GOOD=''
        NOCOL=''
    fi

    if [ "$1" == "--all" ]; then
        PRINTALL="true"
    fi

    if [ "$1" == "--required" ]; then
        REPOLIST=$(cat "tools/required_repos.txt")
    fi

    if [ "$1" == "-h" ]; then
        echo "status [args]"
        echo "-h prints this help"
        echo "--nocolor suppresses colorizing of results"
        echo "--required examines only the repositories in required_repos.txt"
        echo "--all prints all items -- otherwise, only exceptions are printed"
        echo "   exceptions are not on master, not clean, or last tag not at head"
        exit
    fi
    shift
done

# colorize(text, good)
colorize() {
    if [ "$1" == "$2" ]; then
        echo $GOOD$1$NOCOL
    else
        echo $BAD$1$NOCOL
    fi
}

for i in $REPOLIST; do
    cd $i
    BRANCH=$(git branch |grep '*' |cut -c 3-99)
    STATUS=$(git status --porcelain |cut -c 1-2 |uniq |tr '\n' ' '|sed -e s/M/modified/ -e s/??/untracked/ -e s/UU/--uncompleted-merge--/ -e s/A/added/ -e s/D/deleted/ -e s/R/renamed/ -e s/C/copied/ -e s/U/updated/ |tr -d '\n')
    LASTTAG=$(lasttag)
    TAGLOG=$(gitlog1 $LASTTAG)
    CURLOG=$(gitlog1)
    UPTODATE=""
    if [ "$TAGLOG" != "$CURLOG" ]; then
        UPTODATE=$(colorize "Last tag not at head." "")
    fi
    if [ -n "$STATUS" -o "$BRANCH" != "master" -o $PRINTALL == "true" -o "$UPTODATE" != "" ]; then
        echo -e "$i: [ $(colorize $BRANCH "master") ] $LASTTAG $STATUS $UPTODATE"
    fi
    cd ..
done

