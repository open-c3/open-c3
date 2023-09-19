#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import contextlib
import os
import sys
import time
import urllib.request
import subprocess
import json
import hashlib
import random
import base64
import string
import re
import socket
import uuid
import shutil
from ipaddress import ip_network, ip_address


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
    frequency_factor = max(frequency_factor, 0)
    frequency_factor = min(frequency_factor, 1)
    sleep_second = 0

    # 取0表示按照max_frequency_one_second的频率执行
    if frequency_factor == 0:
        all_resp_time = 0.08 * max_frequency_one_second
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
    return subprocess.getoutput("c3mc-sys-ctl sys.device.sync.frequency.factor")


def check_if_resources_safe_for_operation(user_commited_instance_ids, bpm_uuid, bpm_action_type):
    """资源保护检查

    确定用户提交的资源根据 [bpm_action_type] 判断是否可以安全进行后续处理，由用户决定是否继续操作
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

# 下面的 decode_for_special_symbol 和 encode_for_special_symbol 
# 用于实现 bpm目录下 `special_encoding.md` 文件中编码规则的编码和解码
# 
# 下面代码仅处理 ASCII 中的特殊字符（非字母数字字符），而不处理其他 Unicode 字符
def decode_for_special_symbol(encoded_str):
    decoded_str = ''
    i = 0
    while i < len(encoded_str):
        if encoded_str[i] == 'E':
            temp = ''
            i += 1
            while i < len(encoded_str) and encoded_str[i] != 'E':
                temp += encoded_str[i]
                i += 1
            if i < len(encoded_str) and encoded_str[i] == 'E':
                if temp.isdigit() and 0 <= int(temp) < 128:
                    decoded_str += chr(int(temp))
                    i += 1
                else:
                    decoded_str += f'E{temp}'
            else:
                decoded_str += f'E{temp}'
        else:
            decoded_str += encoded_str[i]
            i += 1

    return decoded_str


def encode_for_special_symbol(decoded_str):
    return ''.join(
        char if char.isalnum() or ord(char) >= 128 else f'E{ord(char)}E' for char in decoded_str
    )

def bpm_merge_user_input_tags(instance_params, tag_field_name="tag", tag_key_field="key", tag_value_field="value", **kwargs):
    """将用户bpm工单中用户配置的普通标签和命名标签合并在一起

    Args:
        instance_params (dict): 工单参数
        tag_field_name (str, optional): 工单参数中标签列表字段的名称, 默认为 "tag".
        tag_key_field (str, optional): 工单参数中标签键的名称
        tag_value_field (str, optional): 工单参数中标签值的名称
    """
    def get_env_value(tag_name):
        return subprocess.getoutput(f"c3mc-sys-ctl cmdb.tags.{tag_name}")

    def add_tag_if_missing(tag_list, tag_name, key_name):
        if key_name == "":
            return tag_list

        # 去掉已存在的旧标签
        tag_list = [tag for tag in tag_list if tag[tag_key_field] != tag_name]
        tag_list.append({
            tag_key_field: tag_name,
            tag_value_field: instance_params[key_name]
        })
        return tag_list

    tag_list = []
    with contextlib.suppress(json.JSONDecodeError):
        tag_list = json.loads(instance_params[tag_field_name])

    tag_list = add_tag_if_missing(tag_list, get_env_value("ProductOwner"), kwargs.get("product_owner_key_name", ""))
    tag_list = add_tag_if_missing(tag_list, get_env_value("Owners"), kwargs.get("owners_key_name", ""))
    tag_list = add_tag_if_missing(tag_list, get_env_value("OpsOwner"), kwargs.get("ops_owner_key_name", ""))
    tag_list = add_tag_if_missing(tag_list, get_env_value("Department"), kwargs.get("department_key_name", ""))
    tag_list = add_tag_if_missing(tag_list, get_env_value("Product"), kwargs.get("product_key_name", ""))
    tag_list = add_tag_if_missing(tag_list, get_env_value("HostName"), kwargs.get("hostname_key_name", ""))
    tag_list = add_tag_if_missing(tag_list, get_env_value("Name"), kwargs.get("name_key_name", ""))
    tag_list = add_tag_if_missing(tag_list, get_env_value("Tree"), kwargs.get("tree_key_name", ""))

    instance_params[tag_field_name] = json.dumps(tag_list)
    return instance_params

def encode_base64(string):
    s_bytes = string.encode("utf-8")
    base64_bytes = base64.b64encode(s_bytes)
    return base64_bytes.decode("utf-8")

def decode_base64(base64_string):
    decoded_bytes = base64.b64decode(base64_string)
    return decoded_bytes.decode('utf-8')


def calculate_md5(input_string):
    # 创建 MD5 对象
    md5_hash = hashlib.md5()

    # 将字符串编码为字节流并计算 MD5
    md5_hash.update(input_string.encode('utf-8'))

    return md5_hash.hexdigest()


def exponential_backoff(attempt, max_delay):
    delay = min(max_delay, (2**attempt) + random.uniform(0, 1))
    time.sleep(delay)


def retry_network_request(func, arg):
    """执行网络操作请求, 当出现网络错误时，可以进行重试

    Args:
        func (function): 要执行的函数
        arg (tuple): 函数参数, 元组类型
    """
    def check_not_in(string_list, target_string):
        all_not_in = True
        for string in string_list:
            if string in target_string:
                all_not_in = False 
        return all_not_in
    
    conditions = [
        "Connection timed out",
        "Insufficient capacity",
    ]

    # 每次最长等待10秒
    max_delay = 10

    # 最多尝试5次
    attempt = 0
    while attempt < 5:
        try:
            return func(*arg)
        except Exception as e:
            if check_not_in(conditions, str(e)):
                raise e
            print("使用 Exponential Backoff 等待后重试...", file=sys.stderr)
            exponential_backoff(attempt, max_delay)
            attempt += 1


def generate_password(length, with_special_symbol=True):
    """生成指定长度的密码

    Args:
        length (int): 指定密码长度
        with_special_symbol(bool): 是否包含特殊字符。默认是
    """
    pwd_chars = string.ascii_letters + string.digits + '!@#%^()'
    if not with_special_symbol:
        pwd_chars = string.ascii_letters + string.digits

    random.seed(time.time_ns())
    return ''.join(random.choice(pwd_chars) for _ in range(length))


def flatten_dict(d, parent_key='', sep='.'):
    """把一个嵌套的字典 "展平" 到一层

    Args:
        d (_type_): _description_
        parent_key (str, optional): _description_. Defaults to ''.
        sep (str, optional): _description_. Defaults to '.'.

    Returns:
        _type_: _description_
    """
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)


def safe_run_command(cmd_parts):
    """安全的运行命令。
    命令执行出错会抛出异常
    
    如果成功, 则返回命令输出。
    如果出错, 则将错误打印到标准错误, 同时退出码为1

    Args:
        cmd_parts (list): 数组格式的命令。例如要运行命令 "ls -alh"，则传递 ["ls", "-alh"]
    """
    output = subprocess.run(cmd_parts, capture_output=True, text=True)

    if output.returncode != 0:
        raise RuntimeError(output.stderr)

    output = output.stdout
    if output:
        output = output.strip()
    
    return output

def safe_run_command_v2(cmd_parts):
    """安全的运行命令v2版本。
    命令执行出错不会抛出异常, 而是返回相关信息给调用者
    
    输出: (状态码, 输出，错误)
    """

    output = subprocess.run(cmd_parts, capture_output=True, text=True)

    code = output.returncode

    err = output.stderr if output.returncode != 0 else None
    output = output.stdout
    if output:
        output = output.strip()

    return code, output, err


def safe_run_pipe_command(commands):
    """运行管道命令

    Args:
        commands ([][]str): 二维数组格式的命令。例如要运行命令 "ls -alh | grep test"，则传递 [["ls", "-alh"], ["grep", "test"]]
    """
    prev_process = None
    
    for cmd in commands:
        process = subprocess.Popen(cmd, stdin=(prev_process.stdout if prev_process else None), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        if prev_process:
            prev_process.stdout.close()
            
        prev_process = process

    stdout, stderr = prev_process.communicate()
    
    if prev_process.returncode != 0:
        raise RuntimeError(stderr.decode())
    
    return stdout.decode().strip()

def is_valid_email(email) -> bool:
    """检查邮箱格式是否合法

    Args:
        email (str): 邮箱地址
    """
    email_regex = re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b')
    return bool(email_regex.match(email))

def get_instance_info_list(ip_list):
    """查询指定ip列表的资源详情

    Args:
        ip_list (list): ip列表
    """
    output = safe_run_command([
        "c3mc-device-api-jumpserver",
        "--json", 
        "--ips", 
        ",".join(ip_list) 
    ])
    data_list = json.loads(output)
    if len(data_list) != len(ip_list):
        raise RuntimeError(f"无法从c3查询到指定数量ip的详情, ip_list: {ip_list}")
    
    return data_list


def extract_ips(text):
    """从字符串中提取ip列表

    Args:
        text (str): 包含ip地址的字符串
    """
    pattern = r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'

    matches = re.findall(pattern, text)

    valid_ips = []
    for ip in matches:
        octets = ip.split('.')
        if len(octets) == 4 and all(0 <= int(octet) <= 255 for octet in octets):
            valid_ips.append(ip)

    return valid_ips


def is_ip_in_networks(network_list, target_ip) -> bool:
    """检查ip是否包含在指定网络列表

    Args:
        network_list (list): 网络列表, 可以包含网段和ip
        target_ip (str): 目标ip
    """
    target_ip = ip_address(target_ip)
    for ip in network_list:
        # 如果列表中的项是单个IP，则直接与目标IP进行比较
        if '/' in ip:
            network = ip_network(ip, strict=False)
            if target_ip in network:
                return True
        elif target_ip == ip_address(ip):
            return True
    return False


def get_instance_real_uuid(instance_maybe_identifier):
    """根据实力的标识符查询实例的uuid

    Args:
        instance_maybe_identifier (str): 实例标识符。可能不是实例真实uuid，比如可以是ip，实例名称等，具体可以使用哪些值取决于cmdb同步配置文件中的配置
    """
    output = subprocess.run(["c3mc-device-find-uuid", instance_maybe_identifier], capture_output=True, text=True)
    if output.returncode != 0:
        if output.returncode == 1:
            raise RuntimeError(f"无法找到相关实例或者找到了多个实例: {instance_maybe_identifier}")
        else:
            raise RuntimeError(f"命令c3mc-device-find-uuid出现其他异常: {output.stderr}")
    
    # c3mc-device-find-uuid 命令保证了只会查到一个uuid
    parts = output.stdout.decode("utf-8").strip().split()
    if len(parts) > 1:
        print(f"通过命令 c3mc-device-find-uuid 查询到了多个uuid {parts}", file=sys.stderr)
        exit(1)
    return parts[0]

def test_if_port_can_connected(host, port):
    """检测ip端口是否可以联通

    Args:
        host (str): 主机地址
        port (number): 端口号

    Returns:
        Boolean: 
            True 可以联通
            False 不可以联通
    """
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)
    result = sock.connect_ex((host, port))
    sock.close()
    return result == 0


def doulbe_new_line(content):
    return "\n\n".join(content.split("\n"))


def duplicate_file(source_file_path, target_file_name):
    """创建文件副本
    
    该函数会在/tmp/目录下创建一个随机目录, 并在该目录下创建一个文件副本

    Args:
        source_file_path (str): 源文件绝对路径
        target_file_name (str): 目标文件名称

    Returns:
        tuple: (目标文件绝对路径, 清理函数)
    """
    random_dir_name = str(uuid.uuid4())
    target_dir_path = os.path.join("/tmp", random_dir_name)
    os.makedirs(target_dir_path, exist_ok=True)
    
    target_file_path = os.path.join(target_dir_path, target_file_name)
    
    shutil.copy2(source_file_path, target_file_path)

    def clean_file():
        os.remove(target_file_path)
        os.rmdir(target_dir_path)

    return target_file_path, clean_file

def read_file_lines(file_path, remove_empty_line=True):
    """读取文件内容行

    Args:
        file_path (str): 文件路径
    """
    data_list = []

    if os.path.exists(file_path):
        with open(file_path, "r") as file:
            data_list.extend(line.strip() for line in file)
    
    if remove_empty_line:
        return [line for line in data_list if line != ""]
    else:
        return data_list
