#youtube downloader#

A perl script to download videos according to urls in queue. Also videos could be sync up to baidu pcs automatically.

#files#

##downloadvideos_in_queue.pl##

main program

##log.conf##

store log4perl syslog configuration

##queue.ini##

store urls, script will read contents into db and set initial state.

##crontab##

crons should be added to crontab

##sync_to_baidupcs.sh##

script to sync videos into baidu pcs under dir /apps/bypy/
