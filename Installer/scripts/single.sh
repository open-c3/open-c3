#!/bin/bash

C3BASEPATH=$( [[ "$(uname -s)" == Darwin ]] && echo "$HOME/open-c3-workspace" || echo "/data" )

BASE_PATH=$C3BASEPATH/open-c3

red()    { echo -e "\033[31m[ERROR] $1\033[0m"; }
green()  { echo -e "\033[32m[ OK  ] $1\033[0m"; }
yellow() { echo -e "\033[33m[INFO ] $1\033[0m"; }

shopt -s expand_aliases

# ----- Detect OS Type -----
unameOut="$(uname -s)"
OS_TYPE="unknown"
case "$unameOut" in
    Linux*)  OS_TYPE=linux;;
    Darwin*) OS_TYPE=macos;;
esac

# ----- Set Base Paths -----
if [[ "$OS_TYPE" == "macos" ]]; then
    C3BASEPATH="$HOME/open-c3-workspace"
else
    C3BASEPATH="/data"
fi
BASE_PATH="$C3BASEPATH/open-c3"

# ----- Detect Linux Distribution -----
DISTRO="unknown"
if [[ "$OS_TYPE" == "linux" ]]; then
    if grep -q 'CentOS' /etc/os-release; then DISTRO=centos
    elif grep -q 'Ubuntu' /etc/os-release; then DISTRO=ubuntu
    elif grep -q 'Deepin' /etc/os-release; then DISTRO=deepin
    fi
elif [[ "$OS_TYPE" == "macos" ]]; then
    DISTRO=macos
fi

if [[ "$DISTRO" == "unknown" ]]; then
    red "Unsupported system."
    exit 1
fi
yellow "Current OS detected: $DISTRO"

# ----- Alias Definitions -----
case "$DISTRO" in
    centos)
        alias c3sed='sed -i'
        alias c3xargs='xargs -i{}'
        alias c3pkginstall='yum install -y'
        alias c3-docker-compose="$BASE_PATH/Installer/docker-compose"
        ;;
    ubuntu|deepin)
        alias c3sed='sed -i'
        alias c3xargs='xargs -i{}'
        alias c3pkginstall='apt-get install -y'
        alias c3-docker-compose="$BASE_PATH/Installer/docker-compose"
        ;;
    macos)
        alias c3sed='sed -i ""'
        alias c3xargs='xargs -I{}'
        alias c3pkginstall='brew install'
        alias c3-docker-compose='docker-compose'
        ;;
    *)
        red "System alias setup failed."
        exit 1
        ;;
esac

if docker compose version >/dev/null 2>&1; then
    c3-docker-compose="docker compose"
fi

if [ "X$OPENC3VERSION" == "X" ]; then
    OPENC3VERSION=v2.6.1
fi

MASTERVERSION=$(echo $OPENC3VERSION | awk -F- '{print $1}')

GITADDR=http://github.com
DOCKERINSTALL=https://get.docker.com
if [ "X$OPENC3_ZONE" == "XCN"  ]; then
    GITADDR=http://gitee.com
    DOCKERINSTALL=https://get.daocloud.io/docker
fi

function install() {
    # ----- Ensure git Installed -----
    echo "================================================================="
    yellow "Checking git ..."
    if ! command -v git &>/dev/null; then
        yellow "Git not found. Installing ..."
        c3pkginstall git
    fi
    
    if command -v git &>/dev/null; then
        green "Git is installed."
    else
        red "Failed to install git."
        exit 1
    fi
    
    # ----- Ensure docker Installed -----
    echo "================================================================="
    yellow "Checking docker ..."
    if ! command -v docker &>/dev/null; then
        yellow "Docker not found. Installing ..."
        curl -fsSL $DOCKERINSTALL | bash
    fi
    
    if command -v docker &>/dev/null; then
        green "Docker is installed."
    else
        red "Failed to install docker."
        exit 1
    fi

    # ----- Ensure docker Installed -----
    echo "================================================================="
    yellow "Checking docker ..."
    
    if [[ "$OS_TYPE" == "linux" ]]; then
        if ! command -v docker &>/dev/null; then
            yellow "Docker not found. Installing ..."
            curl -fsSL $DOCKERINSTALL | bash
        fi
    
        if command -v docker &>/dev/null; then
            green "Docker is installed."
        else
            red "Failed to install docker."
            exit 1
        fi
    
        echo "================================================================="
        yellow "Starting Docker service ..."
        docker ps &>/dev/null || service docker start
    
        if docker ps &>/dev/null; then
            green "Docker service started."
        else
            red "Failed to start Docker service."
            exit 1
        fi
    
        echo "================================================================="
        yellow "Enabling Docker service at boot ..."
        systemctl enable docker.service
        if [[ $? -eq 0 ]]; then
            green "Docker service enabled."
        else
            red "Failed to enable Docker service."
            exit 1
        fi
    else
        if command -v docker &>/dev/null; then
            green "Docker is installed (macOS)."
        else
            red "Docker is not installed. Please install Docker Desktop manually on macOS."
            exit 1
        fi
    fi
    
    echo "================================================================="
    yellow "Fetching Open-C3 source code ..."
    
    # 创建主目录
    if [[ ! -d "$C3BASEPATH" ]]; then
        yellow "Creating base directory: $C3BASEPATH"
        mkdir -p "$C3BASEPATH"
    fi
    
    cd "$C3BASEPATH" || { red "Failed to enter $C3BASEPATH"; exit 1; }
    
    # 如果 open-c3 尚未存在，则尝试本地复制或远程 clone
    if [[ ! -d "$BASE_PATH" ]]; then
        yellow "Cloning open-c3 from $GITADDR ..."
        git clone -b "$OPENC3VERSION" "$GITADDR/open-c3/open-c3"
    fi
    
    # 检查最终是否成功获取 open-c3
    if [[ -d "$BASE_PATH" ]]; then
        green "Successfully acquired open-c3."
    else
        red "Failed to acquire open-c3 source code."
        exit 1
    fi

    cd "$BASE_PATH" || { red "Failed to enter $BASE_PATH"; exit 1; }

    echo "================================================================="
    yellow "Extracting Open-C3 package files ..."
    
    EXTRACT_SCRIPT="$C3BASEPATH/open-c3/Installer/C3/pkg/extract.sh"
    
    if [[ -x "$EXTRACT_SCRIPT" ]]; then
        "$EXTRACT_SCRIPT" > /dev/null
        if [[ $? -eq 0 ]]; then
            green "Package extract succeeded."
        else
            red "Package extract failed during execution."
            exit 1
        fi
    else
        red "Package extract script not found or not executable: $EXTRACT_SCRIPT"
        exit 1
    fi

    echo "================================================================="
    yellow "Creating .env file for Open-C3 ..."
    
    MYIP="$1"
    [[ -z "$MYIP" ]] && MYIP="10.10.10.10"  # default IP
    
    # 验证 IP 格式
    if [[ "$MYIP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        RANDOM_STR="$(od -vAn -N16 -tx1 </dev/urandom | tr -d ' \n')"
        NAME="${OPEN_C3_NAME:-test}"
        ENV_FILE="$BASE_PATH/Installer/C3/.env"
    
        mkdir -p "$(dirname "$ENV_FILE")"
    
        {
            echo "OPEN_C3_RANDOM=$RANDOM_STR"
            echo "OPEN_C3_EXIP=$MYIP"
            echo "OPEN_C3_NAME=$NAME"
        } > "$ENV_FILE"
    
        if [[ -f "$ENV_FILE" ]]; then
            green "Created .env file at: $ENV_FILE"
        else
            red "Failed to create .env file at: $ENV_FILE"
            exit 1
        fi
    else
        red "Invalid IP format: $MYIP"
        echo "Usage: $0 install <your_ip>, e.g., $0 install 10.10.10.10"
        exit 1
    fi

    echo "================================================================="
    yellow "Creating Connector/config.ini/current ..."
    
    CONFIG_SRC="$BASE_PATH/Connector/config.ini/openc3"
    CONFIG_DST="$BASE_PATH/Connector/config.ini/current"
    
    mkdir -p "$(dirname "$CONFIG_DST")"
    
    if [[ ! -f "$CONFIG_DST" ]]; then
        cp "$CONFIG_SRC" "$CONFIG_DST"
    fi
    
    if [[ -f "$CONFIG_DST" ]]; then
        green "Created config: $CONFIG_DST"
    else
        red "Failed to create config: $CONFIG_DST"
        exit 1
    fi

    echo "================================================================="
    yellow "Creating c3-front/dist ..."
    
    INSTALL_CACHE="$BASE_PATH/Installer/install-cache/c3-front"
    DIST_TARGET="$BASE_PATH/c3-front/dist"
    
    mkdir -p "$(dirname "$DIST_TARGET")"
    rm -rf "$DIST_TARGET"
    
    if [[ -d "$INSTALL_CACHE/dist-$MASTERVERSION" ]]; then
        cp -r "$INSTALL_CACHE/dist-$MASTERVERSION" "$DIST_TARGET"
    elif [[ -d "$INSTALL_CACHE/dist" ]]; then
        yellow "Fallback: dist-$MASTERVERSION not found, using dist instead."
        cp -r "$INSTALL_CACHE/dist" "$DIST_TARGET"
    else
        red "No valid dist found in install cache."
    fi
    
    if [[ -d "$DIST_TARGET" ]]; then
        green "Created $DIST_TARGET successfully."
    else
        red "Failed to create $DIST_TARGET."
        exit 1
    fi

    echo "================================================================="
    yellow "Creating c3-front/dist/book ..."
    
    BOOK_SOURCE="$BASE_PATH/Connector/pkg/book/"
    BOOK_TARGET="$BASE_PATH/c3-front/dist/book"
    
    if [[ -d "$BOOK_SOURCE" ]]; then
        rsync -a --delete "$BOOK_SOURCE" "$BOOK_TARGET"
    else
        red "Source directory not found: $BOOK_SOURCE"
        exit 1
    fi
    
    if [[ -d "$BOOK_TARGET" ]]; then
        green "Created $BOOK_TARGET successfully."
    else
        red "Failed to create $BOOK_TARGET."
        exit 1
    fi

    echo "================================================================="
    yellow "Creating web-shell/node_modules ..."
    
    NODE_SOURCE="$BASE_PATH/Installer/install-cache/web-shell/node_modules"
    NODE_TARGET="$BASE_PATH/web-shell/node_modules"
    
    if [[ -d "$NODE_SOURCE" ]]; then
        rsync -a --delete "$NODE_SOURCE/" "$NODE_TARGET/"
    else
        red "Not found: $NODE_SOURCE"
    fi
    
    if [[ -d "$NODE_TARGET" ]]; then
        green "Created $NODE_TARGET successfully."
    else
        red "Failed to create $NODE_TARGET."
        exit 1
    fi

    echo "================================================================="
    yellow "Creating Installer/C3/mysql/init/init.sql ..."
    
    INIT_DIR="$BASE_PATH/Installer/C3/mysql/init"
    INIT_SQL="$INIT_DIR/init.sql"
    INSTALLER_SQL="$BASE_PATH/Installer/C3/mysql/init.sql"
    
    mkdir -p "$INIT_DIR"
    : > "$INIT_SQL"  # 清空或新建 init.sql
    
    # 合并所有 schema.sql
    find "$BASE_PATH" -type f -name "schema.sql" -exec cat {} + >> "$INIT_SQL"
    
    # 合并附加 SQL 文件
    if [[ -f "$INSTALLER_SQL" ]]; then
        cat "$INSTALLER_SQL" >> "$INIT_SQL"
    fi
    
    # 检查是否成功创建
    if [[ -f "$INIT_SQL" ]]; then
        green "Created $INIT_SQL successfully."
    else
        red "Failed to create $INIT_SQL."
        exit 1
    fi

    echo "================================================================="
    yellow "Getting MYDan ..."
    
    MYDAN_DIR="$BASE_PATH/MYDan"
    INSTALL_CACHE="$BASE_PATH/Installer/install-cache/MYDan"
    
    mkdir -p "$MYDAN_DIR"
    rm -rf "$MYDAN_DIR/repo"
    
    if [[ -d "$INSTALL_CACHE" ]]; then
        yellow "Found MYDan in install-cache. Syncing ..."
        rsync -a "$INSTALL_CACHE/" "$MYDAN_DIR/"
        if [[ $? -eq 0 ]]; then
            green "MYDan synced from install-cache successfully."
        else
            red "Failed to sync MYDan from install-cache."
            exit 1
        fi
    else
        yellow "MYDan not found in install-cache. Cloning from GitHub ..."
        if git clone https://github.com/MYDan/repo "$MYDAN_DIR/repo"; then
            green "MYDan cloned successfully."
        else
            red "Failed to clone MYDan."
            exit 1
        fi
    fi

    echo "================================================================="
    yellow "Syncing MYDan/repo ..."
    
    INSTALL_CACHE_MYDan="$BASE_PATH/Installer/install-cache/MYDan"
    MYDan_REPO_SCRIPTS="$BASE_PATH/MYDan/repo/scripts"
    
    if [[ -d "$INSTALL_CACHE_MYDan" ]]; then
        yellow "MYDan install-cache exists, skipping sync."
    else
        if [[ -d "$MYDan_REPO_SCRIPTS" ]]; then
            cd "$MYDan_REPO_SCRIPTS"
            SYNC_MYDan_VERSION=20201213220001:10108f7303adc9992db663bfd99ddf1b ./sync.sh
            ret=$?
            cd "$BASE_PATH"
            if [[ $ret -eq 0 ]]; then
                green "MYDan/repo sync succeeded."
            else
                red "MYDan/repo sync failed."
                exit 1
            fi
        else
            red "MYDan repo scripts directory not found: $MYDan_REPO_SCRIPTS"
            exit 1
        fi
    fi

    echo "================================================================="
    yellow "Building tt-front ..."
    
    mkdir -p "$C3BASEPATH/open-c3/c3-front/dist/tt"
    
    rsync -a --delete \
        "$C3BASEPATH/open-c3/Installer/install-cache/trouble-ticketing/tt-front/dist/" \
        "$C3BASEPATH/open-c3/c3-front/dist/tt/"
    
    rsync -a \
        "$C3BASEPATH/open-c3/Connector/tt/tt-front/src/assets/images/" \
        "$C3BASEPATH/open-c3/c3-front/dist/assets/images/"
    
    if [ $? -eq 0 ]; then
        green "tt-front build success."
    else
        red "tt-front build fail."
        exit 1
    fi

    echo "================================================================="
    yellow "Copy trouble-ticketing ..."
    
    COOKIEKEY=$(grep -v '^\s*#' "$C3BASEPATH/open-c3/Connector/config.inix" | grep 'cookiekey:' | awk '{print $2}' | grep -E '^[a-zA-Z0-9]+$')
    if [[ -z "$COOKIEKEY" ]]; then
        echo "[FAIL] failed to extract COOKIEKEY."
        exit 1
    fi
    
    c3sed "s/\"cookiekey\":\".*\"/\"cookiekey\":\"$COOKIEKEY\"/g" "$C3BASEPATH/open-c3/Connector/tt/trouble-ticketing/cfg.json"
    
    cp "$C3BASEPATH/open-c3/Connector/pkg/trouble-ticketing" "$C3BASEPATH/open-c3/Connector/tt/trouble-ticketing/trouble-ticketing.$$"
    mv "$C3BASEPATH/open-c3/Connector/tt/trouble-ticketing/trouble-ticketing.$$" "$C3BASEPATH/open-c3/Connector/tt/trouble-ticketing/trouble-ticketing"
    chmod +x "$C3BASEPATH/open-c3/Connector/tt/trouble-ticketing/trouble-ticketing"
    
    if [ $? -eq 0 ]; then
        green "copy trouble-ticketing success."
    else
        red "copy trouble-ticketing fail."
        exit 1
    fi

    echo =================================================================
    yellow "copy node_exporter to Agent.Mon ..."
    
    NODE_EXPORTER_SRC="$BASE_PATH/Installer/install-cache/node_exporter"
    NODE_EXPORTER_DST="$BASE_PATH/AGENT/agent.mon/data/node_exporter"
    
    if [[ -d "$NODE_EXPORTER_SRC" ]]; then
        rsync -a "$NODE_EXPORTER_SRC/" "$NODE_EXPORTER_DST/"
        if [[ $? -eq 0 ]]; then
            green "copy node_exporter to Agent.Mon success."
        else
            red "rsync node_exporter to Agent.Mon fail."
            exit 1
        fi
    else
        red "source node_exporter not found at $NODE_EXPORTER_SRC"
        exit 1
    fi

    echo "================================================================="
    yellow "Run front-end build script ..."
    
    if bash "$C3BASEPATH/open-c3/Installer/scripts/dev.sh" build >/dev/null ; then
        green "Front-end build success."
    else
        red "Front-end build fail."
        exit 1
    fi

    echo =================================================================
    yellow "init grafana-data ..."
    
    GRAFANA_DATA_SRC="$C3BASEPATH/open-c3/Installer/install-cache/grafana-data"
    GRAFANA_DATA_DST="$C3BASEPATH/open-c3-data/grafana-data"
    
    mkdir -p "$GRAFANA_DATA_DST"
    
    if [[ -d "$GRAFANA_DATA_SRC" ]]; then
        rsync -a "$GRAFANA_DATA_SRC/" "$GRAFANA_DATA_DST/"
        if [[ $? -eq 0 ]]; then
            green "init grafana-data success."
        else
            red "rsync grafana-data fail."
            exit 1
        fi
    else
        echo "[FAIL]source grafana-data not found at $GRAFANA_DATA_SRC"
        exit 1
    fi

    echo =================================================================
    yellow "golang build ..."
    
    find "$C3BASEPATH/open-c3/Connector/pp" -name golang-build.sh \
        | sed "s/\/golang-build.sh$//" \
        | c3xargs bash -c 'echo "golang build {}" && cd {} && ./golang-build.sh'
    
    if [[ $? -eq 0 ]]; then
        green "golang build success."
    else
        red "golang build fail."
        exit 1
    fi

    echo "================================================================="
    yellow "To start the Open-C3 service, run the following command:"
    $C3BASEPATH/open-c3/open-c3.sh start
    if [ $? -eq 0 ]; then
        green "start successfully."
    else
        red "[FAIL] start error."
        exit 1
    fi

#    echo "[INFO] To update the Open-C3 system, run:"
#    echo "       $C3BASEPATH/open-c3/open-c3.sh sup"
#    $C3BASEPATH/open-c3/open-c3.sh sup >/dev/null
#    echo "[INFO] To update the Open-C3 system, run:"
#    echo "       $C3BASEPATH/open-c3/open-c3.sh dup"
#    $C3BASEPATH/open-c3/open-c3.sh dup >/dev/null
#    echo "[INFO] To restart the Open-C3 system:"
#    docker exec openc3-server /data/Software/mydan/Connector/app/c3-restart >/dev/null

    echo =================================================================
    yellow "run version-specific script ..."
    
    SCRIPT="$BASE_PATH/Installer/scripts/single/$MASTERVERSION.sh" 
    
    if [[ -x "$SCRIPT" ]]; then
        "$SCRIPT" >/dev/null
        if [[ $? -eq 0 ]]; then
            green "run $SCRIPT success."
        else
            red "run $SCRIPT fail."
            exit 1
        fi
    else
        echo "No version-specific script found at $SCRIPT, skipping."
    fi

    echo =================================================================
    yellow "agent build ..."
    
    docker exec openc3-server /data/Software/mydan/AGENT/tools/Build >/dev/null
    
    if [[ $? -eq 0 ]]; then
        green "agent build success."
    else
        red "agent build fail."
        exit 1
    fi

    echo "================================================================="
    green "Open-C3 installed successfully."
    yellow "Web page: http://your-openc3-ip/"
    yellow "Username: open-c3"
    yellow "Password: changeme"
}

function start() {
    echo =================================================================
    yellow "start ..."

    DCF=docker-compose.yml
    if [ -f "Connector/mysql.config-test" ]; then
        DCF=docker-compose-nomysql.yml
    fi

    if [ -f "Installer/C3/docker-compose-private.yml" ]; then
        DCF=docker-compose-private.yml
    fi

    #prometheus

    mkdir -p $C3BASEPATH/open-c3-data/prometheus-data
    chmod 777 $C3BASEPATH/open-c3-data/prometheus-data

    if [ ! -f $C3BASEPATH/open-c3/prometheus/config/prometheus.yml ];then
        cp $C3BASEPATH/open-c3/prometheus/config/prometheus.example.yml $C3BASEPATH/open-c3/prometheus/config/prometheus.yml
    fi

    if [ ! -f $C3BASEPATH/open-c3/prometheus/config/openc3_node_sd.yml ];then
        cp $C3BASEPATH/open-c3/prometheus/config/openc3_node_sd.example.yml $C3BASEPATH/open-c3/prometheus/config/openc3_node_sd.yml
    fi

    #alertmanager

    if [ ! -f $C3BASEPATH/open-c3/alertmanager/config/alertmanager.yml ];then
        cp $C3BASEPATH/open-c3/alertmanager/config/alertmanager.example.yml $C3BASEPATH/open-c3/alertmanager/config/alertmanager.yml
    fi

    #lua.1
    mkdir -p $C3BASEPATH/open-c3/lua/lualib
    rsync -av $C3BASEPATH/open-c3/Installer/install-cache/lualib/ $C3BASEPATH/open-c3/lua/lualib/
    #

    cd $BASE_PATH/Installer/C3/ && c3-docker-compose -f $DCF up -d --build

    #grafana

    docker cp $C3BASEPATH/open-c3/grafana/config/grafana.ini openc3-grafana:/etc/grafana/grafana.ini
    docker restart openc3-grafana

    docker cp $C3BASEPATH/open-c3/grafana/config/grafana-fresh.ini openc3-grafana-fresh:/etc/grafana/grafana.ini
    docker restart openc3-grafana-fresh

    #lua

    cp $C3BASEPATH/open-c3/lua/config/lua/sso.example.lua $C3BASEPATH/open-c3/lua/config/lua/sso.temp.lua
    #OPENC3 TODO 这里ip替换域名是lua解析容器中的域名失败
#    REIP=$(docker exec -it openc3-lua ping -c 1 OPENC3_SERVER_IP|grep openc3-server.c3_JobNet|awk -F '[()]' '{print $2}'|grep ^[0-9\.]*$|tail -n 1 )
    COOKIEKEY=$(cat $C3BASEPATH/open-c3/Connector/config.inix | grep -v '^ *#' | grep cookiekey:|awk '{print $2}'|grep ^[a-zA-Z0-9]*$)
#    c3sed "s/OPENC3_SERVER_IP/$REIP/" $C3BASEPATH/open-c3/lua/config/lua/sso.temp.lua
    c3sed "s/ngx.var.cookie_sid/ngx.var.cookie_$COOKIEKEY/g" $C3BASEPATH/open-c3/lua/config/lua/sso.temp.lua

    cp $C3BASEPATH/open-c3/lua/config/lua/sso.temp.lua $C3BASEPATH/open-c3/lua/config/lua/sso.lua

    docker restart  openc3-lua

    docker exec -t openc3-server bash -c "test -f /etc/c3mc-sys-sup.txt || /data/Software/mydan/Connector/pp/c3mc-sys-sup"
#
    green "started."
}

function stop() {
    echo =================================================================
    yellow "stop ..."

    cd $BASE_PATH/Installer/C3/ && c3-docker-compose kill

    green "stoped."
}

function restart() {
    echo =================================================================
    green "restart ..."
    Date=$(date "+%F %H:%M:%S")
    echo "#$Date restart" >> $BASE_PATH/Connector/config.ini/current 

    green "The operation is complete and the service will restart in a few seconds."
}

function reload() {
    echo =================================================================
    green "reload ..."
    Date=$(date "+%F %H:%M:%S")
    echo "#$Date reload" >> $BASE_PATH/Connector/config.ini/current 

    green "The operation is complete and the service will reload in a few seconds."
}

function check() {
    module=$1
    X=$(curl localhost/api/$module/mon 2>/dev/null)
    if [ "X$X" = "Xok" ]; then
        green "module $module up."
    else
        red "module $module down."
    fi
}

function status() {
    echo =================================================================
    check connector
    check agent
    check job
    check jobx
    check ci
}

function inx() {
    docker exec -it openc3-server env LANG=C.UTF-8 LC_ALL=C bash
}

function app() {
    docker exec -it openc3-server env LANG=C.UTF-8 LC_ALL=C /data/Software/mydan/Connector/pp/c3mc-app
}

function sql() {
    docker exec -it openc3-mysql env LANG=C.UTF-8 mysql -uroot -popenc3123456^!
}

function log() {
    docker logs -f openc3-server
}

function dup() {
    docker exec -t openc3-server /data/Software/mydan/Connector/pp/c3mc-sys-dup
}

function sup() {
    docker exec -t openc3-server /data/Software/mydan/Connector/pp/c3mc-sys-sup
}

function cmdbdemo() {
    $C3BASEPATH/open-c3/Installer/scripts/cmdb-demo.sh
}

OPENC3_ZONE_CHECK=$(cat $C3BASEPATH/open-c3/.git/config |grep gitee.com/open-c3/open-c3|wc -l)
if [ "X$OPENC3_ZONE_CHECK" == "X1" ];then
    export OPENC3_ZONE=CN
fi

case "$1" in
install) install $2 ;;
rebuild) stop && start ;;
reborn)
    $BASE_PATH/Installer/scripts/databasectrl.sh backup
    $BASE_PATH/Installer/scripts/upgrade.sh
    stop && start
    $BASE_PATH/Installer/scripts/upgrade.sh
    ;;
upgrade)

    cd $BASE_PATH || exit 1

    echo =================================================================
    yellow "git pull ..."

    git pull

    if [ $? = 0 ]; then
        green "[SUCC]git pull success."
    else
        red "[FAIL]git pull fail."
        exit 1
    fi

    $BASE_PATH/Installer/scripts/upgrade.sh $2 $3
    ;;
switchversion)
    if [ "X$2" = "X" ];then
        echo "$0 switchversion vx.x.x";
        exit 1;
    fi
    $BASE_PATH/Installer/scripts/versionctrl.sh list
    $BASE_PATH/Installer/scripts/versionctrl.sh switch $2
    ;;
start) start ;;
stop) stop ;;
status) status ;;
restart) restart ;;
reload) reload ;;
inx) inx ;;
app) app ;;
sql) sql ;;
log) log ;;
dup) dup ;;
sup) sup ;;
cmdbdemo) cmdbdemo ;;
*)
    echo "Usage: $0 {start|stop|status|restart|reload|install|rebuild|reborn|upgrade|switchversion|inx|app|sql|log|dup|sup|cmdbdemo}"
    echo "$0 install 10.10.10.10(Your Internet IP)"
    exit 2
esac
