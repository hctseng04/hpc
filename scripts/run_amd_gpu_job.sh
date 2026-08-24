#!/usr/bin/env bash
# run_amd_gpu_job.sh
# Wait until N GPUs are idle, then run your program in background.
# Usage: ./run_mpi_when_free.sh <num_gpus> <your_program> [program_args...] [--log <logfile>]

SLEEP_INTERVAL=${SLEEP_INTERVAL:-60}   # seconds between checks

usage() {
  cat <<EOF
Usage: $0 <num_gpus> <your_program> [program_args...] [--log <logfile>]
Example: $0 2 ./run_kramu_2gpu.sh --input file --log myjob.log
EOF
  exit 1
}

if [ $# -lt 2 ]; then usage; fi

NUM_GPUS=$1
shift

# parse optional --log argument
LOGFILE=""
PROGRAM=()
while [[ $# -gt 0 ]]; do
  if [[ "$1" == "--log" ]]; then
    shift
    if [[ -z "$1" ]]; then
      echo "Error: --log requires a filename"
      exit 1
    fi
    LOGFILE=$1
    shift
  else
    PROGRAM+=("$1")
    shift
  fi
done

if [[ ${#PROGRAM[@]} -eq 0 ]]; then
  echo "Error: no program specified"
  usage
fi

# Function to detect idle GPUs
check_idle_gpus() {
  rocm-smi --showuse --showpower 2>/dev/null | \
    awk -F'[:%]' '
      /GPU\[.*GPU use/ {
        gpu=$1; gsub(/[^0-9]/,"",gpu);
        util=$3+0;
        use[gpu]=util;
      }
      /GPU\[.*Power/ {
        gpu=$1; gsub(/[^0-9]/,"",gpu);
        power=$3+0;
        pow[gpu]=power;
      }
      END {
        for (g in use) {
          if (use[g]==0 && pow[g]<100) print g;
        }
      }' | sort -n
}

echo "Waiting for $NUM_GPUS idle GPUs (checking every ${SLEEP_INTERVAL}s) ..."
while true; do
  mapfile -t IDLE_GPUS < <(check_idle_gpus)
  idle_count=${#IDLE_GPUS[@]}

  if (( idle_count >= NUM_GPUS )); then
    echo "Found $idle_count idle GPUs: ${IDLE_GPUS[*]}"
    SELECTED=( "${IDLE_GPUS[@]:0:NUM_GPUS}" )
    SELECTED_GPUS=$(IFS=,; echo "${SELECTED[*]}")
    echo "Using GPUs: $SELECTED_GPUS"
    export HIP_VISIBLE_DEVICES="$SELECTED_GPUS"

    if [[ -n "$LOGFILE" ]]; then
      echo "Launching: ${PROGRAM[*]} > $LOGFILE 2>&1 (in background)"
      "${PROGRAM[@]}" > "$LOGFILE" 2>&1 &
    else
      echo "Launching: ${PROGRAM[*]} (in background)"
      "${PROGRAM[@]}" &
    fi

    disown
    exit 0
  else
    echo "Waiting... only $idle_count idle GPUs available (need $NUM_GPUS). Checking again in ${SLEEP_INTERVAL}s."
    sleep "$SLEEP_INTERVAL"
  fi
done
