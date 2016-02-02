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
ulimit -c 0 # Disable core file creation

### Digest size
# 1. Little packets
python estimate-total.py digest1.$ID $pcap --rows 1 --columns 256 \
    --hashFunction default --xiFunction default --numPackets 100 --maxIter 100 \
    --averageFunction median
# 2. Many packets
python estimate-total.py digest2.$ID $pcap --rows 1 --columns 256 \
    --hashFunction default --xiFunction default --numPackets 10000 \
     --maxIter 100 --averageFunction median
# 3. Bias
python estimate-total.py digest3.$ID $pcap --rows 1 --columns 256 \
         --hashFunction default --maxIter 100 --averageFunction median \
         --xiFunction default

# Pseudo-random functions
# 1. Basic little packets
python estimate-total.py xi1.$ID $pcap --rows 1 --columns 256 \
    --digestSize 32 --numPackets 100 --maxIter 100 --averageFunction median \
    --hashFunction default
python estimate-total.py hash1.$ID $pcap --rows 1 --columns 256 \
    --digestSize 32 --numPackets 100 --maxIter 100 --averageFunction median \
    --xiFunction default
# 2. Many packets
python estimate-total.py xi2.$ID $pcap --rows 1 --columns 256 \
    --digestSize 32 --numPackets 10000 --maxIter 100 --averageFunction median \
    --hashFunction default
python estimate-total.py hash2.$ID $pcap --rows 1 --columns 256 \
    --digestSize 32 --numPackets 10000 --maxIter 100 --averageFunction median \
    --xiFunction default
# 3. Several rows
python estimate-total.py xi3.$ID $pcap --rows 32 --columns 32 \
    --digestSize 32 --numPackets 10000 --maxIter 100 --averageFunction median \
    --hashFunction default
python estimate-total.py hash3.$ID $pcap --rows 32 --columns 32 \
    --digestSize 32 --numPackets 10000 --maxIter 100 --averageFunction median \
    --xiFunction default

# Number of packets
# 1. Basic estimator
python estimate-total.py packets1.$ID $pcap --rows 1 --columns 256 \
    --digestSize 32 --maxIter 100 --averageFunction median \
    --xiFunction default --hashFunction default
# 2. Square sketch
python estimate-total.py packets2.$ID $pcap --rows 32 --columns 32 \
    --digestSize 32 --maxIter 100 --averageFunction median \
    --xiFunction default --hashFunction default

# Number of columns
# 1. Few packets
python estimate-total.py columns1.$ID $pcap --rows 1 --numPackets 100 \
    --digestSize 32 --maxIter 100 --averageFunction median \
    --xiFunction default --hashFunction default
# 2. Many packets
python estimate-total.py columns2.$ID $pcap --rows 1 --numPackets 10000 \
    --digestSize 32 --maxIter 100 --averageFunction median \
    --xiFunction default --hashFunction default
# 3. Several rows
python estimate-total.py columns3.$ID $pcap --rows 32 --numPackets 1000 \
    --digestSize 32 --maxIter 100 --averageFunction median \
    --xiFunction default --hashFunction default
# 4. No duplicates
pcapNodups=~/equinix.nodups.$ID.pcap
python estimate-total.py columns4.$ID $pcapNodups --rows 32 --numPackets 1000 \
    --digestSize 32 --maxIter 100 --averageFunction median \
    --xiFunction default --hashFunction default 

# Average function
# 1. Few packets
python estimate-total.py average1.$ID $pcap --rows 32 --columns 32 \
    --digestSize 32 --maxIter 100 --xiFunction default \
    --hashFunction default --numPackets 100
# 2. Many packets
python estimate-total.py average2.$ID $pcap --rows 32 --columns 32 \
    --digestSize 32 --maxIter 100 --xiFunction default \
    --hashFunction default --numPackets 10000
# 3. Idem with no dups
python estimate-total.py average3.$ID $pcapNodups --rows 32 --columns 32 \
    --digestSize 32 --maxIter 100 --xiFunction default \
    --hashFunction default --numPackets 10000

## Number of rows
python estimate-total.py rows1.$ID $pcap --averageFunction mean --columns 32 \
    --digestSize 32 --maxIter 100 --xiFunction default \
    --hashFunction default --numPackets 1000
# Idem with no dups
python estimate-total.py rows2.$ID $pcapNodups --averageFunction mean --columns 32 \
    --digestSize 32 --maxIter 100 --xiFunction default --hashFunction default \
    --numPackets 1000

## Aspect ratio
for COLUMNS in 8 16 32 64 128 256 512 1024
do
  ROWS=$((1024/$COLUMNS))
  python estimate-total.py aspect1.$ID.$COLUMNS $pcapNodups --rows $ROWS \
    --columns $COLUMNS --digestSize 32 --maxIter 100 --xiFunction default \
    --hashFunction default --numPackets 100 --averageFunction mean
  python estimate-total.py aspect2.$ID.$COLUMNS $pcapNodups --rows $ROWS \
    --columns $COLUMNS --digestSize 32 --maxIter 100 --xiFunction default \
    --hashFunction default --numPackets 10000 --averageFunction mean
done

# Delete output
rm ~/Total*
rm ~/*.$ID.pcap
