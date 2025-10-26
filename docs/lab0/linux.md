# Debian 13.1.0 on Windows 11 Hyper-V - from download to installation, config and applications

!!! Warning "本文尚未完成，不是正式版本"

> 本文适用于 Windows 11 各种版本安装 Debian 13.1.0 虚拟机。教程只说操作，一般不讲为什么，可自行查阅资料。
>
> 有关安装后配置以及软件的安装，在 Debian 系（Debian、Ubuntu 等）是通用的。
>
> 惯用语约定：有时候分层次连续点击的时候会用 `-` 连接几个需要点击的内容。

## Windows 11 Config

`Win + S` 打开搜索框搜索“控制面板”，点左上角“类别”里的“小图标”，点击“程序与功能”，然后点击左侧的“启用或关闭 Windows 功能”，在弹出的窗口中把 “Hyper-V” 大项和 “Windows 虚拟机监控程序平台”（如果有的话）打上对勾，点击确定并等待，等待配置结束后重启电脑。

重启电脑后再次 `Win + S` 打开搜索框搜索 “Hyper-V”，点击 “Hyper-V 管理器”打开应用界面。

## Download Debian 13.1.0

浏览器打开网址 <https://mirrors.ustc.edu.cn/>，下拉在右侧点击“获取安装镜像”，在弹出框中选择发行版 Debian，发行版版本选择 13.1.0 (amd64, Network installer)，获取 iso 镜像文件。

## Install Debian 13.1.0

在打开的 “Hyper-V 管理器”应用界面点击右侧的“新建” - “虚拟机”，在弹出的窗口点击“下一页”，然后为虚拟机起个名字，如 debian，然后点击两次下一页，启动内存最好设为 4096MB，需要保证比 2048MB 大，然后在下一页中“连接”下拉菜单中选择 “Default Switch”，点击两次下一页，选择“从可启动的 CD/DVD-ROM 安装操作系统(C)”，选择“映像文件(.iso)(I)”，然后在“浏览”中选择刚刚在 [Windows 11 Config](#windows-11-config) 步骤中下载好的镜像文件，然后点击下一页，确认无误后点击完成。此时 “Hyper-V 管理器”应用界面中央会显示刚刚加入的虚拟机。

右键点击刚刚加入的虚拟机选择“设置”，在弹出的界面中选择“安全”，取消“启用安全启动”左侧的对勾，点击应用并确定。再次右键点击虚拟机，选择“启动”，然后左键双击虚拟机进入图形化界面。点击回车进入图形化安装界面。

> 本文选择英文系统进行安装。

点五次回车键，进入 root 密码设置环节设置密码后进入下一页，设置用户名进入下一页，点击回车键后设置用户密码后进入下一页，一路回车（5 至 6 次）直到出现两页循环出现为止，在 “Yes” 与 “No” 中按键盘的下箭头选择 “Yes” 后回车后等待配置完成，然后点一次回车进入 `Configure the package manager` 界面，选择 `China` 后回车，再选择 `mirrors.ustc.edu.cn` 后回车两次并等待，再次按回车并等待，最后的桌面环境可以选择 GNOME，最好也选上 SSH server，最后点击 continue 并等待安装完成并重启即可。

## Config Debian 13.1.0

> 约定：`USER_NAME` 为在用户命令行中执行 `whoami` 命令后返回的结果，即用户名。

???+ question "命令行是什么？在哪里打开？"

    在虚拟机图形化界面中按 Win 键或 Command 键或屏幕左上角，然后点击右下角九个点的图样，选择 Terminal 即为命令行。

### sudo

关于用户使用 sudo 命令，有两种配置方法，分别是将用户加入 sudo 用户组以及 visudo，任选其一即可。

**两种方法均需要先先切换到 root 用户！**

#### 1. sudo group

在 root 账户下执行命令 `sudo usermod -aG sudo USER_NAME` 即可。

#### 2. visudo

在 root 账户下执行命令 `visudo`，在 `%sudo   ALL=(ALL:ALL) ALL` 行下面添加：

```plain
# 注意 USER_NAME 是你的用户名
USER_NAME ALL=(ALL:ALL) ALL
```

如果每次不想输入密码，也可以这么写：

```plain
USER_NAME ALL=(ALL:ALL) NOPASSWD:ALL
```

### Crontab 自动任务

像 `apt update` 和 `apt upgrade -y` 这种命令需要经常执行的，可以直接在 root 用户中设置 crontab 自动任务。

使用 `su - root` 后输入密码进入 root 用户中执行如下命令：

```bash
crontab -e

# 如果是第一次执行，会弹出让你选择什么编辑器，一般直接回车使用默认的 nano 即可
```

例如在最下方写入：

```plain
# 每天 9:00 和 21:00 自动更新 apt
0 9,21 * * * apt update && apt upgrade -y
```

然后按 `ctrl + X` 后点 `Y` 然后回车保存。

???+ question "也可以选择在用户层面执行"

    ```plain
    # 每天 9:00 和 21:00 自动更新 apt
    0 9,21 * * * sudo apt update && sudo apt upgrade -y
    ```

### Network Config

#### Static IPv4

!!! Warning "此方法未对路由器进行配置，对于多个虚拟机的场景可能无法使用"

使用 `ip a` 命令可以查看 ip 地址，注意 lo 为本地回环而不是在互联网上的地址。

```bash
ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:bc:f5:08 brd ff:ff:ff:ff:ff:ff
    altname enx00155dbcf508
    inet 172.27.253.209/20 brd 172.27.255.255 scope global dynamic noprefixroute eth0
       valid_lft 84712sec preferred_lft 84712sec
    inet6 fe80::215:5dff:febc:f508/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

这里的 `172.27.253.209` 就是当前的 IPv4 地址，后面的 `20` 是子网掩码，`172.27.255.255` 是广播地址。

使用 `ip r` 命令可以查看当前默认网关：

```bash
ip r
default via 172.27.240.1 dev eth0 proto dhcp src 172.27.253.209 metric 100
172.27.240.0/20 dev eth0 proto kernel scope link src 172.27.253.209 metric 100
```

这里的 `172.27.240.1` 就是当前的默认网关。

???- question "IP 地址、子网掩码、广播地址和网关相关知识"

    1. IP 地址（Internet Protocol Address）是设备在网络中的唯一标识，就像是每台计算机的 "门牌号"。目前常用的 IP 地址分为两种：
       1. IPv4：由 32 位二进制组成，通常写成四段十进制格式，如 192.168.1.1。
       2. IPv6：由 128 位二进制组成，采用十六进制表示，如 2001:db8::ff00:42:8329。
    2. 子网掩码（Subnet Mask）用于确定 IP 地址的网络部分和主机部分。常见的子网掩码示例如下：
       1. 255.255.255.0（/24）表示前 24 位是网络地址，剩余 8 位是主机地址。
       2. 255.255.0.0（/16）表示前 16 位是网络地址，剩余 16 位是主机地址。
       简单来说，子网掩码的功能是告知主机或路由设备，地址的哪一部分是网络号，包括子网的网络号部分，哪一部分是主机号部分。
       **在子网掩码中，网络部分和子网络部分对应的位全为 1，主机部分对应的位全为 0**
       通过将子网掩码与 IP 地址进行“与”操作，可提供所给定的 IP 地址所属的网络号（包括子网络号）

#### Manual DNS

### SSH Config

## Applications

### Vim

宇宙第一文本和代码编辑器

```bash
sudo apt install vim -y
```

### ncdu

查看磁盘使用与空间的工具

```bash
sudo apt install ncdu -y
```

### htop

类似 Windows 的任务管理器

```bash
sudo apt install htop -y
```

### uv

Python 包管理器，<https://uv.doczh.com/>

```bash
# 二选一
curl -LsSf https://astral.sh/uv/install.sh | sh
# wget -qO- https://astral.sh/uv/install.sh | sh
```

### 编程语言配置

### Docker

### Geant4
