---
layout: page
title: Scripts and code
exclude: true
---

This page describes the different pieces of code that make possible reproducing the results presented.

* __[Sketches library](http://github.com/esterl/sketches)__ : Is a collection of files that implement all the different sketches and their pseudo-random functions. They are available as a c++ library, as well as a python module.
* __[network_sketches.py](network_sketches.py)__ : Class that wraps over the sketches python module, so that it can be used for traffic validation, i.e. instead of updating the sketches with numbers, it reads a packet using scapy, generates a digest and then updates the sketch. Additionally, it implements a couple of functions: _test_ and _test\_base_ that are the core functions used on the experiments. They read a pcap file and simulate the estimation process with the given parameters.
* __[estimate-total.sh](estimate-total.sh)__ and __[estimate-ratio.sh](estimate-ratio.sh)__ run all the experiments for the estimation of the total number of dropped packets and the proportion respectively. They are based on the __[estimate-total.py](estimate-total.py)__ and __[estimate-ratio.py](estimate-ratio.py)__ files. The same can be said about __[sampling.sh](sampling.sh)__ and __[sampling.py](sampling.py)__, which reproduce the sampling experiments. Finally, __[utils.py](utils.py)__ has some auxiliary functions used by these _.py_ files.
* __[sketches_pmf.cpp](sketches_pmf.cpp)__ : Cpp code that computes the proposed probability mass functions for the sketches when used for traffic validation. 

Regarding the figures, we have also made available the code to reproduce them given the CSV files produced by the previous scripts.

* __[generate_total.R](generate_total.R)__  and __[generate_ratio.R](generate_ratio.R)__ generate all the figures presented on the reports, using the auxiliary files listed below.
* __[read_files.R](read_files.R)__ contains some auxiliary functions related to reading the CSV files.
* __[figures_total.R](figures_total.R)__ and __[figures_ratio.R](figures_ratio.R)__ have the function that create the ggplots for each figure.
* __[utils.R](utils.R)__ has some auxiliary functions that process the read data.frames.
* __[format.R](format.R)__ defines the format of the figures.
