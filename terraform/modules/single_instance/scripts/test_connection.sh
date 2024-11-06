#!/bin/bash
SECONDS=0
until [ "$(cloud-init status)" = 'status: done' ] ;do 
if [ $SECONDS -gt 300 ]; then exit 1; fi
sleep 5
done