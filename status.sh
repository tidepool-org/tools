#! /bin/bash
# checks status in all the git repositories below this one

if [ -f runservers ]; then
  cd ..
fi

if [ ! -d tools ]; then
  echo "You should be in the tools directory or its immediate parent directory to run this."
  exit 1
fi

if [ -n "$1" ]; then
    if [ ! $1 == "-x" ]; then
        echo "status [args]"
        echo "-h prints this help"
        echo "-x prints exceptions -- not on master or not clean"
        exit
    fi
fi

if [ $1=="-x" ]; then
    EXCEPTIONS="true"
fi

for i in $(find . -name ".git" -depth 2 |sed s/\.git// |sed s@\./@@ |sed s@/@@); do
    cd $i
    BRANCH=$(git branch |grep '*' |cut -c 3-99)
    STATUS=$(git status --porcelain |cut -c 1-2 |uniq |tr '\n' ' '|sed -e s/M/modified/ -e s/??/untracked/ -e s/UU/--uncompleted-merge--/ -e s/A/added/ -e s/D/deleted/ -e s/R/renamed/ -e s/C/copied/ -e s/U/updated/ |tr -d '\n')
    if [ -n "$STATUS" -o "$BRANCH" != "master" -o $EXCEPTIONS != "true" ]; then
        echo "$i: [ $BRANCH ] $STATUS"
    fi
    cd ..
done

