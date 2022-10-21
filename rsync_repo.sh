########
#
#Script for creating or updating linux repositaries
#
#######

#!/bin/bash

OS_FAMILY=almalinux
RELEASE_VER=8
BASE_ARCH=x86_64
REPO_LIST=("BaseOS" "AppStream" "extras")

for REPO_ID in "${REPO_LIST[@]}";
  do
  echo "[+] $REPO_ID"
  LOCAL_PATH=("/local_repo.online/$OS_FAMILY/$RELEASE_VER/$REPO_ID/$BASE_ARCH/os/")
  echo "[+]" $LOCAL_PATH

  # Создание папку в локальном репозитарии, если она не существует
  [[ -d "$LOCAL_PATH" ]] || mkdir -p $LOCAL_PATH
  #mkdir -p /local_repo.online/almalinux/8/{AppStream,BaseOS,extras}/x86_64/os

  #Синхронизируем наш будущий репозиторий с источником пакетов, например, с зеркалом от Яндекса:
  rsync -iavrt --delete  --exclude={'images/*','repo*'} rsync://mirror.yandex.ru/$OS_FAMILY/$RELEASE_VER/$REPO_ID/$BASE_ARCH/os/ $LOCAL_PATH
  #rsync -iavrt --delete  --exclude='repo*' rsync://mirror.yandex.ru/almalinux/8/BaseOS/x86_64/os/ $LOCAL_PATH

  #Индексируем файлы репозитория, если папка не существует то индексируем все файлы полностью (индексируются файлы в файл /repodata/repomd.xml):
  [[ -d "$LOCAL_PATH/repodata" ]] || createrepo -v $LOCAL_PATH

  #Обновлеяем индекс файлы репозитария, если репозитарий был обновлен :
  [[ -d "$LOCAL_PATH/repodata" ]] && createrepo --update $LOCAL_PATH

done
