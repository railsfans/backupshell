#!/bin/bash
#========================
# 您可以安排 cron 任务执行本脚本
# > crontab -e
#
# daily : 1 1 * * * /path/to/script/rsync-backup.sh
#========================
mydate=`date +%Y%m%d.%H%M`

# Define rmt location
RmtUser="root"
RmtHost="192.168.1.13"
RmtPath="/root/Desktop/backuptest"
#BackupSource="${RmtUser}@${RmtHost}:${RmtPath}"
BackupSource="${RmtUser}@${RmtHost}::chapter2"
#BackupSource="/home/"             # 若进行本地备份则用本地路径替换上面的行
# Define location of backup
BackupRoot="/root/backups/$RmtHost/"
# BackupRoot="/backups/localhost/" # 若进行本地备份则用本地路径替换上面的行
LogFile="${BackupRoot}/backup.log"
ExcludeList="/root/backup/exclude.list"
BackupName='home'
BackupNum="7"                      # 指定保留多少个增量备份（适用于每周生成归档文件）
#BackupNum="31"                    # 指定保留多少个增量备份（适用于每月生成归档文件）

# 定义函数检查目录 $1 是否存在，若不存在创建之
checkDir() {
    if [ ! -d "${BackupRoot}/$1" ] ; then
        mkdir -p "${BackupRoot}/$1"
    fi
}
# 定义函数实现目录滚动
# $1 -> 备份路径
# $2 -> 备份名称
# $3 -> 增量备份的数量
rotateDir() {
    for i in `seq 1 $3`; do
     a[10-i]=$i
    done
    for i in ${a[*]}; do
        if [ -d "$1/$2.$i" ] ; then
            rm -rf "$1/$2.$((i + 1))"
            mv "$1/$2.$i" "$1/$2.$((i + 1))"
        fi
    done
}

# 调用函数 checkDir ，确保目录存在
checkDir "archive"
checkDir "daily"

#======= Backup Begin =================
# S1: Rotate daily.
rotateDir "${BackupRoot}/daily" "$BackupName" "$BackupNum"

checkDir "daily/${BackupName}.0/"
checkDir "daily/${BackupName}.1/"
echo "Here we go again"

cat >> ${LogFile} <<_EOF
===========================================
    Backup done on: $mydate
===========================================
_EOF


# S2: Do the backup and save difference in ${BackupName}.1
rsync -av --delete \
    -b --backup-dir=${BackupRoot}/daily/${BackupName}.1 \
    --exclude-from=${ExcludeList} \
    $BackupSource ${BackupRoot}/daily/${BackupName}.0 \
    1>>${LogFile} 2>&1

cp  ${LogFile} ${BackupRoot}/daily/${BackupName}.1/


# S3: Create an archive backup every week
if [ `date +%w` == "0" ] # 每周日做归档
# if [ `date +%d` == "01" ] # 每月1日做归档
then
    tar -cjf ${BackupRoot}/archive/${BackupName}-${mydate}.tar.bz2 \
      -C ${BackupRoot}/daily/${BackupName}.0 .
fi
