#!/bin/bash
while true; do
    notangle -Rks.c ks.nw >ks.c
    notangle -Rimg.f img.nw >img.f
    sleep 2
done

