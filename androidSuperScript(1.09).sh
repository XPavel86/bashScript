#!/bin/sh

# by PavelD v3 for MAC OS
# run command % chmod 754 ~/Downloads/androidSuperScript.sh

appMask="tsum"
appMaskList=(*tma_aqsi* *atc_aqsi* *abc*)
mainDir=~/Downloads

myReturn=0 # флаг подключенного девайса

Exist() {
    type "$1" &> /dev/null ;
} 

Help_ () {

 clear
 echo "Устройство готово к использованию!"
 echo "Загрузите apk дистрибутивы ЦУМ в папку Загрузки (~/Downloads/)"
 echo  "Выберите действие:"
   
 echo "1 - Удалить ЦУМ касса прод"
 echo "2 - Удалить ЦУМ касса тест"
 echo "3 - Удалить Курьеров прод"
 echo "4 - Удалить Курьеров тест"
 
 echo "5 - Установить Курьеров тест"
 echo "6 - Установить ЦУМ касса тест"
 
 echo "7 - Список установленных программ ЦУМ "
 echo "8/s - Запись видео 60 сек / Скриншот"
 echo "9 - Выход"
 echo "а - Установить все приложения $appMask "
 echo "d - Удалить все приложения $appMask "
 echo "i - Установить приложение из списка"
 echo "r - Запустить приложение $appMask "
 echo "k - Завершить все приложения $appMask "
 echo "b - Установить уровень заряда батареи на 50%"
 
 echo "9 - Выход"
 echo "? - Справка"
 echo " "
 
 }

killApp () {
flag=0
 for p in $(adb shell ps | grep "$1" | awk '{ print $9 }');
    do
    flag=1
        adb shell am force-stop $p 
        echo "Стоп " $p
    done
    
    if [[ $flag == 0 ]] ; then 
      echo "Нет запущенных приложений '$1' " ;
    fi
}

installAppFromList () {
# installAppFrom "~/Downloads" "*.apk"
i=0
echo " " 
#find ~/Downloads -type f -name ""$1"" -mtime -30  | sort -r ;
 for p in $(find ""$1"" -type f -name ""$2"" -mtime -30  | sort -r ;);
    do
   if [ -f $p ]; then
   		 ((i++))
   		 array[i]=""$p""
   		 arrayi[i]=$i
   		 echo "$i - $p"
   	fi	 
   	done	

if [[ $i > 0 ]]; then   	
   	
echo "Введите номер приложения для установки, q - отмена" 
   	
while true; do
read -r answer
 
  if [[ "$answer" == "q" ]] ; then return 1
  else
  if [[ "${arrayi[*]}" =~ $answer ]] ; then
  
    echo "Установка " ${array[$answer]} ;
	adb install -r  ${array[$answer]}  ; #&> /dev/null 
	
	adb shell exit ;
	#return 1
  else
	echo "Неверный ввод, повторите"	 
	#echo "${arrayi[*]}" ;
 fi	
fi	
done

else
 echo "Нет приложений соответвующих маске $2"
 return 1
fi
}

runApp() {
 i=0
 for p in $(adb shell pm list package "$1" | cut -f 2 -d ":" );
    do
    ((i++))
      array[i]=$p
      arrayi[i]=$i
    done
#echo "${arrayi[*]}"
echo "Введите номер приложения для запуска, q - отмена"
nameAndVersion $appMask ;

while true; do
read -r answer
 
  if [[ "$answer" == "q" ]] ; then return 1
  else
  if [[ "${arrayi[*]}" =~ $answer ]] ; then
	adb shell monkey -p ${array[$answer]}  -c android.intent.category.LAUNCHER 1  &> /dev/null ;
	echo "Старт " ${array[$answer]} ;
	adb shell exit ;
	#return 1
  else
	echo "Неверный ввод, повторите"	 
 fi	
fi	
done

}

# Поиск последнего измененного файла в последние 15 дней в папке ~/Downloads по маске и установка
FindLastFileAndInstallApp(){

# маска "*atc_aqsi_test*"
 eval str1="$1"
 # echo "str1 = ${str1}"
 var11=$(find ~/Downloads -type f -name ""${str1}"" -mtime -30  | sort -r | sed -n '1p');
 # find ~/Downloads -type f -name "*tma*" -mtime -15  | sort -r
	if [ "$var11" == """" ] ; then
	 echo "Нет приложений соответсвующих маске ~/Downloads/$1" ;
	 echo "$var11"
	else
	# только показываем список приложений 
		if [ "$2" == ""-n"" ] ; then
		 find ~/Downloads -type f -name ""${str1}"" -mtime -30  | sort -r ;
			else  
			     echo "Установка " $var11
				adb install -r "$var11"
		fi
	fi
} 
 
 #  имя и версия установленного приложения определенного маской
nameAndVersion (){
i=0
echo " "
 for p in $(adb shell pm list package "$1" | cut -f 2 -d ":" );
    do
   		 ((i++))
   		 array[i]=$p
   		 echo $i". $p - $(adb shell dumpsys package "$p" | grep versionName | cut -f 2 -d "=")" ;
    done
    
   if [[ $i < 1 ]] ; then 
     echo "Нет установленных программ соответсвующих маске '$1' " ; 
   fi
 adb shell exit
 }
 
# Удалить приложение
 uninstallApp () {
 eval str1="$1"
 var=$(adb shell pm list package "$str1" | cut -f 2 -d ":" )

if [ "$var" == "$1" ] ; then
echo "Удаление " $str1
adb uninstall "$str1"
else
echo "Приложение $1 не установлено"
fi
}

batteryLevel ()
{
# если входим в диапазон 1..100 то ..
if  [ $1 -ge 1 -a $1 -le 100 ] ; then

	adb shell dumpsys battery set level $1 ;
 else
    adb shell dumpsys battery reset
 fi
 echo "Заряд -$(adb shell dumpsys battery | grep "level")"
 adb shell exit
}

 # Удалить все приложения соответсвующие маске
uninstallAppAll ()
{
 for p in $(adb shell pm list package "$1" | cut -f 2 -d ":" );
    do
        uninstallApp "$p";
    done
 adb shell exit
}

# Установить все приложения соответсвующие маске , указанные в аргументах функции
installAppAll ()
{
 for p in "$@" ;
    do
        FindLastFileAndInstallApp "$p";
    done
    
 adb shell exit
}
 
 # снимки экрана
screenCast (){
dt=$(date '+%d.%m.%Y_%H.%M.%S');

if  [ "$1" == ""png"" ] ; then

 adb shell rm -f /sdcard/screen_.png ;
 adb shell screencap -p /sdcard/screen_.png ;
 adb pull /sdcard/screen_.png ~/Downloads/Screen_"$dt".png ;
 echo "\nScreenShot file: ~/Downloads/Screen_$dt.png" ;
 
 fi

if  [ "$1" == ""video"" ] ; then

adb shell rm -f /sdcard/video.mp4 ;
adb shell screenrecord --size 640x480 --bit-rate 6000000 --time-limit 60 --verbose /sdcard/video.mp4 ;
adb pull /sdcard/video.mp4 ~/Downloads/Video_"$dt".mp4 ;
echo "\nVideo file: ~/Downloads/Video_$dt.mp4" ;

fi

adb shell exit ;
open ~/Downloads/

}

# Проверка состояния подключения
StateDevice () {
 
 StateOFF=1;
  StateON=1;
  while : ; do
  
 var=$(adb devices)
 s='List of devices attached'
 if  [ "$var" ==  "$s" ] ;
 then
 
  #clear;
  if [ $StateON == 1 ] ; then
  clear
  echo "Включите отладку по USB. Подключите устройство к компютеру и нажмите доверять на устройстве";
  #open -a Safari https://android-manual.org/level1/android-enable-usb-debug
  StateON=2;
  StateOFF=1;
  myReturn=0
  fi
  
  else
  if  [ $StateOFF == 1 ] ; then
 # clear;
  echo "Устройство подключено"
  
   StateOFF=2;
   StateON=1;
   myReturn=1
   #=============
  break
   #=============
    fi
 fi
  done
 # Проверка состояния END
 }
 

# проверка и установка необходимых компонентов

if ! Exist adb &&  ! Exist /opt/homebrew/bin/adb
 then
 echo 'ADB отсутсвует'
if ! Exist  brew  && ! Exist  /opt/homebrew/bin/brew  ; then

  echo 'Будут установлены дополнительные компоненты, введите пароль при появлении запроса' >&2 ;
 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" ;
 %PATH=/opt/homebrew/bin/ export PATH ;
  exit 1
  
  else
  echo 'Устанавливаем ADB...' ;
  brew install android-platform-tools ;
  %PATH=/opt/homebrew/bin/ export PATH ;
fi
else
 echo 'ADB установлен!' ;
 #adb devices
 fi
 
 StateDevice

 if  [ "$myReturn" ==  0] ;
 then
 StateDevice
  else
 
   Help_

   while true; do
  
    read -r runCommand
   case $runCommand in
            [1] ) uninstallApp "ru.tsum.mobile.assistant.aqsi_prod" ;;
            [2] ) uninstallApp "ru.tsum.mobile.assistant.aqsi_test" ;;
            [3] ) uninstallApp "ru.tsum.couriers.aqsi_prod" ;;
            [4] ) uninstallApp "ru.tsum.couriers.aqsi_test" ;;
            [5] ) FindLastFileAndInstallApp "*atc_aqsi_test*"  ;; # from folder Downloads
            [6] ) FindLastFileAndInstallApp "*tma_aqsi_test*" ;;
            [7] ) nameAndVersion $appMask ;;
            [8] ) screenCast "video" ;;
            [9] ) exit 1 ;;
            [?] ) Help_ ;;
            [s] ) screenCast "png" ;;
            [d] ) uninstallAppAll $appMask ;;
            [a] ) installAppAll ${appMaskList[*]} ;; # installAppAll "*app1*" "*app2*"  .. from folder Downloads 
            [l] ) FindLastFileAndInstallApp "*.apk*" "-n" ;; # список без установки
            [c] ) FindLastFileAndInstallApp "*abc*" ;;
            [m] ) FindLastFileAndInstallApp "*brs*" ;;
            [i] ) installAppFromList $mainDir "*.apk" ;;
            
            [r] ) runApp $appMask  ;;
            [k] ) killApp $appMask ;;
            [b] ) batteryLevel 50 ;;
             * ) echo "Ошибочный ввод" ;;
        esac
        
         echo "\nГотово! "
         echo "Выберите действие (?):"
  done
 
  exit 1
fi

# старт adb shell monkey -p app.package.name -c android.intent.category.LAUNCHER 1 
