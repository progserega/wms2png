#!/bin/bash
dir="out"
x_tiles=152
y_tyles=1


tmp_dir="/tmp/wms2png"
mkdir -p "${tmp_dir}"
#rm -f "${tmp_dir}/*"


process_current_iteration()
{
	iteration="$1"
	y="$2"

	exit_status=0
	end_list=0
	new_iteration=`expr $iteration + 1`
	new_x=0

	x=0
	while /bin/true
	do
		# Создаём список на обработку:
		in_files=""
		num_files=0
		while /bin/true
		do
			img=${tmp_dir}/iteration_${iteration}-x_${x}-y_${y}.png
			echo "img=$img"
			if [ -f "${img}" ]
			then
				in_files="${in_files} ${img}"
				num_files=`expr $num_files + 1`
			else
				end_list=1
				break
			fi
			x=`expr $x + 1`
			# Клеим по 10 файлов 
			if [ 9 -lt $num_files ]
			then
				break
			fi
		done
		out_file=${tmp_dir}/iteration_${new_iteration}-x_${new_x}-y_${y}.png
		echo "montage -geometry +0+0 -tile ${num_files}x1 ${in_files} ${out_file}"
		montage -geometry +0+0 -tile ${num_files}x1 ${in_files} ${out_file}
		new_x=`expr $new_x + 1`
		# Удаляем слитые файлы:
		echo "rm ${in_files}"
		rm ${in_files}
		if [ 1 -eq $end_list ]
		then
			break
		fi
	done
	return $exit_status
}

process_create_current_lenta()
{
	y=$1
	exit_status=0
	iteration=0
	while /bin/true
	do
		process_current_iteration $iteration $y
		iteration=`expr $iteration + 1`
		if [ ! -f "${tmp_dir}/iteration_${iteration}-x_1-y_${y}.png" ]
		then
			# Слилось в один файл
			break
		fi
	done
	return $exit_status
}



x=0
y=0
index=0
while /bin/true
do
	process_create_current_lenta $y
	y=`expr $y + 1`
	if [ ! -f "${tmp_dir}/iteration_0-x_0-y_${y}.png" ]
	then
		# Слилось в один файл
		break
	fi
done

exit 0

#rm -f "${tmp_dir}/*"
#rmdir "${tmp_dir}"
