#!/bin/sh
# author: yangxiangxiao  time: 2013.10.19

cfgname=()
cfgvalue=()

#ctrl+c信号
trap "my_exit" 2
my_exit() 
{
	echo "you just hit ctrl+c"
	exit 1
}

function printsign(){
	b=''
	for ((i=1;$i<=72;i+=1)) do
	if [ ${#b} -eq 72 ]; then
	   b=''
	fi
	printf "progress:%-71s\r" $b
	 sleep 0.1
	 b=#$b
	done
	echo ''
}


function exebackup()
{
        flag=true
        while $flag
        do
           printsign 
        done &
        printflag=$!
        echo $printflag
	num=0
	for k in ${cfgname[@]}; do 
	  if [ $k = 'dir' -o $k = 'file' ]; then 
	    ((num++))
	  fi
	done
	((num--))
        len=${#cfgname[@]}
	((len--))
        BackupDes=${cfgvalue[$len]}
	BackupIp=${cfgvalue[0]}
	for n in `seq  1 $num`; do  
		BackupSou=${cfgvalue[$[n+1]]}
		rsync -av --progress root@${BackupIp}:${BackupSou} ${BackupDes} > /dev/null 
                if [ $? != 0 ]; then
                  TIME=`date +%Y%m%d-%H%M`
                  echo "${TIME}">>/root/Desktop/log.txt
                  echo "backup file and dir false" >> /root/Desktop/log.txt
                  exit 1
                else
                  flag=false                                     
                fi
	done 
        

        begin=$[num+2]
        MysqlIp=${cfgvalue[begin]}   
        ((begin++))
        MysqlUser=${cfgvalue[begin]}  
        ((begin++))
        MysqlPasswd=${cfgvalue[begin]}  
        ((begin++))
        ((len--))
        for m in `seq $begin $len`; do
#        	echo ${cfgvalue[m]}
                MysqlDB=${cfgvalue[m]}
		DB_TIME=`date +%Y%m%d-%H%M`
		NAME_1="$MysqlDB-$DB_TIME"
                mysqldump -u ${MysqlUser} -p${MysqlPasswd} -h ${MysqlIp} --database ${MysqlDB} > ${BackupDes}/${NAME_1}.sql 
                if [ $? != 0 ]; then
                   TIME=`date +%Y%m%d-%H%M`
                   echo "${TIME}">>/root/Desktop/log.txt
                   echo "backup database file false" >> /root/Desktop/log.txt
                   exit 1
                fi
        done 
        
        echo -e "\nbackup $cfgfile success\n"
        kill -9 $printflag 
} 
 
function readcfg()
{
                cfgname=()
		cfgvalue=()
                j=0
		exec < $cfgfile
		while read line
		do
			if [[ "$line" =~ ^[^#|^[]*= ]]; then
				cfgname[j]=`echo $line | awk -F '=' '{print $1}' | tr '\r' ' ' | grep -o "[^ ]\+\( \+[^ ]\+\)*"`
				cfgvalue[j]=`echo $line | awk -F '=' '{print $2}'| tr '\r' ' ' | grep -o "[^ ]\+\( \+[^ ]\+\)*"`
				((j++))
			fi
		done 
                echo -e "readcfg $cfgfile success\n"
} 

 
if [ $# -eq 0 ]; then
	cat << HELP
	help information
	USAGE: sh dd.sh all or sh dd.sh serviceA.cfg
HELP
	exit 0
elif [ $# -eq 1 -a $1 = 'all' ]; then
	echo "back up all file"
        find . -maxdepth 1 -name "*.cfg" -type f  | sed 's/^.\///' > tmp.txt  #sed 语句去除./
        kk=0
        exec <  tmp.txt
		while read line
		do
                          echo $line
                          jj[kk]=$line
                          ((kk++))
		done 
                
                for i in ${jj[@]}; do
                        echo -e "begin backup $i\n"
                        cfgfile=$i
                        readcfg
                        exebackup
                done
        rm -rf tmp.txt
	exit 0
else 
	for i in $*; do
		if [ -f $i -a -s $i ] && ls $i | grep '.cfg$' >/dev/null ; then
			echo -e "begin backup $i\n"
                        cfgfile=$i
                        readcfg
                        exebackup
		else
			echo "no such file $i or file type error"
			exit 0
		fi
	done
fi   
 
