# -*- coding: UTF-8 -*-
"""
__Author__ = "WECENG"
__Version__ = "1.0.0"
__Description__ = "配置类"
__Created__ = 2023/10/27 09:54
"""
import json
import os


class Config:
    def __init__(self, server_url, keyword, users, city, date, price, price_index,
                 if_commit_order, device_name=None, platform_version=None):
        self.server_url = server_url
        self.keyword = keyword
        self.users = users
        self.city = city
        self.date = date
        self.price = price
        self.price_index = price_index
        self.if_commit_order = if_commit_order
        # 设备信息：不填则用默认值（模拟器 emulator-5554 / Android 16）
        self.device_name = device_name
        self.platform_version = platform_version

    @staticmethod
    def load_config():
        # 本地私有配置优先（含真实场次信息，已被 .gitignore 排除）；仓库内 config.jsonc 为脱敏示例
        config_path = 'config.local.jsonc' if os.path.exists('config.local.jsonc') else 'config.jsonc'
        with open(config_path, 'r', encoding='utf-8') as config_file:
            config = json.load(config_file)
        return Config(config['server_url'],
                      config['keyword'],
                      config['users'],
                      config['city'],
                      config['date'],
                      config['price'],
                      config['price_index'],
                      config['if_commit_order'],
                      config.get('device_name'),
                      config.get('platform_version'))