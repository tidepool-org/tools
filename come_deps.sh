#! /bin/bash -eu

SRC_DIR=`pwd`/src
CD_FILE=`pwd`/Comedeps
if [ ! -f ${CD_FILE} ];
then
    echo "No Comedeps file at ${CD_FILE}"
    exit 2
fi

cat ${CD_FILE} | while read line
do
    echo "Loading ${line}"

    dep=( ${line} )
    pkg=${dep[0]}
    vcs=${dep[1]}
    url=${dep[2]}
    hash=${dep[3]}

    if [ -z ${hash} ]
    then
	echo "Must specify a commit hash/revision number, got[${hash}]"
	exit 3
    fi

    dir=${SRC_DIR}/${pkg}
    if [ -d ${dir} ];
    then
	echo "Package[${pkg}] already exists in dir[${dir}]"
    else
	mkdir -p `dirname ${dir}`
	case ${vcs} in
	    git)
		echo "Cloning git repository[${url}] to dir[${dir}]"
		git clone ${url} ${dir}
		;;
	    bzr)
		echo "Cloning bazaar repository[${url}] to dir[${dir}]"
		bzr branch ${url} ${dir}
		;;
	    *)
		echo "Unknown vcs system[${vcs}].  Fix type or update script"
		exit 4
		;;
	esac
    fi

    echo "Checking out revision ${hash}"
    case ${vcs} in
	git)
	    cd ${dir}; git checkout -q ${hash}
	    ;;
	bzr)
	    cd ${dir}; bzr up -r ${hash}
	    ;;
	*)
	    echo "Unknown vcs system[${vcs}].  Fix type or update script"
	    exit 4
	    ;;
    esac
done
