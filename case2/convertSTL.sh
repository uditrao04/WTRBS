#!/bin/bash
# This file creates new files after transforming them into new positions/angles.
# 'O' means 'At Origin'

cd constant/triSurface/ || exit
for i in *.STL
do
	mv "$i" "${i%.STL}".obj
	mv "${i%.STL}".obj "${i%.STL}".stl
done
