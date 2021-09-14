#!/bin/bash

if [ "X$OPEN_C3_ADDR" == "X" ] ;then
    echo 'OPEN_C3_ADDR nofind'
    exit 1
fi

OS=$(uname)
ARCH=$(uname -m)
PERLURL="$OPEN_C3_ADDR/api/scripts/MYDan/repo/data/perl"
INSTALLERDIR='/opt/mydan'

checktool() {
    if ! type $1 >/dev/null 2>&1; then
        echo "Need tool: $1"
        exit 1;
    fi
}

SLIC=""
if [ "X$OS" == "XLinux" ] && [ "X$ARCH" == "Xx86_64" ]; then
     checktool ldd
     LDDVERSION=$(ldd --version|head -n 1)
     if [ "X$LDDVERSION" == "Xldd (GNU libc) 2.5" ];then
         SLIC="libc/2.5/"
     fi
fi

for T in "Linux:x86_64" "Linux:i686" "CYGWIN_NT-6.1:x86_64" "FreeBSD:amd64" "FreeBSD:i386"
do
    o=$(echo $T|awk -F: '{print $1}')
    a=$(echo $T|awk -F: '{print $2}')
    [ "X$OS" == "X$o" ] && [ "X$ARCH" == "X$a" ]&&  break
done

if [ "X$OS" == "X$o" ] && [ "X$ARCH" == "X$a" ]; then
    echo "OS:$OS ARCH:$ARCH ok"
else
    echo "OS:$OS ARCH:$ARCH Not supported"
    exit 1
fi

if [ -f $INSTALLERDIR/perl/.lock ]; then
    echo "The perl is locked"
    exit 1;
fi

checktool curl
checktool wget
checktool cat
checktool md5sum

if [ ! -d "$INSTALLERDIR/perl" ]; then
    echo 'Not yet installed'
fi

VVVV=$(curl -k -s $PERLURL/data/$OS/$ARCH/${SLIC}version)
version=$(echo $VVVV|awk -F: '{print $1}')
md5=$(echo $VVVV|awk -F: '{print $2}')

echo $version

if [[ $version =~ ^[0-9]{14}$ ]]; then
    echo "perl version: $version"
else
    echo "get version fail"
    exit 1;
fi

localversion=$(cat $INSTALLERDIR/perl/.version )

if [ "X$localversion" == "X$version" ]; then
    echo "This is the latest version of Perl";
    exit 0;
fi

clean_exit () {
    [ -f $LOCALINSTALLER ] && rm $LOCALINSTALLER
    echo  "ERROR"
    exit $1
}

get_repo ()
{
    ALLREPO=$1
    C=${#ALLREPO[@]}

    DF=/tmp/x.$$.tmp
    mkfifo $DF
    exec 1000<>$DF
    rm -f $DF

    for((n=1;n<=$C;n++))
    do
        echo >&1000
    done

    for((i=0;i<$C;i++))
    do
        read -u1000
        {
            s=$(curl -I -k --connect-timeout 2 ${ALLREPO[$i]}/data/$OS/$ARCH/${SLIC}perl.$version.tar.gz 2>/dev/null|head -n 1|awk '/302|200/'|wc -l)
            echo "$i:$s" >&1000
        }&
    done

    wait

    for((i=1;i<=$C;i++))
    do
        read -u1000 X
        id=$(echo $X|awk -F: '{print $1}')
        s=$(echo $X|awk -F: '{print $2}')
        if [[ "x1" == "x$s" && "x" == "x$ID" ]];then
            ID=$id
        fi
    done

    exec 1000>&-
    exec 1000<&-

    if [ "X$ID" != "X" ];then
        MYDan_REPO=${ALLREPO[$ID]}
    fi
}

if [[ ! -z $MYDAN_REPO_PRIVATE ]];then
    MYDAN_REPO=$(echo $MYDAN_REPO_PRIVATE |xargs -n 1|awk '{print $0"/perl"}'|xargs -n 100)
    ALLREPO=( $MYDAN_REPO )
    get_repo $ALLREPO
fi

if [ -z $MYDan_REPO ];then
    MYDAN_REPO=$(echo $MYDAN_REPO_PUBLIC|xargs -n 1|awk '{print $0"/perl"}'|xargs -n 100)
    ALLREPO=( $PERLURL $MYDAN_REPO )
    get_repo $ALLREPO
fi

if [ -z "$MYDan_REPO" ];then
    echo "nofind $OS/$ARCH/${SLIC}perl.$version.tar.gz on all repo"
    exit 1
else
    PACKTAR=$MYDan_REPO/data/$OS/$ARCH/${SLIC}perl.$version.tar.gz
fi

LOCALINSTALLER=$(mktemp perl.XXXXXX)

wget --no-check-certificate -O $LOCALINSTALLER "$PACKTAR" || clean_exit 1

fmd5=$(md5sum $LOCALINSTALLER|awk '{print $1}')

if [ "X$md5" != "X$fmd5" ];then
    echo "perl $version md5 nomatch"
    exit 1;
fi

if [ ! -e $INSTALLERDIR ]; then
    mkdir -p $INSTALLERDIR
fi

tar -zxf $LOCALINSTALLER -C $INSTALLERDIR || clean_exit 1

[ -f $LOCALINSTALLER ] && rm $LOCALINSTALLER

echo $version > $INSTALLERDIR/perl/.version

echo perl update OK
