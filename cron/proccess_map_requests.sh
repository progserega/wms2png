#!/bin/bash
generated_conf_dirs="/var/osm/wms2png/generted_conf_files"
export_dir="/opt/osm/local_web_services/wms2png/out"
export_url="http://tools.map.prim.drsk.ru/wms2png/out"
log="/var/log/osm/wms2png/cron_process_map_request.log"
email_from="semenov@rsprim.ru"
email_server="mail.rsprim.ru"

find $generated_conf_dirs -type f -and -name '*_new.conf'|while read conf_file
do
  echo "`date +%Y.%m.%d-%T`: ==== start proccess map request for $email_result_to by $conf_file" >> ${log}
  cat $conf_file >> "${log}"
  source $conf_file
  echo "`date +%Y.%m.%d-%T`: ==== start proccess map request for $email_result_to by $conf_file" >> ${log}
  cat $conf_file >> "${log}"
  /opt/osm/local_utils/wms2png/run_tms2png.sh "$conf_file"
  if [ 0 != $? ]
  then
    echo "`date +%Y.%m.%d-%T`: error generate map by $conf_file"
    echo "`date +%Y.%m.%d-%T`: error generate map by $conf_file" >> "${log}"
    echo "conf_file=" >> "${log}"
    cat $conf_file >> "${log}"
    sendEmail -o tls=no -o message-charset=utf-8 -s $email_server -f $email_from -t $email_result_to -u "=?utf-8?b?`echo 'Ошибка создания бумажной карты по вашему запросу!'|base64 -w 0`?=" -m "Карта для вас не сгенерирована. Возможно проблема во входных данных от вас или дело во внутренних проблемах в системе. Обратитесь к системному администратору" 
    if [ 0 -eq $? ]
    then
      echo "success send email to $email_result_to about ERROR map create" >> "${log}"
    else
      echo "ERROR send email to $email_result_to about ERROR map create" >> "${log}"
    fi
    # переименовываем входной конфиг как "неудачно-отработанный":
    error_conf_name="`echo $conf_file|sed 's/_new.conf/_error.conf/'`"
    echo "`date +%Y.%m.%d-%T`: mv $conf_file $error_conf_name" >> "${log}"
    mv "$conf_file" "$error_conf_name"
    # удаляем данные этой генерации:
    echo "`date +%Y.%m.%d-%T`: чистка временных данных:" >> "${log}"
    echo "rm -rf ${out_dir}" >> "${log}"
    rm -rf "${out_dir}" >> "${log}"
    exit 1
  fi
  # Отправляем результат:
  cd "${out_dir}"
  prefix="`pwgen -s -1 -s 16`"
  tar_name="${prefix}.tar.gz"
  tar czf "${tar_name}" result
  mv "${tar_name}" "${export_dir}"
  if [ 0 -eq $? ]
  then
    echo "Создал: ${export_dir}/${tar_name}" >> "${log}"
  else
    echo "ERROR mv $tar_name to ${export_dir}/${tar_name}" >> "${log}"
  fi
  chown www-data "${export_dir}/${tar_name}"
  sendEmail -o tls=no -o message-charset=utf-8 -s $email_server -f $email_from -t $email_result_to -u "=?utf-8?b?`echo 'бумажная карта готова!'|base64 -w 0`?=" -m "Карта для вас сгенерирована. Вы можете скачать архив со сгенерированными для вас слоями по ссылке:  $export_url/$tar_name"
  if [ 0 -eq $? ]
  then
    echo "success send email to $email_result_to about map success on url: $export_url/$tar_name" >> "${log}"
  else
    echo "ERROR send email to $email_result_to about map success on url: $export_url/$tar_name" >> "${log}"
  fi

  # переименовываем входной конфиг как "неудачно-отработанный":
  success_conf_name="`echo $conf_file|sed 's/_new.conf/_success.conf/'`"
  echo "`date +%Y.%m.%d-%T`: mv $conf_file $success_conf_name" >> "${log}"
  mv -v "$conf_file" "$success_conf_name"  >> "${log}"

  # удаляем временные данные этой генерации:
  echo "`date +%Y.%m.%d-%T`: чистка временных данных:" >> "${log}"
  echo "rm -rf ${out_dir}" >> "${log}"
  rm -rf "${out_dir}" >> "${log}"
done

# чистка директории экспорта (карты старее 14 дней):
echo "`date +%Y.%m.%d-%T`: чистка директории экспорта:" >> "${log}"
find "${export_dir}" -mtime +14 -and -type f -print  >> "${log}"
find "${export_dir}" -mtime +14 -and -type f -delete
