#!/bin/bash

br=$(brightnessctl | awk -F'[()%]' '/Current brightness/ {print $2}')
echo " ${br}%"



