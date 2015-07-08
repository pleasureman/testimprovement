#!/bin/bash
set -e

export time_stamp=`date '+%Y_%m_%d_%H_%M_%S'`
TMP=/tmp/patch`whoami`/${time_stamp}
mkdir -p $TMP
#TMP=`mktemp -d`

echo TMP=$TMP
#REPORT=$TMP/report_debug.html
REPORT=$TMP/report.html
TOPDIR=`dirname $0`
cd $TOPDIR;
TOPDIR=`pwd`/community
echo "TOPDIR= $TOPDIR"
otherparameter="--since 2015-1-1"
mkdir -p $TOPDIR
#TOPDIR=/root/patch/community/
#communitylist="ltp libnetwork libcontainer"
communitylist="kernel docker libcontainer ltp distribution libnetwork oe-core machine meta-oe kpatch logrus coder mcelog"

for i in $communitylist
do
	echo "checking $i community"
	if [ -e ${TOPDIR}/$i ];then
		cd ${TOPDIR}/$i
	else
		cd ${TOPDIR};
		echo "start to clone $i community"
		case $i in
		"libcontainer" ) repo="https://github.com/docker/libcontainer.git";;
		"docker" ) repo="https://github.com/docker/docker.git";;
		"compose" ) repo="https://github.com/docker/compose.git";;
		"docker-registry" ) repo="https://github.com/docker/docker-registry.git";;
		"libnetwork" ) repo="https://github.com/docker/libnetwork.git";;
		"lxc" ) repo="https://github.com/lxc/lxc.git";;
		"oe-core" ) repo="https://github.com/openembedded/oe-core.git";;
		"machine" ) repo="https://github.com/docker/machine.git";;
		"meta-oe" ) repo="https://github.com/openembedded/meta-oe.git";;
		"crash" ) repo="https://github.com/crash-utility/crash.git";;
		"kexec-tools" ) repo="https://git.kernel.org/pub/scm/utils/kernel/kexec/kexec-tools.git";;
		"kernel" ) repo="https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git";;
		"distribution" ) repo="https://github.com/docker/distribution.git";;
		"kpatch" ) repo="https://github.com/dynup/kpatch";;
		"logrus" ) repo="https://github.com/Sirupsen/logrus.git";;
		"code" ) repo="http://git.code.sf.net/p/makedumpfile/code";;
		"rasdaemon" ) repo="https://git.fedorahosted.org/git/rasdaemon.git";;
		"ltp" ) repo="https://github.com/linux-test-project/ltp";;
		"mcelog" ) repo="https://git.kernel.org/pub/scm/utils/cpu/mce/mcelog.git";;
		#* ) echo "not exist $i repo";exit 1;;
		esac
		git clone ${repo}  $i
		cd ${TOPDIR}/$i
	fi
	#git log --since 2015-1-1 | grep ^Author: | grep "@huawei.com" | awk '{print $NF}' | sed 's/^<//g' | sed 's/>$//g' | grep -v ^$ | grep -v "\?" > ${TMP}/${i}_authors
	echo "git pull $i repo"
	git pull && git log ${otherparameter} | grep ^Author: | grep "@huawei.com" | awk '{print $NF}' | sed 's/^<//g' | sed 's/>$//g' | grep -v ^$ | grep -v "\?" > ${TMP}/${i}_authors
	echo "sort $i data"
	sort ${TMP}/${i}_authors | uniq > ${TMP}/${i}_authorlist

	while read line; 
	do
		echo -n "$line  " >> ${TMP}/${i}_authorinfo; 
		echo `grep $line ${TMP}/${i}_authors | wc -l` >> ${TMP}/${i}_authorinfo; 
	done < ${TMP}/${i}_authorlist

	#sort -n -r  -k2 ${TMP}/authorinfo > ${TMP}/authorinfo_sorted
	sort -n -r  -k2 ${TMP}/${i}_authorinfo | grep "@huawei.com" > ${TMP}/${i}_authorinfosorted

	echo "cd $TMP"
	echo "cat ${TMP}/${i}_authorinfosorted"
	echo "--------------------------------"
done

sort ${TMP}/*_authorlist | uniq > ${TMP}/all_authorlist

while read line; 
do
	total=`grep $line ${TMP}/*_authors | wc -l`

	personal_tmp=""
	for i in $communitylist
	do
		tmp=`grep $line ${TMP}/${i}_authors | wc -l`
		personal_tmp="${personal_tmp} $tmp"
	done
	echo  "$line ${total} ${personal_tmp}" >> ${TMP}/all_authorinfo;
done < ${TMP}/all_authorlist

	sort -n -r  -k2 ${TMP}/all_authorinfo > ${TMP}/all_authorinfosorted


echo "<style type="text/css">" >> ${REPORT}
echo "table {" >> ${REPORT}
echo "margin: 1em 1em 1em 0;" >> ${REPORT}
echo "background: #f9f9f9;" >> ${REPORT}
echo "border: 1px #aaaaaa solid;" >> ${REPORT}
echo "border-collapse: collapse;" >> ${REPORT}
echo "}" >> ${REPORT}
echo "table th, table td {" >> ${REPORT}
echo "border: 1px #aaaaaa solid;" >> ${REPORT}
echo "padding: 0.2em;" >> ${REPORT}
echo "}" >> ${REPORT}
echo "</style>" >> ${REPORT}

echo "Updated time: `date '+%Y/%m/%d %H:%M:%S'`        admin: sunyuan3@huawei.com" >> ${REPORT}

echo "<p><table>" >> ${REPORT}
echo "<tr>" >> ${REPORT}
echo "  <th align=center><div style=\"width:30px;\">num</th>" >> ${REPORT}
echo "  <th align=center><div style=\"width:150px;\">author</th>" >> ${REPORT}
echo "  <th align=center><div style=\"width:30px;\">all</th>" >> ${REPORT}
for i in $communitylist
do
	charnum=`echo $i | wc -c`
	wid=$(($charnum*8))
	if [ $wid -le 30 ];then
		wid=30
	fi
	
	#echo "  <th align=center><div style=\"width:100px;\">$i</th>" >> ${REPORT}
	echo "  <th align=center><div style=\"width:${wid}px;\">$i</th>" >> ${REPORT}
done
echo "</tr>" >> ${REPORT}


# total quantity
allpatchquantity=`cat ${TMP}/*_authors | wc -l`
echo "<tr>" >> ${REPORT}
echo "<td align=center><b> </b></td>" >> ${REPORT}
echo "<td align=center><b>all</b></td>" >> ${REPORT}
echo "<td align=center><b>${allpatchquantity}</b></td>" >> ${REPORT}

for j in $communitylist
do
	content=`cat ${TMP}/${j}_authors | wc -l`
	if [ $content -eq 0 ];then
		echo "<td align=center><b><tt><font color=gray>$content</tt></b></td>" >> ${REPORT}
	else
		echo "<td align=center><b><tt><font color=blue>$content</tt></b></td>" >> ${REPORT}
	fi
	k=`expr $k + 1`
done
echo "</tr>" >> ${REPORT}





num=1
#column_num=
while read line; 
do
        author=`echo $line | awk '{print $1}'`
        #patchquantity=`echo $line | awk '{print $2}'`
        allpatchquantity=`echo $line | awk '{print $2}'`
	echo "<tr>" >> ${REPORT}
	echo "<td align=center><b>${num}</b></td>" >> ${REPORT}
	echo "<td align=center><b>${author}</b></td>" >> ${REPORT}
	echo "<td align=center><b>${allpatchquantity}</b></td>" >> ${REPORT}

	#echo "<td align=center><b>`echo $line | awk '{print $3}'`</b></td>" >> ${REPORT}
	#echo "<td align=center><b>`echo $line | awk '{print $21}'`</b></td>" >> ${REPORT}
	#echo "<td align=left><tt><font color="#00dd00">patchquantity</tt></td>" >> ${REPORT}
	#echo "<td align=left><tt><font color="#00dd00">${patchquantity}</tt></td>" >> ${REPORT}
	k=3
	for j in $communitylist
	do
		#echo "andy.wangguoli@huawei.com 1  0 9 1" | awk '{print $u}' u="$u"
		content=`echo $line | awk '{print $k}' k=$k`
	#	echo "cmd: echo $line | awk '{print $k}'"
	#	echo "line=$line ;k=$k; content=$content"
		if [ $content -eq 0 ];then
			echo "<td align=center><b><tt><font color=gray>$content</tt></b></td>" >> ${REPORT}
		else
			echo "<td align=center><b><tt><font color=blue>$content</tt></b></td>" >> ${REPORT}
		fi
		k=`expr $k + 1`
	done

	echo "</tr>" >> ${REPORT}
	num=`expr $num + 1`
done < ${TMP}/all_authorinfosorted

cp ${REPORT} /var/www/html/
