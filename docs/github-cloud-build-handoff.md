# 京东云亚瑟固件：GitHub 连接、云编译与换电脑交接

这份文档记录我们这套 **京东云亚瑟（JDCloud RE-SS-01 / Arthur）ImmortalWrt 固件** 是怎么接到 GitHub 上的、云编译怎么跑、本地仓库怎么布局、刷机要注意什么，以及换一台电脑后怎么把开发和编译接回去。

仓库是 **公开仓库**。本文不写入路由器 root 密码、当前 Wi-Fi 密码、Clash/Nikki 面板密码、订阅链接和 token。这些只列在文末「本机私密信息」清单里，换电脑时请从旧电脑或正在跑的亚瑟上自己抄，不要提交到 GitHub。

---

## 1. 一句话全貌

1. GitHub 账号 `3584569425` 下有公开仓库  
   [https://github.com/3584569425/immortalwrt-arthur](https://github.com/3584569425/immortalwrt-arthur)
2. 这个仓库 **不是完整 OpenWrt 源码树**。它只放自定义配置、diy 脚本、files 覆盖层、以及 GitHub Actions 工作流。
3. 每次 push 到 `main`（改了 `.config` / `diy-*.sh` / `files/**` / 工作流），或在网页上点 **Run workflow**，GitHub 托管的 Ubuntu 22.04 runner 会：
   - clone 官方 [immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt) 的 `master`
   - 加 Nikki feed
   - 套我们的 `.config` 和 `files/`
   - 编出亚瑟的 squashfs 固件
   - 再打一份给 Hugo U-Boot 用的 `factory.bin`
   - 上传 Artifact，并发 GitHub Release
4. 本机旧电脑上的工作副本在：
   `/Users/pingguobijiben/Documents/chatgpt/openwrt`
5. 亚瑟已经刷过 Hugo U-Boot。U-Boot 刷机只用 `*squashfs-factory.bin`，**绝对不要刷 initramfs**。已经在 ImmortalWrt 里以后，用 `*squashfs-sysupgrade.bin` 升级。

---

## 2. GitHub 账号与仓库

### 2.1 账号

| 项 | 值 |
| --- | --- |
| GitHub 用户名 | `3584569425` |
| 主页 | https://github.com/3584569425 |
| 显示名 | xiaoqi |
| 公开邮箱 | `3584569425@qq.com` |
| 账号 ID | `179310889` |
| 账号创建 | 2024-08-24 |
| 本仓库权限 | 该用户是 owner，admin/push 都有 |

同账号下还有别的仓库（`zcode-mini`、`AI-Mini-Source` 等），**和亚瑟固件无关**。固件只认 `immortalwrt-arthur`。

### 2.2 本仓库

| 项 | 值 |
| --- | --- |
| 仓库 | `3584569425/immortalwrt-arthur` |
| URL | https://github.com/3584569425/immortalwrt-arthur.git |
| 可见性 | **Public** |
| 默认分支 | `main` |
| 创建时间 | 2026-09-16 |
| 许可证 | MIT |
| Description | 京东云亚瑟 RE-SS-01 ImmortalWrt 云编译，针对 USB 随身WiFi 上网优化 |
| GitHub Secrets | 无（云编译不需要额外 secret，`GITHUB_TOKEN` 够发 Release） |
| GitHub Variables | 无 |
| Actions 工作流 | `Build ImmortalWrt`，id `359531709`，状态 active |

clone 命令：

```bash
git clone https://github.com/3584569425/immortalwrt-arthur.git
cd immortalwrt-arthur
```

### 2.3 Git 提交身份

旧电脑本地 git 用的是：

```
user.name=xiaozhengyi
user.email=179310889+3584569425@users.noreply.github.com
```

远程：

```
origin  https://github.com/3584569425/immortalwrt-arthur.git
branch  main -> origin/main
```

截至交接时 `main` 最新提交：

```
b143578  Add Nikki/Mihomo, TUN kmods, and Argon to the Arthur image.
```

完整提交历史：

| 提交 | 日期 | 说明 |
| --- | --- | --- |
| `2866e4e` | 2026-09-16 | 初版：ImmortalWrt 云编译骨架、USB WAN 热插拔/watchdog、中文 LuCI |
| `cd7b458` | 2026-09-16 | 说明当时 OAuth 没有 `workflow` 权限，工作流先放在 `workflow/build.yml` |
| `233beb1` | 2026-09-16 | 真正把工作流写进 `.github/workflows/build.yml`，云编译开始能跑 |
| `ad4a62c` | 2026-09-16 | 增加 Hugo U-Boot 用的 `factory.bin` 打包，避免刷成临时系统 |
| `b143578` | 2026-09-22 | 把 Nikki/Mihomo、TUN/TPROXY kmod、Argon 打进固件 |

---

## 3. 旧电脑上 GitHub 是怎么登录的

### 3.1 当前登录状态（旧 Mac）

- CLI：`gh` 在 `/Users/pingguobijiben/.local/bin/gh`
- 版本：`gh version 2.96.0 (2026-07-02)`
- 已登录主机：`github.com`
- 已登录账号：`3584569425`
- 凭证存放：macOS **keyring**（不是明文 token 文件）
- Git 协议：**HTTPS**，不是 SSH
- Git 凭据助手：

  ```
  credential.https://github.com.helper=!/Users/pingguobijiben/.local/bin/gh auth git-credential
  credential.https://gist.github.com.helper=!/Users/pingguobijiben/.local/bin/gh auth git-credential
  ```

- Token 类型：GitHub OAuth（`gho_` 开头）
- Token scopes：`gist`、`read:org`、`repo`、`workflow`

`workflow` 这个 scope 很关键。没有它，就不能推 `.github/workflows/*.yml`，也就不能改云编译。

本机 `~/.ssh/` 里 **没有** 给这个仓库用的 GitHub SSH key。现有 `aimini-source-deploy-20260807` 是别的项目的 deploy key，不要拿来推亚瑟仓库。

仓库也 **没有** 配置 GitHub Actions secrets。发 Release 靠工作流里的 `permissions: contents: write` 和默认 `GITHUB_TOKEN`。

### 3.2 第一次是怎么授权上云编译的

2026-09-16 做第一版时，当时的 OAuth **没有 `workflow` 权限**，所以工作流先放在仓库的 `workflow/build.yml`，不能直接进 `.github/workflows/`。

后来用 GitHub **Device Activation（设备码登录）** 补了权限：

1. 某端（Codex / `gh`）向 GitHub 申请 device code
2. 浏览器打开 `https://github.com/login/device`
3. 当时登录身份是 GitHub 用户 `3584569425`
4. 输入设备码，点 Continue
5. 成功页是 `https://github.com/login/device/success`  
   文案：`Congratulations, you're all set!` / `Your device is now connected.`
6. 之后才能提交 `.github/workflows/build.yml`，Actions 才真正跑起来

换电脑后如果 `gh` 还没登录，**再走一遍 device 登录即可**，不必抄旧 token。旧 token 在 keyring 里，换机带不过去。

---

## 4. 新电脑怎么把 GitHub 接回去

目标：新电脑能 `git clone` / `git push`，能 `gh workflow run`，能看 Actions / Release。

### 4.1 安装 GitHub CLI

macOS 推荐：

```bash
brew install gh git
```

或从 https://cli.github.com/ 安装。装完确认：

```bash
gh --version
git --version
```

### 4.2 登录（推荐 HTTPS + gh 凭据，和旧电脑一致）

```bash
gh auth login
```

按提示选：

1. `GitHub.com`
2. `HTTPS`
3. 用浏览器登录，或选 **one-time code**（就是 device flow，打开 github.com/login/device）
4. 授权账号 **`3584569425`**
5. 权限至少勾上：**repo**、**workflow**、**read:org**（gist 可选）

登录后检查：

```bash
gh auth status
gh api user --jq .login
# 应输出 3584569425
```

把 git 凭据交给 gh（和旧电脑一样）：

```bash
gh auth setup-git
```

设置提交身份（建议继续用 GitHub noreply，和现有 commit 一致）：

```bash
git config --global user.name "xiaozhengyi"
git config --global user.email "179310889+3584569425@users.noreply.github.com"
```

### 4.3 另一种：SSH

不是旧电脑的做法，但新电脑可以用：

```bash
ssh-keygen -t ed25519 -C "3584569425@qq.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
gh ssh-key add ~/.ssh/id_ed25519.pub -t "new-computer"
```

然后把 remote 改成：

```bash
git remote set-url origin git@github.com:3584569425/immortalwrt-arthur.git
```

### 4.4 拉仓库

```bash
git clone https://github.com/3584569425/immortalwrt-arthur.git
cd immortalwrt-arthur
git status
git log -5 --oneline
```

本地固件 bin **不在 git 里**（`.gitignore` 忽略了 `*.bin` / `*.itb`）。新电脑要刷机包，从 Release 下，或把旧电脑 `firmware/` 拷过来。

### 4.5 验证云编译入口

```bash
gh workflow list
# 应看到：Build ImmortalWrt    active

gh run list --limit 5
gh release list
```

手动触发一次（不改文件也能编）：

```bash
gh workflow run "Build ImmortalWrt" --ref main
gh run watch
```

或浏览器：  
https://github.com/3584569425/immortalwrt-arthur/actions  
→ **Build ImmortalWrt** → **Run workflow** → 选 `main`。

---

## 5. 仓库目录说明

这是一个 **云编译配方仓库**，不是 immortalwrt 源码本身。

```
immortalwrt-arthur/
├── .github/workflows/build.yml   # GitHub 真正会跑的工作流（必须在这个路径）
├── workflow/build.yml            # 历史副本，内容和上面应保持一致
├── .config                       # 目标机型 + 要编进固件的包
├── diy-part1.sh                  # feeds update 之前：加入 nikki feed
├── diy-part2.sh                  # feeds install 之后：中文、banner、打 factory 配方
├── files/                        # 打进 rootfs 的覆盖文件
│   ├── etc/uci-defaults/99-arthur-setup
│   ├── etc/hotplug.d/net/21-usb-wan
│   ├── etc/hotplug.d/usb/21-usb-power
│   ├── etc/init.d/usbwan-watchdog
│   ├── etc/modprobe.d/usbcore.conf
│   └── usr/sbin/usbwan-watchdog
├── scripts/
│   ├── patch-factory-recipe.py   # 给 ipq60xx.mk 加上 factory.bin 配方
│   └── make-factory.py           # 从 sysupgrade tar 再打一份 U-Boot factory.bin
├── README.md
├── LICENSE
├── .gitignore
└── docs/github-cloud-build-handoff.md   # 本文
```

旧电脑工作副本里还有 **未进 git** 的东西：

| 路径 | 是否进 git | 说明 |
| --- | --- | --- |
| `firmware/*.bin` | 否（gitignore） | 本地下载的刷机包 |
| `backup-20260922/` | 否 | 当时救 overlay / 恢复 Nikki 的脚本和 geo 文件，**含订阅 URL，不要提交** |
| `.DS_Store` | 忽略 | macOS 垃圾文件 |

`.gitignore` 内容：

```
.DS_Store
openwrt/
*.swp
*.bin
*.itb
```

`openwrt/` 是工作流在 runner 上 clone 官方源码的目录名；本仓库也忽略它，避免有人在本地全量编完把源码树提交上去。

---

## 6. 云编译工作流（核心）

文件：`.github/workflows/build.yml`  
工作流名：`Build ImmortalWrt`  
Runner：`ubuntu-22.04`  
并发组：`immortalwrt-arthur`（同一时间只跑一个，新的会取消旧的）

### 6.1 触发条件

```yaml
on:
  workflow_dispatch:          # 网页或 gh workflow run 手动触发
  push:
    branches: [main]
    paths:
      - ".config"
      - "diy-*.sh"
      - "files/**"
      - ".github/workflows/build.yml"
```

只改 `README.md` / 本文 **不会** 自动开编。改包列表、diy、files、工作流才会。

### 6.2 环境变量

```yaml
REPO_URL: https://github.com/immortalwrt/immortalwrt
REPO_BRANCH: master
CONFIG_FILE: .config
DIY_P1_SH: diy-part1.sh
DIY_P2_SH: diy-part2.sh
TZ: Asia/Shanghai
```

也就是：**永远跟官方 ImmortalWrt master 编**，不是某个冻结的 tag。换电脑后续编出来的内核/软件包版本，会比 2026-09-22 那次 snapshot 新。这是预期行为。

### 6.3 步骤（按实际 yml）

1. `actions/checkout@v4` 检出本仓库
2. 清 GitHub runner 磁盘，装编译依赖（gcc、ncurses、python3、squashfs-tools 等），时区设上海
3. 在 `/workdir` clone `immortalwrt/immortalwrt` 的 `master`，并 ln 到工作区 `openwrt/`
4. 跑 `diy-part1.sh`：往 `feeds.conf.default` 追加  
   `src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main`
5. `./scripts/feeds update -a`
6. `./scripts/feeds install -a`
7. 拷 `files/` → `openwrt/files`，拷 `.config`，跑 `diy-part2.sh`  
   diy-part2 会：
   - 把 LuCI 默认语言改成 `zh_cn`
   - 写 banner
   - 用 `scripts/patch-factory-recipe.py` 给 `jdcloud_re-ss-01` 加上  
     `IMAGE/factory.bin := append-kernel | pad-to $(KERNEL_SIZE) | append-rootfs`  
     **故意不用** `Device/EmmcImage`（那种 factory 只有 rootfs，Hugo U-Boot 刷了不持久）
8. `make defconfig`，并检查这些包必须是 `=y`：
   - `luci`
   - `kmod-usb-net-rndis`
   - `kmod-usb-net-cdc-ether`
   - `luci-i18n-base-zh-cn`
   - `luci-proto-qmi`
   - `kmod-tun`
   - `luci-app-nikki`
   - `luci-theme-argon`
9. `make download -j8`
10. `make -j$(nproc)`，失败再 `make -j1 V=s`
11. 整理 `openwrt/bin/targets/*/*` 到 `firmware/`，再跑  
    `scripts/make-factory.py <sysupgrade.bin> firmware/`  
    生成 Hugo U-Boot 用的 `*squashfs-factory.bin`
12. `actions/upload-artifact@v4`，保留 14 天
13. `softprops/action-gh-release@v2` 发 Release  
    tag 形如 `{run_number}-{YYYYMMDD-HHMM}`  
    例如最新：`3-20260922-1849`

权限：

```yaml
permissions:
  contents: write
  actions: write
```

没有这个，Release 发不出去。

### 6.4 factory.bin 的二进制格式（刷 U-Boot 必须懂）

`scripts/make-factory.py` 做的事：

1. 打开 ImmortalWrt 的 `*squashfs-sysupgrade.bin`（其实是 tar）
2. 取出 `kernel`（FIT，magic `d00dfeed`，DTB 里要有 `jdcloud,re-ss-01`）和 `root`（squashfs，magic `hsqs`）
3. kernel 后面 **补零到 6MiB（6144KiB）**
4. 再拼 squashfs rootfs
5. **不要** 在 overlay 开头追加 fwtool metadata，否则设置落不到 eMMC

即：

```
[ FIT kernel ][ zero pad to 6MiB ][ squashfs rootfs ]
```

这才是 Hugo U-Boot 网页固件页要的包。

### 6.5 已经跑过的云编译

| Run | 触发 | 结果 | 耗时 | Release |
| --- | --- | --- | --- | --- |
| 35711427865 | push `b143578`（Nikki/Argon） | success | 1h12m | **Arthur 20260922-1849**（当前在用） |
| 35095196250 | push `ad4a62c`（factory 打包） | success | 1h26m | Arthur 20260916-2146 |
| 35084427283 | push `233beb1`（工作流就位） | success | 43m | Arthur 20260916-1903 |

当前机器上刷的是 **20260922** 那一版（ImmortalWrt SNAPSHOT，当时内核 `6.18.52`，版本串曾见 `r41408-1e93f17910`）。

Release 页：  
https://github.com/3584569425/immortalwrt-arthur/releases

最新 Release 资源（不要拿 initramfs 去刷）：

- `immortalwrt-qualcommax-ipq60xx-jdcloud_re-ss-01-squashfs-factory.bin` ← **U-Boot 刷这个**
- `immortalwrt-qualcommax-ipq60xx-jdcloud_re-ss-01-squashfs-sysupgrade.bin` ← **LuCI 升级用这个**
- `immortalwrt-qualcommax-ipq60xx-jdcloud_re-ss-01-initramfs-uImage.itb` ← **RAM 临时系统，禁止当刷机包**
- `config.build` / `config.buildinfo` / `feeds.buildinfo` / `sha256sums` / `manifest` / `profiles.json` / `version.buildinfo`

---

## 7. 固件配方里有什么

### 7.1 机型

```
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq60xx=y
CONFIG_TARGET_qualcommax_ipq60xx_DEVICE_jdcloud_re-ss-01=y
```

硬件：京东云亚瑟 RE-SS-01，SoC **IPQ6000**，eMMC，双频 Wi-Fi。设备树 `config@cp03-c2`。

### 7.2 已打进镜像的东西（精简，不装 iStore）

- LuCI + 中文 + bootstrap + **Argon**（`99-arthur-setup` 把默认主题指到 Argon）
- USB 网卡：RNDIS / CDC Ether / NCM / MBIM / QMI / iPhone / RTL8152 / ASIX 等
- 4G/5G 协议页：`luci-proto-3g/ncm/qmi/mbim`，`uqmi`/`umbim`/`comgt`
- USB 存储和常见文件系统
- `luci-app-upnp`、`watchcat`、`ttyd`
- **Nikki / Mihomo**（Clash 兼容）+ `kmod-tun` + `kmod-nft-tproxy` + `kmod-nft-socket` + `kmod-dummy` + `yq`
- 诊断：`ethtool`、`ip-full`、`iperf3`、`htop`、`curl`、`openssh-sftp-server`

**没有** 插件商店、iStore。要加包装进 `.config` 再云编译，不要在 SNAPSHOT 上随便 `opkg` 装和内核版本不一致的 kmod，会崩。

### 7.3 第一次开机默认（uci-defaults）

`files/etc/uci-defaults/99-arthur-setup` 只在 **第一次** 从 squashfs 落到 overlay 时跑：

- hostname `ImmortalWrt`
- 时区 `CST-8` / `Asia/Shanghai`
- LuCI 语言 `zh_cn`，主题 Argon
- 新建 DHCP 接口 `usbwan`，metric 10，关 IPv6
- 把 `usbwan` 加进防火墙 wan 区
- 打开双频 AP：出厂 SSID `Arthur` / `Arthur-5G`，密码 `12345678`（这是固件默认，**不是** 现在机器上正在用的名字）
- USB autosuspend 关掉
- 打开 `usbwan-watchdog`

Nikki **默认关闭**，不会一开机就接管网络。订阅是刷进去之后在后台加的，不属于 git 配方。

### 7.4 USB 随身 WiFi 为什么能当网线

1. 热插拔 `files/etc/hotplug.d/net/21-usb-wan`：USB 网卡（rndis/cdc 等）改名为固定接口 `usbwan`，并 `ifup usbwan`
2. QMI/MBIM 4G 模块 **不** 走这条 DHCP 网卡逻辑，要在 LuCI 里选对应协议
3. `usbwan-watchdog` 每 12 秒看接口还在不在，丢了就尝试重命名或 USB reset
4. `21-usb-power` + `usbcore autosuspend=-1` 避免网卡被 USB 省电挂掉

这是当初重做固件的主因：原固件 USB 网口经常在网络里消失。

---

## 8. 刷机（换电脑后也按这个来）

机器已经刷了 **Hugo U-Boot**。eMMC 有 A/B 两套分区。

### 8.1 U-Boot 刷（全新或救砖）

1. 到 Releases 下  
   `immortalwrt-qualcommax-ipq60xx-jdcloud_re-ss-01-squashfs-factory.bin`
2. 电脑网线接亚瑟 **LAN**
3. 按住 Reset 上电，灯闪几下后常亮
4. 浏览器打开 http://192.168.1.1
5. **只在固件页** 上传 `*squashfs-factory.bin`
6. 不要打开：
   - `/uimage.html`：只启动内存系统，重启就没了
   - `/img.html`：刷分区表
   - `/uboot.html`：刷 U-Boot 本身
7. 等它写完 eMMC 并自动重启。第一次开机 1–2 分钟
8. 进后台改密码，**再重启一次**。设置还在，才说明 overlay 在 eMMC 上

`initramfs-uImage.itb` 是内存固件，**绝对不要当刷机包**。刷了看起来能进系统，断电或 overlay 在 `/tmp`，设置全丢。

如果刷完还是旧系统：多半是另一套 A/B 分区在启动。再进 U-Boot 刷一次 factory，或用 U-Boot bootconfig 切分区。

### 8.2 已经在 ImmortalWrt 里以后

用 `*squashfs-sysupgrade.bin`，LuCI 系统升级。  
**U-Boot 再刷 factory 会清空配置。**

### 8.3 旧电脑上的本地刷机包

```
/Users/pingguobijiben/Documents/chatgpt/openwrt/firmware/
  immortalwrt-qualcommax-ipq60xx-jdcloud_re-ss-01-squashfs-factory.bin     ~37M
  immortalwrt-qualcommax-ipq60xx-jdcloud_re-ss-01-squashfs-sysupgrade.bin  ~37M
```

这是 20260922 那次编的。gitignore 了，换电脑请从 Release 重新下，或 U 盘拷 `firmware/`。

---

## 9. 刷进去之后，机器上后来改过什么（不在 git 里）

这些是 **运行中 overlay 上的配置**，重新刷 factory 会丢，需要的话在新电脑上对着活机器迁，不要写进公开仓库。

已知、和开发有关的状态（2026-09 到 10 月）：

| 项 | 说明 |
| --- | --- |
| 管理地址 | `192.168.1.1` |
| SSH | 开着，用户 `root`，密码认证 |
| overlay | 持久 ext4，`/dev/loop0`，LABEL `rootfs_data`，大约 1.9G，`.fs_state -> 2` |
| 只读根 | `/rom` squashfs 在 `mmcblk0p18` |
| WAN | USB 随身 WiFi → 接口名 `usbwan`，DHCP，常见地址 `192.168.100.100/24`，网关 `192.168.100.1` |
| LAN | `192.168.1.0/24` |
| DNS | dnsmasq `noresolv=1`，`223.5.5.5` / `119.29.29.29` / `8.8.8.8`；`usbwan.peerdns=0` |
| 硬件流量卸载 | **必须关**，否则 Nikki TUN 分流失效 |
| UPnP | 关过 |
| Nikki | 后来启用了，TUN + fake-ip，LAN/路由器都走代理，模式 rule |
| 面板 | `http://192.168.1.1:9090/ui`，主机填 `192.168.1.1` 不要填 `127.0.0.1` |
| 本机 DHCP 静态 | Mac `192.168.1.158` 绑过当前隐私 MAC 和真实 Wi-Fi MAC |
| INET 美国节点 | 从亚瑟 USB WAN 直连经常失败，德国节点可用；这是线路/节点 IP 问题，不是 git 配方问题 |

Nikki 的订阅、节点、geo 文件在 `/etc/nikki/`，**不要** 把订阅 URL 推进 git。`backup-20260922/setup-nikki.sh` 里有旧订阅，那个目录不要提交。

---

## 10. 换电脑后怎么继续改固件

日常循环：

```bash
# 1. 改配方
vim .config                 # 加/减包
vim files/etc/...           # 改首次开机或热插拔
vim diy-part1.sh            # 改 feeds

# 2. 提交并推送（会自动云编译）
git add -A
git status                  # 确认没有把 *.bin、backup、订阅写进去
git commit -m "..."
git push origin main

# 3. 看编译
gh run watch
# 或打开
# https://github.com/3584569425/immortalwrt-arthur/actions

# 4. 编完从 Releases 下 factory 或 sysupgrade
gh release list
gh release download --pattern '*factory.bin'
```

改完 `workflow/build.yml` 时，**同步改** `.github/workflows/build.yml`，Actions 只认后者。

本地全量编译不是必须的。这台设备的官方源码树很大，旧方案就是 GitHub Actions。新电脑如果要本地编：

1. 按 ImmortalWrt 文档准备 Linux（macOS 原生编这个 target 不划算）
2. clone `immortalwrt/immortalwrt` master
3. 把本仓库的 `diy-part1.sh`、`diy-part2.sh`、`.config`、`files/` 按工作流同样顺序套进去
4. `make defconfig && make -j$(nproc)`
5. 用 `scripts/make-factory.py` 从 sysupgrade 再打 factory

更省事：继续云编译。

---

## 11. 新电脑建议拷贝的东西

**必须 / 从 GitHub 就能拿到：**

- 本仓库（clone 即可）
- GitHub 账号登录（`gh auth login`，账号 `3584569425`）
- Releases 里的刷机包

**建议从旧电脑拷，git 里没有：**

```
/Users/pingguobijiben/Documents/chatgpt/openwrt/firmware/          # 已下载的 bin
/Users/pingguobijiben/Documents/chatgpt/openwrt/backup-20260922/   # 含敏感信息，只放私密盘
```

**不要拷、不要提交：**

- `gh` 的 keyring token（新电脑重新 login）
- 亚瑟 root / Wi-Fi / Nikki 密码
- 订阅链接
- `backup-20260922/setup-nikki.sh` 里的 URL（旧订阅，且不该进公开仓库）

**旧电脑 git 全局里和 GitHub 有关的：**

```
credential.https://github.com.helper=!/Users/pingguobijiben/.local/bin/gh auth git-credential
user.name=xiaozhengyi
user.email=179310889+3584569425@users.noreply.github.com
```

新电脑配同等即可，路径改成新电脑的 `gh`。

---

## 12. 常用 URL 和命令速查

```text
仓库:     https://github.com/3584569425/immortalwrt-arthur
Actions:  https://github.com/3584569425/immortalwrt-arthur/actions
Releases: https://github.com/3584569425/immortalwrt-arthur/releases
上游:     https://github.com/immortalwrt/immortalwrt
Nikki:    https://github.com/nikkinikki-org/OpenWrt-nikki
设备码:   https://github.com/login/device
亚瑟:     http://192.168.1.1
面板:     http://192.168.1.1:9090/ui
```

```bash
gh auth login
gh auth status
gh auth setup-git
git clone https://github.com/3584569425/immortalwrt-arthur.git
gh workflow run "Build ImmortalWrt" --ref main
gh run list --limit 5
gh run watch
gh release list
gh release download 3-20260922-1849 --pattern '*factory.bin'
```

---

## 13. 踩过的坑（换电脑后不要重踩）

1. **没 `workflow` scope 就推不了 Actions 文件。** 新电脑 `gh auth login` 务必带 `workflow`。
2. **刷 initramfs / 打开 `/uimage.html` = 临时系统。** overlay 在内存，重启配置全没。
3. **Hugo U-Boot 要 kernel+rootfs 的 factory.bin**，不是 ImmortalWrt 默认那种 EmmcImage rootfs-only。
4. **SNAPSHOT 的 kmod 必须和当时编的内核一起打进镜像。** 运行后再 opkg 装 TUN 等模块会版本不合、可能 panic。所以 Nikki 的 kmod 是编进固件的。
5. **Nikki TUN 开着时不要开硬件流量卸载。**
6. **不要 `insmod` 乱匹配的 kmod。**
7. 公开仓库里不要出现订阅 token、root 密码。
8. 美国 INET 节点从亚瑟 USB WAN 直连失败，换移动/电信随身 WiFi 都试过，是节点 IP 从该出口不可达，不是 git 仓库能修的。
9. 本仓库 `workflow/build.yml` 和 `.github/workflows/build.yml` 要一起改。

---

## 14. 本机私密信息（不要写进 git，换电脑自己抄）

从旧电脑或正在运行的亚瑟上取，不要贴到这份会进 GitHub 的文档里：

- [ ] 亚瑟 SSH / LuCI root 密码
- [ ] 当前 Wi-Fi SSID 和密码（出厂配方是 `Arthur` / `12345678`，后来改过）
- [ ] Nikki 面板 / API secret、用户名密码
- [ ] 各家订阅 URL（INET / 狗子云 / FSL 等）
- [ ] 若用过设备码登录，新电脑直接重新 `gh auth login`，不要复制旧 `gho_` token

在亚瑟上查看（连着它的 LAN/Wi-Fi 时）：

```bash
ssh root@192.168.1.1
uci show nikki | sed '/url=/s/=.*/=*** /; /secret=/s/=.*/=*** /; /password=/s/=.*/=*** /'
uci show wireless
uci show network.usbwan
df -h /overlay
```

---

## 15. 交接检查单

新电脑上做完这些就可以开发和云编译了：

1. 安装 `git`、`gh`
2. `gh auth login` 到账号 `3584569425`，scopes 含 `repo` + `workflow`
3. `gh auth setup-git`
4. `git config --global user.name/email` 如上
5. `git clone https://github.com/3584569425/immortalwrt-arthur.git`
6. `gh workflow list` 能看到 `Build ImmortalWrt`
7. （可选）`gh workflow run "Build ImmortalWrt"` 验证还能编
8. 从 Releases 下载 factory/sysupgrade，不要用 initramfs
9. 私密配置从旧电脑/路由器手抄，不进 git
