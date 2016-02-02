---
layout: page
title: Estimating the ratio of different packets
exclude: true
---

We have [covered](../estimating-total) previously all the details about the factors that influence the accuracy of the sketches when estimating the total number of different packets between two traffic streams. However, in some situations we will be more interested in estimating the proportion of packets, rather than the absolute number, e.g. we may want to know what is probability that a packet traversing a network area will be dropped. In the general case we will not know the total number of packets that go through that network area, so estimating the probability will imply that we have to estimate the total number of packets that enter that network area and the difference between the packets that enter and leave it. Then, by dividing those two numbers we will obtain an estimate of the probability of dropping a packet. Because both estimations are correlated the results will be slightly different to the ones on the previous case.

## Experiments

In this case our experiments have an additional step, packets are read from a pcap file as before, but now we will emulate a network area that looses a certain proportion of the packets and generate two different sketches: one for the incoming traffic with all the packets and one for the outgoing traffic with only those packets that haven't been dropped. Then, we will estimate the number of packets on the sketch of the incoming traffic and the number of packets on the sketch resulting form subtracting the outgoing and incoming sketches. The variables considered in this case are:

* [Digest size](digest.html)
* [Pseudo-random function](random.html)
* [Drop probability](drop.html)
* [Number of packets](packets.html)
* [Number of columns](columns.html)
* [Number of rows](rows.html)
* [Time interval](time.html)

