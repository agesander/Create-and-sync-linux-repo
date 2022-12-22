#!/bin/bash
#####
# repos_update.sh
# version 2.2 25-11-2022
#
# Script that update local repos for:
# - CentOS 7, 8-stream
# - EPEL 7,8
# - AlmaLinux 8
# - RHEL 8.5 (Disabled, because end of license)
# For other please add necessary values in listed variables
# PS: RHEL using another repo sync method
# Fixed:
# - Deleted repeated slash before $END_OF_PATH
# - Generating repo files for client host.
# - Downloding only "Packages" folder, without iso files and other files.
####

PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

#####################################################
#                                                   #
## Function download and update linux repositories ##
#                                                   #
#####################################################
function rsync_repo() {
  echo "+----------------------------------------------------------------------------+"
  echo "  [+] $OS_FAMILY - $RELEASE_VER($BASE_ARCH): $REPO_ID"
  SLASH=""; SLASH2=""; SLASH2W=""
  [ $REPO_ID ] && SLASH="/" #If REPO_ID exist then adding slash '/'
  #[ $REPO_ID ] && REPO_ID="$REPO_ID/" #If REPO_ID exist then adding slash '/'
  [ $END_OF_PATH ] && SLASH2="/" && SLASH2W='/' #If exist then adding slash '/'

  BASE_PATH=("$OS_FAMILY/$RELEASE_VER/$REPO_ID$SLASH$BASE_ARCH$SLASH2$END_OF_PATH/Packages")
  # $END_OF_PATH ] && SLASH="/" || SLASH="" #If exist then adding slash '/'

  LOCAL_PATH=("/local_repo.online/$OS_FAMILY/$RELEASE_VER/$REPO_ID$SLASH$BASE_ARCH$SLASH$END_OF_PATH")
#  [ $END_OF_PATH == "Packages" ] LOCAL_PATH=("/local_repo.online/$BASE_PATH")
  #LOCAL_PATH=("/local_repo.online/$BASE_PATH")

  #  LOCAL_PATH=("/local_repo.online/$OS_FAMILY/$RELEASE_VER/$REPO_ID/$BASE_ARCH/os/")
  echo "  [+] $LOCAL_PATH"
  echo "  [+] $MIRROR/$BASE_PATH"
sleep 2
  # Создание папку в локальном репозитарии, если она не существует
  [[ -d "$LOCAL_PATH" ]] || mkdir -p $LOCAL_PATH
  #mkdir -p /local_repo.online/almalinux/8/{AppStream,BaseOS,extras}/x86_64/os

  #Синхронизируем наш будущий репозиторий с источником пакетов, например, с зеркалом от Яндекса:
 rsync -iavrt --delete  --exclude={'repo*'} "$MIRROR/$BASE_PATH" "$LOCAL_PATH"

  #rsync -iavrt --delete  --exclude={'images/*','repo*'} "rsync://mirror.yandex.ru/$BASE_PATH" $LOCAL_PATH
  #rsync -iavrt --delete  --exclude={'images/*','repo*'} rsync://mirror.yandex.ru/$OS_FAMILY/$RELEASE_VER/$REPO_ID/$BASE_ARCH/os/ $LOCAL_PATH
  #rsync -iavrt --delete  --exclude='repo*' rsync://mirror.yandex.ru/almalinux/8/BaseOS/x86_64/os/ $LOCAL_PATH

  #Если нет ошибки индексируем загруженные файлы и создаем файлы repo
  if [[ $? -eq 0 ]]; then
    #Индексируем файлы репозитория, если папка не существует то индексируем все файлы полностью (индексируются файлы в файл /repodata/repomd.xml):
    [[ -d "$LOCAL_PATH/repodata" ]] || createrepo -v $LOCAL_PATH

    #Обновлеяем индекс файлы репозитария, если репозитарий был обновлен :
    [[ -d "$LOCAL_PATH/repodata" ]] && createrepo --update $LOCAL_PATH

    #Создания файлов *.repo для копирования в папку /etc/yum.repo.d/* на сервера использующих локальные репозитарии
        SERVER_IP=10.222.10.25
        FILENAME="local-$OS_FAMILY$RELEASE_VER.repo"
        DASH=""
          [ $REPO_ID ] && DASH="-" #If REPO_ID exist then adding dash '-'
        HEADER="[itc-local-$OS_FAMILY-$RELEASE_VER$DASH$REPO_ID]"
        NAME="name=ITC-Local ${OS_FAMILY^} $RELEASE_VER $DASH ${REPO_ID^^} - $BASE_ARCH"
        BASEURL="baseurl=http://$SERVER_IP/$OS_FAMILY/\$releasever/$REPO_ID$SLASH\$basearch$SLASH2W$END_OF_PATH"

        if [ "$PREV_FILENAME" == "$FILENAME" ]; then
          echo -e "$HEADER\n$NAME\nenabled=1\ngpgcheck=0\n$BASEURL\n\n" >> "$FILENAME"
        else
          echo -e "$HEADER\n$NAME\nenabled=1\ngpgcheck=0\n$BASEURL\n\n" > "$FILENAME"
        fi
        PREV_FILENAME=$FILENAME
  fi

}
############### END of Fumction ######################



#########################
# Centos 8 vault
#
# Example:  rsync://mirror.yandex.ru/almalinux/8/BaseOS/x86_64/os/
# rsync://mirror.dc.uz/centos-vault/8/AppStream/x86_64/os/
OS_FAMILY=centos
RELEASE_VER=8-stream
BASE_ARCH=x86_64
REPO_LIST=("BaseOS" "AppStream" "extras")
MIRROR="rsync://mirror.yandex.ru"
#https://mirror.yandex.ru/centos/8-stream/AppStream/x86_64/os/
#MIRROR="rsync://mirror.dc.uz"
END_OF_PATH="os" #For Centos 8 is 'os'

for REPO_ID in "${REPO_LIST[@]}";  do
  rsync_repo
done



#exit 0
#########################
# AlmaLinux 8
#
# Example:  rsync://mirror.yandex.ru/almalinux/8/BaseOS/x86_64/os/
#
OS_FAMILY=almalinux
RELEASE_VER=8
BASE_ARCH=x86_64
REPO_LIST=("BaseOS" "AppStream" "extras")
MIRROR="rsync://mirror.yandex.ru"
END_OF_PATH="os" #For Almalinux 8 is 'os'

for REPO_ID in "${REPO_LIST[@]}";  do
  rsync_repo
done


#########################
# Centos 7
#
# Example: rsync://mirror.yandex.ru/centos/7/os/x86_64/
OS_FAMILY=centos
RELEASE_VER=7
BASE_ARCH=x86_64
REPO_LIST=("os" "updates" "extras")
MIRROR="rsync://mirror.yandex.ru"
END_OF_PATH="" #For Centos 7 is empty

for REPO_ID in "${REPO_LIST[@]}";  do
  rsync_repo
done


##########################
#Update EPEL 7 repos
# Example: NOT Accessable rsync://mirror.logol.ru/epel/7/x86_64/
# Example: rsync:/mirror.dc.uz/epel/7/x86_64/Packages
OS_FAMILY=epel
RELEASE_VER=7
BASE_ARCH=x86_64
REPO_ID="" #For EPEL is empty
MIRROR="rsync://mirror.dc.uz"
END_OF_PATH=""   #For EPEL 7 is empty

  rsync_repo



##########################
# Update EPEL 8 repo
# Example: rsync://epel/8/Everything/x86_64/Packages
OS_FAMILY=epel
RELEASE_VER=8
BASE_ARCH=x86_64
REPO_ID="Everything" #For EPEL is empty
MIRROR="rsync://mirror.dc.uz"
END_OF_PATH="" #For EPEL 7 is empty

  rsync_repo

##########################
#Update RHEL 8.5 repos
# Disabled because end of license
# Sync via reposync
if false; then
reposync -n --delete -p /local_repo.online --download-metadata --repo=rhel-8-for-x86_64-baseos-rpms
reposync -n --delete -p /local_repo.online --download-metadata --repo=rhel-8-for-x86_64-appstream-rpms
fi
