MY_USER="root"
MY_PASS="28362"
MY_HOST="192.168.1.40"
MY_CONN="-u $MY_USER -p$MY_PASS -h $MY_HOST"
MY_DB1="test"
MY_DB2="test1"
BF_DIR="/root"
BF_CMD="mysqldump"
BF_TIME=`date +%Y%m%d-%H%M`
NAME_1="$MY_DB1-$BF_TIME"
NAME_2="$MY_DB2-$BF_TIME" 
cd $BF_DIR/
tar zcf $NAME_1.tar.gz $NAME_1.sql --remove &>/dev/null
rsync -ave root@192.168.1.40:/root/Desktop/backuptest /root/backup

