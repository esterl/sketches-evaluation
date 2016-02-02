#!/bin/bash
CSCRATCH=/scratch/nas/1/`whoami`
ID=$JOB_ID.$SGE_TASK_ID

# Activate virtual environment
cd $CSCRATCH
source venv/bin/activate

# Install sketches
cd sketches/pythonlib
python setup.py install
export LD_LIBRARY_PATH="/scratch/nas/1/esterl/sketches"

cd $CSCRATCH
cd SummaryFunctions

# Copy pcap
cp $CSCRATCH/pcaps/equinix-*pcap ~/equinix.$ID.pcap
cp $CSCRATCH/pcaps/equinix.nodups.pcap ~/equinix.nodups.$ID.pcap

pcap=~/equinix.$ID.pcap
pcapNodups=~/equinix.nodups.$ID.pcap
ulimit -c 0 # Disable core file creation

### Digest experiments
# 1. Small drop probability
python estimate-ratio.py digest1.$ID $pcap --rows 32 --columns 32 \
  --hashFunction default --xiFunction default --numPackets 10000 --maxIter 100 \
  --averageFunction mean --dropProbability 0.01
# 2. Large drop probability
python estimate-ratio.py digest2.$ID $pcap --rows 32 --columns 32 \
  --hashFunction default --xiFunction default --numPackets 10000 --maxIter 100 \
  --averageFunction mean --dropProbability 0.5

### Pseudo-random functions
python estimate-ratio.py random1.$ID $pcap --rows 32 --columns 32 \
  --numPackets 10000 --maxIter 100 --averageFunction mean --dropProbability 0.1 \
  --digestSize 32

### Number of packets
# 1. Small drop probability
python estimate-ratio.py packets1.$ID $pcap --rows 32 --columns 32 \
  --maxIter 100 --averageFunction mean --dropProbability 0.1 --digestSize 32 \
  --hashFunction default --xiFunction default
# 2. Large drop probability
python estimate-ratio.py packets2.$ID $pcap --rows 32 --columns 32 \
  --maxIter 100 --averageFunction mean --dropProbability 0.6 --digestSize 32 \
  --hashFunction default --xiFunction default

### Drop probability
python estimate-ratio.py drop1.$ID $pcap --rows 32 --columns 32 \
  --maxIter 100 --averageFunction mean --numPackets 10000 --digestSize 32 \
  --hashFunction default --xiFunction default

### Number of columns
# 1. Small drop probability
python estimate-ratio.py columns1.$ID $pcap --rows 32 --dropProbability 0.1 \
  --maxIter 100 --averageFunction mean --numPackets 1000 --digestSize 32 \
  --hashFunction default --xiFunction default
python estimate-ratio.py columns4.$ID $pcapNodups --rows 32 --dropProbability 0.1 \
  --maxIter 100 --averageFunction mean --numPackets 1000 --digestSize 32 \
  --hashFunction default --xiFunction default
# 2. Large drop probability
python estimate-ratio.py columns2.$ID $pcap --rows 32 --dropProbability 0.6 \
  --maxIter 100 --averageFunction mean --numPackets 1000 --digestSize 32 \
  --hashFunction default --xiFunction default
python estimate-ratio.py columns5.$ID $pcapNodups --rows 32 --dropProbability 0.6 \
  --maxIter 100 --averageFunction mean --numPackets 1000 --digestSize 32 \
  --hashFunction default --xiFunction default
# 3. One row
python estimate-ratio.py columns3.$ID $pcap --rows 1 --dropProbability 0.1 \
  --maxIter 100 --averageFunction mean --numPackets 1000 --digestSize 32 \
  --hashFunction default --xiFunction default
python estimate-ratio.py columns6.$ID $pcapNodups --rows 1 --dropProbability 0.1 \
  --maxIter 100 --averageFunction mean --numPackets 1000 --digestSize 32 \
  --hashFunction default --xiFunction default

### Number of rows
# 1. Average function
python estimate-ratio.py average1.$ID $pcap --rows 32 --dropProbability 0.1 \
  --maxIter 100 --columns 32 --numPackets 1000 --digestSize 32 \
  --hashFunction default --xiFunction default
# 2. Number of rows
python estimate-ratio.py rows1.$ID $pcap --columns 32 --dropProbability 0.1 \
  --maxIter 100 --averageFunction mean --numPackets 1000 --digestSize 32 \
  --hashFunction default --xiFunction default
python estimate-ratio.py rows2.$ID $pcapNodups --columns 32 --dropProbability 0.1 \
  --maxIter 100 --averageFunction mean --numPackets 1000 --digestSize 32 \
  --hashFunction default --xiFunction default
# 3. Aspect ratio
for COLUMNS in 512 1024 #4 8 16 32 64 128 256 512 1024
do
    ROWS=$((1024/COLUMNS))
    python estimate-ratio.py aspect1.$ID.$COLUMNS $pcap --columns $COLUMNS --dropProbability 0.1 \
      --maxIter 100 --averageFunction mean --numPackets 100 --digestSize 32 \
      --hashFunction default --xiFunction default --rows $ROWS
    python estimate-ratio.py aspect2.$ID.$COLUMNS $pcap --columns $COLUMNS --dropProbability 0.1 \
      --maxIter 100 --averageFunction mean --numPackets 10000 --digestSize 32 \
      --hashFunction default --xiFunction default --rows $ROWS
done

### Time interval
# 1. Equinix
python estimate-ratio.py equinix1.$ID $pcap --rows 32 --dropProbability 0.1 \
  --maxIter 100 --columns 32 --numPackets 1000 --digestSize 32 \
  --hashFunction default --xiFunction default --averageFunction mean \
  --byInterval
python estimate-ratio.py equinix2.$ID $pcap --rows 16 --dropProbability 0.1 \
  --maxIter 100 --columns 16 --digestSize 32 \
  --hashFunction default --xiFunction default --averageFunction mean \
  --byInterval
python estimate-ratio.py equinix3.$ID $pcap --rows 16 --dropProbability 0.01 \
  --maxIter 100 --columns 16 --digestSize 32 \
  --hashFunction default --xiFunction default --averageFunction mean \
  --byInterval
# 2. Sagunt
pcap=$CSCRATCH/pcaps/morning_sagunt.pcap
python estimate-ratio.py sagunt1.$ID $pcap --rows 32 --dropProbability 0.1 \
  --maxIter 100 --columns 32 --numPackets 1000 --digestSize 32 \
  --hashFunction default --xiFunction default --averageFunction mean \
  --byInterval
python estimate-ratio.py sagunt2.$ID $pcap --rows 16 --dropProbability 0.1 \
  --maxIter 100 --columns 16 --digestSize 32 \
  --hashFunction default --xiFunction default --averageFunction mean \
  --byInterval
python estimate-ratio.py sagunt3.$ID $pcap --rows 16 --dropProbability 0.01 \
  --maxIter 100 --columns 16 --digestSize 32 \
  --hashFunction default --xiFunction default --averageFunction mean \
  --byInterval
# 3. Proxy
pcap=$CSCRATCH/pcaps/anon.pcap
python estimate-ratio.py proxy1.$ID $pcap --rows 32 --dropProbability 0.1 \
  --maxIter 100 --columns 32 --numPackets 1000 --digestSize 32 \
  --hashFunction default --xiFunction default --averageFunction mean \
  --byInterval
python estimate-ratio.py proxy2.$ID $pcap --rows 16 --dropProbability 0.1 \
  --maxIter 100 --columns 16 --digestSize 32 \
  --hashFunction default --xiFunction default --averageFunction mean \
  --byInterval
python estimate-ratio.py proxy2.$ID $pcap --rows 16 --dropProbability 0.01 \
  --maxIter 100 --columns 16 --digestSize 32 \
  --hashFunction default --xiFunction default --averageFunction mean \
  --byInterval

#### Cost: memory and bandwidth
pcap=~/equinix.$ID.pcap
python estimate-ratio.py memory-equinix1.$ID $pcap --dropProbability 0.1 \
  --maxIter 100 --byInterval --interval 5 --hashFunction default \
  --xiFunction default --averageFunction mean --squareSketch
pcap=$CSCRATCH/pcaps/morning_sagunt.pcap
python estimate-ratio.py memory-sagunt1.$ID $pcap --dropProbability 0.1 \
  --maxIter 100 --byInterval --interval 5 --hashFunction default \
  --xiFunction default --averageFunction mean --squareSketch
pcap=$CSCRATCH/pcaps/anon.pcap
python estimate-ratio.py memory-proxy1.$ID $pcap --dropProbability 0.1 \
  --maxIter 100 --byInterval --interval 5 --hashFunction default \
  --xiFunction default --averageFunction mean --squareSketch

### Time interval
rm ~/Ratio*
rm ~/*$ID.pcap
