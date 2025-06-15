#!/bin/bash

C3BASEPATH=$( [[ "$(uname -s)" == Darwin ]] && echo "$HOME/open-c3-workspace" || echo "/data" )

BASE_PATH=$C3BASEPATH/open-c3

###
shopt -s expand_aliases

CurrOS=Unknown
unameOutput=$(uname -s)
case "${unameOutput}" in
    Linux*)
        if grep -q 'CentOS' /etc/os-release; then
            CurrOS=CentOS
        elif grep -q 'Ubuntu' /etc/os-release; then
            CurrOS=Ubuntu
        elif grep -q 'Deepin' /etc/os-release; then
            CurrOS=Deepin
        fi
        ;;
    Darwin*)
        CurrOS=macOS
        ;;
    *)
        CurrOS=Unknown
        ;;
esac

test "X$1" == "Xinstall" && echo CurrOS: $CurrOS

test $CurrOS == "Unknown" && exit 1

if [ "$CurrOS" == "macOS" ]; then
    alias c3sed='sed -i ""'
    alias c3xargs='xargs -I{}'
    alias c3pkginstall='brew'

    alias c3-docker-compose="docker-compose"
    C3BASEPATH=$HOME/open-c3-workspace

elif [ "$CurrOS" == "CentOS" ]; then
    alias c3sed='sed -i'
    alias c3xargs='xargs -i{}'
    alias c3pkginstall='yum'

    alias c3-docker-compose="$C3BASEPATH/open-c3/Installer/docker-compose"

else
    alias c3sed='sed -i'
    alias c3xargs='xargs -i{}'
    alias c3pkginstall='apt-get'

    alias c3-docker-compose="$C3BASEPATH/open-c3/Installer/docker-compose"
fi

###

if [ "X$OPENC3VERSION" == "X" ]; then
    OPENC3VERSION=v2.2.0
fi

MASTERVERSION=$(echo $OPENC3VERSION | awk -F- '{print $1}')

GITADDR=http://github.com
DOCKERINSTALL=https://get.docker.com
if [ "X$OPENC3_ZONE" == "XCN"  ]; then
    GITADDR=http://gitee.com
    DOCKERINSTALL=https://get.daocloud.io/docker
fi

function install() {
    echo =================================================================
    echo "[INFO]install git ..."

    git --help 1>/dev/null 2>&1 || c3pkginstall install git -y
    git --help 1>/dev/null 2>&1
    if [ $? = 0 ]; then
        echo "[SUCC]git installed."
    else
        echo "[FAIL]install git fail."
        exit 1
    fi


    if [[ $CurrOS == "CentOS" || $CurrOS == "Ubuntu" || $CurrOS == "Deepin" ]]; then

        echo =================================================================
        echo "[INFO]install docker ..."

        docker --help 1>/dev/null 2>&1 || curl -fsSL $DOCKERINSTALL | bash
        docker --help 1>/dev/null 2>&1
        if [ $? = 0 ]; then
            echo "[SUCC]docker installed."
        else
            echo "[FAIL]install docker fail."
            exit 1
        fi

        echo =================================================================
        echo "[INFO]start docker ..."
        docker ps 1>/dev/null 2>&1 || service docker start
        docker ps 1>/dev/null 2>&1
        if [ $? = 0 ]; then
            echo "[SUCC]docker is started."
        else
            echo "[FAIL]start docker fail."
            exit 1
        fi

        echo =================================================================
        echo "[INFO]enable docker.service ..."
        systemctl enable docker.service
        if [ $? = 0 ]; then
            echo "[SUCC]enable docker.service success."
        else
            echo "[FAIL]enable docker.service fail."
            exit 1
        fi

    fi

    echo =================================================================
    echo "[INFO]get open-c3 ..."
    if [ ! -d $BASE_PATH ]; then
        if [ ! -d $C3BASEPATH ];then
            mkdir $C3BASEPATH
        fi
        if [ -d $C3BASEPATH/open-c3-installer/open-c3 ];then
            cd $C3BASEPATH && cp -r $C3BASEPATH/open-c3-installer/open-c3 .
        else
            cd $C3BASEPATH && git clone -b "$OPENC3VERSION" $GITADDR/open-c3/open-c3
        fi
    fi

    if [ -d "$BASE_PATH" ]; then
        echo "[SUCC]get open-c3 success."
    else
        echo "[FAIL]get open-c3 fail."
        exit 1
    fi

    cd $BASE_PATH || exit 1

    echo =================================================================
    echo "[INFO]pkg extract ..."

    $C3BASEPATH/open-c3/Installer/C3/pkg/extract.sh

    if [ $? = 0 ]; then
        echo "[SUCC]pkg extract success."
    else
        echo "[FAIL]pkg extract fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]create Installer/C3/.env"

    MYIP=$1
    if [ "X$MYIP" == "X" ]; then
       MYIP=10.10.10.10 #default
    fi
    if [ "X$MYIP" != "X" ]; then
        echo $MYIP |grep "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$" > /dev/null
        if [ $? = 0 ]; then
            random=$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM
            name="test"
            if [ "X$OPEN_C3_NAME" != "X" ];then
                name=$OPEN_C3_NAME
            fi
            echo "OPEN_C3_RANDOM=$random" > $BASE_PATH/Installer/C3/.env
            echo "OPEN_C3_EXIP=$MYIP"    >> $BASE_PATH/Installer/C3/.env
            echo "OPEN_C3_NAME=$name"    >> $BASE_PATH/Installer/C3/.env
        else
            echo "$0 install 10.10.10.10(Your Internet IP)"
            exit 1
        fi
    else
        echo "$0 install 10.10.10.10(Your Internet IP)"
        exit 1
    fi

    if [ -f "$BASE_PATH/Installer/C3/.env" ]; then
        echo "[SUCC]create $BASE_PATH/Installer/C3/.env success."
    else
        echo "[FAIL]create $BASE_PATH/Installer/C3/.env fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]create Connector/config.ini/current ..."

    if [ ! -f $BASE_PATH/Connector/config.ini/current ];then
        cp $BASE_PATH/Connector/config.ini/openc3 $BASE_PATH/Connector/config.ini/current
    fi

    if [ -f "$BASE_PATH/Connector/config.ini/current" ]; then
        echo "[SUCC]create Connector/config.ini/current success."
    else
        echo "[FAIL]create Connector/config.ini/current fail."
        exit 1
    fi

#    echo =================================================================
#    echo "[INFO]get open-c3-install-cache ..."
#
#    if [ ! -d "$BASE_PATH/Installer/install-cache" ]; then
#        if [ -d $C3BASEPATH/open-c3-installer/install-cache ];then
#            cd $BASE_PATH/Installer && cp -r $C3BASEPATH/open-c3-installer/install-cache .
#        else
#            cd $BASE_PATH/Installer && git clone $GITADDR/open-c3/open-c3-install-cache install-cache
#        fi
#        cd $BASE_PATH
#    fi
#
#    if [ -d "$BASE_PATH/Installer/install-cache" ]; then
#        echo "[SUCC]get open-c3-install-cache success."
#    else
#        echo "[FAIL]get open-c3-install-cache fail."
#        exit 1
#    fi

    echo =================================================================
    echo "[INFO]create c3-front/dist ..."

    if [ -d "$BASE_PATH/Installer/install-cache/c3-front/dist-$MASTERVERSION" ]; then
        rm -rf $BASE_PATH/c3-front/dist
        cp -r "$BASE_PATH/Installer/install-cache/c3-front/dist-$MASTERVERSION" $BASE_PATH/c3-front/dist
    else
        echo "[Warn]nofind c3-front/dist-$MASTERVERSION in open-c3-install-cache."

        if [ -d "$BASE_PATH/Installer/install-cache/c3-front/dist" ]; then
            rm -rf $BASE_PATH/c3-front/dist
            cp -r "$BASE_PATH/Installer/install-cache/c3-front/dist" $BASE_PATH/c3-front/dist
        else
            echo "[FAIL]nofind c3-front/dist in open-c3-install-cache."
        fi
    fi

    if [ -d "$BASE_PATH/c3-front/dist" ]; then
        echo "[SUCC]create c3-front/dist success."
    else
        echo "[FAIL]create c3-front/dist fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]create c3-front/dist/book ..."

    rm -rf $BASE_PATH/c3-front/dist/book

    if [ -d $C3BASEPATH/open-c3-installer/book ]; then
        cp -r $C3BASEPATH/open-c3-installer/book $BASE_PATH/c3-front/dist/book
    else
        cd $BASE_PATH/c3-front/dist && git clone $GITADDR/open-c3/open-c3.github.io book
    fi

    if [ -d "$BASE_PATH/c3-front/dist/book" ]; then
        echo "[SUCC]create c3-front/dist/book success."
    else
        echo "[FAIL]create c3-front/dist/book fail."
        exit 1
    fi

    cd $BASE_PATH || exit 1

    echo =================================================================
    echo "[INFO]create web-shell/node_modules ..."

    if [ -d "$BASE_PATH/Installer/install-cache/web-shell/node_modules" ]; then
        rm -rf $BASE_PATH/web-shell/node_modules
        cp -r $BASE_PATH/Installer/install-cache/web-shell/node_modules $BASE_PATH/web-shell/node_modules
    else
        echo "[FAIL]nofind web-shell/node_modules in open-c3-install-cache."
    fi

    if [ -d "$BASE_PATH/web-shell/node_modules" ]; then
        echo "[SUCC]create web-shell/node_modules success."
    else
        echo "[FAIL]create web-shell/node_modules fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]create Installer/C3/mysql/init/init.sql ..."

    cat $BASE_PATH/*/schema.sql > $BASE_PATH/Installer/C3/mysql/init/init.sql
    cat $BASE_PATH/Installer/C3/mysql/init.sql >> $BASE_PATH/Installer/C3/mysql/init/init.sql

    if [ -f "$BASE_PATH/Installer/C3/mysql/init/init.sql" ]; then
        echo "[SUCC]create Installer/C3/mysql/init/init.sql success."
    else
        echo "[FAIL]create Installer/C3/mysql/init/init.sql fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]get MYDan ..."

    mkdir -p $BASE_PATH/MYDan
    rm -rf $BASE_PATH/MYDan/repo

    if [ -d "$BASE_PATH/Installer/install-cache/MYDan" ]; then
        rsync -av $BASE_PATH/Installer/install-cache/MYDan/ $BASE_PATH/MYDan/
        if [ $? = 0 ]; then
            echo "[SUCC]rsync MYDan from install-cache success."
        else
            echo "[FAIL]rsync MYDan from install-cache fail."
            exit 1
        fi
    else
        cd $BASE_PATH/MYDan && git clone https://github.com/MYDan/repo
        cd $BASE_PATH

        if [ -d "$BASE_PATH/MYDan/repo" ]; then
            echo "[SUCC]get MYDan success."
        else
            echo "[FAIL]get MYDan fail."
            exit 1
        fi

    fi

    echo =================================================================
    echo "[INFO]sync MYDan/repo ..."

    if [ -d "$BASE_PATH/Installer/install-cache/MYDan" ]; then
        echo "[INFO]rsync MYDan from install-cache done. skip"
    else
        cd $BASE_PATH/MYDan/repo/scripts && SYNC_MYDan_VERSION=20201213220001:10108f7303adc9992db663bfd99ddf1b ./sync.sh
        cd $BASE_PATH

        if [ $? = 0 ]; then
            echo "[SUCC]sync MYDan/repo success."
        else
            echo "[FAIL]sync MYDan/repo fail."
            exit 1
        fi
    fi

    echo "[SUCC]openc-c3 installed successfully."

    echo =================================================================
    echo "Web page: http://$1"
    echo "User: open-c3"
    echo "Password: changeme"

    echo "[INFO]Run command to start service: $C3BASEPATH/open-c3/open-c3.sh start"

    echo =================================================================
    echo "[INFO]tt-front build ..."

    mkdir -p $C3BASEPATH/open-c3/c3-front/dist/tt
    rsync  -av $C3BASEPATH/open-c3/Installer/install-cache/trouble-ticketing/tt-front/dist/ $C3BASEPATH/open-c3/c3-front/dist/tt/ --delete
    rsync -av $C3BASEPATH/open-c3/Connector/tt/tt-front/src/assets/images/  $C3BASEPATH/open-c3/c3-front/dist/assets/images/

    if [ $? = 0 ]; then
        echo "[SUCC]tt-front build success."
    else
        echo "[FAIL]tt-front build fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]copy trouble-ticketing ..."

    COOKIEKEY=$(cat $C3BASEPATH/open-c3/Connector/config.inix | grep -v '^ *#' | grep cookiekey:|awk '{print $2}'|grep ^[a-zA-Z0-9]*$)
    c3sed "s/\"cookiekey\":\".*\"/\"cookiekey\":\"$COOKIEKEY\"/g" $C3BASEPATH/open-c3/Connector/tt/trouble-ticketing/cfg.json

    cp $C3BASEPATH/open-c3/Connector/pkg/trouble-ticketing $C3BASEPATH/open-c3/Connector/tt/trouble-ticketing/trouble-ticketing.$$
    mv $C3BASEPATH/open-c3/Connector/tt/trouble-ticketing/trouble-ticketing.$$ $C3BASEPATH/open-c3/Connector/tt/trouble-ticketing/trouble-ticketing
    chmod +x $C3BASEPATH/open-c3/Connector/tt/trouble-ticketing/trouble-ticketing

    if [ $? = 0 ]; then
        echo "[SUCC]copy trouble-ticketing success."
    else
        echo "[FAIL]copy trouble-ticketing fail."
        exit 1
    fi

    if [ -d $C3BASEPATH/open-c3-installer/dev-cache ];then
        cp -r $C3BASEPATH/open-c3-installer/dev-cache $C3BASEPATH/open-c3/Installer/
    fi
    $C3BASEPATH/open-c3/Installer/scripts/dev.sh build

    $C3BASEPATH/open-c3/open-c3.sh start
    $C3BASEPATH/open-c3/open-c3.sh sup
    docker exec openc3-server /data/Software/mydan/Connector/app/c3-restart

    echo =================================================================
    echo "[INFO]run script ..."

    if [ -x "$BASE_PATH/Installer/scripts/single/$MASTERVERSION.sh" ]; then
        $BASE_PATH/Installer/scripts/single/$MASTERVERSION.sh
        if [ $? = 0 ]; then
            echo "[SUCC]run script success."
        else
            echo "[FAIL]run script fail."
            exit 1
        fi
    fi

    mkdir -p $C3BASEPATH/open-c3-data/grafana-data
    rsync -av $C3BASEPATH/open-c3/Installer/install-cache/grafana-data/ $C3BASEPATH/open-c3-data/grafana-data/


    echo sleep 60 sec ...
    sleep 60

    $C3BASEPATH/open-c3/open-c3.sh sup
    $C3BASEPATH/open-c3/open-c3.sh dup
    $C3BASEPATH/open-c3/open-c3.sh start

    echo =================================================================
    echo "[INFO]Update the system to the latest version ..."

    $C3BASEPATH/open-c3/upgrade.sh
}

function start() {
    echo =================================================================
    echo "[INFO]start ..."

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
#

#alertmanager

    if [ ! -f $C3BASEPATH/open-c3/alertmanager/config/alertmanager.yml ];then
        cp $C3BASEPATH/open-c3/alertmanager/config/alertmanager.example.yml $C3BASEPATH/open-c3/alertmanager/config/alertmanager.yml
    fi

#

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
#

#lua

    cp $C3BASEPATH/open-c3/lua/config/lua/sso.example.lua $C3BASEPATH/open-c3/lua/config/lua/sso.temp.lua
    #OPENC3 TODO 这里ip替换域名是lua解析容器中的域名失败
#    REIP=$(docker exec -it openc3-lua ping -c 1 OPENC3_SERVER_IP|grep openc3-server.c3_JobNet|awk -F '[()]' '{print $2}'|grep ^[0-9\.]*$|tail -n 1 )
    COOKIEKEY=$(cat $C3BASEPATH/open-c3/Connector/config.inix | grep -v '^ *#' | grep cookiekey:|awk '{print $2}'|grep ^[a-zA-Z0-9]*$)
#    c3sed "s/OPENC3_SERVER_IP/$REIP/" $C3BASEPATH/open-c3/lua/config/lua/sso.temp.lua
    c3sed "s/ngx.var.cookie_sid/ngx.var.cookie_$COOKIEKEY/g" $C3BASEPATH/open-c3/lua/config/lua/sso.temp.lua

    cp $C3BASEPATH/open-c3/lua/config/lua/sso.temp.lua $C3BASEPATH/open-c3/lua/config/lua/sso.lua

    docker restart  openc3-lua
#
    echo "[SUCC]started."
}

function stop() {
    echo =================================================================
    echo "[INFO]stop ..."

    cd $BASE_PATH/Installer/C3/ && c3-docker-compose kill

    echo "[SUCC]stoped."
}

function restart() {
    echo =================================================================
    echo "[INFO]restart ..."
    Date=$(date "+%F %H:%M:%S")
    echo "#$Date restart" >> $BASE_PATH/Connector/config.ini/current 

    echo "[SUCC]The operation is complete and the service will restart in a few seconds."
}

function reload() {
    echo =================================================================
    echo "[INFO]reload ..."
    Date=$(date "+%F %H:%M:%S")
    echo "#$Date reload" >> $BASE_PATH/Connector/config.ini/current 

    echo "[SUCC]The operation is complete and the service will reload in a few seconds."
}

function check() {
    module=$1
    X=$(curl localhost/api/$module/mon 2>/dev/null)
    if [ "X$X" = "Xok" ]; then
        echo "[SUCC]module $module up."
    else
        echo "[FAIL]module $module down."
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
install)
    install $2
    ;;
rebuild)
    stop && start
    ;;
reborn)
    $BASE_PATH/Installer/scripts/databasectrl.sh backup
    $BASE_PATH/Installer/scripts/upgrade.sh
    stop && start
    $BASE_PATH/Installer/scripts/upgrade.sh
    ;;
upgrade)

    cd $BASE_PATH || exit 1

    echo =================================================================
    echo "[INFO]git pull ..."

    git pull

    if [ $? = 0 ]; then
        echo "[SUCC]git pull success."
    else
        echo "[FAIL]git pull fail."
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
start)
    start
    ;;
stop)
    stop
    ;;
status)
    status
    ;;
restart)
    restart
    ;;
reload)
    reload
    ;;
inx)
    inx
    ;;
app)
    app
    ;;
sql)
    sql
    ;;
log)
    log
    ;;
dup)
    dup
    ;;
sup)
    sup
    ;;
cmdbdemo)
    cmdbdemo
    ;;
*)
    echo "Usage: $0 {start|stop|status|restart|reload|install|rebuild|reborn|upgrade|switchversion|inx|app|sql|log|dup|sup|cmdbdemo}"
    echo "$0 install 10.10.10.10(Your Internet IP)"
    exit 2
esac
