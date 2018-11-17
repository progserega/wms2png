#!/usr/bin/env python
# -*- coding: utf-8 -*-
import cgi
import os
import time
import re
import sys
import logging
import config as conf

def add_request(lat_left_bottom,lon_left_bottom,lat_right_top,lon_right_top,scale,email):
  # TODO
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

if conf.debug:
  # логирование в консоль:
  #stdout = logging.FileHandler("/dev/stdout")
  stdout = logging.StreamHandler(sys.stdout)
  stdout.setFormatter(formatter)
  log.addHandler(stdout)

# add handler to logger object
log.addHandler(fh)

log.info("Program started")
  
if conf.debig:
  lat_left_bottom=42.9275
  lon_left_bottom=131.7008
  lat_right_top=43.2279
  lon_right_top=132.12
  scale=14
  email="semenov@rsprim.ru"
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
  else:
    print("Необходимо заполнить все поля")
    print("</body></html>")
    sys.exit(1)
  layers = u"%s" % cgi.escape(form['formLayers[]'].value)


# Обрабатываем ФИО - добавляем пользователя и выводим на экран результат:
user={}

if add_request(lat_left_bottom,lon_left_bottom,lat_right_top,lon_right_top,scale,email) == False:
  print("<h1>Внутренняя ошибка!</h1>")
  print("</body></html>")
  sys.exit(1)
else:
  # Всё хорошо, печатаем результат:
  print("""<h1>Результат:</h1>""")
  print("""<h2>Заявка успешно создана, ожидайте письма</h2>""")
  print("</body></html>")

  sys.exit(0)
