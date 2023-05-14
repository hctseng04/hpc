#!/bin/bash

IFS=',' declare -a 'ARRY_GPU_LISTS=($CUDA_VISIBLE_DEVICES)'
IFS=',' declare -a 'ARRY_CPU_LISTS=($CUDA_VISIBLE_DEVICES)'

arraylength=${#ARRY_GPU_LISTS[@]}

for (( i=0; i<${arraylength}; i++ ));
do
    ARRY_GPU_LISTS[$i]=""
    ARRY_CPU_LISTS[$i]=""
done

mkdir -p $PBS_O_WORKDIR/$PBS_JOBID

nvidia-smi -L > $PBS_O_WORKDIR/$PBS_JOBID/nvidia-smi_l_`hostname -s`
NVIDIA_SMI_L_FILE="$PBS_O_WORKDIR/$PBS_JOBID/nvidia-smi_l_`hostname -s`"
nvidia-smi topo --matrix > $PBS_O_WORKDIR/$PBS_JOBID/nvidia-smi_topo_`hostname -s`
NVIDIA_SMI_TOPO_FILE="$PBS_O_WORKDIR/$PBS_JOBID/nvidia-smi_topo_`hostname -s`"

#nvidia-smi -L > nvidia-smi_l_`hostname -s`
#nvidia-smi topo --matrix > nvidia-smi_topo_`hostname -s`
#NVIDIA_SMI_L_FILE=`pwd`/nvidia-smi_l_`hostname -s`
#NVIDIA_SMI_TOPO_FILE=`pwd`/nvidia-smi_topo_`hostname -s`

for i in ${CUDA_VISIBLE_DEVICES//,/ }
do
    GPUID=`cat $NVIDIA_SMI_L_FILE | grep $i | awk '{print $2}' | sed -e 's/://g'`
    # echo "GPUID : "$GPUID
    ARRY_GPU_LISTS[$GPUID]=$i
done

for (( i=0; i<${arraylength}; i++ ));
do
    CPUSETS=`cat $NVIDIA_SMI_TOPO_FILE | grep GPU$i | tail -n 1 | awk -vCPU_INDEX=$((arraylength + 5)) '{print $CPU_INDEX}'`
    # echo "CPUSETS : "$CPUSETS
    CPUID_BEGIN="${CPUSETS%%-*}"
    CPUID_END="${CPUSETS##*-}"
    # echo "CPUID : "$CPUID
    if [[ ! "${ARRY_CPU_LISTS[*]}" =~ "${CPUID_BEGIN}" ]]
    then
        ARRY_CPU_LISTS[$i]=$CPUID_BEGIN
    else
	CPUID_MIDDLE=$(( (${CPUID_END} - ${CPUID_BEGIN} + 1) / 2 + ${CPUID_BEGIN}))
        ARRY_CPU_LISTS[$i]=$CPUID_MIDDLE
    fi
done

#rm -rf $NVIDIA_SMI_TOPO_FILE $NVIDIA_SMI_L_FILE

#echo ${ARRY_GPU_LISTS[@]}
#echo ${ARRY_CPU_LISTS[@]}

export CUDA_VISIBLE_DEVICES=${ARRY_GPU_LISTS[$OMPI_COMM_WORLD_LOCAL_RANK]}
numactl -a -l --physcpubind="${ARRY_CPU_LISTS[$OMPI_COMM_WORLD_LOCAL_RANK]}" $@
