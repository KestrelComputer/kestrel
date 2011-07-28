#!/bin/bash
while true; do
    noweave -index -html ks.nw >ks.html
    noweave -index -html img.nw >img.html
    sleep 2
done

