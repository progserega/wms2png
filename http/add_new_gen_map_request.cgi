#!/usr/bin/env python
# -*- coding: utf-8 -*-
import cgi
import os
import time
import re
import sys
import logging
import config as conf

def add_request(lat_left_bottom,lon_left_bottom,lat_right_top,lon_right_top,scale,email,layers):
  index=1
  conf_path_new=None
  conf_path_success=None
  conf_path_error=None
  while(True):
    conf_path_new=conf.config_path+"/"+email+"_%d"%index+"_new.conf"
    conf_path_success=conf.config_path+"/"+email+"_%d"%index+"_success.conf"
    conf_path_error=conf.config_path+"/"+email+"_%d"%index+"_error.conf"
    cf_new_flag=False
    cf_success_flag=False
    cf_error_flag=False
    try:
      cf_new=open(conf_path_new,"r")
      cf_new_flag=True
      cf_new.close()
    except:
      # нет такого файла:
      break
    try:
      cf_success=open(conf_path_success,"r")
      cf_success_flag=True
      cf_success.close()
    except:
      # нет такого файла:
      break
    try:
      cf_error=open(conf_path_error,"r")
      cf_error_flag=True
      cf_error.close()
    except:
      # нет такого файла:
      break

    if cf_new_flag == False and cf_success_flag == False and cf_error_flag == False:
      # нет ни одного файла с любым статусом - создаём новый файл задачи с этим (index) индексом:
      break
    else:
      # увеличиваем индекс и ищем следующий файл:
      pass
    index+=1

  try:
    cf=open(conf_path_new,"w+")
  except:
    log.error("can not create file: %s"%conf_path_new)
    return False

  # создаём конфиг:
  conf_data="""# Конфигурационный файл для tms2png созданный скриптом через веб интерфейс
ZOOM="%(scale)d"
LAT_LEFT_DOWN="%(lat_left_bottom)f"
LON_LEFT_DOWN="%(lon_left_bottom)f"
LAT_RIGHT_UP="%(lat_right_top)f"
LON_RIGHT_UP="%(lon_right_top)f"
out_dir="%(out_dir)s"
log="%(log_file)s"
wget_log="%(wget_log)s"
create_image_script_path="/opt/osm/local_utils/wms2png/create_image.sh"
#wget_opt="--no-proxy"
wget_opt="--no-proxy --tries=10 --timeout=10"
email_result_to="%(email)s"
"""%{\
  "lat_left_bottom":lat_left_bottom,\
  "lon_left_bottom":lon_left_bottom,\
  "lat_right_top":lat_right_top,\
  "lon_right_top":lon_right_top,\
  "scale":scale,\
  "out_dir":conf.out_dir+"/"+email+"_%d"%index,\
  "log_file":conf.log_dir+"/"+email+"_%d"%index+".log",\
  "email":email,\
  "wget_log":conf.log_dir+"/"+email+"_%d"%index+"_wget.log"\
}

  cf.write(conf_data)
  cf.write("tms_url=\"http://b.tile.osm.prim.drsk.ru\"\n")

  # слои:
  cf.write("# слои для скачивания\nlayers=\"")
  for l in layers:
    cf.write(l.strip())
    cf.write(" ")
  cf.write("\"\n")

  cf.close()

  return True

# ========== main ==============
# log init:
log=logging.getLogger("add_new_gen_map_request")
if conf.debug:
  log.setLevel(logging.DEBUG)
else:
  log.setLevel(logging.INFO)

# create the logging file handler
fh = logging.FileHandler(conf.log_path)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
fh.setFormatter(formatter)

if conf.console:
  # логирование в консоль:
  #stdout = logging.FileHandler("/dev/stdout")
  stdout = logging.StreamHandler(sys.stdout)
  stdout.setFormatter(formatter)
  log.addHandler(stdout)

# add handler to logger object
log.addHandler(fh)

log.info("Program started")
  
if conf.console:
  lat_left_bottom="42.9275"
  lon_left_bottom="131.7008"
  lat_right_top="43.2279"
  lon_right_top="132.12"
  scale="14"
  email="semenov@rsprim.ru"
  layers=["drsk_tower_04","osm"]
else:
  form = cgi.FieldStorage()

  web_user_agent=os.getenv("HTTP_USER_AGENT")
  web_user_addr=os.getenv("REMOTE_ADDR")
  web_user_host=os.getenv("REMOTE_HOST")
  web_user_name=os.getenv('AUTHENTICATE_SAMACCOUNTNAME')

  print("""
  <html>
  <head>
  <meta http-equiv='Content-Type' content='text/html; charset=utf-8'>
  <title>Результат выполнения</title>

    <style>
    .password {
 /*   color: green;  Зелёный цвет выделения */
 /*   background: #D9FFAD; */
    font-size: 150%;
    /*font-family: courier-new;*/
    font-family: Andale Mono;
    }
    </style>

    <style>
    .info {
    color: green;  /* Зелёный цвет выделения */
    background: #D9FFAD; 
    font-size: 150%;
    /*font-family: courier-new;*/
    font-family: Andale Mono;
    }
    </style>

    <style>
    .success {
    background: green; 
    }
    </style>

    <style>
    .error {
    background: red; 
    }
    </style>

  </head>
  <body>
  """ )
try:
  # Поле 'work_sites_regex' содержит не пустое значение:
  if 'lat_left_bottom' in form \
    and 'scale' in form \
    and 'email' in form \
    and 'lon_left_bottom' in form \
    and 'lat_right_top' in form \
    and 'lon_right_top' in form:
    lat_left_bottom = "%s" % cgi.escape(form['lat_left_bottom'].value)
    lon_left_bottom = "%s" % cgi.escape(form['lon_left_bottom'].value)
    lat_right_top = "%s" % cgi.escape(form['lat_right_top'].value)
    lon_right_top = "%s" % cgi.escape(form['lon_right_top'].value)
    scale = "%s" % cgi.escape(form['scale'].value)
    email = "%s" % cgi.escape(form['email'].value)
    layers_list = form['formLayers[]']
    layers=[]
    if type(layers_list) == list:
      log.debug("many layer - add as list")
      for i in layers_list:
        layers.append(cgi.escape(i.value))
    else:
      log.debug("one layer - add as string")
      layers.append(cgi.escape(layers_list.value))

  else:
    print("Необходимо заполнить все поля")
    print("</body></html>")
    log.info("exit")
    sys.exit(1)
except:
  print("Ошибка разбора параметров - обратитесь к администратору")
  print("</body></html>")
  log.error("error parse parameters")
  log.error("exit")
  sys.exit(1)

# проверяем параметры:
try:
  lat_left_bottom_f=float(lat_left_bottom.strip())
  lon_left_bottom_f=float(lon_left_bottom.strip())
  lat_right_top_f=float(lat_right_top.strip())
  lon_right_top_f=float(lon_right_top.strip())
  scale_i=int(scale.strip())
except:
  print("Неверно указаны координаты (отделяйте дробную часть точкой)")
  print("</body></html>")
  log.error("error input coordinates")
  log.info("exit")
  sys.exit(1)

if '@' not in email or 'drsk.ru' not in email and 'rsprim.ru' not in email:
  print("Неверно указан почтовый адрес (почтовый адрес должен принадлежать внутренним почтовым серверам АО ДРСК)")
  print("</body></html>")
  log.error("error email=%s"%email)
  log.info("exit")
  sys.exit(1)

# размер получаемой карты (2.5 - на глазок):
size=(lat_right_top_f-lat_left_bottom_f)*(lon_right_top_f-lon_left_bottom_f)*scale_i
if size > 2.5 or scale_i>17:
  print("Вы запрашиваете слишком большой размер карты. Попробуйте уменьшить либо размер квадрата либо масштаб")
  print("</body></html>")
  log.error("%s: error size map too big (size=%f, scale_i=%f)"%(email, size, scale_i))
  log.error("%s: bbox was: %f,%f - %f,%f scale_i=%f)"%(email, lat_left_bottom_f,lon_left_bottom_f,lat_right_top_f,lon_right_top_f))
  log.info("exit")
  sys.exit(1)

log.info("request: %f,%f-%f,%f size: %d, email: %s"%(lat_left_bottom_f,lon_left_bottom_f,lat_right_top_f,lon_right_top_f,scale_i,email))

for layer in layers:
  log.info("layer: %s"%layer)

if add_request(lat_left_bottom_f,lon_left_bottom_f,lat_right_top_f,lon_right_top_f,scale_i,email.strip(),layers) == False:
  print("<h1>Внутренняя ошибка!</h1>")
  print("</body></html>")
  sys.exit(1)
else:
  # Всё хорошо, печатаем результат:
  print("""<h1>Результат:</h1>""")
  print("""<h2>Заявка успешно создана, ожидайте письма</h2>""")
  print("</body></html>")

  sys.exit(0)
