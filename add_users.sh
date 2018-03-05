#!/bin/bash

## declare an array variable
declare -a users=("user1" "user2" "user3" "user4" "user5" "user6")

for user in "${users[@]}"; 
do 
  useradd -m $user # make the user  
  pass=$USER_PW # this is run in dockerfile so using the env variable from there
  echo "$user:$pass" | chpasswd # set the password     
  #echo "$user $pass" # or `>> passwords` to create a file recording your passwords 
done

