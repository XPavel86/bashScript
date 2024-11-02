#!/bin/sh
 
# by PavelD 
# Universal androidSuperScript for MAC OS
# Run with: % chmod 754 ~/Downloads/androidSuperScript.sh

IFS=$'\n'

mainDir=~/Downloads
dirOnPhone="/sdcard/Download" 

myReturn=0 # флаг подключенного девайса

Exist() {
    type "$1" &> /dev/null ;
} 

Help_ () {
 clear
 echo "Device ready to use!"
 echo "Load APK files in $mainDir"
 echo "Choose an action:"
   
 echo "1 - List installed applications by mask"
 echo "2 - Video Recording / Screenshot"
 echo "3 - Exit"
 echo "a - Install all APKs from list"
 echo "d - Uninstall all applications by mask"
 echo "i - Install an application from list"
 echo "r - Run application by mask"
 echo "k - Kill all applications by mask"
 echo "b - Set battery level to 50%"
 echo "g - Retrieve logs to $mainDir"
 
 echo "q - Exit"
 echo "? - Help"
 echo " "
 }

killApp () {
    local mask=$1
    local flag=0
    for p in $(adb shell ps | grep "$mask" | awk '{ print $9 }'); do
        flag=1
        adb shell am force-stop $p 
        echo "Stopped: $p"
    done
    
    if [[ $flag == 0 ]] ; then 
      echo "No running applications matching '$mask' found";
    fi
}

installAppFromList () {
    i=0
    for p in $(ls -t "$1"/*.apk); do
        if [ -f "$p" ]; then
            ((i++))
            array[i]="$p"
            echo "  $i - $p" 
        fi
    done

    if (( $i > 0 )) ; then   
        echo "Enter app number to install, or 'q' to cancel"
        while true; do 
            read -r answer 
            if [[ "$answer" = [qQ] ]] ; then return 1
            elif [[ $answer -ge 1 && $answer -le ${#array[@]} ]] &> /dev/null; then
                echo "Installing ${array[$answer]}"
                adb install -r "${array[$answer]}"
                adb shell exit
                break
            else
                echo "Invalid input, try again"
            fi
        done
    else
        echo "No applications matching '*.apk' found in $mainDir"
    fi
}

runApp() {
    i=0
    for p in $(adb shell pm list package "$1" | cut -f 2 -d ":"); do
        ((i++))
        array[i]=$p
    done
    echo "Enter app number to run, or 'q' to cancel"
    nameAndVersion "$1"

    while true; do
        read -r answer
        if [[ "$answer" = [qQ] ]]; then return 1
        elif [[ "${array[*]}" =~ $answer ]]; then
            adb shell monkey -p ${array[$answer]} -c android.intent.category.LAUNCHER 1 &> /dev/null 
            echo "Starting ${array[$answer]}"
            adb shell exit
            break
        else
            echo "Invalid input, try again"
        fi
    done
}

FindLastFileAndInstallApp() {
    eval str1="$1"
    var11=$(find "$mainDir" -type f -name "$str1" -mtime -30 | sort -r | sed -n '1p')
    if [ -z "$var11" ]; then
        echo "No apps found matching $mainDir/$1"
    else
        if [ "$2" == "-n" ]; then
            find "$mainDir" -type f -name "$str1" -mtime -30 | sort -r
        else  
            echo "Installing $var11"
            adb install -r "$var11"
        fi
    fi
} 
 
nameAndVersion (){
    i=0
    echo " "
    for p in $(adb shell pm list package "$1" | cut -f 2 -d ":"); do
        ((i++))
        array[i]=$p
        echo "$i. $p - $(adb shell dumpsys package "$p" | grep versionName | cut -f 2 -d "=")"
    done
    
    if [[ $i -lt 1 ]]; then 
        echo "No installed programs matching '$1'"
    fi
    adb shell exit
}

uninstallApp () {
    local mask=$1
    for p in $(adb shell pm list package "$mask" | cut -f 2 -d ":"); do
        adb uninstall "$p"
        echo "Uninstalled $p"
    done
    adb shell exit
}

batteryLevel () {
    if [ "$1" -ge 1 -a "$1" -le 100 ]; then
        adb shell dumpsys battery set level "$1"
    else
        adb shell dumpsys battery reset
    fi
    echo "Battery level: $(adb shell dumpsys battery | grep 'level')"
    adb shell exit
}

screenCast (){
    dt=$(date '+%d.%m.%Y_%H.%M.%S')
    if  [ "$1" == "png" ]; then
        adb shell rm -f /sdcard/screen_.png
        adb shell screencap -p /sdcard/screen_.png
        adb pull /sdcard/screen_.png "$mainDir/Screen_$dt.png"
        echo "Screenshot file: $mainDir/Screen_$dt.png"
    elif [ "$1" == "video" ]; then
        adb shell rm -f /sdcard/video.mp4
        adb shell screenrecord --size 640x480 --bit-rate 6000000 --time-limit 60 --verbose /sdcard/video.mp4
        adb pull /sdcard/video.mp4 "$mainDir/Video_$dt.mp4"
        echo "Video file: $mainDir/Video_$dt.mp4"
    fi
    adb shell exit
    if [ -f "$mainDir/Video_$dt.mp4" ] || [ -f "$mainDir/Screen_$dt.png" ]; then
        open "$mainDir/"
    else
        echo "Error copying to $mainDir/"
    fi
}

StateDevice () {
    while : ; do
        var=$(adb devices)
        s='List of devices attached'
        if  [ "$var" ==  "$s" ]; then
            echo "Enable USB debugging and trust this device"
            myReturn=0
        else
            echo "Device connected"
            myReturn=1
            break
        fi
    done
}

# Main
if ! Exist adb &&  ! Exist /opt/homebrew/bin/adb; then
    echo 'ADB not found'
    if ! Exist brew && ! Exist /opt/homebrew/bin/brew; then
        echo 'Installing dependencies, please enter password if prompted'
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        PATH=/opt/homebrew/bin/ export PATH
    else
        echo 'Installing ADB...'
        brew install android-platform-tools
        PATH=/opt/homebrew/bin/ export PATH
    fi
else
    echo 'ADB is installed!'
fi
 
StateDevice

if [ "$myReturn" ==  0 ]; then
    StateDevice
else
    Help_
    while true; do
        read -r runCommand
        case $runCommand in
            [1] ) nameAndVersion "package_mask" ;;
            [2] ) screenCast "video" ;;
            [qQ] ) exit 1 ;;
            [?] ) Help_ ;;
            [sS] ) screenCast "png" ;;
            [dD] ) uninstallApp "package_mask" ;;
            [aA] ) installAppAll "*.apk" ;;
            [iI] ) installAppFromList "$mainDir" "*.apk" ;;
            [gG] ) getLastLogFileTxt "$dirOnPhone" "*.txt" ;;
            [rR] ) runApp "package_mask" ;;
            [kK] ) killApp "package_mask" ;;
            [bB] ) batteryLevel 50 ;;
             * ) echo "Invalid input" ;;
        esac
        echo "Done! Choose an action (? for help):"
    done
fi
