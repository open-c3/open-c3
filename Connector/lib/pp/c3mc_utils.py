#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import os
import sys
import time
import urllib.request
import subprocess


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


def sleep_time_for_limiting(max_frequency_one_second):
    """
        max_frequency_one_second是某个接口每秒的最大请求频率,
        该接口的作用是根据频率限制因子限制频率
    """
    frequency_factor = float(get_frequency_factor())
    if frequency_factor < 0:
        frequency_factor = 0
    if frequency_factor > 1:
        frequency_factor = 1
    
    sleep_second = 0
    
    # 取0表示按照max_frequency_one_second的频率执行
    if frequency_factor == 0:
        # 因为没法预知一个接口请求一次花的时间, 并且如果请求海外服务
        # 响应会更慢, 这里只能预估一个响应时间, 假设一次请求往返消耗0.08秒
        assume_resp_time = 0.08
        all_resp_time = assume_resp_time * max_frequency_one_second
        if all_resp_time > 1:
            # 预估的时间肯定不准确, 但还是要保证能休眠一小段时间
            all_resp_time = 0.8
        sleep_second = (1 - all_resp_time) / (max_frequency_one_second - 1)
    elif frequency_factor == 1:
        sleep_second = (max_frequency_one_second - 1) / max_frequency_one_second
    else:
        sleep_second = frequency_factor
    
    time.sleep(sleep_second)
    return


# 获取同步频率限制因子
# 改因子最小为0，最大为1
def get_frequency_factor():
    output = subprocess.getoutput("c3mc-sys-ctl sys.device.sync.frequency.factor")
    return output


def check_if_params_safe_in_recycle(user_commited_instance_ids, bpm_uuid, bpm_action_type):
    """检查资源回收中涉及的参数是否合法
    """
    cmd_parts = ["c3mc-bpm-protect", "--eventname", bpm_action_type, "--bpmuuid", bpm_uuid]

    proc = subprocess.Popen(cmd_parts, stdin=subprocess.PIPE, stdout=subprocess.PIPE)

    for instance_id in user_commited_instance_ids:
        proc.stdin.write(instance_id.encode())
        proc.stdin.write(b"\n")
        proc.stdin.flush()

    output, errors = proc.communicate()
    if output is not None:
        print(f"命令 c3mc-bpm-protect 执行结果: {output.decode()}")
    if errors is not None:
        print(f"命令 c3mc-bpm-protect 执行出现错误: {errors.decode()}", file=sys.stderr)

    if proc.returncode == 1:
        print("命令 c3mc-bpm-protect 执行出现错误, 直接退出", file=sys.stderr)
        exit(1)

    if proc.returncode == 254:
        # 用户拒绝继续操作，直接退出程序
        print("用户拒绝继续操作，直接退出程序")
        exit(0)
