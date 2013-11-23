#!/bin/bash

if [ -z "${2}" ]
then
	echo "Использование:"
	echo "$0 директория_со_скачанными_тайлами имя_файла_результата"
	echo "Где:"
	echo "   директория_со_скачанными_тайлами - это директория, которая содержит тайлы, скачанные с помощью скриптов wms2png"
	echo "   имя_файла_результата - имя файла, который будет содержать результирующее изображение"
	exit 1
fi
in_dir="${1}"
result_file="${2}"


tmp_dir="/tmp/wms2png"
mkdir -p "${tmp_dir}"
rm -f "${tmp_dir}"/*
echo "Копирую файлы:"
cp "${in_dir}"/* "${tmp_dir}/"

process_current_full_image_iteration()
{
	iteration="$1"

	exit_status=0
	end_list=0
	new_iteration=`expr $iteration + 1`
	new_y=0

	y=0
		echo "y=${y}"
	while /bin/true
	do
		echo "y=${y}"
		# Создаём список на обработку:
		in_files=""
		num_files=0
		while /bin/true
		do
		echo "y=${y}"
			img=${tmp_dir}/iteration_${iteration}-x_0-y_${y}.png
			if [ -f "${img}" ]
			then
				in_files="${img} ${in_files}"
				num_files=`expr $num_files + 1`
			else
				end_list=1
				break
			fi
			echo "img=$img"
			y=`expr $y + 1`
			# Клеим по 10 файлов 
			if [ 9 -lt $num_files ]
			then
				break
			fi
		done
		out_file=${tmp_dir}/iteration_${new_iteration}-x_0-y_${new_y}.png
		echo "montage -background transparent -geometry +0+0 -tile 1x${num_files} ${in_files} ${out_file}"
		montage -background transparent -geometry +0+0 -tile 1x${num_files} ${in_files} ${out_file}
		new_y=`expr $new_y + 1`
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

process_create_current_full_image()
{
	exit_status=0
	iteration=0
	while /bin/true
	do
		process_current_full_image_iteration $iteration
		iteration=`expr $iteration + 1`
		if [ ! -f "${tmp_dir}/iteration_${iteration}-x_0-y_1.png" ]
		then
			# Слилось в один файл
			# Переименовываем его:
			mv "${tmp_dir}/iteration_${iteration}-x_0-y_0.png" "${result_file}" 
			break
		fi
	done
	return $exit_status
}

process_current_lenta_iteration()
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
			if [ -f "${img}" ]
			then
				in_files="${in_files} ${img}"
				num_files=`expr $num_files + 1`
			else
				end_list=1
				break
			fi
			echo "img=$img"
			x=`expr $x + 1`
			# Клеим по 10 файлов 
			if [ 9 -lt $num_files ]
			then
				break
			fi
		done
		out_file=${tmp_dir}/iteration_${new_iteration}-x_${new_x}-y_${y}.png
		echo "montage -background transparent -geometry +0+0 -tile ${num_files}x1 ${in_files} ${out_file}"
		montage -background transparent -geometry +0+0 -tile ${num_files}x1 ${in_files} ${out_file}
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
		process_current_lenta_iteration $iteration $y
		iteration=`expr $iteration + 1`
		if [ ! -f "${tmp_dir}/iteration_${iteration}-x_1-y_${y}.png" ]
		then
			# Слилось в один файл
			# Переименовываем его:
			mv "${tmp_dir}/iteration_${iteration}-x_0-y_${y}.png" "${tmp_dir}/iteration_0-x_0-y_${y}.png" 
			break
		fi
	done
	return $exit_status
}


# Начало скрипта

# Формируем "ленты":
y=0
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

# Склеиваем "ленты" в изображение:
process_create_current_full_image


rm -f "${tmp_dir}"/*
rmdir "${tmp_dir}"

exit 0
