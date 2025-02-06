#!/bin/bash

set -e

date=$(date "+%F_%T")

for ((buffer_size=4; buffer_size <= 128; buffer_size *= 2)); do
    echo "Running with input buffer size $buffer_size"
    sed -i switch/testbench/switch_measure_wrapper.sv -e "s/localparam BUFFER_SIZE.*/localparam BUFFER_SIZE = $buffer_size;/"
    sed -i switch/testbench/NetworkManager.h -e "s/define BUFFER_SIZE.*/define BUFFER_SIZE $buffer_size/"
    make versim_switch_src_measure || true
    dir="logs/${date}/sweep_${buffer_size}"
    mkdir -p $dir
    cp tmp/build/measure-verilator/switch*_* $dir
    for file in $dir/*; do
        new=$(echo $file | sed -e "s/\(switch.*perf\).*/\1.txt/")
        mv $file $new
    done
done
