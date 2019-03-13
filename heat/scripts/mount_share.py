#!/usr/bin/env python
import os
import json
import re
import requests
r = requests.get('http://169.254.169.254/openstack/latest/meta_data.json')
data = r.json()
m = re.search('\'(.+?)\'', data['meta']['share_export_loc_path'])
sharepath = m.group(1)
mountpoint = '/mnt/share'
os.mkdir(mountpoint)
os.chown(mountpoint,0,0)
os.system("mount %s %s" % (sharepath,mountpoint))

