#! /bin/sh
# checks status in all the git repositories below this one

if [ -f runservers ]; then
  cd ..
fi

if [ ! -d tools ]; then
  echo "You should be in the tools directory or its immediate parent directory to run this."
  exit 1
fi

for i in $(find . -name ".git" -depth 2 |sed s/\.git// |sed s@\./@@ |sed s@/@@); do
    cd $i
    echo -n "$i: [" `git branch |grep '*' |cut -c 3-99` "] "
    git status --porcelain |cut -c 1-2 |uniq |tr '\n' ' '|sed -e s/M/modified/ -e s/??/untracked/ -e s/A/added/ -e s/D/deleted/ -e s/R/renamed/ -e s/C/copied/ -e s/U/updated/ |tr -d '\n'
    echo
    cd ..
done

