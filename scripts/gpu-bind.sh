#!/bin/bash

case $OMPI_COMM_WORLD_LOCAL_RANK in
0|8)
  export CUDA_VISIBLE_DEVICES=0
  CPUS="36"
  ;;
1|9)
  export CUDA_VISIBLE_DEVICES=1
  CPUS="40"
  ;;
2|10)
  export CUDA_VISIBLE_DEVICES=2
  CPUS="12"
  ;;
3|11)
  export CUDA_VISIBLE_DEVICES=3
  CPUS="16"
  ;;
4|12)
  export CUDA_VISIBLE_DEVICES=4
  CPUS="84"
  ;;
5|13)
  export CUDA_VISIBLE_DEVICES=5
  CPUS="88"
  ;;
6|14)
  export CUDA_VISIBLE_DEVICES=6
  CPUS="60"
  ;;
7|15)
  export CUDA_VISIBLE_DEVICES=7
  CPUS="64"
  ;;
*)
  echo usage .. unexpected default case ...
  exit 1
esac
numactl -a -l --physcpubind="${CPUS}" $@
