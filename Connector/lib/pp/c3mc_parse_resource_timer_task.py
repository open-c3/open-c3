#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import os
import shutil

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


def read_file_lines(file_path):
    data_list = []

    if os.path.exists(file_path):
        with open(file_path, "r") as file:
            data_list.extend(line.strip() for line in file)
    return data_list


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
    file_path = "/data/open-c3-data/bpm/crontask.txt"
    backup_file_path = ""

    # 创建备份文件
    if os.path.exists(file_path):
        backup_file_path = f"{file_path}.bak"
        shutil.copyfile(file_path, backup_file_path)

    try:
        # 确保目录存在
        os.makedirs(os.path.dirname(file_path), exist_ok=True)

        # 清空原文件内容
        with open(file_path, "w") as file:
            pass

        with open(file_path, "a") as file:
            for item in line_info_list:
                file.write(str(item) + "\n")

        # 写入成功，删除备份文件
        if backup_file_path != "":
            os.remove(backup_file_path)
    except Exception as e:
        # 写入出错，恢复备份文件
        if backup_file_path != "":
            shutil.move(backup_file_path, file_path)
        raise RuntimeError("写入文件时发生错误") from e


class OperateTimeTaskFile:
    def __init__(self):
        lines = read_file_lines(CRON_TASK_PATH)

        data = {}
        for line in lines:
            line_info = Line().init_from_line(line)

            instance_uuid = line_info.get_instance_uuid()
            action_type = line_info.get_action_type()

            if instance_uuid not in data:
                data[instance_uuid] = {action_type: line_info}

        self.data = data

    def add(
        self,
        action_type,
        instance_uuid,
        timer,
        editor,
        valid_start_timestamp,
        valid_end_timestamp,
    ):
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


    def remove(self, action_type, instance_uuid):
        if (
            instance_uuid not in self.data
            or action_type not in self.data[instance_uuid]
        ):
            return

        self.data[instance_uuid].pop(action_type, None)

    def get_all(self):
        result = []
        for instance_uuid in self.data:
            for action_type in self.data[instance_uuid]:
                line_info = self.data[instance_uuid][action_type]
                result.append({
                    "instance_uuid": line_info.get_instance_uuid(),
                    "str_data": str(line_info)
                })

        return result

    def save(self):
        str_data_list = []
        for instance_uuid in self.data:
            str_data_list.extend(
                str(self.data[instance_uuid][action_type])
                for action_type in self.data[instance_uuid]
            )
        batch_update_lines(str_data_list)
