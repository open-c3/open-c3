#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import time
import urllib.request


def print_c3debug1_log(msg):
    if "C3DEBUG1" in os.environ:
        print(msg, file=sys.stderr)


def print_c3debug2_log(msg):
    if "C3DEBUG2" in os.environ:
        print(msg, file=sys.stderr)


def redownload_file_if_need(filepath, url, alive_seconds):
    """
        该方法会把下载的文件缓存在filepath, 超过有效期重新下载
    """
    os.makedirs(os.path.dirname(filepath), exist_ok=True)

    need_download = False
    if os.path.exists(filepath):
        modified_time=os.path.getmtime(filepath)
        if time.time()-modified_time > alive_seconds: 
            os.remove(filepath)
            need_download = True
    else:
        need_download = True

    if need_download: 
        urllib.request.urlretrieve(url, filepath)