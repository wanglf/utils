echo "------------------------------------------------------------"
echo "`date` - start executing syncup_to_baidupcs.sh"
echo "------------------------------------------------------------"
# move downloaded file to /opt/baidupcs
find /opt/youtube/ -name "*.mp4" -exec mv {} /opt/baidupcs/ \;
# upload to baidu pcs
cd /opt/baidupcs/ && /usr/bin/python /opt/git/bypy.git/bypy.py syncup
# remove files created more than 7 days
find /opt/baidupcs/ -ctime +7 -exec rm -fr {} \; > /dev/null 2>&1
echo "------------------------------------------------------------"
echo "`date` - finish executing syncup_to_baidupcs.sh"
echo "------------------------------------------------------------"
