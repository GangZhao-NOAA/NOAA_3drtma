#!/bin/ksh --login

np=`cat $PBS_NODEFILE | wc -l`

# Load modules
module purge
module load szip/2.1
module load intel/18.0.5.274
module load hdf5/1.8.9
module load netcdf/4.2.1.1
module load mvapich2/2.3
module load ncl/6.5.0
module load imagemagick/7.0.8-34

# Make sure we are using GMT time zone for time computations
export TZ="GMT"
export NCARG_ROOT="/apps/ncl/6.5.0-CentOS6.10_64bit_nodap_gnu447"
export NCARG_LIB="/apps/ncl/6.5.0-CentOS6.10_64bit_nodap_gnu447/lib"
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
NCL=${NCARG_ROOT}/bin/ncl
CTRANS=${NCARG_ROOT}/bin/ctrans
PS2PDF=/usr/bin/ps2pdf
CONVERT=`which convert`
MONTAGE=`which montage`
PATH=${NCARG_ROOT}/bin:${PATH}

typeset -RZ2 FCST_TIME

# ulimit -s 512000
ulimit -s 1024000

# Settings for testing
EXE_ROOT=/misc/whome/wrfruc/bin/ncl/nclhrrr
# START_TIME=2011101106
# FCST_TIME=12
# DATAROOT=/home/rtrr/hrrr
# DATAHOME=${DATAROOT}/${START_TIME}

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
  ${ECHO} "START_TIME not defined - get from date"
  START_TIME=$( date +"%Y%m%d %H" )
  START_TIME=$( date +"%Y%m%d%H" -d "${START_TIME}" )
else
  ${ECHO} "START_TIME defined and is ${START_TIME}"
  START_TIME=$( date +"%Y%m%d %H" -d "${START_TIME%??} ${START_TIME#????????}" )
  START_TIME=$( date +"%Y%m%d%H" -d "${START_TIME}" )
fi

# Print out times
# ${ECHO} "   START TIME = "`${DATE} +%Y%m%d%H -d "${START_TIME}"`
${ECHO} "   START_TIME = ${START_TIME}"
${ECHO} "   FCST_TIME = ${FCST_TIME}"

# Set up the work directory and cd into it
# workdir=nclprd/${FCST_TIME}skewt4   # for testing
workdir=${DATAHOME}/nclprd/${FCST_TIME}skewt4
${RM} -rf ${workdir}
${MKDIR} -p ${workdir}
# skewtdir=nclprd/skewt   # for testing
skewtdir=${DATAHOME}/nclprd/skewt
${MKDIR} -p ${skewtdir}
cd ${workdir}

# Link to input file
${LN} -s ${DATAHOME}/postprd/wrfnat_hrconus_${FCST_TIME}.grib2 nat_file.grb
${ECHO} "nat_file.grb" > nat_file.txt
ls -al nat_file.grb
${LN} -s ${DATAHOME}/postprd/wrfprs_hrconus_${FCST_TIME}.grib2 prs_file.grb
${ECHO} "prs_file.grb" > prs_file.txt
ls -al prs_file.grb
${LN} -s ${EXE_ROOT}/hrrrterrainland.grib2 hrrrterrainland.grib2

set -A ncgms  sfc_skewt4

set -A pngs sfc_skewt4-0.png   \
            sfc_skewt4-1.png   \
            sfc_skewt4-2.png   \
            sfc_skewt4-3.png   \
            sfc_skewt4-4.png   \
            sfc_skewt4-5.png   \
            sfc_skewt4-6.png   \
            sfc_skewt4-7.png   \
            sfc_skewt4-8.png   \
            sfc_skewt4-9.png   \
            sfc_skewt4-10.png  \
            sfc_skewt4-11.png  \
            sfc_skewt4-12.png  \
            sfc_skewt4-13.png  \
            sfc_skewt4-14.png  \
            sfc_skewt4-15.png  \
            sfc_skewt4-16.png  \
            sfc_skewt4-17.png  \
            sfc_skewt4-18.png  \
            sfc_skewt4-19.png  \
            sfc_skewt4-20.png  \
            sfc_skewt4-21.png

set -A webnames skewt_MFL_72202 \
                skewt_NTD_72391 \
                skewt_NSI_72291 \
                skewt_VBG_72393 \
                skewt_IAD_72403 \
                skewt_WAL_72402 \
                skewt_MHX_72305 \
                skewt_TLH_72214 \
                skewt_GGW_72768 \
                skewt_UNR_72662 \
                skewt_UIL_72797 \
                skewt_OKX_72501 \
                skewt_PIT_72520 \
                skewt_OAX_72558 \
                skewt_DVN_74455 \
                skewt_MPX_72649 \
                skewt_999_74001 \
                skewt_999_74005 \
                skewt_999_74626 \
                skewt_LMN_74646 \
                skewt_MSN_99999 \
                skewt_MKE_99999

ncl_error=0

# Run the NCL scripts for each plot
cp ${EXE_ROOT}/names_grib2.txt .
cp ${EXE_ROOT}/conus_raobs4.txt .
cp ${EXE_ROOT}/skewt_func.ncl .
cp ${EXE_ROOT}/plot_hodo.ncl .

i=0
while [ ${i} -lt ${#ncgms[@]} ]; do

  plot=${ncgms[${i}]}
  ${ECHO} "Starting rr_${plot}.ncl at `${DATE}`"
  ${NCL} < ${EXE_ROOT}/rr_${plot}.ncl
  error=$?
  if [ ${error} -ne 0 ]; then
    ${ECHO} "ERROR: rr_${plot} crashed!  Exit status=${error}"
    ncl_error=${error}
  fi
  ${ECHO} "Finished rr_${plot}.ncl at `${DATE}`"

  (( i=i + 1 ))

done

# Convert the .ps files into .png files
i=0
while [ ${i} -lt ${#ncgms[@]} ]; do

  plot=${ncgms[${i}]}
  ${ECHO} "Starting convert for ${plot} at `${DATE}`"

  if [ -s ${plot}.ps ]; then
# skewt image
    ${CONVERT} -colors 128 -trim -density 300 -geometry 700x700 -border 25x25 -bordercolor black ${plot}.ps ${plot}.png
    error=$?
    if [ ${error} -ne 0 ]; then      ${ECHO} "ERROR: convert ${plot}.ps crashed!  Exit status=${error}"
      ncl_error=${error}
    fi
    ${ECHO} "Finished convert for ${plot}.ps at `${DATE}`"
  else
    ${ECHO} "No file to convert, exit gracefully"
    ncl_error=0
  fi

  (( i=i + 1 ))
  
done

# Copy png files to their proper names
i=0
while [ ${i} -lt ${#pngs[@]} ]; do
  pngfile=${pngs[${i}]}
  webfile=${DATAHOME}/nclprd/skewt/${webnames[${i}]}_f${FCST_TIME}.png
#  webfile=/home/rtrr/HRRR3_conus/bin/nclprd/skewt/${webnames[${i}]}_f${FCST_TIME}.png    # for testing
  ${MV} ${pngfile} ${webfile}

  (( i=i + 1 ))
done

# Remove the workdir
${RM} -rf ${workdir}

${ECHO} "ncl.ksh completed at `${DATE}`"

exit ${ncl_error}
