#!/bin/bash

app=tdex
uuid=$(cat /dev/urandom | tr -dc 'a-z' | fold -w 5 | head -n 1)
case $1 in
remote)
    iex --name ${uuid}_${app}@erlnode1 --remsh ${app}@erlnode1 --erl "-setcookie nopass"
    ;;
test)
    CONFIG_FILE=priv/${app}.config mix test --no-start
    ;;
*)
    CONFIG_FILE=priv/${app}.config iex --name ${app}@erlnode1 --erl "-setcookie nopass" -S mix
    ;;
esac