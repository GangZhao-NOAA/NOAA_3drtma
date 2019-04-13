#!/bin/ksh --login
##########################################################################
#
#Script Name: ncl.ksh
# 
#     Author: Christopher Harrop
#             Forecast Systems Laboratory
#             325 Broadway R/FST
#             Boulder, CO. 80305
#
#   Released: 10/30/2003
#    Version: 1.0
#    Changes: None
#
# Purpose: This script generates NCL graphics from wrf output.  
#
#               EXE_ROOT = The full path of the ncl executables
#          DATAHOME = Top level directory of wrf output and
#                          configuration data.
#             START_TIME = The cycle time to use for the initial time. 
#                          If not set, the system clock is used.
#              FCST_TIME = The two-digit forecast that is to be ncled
# 
# A short and simple "control" script could be written to call this script
# or to submit this  script to a batch queueing  system.  Such a "control" 
# script  could  also  be  used to  set the above environment variables as 
# appropriate  for  a  particular experiment.  Batch  queueing options can
# be  specified on the command  line or  as directives at  the top of this
# script.  A set of default batch queueing directives is provided.
#
##########################################################################

if [ "${PBS_NODEFILE:-unset}" != "unset" ]; then
        THREADS=$(cat $PBS_NODEFILE | wc -l)
else
        THREADS=1
fi
echo "Using $THREADS thread(s) for procesing."

# Load modules
module load intel
module load mvapich2
module load netcdf
module load ncl/${NCL_VER}
module load imagemagick/6.2.8

# Make sure we are using GMT time zone for time computations
# export NCL_VER=6.1.2  # for testing
# export DATAROOT="/home/rtrr/hrrr"  # for testing
# export FCST_TIME=3  # for testing
# export START_TIME=2014111812  # for testing
export TZ="GMT"
export NCARG_ROOT="/apps/ncl/${NCL_VER}"
export NCARG_LIB="/apps/ncl/${NCL_VER}/lib"
export NCL_HOME="/whome/Brian.D.Jamison/fim/svncode/ncl/fimall"
export UDUNITS2_XML_PATH=$NCARG_ROOT/lib/ncarg/udunits/udunits2.xml

# Set up paths to shell commands
LS=/bin/ls
LN=/bin/ln
RM=/bin/rm
MKDIR=/bin/mkdir
CP=/bin/cp
MV=/bin/mv
ECHO=/bin/echo
CAT=/bin/cat
GREP=/bin/grep
CUT=/bin/cut
AWK="/bin/gawk --posix"
SED=/bin/sed
DATE=/bin/date
BC=/usr/bin/bc
XARGS=${XARGS:-/usr/bin/xargs}
BASH=${BASH:-/bin/bash}
NCL=${NCARG_ROOT}/bin/ncl
CTRANS=${NCARG_ROOT}/bin/ctrans
PS2PDF=/usr/bin/ps2pdf
CONVERT=`which convert`
MONTAGE=`which montage`
PATH=${NCARG_ROOT}/bin:${PATH}

ulimit -s 512000

typeset -RZ2 FCST_TIME
typeset -RZ2 FCST_TIME_BACK3

EXE_ROOT=/misc/whome/wrfruc/bin/ncl/nclhrrr

# Print run parameters
${ECHO}
${ECHO} "ncl.ksh started at `${DATE}`"
${ECHO}
${ECHO} "DATAHOME = ${DATAHOME}"
${ECHO} "     EXE_ROOT = ${EXE_ROOT}"

# Check to make sure the EXE_ROOT var was specified
if [ ! -d ${EXE_ROOT} ]; then
  ${ECHO} "ERROR: EXE_ROOT, '${EXE_ROOT}', does not exist"
  exit 1
fi

# Check to make sure that the DATAHOME exists
if [ ! -d ${DATAHOME} ]; then
  ${ECHO} "ERROR: DATAHOME, '${DATAHOME}', does not exist"
  exit 1
fi

# If START_TIME is not defined, use the current time
if [ ! "${START_TIME}" ]; then
  DATESTAMP=$( expr $( date +"%s"))
  START_TIME=$( date -d@${DATESTAMP} +"%Y%m%d%H" )
fi

FCST_TIME_BACK3=-9
if (( ${FCST_TIME} >= 3 )); then
  FCST_TIME_BACK3=$(($FCST_TIME - 3))
fi

# Print out times
# ${ECHO} "   START TIME = "`${DATE} +%Y%m%d%H -d "${START_TIME}"`
${ECHO} "   START_TIME = ${START_TIME}"
${ECHO} "    FCST_TIME = ${FCST_TIME}"
if (( ${FCST_TIME} <= 3 )); then
  ${ECHO} "   FCST_TIME_BACK3 = ${FCST_TIME_BACK3}"
fi


# Set up the work directory and cd into it
# workdir=nclprd/${FCST_TIME}part2   # for testing
workdir=${DATAHOME}/nclprd/${FCST_TIME}part2
${RM} -rf ${workdir}
${MKDIR} -p ${workdir}
cd ${workdir}

# Link to input file
# DATAHOME=${DATAROOT}/${START_TIME}  # for testing
${LN} -s ${DATAHOME}/postprd/wrfprs_hrconus_${FCST_TIME}.grib2 hrrrfile.grb
${ECHO} "hrrrfile.grb" > arw_file.txt
if (( ${FCST_TIME_BACK3} != -9 )); then
  ${LN} -s ${DATAHOME}/postprd/wrfprs_hrconus_${FCST_TIME_BACK3}.grib2 back3file.grb
  ${ECHO} "back3file.grb" > back3_file.txt
  ls -al back3file.grb
fi

ls -al hrrrfile.grb
ls -al back3file.grb

set -A ncgms  sfc_hlcy  \
              mx16_hlcy \
              in25_hlcy \
              in16_hlcy \
              sfc_ca1   \
              sfc_ca2   \
              sfc_ca3   \
              sfc_ci1   \
              sfc_ci2   \
              sfc_ci3   \
              sfc_ltg1  \
              sfc_ltg2  \
              sfc_ltg3  \
              sfc_pchg  \
              sfc_lcl   \
              sfc_tcc   \
              sfc_lcc   \
              sfc_mcc   \
              sfc_hcc   \
              sfc_mnvv  \
              sfc_mref  \
              sfc_mucp  \
              sfc_mulcp \
              sfc_mxcp  \
              sfc_1hsm  \
              sfc_3hsm  \
              sfc_vig   \
              sfc_s1shr \
              sfc_6kshr \
              500_temp  \
              700_temp  \
              850_temp  \
              925_temp  \
              sfc_1ref  \
              sfc_bli   \
              nta_ulwrf \
              sfc_lhtfl \
              sfc_shtfl \
              sfc_flru  \
              80m_wpwr  \
              sfc_solar \
              sfc_ectp  \
              sfc_vil   \
              sfc_rvil  \
              sat_G113bt \
              sat_G114bt \
              sat_G123bt \
              sat_G124bt \
              sfc_cpofp

set -A webpfx hlcy hlcy hlcy hlcy ca1 ca2 ca3 ci1 ci2 ci3 ltg1 ltg2 ltg3 pchg lcl tcc lcc mcc hcc \
              mnvv mref mucp mulcp mxcp 1hsm 3hsm vig s1shr 6kshr temp temp temp temp \
              1ref bli ulwrf lhtfl shtfl flru wpwr solar ectp vil rvil G113bt G114bt G123bt G124bt \
              cpofp

set -A fhr 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15

set -A websfx sfc mx16 in25 in16 sfc sfc sfc sfc sfc sfc sfc sfc sfc sfc sfc sfc sfc sfc sfc sfc \
              sfc sfc sfc sfc sfc sfc sfc sfc sfc 500 700 850 925 sfc sfc nta sfc sfc sfc 80m \
              sfc sfc sfc sfc sat sat sat sat sfc

set -A tiles dum t1 t2 t3 t4 t5 t6 t7 t8 z0 z1 z2 z3 z4

set -A webmon montage

i=0
p=0
while [ ${i} -lt ${#ncgms[@]} ]; do
  j=0 
  numtiles=${#tiles[@]}
  (( numtiles=numtiles - 1 ))
  while [ ${j} -le ${numtiles} ]; do
    pngs[${p}]=${ncgms[${i}]}-${j}.png
    # echo ${pngs[${p}]}
    if [ ${j} -eq 0 ]; then
      webnames[${p}]=${webpfx[${i}]}_${websfx[${i}]}
    else
      webnames[${p}]=${webpfx[${i}]}_${tiles[${j}]}${websfx[${i}]}
    fi  
    # echo ${webnames[${p}]}
    (( j=j + 1 ))
# p is total number of images (image index)
    (( p=p + 1 ))
  done
  (( i=i + 1 ))
done

ncl_error=0

CMDFN=/tmp/cmdfn.hrrr_part2.$$
${RM} -f $CMDFN

# Run the NCL scripts for each plot
cp /whome/wrfruc/bin/ncl/Airpor* .
cp ${EXE_ROOT}/names_grib2.txt .
i=0
while [ ${i} -lt ${#ncgms[@]} ]; do

  plot=${ncgms[${i}]}
#  ${ECHO} "Starting rr_${plot}.ncl at `${DATE}`"
#  ${NCL} < ${EXE_ROOT}/rr_${plot}.ncl
#  error=$?
#  if [ ${error} -ne 0 ]; then
#    ${ECHO} "ERROR: rr_${plot} crashed!  Exit status=${error}"
#    ncl_error=${error}
#  fi
#  ${ECHO} "Finished rr_${plot}.ncl at `${DATE}`"

  echo ${NCL} ${EXE_ROOT}/rr_${plot}.ncl >> $CMDFN

  (( i=i + 1 ))

done

${CAT} $CMDFN | ${XARGS} -P $THREADS -I {} ${BASH} -c "{}" 
ncl_error=$?
${RM} -f $CMDFN

# Run ctrans on all the .ncgm files to translate them into Sun Raster files
# NOTE: ctrans ONLY works for 32-bit versions of NCL
i=0
while [ ${i} -lt ${#ncgms[@]} ]; do

  plot=${ncgms[${i}]}

#  ${ECHO} "Starting ctrans for ${plot}.ncgm at `${DATE}`"
## normal image
##  ${CTRANS} -d sun ${plot}.ncgm -resolution 1510x1208 > ${plot}.ras
#  ${CTRANS} -d sun ${plot}.ncgm -resolution 1132x906 > ${plot}.ras
#
#  error=$?
#  if [ ${error} -ne 0 ]; then
#    ${ECHO} "ERROR: ctrans ${plot}.ncgm crashed!  Exit status=${error}"
#    ncl_error=${error}
#  fi
#  ${ECHO} "Finished ctrans for ${plot}.ncgm at `${DATE}`"

  echo "${CTRANS} -d sun ${plot}.ncgm -resolution 1132x906 > ${plot}.ras" >> $CMDFN

  (( i=i + 1 )) 
 
done

${CAT} $CMDFN | ${XARGS} -P $THREADS -I {} ${BASH} -c "{}" 
ncl_error=$?
${RM} -f $CMDFN

# Convert the .ras files into .png files
i=0
while [ ${i} -lt ${#ncgms[@]} ]; do

  plot=${ncgms[${i}]}
  ${ECHO} "Starting convert for ${plot}.ras at `${DATE}`"
  if [ -s ${plot}.ras ]; then 
#    ${CONVERT} -colors 128 -trim -border 25x25 -bordercolor black ${plot}.ras ${plot}.png
#    error=$?
#    if [ ${error} -ne 0 ]; then
#      ${ECHO} "ERROR: convert ${plot}.ras crashed!  Exit status=${error}"
#      ncl_error=${error}
#    fi
    echo "${CONVERT} -colors 128 -trim -border 25x25 -bordercolor black ${plot}.ras ${plot}.png" >> $CMDFN
  else 
    ${ECHO} "No file to convert, exit gracefully"
    ncl_error=0
  fi
  ${ECHO} "Finished convert for ${plot}.ras at `${DATE}`"

  (( i=i + 1 ))

done

${CAT} $CMDFN | ${XARGS} -P $THREADS -I {} ${BASH} -c "{}" 
ncl_error=$?
${RM} -f $CMDFN

# Copy png files to their proper names
i=0
while [ ${i} -lt ${#pngs[@]} ]; do
  pngfile=${pngs[${i}]}
  fulldir=${DATAHOME}/nclprd/full
  ${MKDIR} -p ${fulldir}
  webfile=${fulldir}/${webnames[${i}]}_f${FCST_TIME}.png
#  webfile=${webnames[${i}]}_f${FCST_TIME}.png    # for testing
  ${MV} ${pngfile} ${webfile}
  (( i=i + 1 ))
  pngfile=${pngs[${i}]}
  t1dir=${DATAHOME}/nclprd/t1
  ${MKDIR} -p ${t1dir}
  webfile=${t1dir}/${webnames[${i}]}_f${FCST_TIME}.png
  ${MV} ${pngfile} ${webfile}
  (( i=i + 1 ))
  pngfile=${pngs[${i}]}
  t2dir=${DATAHOME}/nclprd/t2
  ${MKDIR} -p ${t2dir}
  webfile=${t2dir}/${webnames[${i}]}_f${FCST_TIME}.png
  ${MV} ${pngfile} ${webfile}
  (( i=i + 1 ))
  pngfile=${pngs[${i}]}
  t3dir=${DATAHOME}/nclprd/t3
  ${MKDIR} -p ${t3dir}
  webfile=${t3dir}/${webnames[${i}]}_f${FCST_TIME}.png
  ${MV} ${pngfile} ${webfile}
  (( i=i + 1 ))
  pngfile=${pngs[${i}]}
  t4dir=${DATAHOME}/nclprd/t4
  ${MKDIR} -p ${t4dir}
  webfile=${t4dir}/${webnames[${i}]}_f${FCST_TIME}.png
  ${MV} ${pngfile} ${webfile}
  (( i=i + 1 ))
  pngfile=${pngs[${i}]}
  t5dir=${DATAHOME}/nclprd/t5
  ${MKDIR} -p ${t5dir}
  webfile=${t5dir}/${webnames[${i}]}_f${FCST_TIME}.png
  ${MV} ${pngfile} ${webfile}
  (( i=i + 1 ))
  pngfile=${pngs[${i}]}
  t6dir=${DATAHOME}/nclprd/t6
  ${MKDIR} -p ${t6dir}
  webfile=${t6dir}/${webnames[${i}]}_f${FCST_TIME}.png
  ${MV} ${pngfile} ${webfile}
  (( i=i + 1 ))
  pngfile=${pngs[${i}]}
  t7dir=${DATAHOME}/nclprd/t7
  ${MKDIR} -p ${t7dir}
  webfile=${t7dir}/${webnames[${i}]}_f${FCST_TIME}.png
  ${MV} ${pngfile} ${webfile}
  (( i=i + 1 ))
  pngfile=${pngs[${i}]}
  t8dir=${DATAHOME}/nclprd/t8
  ${MKDIR} -p ${t8dir}
  webfile=${t8dir}/${webnames[${i}]}_f${FCST_TIME}.png
  ${MV} ${pngfile} ${webfile}
  (( i=i + 1 ))
  pngfile=${pngs[${i}]}
  z0dir=${DATAHOME}/nclprd/z0
  ${MKDIR} -p ${z0dir}
  webfile=${z0dir}/${webnames[${i}]}_f${FCST_TIME}.png
  ${MV} ${pngfile} ${webfile}
  (( i=i + 1 ))
  pngfile=${pngs[${i}]}
  z1dir=${DATAHOME}/nclprd/z1
  ${MKDIR} -p ${z1dir}
  webfile=${z1dir}/${webnames[${i}]}_f${FCST_TIME}.png
  ${MV} ${pngfile} ${webfile}
  (( i=i + 1 ))
  pngfile=${pngs[${i}]}
  z2dir=${DATAHOME}/nclprd/z2
  ${MKDIR} -p ${z2dir}
  webfile=${z2dir}/${webnames[${i}]}_f${FCST_TIME}.png
  ${MV} ${pngfile} ${webfile}
  (( i=i + 1 ))
  pngfile=${pngs[${i}]}
  z3dir=${DATAHOME}/nclprd/z3
  ${MKDIR} -p ${z3dir}
  webfile=${z3dir}/${webnames[${i}]}_f${FCST_TIME}.png
  ${MV} ${pngfile} ${webfile}
  (( i=i + 1 ))
  pngfile=${pngs[${i}]}
  z4dir=${DATAHOME}/nclprd/z4
  ${MKDIR} -p ${z4dir}
  webfile=${z4dir}/${webnames[${i}]}_f${FCST_TIME}.png
  ${MV} ${pngfile} ${webfile}
  (( i=i + 1 ))
done

# Remove the workdir
${RM} -rf ${workdir}

${ECHO} "ncl.ksh completed at `${DATE}`"

exit ${ncl_error}