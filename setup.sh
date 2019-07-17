#!/bin/bash
export SRC_DIR=`pwd`

export_envs=n
envoptions=("yes" "no" "quit")
PS3='Export environment variables? '
select flag in "${envoptions[@]}"
do
   case $flag in
      "yes")
         export_envs=y
         ;;
      "no")
         export_envs=n
         ;;
      "quit")
         printf "\nBye.\n"
         return
         ;;
      *) echo "invalid option";;
   esac
   break
done

options=("local" "quit")
PS3='Select dev environment: '
select env in "${options[@]}"
do
   if [ "$export_envs" == "y" ] && [ "$env" != "quit" ]
   then
      printf "\nExporting $env environment variables, etc...\n"
      export INSTANCE_DB=story_
   fi
   case $env in
      "local")
         if [ "$export_envs" == "y" ]
         then
            export PGPASSFILE=$SRC_DIR/sql/.pgpass
            export DEV_ENV=local
            export DB_USERNAME=postgres
            export DB_HOST=localhost
            export DB_PORT=5432
         fi
         printf "\nStarting local dev docker containers...\n"
         docker-compose -f docker/$env/docker-compose.$env.yml up -d
         ;;
      "quit")
         printf "\nBye.\n"
         return
         ;;
      *) echo "invalid option";;
   esac
   break
done