#! /bin/bash
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[info]${Font_color_suffix}"
Error="${Red_font_prefix}[error]${Font_color_suffix}"
shell_version="1.1.1"
ct_new_ver="2.11.5" # 2.x 
gost_conf_path="/etc/gost/config.json"
raw_conf_path="/etc/gost/rawconf"
function checknew() {
  checknew=$(gost -V 2>&1 | awk '{print $2}')
  # check_new_ver
  echo "your gost version:""$checknew"""
  echo -n isupdate\(y/n\)\:
  read checknewnum
  if test $checknewnum = "y"; then
    cp -r /etc/gost /tmp/
    Install_ct
    rm -rf /etc/gost
    mv /tmp/gost /etc/
    systemctl restart gost
  else
    exit 0
  fi
}
function check_sys() {
  if [[ -f /etc/redhat-release ]]; then
    release="centos"
  elif cat /etc/issue | grep -q -E -i "debian"; then
    release="debian"
  elif cat /etc/issue | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  elif cat /proc/version | grep -q -E -i "debian"; then
    release="debian"
  elif cat /proc/version | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  fi
  bit=$(uname -m)
  if test "$bit" != "x86_64"; then
    echo "input your CPU artitecture，/386/armv5/armv6/armv7/armv8"
    read bit
  else
    bit="amd64"
  fi
}
function Installation_dependency() {
  gzip_ver=$(gzip -V)
  if [[ -z ${gzip_ver} ]]; then
    if [[ ${release} == "centos" ]]; then
      yum update
      yum install -y gzip wget
    else
      apt-get update
      apt-get install -y gzip wget
    fi
  fi
}
function check_root() {
  [[ $EUID != 0 ]] && echo -e "${Error} now not ROOT(or no ROOT right)，can not continue，PLS change ROOT or use ${Green_background_prefix}sudo su${Font_color_suffix} command get temp ROOT right（input secret code after this）。" && exit 1
}
function check_new_ver() {
  # deprecated
  ct_new_ver=$(wget --no-check-certificate -qO- -t2 -T3 https://api.github.com/repos/ginuerzh/gost/releases/latest | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g;s/v//g')
  if [[ -z ${ct_new_ver} ]]; then
    ct_new_ver="2.11.5"
    echo -e "${Error} gost neweset version gain failed，downloading v${ct_new_ver}"
  else
    echo -e "${Info} gost current version is ${ct_new_ver}"
  fi
}
function check_file() {
  if test ! -d "/usr/lib/systemd/system/"; then
    mkdir /usr/lib/systemd/system
    chmod -R 777 /usr/lib/systemd/system
  fi
}
function check_nor_file() {
  rm -rf "$(pwd)"/gost
  rm -rf "$(pwd)"/gost.service
  rm -rf "$(pwd)"/config.json
  rm -rf /etc/gost
  rm -rf /usr/lib/systemd/system/gost.service
  rm -rf /usr/bin/gost
}
function Install_ct() {
  check_root
  check_nor_file
  Installation_dependency
  check_file
  check_sys
  # check_new_ver
  echo -e "choose Y, or N"
  read -e -p "[y/n]:" addyn
  [[ -z ${addyn} ]] && addyn="n"
  if [[ ${addyn} == [Yy] ]]; then
    rm -rf gost-linux-"$bit"-"$ct_new_ver".gz
    wget --no-check-certificate https://github.com/iPmartNetwork/GOST/releases/tag/v2.11.5/gost-linux-"$bit"-"$ct_new_ver".gz
    gunzip gost-linux-"$bit"-"$ct_new_ver".gz
    mv gost-linux-"$bit"-"$ct_new_ver" gost
    mv gost /usr/bin/gost
    chmod -R 777 /usr/bin/gost
    wget --no-check-certificate https://raw.githubusercontent.com/iPmartNetwork/GOST/main/gost.service && chmod -R 777 gost.service && mv gost.service /usr/lib/systemd/system
    mkdir /etc/gost && wget --no-check-certificate https://raw.githubusercontent.com/iPmartNetwork/GOST/main/config.json && mv config.json /etc/gost && chmod -R 777 /etc/gost
  else
    rm -rf gost-linux-"$bit"-"$ct_new_ver".gz
    wget --no-check-certificate https://github.com/ginuerzh/gost/releases/download/v"$ct_new_ver"/gost-linux-"$bit"-"$ct_new_ver".gz
    gunzip gost-linux-"$bit"-"$ct_new_ver".gz
    mv gost-linux-"$bit"-"$ct_new_ver" gost
    mv gost /usr/bin/gost
    chmod -R 777 /usr/bin/gost
    wget --no-check-certificate https://raw.githubusercontent.com/ipmartnetwork/Gost/main/gost.service && chmod -R 777 gost.service && mv gost.service /usr/lib/systemd/system
    mkdir /etc/gost && wget --no-check-certificate https://raw.githubusercontent.com/ipmartnetwork/Gost/main/config.json && mv config.json /etc/gost && chmod -R 777 /etc/gost
  fi

  systemctl enable gost && systemctl restart gost
  echo "------------------------------"
  if test -a /usr/bin/gost -a /usr/lib/systemctl/gost.service -a /etc/gost/config.json; then
    echo "gost installed"
    rm -rf "$(pwd)"/gost
    rm -rf "$(pwd)"/gost.service
    rm -rf "$(pwd)"/config.json
  else
    echo "gost install failed"
    rm -rf "$(pwd)"/gost
    rm -rf "$(pwd)"/gost.service
    rm -rf "$(pwd)"/config.json
    rm -rf "$(pwd)"/gost.sh
  fi
}
function Uninstall_ct() {
  rm -rf /usr/bin/gost
  rm -rf /usr/lib/systemd/system/gost.service
  rm -rf /etc/gost
  rm -rf "$(pwd)"/gost.sh
  echo "gost delete success"
}
function Start_ct() {
  systemctl start gost
  echo "started"
}
function Stop_ct() {
  systemctl stop gost
  echo "stopped"
}
function Restart_ct() {
  rm -rf /etc/gost/config.json
  confstart
  writeconf
  conflast
  systemctl restart gost
  echo "reloaded config and restart"
}
function read_protocol() {
  echo -e "choose([2]encode [3]decode): "
  echo -e "-----------------------------------"
  echo -e "[1] tcp+udp traffic forwarding, no encryption"
  echo -e "-----------------------------------"
  echo -e "[2] Encode tunnle and transfer"
  echo -e "-----------------------------------"
  echo -e "[3] Decode tunnle and transfer"
  echo -e "-----------------------------------"
  echo -e "[4] Install ss/socks5/http proxy with one click"
  echo -e "-----------------------------------"
  echo -e "[5] Advanced: Multi-landing load balancing"
  echo -e "-----------------------------------"
  echo -e "[6] Advanced: forwarding CDN to selected nodes"
  echo -e "-----------------------------------"
  read -p "Choose: " numprotocol

  if [ "$numprotocol" == "1" ]; then
    flag_a="nonencrypt"
  elif [ "$numprotocol" == "2" ]; then
    encrypt
  elif [ "$numprotocol" == "3" ]; then
    decrypt
  elif [ "$numprotocol" == "4" ]; then
    proxy
  elif [ "$numprotocol" == "5" ]; then
    enpeer
  elif [ "$numprotocol" == "6" ]; then
    cdn
  else
    echo "type error, please try again"
    exit
  fi
}
function read_s_port() {
  if [ "$flag_a" == "ss" ]; then
    echo -e "-----------------------------------"
    read -p "input ss password: " flag_b
  elif [ "$flag_a" == "socks" ]; then
    echo -e "-----------------------------------"
    read -p "input socks password: " flag_b
  elif [ "$flag_a" == "http" ]; then
    echo -e "-----------------------------------"
    read -p "input http password: " flag_b
  else
    echo -e "------------------------------------------------------------------"
    echo -e "whice port will you transfer?"
    read -p "input: " flag_b
  fi
}
function read_d_ip() {
  if [ "$flag_a" == "ss" ]; then
    echo -e "------------------------------------------------------------------"
    echo -e "which ss encryption: "
    echo -e "-----------------------------------"
    echo -e "[1] aes-256-gcm"
    echo -e "[2] aes-256-cfb"
    echo -e "[3] chacha20-ietf-poly1305"
    echo -e "[4] chacha20"
    echo -e "[5] rc4-md5"
    echo -e "[6] AEAD_CHACHA20_POLY1305"
    echo -e "-----------------------------------"
    read -p "input ss encrypton: " ssencrypt

    if [ "$ssencrypt" == "1" ]; then
      flag_c="aes-256-gcm"
    elif [ "$ssencrypt" == "2" ]; then
      flag_c="aes-256-cfb"
    elif [ "$ssencrypt" == "3" ]; then
      flag_c="chacha20-ietf-poly1305"
    elif [ "$ssencrypt" == "4" ]; then
      flag_c="chacha20"
    elif [ "$ssencrypt" == "5" ]; then
      flag_c="rc4-md5"
    elif [ "$ssencrypt" == "6" ]; then
      flag_c="AEAD_CHACHA20_POLY1305"
    else
      echo "type error, please try again"
      exit
    fi
  elif [ "$flag_a" == "socks" ]; then
    echo -e "-----------------------------------"
    read -p "input socks username: " flag_c
  elif [ "$flag_a" == "http" ]; then
    echo -e "-----------------------------------"
    read -p "input http username: " flag_c
  elif [[ "$flag_a" == "peer"* ]]; then
    echo -e "------------------------------------------------------------------"
    echo -e "input list file name"
    read -e -p "Customized but different configurations should not be repeated, no need to enter a suffix，e.g. ips1、iplist2: " flag_c
    touch $flag_c.txt
    echo -e "------------------------------------------------------------------"
    echo -e "input Please enter the landing IP and port you want to load balance in sequence."
    while true; do
      echo -e "will you transfer from ${flag_b} gain flow to IP or Domain?"
      read -p "input IP: " peer_ip
      echo -e "will you transfer from ${flag_b} gain flow to ${peer_ip} port?"
      read -p "input Port: " peer_port
      echo -e "$peer_ip:$peer_port" >>$flag_c.txt
      read -e -p "Whether to continue adding landings？[Y/n]:" addyn
      [[ -z ${addyn} ]] && addyn="y"
      if [[ ${addyn} == [Nn] ]]; then
        echo -e "------------------------------------------------------------------"
        echo -e "in root folder created $flag_c.txt，you can edit this file to modify landing information, reboot gost is ok"
        echo -e "------------------------------------------------------------------"
        break
      else
        echo -e "------------------------------------------------------------------"
        echo -e "Continue to add balanced load landing configuration"
      fi
    done
  elif [[ "$flag_a" == "cdn"* ]]; then
    echo -e "------------------------------------------------------------------"
    echo -e "this VPS from ${flag_b} gain flow transfer to ip:"
    read -p "input cdn: " flag_c
    echo -e "will you transfer from ${flag_b} gain flow transfer to ${flag_c} which Port?"
    echo -e "[1] 80"
    echo -e "[2] 443"
    echo -e "[3] customize（e.g. 8080 et,al.）"
    read -p "input Port: " cdnport
    if [ "$cdnport" == "1" ]; then
      flag_c="$flag_c:80"
    elif [ "$cdnport" == "2" ]; then
      flag_c="$flag_c:443"
    elif [ "$cdnport" == "3" ]; then
      read -p "input customize Port: " customport
      flag_c="$flag_c:$customport"
    else
      echo "type error, please try again"
      exit
    fi
  else
    echo -e "------------------------------------------------------------------"
    echo -e "will you transfer from ${flag_b} gain flow transfer to which IP or Domain?"
    echo -e "Note: The IP can be either the public IP of [remote machine/current machine], or the local loopback IP of this machine (i.e. 127.0.0.1)"
    if [[ ${is_cert} == [Yy] ]]; then
      echo -e "Note: Turn on the custom tls certificate on the floor machine，input ${Red_font_prefix} Domain ${Font_color_suffix}"
    fi
    read -p "input: " flag_c
  fi
}
function read_d_port() {
  if [ "$flag_a" == "ss" ]; then
    echo -e "------------------------------------------------------------------"
    echo -e "which Port will set ss proxy?"
    read -p "input: " flag_d
  elif [ "$flag_a" == "socks" ]; then
    echo -e "------------------------------------------------------------------"
    echo -e "which Port will set socks proxy?"
    read -p "input: " flag_d
  elif [ "$flag_a" == "http" ]; then
    echo -e "------------------------------------------------------------------"
    echo -e "which Port will set http proxy?"
    read -p "input: " flag_d
  elif [[ "$flag_a" == "peer"* ]]; then
    echo -e "------------------------------------------------------------------"
    echo -e "The load balancing policy you want to set: "
    echo -e "-----------------------------------"
    echo -e "[1] round"
    echo -e "[2] random"
    echo -e "[3] fifo"
    echo -e "-----------------------------------"
    read -p "choose: " numstra

    if [ "$numstra" == "1" ]; then
      flag_d="round"
    elif [ "$numstra" == "2" ]; then
      flag_d="random"
    elif [ "$numstra" == "3" ]; then
      flag_d="fifo"
    else
      echo "type error, please try again"
      exit
    fi
  elif [[ "$flag_a" == "cdn"* ]]; then
    echo -e "------------------------------------------------------------------"
    read -p "input host:" flag_d
  else
    echo -e "------------------------------------------------------------------"
    echo -e "will you transfer from ${flag_b} gain flow transfer to Port ${flag_c} ?"
    read -p "input: " flag_d
    if [[ ${is_cert} == [Yy] ]]; then
      flag_d="$flag_d?secure=true"
    fi
  fi
}
function writerawconf() {
  echo $flag_a"/""$flag_b""#""$flag_c""#""$flag_d" >>$raw_conf_path
}
function rawconf() {
  read_protocol
  read_s_port
  read_d_ip
  read_d_port
  writerawconf
}
function eachconf_retrieve() {
  d_server=${trans_conf#*#}
  d_port=${d_server#*#}
  d_ip=${d_server%#*}
  flag_s_port=${trans_conf%%#*}
  s_port=${flag_s_port#*/}
  is_encrypt=${flag_s_port%/*}
}
function confstart() {
  echo "{
    \"Debug\": true,
    \"Retries\": 0,
    \"ServeNodes\": [" >>$gost_conf_path
}
function multiconfstart() {
  echo "        {
            \"Retries\": 0,
            \"ServeNodes\": [" >>$gost_conf_path
}
function conflast() {
  echo "    ]
}" >>$gost_conf_path
}
function multiconflast() {
  if [ $i -eq $count_line ]; then
    echo "            ]
        }" >>$gost_conf_path
  else
    echo "            ]
        }," >>$gost_conf_path
  fi
}
function encrypt() {
  echo -e "What type of forwarding transmission do you want to set?: "
  echo -e "-----------------------------------"
  echo -e "[1] tls tunnle"
  echo -e "[2] ws tunnle"
  echo -e "[3] wss tunnle"
  echo -e "Note: For the same forwarding, the transfer and landing transmission types must correspond! This script enables tcp+udp by default"
  echo -e "-----------------------------------"
  read -p "Please select a forward transfer type: " numencrypt

  if [ "$numencrypt" == "1" ]; then
    flag_a="encrypttls"
    echo -e "Note: Selecting Yes will enable certificate verification for the implemented custom certificate to ensure security.，after landing machine must input ${Red_font_prefix} domain ${Font_color_suffix}"
    read -e -p "Is the custom tls certificate enabled on the floor machine? [y/n]:" is_cert
  elif [ "$numencrypt" == "2" ]; then
    flag_a="encryptws"
  elif [ "$numencrypt" == "3" ]; then
    flag_a="encryptwss"
    echo -e "Note: Selecting Yes will enable certificate verification for the implemented custom certificate to ensure security.，after landing machine must input ${Red_font_prefix} domain ${Font_color_suffix}"
    read -e -p "Is the custom tls certificate enabled on the floor machine？[y/n]:" is_cert
  else
    echo "type error, please try again"
    exit
  fi
}
function enpeer() {
  echo -e "What type of balanced load transmission do you want to set?: "
  echo -e "-----------------------------------"
  echo -e "[1] Forwarding without encryption"
  echo -e "[2] tls tunnle"
  echo -e "[3] ws tunnle"
  echo -e "[4] wss tunnle"
  echo -e "Note: For the same forwarding, the transfer and landing transmission types must correspond! This script defaults to the same transmission type for the same configuration"
  echo -e "-----------------------------------"
  read -p "Please select a forward transfer type: " numpeer

  if [ "$numpeer" == "1" ]; then
    flag_a="peerno"
  elif [ "$numpeer" == "2" ]; then
    flag_a="peertls"
  elif [ "$numpeer" == "3" ]; then
    flag_a="peerws"
  elif [ "$numpeer" == "4" ]; then
    flag_a="peerwss"

  else
    echo "type error, please try again"
    exit
  fi
}
function cdn() {
  echo -e "What CDN transmission type do you want to set?: "
  echo -e "-----------------------------------"
  echo -e "[1] Forwarding without encryption"
  echo -e "[2] ws tunnle"
  echo -e "[3] wss tunnle"
  echo -e "-----------------------------------"
  read -p "Please select CDN forwarding transfer type: " numcdn

  if [ "$numcdn" == "1" ]; then
    flag_a="cdnno"
  elif [ "$numcdn" == "2" ]; then
    flag_a="cdnws"
  elif [ "$numcdn" == "3" ]; then
    flag_a="cdnwss"
  else
    echo "type error, please try again"
    exit
  fi
}
function cert() {
  echo -e "-----------------------------------"
  echo -e "[1] ACME one-click application for certificate"
  echo -e "[2] Manually upload certificate"
  echo -e "-----------------------------------"
  read -p "Please select the certificate generation method: " numcert

  if [ "$numcert" == "1" ]; then
    check_sys
    if [[ ${release} == "centos" ]]; then
      yum install -y socat
    else
      apt-get install -y socat
    fi
    read -p "Please enter your ZeroSSL account email (just register at zerossl.com)：" zeromail
    read -p "Please enter the domain name resolved to this machine：" domain
    curl https://get.acme.sh | sh
    "$HOME"/.acme.sh/acme.sh --set-default-ca --server zerossl
    "$HOME"/.acme.sh/acme.sh --register-account -m "${zeromail}" --server zerossl
    echo -e "ACME certificate application program installed successfully"
    echo -e "-----------------------------------"
    echo -e "[1] HTTP application (requires port 80 to be unoccupied)"
    echo -e "[2] Cloudflare DNS API application (requires entering APIKEY)"
    echo -e "-----------------------------------"
    read -p "Please select the certificate application method: " certmethod
    if [ "certmethod" == "1" ]; then
      echo -e "Please confirm this machine${Red_font_prefix}80${Font_color_suffix}Port is not occupied, Otherwise, the application will fail"
      if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force; then
        echo -e "The SSL certificate is generated successfully and a high-security ECC certificate is applied by default."
        if [ ! -d "$HOME/gost_cert" ]; then
          mkdir $HOME/gost_cert
        fi
        if "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath $HOME/gost_cert/cert.pem --keypath $HOME/gost_cert/key.pem --ecc --force; then
          echo -e "The SSL certificate is configured successfully and will be automatically renewed. certificate and key in user folder ${Red_font_prefix}gost_cert${Font_color_suffix} "
          echo -e "Do not change the certificate directory name and certificate file name; delete the gost_cert directory and restart with the script, which will automatically enable the gost built-in certificate."
          echo -e "-----------------------------------"
        fi
      else
        echo -e "SSL Certificate generation failed"
        exit 1
      fi
    else
      read -p "Please enter your Cloudflare account email address：" cfmail
      read -p "Please enter Cloudflare Global API Key:" cfkey
      export CF_Key="${cfkey}"
      export CF_Email="${cfmail}"
      if "$HOME"/.acme.sh/acme.sh --issue --dns dns_cf -d "${domain}" --standalone -k ec-256 --force; then
        echo -e "The SSL certificate is generated successfully and a high-security ECC certificate is applied by default."
        if [ ! -d "$HOME/gost_cert" ]; then
          mkdir $HOME/gost_cert
        fi
        if "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath $HOME/gost_cert/cert.pem --keypath $HOME/gost_cert/key.pem --ecc --force; then
          echo -e "The SSL certificate is configured successfully and will be automatically renewed.The certificate and secret key are located in the user directory ${Red_font_prefix}gost_cert${Font_color_suffix} "
          echo -e "Do not change the certificate directory name and certificate file name; delete the gost_cert directory and use the script to restart, that is, re-enable the gost built-in certificate"
          echo -e "-----------------------------------"
        fi
      else
        echo -e "SSL Certificate generation failed"
        exit 1
      fi
    fi

  elif [ "$numcert" == "2" ]; then
    if [ ! -d "$HOME/gost_cert" ]; then
      mkdir $HOME/gost_cert
    fi
    echo -e "-----------------------------------"
    echo -e "Created in user directory ${Red_font_prefix}gost_cert${Font_color_suffix} folder，Please upload the certificate file cer.pem and key file key.pem to this directory"
    echo -e "The certificate and secret key file names must be consistent with the above, and the directory name must not be changed."
    echo -e "After the upload is successful, restart gost with a script and it will be automatically enabled, no need to set it up again; delete the gost_cert directory and restart with a script, that is, re-enable gost's built-in certificate"
    echo -e "-----------------------------------"
  else
    echo "type error, please try again"
    exit
  fi
}
function decrypt() {
  echo -e "What type of decryption transmission do you want to set?: "
  echo -e "-----------------------------------"
  echo -e "[1] tls"
  echo -e "[2] ws"
  echo -e "[3] wss"
  echo -e "Note: For the same forwarding, the transfer and landing transmission types must correspond! This script enables tcp+udp by default"
  echo -e "-----------------------------------"
  read -p "Please select a decryption transfer type: " numdecrypt

  if [ "$numdecrypt" == "1" ]; then
    flag_a="decrypttls"
  elif [ "$numdecrypt" == "2" ]; then
    flag_a="decryptws"
  elif [ "$numdecrypt" == "3" ]; then
    flag_a="decryptwss"
  else
    echo "type error, please try again"
    exit
  fi
}
function proxy() {
  echo -e "------------------------------------------------------------------"
  echo -e "What type of proxy do you want to set up?: "
  echo -e "-----------------------------------"
  echo -e "[1] shadowsocks"
  echo -e "[2] socks5(It is strongly recommended to add a tunnel for Telegram proxy)"
  echo -e "[3] http"
  echo -e "-----------------------------------"
  read -p "Please select agent type: " numproxy
  if [ "$numproxy" == "1" ]; then
    flag_a="ss"
  elif [ "$numproxy" == "2" ]; then
    flag_a="socks"
  elif [ "$numproxy" == "3" ]; then
    flag_a="http"
  else
    echo "type error, please try again"
    exit
  fi
}
function method() {
  if [ $i -eq 1 ]; then
    if [ "$is_encrypt" == "nonencrypt" ]; then
      echo "        \"tcp://:$s_port/$d_ip:$d_port\",
        \"udp://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "cdnno" ]; then
      echo "        \"tcp://:$s_port/$d_ip?host=$d_port\",
        \"udp://:$s_port/$d_ip?host=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peerno" ]; then
      echo "        \"tcp://:$s_port?ip=/root/$d_ip.txt&strategy=$d_port\",
        \"udp://:$s_port?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "encrypttls" ]; then
      echo "        \"tcp://:$s_port\",
        \"udp://:$s_port\"
    ],
    \"ChainNodes\": [
        \"relay+tls://$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "encryptws" ]; then
      echo "        \"tcp://:$s_port\",
    	\"udp://:$s_port\"
	],
	\"ChainNodes\": [
    	\"relay+ws://$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "encryptwss" ]; then
      echo "        \"tcp://:$s_port\",
		  \"udp://:$s_port\"
	],
	\"ChainNodes\": [
		\"relay+wss://$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peertls" ]; then
      echo "        \"tcp://:$s_port\",
    	\"udp://:$s_port\"
	],
	\"ChainNodes\": [
    	\"relay+tls://:?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peerws" ]; then
      echo "        \"tcp://:$s_port\",
    	\"udp://:$s_port\"
	],
	\"ChainNodes\": [
    	\"relay+ws://:?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peerwss" ]; then
      echo "        \"tcp://:$s_port\",
    	\"udp://:$s_port\"
	],
	\"ChainNodes\": [
    	\"relay+wss://:?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "cdnws" ]; then
      echo "        \"tcp://:$s_port\",
    	\"udp://:$s_port\"
	],
	\"ChainNodes\": [
    	\"relay+ws://$d_ip?host=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "cdnwss" ]; then
      echo "        \"tcp://:$s_port\",
    	\"udp://:$s_port\"
	],
	\"ChainNodes\": [
    	\"relay+wss://$d_ip?host=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "decrypttls" ]; then
      if [ -d "$HOME/gost_cert" ]; then
        echo "        \"relay+tls://:$s_port/$d_ip:$d_port?cert=/root/gost_cert/cert.pem&key=/root/gost_cert/key.pem\"" >>$gost_conf_path
      else
        echo "        \"relay+tls://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
      fi
    elif [ "$is_encrypt" == "decryptws" ]; then
      echo "        \"relay+ws://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "decryptwss" ]; then
      if [ -d "$HOME/gost_cert" ]; then
        echo "        \"relay+wss://:$s_port/$d_ip:$d_port?cert=/root/gost_cert/cert.pem&key=/root/gost_cert/key.pem\"" >>$gost_conf_path
      else
        echo "        \"relay+wss://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
      fi
    elif [ "$is_encrypt" == "ss" ]; then
      echo "        \"ss://$d_ip:$s_port@:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "socks" ]; then
      echo "        \"socks5://$d_ip:$s_port@:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "http" ]; then
      echo "        \"http://$d_ip:$s_port@:$d_port\"" >>$gost_conf_path
    else
      echo "config error"
    fi
  elif [ $i -gt 1 ]; then
    if [ "$is_encrypt" == "nonencrypt" ]; then
      echo "                \"tcp://:$s_port/$d_ip:$d_port\",
                \"udp://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peerno" ]; then
      echo "                \"tcp://:$s_port?ip=/root/$d_ip.txt&strategy=$d_port\",
                \"udp://:$s_port?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "cdnno" ]; then
      echo "                \"tcp://:$s_port/$d_ip?host=$d_port\",
                \"udp://:$s_port/$d_ip?host=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "encrypttls" ]; then
      echo "                \"tcp://:$s_port\",
                \"udp://:$s_port\"
            ],
            \"ChainNodes\": [
                \"relay+tls://$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "encryptws" ]; then
      echo "                \"tcp://:$s_port\",
	            \"udp://:$s_port\"
	        ],
	        \"ChainNodes\": [
	            \"relay+ws://$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "encryptwss" ]; then
      echo "                \"tcp://:$s_port\",
		        \"udp://:$s_port\"
		    ],
		    \"ChainNodes\": [
		        \"relay+wss://$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peertls" ]; then
      echo "                \"tcp://:$s_port\",
                \"udp://:$s_port\"
            ],
            \"ChainNodes\": [
                \"relay+tls://:?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peerws" ]; then
      echo "                \"tcp://:$s_port\",
                \"udp://:$s_port\"
            ],
            \"ChainNodes\": [
                \"relay+ws://:?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "peerwss" ]; then
      echo "                \"tcp://:$s_port\",
                \"udp://:$s_port\"
            ],
            \"ChainNodes\": [
                \"relay+wss://:?ip=/root/$d_ip.txt&strategy=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "cdnws" ]; then
      echo "                \"tcp://:$s_port\",
                \"udp://:$s_port\"
            ],
            \"ChainNodes\": [
                \"relay+ws://$d_ip?host=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "cdnwss" ]; then
      echo "                 \"tcp://:$s_port\",
                \"udp://:$s_port\"
            ],
            \"ChainNodes\": [
                \"relay+wss://$d_ip?host=$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "decrypttls" ]; then
      if [ -d "$HOME/gost_cert" ]; then
        echo "        		  \"relay+tls://:$s_port/$d_ip:$d_port?cert=/root/gost_cert/cert.pem&key=/root/gost_cert/key.pem\"" >>$gost_conf_path
      else
        echo "        		  \"relay+tls://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
      fi
    elif [ "$is_encrypt" == "decryptws" ]; then
      echo "        		  \"relay+ws://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "decryptwss" ]; then
      if [ -d "$HOME/gost_cert" ]; then
        echo "        		  \"relay+wss://:$s_port/$d_ip:$d_port?cert=/root/gost_cert/cert.pem&key=/root/gost_cert/key.pem\"" >>$gost_conf_path
      else
        echo "        		  \"relay+wss://:$s_port/$d_ip:$d_port\"" >>$gost_conf_path
      fi
    elif [ "$is_encrypt" == "ss" ]; then
      echo "        \"ss://$d_ip:$s_port@:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "socks" ]; then
      echo "        \"socks5://$d_ip:$s_port@:$d_port\"" >>$gost_conf_path
    elif [ "$is_encrypt" == "http" ]; then
      echo "        \"http://$d_ip:$s_port@:$d_port\"" >>$gost_conf_path
    else
      echo "config error"
    fi
  else
    echo "config error"
    exit
  fi
}

function writeconf() {
  count_line=$(awk 'END{print NR}' $raw_conf_path)
  for ((i = 1; i <= $count_line; i++)); do
    if [ $i -eq 1 ]; then
      trans_conf=$(sed -n "${i}p" $raw_conf_path)
      eachconf_retrieve
      method
    elif [ $i -gt 1 ]; then
      if [ $i -eq 2 ]; then
        echo "    ],
    \"Routes\": [" >>$gost_conf_path
        trans_conf=$(sed -n "${i}p" $raw_conf_path)
        eachconf_retrieve
        multiconfstart
        method
        multiconflast
      else
        trans_conf=$(sed -n "${i}p" $raw_conf_path)
        eachconf_retrieve
        multiconfstart
        method
        multiconflast
      fi
    fi
  done
}
function show_all_conf() {
  echo -e "                      GOST Configuration                        "
  echo -e "--------------------------------------------------------"
  echo -e "num|method\t    |local port\t|destination IP: destination Port"
  echo -e "--------------------------------------------------------"

  count_line=$(awk 'END{print NR}' $raw_conf_path)
  for ((i = 1; i <= $count_line; i++)); do
    trans_conf=$(sed -n "${i}p" $raw_conf_path)
    eachconf_retrieve

    if [ "$is_encrypt" == "nonencrypt" ]; then
      str="Transfer without encryption"
    elif [ "$is_encrypt" == "encrypttls" ]; then
      str=" tls tunnel "
    elif [ "$is_encrypt" == "encryptws" ]; then
      str="  ws tunnel "
    elif [ "$is_encrypt" == "encryptwss" ]; then
      str=" wss tunnel "
    elif [ "$is_encrypt" == "peerno" ]; then
      str=" Load balancing without encryption "
    elif [ "$is_encrypt" == "peertls" ]; then
      str=" tls tunnel load balancing "
    elif [ "$is_encrypt" == "peerws" ]; then
      str="  ws tunnel load balancing "
    elif [ "$is_encrypt" == "peerwss" ]; then
      str=" wss tunnel load balancing "
    elif [ "$is_encrypt" == "decrypttls" ]; then
      str=" tls decryption "
    elif [ "$is_encrypt" == "decryptws" ]; then
      str="  ws decryption "
    elif [ "$is_encrypt" == "decryptwss" ]; then
      str=" wss decryption "
    elif [ "$is_encrypt" == "ss" ]; then
      str="   ss   "
    elif [ "$is_encrypt" == "socks" ]; then
      str=" socks5 "
    elif [ "$is_encrypt" == "http" ]; then
      str=" http "
    elif [ "$is_encrypt" == "cdnno" ]; then
      str="Forwarding CDN without encryption"
    elif [ "$is_encrypt" == "cdnws" ]; then
      str="ws tunnel forwarding CDN"
    elif [ "$is_encrypt" == "cdnwss" ]; then
      str="wss tunnel forwarding CDN"
    else
      str=""
    fi

    echo -e " $i  |$str  |$s_port\t|$d_ip:$d_port"
    echo -e "--------------------------------------------------------"
  done
}

cron_restart() {
  echo -e "------------------------------------------------------------------"
  echo -e "gost schedule restart task: "
  echo -e "-----------------------------------"
  echo -e "[1] config gost schedule restart task"
  echo -e "[2] delete gost schedule restart task"
  echo -e "-----------------------------------"
  read -p "select: " numcron
  if [ "$numcron" == "1" ]; then
    echo -e "------------------------------------------------------------------"
    echo -e "gost schedule restart task type: "
    echo -e "-----------------------------------"
    echo -e "[1] every ？ hour restart"
    echo -e "[2] every day ？ clock restart"
    echo -e "-----------------------------------"
    read -p "select: " numcrontype
    if [ "$numcrontype" == "1" ]; then
      echo -e "-----------------------------------"
      read -p "every ？ hour restart: " cronhr
      echo "0 0 */$cronhr * * ? * systemctl restart gost" >>/etc/crontab
      echo -e "Scheduled restart setting successful！"
    elif [ "$numcrontype" == "2" ]; then
      echo -e "-----------------------------------"
      read -p "everyday？restart: " cronhr
      echo "0 0 $cronhr * * ? systemctl restart gost" >>/etc/crontab
      echo -e "Scheduled restart setting successful！"
    else
      echo "type error, please try again"
      exit
    fi
  elif [ "$numcron" == "2" ]; then
    sed -i "/gost/d" /etc/crontab
    echo -e "Scheduled restart task deletion completed！"
  else
    echo "type error, please try again"
    exit
  fi
}

update_sh() {
  ol_version=$(curl -L -s --connect-timeout 5 https://raw.githubusercontent.com/ipmartnetwork/Gost/main/Gost3.sh | grep "shell_version=" | head -1 | awk -F '=|"' '{print $3}')
  if [ -n "$ol_version" ]; then
    if [[ "$shell_version" != "$ol_version" ]]; then
      echo -e "There is a new version, update it or not [Y/N]?"
      read -r update_confirm
      case $update_confirm in
      [yY][eE][sS] | [yY])
        wget -N --no-check-certificate https://raw.githubusercontent.com/ipmartnetwork/Gost/main/Gost3.sh
        echo -e "update complete"
        exit 0
        ;;
      *) ;;

      esac
    else
      echo -e "                 ${Green_font_prefix}The current version is the latest version！${Font_color_suffix}"
    fi
  else
    echo -e "                 ${Red_font_prefix}Failed to obtain the latest version of the script, please check the connection to github！${Font_color_suffix}"
  fi
}

update_sh
clear
echo && echo -e "                 gost one key install config script"${Red_font_prefix}[${shell_version}]${Font_color_suffix}"

  Features: 
        (1)This script uses systemd and gost configuration files to manage gost.
        (2)Able to implement multiple forwarding rules to take effect at the same time without using other tools (such as screen)
        (3)The forwarding does not fail after the machine reboots.
  Function: 
        (1) tcp+udp unencrypted forwarding, 
	(2) transit machine encrypted forwarding, 
        (3) landing machine decryption and docking forwarding

 ${Green_font_prefix}1.${Font_color_suffix} install gost
 ${Green_font_prefix}2.${Font_color_suffix} update gost
 ${Green_font_prefix}3.${Font_color_suffix} uninstall gost
————————————
 ${Green_font_prefix}4.${Font_color_suffix} start gost
 ${Green_font_prefix}5.${Font_color_suffix} stop gost
 ${Green_font_prefix}6.${Font_color_suffix} restart gost
————————————
 ${Green_font_prefix}7.${Font_color_suffix} add gost transfer config
 ${Green_font_prefix}8.${Font_color_suffix} list gost configs
 ${Green_font_prefix}9.${Font_color_suffix} delete one gost config
————————————
 ${Green_font_prefix}10.${Font_color_suffix} gost scheduled restart configuration
 ${Green_font_prefix}11.${Font_color_suffix} Custom TLS certificate configuration
————————————" && echo
read -e -p " input number [1-9]:" num
case "$num" in
1)
  Install_ct
  ;;
2)
  checknew
  ;;
3)
  Uninstall_ct
  ;;
4)
  Start_ct
  ;;
5)
  Stop_ct
  ;;
6)
  Restart_ct
  ;;
7)
  rawconf
  rm -rf /etc/gost/config.json
  confstart
  writeconf
  conflast
  systemctl restart gost
  echo -e "The configuration has taken effect. The current configuration is as follows"
  echo -e "--------------------------------------------------------"
  show_all_conf
  ;;
8)
  show_all_conf
  ;;
9)
  show_all_conf
  read -p "Please enter the configuration number you want to delete：" numdelete
  if echo $numdelete | grep -q '[0-11]'; then
    sed -i "${numdelete}d" $raw_conf_path
    rm -rf /etc/gost/config.json
    confstart
    writeconf
    conflast
    systemctl restart gost
    echo -e "The configuration has been deleted and the service has been restarted"
  else
    echo "Please enter the correct number"
  fi
  ;;
10)
  cron_restart
  ;;
11)
  cert
  ;;
*)
  echo "Please enter the correct number [1-11]"
  ;;
esac
