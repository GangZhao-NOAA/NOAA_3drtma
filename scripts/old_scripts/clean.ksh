#!/bin/ksh 

ulimit -s 512000

np=`cat $PBS_NODEFILE | wc -l`

source /home/rtrr/PARM_EXEC/modulefiles/modulefile.jet.GSI_UPP_WRF

# Make sure WORK_ROOT is defined and exists
if [ ! "${WORK_ROOT}" ]; then
  ${ECHO} "ERROR: WORK_ROOT is not defined!"
  exit 1
fi
if [ ! -d "${WORK_ROOT}" ]; then
  ${ECHO} "ERROR: WORK_ROOT directory '${WORK_ROOT}' does not exist!"
  exit 1
fi
if [ ! "${CYCLE_HOUR}" ]; then
  ${ECHO} "ERROR: CYCLE_HOUR is not defined!"
  exit 1
fi

currentime=`date`
cyclehour=${CYCLE_HOUR}
savelogtime=`date +%Y%m%d -d "${currentime}  2 days ago"`
mainroot=${WORK_ROOT}

# Delete run directories
deletetime=`date +%Y%m%d%H -d "${currentime}  42 hours ago"`
set -A workdir "${mainroot}/run"
echo "Delete directory before ${deletetime}"
for currentdir in ${workdir[*]}; do
  cd ${currentdir}
  echo "Working on directory ${currentdir}"
  set -A XX `ls -d 20* | sort -r`
  maxnum=${#XX[*]}
  for onetime in ${XX[*]};do
    if [[ ${onetime} -le ${deletetime} ]]; then
      echo "Delete data in ${onetime}"
      rm -rf ${onetime}
    fi
  done
done

# Save recent logs into directory
echo "Cycle hour = ${cyclehour}"
saveloghour='03'
if [ ${cyclehour} -eq ${saveloghour} ]; then
  echo "Save log file"
  cd ${mainroot}/log
  mkdir ${savelogtime}
  mv *${savelogtime}*.log ./${savelogtime}
  mv *${savelogtime}*.log.* ./${savelogtime}
  mv *${savelogtime}*.txt ./${savelogtime}
fi

# Delete log file directories
deletetime=`date +%Y%m%d -d "${currentime}  720 hours ago"`
set -A workdir "${mainroot}/log"
cd ${workdir}
set -A XX `ls -d 20*`
for dir in ${XX[*]}; do
  if [[ ${dir} -le ${deletetime} ]]; then
    echo "Delete log directory : ${dir}"
    rm -rf ${dir}
  fi
done


exit 0
