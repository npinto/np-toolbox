#!/bin/bash

set -e
set -x

# -- if a session 'burn' already exists, re-attach
tmux ls | grep '^burn:' && tmux attach -d -t burn && exit 0

# -- otherwise create it
tmux new-session -d -s burn htop

#tmux split-window -v -t burn:0 "stress -m 1 --vm-bytes $((1024**3)) -c 1 -d 1 -i 1"
tmux split-window -v -t burn:0 "stress -m 8 --vm-bytes $((1024**3)) -c 4 -d 4 -i 4"
tmux split-window -v -t burn:0 "watch 'nvidia-smi -a | grep Gpu | grep C; uptime'"
tmux resize-pane -t burn:0.0 -D 40

/opt/cuda/sdk/C/bin/linux/release/deviceQuery
for i in $(seq `ls /dev/nvidia? | wc -l`); do
    dev=$(($i-1));
    tmux new-window -t burn:$i "cuda_memtest --stress --device $dev";
done;

tmux select-window -t burn:0

tmux attach -t burn
