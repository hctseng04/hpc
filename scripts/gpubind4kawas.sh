#!/bin/bash

MYHOST=`hostname -s`
IFS=',' declare -a 'CUDA_VISIBLE_DEVICES_CPU=($CUDA_VISIBLE_DEVICES)'
IFS=',' declare -a 'CUDA_VISIBLE_DEVICES_GPUID=($CUDA_VISIBLE_DEVICES)'

# kawas17
KAWAS17_ARRY_GPU_LISTS=( "GPU-2e21eb45-f755-8aba-505e-39c416840ee9"
                         "GPU-31dae178-30f1-99c9-a5f7-6026c15e323c"
                         "GPU-6c085808-de42-2c2c-a61c-c16f14d5b8ee"
                         "GPU-d075e29e-0b5d-400b-fdd8-16c9a450547f"
                         "GPU-3c07068f-1176-1bb1-b96c-488d02825e41"
                         "GPU-46d12b2f-3f9b-363c-4b6c-b99ee4640e3c"
                         "GPU-cba16ace-9461-7418-c8df-8b57b2045ca9"
                         "GPU-40893529-3837-da6d-5a31-ee7e260bd88d" )

# kawas18
KAWAS18_ARRY_GPU_LISTS=( "GPU-e92922b4-7ce8-170d-7146-df51111da887"
                         "GPU-357c1158-ec85-58fe-9db5-c7e010adca8c"
                         "GPU-ec72e6df-a580-7c46-d5ca-dc82ca37723a"
                         "GPU-d28e1ae3-12a0-5ed7-afa2-50127add4b92"
                         "GPU-82f43607-b06f-4976-b0b9-b523571019e9"
                         "GPU-0fefae63-984c-dff5-215e-2493047ae1c0"
                         "GPU-ea781671-2ee1-d8ac-3224-481097dd3f0d"
                         "GPU-b694d9a3-6df2-9937-94a0-e9795f1dfad2" )

ARRY_GPU_CPUBIND_LISTS=( 36 42 12 18 84 90 60 66 )

if [ $MYHOST == "kawas17" ]
then
    MYHOST_ARRY_GPU_LISTS=("${KAWAS17_ARRY_GPU_LISTS[@]}")
elif [ $MYHOST == "kawas18" ]
then
    MYHOST_ARRY_GPU_LISTS=("${KAWAS18_ARRY_GPU_LISTS[@]}")
else
    exit 1
fi

arraylength=${#CUDA_VISIBLE_DEVICES_CPU[@]}

for (( i=0; i<${arraylength}; i++ ));
do
    for j in "${!MYHOST_ARRY_GPU_LISTS[@]}"; do
        if [ ${CUDA_VISIBLE_DEVICES_CPU[i]} == ${MYHOST_ARRY_GPU_LISTS[j]} ]
        then
            CUDA_VISIBLE_DEVICES_CPU[i]=${ARRY_GPU_CPUBIND_LISTS[j]}
	          CUDA_VISIBLE_DEVICES_GPUID[i]=$j
            break
        fi
    done
done

#export CUDA_VISIBLE_DEVICES_BINDCPU=`echo $(echo ${CUDA_VISIBLE_DEVICES_CPU[@]}) | tr ' ' ','`

#echo ${CUDA_VISIBLE_DEVICES_GPUID[@]}

CPU=${CUDA_VISIBLE_DEVICES_CPU[$OMPI_COMM_WORLD_LOCAL_RANK]}

numactl -a -l --physcpubind="${CPU}" $@
