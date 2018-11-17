#!/usr/bin/env python
# -*- coding: utf-8 -*-
import cgi
import os
import time
import re
import sys
import config as conf
import sendemail



# ========== main ==============
if conf.DEBUG:
  user_familia = u"Фамилия"
  user_name = u"Имя"
  user_otchestvo = u"Отчество"
  user_description = u"(А - для сортировки) описание"
  user_addr="DEBUG - empty"
  ou_name = u"filial"
  web_user_name="DEBUG script in console"
  web_user_agent="console"
  web_user_addr="127.0.0.1"
  web_user_host="localhost"
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
print("form=",form)
sys.exit()

# Обрабатываем ФИО - добавляем пользователя и выводим на экран результат:
user={}

if create_drsk_user(user_familia,user_name,user_otchestvo,user_description,ou_name,user) is False:
  log.add(u"ERROR create user: %s, %s, %s, %s" % (user_familia, user_name, user_otchestvo, user_description) )
  print("<h1>Внутренняя ошибка!</h1>")
  print("</body></html>")
  sys.exit(1)
else:
  # Всё хорошо, печатаем результат:
  print("""<h1>Результат:</h1>""")
  print("""<p>Выполнено %d из %d задач</p>""" % (user["num_success_op"], user["num_op"]))
  print("""<h2>Успешно создан пользователь:</h2>""")
  print("""<h2>Имя:</h2>
  <p>%s</p>""" % user["fio"].encode('utf8'))
  print("""<h2>Логин:</h2>
  <p>%s</p>""" % user["login"].encode('utf8'))
  print("""<h2>Пароль:</h2>
  <p><span class="password">%s</span></p>""" % user["passwd"].encode('utf8'))
  print("""<h2>Префикс почты:</h2>
  <p>%s</p>""" % user["email_prefix"].encode('utf8'))
  print("""<h2>Почтовый ящик1:</h2>
  <p>%s</p>""" % user["email_server1"].encode('utf8'))
  print("""<h2>Почтовый ящик2:</h2>
  <p>%s</p>""" % user["email_server2"].encode('utf8'))
  print("<h2>Будьте внимательны с символами в пароле:</h2>")
  print("<p><span class='info'>1 - один, l - английская прописная Л, 0 - ноль, O - английская буква, I - английская большая И</span></p>")
  print("</body></html>")

  sys.exit(0)
