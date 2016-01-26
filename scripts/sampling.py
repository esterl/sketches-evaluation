from __future__ import division
import argparse
from scapy.all import *
import numpy as np
import hashlib
import random

def get_hash(pkt, key=0):
    """Returns the hash of the packet xor the key."""
    while pkt is not None and not pkt.name in ['IPv6', 'IP']:
        pkt = pkt.getlayer(1)
    if pkt is None:
        return None
    if pkt.name == 'IPv6':
        pkt.setfieldval('hlim', 0)
    elif pkt.name == 'IP':
        pkt.setfieldval('ttl', 0)
    try:
        packet_hash = hashlib.sha256(pkt.__str__()[0:len(pkt.original)]).hexdigest()
    except TypeError:
        warnings.warn('Packet error')
        packet_hash = hashlib.sha256(pkt.original).hexdigest()
    return long(packet_hash, base=16)^key

def estimate_total(pcap, sampling_probability, digest_size, num_packets, 
                    max_iter=10):
    """Reads repeatedly num_packets packets from the pcap and simulates sampling 
    process, estimates the number of packets and returns the result for max_iter 
    iterations"""
    mask = 2**digest_size - 1
    key = random.getrandbits(digest_size)
    threshold = int(sampling_probability * (mask+1))
    pkts = PcapReader(pcap)
    processed_packets = 0.
    sampled_pkts = 0.
    iters = 0
    results = []
    for pkt in pkts:
        if processed_packets >= num_packets:
            iters +=1
            estimation = sampled_pkts / sampling_probability
            result = (processed_packets, estimation, sampling_probability, 
                        digest_size)
            results.append(result)
            sampled_pkts = 0
            processed_packets = 0
        # Enough iterations?
        if iters >= max_iter:
            break
        # Process packet pkt:
        packet_hash = get_hash(pkt, key)
        if packet_hash is None: continue
        if packet_hash & mask < threshold:
            sampled_pkts += 1
        processed_packets += 1
    results_dtype = [ ('ProcessedPackets', 'float'), 
                      ('EstimatedPackets', 'float'),
                      ('SamplingProbability', 'float'), 
                      ('DigestSize', 'float')]
    return np.array(results, results_dtype)

def estimate_total_time(pcap, sampling_probability, digest_size, time_interval, 
                        max_iter=10):
    """Reads and estimates the number of packets for each interval of length 
    time_interval for the given pcap, the process is repeated max_iter 
    iterations and the results of the estimation is returned as result"""
    mask = 2**digest_size - 1
    key = random.getrandbits(digest_size)
    threshold = int(sampling_probability * (mask+1))
    pkts = PcapReader(pcap)
    start_time = pkts.next().time
    pkts.close()
    pkts = PcapReader(pcap)
    max_t = start_time + time_interval
    processed_packets = 0.
    results = []
    sampled_pkts = 0.
    iters = 0
    for pkt in pkts:
        # Check test condition
        if pkt.time>max_t:
            iters +=1
            estimation = sampled_pkts / sampling_probability
            result = (processed_packets, estimation, time_interval, 
                            sampling_probability, digest_size)
            results.append(result)
            sampled_pkts = 0
            processed_packets = 0
            # Update max_t
            while pkt.time>max_t:
                max_t += time_interval
        # Enough iterations?
        if iters >= max_iter:
            break
        # Process packet pkt:
        packet_hash = get_hash(pkt, key)
        if packet_hash is None: continue
        if packet_hash & mask < threshold:
            sampled_pkts += 1
        processed_packets += 1
    results_dtype = [ ('ProcessedPackets', 'float'), 
                      ('EstimatedPackets', 'float'),
                      ('TimeInterval', 'float'), 
                      ('SamplingProbability', 'float'), 
                      ('DigestSize', 'float')]
    return np.array(results, results_dtype)

def estimate_ratio(pcap, drop_probability, sampling_probability, digest_size, 
                    num_packets, is_random=True, max_iter=10):
    """Reads the pcap and simulates a node that receives the packets from the 
    pcap and drops packets with drop_probability. If is_random, the packets will
    be dropped deterministicly (the first ones of the interval), otherwise they
    will be dropped randomly. The process is repeated max_iter times and all the 
    estimated results are returned as result."""
    mask = 2**digest_size - 1
    key = random.getrandbits(digest_size)
    threshold = int(sampling_probability * (mask+1))
    pkts = PcapReader(pcap)
    sampled_in = 0
    sampled_out = 0
    input_packets = 0
    output_packets = 0
    results = []
    iters = 0
    for pkt in pkts:
        if input_packets >= num_packets:
            iters += 1
            estimated_in = sampled_in / sampling_probability
            estimated_out = sampled_out / sampling_probability
            result = (input_packets, output_packets, estimated_in-estimated_out, 
                        estimated_in, estimated_out, sampling_probability, 
                        drop_probability, digest_size)
            results.append(result)
            sampled_in = 0
            sampled_out = 0
            input_packets = 0
            output_packets = 0
        # Enough iterations?
        if iters >= max_iter:
            break
        # Sample packet
        packet_hash = get_hash(pkt, key)
        if packet_hash is None:
            continue
        if packet_hash & mask < threshold:
            sampled_in += 1
        input_packets += 1
        # Drop the packet?
        if not is_random:
            # Drop the first num_packets*drop_probability:
            if input_packets > num_packets*drop_probability:
                output_packets += 1
                if packet_hash & mask < threshold:
                    sampled_out += 1
        else:
            if random.random() > drop_probability:
                output_packets += 1
                if packet_hash & mask < threshold:
                    sampled_out += 1
    results_dtype = [ ('InputPackets', 'float'), 
                      ('OutputPackets', 'float'),
                      ('EstimatedDifference', 'float'), 
                      ('EstimatedInput', 'float'), 
                      ('EstimatedOutput', 'float'),
                      ('SamplingProbability', 'float'), 
                      ('DropProbability', 'float'),
                      ('DigestSize', 'float')]
    return np.array(results, results_dtype)


def estimate_ratio_time(pcap, drop_probability, sampling_probability, 
        digest_size, time_interval, max_iter=10):
    """Reads the pcap and simulates a node that receives the packets from the 
    pcap and drops packets with drop_probability. Packets are dropped randomly 
    with drop_probability, and each interval lasts time_interval."""
    mask = 2**digest_size - 1
    key = random.getrandbits(digest_size)
    threshold = int(sampling_probability * (mask+1))
    pkts = PcapReader(pcap)
    start_time = pkts.next().time
    pkts.close()
    pkts = PcapReader(pcap)
    max_t = start_time + time_interval
    sampled_in = 0
    sampled_out = 0
    input_packets = 0
    output_packets = 0
    results = []
    iters = 0
    for pkt in pkts:
        if pkt.time>max_t:
            iters += 1
            estimated_in = sampled_in / sampling_probability
            estimated_out = sampled_out / sampling_probability
            result = (input_packets, output_packets, estimated_in-estimated_out, 
                        estimated_in, estimated_out, time_interval, 
                        sampling_probability, drop_probability, digest_size)
            results.append(result)
            sampled_in = 0
            sampled_out = 0
            input_packets = 0
            output_packets = 0
            while pkt.time>max_t:
                max_t += time_interval
        # Enough iterations?
        if iters >= max_iter:
            break
        # Sample packet
        packet_hash = get_hash(pkt, key)
        if packet_hash is None:
            continue
        if packet_hash & mask < threshold:
            sampled_in += 1
        input_packets += 1
        # Drop the packet?
        if random.random() > drop_probability:
            output_packets += 1
            if packet_hash & mask < threshold:
                sampled_out += 1
    results_dtype = [ ('InputPackets', 'float'), 
                      ('OutputPackets', 'float'),
                      ('EstimatedDifference', 'float'), 
                      ('EstimatedInput', 'float'), 
                      ('EstimatedOutput', 'float'),
                      ('TimeInterval', 'float'), 
                      ('SamplingProbability', 'float'), 
                      ('DropProbability', 'float'),
                      ('DigestSize', 'float')]
    return np.array(results, results_dtype)

def stack(results, result):
    if results is None:
        return result
    else : 
        return np.hstack((results, result))

################################ Main ##########################################
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("id")
    parser.add_argument("pcap")

    parser.add_argument("--samplingProbability", type=lambda val: [float(val)],
        default=[0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.])
    parser.add_argument("--digestSize", default=64, type=int)
    parser.add_argument("--maxIter", default=100, type=int)
    parser.add_argument("--byTime", action="store_true")
    parser.add_argument("--interval", default=[0.1, 0.5, 1., 5., 10., 50., 100., 
                                                500., 1000., 5000.],
        type=lambda vals: [float(val) for val in vals.split(',')])
    parser.add_argument("--numPackets", default= [10,50,100,500,1000,5000,10000],
        type=lambda val: [int(val)])
    parser.add_argument("--ratio", action="store_true")
    parser.add_argument("--dropProbability", default= [0.05, 0.1, 0.2],
        type=lambda val: [float(val)])
    parser.add_argument("--random", action="store_true")
    args = parser.parse_args()
    if "equinix" in args.pcap:
        intervals = [ interval*.001 for interval in args.interval ]
    elif "anon" in args.pcap:
        intervals = [ interval*0.1 for interval in args.interval[0:4] ]
    else:
        intervals = args.interval[0:5]
    results = None
    for samplingProb in args.samplingProbability:
        if (args.byTime):
            for interval in intervals:
                if (args.ratio):
                    for dropProb in args.dropProbability:
                        results = stack(results, estimate_ratio_time(args.pcap, 
                            dropProb, samplingProb, args.digestSize, interval, 
                            args.maxIter))
                else:
                    results = stack(results, estimate_total_time(args.pcap, 
                        samplingProb, args.digestSize, interval, args.maxIter))
        else:
            for packets in args.numPackets:
                if (args.ratio):
                    for dropProb in args.dropProbability:
                        results = stack(results, estimate_ratio(args.pcap, 
                            dropProb, samplingProb, args.digestSize, packets, 
                            args.random, args.maxIter))
                else:
                    results = stack(results, estimate_total(args.pcap, 
                        samplingProb, args.digestSize, packets, args.maxIter))
    header = ','.join(results.dtype.names)
    np.savetxt('../results/sampling_%s.csv' % args.id, results, delimiter=',', 
        fmt="%s", header=header, comments="")


