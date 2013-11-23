#!/bin/bash

if [ -z $1 ]
then
	echo "Нужно указать конфигурационный файл."
	echo "Напрмиер:"
	echo "$0 wms2png.conf"
	exit 1
fi

source "${1}"

# нижний левый угол
x1="`echo $BBOX1|awk '{print $1}' FS=','`"
y1="`echo $BBOX1|awk '{print $2}' FS=','`"

# верхний правый угол:
x2="`echo $BBOX2|awk '{print $3}' FS=','`"
y2="`echo $BBOX2|awk '{print $4}' FS=','`"

xx1="`echo $BBOX1|awk '{print $3}' FS=','`"
yy1="`echo $BBOX1|awk '{print $4}' FS=','`"
x_delta="`echo $xx1 - $x1|bc -l`"
y_delta="`echo $yy1 - $y1|bc -l`"

file_x_index="0"
file_y_index="0"

for layer in ${layers}
do
	mkdir -p "${out_dir}/${layer}"
done

download_tile()
{
	# parameters - bbox: $1,$2,$3,$4
	echo "Start processing bbox: ${1},${2} - ${3},${4}"
	echo "============================================" >> "${log}"
	echo "Start processing bbox: ${1},${2} - ${3},${4}" >> "${log}"
	for layer in ${layers}
	do
		echo "запуск команды:" >> "${log}"
		echo "wget ${wms_url}?LAYERS=${layer}&TRANSPARENT=true&REASPECT=false&FORMAT=png&SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&STYLES=&SRS=EPSG%3A3857&BBOX=${1},${2},${3},${4}&WIDTH=256&HEIGHT=256" -O "${out_dir}/${layer}/iteration_0-x_${file_x_index}-y_${file_y_index}.png" -o "${wget_log} &> /dev/null" >> "${log}"
		wget "${wms_url}?LAYERS=${layer}&TRANSPARENT=true&REASPECT=false&FORMAT=png&SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&STYLES=&SRS=EPSG%3A3857&BBOX=${1},${2},${3},${4}&WIDTH=256&HEIGHT=256" -O "${out_dir}/${layer}/iteration_0-x_${file_x_index}-y_${file_y_index}.png" -o "${wget_log}" &> /dev/null
	done
}



bbox_x1="${x1}"
bbox_y1="${y1}"
bbox_x2="${x2}"
bbox_y2="${y2}"

exit_status=0

while /bin/true
do

	bbox_y2="`echo ${bbox_y1}+${y_delta}|bc -l`"
	if [ $(echo "$bbox_y2 > $y2" | bc) -eq 1 ]
	then
		bbox_y2="${y2}"
	fi
	# processing:

		bbox_x1="${x1}"
		bbox_x2="${x1}"
		while /bin/true
		do
			bbox_x2="`echo ${bbox_x1}+${x_delta}|bc -l`"
			if [ $(echo "$bbox_x2 > $x2" | bc) -eq 1 ]
			then
				bbox_x2="${x2}"
			fi

			#############################
			# download_tile:
			echo "download_tiles (${layers}) from: ${bbox_x1} ${bbox_y1} ${bbox_x2} ${bbox_y2}"
			echo "download_tiles (${layers}) from: ${bbox_x1} ${bbox_y1} ${bbox_x2} ${bbox_y2}" >> "${log}"
			download_tile "${bbox_x1}" "${bbox_y1}" "${bbox_x2}" "${bbox_y2}"
			if [ ! 0 -eq $? ]
			then
				echo "`date +%Y.%m.%d-%T`: error process_bbox()!" 
				echo "`date +%Y.%m.%d-%T`: error process_bbox()!" >> "${log}"
				exit_status=1
				break
			fi


			#############################
			bbox_x1="${bbox_x2}"
			if [ $(echo "$bbox_x1 >= $x2" | bc) -eq 1 ]
			then
				break
			fi
			file_x_index=`expr $file_x_index + 1`
		done
	bbox_y1="${bbox_y2}"
	if [ $(echo "$bbox_y1 >= $y2" | bc) -eq 1 ]
	then
		break
	fi
	file_x_index=0
	file_y_index=`expr $file_y_index + 1`
	if [ 1 -eq $exit_status ]
	then
		break
	fi
done

# Запускаем "склейку" файлов:
for layer in ${layers}
do
	${create_image_script_path} "${out_dir}/${layer}/"
done
