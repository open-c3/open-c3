#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import os
import shutil
import time

# 每一行的格式是

# action_type;hour/crontab format;instance_uuid;editor;valid_start_timestamp;valid_end_timestamp
#
# 总共分为5列
#
# 第一列: action_type               操作类型
# 第二列: hour / crontab format     24小时格式制，或者crontab格式的时间格式
# 第三列: instance_uuid             实例uuid
# 第四列: editor                    编辑人
# 第五列: valid_start_timestamp     该条规则生效的起始时间点
# 第六列: valid_end_timestamp       该条规则生效的截止时间点
#
# 所有列使用 ; 进行连接
#

CRON_TASK_PATH = "/data/open-c3-data/bpm/crontask.txt"
# 锁文件。用于防止多个进程同时读取文件内容并进行处理，后续会丢数据的问题
# 如果该文件存在则表示有进程正在读取文件内容，其他进程需要等待
CRON_TASK_LOCK_PATH = "/data/open-c3-data/bpm/crontask.txt.lock"


def read_file_lines(file_path):
    data_list = []

    if os.path.exists(file_path):
        with open(file_path, "r") as file:
            data_list.extend(line.strip() for line in file)
    return data_list


def wait_until_file_unlocked(timeout=900):
    """等待 CRON_TASK_PATH 文件解锁
    """
    start = time.time()
    while True:
        if os.path.exists(CRON_TASK_LOCK_PATH):
            time.sleep(3)
        else:
            break
        
        if time.time() - start >= timeout:
            raise RuntimeError(f"等待文件锁超时, 超时时间: {timeout} 秒")


def lock_file():
    """锁定 CRON_TASK_PATH 文件
    执行之前请确保锁文件不存在，否则出错
    """
    try:
        with open(CRON_TASK_LOCK_PATH, 'x'):
            print(f'锁文件已创建: {CRON_TASK_LOCK_PATH}')
    except FileExistsError as e:
        raise RuntimeError(f'锁文件已存在: {CRON_TASK_LOCK_PATH}') from e

def unlock_file():
    """解锁 CRON_TASK_PATH 文件
    """
    if os.path.exists(CRON_TASK_LOCK_PATH):
        os.remove(CRON_TASK_LOCK_PATH)
        print(f'锁文件已删除: {CRON_TASK_LOCK_PATH}')


class Line:
    def init_from_line(self, line):
        parts = line.split(";")

        if len(parts) != 6:
            raise RuntimeError(f"格式出错, 数据列不完整, 只有 {len(parts)} 列, line: {line}")

        self.action_type = parts[0]
        self.timer = parts[1]
        self.instance_uuid = parts[2]
        self.editor = parts[3]
        self.valid_start_timestamp = parts[4]
        self.valid_end_timestamp = parts[5]

        return self

    def init_from_fields(
        self,
        action_type,
        timer,
        instance_uuid,
        editor,
        valid_start_timestamp,
        valid_end_timestamp,
    ):
        self.action_type = action_type
        self.timer = timer
        self.instance_uuid = instance_uuid
        self.editor = editor
        self.valid_start_timestamp = valid_start_timestamp
        self.valid_end_timestamp = valid_end_timestamp

        return self

    def get_action_type(self):
        return self.action_type

    def set_action_type(self, new_action_type):
        self.action_type = new_action_type

    def get_timer(self):
        return self.timer

    def set_timer(self, new_timer):
        self.timer = new_timer

    def get_instance_uuid(self):
        return self.instance_uuid

    def set_instance_uuid(self, new_instance_uuid):
        self.instance_uuid = new_instance_uuid

    def get_editor(self):
        return self.editor

    def set_editor(self, new_editor):
        self.editor = new_editor

    def get_valid_start_timestamp(self):
        return self.valid_start_timestamp

    def set_valid_start_timestamp(self, new_valid_start_timestamp):
        self.valid_start_timestamp = new_valid_start_timestamp

    def get_valid_end_timestamp(self):
        return self.valid_end_timestamp

    def set_valid_end_timestamp(self, new_valid_end_timestamp):
        self.valid_end_timestamp = new_valid_end_timestamp

    def __str__(self):
        return f"{self.action_type};{self.timer};{self.instance_uuid};{self.editor};{self.valid_start_timestamp};{self.valid_end_timestamp}"


def batch_update_lines(line_info_list):
    """将line_info_list写入到文件"""
    backup_file_path = ""

    # 创建备份文件
    if os.path.exists(CRON_TASK_PATH):
        backup_file_path = f"{CRON_TASK_PATH}.bak"
        shutil.copyfile(CRON_TASK_PATH, backup_file_path)

    try:
        # 确保目录存在
        os.makedirs(os.path.dirname(CRON_TASK_PATH), exist_ok=True)

        # 清空原文件内容
        with open(CRON_TASK_PATH, "w") as file:
            pass

        with open(CRON_TASK_PATH, "a") as file:
            for item in line_info_list:
                file.write(str(item) + "\n")

        # 写入成功，删除备份文件
        if backup_file_path != "":
            os.remove(backup_file_path)
    except Exception as e:
        # 写入出错，恢复备份文件
        if backup_file_path != "":
            shutil.move(backup_file_path, CRON_TASK_PATH)
        raise RuntimeError("写入文件时发生错误") from e


class OperateTimeTaskFile:
    def __init__(self):
        try:
            # 假设有其他进程在处理定时任务操作，等待其操作完成
            wait_until_file_unlocked()
            # 锁定文件
            lock_file()

            lines = read_file_lines(CRON_TASK_PATH)

            data = {}
            for line in lines:
                line_info = Line().init_from_line(line)

                instance_uuid = line_info.get_instance_uuid()
                action_type = line_info.get_action_type()

                if instance_uuid not in data:
                    data[instance_uuid] = {action_type: line_info}
                else:
                    data[instance_uuid][action_type] = line_info

            self.data = data
        except Exception as e:
            unlock_file()
            raise RuntimeError("读取定时任务文件失败") from e

    def add(
        self,
        action_type,
        instance_uuid,
        timer,
        editor,
        valid_start_timestamp,
        valid_end_timestamp,
    ):
        """添加定时任务

        调用完add方法，最后需要调用save方法保存数据 (save方法同时清理锁文件)

        Args:
            action_type (str): 操作类型
            instance_uuid (str): 实例uuid
            timer (str): 时间配置，可以是24小时制时间，还可以是crontab格式时间
            editor (str): 操作人
            valid_start_timestamp (str): 起始时间
            valid_end_timestamp (str): 截止时间
        """
        try:
            if instance_uuid in self.data and action_type in self.data[instance_uuid]:
                selected_line_info = self.data[instance_uuid][action_type]
                selected_line_info.set_timer(timer)
                selected_line_info.set_editor(editor)
                selected_line_info.set_valid_start_timestamp(valid_start_timestamp)
                selected_line_info.set_valid_end_timestamp(valid_end_timestamp)

                self.data[instance_uuid][action_type] = selected_line_info
            else:
                line_info = Line().init_from_fields(
                    action_type,
                    timer,
                    instance_uuid,
                    editor,
                    valid_start_timestamp,
                    valid_end_timestamp,
                )
                if instance_uuid not in self.data:
                    self.data[instance_uuid] = {action_type: line_info}
                    return
                self.data[instance_uuid][action_type] = line_info
        except Exception as e:
            unlock_file()
            raise RuntimeError(f"添加定时任务失败, 实例: {instance_uuid}, 操作类型: {action_type}") from e


    def remove(self, action_type, instance_uuid):
        """删除定时任务

        调用完remove方法，最后需要调用save方法保存数据 (save方法同时清理锁文件)

        Args:
            action_type (str): 操作类型
            instance_uuid (str): 实例uuid
        """
        try:
            if instance_uuid not in self.data or action_type not in self.data[instance_uuid]:
                unlock_file()
                raise RuntimeError(f"无法找到相关定时任务, 实例: {instance_uuid}, 操作类型: {action_type}")

            self.data[instance_uuid].pop(action_type, None)
        except Exception as e:
            unlock_file()
            raise RuntimeError(f"删除定时任务失败, 实例: {instance_uuid}, 操作类型: {action_type}") from e

    def get_all(self):
        try:
            result = []
            for instance_uuid in self.data:
                for action_type in self.data[instance_uuid]:
                    line_info = self.data[instance_uuid][action_type]
                    result.append({
                        "action_type": line_info.get_action_type(),
                        "instance_uuid": line_info.get_instance_uuid(),
                        "timer": line_info.get_timer(),
                        "editor": line_info.get_editor(),
                        "valid_start_timestamp": line_info.get_valid_start_timestamp(),
                        "valid_end_timestamp": line_info.get_valid_end_timestamp(),
                    })

            unlock_file()
            return result
        except Exception as e:
            unlock_file()
            raise RuntimeError("获取定时任务失败") from e
    

    def update_valid_start_timestamp(
        self,
        action_type,
        instance_uuid,
        valid_start_timestamp
    ):
        try:
            if instance_uuid not in self.data or action_type not in self.data[instance_uuid]:
                raise RuntimeError(f"无法找到相关定时任务, 实例: {instance_uuid}, 操作类型: {action_type}")

            self.data[instance_uuid][action_type].set_valid_start_timestamp(valid_start_timestamp)
        except Exception as e:
            unlock_file()
            raise RuntimeError(f"更新定时任务失败, 实例: {instance_uuid}, 操作类型: {action_type}") from e


    def save(self):
        try:
            str_data_list = []
            for instance_uuid in self.data:
                str_data_list.extend(
                    str(self.data[instance_uuid][action_type])
                    for action_type in self.data[instance_uuid]
                )
            batch_update_lines(str_data_list)
            unlock_file()
        except Exception as e:
            unlock_file()
            raise RuntimeError("保存定时任务失败") from e
