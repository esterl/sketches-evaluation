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
  parser.add_argument("--numPackets", default= [10,20,30,50,100,500,1000,5000,1e4,1e5],
      type=lambda val: [int(val)])
  parser.add_argument("--averageFunction", default=["mean", "trimmean", "median"],
      type=lambda val: [val])
  parser.add_argument("--hashFunction", default=["cw4", "cw2", "tab"], type=lambda val: [val])
  parser.add_argument("--dropProbability", default = [1e-4, 1e-3, 1e-2, 0.1, 
                                                      0.2, 0.3, 0.4, 0.5, 
                                                      0.6, 0.7, 0.8, 0.9], 
      type=lambda val: [float(val)])
  parser.add_argument("--byInterval", action="store_true")
  parser.add_argument("--interval", default=[0.1, 0.5, 1., 5., 10., 50., 100., 
                                              500., 1000., 5000], 
      type=lambda vals: [float(val) for val in vals.split(',')])
  parser.add_argument("--squareSketch", action="store_true")
  args = parser.parse_args()
  if "equinix" in args.pcap:
      intervals = [ interval*.001 for interval in args.interval ]
  elif "anon" in args.pcap:
      intervals = [ interval*0.1 for interval in args.interval[0:4] ]
      args.maxIter = float("inf")
  else:
      intervals = args.interval[0:5]
      args.maxIter = float("inf")
  
  results = None
  # Prepare all the permutations to run:
  if args.byInterval:
      permutations = [ (t, c, r, None, l, a, d, i)
                          for t in args.sketchType
                          for c in args.columns
                          for r in args.rows
                          for a in args.averageFunction
                          for l in args.digestSize
                          for d in args.dropProbability
                          for i in intervals ]
  else:
      permutations = [ (t, c, r, p, l, a, d, None)
                          for t in args.sketchType
                          for c in args.columns
                          for p in args.numPackets
                          for r in args.rows
                          for a in args.averageFunction
                          for l in args.digestSize
                          for d in args.dropProbability ]
  # Run the experiments
  i = 0
  total = len(permutations)
  for (sketchType, columns, rows, packets, digestSize, 
        averageFnc, dropProb, interval) in permutations:
    print("%d/%d" % (i,total))
    i += 1
    if sketchType == "AGMS":
        randFunc = [ (xi, None) for xi in args.xiFunction ]
    elif sketchType == "FAGMS":
        randFunc = [ (xi, hash) for xi in args.xiFunction 
                                for hash in args.hashFunction ]
    elif sketchType == "FastCount":
        randFunc = [ (None, hash) for hash in args.hashFunction ]
    else:
        break
    for (xi, hash) in randFunc:
        if args.squareSketch:
            if columns != rows: continue
        sketch = get_sketch(sketchType, digestSize, columns, 
                    rows, xi, averageFnc, hash)
        net_sketch = NetworkSketch(sketch)
        if args.byInterval :
            result = net_sketch.test(args.pcap, dropProb, 
                is_random=True, time_interval=interval, 
                max_iter=args.maxIter)
        else :
            result = net_sketch.test(args.pcap, dropProb, 
                is_random=False, num_packets=packets, 
                max_iter=args.maxIter)
        # Add additional fields
        result = rfn.append_fields(result, names="XiFunction", 
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
        result = rfn.append_fields(result, names="DropProbability",
            data=[dropProb]*len(result), usemask=False,
            dtypes="float")
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
  np.savetxt('results/ratio_%s.csv' % args.id, results, delimiter=',', 
      fmt="%s", header=header, comments="")

