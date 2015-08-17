# upload to baidu pcs
cd /opt/youtube/ && /usr/bin/python /opt/git/bypy.git/bypy.py syncup
# remove files created more than 7 days
find /opt/youtube/ -ctime +7 -exec rm -fr {} \; > /dev/null 2>&1
