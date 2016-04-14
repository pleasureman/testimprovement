#!/bin/bash
set -e

export time_stamp=`date '+%Y_%m_%d_%H_%M_%S'`
TMP=/home/weiyan/improve_`whoami`/${time_stamp}
mkdir -p $TMP
#TMP=`mktemp -d`

echo TMP=$TMP
#REPORT=$TMP/report_debug.html

REPORT=$TMP/company.html
TOPDIR=`dirname $0`
cd $TOPDIR
TOPDIR=`pwd`/community
echo "TOPDIR= $TOPDIR"
otherparameter="--since 2015-1-1 --until 2015-12-31"
mkdir -p $TOPDIR
#TOPDIR=/root/patch/community/
#communitylist="ltp libnetwork libcontainer"
communitylist="kernel docker"

for i in $communitylist
do
	echo "checking $i community"
	if [ -e ${TOPDIR}/$i ];then
		cd ${TOPDIR}/$i
	else
		cd ${TOPDIR};
		echo "start to clone $i community"
		case $i in
		#"libcontainer" ) repo="https://github.com/docker/libcontainer.git";;
		"docker" ) repo="https://github.com/docker/docker.git";;
		"kernel" ) repo="https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git";;
		esac
		git clone ${repo}  $i
		cd ${TOPDIR}/$i
	fi
	echo "git pull $i repo"
	touch ${TMP}/${i}_authors
	git pull 
	git log ${otherparameter} | grep ^Author: | awk '{print $NF}' | sed 's/^<//g' | sed 's/>$//g' > ${TMP}/${i}_authors || echo error1
	
	git log ${otherparameter} | grep ^Author: | awk '{print $NF}' | sed 's/^<//g' | sed 's/>$//g' | awk -F "@" '{print $2}' | sed '/^$/d' > ${TMP}/${i}_company

	if [ $i = "kernel" ]; then
		for j in arm google huawei ibm intel oracle redhat samsung suse ti
		do
			number=`cat ${TMP}/${i}_company | grep "$j" | wc -l`
			echo "$j  $number" >>${TMP}/${i}_companyinfo
		done
	else
		for j in docker fujitsu google huawei ibm microsoft oracle rancher redhat suse 
		do
			number=`cat ${TMP}/${i}_company | grep "$j" | wc -l`
			echo "$j  $number" >>${TMP}/${i}_companyinfo
		done
	fi

	sort -n -r -k2 ${TMP}/${i}_companyinfo > ${TMP}/${i}_companyinfosorted || touch ${TMP}/${i}_companyinfosorted



	total=`git log ${otherparameter} | grep ^Author: | awk '{print $NF}' | sed 's/^<//g' | sed 's/>$//g' | wc -l`
	sum=0
	rate=0
	while read line
	do
		num=`echo $line | awk '{print $2}'`
		sum=`expr $sum + $num`
		proportion=`expr $num \* 10000 / $total`
		proportion=$(printf "%.2f" `echo "$proportion/100" | bc -l`)
		rate=$(printf "%.2f" `echo "$rate+$proportion" | bc -l`)
		echo -n "$line  " >>${TMP}/${i}_companyfinal || touch ${TMP}/${i}_companyfinal
		echo "$proportion" >>${TMP}/${i}_companyfinal || touch ${TMP}/${i}_companyfinal
	done < ${TMP}/${i}_companyinfosorted
	others_sum=`expr $total - $sum`
	others_proportion=`expr $others_sum \* 10000 / $total`
	others_proportion=$(printf "%.2f" `echo "100-$rate" | bc -l`)
	#others_propor="`expr $others_propor / 100`.`expr $others_propor % 100`"
	echo "others  $others_sum  $others_proportion" >>${TMP}/${i}_companyfinal || touch ${TMP}/${i}_companyfinal

	echo "cd $TMP"
	echo "cat ${TMP}/${i}_companyfinal"
	echo "--------------------------------"
done

echo "<!DOCTYPE HTML>" >> ${REPORT}
echo "<html>" >> ${REPORT}
echo "<head>" >> ${REPORT}
echo "  <script type=\"text/javascript\">" >> ${REPORT}
echo "  window.onload = function () {" >> ${REPORT}
echo "    var chart1 = new CanvasJS.Chart(\"chart1Container\"," >> ${REPORT}
echo "    {" >> ${REPORT}
echo "      title:{" >> ${REPORT}
echo "        text: \"Kernel Community Engagement\"" >> ${REPORT}
echo "      }," >> ${REPORT}
echo "      animationEnabled: true," >> ${REPORT}
echo "      axisY:{" >> ${REPORT}
echo "        title: \"Patch Number\"" >> ${REPORT}
echo "      }," >> ${REPORT}
echo "      legend:{" >> ${REPORT}
echo "        verticalAlign: \"bottom\"," >> ${REPORT}
echo "        horizontalAlign: \"center\"" >> ${REPORT}
echo "      }," >> ${REPORT}
echo "      theme: \"theme2\"," >> ${REPORT}
echo "      data: [" >> ${REPORT}
echo "      {" >> ${REPORT}
echo "        type: \"column\"," >> ${REPORT}
echo "        showInLegend: true," >> ${REPORT}
echo "        legendMarkerColor: \"grey\"," >> ${REPORT}
echo "        legendText: \"companies\"," >> ${REPORT}
echo "        dataPoints: [" >> ${REPORT}
lin=0
while read line
do
	lin=$(($lin+1))
	company=`echo $line | awk '{print $1}'`
	patch_num=`echo $line | awk '{print $2}'`
	if [ $lin -eq 10 ]
	then
		echo "        {y: ${patch_num}, label: \"$company\"}" >> ${REPORT}
	elif [ $lin -ne 11 ]; then
		echo "        {y: ${patch_num}, label: \"$company\"}," >> ${REPORT}
	fi
done < ${TMP}/kernel_companyfinal
echo "        ]" >> ${REPORT}
echo "      }" >> ${REPORT}
echo "      ]" >> ${REPORT}
echo "    });" >> ${REPORT}
echo "    chart1.render();" >> ${REPORT}

echo "    var chart2 = new CanvasJS.Chart(\"chart2Container\"," >> ${REPORT}
echo "    {" >> ${REPORT}
echo "      title:{" >> ${REPORT}
echo "        text: \"Kernel Community Engagement\"" >> ${REPORT}
echo "      }," >> ${REPORT}
echo "      animationEnabled: true," >> ${REPORT}
echo "      legend:{" >> ${REPORT}
echo "        verticalAlign: \"center\"," >> ${REPORT}
echo "        horizontalAlign: \"right\"," >> ${REPORT}
echo "        fontSize: 20," >> ${REPORT}
echo "        fontFamily: \"Helvetica\"" >> ${REPORT}
echo "      }," >> ${REPORT}
echo "      theme: \"theme2\"," >> ${REPORT}
echo "      data: [" >> ${REPORT}
echo "      {" >> ${REPORT}
echo "        type: \"pie\"," >> ${REPORT}
echo "        indexLabelFontFamily: \"Garamond\"," >> ${REPORT}
echo "        indexLabelFontSize: 20," >> ${REPORT}
echo "        indexLabel: \"{label} {y}%\"," >> ${REPORT}
echo "        startAngle:-20," >> ${REPORT}
echo "        showInLegend: true," >> ${REPORT}
echo "        toolTipContent:\"{legendText} {y}%\"," >> ${REPORT}
echo "        dataPoints: [" >> ${REPORT}
lin=0
while read line
do
	lin=$(($lin+1))
	company=`echo $line | awk '{print $1}'`
	proportion=`echo $line | awk '{print $3}'`
	if [ $lin -eq 11 ]
	then
		echo "        {  y: $proportion, legendText:\"$company\", label: \"$company\"}" >> ${REPORT}
	else
		echo "        {  y: $proportion, legendText:\"$company\", label: \"$company\"}," >> ${REPORT}
	fi
done < ${TMP}/kernel_companyfinal
echo "        ]" >> ${REPORT}
echo "      }" >> ${REPORT}
echo "      ]" >> ${REPORT}
echo "    });" >> ${REPORT}
echo "    chart2.render();" >> ${REPORT}


echo "    var chart3 = new CanvasJS.Chart(\"chart3Container\"," >> ${REPORT}
echo "    {" >> ${REPORT}
echo "      title:{" >> ${REPORT}
echo "        text: \"Docker Community Engagement\"" >> ${REPORT}
echo "      }," >> ${REPORT}
echo "      animationEnabled: true," >> ${REPORT}
echo "      axisY:{" >> ${REPORT}
echo "        title: \"Patch Number\"" >> ${REPORT}
echo "      }," >> ${REPORT}
echo "      legend:{" >> ${REPORT}
echo "        verticalAlign: \"bottom\"," >> ${REPORT}
echo "        horizontalAlign: \"center\"" >> ${REPORT}
echo "      }," >> ${REPORT}
echo "      theme: \"theme2\"," >> ${REPORT}
echo "      data: [" >> ${REPORT}
echo "      {" >> ${REPORT}
echo "        type: \"column\"," >> ${REPORT}
echo "        showInLegend: true," >> ${REPORT}
echo "        legendMarkerColor: \"grey\"," >> ${REPORT}
echo "        legendText: \"companies\"," >> ${REPORT}
echo "        dataPoints: [" >> ${REPORT}
lin=0
while read line
do
	lin=$(($lin+1))
	company=`echo $line | awk '{print $1}'`
	patch_num=`echo $line | awk '{print $2}'`
	if [ $lin -eq 10 ]
	then
		echo "        {y: ${patch_num}, label: \"$company\"}" >> ${REPORT}
	elif [ $lin -ne 11 ]; then
		echo "        {y: ${patch_num}, label: \"$company\"}," >> ${REPORT}
	fi
done < ${TMP}/docker_companyfinal
echo "        ]" >> ${REPORT}
echo "      }" >> ${REPORT}
echo "      ]" >> ${REPORT}
echo "    });" >> ${REPORT}
echo "    chart3.render();" >> ${REPORT}

echo "    var chart4 = new CanvasJS.Chart(\"chart4Container\"," >> ${REPORT}
echo "    {" >> ${REPORT}
echo "      title:{" >> ${REPORT}
echo "        text: \"Docker Community Engagement\"" >> ${REPORT}
echo "      }," >> ${REPORT}
echo "      animationEnabled: true," >> ${REPORT}
echo "      legend:{" >> ${REPORT}
echo "        verticalAlign: \"center\"," >> ${REPORT}
echo "        horizontalAlign: \"right\"," >> ${REPORT}
echo "        fontSize: 20," >> ${REPORT}
echo "        fontFamily: \"Helvetica\"" >> ${REPORT}
echo "      }," >> ${REPORT}
echo "      theme: \"theme2\"," >> ${REPORT}
echo "      data: [" >> ${REPORT}
echo "      {" >> ${REPORT}
echo "        type: \"pie\"," >> ${REPORT}
echo "        indexLabelFontFamily: \"Garamond\"," >> ${REPORT}
echo "        indexLabelFontSize: 20," >> ${REPORT}
echo "        indexLabel: \"{label} {y}%\"," >> ${REPORT}
echo "        startAngle:-20," >> ${REPORT}
echo "        showInLegend: true," >> ${REPORT}
echo "        toolTipContent:\"{legendText} {y}%\"," >> ${REPORT}
echo "        dataPoints: [" >> ${REPORT}
lin=0
while read line
do
        lin=$(($lin+1))
        company=`echo $line | awk '{print $1}'`
        proportion=`echo $line | awk '{print $3}'`
        if [ $lin -eq 11 ]
        then
		echo "        {  y: $proportion, legendText:\"$company\", label: \"$company\"}" >> ${REPORT}
	else
	        echo "        {  y: $proportion, legendText:\"$company\", label: \"$company\"}," >> ${REPORT}
	fi
done < ${TMP}/docker_companyfinal
echo "        ]" >> ${REPORT}
echo "      }" >> ${REPORT}
echo "      ]" >> ${REPORT}
echo "    });" >> ${REPORT}
echo "    chart4.render();" >> ${REPORT}


echo "  }" >> ${REPORT}
echo "</script>" >> ${REPORT}
echo "<script type=\"text/javascript\" src=\"canvasjs.min.js\"></script>" >> ${REPORT}
echo "</head>" >> ${REPORT}
echo "<body>" >> ${REPORT}
echo "  <div id=\"chart1Container\" style=\"margin-top: 10px; margin-left: 10px; height:300px; width:50%;\">" >> ${REPORT}
echo "  </div>" >> ${REPORT}
echo "  <div id=\"chart2Container\" style=\"margin-top: -300px; margin-left: 850px; height:300px; width:50%;\">" >> ${REPORT}
echo "  </div>" >> ${REPORT}
echo "  <div id=\"chart3Container\" style=\"margin-top: 30px; margin-left: 10px; height:300px; width:50%;\">" >> ${REPORT}
echo "  </div>" >> ${REPORT}
echo "  <div id=\"chart4Container\" style=\"margin-top: -300px; margin-left: 850px; height:300px; width:50%;\">" >> ${REPORT}
echo "  </div>" >> ${REPORT}
echo "</body>" >> ${REPORT}
echo "</html>" >> ${REPORT}


echo "<style type=\"text/css\">" >> ${REPORT}
echo "table {" >> ${REPORT}
echo "margin: 310px 1em 1em 0;" >> ${REPORT}
echo "background: #f9f9f9;" >> ${REPORT}
echo "border: 1px #aaaaaa solid;" >> ${REPORT}
echo "border-collapse: collapse;" >> ${REPORT}
echo "}" >> ${REPORT}
echo "table th, table td {" >> ${REPORT}
echo "border: 1px #aaaaaa solid;" >> ${REPORT}
echo "padding: 0.2em;" >> ${REPORT}
echo "}" >> ${REPORT}
echo "</style>" >> ${REPORT}
echo "<p><table>" >> ${REPORT}
echo "<caption>Kernel</caption>" >> ${REPORT}
echo "<tr>" >> ${REPORT}
echo "  <th align=center><div style=\"width:30px;\">num</th>" >> ${REPORT}
echo "  <th align=center><div style=\"width:150px;\">company</th>" >> ${REPORT}
echo "  <th align=center><div style=\"width:100px;\">patch_num</th>" >> ${REPORT}
echo "  <th align=center><div style=\"width:100px;\">proportion</th>" >> ${REPORT}
echo "</tr>" >> ${REPORT}

num=1
#column_num=
while read line
do
	company=`echo $line | awk '{print $1}'`
	patch_num=`echo $line | awk '{print $2}'`
	proportion=`echo $line | awk '{print $3}'`
	echo "<tr>" >> ${REPORT}
	echo "<td align=center><b>${num}</b></td>" >> ${REPORT}
	echo "<td align=center><b>${company}</b></td>" >> ${REPORT}
	echo "<td align=center><b>${patch_num}</b></td>" >> ${REPORT}
	echo "<td align=center><b>${proportion}%</b></td>" >> ${REPORT}

	echo "</tr>" >> ${REPORT}
	num=`expr $num + 1`
done < ${TMP}/kernel_companyfinal



echo "<style type=\"text/css\">" >> ${REPORT}
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

echo "<p><table>" >> ${REPORT}
echo "<caption>Docker</caption>" >> ${REPORT}
echo "<tr>" >> ${REPORT}
echo "  <th align=center><div style=\"width:30px;\">num</th>" >> ${REPORT}
echo "  <th align=center><div style=\"width:150px;\">company</th>" >> ${REPORT}
echo "  <th align=center><div style=\"width:100px;\">patch_num</th>" >> ${REPORT}
echo "  <th align=center><div style=\"width:100px;\">proportion</th>" >> ${REPORT}
echo "</tr>" >> ${REPORT}

num=1
#column_num=
while read line 
do
        company=`echo $line | awk '{print $1}'`
        patch_num=`echo $line | awk '{print $2}'`
	proportion=`echo $line | awk '{print $3}'`
	echo "<tr>" >> ${REPORT}
	echo "<td align=center><b>${num}</b></td>" >> ${REPORT}
	echo "<td align=center><b>${company}</b></td>" >> ${REPORT}
	echo "<td align=center><b>${patch_num}</b></td>" >> ${REPORT}
	echo "<td align=center><b>${proportion}%</b></td>" >> ${REPORT}

	echo "</tr>" >> ${REPORT}
	num=`expr $num + 1`
done < ${TMP}/docker_companyfinal

cp ${REPORT} /var/www/html/
