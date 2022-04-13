#!/bin/bash
# xtile+=xtile<0?-0.5:0.5;
#  ytile+=ytile<0?-0.5:0.5;

long2xtile()  
{ 
 long=$1
 zoom=$2
 echo "${long} ${zoom}" | awk '{ xtile = ($1 + 180.0) / 360 * 2.0^$2; 
  printf("%d", xtile ) }'
}

lat2ytile() 
{ 
 lat=$1;
 zoom=$2;
 tms=$3;
 ytile=`echo "${lat} ${zoom}" | awk -v PI=3.14159265358979323846 '{ 
   tan_x=sin($1 * PI / 180.0)/cos($1 * PI / 180.0);
   ytile = (1 - log(tan_x + 1/cos($1 * PI/ 180))/PI)/2 * 2.0^$2; 
   printf("%d", ytile ) }'`;
 if [ ! -z "${tms}" ]
 then
  #  from oms_numbering into tms_numbering
  ytile=`echo "${ytile}" ${zoom} | awk '{printf("%d\n",((2.0^$2)-1)-$1)}'`;
 fi
 echo "${ytile}";
}

download_tile()
{
	# parameters - zoom,x,y: $1,$2,$3
	echo "Start processing tile: ${1}/${2}/${3}"
	echo "============================================" >> "${log}"
	echo "Start processing tile: ${1}/${2}/${3}" >> ${log}
  for layer in ${layers}
  do
    success_download_layer_tile=0
    for tms_url_server in ${tms_url}
    do
      echo "`date +%Y.%m.%d-%T`: запуск команды:" >> "${log}"
      echo "`date +%Y.%m.%d-%T`: wget ${wget_opt} ${tms_url_server}/${layer}/${1}/${2}/${3}.png -O ${out_dir}/${layer}/iteration_0-x_${file_x_index}-y_${file_y_index}.png -o ${wget_log} &> /dev/null"
      echo "`date +%Y.%m.%d-%T`: wget ${wget_opt} ${tms_url_server}/${layer}/${1}/${2}/${3}.png -O ${out_dir}/${layer}/iteration_0-x_${file_x_index}-y_${file_y_index}.png -o ${wget_log} &> /dev/null" >> "${log}"
      # 10 попыток скачать:
      for((try=0;try<=10;try++))
      do
        wget ${wget_opt} "${tms_url_server}/${layer}/${1}/${2}/${3}.png" -O "${out_dir}/${layer}/iteration_0-x_${file_x_index}-y_${file_y_index}.png" -o "${wget_log}" &> /dev/null
        if [ 0 == $? ]
        then
          # success
          success_download_layer_tile=1
          break
        fi
        sleep 10
        if [ $try -eq 10 ]
        then
          echo "`date +%Y.%m.%d-%T`: 10 try wget start is fail. try next server..." >> "${log}"
          echo "`date +%Y.%m.%d-%T`: fail url: ${tms_url_server}/${layer}/${1}/${2}/${3}.png" >> "${log}"
          break
        fi
      done
      if [ 1 -eq $success_download_layer_tile ]
      then
        echo "`date +%Y.%m.%d-%T`: success download tile" >> "${log}"
        break
      fi
    done
    if [ 0 -eq $success_download_layer_tile ]
    then
      echo "`date +%Y.%m.%d-%T`: can not download tile on all servers - return 1" >> "${log}"
      return 1
    fi
  done
  echo "`date +%Y.%m.%d-%T`: success download all layers for this 'num-tile' (${1}/${2}/${3})" >> "${log}"
}

if [ -z $1 ]
then
	echo "Нужно указать конфигурационный файл."
	echo "Напрмиер:"
	echo "$0 tms2png.conf"
	exit 1
fi

source "${1}"

echo "`date +%Y.%m.%d-%T`: =======   start run_tms2png.sh $1  ============" >> "${log}"

X1=$( long2xtile ${LON_LEFT_DOWN} ${ZOOM} );
Y1=$( lat2ytile ${LAT_LEFT_DOWN} ${ZOOM} ${TMS} );

X2=$( long2xtile ${LON_RIGHT_UP} ${ZOOM} );
Y2=$( lat2ytile ${LAT_RIGHT_UP} ${ZOOM} ${TMS} );

url1="http://tile.osm.prim.drsk.ru/osm/${ZOOM}/${X1}/${Y1}.png"
url2="http://tile.osm.prim.drsk.ru/osm/${ZOOM}/${X2}/${Y2}.png"

echo "url1: $url1"
echo "url2: $url2"

file_x_index=0
file_y_index=0

for layer in ${layers}
do
	mkdir -p "${out_dir}/${layer}"
done


exit_status=0

cur_x=$X1
cur_y=$Y1

echo "`date +%Y.%m.%d-%T`: begin download layers..." >> "${log}"

while /bin/true
do
		while /bin/true
		do
			#############################
			# download_tile:
			echo "download_tiles (${layers}) zoom: $ZOOM, x=$cur_x y=$cur_y"
			echo "download_tiles (${layers}) zoom: $ZOOM, x=$cur_x y=$cur_y" >> "${log}"
			download_tile "${ZOOM}" "${cur_x}" "${cur_y}"
			if [ ! 0 -eq $? ]
			then
				echo "`date +%Y.%m.%d-%T`: error process_bbox()!" 
				echo "`date +%Y.%m.%d-%T`: error process_bbox()!" >> "${log}"
				exit 1
			fi

			#############################
      file_x_index=`expr $file_x_index + 1`
      cur_x=`expr $cur_x + 1`
			if [ $cur_x -gt $X2 ]
			then
				break
			fi
		done
  cur_x=$X1
  cur_y=`expr $cur_y - 1`
  if [ $cur_y -lt $Y2 ]
  then
    echo "cur_y=$cur_y, Y2=$Y2"
    break
  fi
	file_x_index=0
	file_y_index=`expr $file_y_index + 1`
	if [ 1 -eq $exit_status ]
	then
    echo "`date +%Y.%m.%d-%T`: error exit_status = 1" 
    echo "`date +%Y.%m.%d-%T`: error exit_status == 1" >> "${log}"
    exit 1
	fi
done

echo "`date +%Y.%m.%d-%T`: ==== success  download layers  ====" >> "${log}"
echo "`date +%Y.%m.%d-%T`: ==== begin montage full layers ====" >> "${log}"

# Запускаем "склейку" файлов:
mkdir "${out_dir}/result"
for layer in ${layers}
do
	${create_image_script_path} "${out_dir}/${layer}/" "${out_dir}/result/${layer}_full_image.png"
  if [ ! 0 -eq $? ]
  then
    echo "`date +%Y.%m.%d-%T`: error ${create_image_script_path} ${out_dir}/${layer}/ ${out_dir}/result/${layer}_full_image.png" >> "${log}"
    echo "`date +%Y.%m.%d-%T`: exit!" >> "${log}"
    exit 1
  fi
done
echo "`date +%Y.%m.%d-%T`: ==== success montage full layers ====" >> "${log}"
echo "`date +%Y.%m.%d-%T`: ==== end success create tms-map ====" >> "${log}"
exit 0
