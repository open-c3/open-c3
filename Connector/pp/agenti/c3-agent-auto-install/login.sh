#!/bin/bash

key_directory="./secret"

if [ "X$Install_C3_Agent" == "X1"  ]; then
    c3addr=$(< addr)
    c3addr=$(echo "$c3addr" | xargs) 
    
    if [ -z "$c3addr" ]; then
      echo "错误：addr 文件内容为空，请配置正确的网址。"
      exit 1
    fi
fi

server_ip="$1"

if [ -z "$server_ip" ]; then
  echo "请输入服务器 IP 地址。"
  exit 1
fi

proxy_ip=$(c3mc-base-get-proxy-ip --node "$server_ip" 2>/dev/null | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1)

echo proxy_ip : $proxy_ip


frames=('/' '-' '\' '|')

key_prefix=""

IFS='.' read -ra ADDR <<< "$server_ip"

ip_prefix="${ADDR[0]}.${ADDR[1]}"

while IFS= read -r line; do
  ip_list="${line%%:*}"   # 取冒号前部分
  prefix="${line##*:}"    # 取冒号后部分

  IFS=',' read -ra ip_arr <<< "$ip_list"
  for cfg_ip in "${ip_arr[@]}"; do
    if [[ "$ip_prefix" == "$cfg_ip" ]]; then
      key_prefix="$prefix"
      break 2  # 找到就退出两层循环
    fi
  done
done < config.txt


key_files=("$key_directory"/*)
if [ -n "$key_prefix" ]; then
    key_files=("$key_directory"/$key_prefix*)
fi

for key_file in "${key_files[@]}"; do

    if [[ "$key_file" == *.username ]]; then
        break;
    fi

    usernames=("root")

    if [ -f "${key_file}.username" ];then
      usernames=()
      while IFS= read -r line; do
        usernames+=("$line")
      done < <(cat "${key_file}.username" )
    fi

    for username in "${usernames[@]}"; do
        frame=0
        for ((i=0; i<${#frames[@]}; i++)); do
          echo -ne "\r尝试使用用户名: $username 密钥: $(basename "$key_file") 登录 $server_ip ${frames[frame]}"
          frame=$(( (frame + 1) % 4 ))
          sleep 0.1
        done
    
        if [[ "$key_file" == *.passwd ]]; then
            password=$( cat $key_file )

            if [ "X$Install_C3_Agent" == "X1"  ]; then
                if sshpass -p "$password" ssh -q -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$username@$server_ip" "echo 'start install' && curl -L $c3addr/api/agent-install.sh | sudo bash" ;  then
                  echo -e "\r成功: 服务器 $server_ip 可以使用密钥 $(basename "$key_file") 和用户名 $username 登录。"
                  exit 0
                fi
            else

                if sshpass -p "$password" ssh -q -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$username@$server_ip" ;  then
                  echo -e "\r成功: 服务器 $server_ip 可以使用密钥 $(basename "$key_file") 和用户名 $username 登录。"
                  exit 0
                fi
           fi

        else
            if [ -n "$proxy_ip" ]; then
                proxy_opt=( -o "ProxyCommand=ssh -i $key_file -o StrictHostKeyChecking=no -o PreferredAuthentications=publickey -W %h:%p $username@$proxy_ip" )
            else
                proxy_opt=()
            fi

            if [ "X$Install_C3_Agent" == "X1"  ]; then
                if ssh -q -o ConnectTimeout=10 "${proxy_opt[@]}" -o BatchMode=yes -o StrictHostKeyChecking=no -i "$key_file" "$username@$server_ip" "echo 'start install' && curl -L $c3addr/api/agent-install.sh | sudo bash" ;  then
                  echo -e "\r成功: 服务器 $server_ip 可以使用密钥 $(basename "$key_file") 和用户名 $username 登录。"
                  exit 0
                fi
            else

                if ssh -q -o ConnectTimeout=10 "${proxy_opt[@]}" -o PreferredAuthentications=publickey -o BatchMode=yes -o StrictHostKeyChecking=no -i "$key_file" "$username@$server_ip";  then
                  echo -e "\r成功: 服务器 $server_ip 可以使用密钥 $(basename "$key_file") 和用户名 $username 登录。"
                  exit 0
                fi
           fi
        fi
    done
done

echo -e "\r错误: 目录里面的密钥无法登录到服务器 $server_ip，请尝试使用其他的密钥和用户名。"
exit 1
