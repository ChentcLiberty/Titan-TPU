#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# Verdi 大字体启动脚本
# 作者: Chen Weidong
# 日期: 2026-01-22
# 说明: 强制使用大字体启动 Verdi
# ═══════════════════════════════════════════════════════════════════

# 设置 Qt 字体
export QT_FONT_DPI=192

# 设置 X11 字体 DPI
export GDK_DPI_SCALE=2

# 创建临时 Qt 配置
export QT_QPA_PLATFORMTHEME=gtk2

# 启动 Verdi
/home/jjt/install/synopsys/verdi/verdi/T-2022.06/bin/verdi "$@"
