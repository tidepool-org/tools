#!/bin/bash -u

SRC_DIR=`pwd`/src
CD_FILE=`pwd`/Comedeps
TMP=$(mktemp -t come_deps)
if [ ! -f ${CD_FILE} ];
then
    echo "No Comedeps file at ${CD_FILE}"
    exit 2
fi

cat ${CD_FILE} | while read line
do
    echo "Loading ${line}" >> ${TMP} 2>&1

    dep=( ${line} )
    pkg=${dep[0]}
    vcs=${dep[1]}
    url=${dep[2]}
    hash=${dep[3]}
    # you can specify a branch as a fifth parameter if the hash is not
    # on master -- if you don't do this, then people who don't have that
    # branch already checked out will fail to fetch the specified hash
    branch=${dep[4]-master}

    if [ -z ${hash} ]
    then
        echo "Must specify a commit hash/revision number, got[${hash}]"
        exit 3
    fi

    dir=${SRC_DIR}/${pkg}
    if [ ! -d ${dir} ];
    then
        mkdir -p `dirname ${dir}`
        case ${vcs} in
	      git)
            git clone ${url} ${dir} >> ${TMP} 2>&1
            ;;
    	  bzr)
        		bzr branch -q ${url} ${dir} >> ${TMP} 2>&1
        		;;
    		hg)
        		hg clone -r ${hash} ${url} ${dir} >> ${TMP} 2>&1
        		;;
    	  *)
        		echo "Unknown vcs system[${vcs}].  Fix type or update script"
        		exit 4
        		;;
    	  esac
        STATUS=${?}
        if [ ${STATUS} != 0 ]; then
          cat ${TMP}
          exit ${STATUS}
        fi
    fi

    cd ${dir}

    case ${vcs} in
  	git)
        git fetch --prune --tags >> ${TMP} 2>&1
        STATUS=${?}
        if [ ${STATUS} != 0 ]; then
          cat ${TMP}
          exit ${STATUS}
        fi
        git checkout --quiet ${branch} >> ${TMP} 2>&1
        STATUS=${?}
        if [ ${STATUS} != 0 ]; then
          cat ${TMP}
          exit ${STATUS}
        fi
        git pull --quiet origin ${branch} >> ${TMP} 2>&1
        STATUS=${?}
        if [ ${STATUS} != 0 ]; then
          cat ${TMP}
          exit ${STATUS}
        fi
        git checkout --quiet ${hash} >> ${TMP} 2>&1
        STATUS=${?}
        if [ ${STATUS} != 0 ]; then
          cat ${TMP}
          exit ${STATUS}
        fi
  	    ;;
  	bzr)
        bzr up -r ${hash} >> ${TMP} 2>&1
        STATUS=${?}
        if [ ${STATUS} != 0 ]; then
          cat ${TMP}
          exit ${STATUS}
        fi
  	    ;;
  	hg)
  	    ;;
  	*)
  	    echo "Unknown vcs system[${vcs}].  Fix type or update script"
  	    exit 4
  	    ;;
    esac
done
