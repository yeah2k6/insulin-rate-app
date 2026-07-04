# 胰岛素泵基础率记录

一个 PWA 应用，帮助记录胰岛素泵基础率修改。

## 文件结构

```
insulin-app/
├── index.html       # 主应用（HTML + CSS + JS 全部内联）
├── manifest.json    # PWA 清单
├── sw.js            # Service Worker（离线缓存）
└── icons/           # App 图标
    ├── icon-192.png
    └── icon-512.png
```

## 在 PC 端使用

### 方式一：直接打开
1. 解压项目文件夹
2. 双击 `index.html` 在浏览器中打开

### 方式二：本地服务器（推荐，PWA 功能完整）
```bash
# Python
python3 -m http.server 8000

# 或 Node.js
npx serve .
```
然后浏览器访问 `http://localhost:8000`

### 方式三：部署到公网
推送到 GitHub 仓库，开启 GitHub Pages 即可多设备访问。

## 功能

- ✏️ **记录**：填写各时间段旧值/新值，有变化自动标橙
- 📋 **历史**：按方案筛选，查看详情，看调整变化量
- 📤 **导出**：单条或全部导出为文本，可分享/复制
- 📥 **导入**：粘贴导出文本，自动识别并导入
- ⚙️ **设置**：自定义时间段、提醒、清除数据
- 💾 **离线**：数据存浏览器本地，无需联网

## 数据存储

所有数据存在浏览器 `localStorage` 中：
- `ir_records`：记录数据
- `ir_slots`：时间段配置
- `ir_settings`：设置项

> 注意：清除浏览器数据会丢失记录，建议定期用"导出全部"备份。
