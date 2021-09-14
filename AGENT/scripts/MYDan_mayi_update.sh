#!/bin/bash

if [ "X$OPEN_C3_ADDR" == "X" ] ;then
    echo 'OPEN_C3_ADDR nofind'
    exit 1
fi

#MAYIURL='https://github.com/MYDan/mayi/archive'
MAYIURL="$OPEN_C3_ADDR/api/scripts/MYDan/repo/data/mayi/data"
VERSIONURL="$OPEN_C3_ADDR/api/scripts/MYDan/repo/data/mayi/data/version"
INSTALLERDIR='/opt/mydan'

if [ -f $INSTALLERDIR/dan/.lock ]; then
    echo "The mayi is locked"
    exit 1
fi

if [ ! -d "$INSTALLERDIR/dan" ]; then
    echo 'Not yet installed'
fi

checktool() {
    if ! type $1 >/dev/null 2>&1; then
        echo "Need tool: $1"
        exit 1
    fi
}

checktool curl
checktool wget
checktool tar
checktool cat
checktool head
checktool make
checktool rsync
checktool md5sum

VVVV=$(curl -k -s $VERSIONURL)

if [ "X$MYDanInstallLatestVersion" == "X1" ]; then
    VVVV="00000000000000:00000000000000000000000000000000"
    rm $INSTALLERDIR/dan/.version
else
    VVVV=$(curl -k -s $VERSIONURL)
fi

version=$(echo $VVVV|awk -F: '{print $1}')
md5=$(echo $VVVV|awk -F: '{print $2}')

if [[ $version =~ ^[0-9]{14}$ ]];then
    echo "mayi version: $version"
else
    echo "get version fail"
    exit 1
fi

localversion=$(cat $INSTALLERDIR/dan/.version )

PERL=$INSTALLERDIR/perl/bin/perl

if [ ! -x "$PERL" ]; then
  echo "no find $PERL"
  clean_exit 1
fi

#localperl=$(head -n 1 $INSTALLERDIR/dan/tools/range )

#if [ "X$localversion" == "X$version" ] && [ "X$localperl" == "X#!$PERL" ]; then
if [ "X$localversion" == "X$version" ]; then
    echo "This is the latest version of Mayi";
    exit 1
fi

LOCALINSTALLER=$(mktemp mayi.XXXXXX)
clean_exit () {
    [ -f $LOCALINSTALLER ] && rm $LOCALINSTALLER
    [ -d mayi-mayi.$version ] && rm -rf mayi-mayi.$version
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
            s=$(curl -k --connect-timeout 2 -I ${ALLREPO[$i]}/mayi.$version.tar.gz 2>/dev/null|head -n 1|awk '/302|200/'|wc -l)
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
    MYDAN_REPO=$(echo $MYDAN_REPO_PRIVATE |xargs -n 1|awk '{print $0"/mayi/data"}'|xargs -n 100)
    ALLREPO=( $MYDAN_REPO )
    get_repo $ALLREPO
fi

if [ -z $MYDan_REPO ];then
    MYDAN_REPO=$(echo $MYDAN_REPO_PUBLIC|xargs -n 1|awk '{print $0"/mayi/data"}'|xargs -n 100)
    ALLREPO=( $MAYIURL $MYDAN_REPO )
    get_repo $ALLREPO
fi

if [ -z "$MYDan_REPO" ];then
    echo "nofind mayi.$version.tar.gz on all repo"
    #exit 1
    PACKTAR="$MAYIURL/mayi.$version.tar.gz"
else
    PACKTAR="$MYDan_REPO/mayi.$version.tar.gz"
fi

wget --no-check-certificate -O $LOCALINSTALLER "$PACKTAR" || clean_exit 1

if [ "X$md5" != "X00000000000000000000000000000000" ];then
    fmd5=$(md5sum $LOCALINSTALLER|awk '{print $1}')
    if [ "X$md5" != "X$fmd5" ];then
        echo "mayi $version md5 nomatch"
        exit 1;
    fi
fi

tar -zxvf $LOCALINSTALLER || clean_exit 1

cd mayi-mayi.$version || clean_exit 1

$PERL Makefile.PL || clean_exit 1
make  || clean_exit 1
make install dan=1 box=1 def=1 || clean_exit 1

cd - || clean_exit 1

rm -rf mayi-mayi.$version
rm -f $LOCALINSTALLER

echo $version > $INSTALLERDIR/dan/.version

if [ ! -e /bin/mydan ];then
    ln -fsn $INSTALLERDIR/bin/mydan /bin/mydan
fi

echo mayi update OK
