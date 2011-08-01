#!/bin/bash
while true; do
    noweave -index -html ks.nw >ks.html
    noweave -index -html img.nw >img.html
    noweave -index -html asm.nw >asm.html
    sleep 5
done

