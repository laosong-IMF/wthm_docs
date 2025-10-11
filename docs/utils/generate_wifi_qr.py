#!/usr/bin/env python3

import qrcode
from PIL import Image, ImageDraw

def generate_wifi_qr_code():
    """
    生成一个包含 WiFi 连接信息的二维码图片。
    """
    # WiFi 信息字符串
    wifi_info = "WIFI:T:WPA2;S:WTHM-001;P:wangkong;;"

    # 创建 QRCode 对象
    qr = qrcode.QRCode(
        version=3,  # 标准版本3，约29x29模块
        error_correction=qrcode.constants.ERROR_CORRECT_M,  # 中等错误纠正能力
        box_size=10,  # 每个模块（像素）的大小
        border=4,     # 二维码边框的模块数（最小为4）
    )

    # 添加数据并生成二维码
    qr.add_data(wifi_info)
    qr.make(fit=True)

    # 创建二维码图像
    img = qr.make_image(fill_color="black", back_color="white")

    # 保存图像到文件
    output_filename = "wifi_qr_code.png"
    img.save(output_filename)
    print(f"二维码已生成并保存为: {output_filename}")

    # (可选) 显示生成的二维码
    # img.show() 

if __name__ == "__main__":
    generate_wifi_qr_code()
