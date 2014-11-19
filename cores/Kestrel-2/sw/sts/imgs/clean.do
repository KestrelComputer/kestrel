#!/bin/bash
for x in $(ls -1)
do
	rm -f ${x%.do}
done

