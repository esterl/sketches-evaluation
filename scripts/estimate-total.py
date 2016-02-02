from network_sketches import *
import numpy as np
from numpy.lib import recfunctions as rfn
import argparse
import socket
from utils import get_sketch

# Main
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("id")
    parser.add_argument("pcap")

    parser.add_argument("--sketchType", default=["AGMS", "FAGMS", "FastCount"], 
        type=lambda val: [val])
    parser.add_argument("--xiFunction", 
        default=["cw4", "cw2", "bch5", "bch3", "eh3"], type=lambda val: [val])
    parser.add_argument("--digestSize", default=[8, 16, 32, 64], 
        type=lambda val: [int(val)])
    parser.add_argument("--maxIter", default=100, type=int)
    parser.add_argument("--columns", default=[8,16,32,64,128,256,512,1024],
        type=lambda val: [int(val)])
    parser.add_argument("--rows", default=[1,2,4,8,16,32,48,64,96,128,192,256,384,512,768,1024], 
        type=lambda val: [int(val)])
    parser.add_argument("--numPackets", default= [5,10,50,100,500,1000,5000,10000],
        type=lambda val: [int(val)])
    parser.add_argument("--averageFunction", default=["mean", "trimmean", "median"],
        type=lambda val: [val])
    parser.add_argument("--hashFunction", default=["cw4", "cw2", "tab"], type=lambda val: [val])
    
    args = parser.parse_args()
    results = None
    for sketchType in args.sketchType:
        for columns in args.columns:
            for rows in args.rows:
                for packets in args.numPackets:
                    for digestSize in args.digestSize:
                        for averageFnc in args.averageFunction:
                            if sketchType == "AGMS":
                                randFunc = [ (xi, None) for xi in args.xiFunction ]
                            elif sketchType == "FAGMS":
                                randFunc = [ (xi, hash) for xi in args.xiFunction for hash in args.hashFunction ]
                            elif sketchType == "FastCount":
                                randFunc = [ (None, hash) for hash in args.hashFunction ]
                            else:
                                break
                            for (xi, hash) in randFunc:
                                sketch = get_sketch(sketchType, digestSize, columns, 
                                            rows, xi, averageFnc, hash)
                                net_sketch = NetworkSketch(sketch)
                                result = net_sketch.test_base(args.pcap, 
                                    max_iter=args.maxIter, num_packets=packets)
                                # Add additional fields
                                result = rfn.append_fields(result, names="Xi", 
                                    data=[xi]*len(result), usemask=False, 
                                    dtypes="|S8")
                                result = rfn.append_fields(result, names="SketchType", 
                                    data=[sketchType]*len(result), usemask=False,
                                    dtypes="|S16")
                                result = rfn.append_fields(result, names="DigestSize", 
                                    data=[digestSize]*len(result), usemask=False, 
                                    dtypes="float")
                                result = rfn.append_fields(result, names="AverageFunction", 
                                    data=[averageFnc]*len(result), usemask=False,
                                    dtypes="|S16")
                                result = rfn.append_fields(result, names="HashFunction", 
                                    data=[hash]*len(result), usemask=False,
                                    dtypes="|S16")
                                # Hostname for debugging
                                hostname = socket.gethostname()
                                result = rfn.append_fields(result, names="Hostname", 
                                    data=[hostname]*len(result), usemask=False,
                                    dtypes="|S16")
                                if results is None:
                                    results = result
                                else : 
                                    results = np.hstack((results, result))
    
    header = ','.join(results.dtype.names)
    np.savetxt('results/total_%s.csv' % args.id, results, delimiter=',', 
        fmt="%s", header=header, comments="")

