#!/bin/bash

startcommit=$1
endcommit=$2
commitfile=$3
exp=$4
echo "startcommit=${startcommit} endcommit=${endcommit}"

#commitarray[3]=1 #0 true 1 error
#commitarray[4]=1

startcommitnum=`grep -n -x ${startcommit} ${commitfile} | awk -F: '{print $1}'`
endcommitnum=`grep -n -x ${endcommit} ${commitfile} | awk -F: '{print $1}'`
echo "startcommitnum=${startcommitnum} endcommitnum=${endcommitnum}"

function testbenchmark()
{
	#exp=17
	echo "t:$1"
	if [ $1 -le ${exp} ];then
		commitarray[$1]=1
		num=`expr $1 + 1`
		#echo tmp1=$tmp1
		tmp=${commitarray[$num]}
		#echo tmp=$tmp
		if [ ${tmp}a == "0a" ];then
			echo rrrrrrrr $1
			exit 0
		fi

		return 1 #error
	else
		commitarray[$1]=0
		#num=`expr $1 - 1`
		#num=3
		#echo tttttttttttttt  $1
		num=`expr $1 - 1`
		#echo ttttttt
		tmp=${commitarray[$num]}
		if [ ${tmp}a == "1a" ];then
			echo rrrrrrrr $num
			exit 0
		fi
		return 0 #good
	fi
}

function dic()
{
	local startnum=$1
	local endnum=$2
	local totalnum=`expr $1 + $2`
	local mednum=`expr ${totalnum} / 2`
	#echo startnum=$startnum endnum=$endnum mednum=${mednum}
	if [ `expr $endnum - $startnum` -eq 1 ];then
		testbenchmark $startnum
		if [ $? -eq 0 ];then
			return
		else
			testbenchmark $endnum
			return
		fi
	fi
	testbenchmark $mednum	
	ret=$?

	if [ $ret -eq 0 ];then
		dic $startnum `expr $mednum - 1`
	elif [ $ret -eq 1 ];then #$1 -lt ${exp}
		dic `expr $mednum + 1` $endnum
	fi

}

dic ${startcommitnum} ${endcommitnum}
