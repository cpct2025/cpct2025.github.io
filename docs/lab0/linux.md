# Debian 13.1.0 on Windows 11 Hyper-V - from download to installation, config and applications

!!! Warning "本文已基本完成，尚需审阅和校对"

> 本文第一部分适用于 Windows 11 各种版本安装 Debian 13.1.0 虚拟机。教程只说操作，一般不讲为什么，可自行查阅资料。
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

> 约定：`USER_NAME` 为在用户命令行 Shell 中执行 `whoami` 或 `echo $USER` 命令后返回的结果，即用户名；`HOME` 为在用户命令行 Shell 中执行 `echo $HOME` 命令后返回的结果。

???+ question "命令行 Shell 是什么？在哪里打开？"

    在虚拟机图形化界面中按 Win 键或 Command 键或屏幕左上角，然后点击右下角九个点的图样，选择 Terminal 即为命令行。

    > Debian 系发行版默认使用 bash 作为 Shell

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

!!! Warning "示例输出只是方便演示操作，具体每个人的电脑 IP 可能不尽相同"

使用 `ip a` 命令可以查看 ip 地址，注意 lo 为本地回环而不是在互联网上的地址。

```bash
ip a

# 一个示例输出
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

这里的 `172.27.253.209` 就是当前的 IPv4 地址，后面的 `20` 是子网掩码，对应 `255.255.240.0`，`172.27.255.255` 是广播地址。

使用 `ip r` 命令可以查看当前默认网关：

```bash
ip r

# 一个示例输出
default via 172.27.240.1 dev eth0 proto dhcp src 172.27.253.209 metric 100
172.27.240.0/20 dev eth0 proto kernel scope link src 172.27.253.209 metric 100
```

这里的 `172.27.240.1` 就是当前的默认网关。

如果安装了 GNOME 或其他桌面环境，默认的网络配置是 NetworkManager，可用 `sudo systemctl status NetworkManager` 命令查看服务运行状态。采用命令行配置静态 IP 地址时，为避免冲突，需要先关闭 NetworkManager，使用 /etc/network/interfaces 管理网络。

##### 使用 NetworkManager 配置静态 IP

点击右上角打开设置齿轮，左侧选择 Network，点击右边 “Wired” 右下方的小齿轮进入配置页面，点击 IPv4 后选择 “Manual”，Addresses 中分别填入刚刚通过命令行查看获得的 Address: 172.27.253.209, Netmask: 255.255.240.0, Gateway: 172.27.240.1。**Netmask 有关计算可以看后面的"IP 地址、子网掩码、广播地址和网关相关知识"。**填好之后点 Apply 即可。

##### 使用命令行配置静态 IP

首先需要停用 NetworkManager，然后通过编辑 /etc/network/interfaces 文件来实现网络配置。

原始的一个 /etc/network/interfaces 文件示例如下：

```plain
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback
```

使用 `sudo nano /etc/network/interfaces` 命令将其改为：

```plain
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
        address 172.27.253.209
        netmask 255.255.240.0
        gateway 172.27.240.1
```

改完后用 `sudo systemctl restart networking.service` 命令重启网络服务即可。

???- question "如何停用 NetworkManager？"

    ```bash
    # 停止当前运行的 NetworkManager 服务
    sudo systemctl stop NetworkManager
    # 禁用开机自启动（避免重启后自动运行）
    sudo systemctl disable NetworkManager
    ```

???- question "IP 地址、子网掩码、广播地址和网关相关知识"

    1. IP 地址（Internet Protocol Address）是设备在网络中的唯一标识，目前常用的 IP 地址分为两种：
        1. IPv4：由 32 位二进制组成，通常写成四段十进制格式，如 192.168.1.1。
        2. IPv6：由 128 位二进制组成，采用十六进制表示，如 2001:db8::ff00:42:8329。
        
        一个 IP 地址由两个部分组成：
            1. 网络地址（Network Address，网络号）：用于标识整个网络，所有处于同一网络的设备共享相同的网络地址。
            2. 主机地址（Host Address，主机号）：用于标识同一网络中的具体设备，每台设备的主机地址必须唯一。
    2. 子网掩码（Subnet Mask）用于确定 IP 地址的网络部分和主机部分。常见的子网掩码示例如下：
        1. 255.255.255.0(/24)表示前 24 位是网络地址，剩余 8 位是主机地址。
        2. 255.255.0.0(/16)表示前 16 位是网络地址，剩余 16 位是主机地址。

        简单来说，子网掩码的功能是告知主机或路由设备，地址的哪一部分是网络号，包括子网的网络号部分，哪一部分是主机号部分。

        **在子网掩码中，网络部分和子网络部分对应的位全为 1，主机部分对应的位全为 0**

        通过将子网掩码与 IP 地址进行“与”操作，可提供所给定的 IP 地址所属的网络号（包括子网络号）
    3. 广播地址（Broadcast Address）是计算机网络中用于向同一网络段内所有设备发送数据的特殊地址。
    4. 网关（Gateway）又称网间连接器、协议转换器，完成不同网络协议转换的设备。主要指传输层以上的协议转换。用于不同网络的互连。

    参见 <https://blog.csdn.net/qq_41207757/article/details/107839099>，计算工具可用 <https://tool.hiofd.com/subnet-mask-calculator/>

#### Manual DNS

如果安装了 GNOME 或其他桌面环境，默认的网络配置是 NetworkManager，可用 `sudo systemctl status NetworkManager` 命令查看服务运行状态。采用命令行配置手动 DNS 时，为避免冲突，需要先关闭 NetworkManager，使用 /etc/resolv.conf 管理 DNS。

##### 使用 NetworkManager 配置 DNS

点击右上角打开设置齿轮，左侧选择 Network，点击右边 “Wired” 右下方的小齿轮进入配置页面，在 DNS 下方的框框中填入 `202.38.64.56,202.38.64.17,114.114.114.114`，填好之后点 Apply 即可。

##### 使用命令行配置 DNS

首先需要停用 NetworkManager，然后通过编辑 /etc/resolv.conf 文件来实现网络配置。

???- question "如何停用 NetworkManager？"

    ```bash
    # 停止当前运行的 NetworkManager 服务
    sudo systemctl stop NetworkManager
    # 禁用开机自启动（避免重启后自动运行）
    sudo systemctl disable NetworkManager
    ```

使用 `sudo nano /etc/resolv.conf` 命令编辑 resolv.conf 文件（若没有文件则创建文件）为：

```plain
nameserver 202.38.64.56
nameserver 202.38.64.17
nameserver 114.114.114.114
```

???+ question "通过修改 /etc/network/interfaces 文件也可实现 DNS 的配置"

    ```plain
    # This file describes the network interfaces available on your system
    # and how to activate them. For more information, see interfaces(5).

    source /etc/network/interfaces.d/*

    # The loopback network interface
    auto lo
    iface lo inet loopback

    auto eth0
    iface eth0 inet static
            address 172.27.253.209
            netmask 255.255.240.0
            gateway 172.27.240.1
            dns-nameservers 202.38.64.56 202.38.64.17 114.114.114.114
    ```

???+ question "如何锁定配置文件，防止被系统改写？"

    例如使用 `sudo chattr +i /etc/resolv.conf` 命令为文件添加不可变（immutable）属性，使其无法被修改。可通过 `lsattr /etc/resolv.conf` 命令验证锁定状态，如需解锁（恢复可修改状态），可通过 `sudo chattr -i /etc/resolv.conf` 命令实现。

    ```bash
    lsattr /etc/resolv.conf
    # 未锁定状态
    --------------e------- /etc/resolv.conf
    # 锁定状态
    ----i---------e------- /etc/resolv.conf
    ```

### SSH Config

如果在装系统时没有勾选 SSH Server 选项，可通过 `sudo apt install openssh-server` 命令下载。

在 Windows 10 或 Windows 11 系统中按快捷键 `Win + X` 或右键点击 Windows 徽标键，打开终端或 Windows Powershell，可通过输入 `ssh USER_NAME@HostName` 通过 ssh 访问远程主机或虚拟机。

#### Config 文件

Windows 10 和 11 默认支持 ssh，其连接服务器的配置文件为 `~\.ssh\config`，一般是由许多具有形如如下格式的结构组成的：

```plain
Host debian
    HostName 172.27.253.209
    User USER_NAME
    ForwardX11 yes
    ForwardX11Trusted yes
    ProxyCommand none
    TCPKeepAlive yes

```

当使用 `ssh debian` 命令时，会自动找到这个配置文件并将 debian 解析为 172.27.253.209 并连接，相当于原始的 `ssh -XY USER_NAME@172.27.253.209`

#### 公钥认证登录

> 参见 <https://101.lug.ustc.edu.cn/Ch01/supplement/#ssh>

#### X11 Forwarding

ssh 也有图形化支持，即 X11 Forwarding，参见 <https://zhuanlan.zhihu.com/p/16034352413>

### 防火墙

#### ufw

#### iptables

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

### VSCode & code-server

如果已经配置好了 ssh config 文件，那么可以直接在本地 VSCode 中使用 Remote - SSH 插件连接到远程主机或虚拟机，参见 <https://vlab.ustc.edu.cn/docs/tutorial/vscode2vlab/#installvs>

### uv

Python 包管理器，参见 <https://uv.doczh.com/>

```bash
sudo apt install curl -y
# 二选一
curl -LsSf https://astral.sh/uv/install.sh | sh
# wget -qO- https://astral.sh/uv/install.sh | sh
```

### 编程语言配置

参见 <https://101.lug.ustc.edu.cn/Ch07/>

### Docker

参见 <https://101.lug.ustc.edu.cn/Ch08/>

```bash
sudo apt install -y docker.io docker-compose

sudo systemctl enable docker

sudo systemctl start docker

sudo usermod -aG docker USER_NAME

sudo nano /etc/docker/daemon.json
```

```plain
{
    "registry-mirrors": [
        "https://docker.m.daocloud.io",
        "https://docker.imgdb.de",
        "https://docker-0.unsee.tech",
        "https://docker.hlmirror.com",
        "https://docker.1ms.run",
        "https://func.ink",
        "https://lispy.org",
        "https://docker.xiaogenban1993.com",
        "https://docker.1panel.live"
    ]
}
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### Geant4

> Geant4 is a free software package composed of tools which can be used to accurately simulate the passage of particles through matter.

Geant4 是由欧洲核子研究组织基于 C++ 面向对象技术开发的蒙特卡罗应用软件包，用于模拟粒子在物质中输运的物理过程。由于具有良好的通用性和扩展能力，Geant4 在涉及微观粒子与物质相互作用的诸多领域获得了广泛应用。教程参见 <https://zhuanlan.zhihu.com/c_1238110686846484480>

更详细的安装可见 <https://github.com/yzguo/geant4-install>

#### 在物理机/虚拟机中安装 Geant4

> 参见 <https://geant4-userdoc.web.cern.ch/UsersGuides/InstallationGuide/html/index.html>

```bash
sudo apt update && sudo apt upgrade -y
# Basic
sudo apt install -y build-essential cmake wget axel libexpat1-dev qtbase5-dev libvtk9-dev libvtk9-qt-dev
```

```bash
sudo apt update && sudo apt upgrade -y
# Basic
sudo apt install -y build-essential ca-certificates cmake wget axel libexpat1-dev
# Qt5
sudo apt install qtbase5-dev
# Qt5 extra
sudo apt install qtchooser qt5-qmake qtbase5-dev-tools qtcreator libqt5charts5-dev libqt5datavisualization5-dev libqt5gamepad5-dev libqt5networkauth5-dev libqt5opengl5-dev libqt5sensors5-dev libqt5serialport5-dev libqt5svg5-dev libqt5texttospeech5-dev libqt5virtualkeyboard5-dev libqt5waylandclient5-dev libqt5waylandcompositor5-dev libqt5webchannel5-dev libqt5websockets5-dev libqt5webview5-dev libqt5x11extras5-dev libqt5xmlpatterns5-dev
# OpenGL
sudo apt install -y libgl1-mesa-dev libglu1-mesa-dev freeglut3-dev mesa-utils mesa-common-dev libglew-dev libglfw3-dev
# VTK
sudo apt install -y libvtk9-dev libvtk9-qt-dev

mkdir -p $HOME/geant4
cd $HOME/geant4/
axel -n 32 https://gitlab.cern.ch/geant4/geant4/-/archive/v11.3.2/geant4-v11.3.2.tar.gz
tar -xzf geant4-v11.3.2.tar.gz
mkdir geant4-build geant4-install
cd geant4-build/

cmake -DCMAKE_INSTALL_PREFIX=$HOME/geant4/geant4-install -DGEANT4_INSTALL_DATA=ON -DGEANT4_USE_QT=ON -DGEANT4_USE_VTK=ON $HOME/geant4/geant4-v11.3.2
make -j$(nproc)
make install

cd $HOME/geant4/geant4-install/bin
source geant4.sh
echo "source $HOME/geant4/geant4-install/bin/geant4.sh" >> $HOME/.bashrc
```

#### 在 Docker 中安装 Geant4

需要有 sudo 权限或以 root 用户执行如下命令：

```bash
git clone https://github.com/yzguo/geant4-install.git
cd geant4-v11.3.2-docker/
make build
make run
```

然后就可以使用用浏览器访问 127.0.0.1:8080 来使用 Geant4 了，也可以在局域网中通过将 127.0.0.1 替换为主机/虚拟机的 IP 地址来访问。
