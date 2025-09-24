# C 程序的编译—链接全过程详解

> 目的：本文件详细介绍从 C 源码到可执行程序（或共享库）的整个流程——预处理、编译、汇编、链接、以及运行时装载。面向读者：有一定 C 语言基础、希望深入理解编译器/链接器/加载器如何协同工作的程序员。

## 目录

1. 概览（总体流程）
2. 简单示例与命令（快速上手）
3. 预处理（Preprocessing）
4. 编译（Compilation）——C 源码到汇编
5. 汇编（Assembly）——汇编到目标文件（.o）
6. 链接（Linking）——把目标文件与库组合成可执行文件或共享对象
7. 运行时装载（动态链接器 / loader）
8. 静态库（.a）与共享库（.so）比较与制作方法
9. 启动文件、CRT（C 运行时）以及 \_start 与 main 的关系
10. 高级话题（PIE/FPI C、GOT/PLT、LTO、符号版本、弱符号等）
11. 常见错误、排错技巧与工具清单
12. 完整示例：多文件项目的构建流程
13. 推荐阅读与参考

---

## 1. 概览（总体流程）

将 C 程序从源码变成可运行程序，通常经历以下主要阶段：

* **预处理（Preprocessing）**：处理 `#include`、`#define`、条件编译指令，将源码展开生成“翻译单元”（translation unit）。
* **编译（Compilation）**：将预处理后的 C 源码解析、类型检查、优化并生成汇编代码（或中间表示再到汇编）。
* **汇编（Assembly）**：把汇编代码转换成机器码并封装成目标文件（object file，通常是 `.o`）。目标文件包含节（sections）、符号表和重定位（relocation）信息。
* **链接（Linking）**：把一个或多个目标文件和库（静态库 `.a` 或共享库 `.so`）合并，解析符号引用、执行重定位、生成最终可执行文件或共享库。
* **运行时装载（Loading / Dynamic Linking）**：当使用动态链接时，程序启动时（或首次调用函数时）由动态链接器（ld-linux.so）加载所需共享库，完成运行时重定位，初始化运行时环境并转入 `main`。

把这些阶段串联起来，可以用如下比喻：**预处理**相当于把剧本展开并把注释去掉；**编译**把剧本翻译成演员台词（汇编）；**汇编**把台词变成演员的声音（机器码）并装入不同舞台区域（节）；**链接**把所有演员和舞台道具拼成完整的表演；**装载**把表演搬到剧院并点亮灯光，正式开始演出。

---

## 2. 简单示例与命令（快速上手）

先用一个最小示例说明每一阶段常用命令：

`hello.c`：

```c
#include <stdio.h>

int main(void) {
    printf("Hello, world\n");
    return 0;
}
```

常用 GCC 驱动命令：

* 预处理：`gcc -E hello.c -o hello.i`  （输出预处理结果）
* 生成汇编：`gcc -S hello.c -o hello.s` （生成汇编源码）
* 汇编为目标文件：`gcc -c hello.c -o hello.o` （只到 .o，不链接）
* 链接生成可执行文件：`gcc hello.o -o hello` 或 `gcc hello.c -o hello`（一次完成所有阶段）

调试/优化相关：

* `-g`：生成调试信息（DWARF）
* `-O0/-O1/-O2/-O3/-Os`：优化等级
* `-save-temps`：保存中间文件（预处理、汇编等）

查看文件格式和符号：

* `file hello`、`readelf -h hello`、`readelf -S hello`、`nm hello`、`objdump -d hello`、`ldd hello`（动态库依赖）

---

## 3. 预处理（Preprocessing）

**功能**：按 C 预处理指令处理源码，展开 `#include` 文件、替换宏（`#define`）、移除或保留注释（取决于选项）、执行条件编译（`#ifdef/#if`）等，输出完整的“翻译单元”。

**关键点**：

* `#include "file.h"` 和 `#include <file.h>` 的查找路径不同（前者优先当前目录，后者优先系统包含目录）。
* `-I` 选项可以添加额外的头文件搜索路径。
* `#pragma` 指令由实现决定，常用于警告控制或结构对齐等。
* 为避免重复包含头文件，常使用 include guard（宏保护）或 `#pragma once`。

**命令**：`gcc -E` 会输出预处理后的结果。调试宏定义时可以使用 `-dD` 来查看宏展开情况。

**注意**：头文件只提供 *接口/声明*（函数原型、类型、宏等），它们并不包含函数体（除内联或宏），因此头文件本身不会直接在链接阶段产生函数定义（除非头文件包含了非 `static inline` 的函数定义，这可能导致重复定义）。

---

## 4. 编译（Compilation）——C 源码到汇编

**功能**：把预处理后的源码进行词法分析、语法分析、语义检查（类型检查等）、生成中间表示（IR），可能执行若干优化，最终生成汇编代码（`.s`）。

**内部步骤（常见的）**：

1. 词法分析 -> 标记流（tokens）
2. 语法分析 -> 抽象语法树（AST）
3. 语义分析（类型检查、符号表）
4. 中间代码生成（IR）
5. 优化（在 IR 级别或代码生成后进行）
6. 目标代码生成 -> 汇编

**编译器的组件**：GCC 中的 `cc1` / `cc1plus` 负责 C/C++ 的编译阶段，Clang 则有自己的前端和 LLVM 后端。

**常见选项**：

* `-S`：停止在生成汇编阶段
* `-fPIC`：生成位置无关代码（用于共享库）
* `-fno-common`：控制未初始化全局变量的链接行为（避免多个定义）
* `-g`：生成调试信息（DWARF）
* `-O` 系列：影响优化与代码生成（会改变符号、行号对应关系等）

**警告与诊断**：编译阶段会报告语法或类型错误，也会产生警告（使用 `-Wall -Wextra` 可打开更多警告）。

---

## 5. 汇编（Assembly）——汇编到目标文件（.o）

**功能**：汇编器（assembler，如 GNU as）把汇编文本（`.s`）转换为目标文件（`.o`）。目标文件的内容包括：

* **节（sections）**：例如 `.text`（代码）、`.data`（已初始化数据）、`.bss`（未初始化数据）、`.rodata`（只读数据）等。
* **符号表（symbol table）**：记录定义与引用的符号（函数和全局变量）及其属性（本地/全局/弱/强）。
* **重定位记录（relocation entries）**：当某个节中的地址依赖于其他节或其他目标文件中的符号时，汇编器会在目标文件中留下重定位信息，链接器会根据最终地址修正这些位置。

**查看目标文件**：

* `readelf -h -S -s file.o`
* `nm file.o`（符号）
* `objdump -d file.o`（反汇编）

**示例**：函数调用 `foo()` 时，调用指令通常不会直接写入最终地址，而会写入一个相对位置或占位，然后在链接阶段或运行时由重定位条目来修正。

---

## 6. 链接（Linking）——把目标文件与库组合

**功能**：链接器（ld / gold / lld）将多个目标文件和库合并为一个可执行文件或共享对象。主要工作包括：

* 合并节（sections）并为它们安排最终的虚拟地址（load address）
* 解析符号（将引用的符号找到对应的定义）
* 执行重定位（修正目标文件中的绝对/相对地址以反映最终布局）
* 如果生成共享库，设置 SONAME，生成动态段（Dynamic Section）等

**两种链接方式**：

* **静态链接（Static linking）**：把所需库的代码复制进可执行文件（通常来自 `.a` 静态库）。优点：部署简单（单文件），缺点：可执行文件大，不共享内存中的库代码，库更新不能自动生效。
* **动态链接（Dynamic linking）**：可执行文件只保存对共享库（`.so`）的引用（DT\_NEEDED）。运行时由动态链接器加载共享库并执行重定位。优点：共享、节省内存、可升级库。缺点：运行时需要正确的库和 ABI。

**符号解析策略**：

* 默认情况下，链接器按输入文件/库的顺序搜索和解析符号。静态库（`.a`）中的成员仅在某个未解析的符号被找到时才会从库中提取。
* 链接器在处理静态库时通常是单向查找（从左到右），因此库顺序重要；可用 `--start-group ... --end-group` 来解决循环依赖。
* **弱符号（weak）**：如果存在强符号则覆盖弱符号；如果全部为弱符号，链接器可能选择其中之一或将其视作未定义（平台不同）。

**常见链接器输出/控制选项**：

* `-o out`：设定输出文件
* `-L`：库搜索目录
* `-lfoo`：链接 `libfoo.a` 或 `libfoo.so`
* `-Wl,<opt>`：把 `<opt>` 传给链接器（如 `-Wl,-Map=output.map`）
* `-static`：静态链接
* `-shared`：生成共享库
* `-fPIC`：配合 `-shared` 使用，生成位置无关代码
* `--as-needed`/`--no-as-needed`：控制是否把某些链接的库记录为 DT\_NEEDED

**库的选择与 SONAME**：共享库通常带有 SONAME（`DT_SONAME`）。当链接时（编译阶段），链接器把 SONAME 记录到可执行文件的动态段；运行时动态加载器会根据此 SONAME 查找库（结合 rpath、ld.so.cache、LD\_LIBRARY\_PATH 等）。

**链接器脚本**：高级用户可以使用链接脚本来精确控制输出节的布局、符号导出/隐藏、分配地址等。

---

## 7. 运行时装载（动态链接器 / loader）

如果可执行文件是动态链接的，加载步骤如下（简化说明）：

1. **内核加载 ELF 可执行文件的程序头（program headers）**，因为 ELF 程序头包含 *loadable segments*，内核根据这些段把程序映射到进程地址空间（使用 `mmap`）并设置初始堆栈和寄存器状态。
2. 如果 ELF 的 `PT_INTERP` 段指明了动态链接器（例如 `/lib64/ld-linux-x86-64.so.2`），内核会将控制权交给该动态链接器（而不是直接执行程序的 `_start`）。
3. **动态链接器** 解析可执行文件的动态段（`DT_NEEDED` 条目），按依赖关系加载共享库（并可能递归加载这些库的依赖）。
4. 动态链接器读取各共享库的符号表和重定位表，执行必要的重定位（有的重定位可以在链接阶段完成，有的必须在运行时完成，尤其是与共享库地址相关的重定位）。
5. **GOT/PLT 机制**：调用外部函数通常通过 PLT（Procedure Linkage Table）跳转，而 PLT 使用 GOT（Global Offset Table）存放实际地址。动态链接器在第一次调用时可以延迟解析（lazy binding），也可以在程序启动时全部解析（`LD_BIND_NOW`）。
6. 在所有库初始化完成后，动态链接器会调用各模块的构造函数（`.init_array`），然后把控制权转给程序的 `_start` / libc 的启动代码，最终进入 `main`。

**常用运行时工具**：

* `ldd ./program`：列出动态依赖（注意：`ldd` 的实现可能执行目标加载器的部分逻辑，谨慎对待来自不受信任二进制的 `ldd`）。
* `LD_PRELOAD=/path/libfoo.so`：在运行时优先加载指定库，用于函数拦截/替换。
* `LD_LIBRARY_PATH`：临时指定共享库搜索路径（影响运行时查找）。
* `LD_DEBUG`：动态链接器的调试输出。

---

## 8. 静态库（.a）与共享库（.so）比较与制作方法

**制作静态库**：

```bash
gcc -c foo.c -o foo.o
ar rcs libfoo.a foo.o
# ranlib libfoo.a  # 有些系统需要
```

**制作共享库**：

```bash
gcc -fPIC -c foo.c -o foo.o
gcc -shared -o libfoo.so foo.o
```

**链接示例**：

```bash
gcc main.c -L. -lfoo -o main   # 链接 libfoo.so 或 libfoo.a（优先共享库）
# 或者显式静态链接
gcc main.c libfoo.a -o main
# 或者禁用共享库，强制静态链接 libc 等：
gcc -static main.c -o main-static
```

**比较**：

* 静态库：部署简单（无需外部 .so），但可执行文件大、不能共享内存代码、更新时间困难。
* 共享库：可由多个进程共享内存、升级库能影响多个程序、减小可执行文件体积，但运行环境依赖库必须匹配 ABI，且加载与重定位有运行时开销。

---

## 9. 启动文件、CRT 与 \_start

编译器/链接器通常会把一组启动文件（CRT, C runtime）与用户对象文件链接在一起。常见的启动文件包括：

* `crt1.o` / `crti.o` / `crtn.o`：包含程序入口 `_start`，负责设置环境并调用 `__libc_start_main` 或类似函数。
* `crtbegin.o` / `crtend.o`（GCC/GLIBC）：用于构造 `.init_array` / `.fini_array` 的界限等。

`_start`（在 crt1.o 中）是程序真正的入口点；它会做一些平台/ABI 的初始化工作，然后调用 libc 的启动例程，最终进入 `main(argc, argv, envp)`。

如果使用 `-nostartfiles` 或 `-nostdlib`，链接器不会自动链接这些启动文件，程序必须自己提供入口点或手动链接。

---

## 10. 高级话题（选读）

### 10.1 PIE（Position Independent Executable）与 PIE/FPI C

* `-fPIE`（编译）与 `-pie`（链接）用于生成位置无关的可执行文件，以支持 ASLR（地址空间布局随机化）。许多现代发行版默认启用 PIE。

### 10.2 GOT / PLT（动态链接机制的核心）

* GOT（Global Offset Table）用于存放共享对象中需要在运行时修正的地址。
* PLT（Procedure Linkage Table）是一种间接跳转机制，允许函数调用先跳到 PLT 入口，PLT 再通过 GOT 调用真实函数地址；动态链接器可在第一次调用时解析地址（lazy binding）。

### 10.3 符号可见性与预占（interposition）

* 默认情况下，动态库中的全局符号可被外部覆盖（preemption）。可以通过 `-fvisibility=hidden` 或链接时使用 `-Bsymbolic`、版本脚本（version script）来控制导出符号。

### 10.4 LTO（Link Time Optimization）

* LTO 是在链接阶段跨模块进行优化的技术。使用 `-flto` 会在编译阶段生成可供 LTO 使用的中间表示，链接器（或特定插件）会在最终链接时进行跨文件优化。

### 10.5 符号版本与 SONAME

* 共享库可以使用符号版本（GNU version script）来维护 ABI 向后兼容性。
* SONAME 决定了可执行文件在运行时会查找哪个版本的库（`DT_SONAME`）。打包时通常把文件名做成 `libfoo.so.1.2.3`，并给 `libfoo.so.1` 或 `libfoo.so` 做符号链接，SONAME 常为 `libfoo.so.1`。

### 10.6 Weak / Strong 符号

* `__attribute__((weak))` 可定义弱符号，若存在同名强符号则以强符号为准。常用于库里提供默认实现，允许用户覆盖它们。

---

## 11. 常见错误、排错技巧与工具清单

**常见链接错误与原因**：

* `undefined reference to 'foo'`：链接时找不到 `foo` 的定义。检查：是否 `-l` 缺失？库顺序是否正确？是否在编译时使用了 `-c` 忘记链接？是否使用了 C++ 的 name-mangling 而另一个对象是以 C 编译？
* `multiple definition of 'bar'`：同一符号在多个目标文件或库中被定义（例如把函数定义写在头文件且没有 `static inline`），或者将函数的实现写在了头文件中而被多次定义。
* 运行时找不到某共享库（`libfoo.so.1: cannot open shared object file: No such file or directory`）：检查 `LD_LIBRARY_PATH`、`/etc/ld.so.conf`、`ldconfig` 缓存或 `DT_RUNPATH`。

**调试与诊断工具**：

* `gcc -v`：查看 GCC 的内部调用流程
* `gcc -save-temps`：保留中间文件（`.i`, `.s`, `.o`）
* `readelf -h -S -s -l`：查看 ELF 标头、节、符号、段
* `nm -C --defined-only file.o`：查看符号（`-C` 解码 C++ 名称）
* `objdump -d -r file.o`：反汇编并查看重定位
* `ldd program`：查看动态依赖
* `LD_DEBUG=all ./program`：动态链接器的详细调试输出
* `strace` / `ltrace`：系统调用跟踪或库调用跟踪（间接帮助定位库加载问题）

**常用排查方法**：

* 如果出现 `undefined reference`，先用 `nm` / `readelf -s` 检查目标文件或库中是否有符号定义。
* 当动态库版本不匹配时，使用 `ldd` 与 `readelf -d` 检查 `DT_SONAME` 与 `DT_NEEDED`。
* 当符号看似存在但链接失败，检查符号是否为本地（local）或静态（static）限定的（用 `nm -a` 查看符号类别）。

---

## 12. 完整示例：多文件项目的构建流程

**文件结构**：

```
project/
  ├─ include/
  │   └─ util.h
  ├─ src/
  │   ├─ main.c
  │   └─ util.c
  └─ build.sh
```

`include/util.h`：

```c
#ifndef UTIL_H
#define UTIL_H

void greet(const char *name);

#endif
```

`src/util.c`：

```c
#include <stdio.h>
#include "../include/util.h"

void greet(const char *name) {
    printf("Hello, %s\n", name);
}
```

`src/main.c`：

```c
#include "../include/util.h"

int main(void) {
    greet("Alice");
    return 0;
}
```

**构建脚本（简化）**：

```bash
#!/bin/sh
set -e

gcc -Iinclude -c src/util.c -o build/util.o
gcc -Iinclude -c src/main.c -o build/main.o

# 静态链接示例
ar rcs build/libutil.a build/util.o
gcc build/main.o build/libutil.a -o build/app_static

# 共享库示例
gcc -fPIC -c src/util.c -o build/util_pic.o
gcc -shared -o build/libutil.so build/util_pic.o
gcc build/main.o -Lbuild -lutil -Wl,-rpath,'$ORIGIN' -o build/app_shared

# 说明：-Wl,-rpath,'$ORIGIN' 会在运行时从可执行文件目录查找 libutil.so
```

**解释**：

* 先分别生成目标文件（`.o`）；
* 用 `ar` 把 `util.o` 放入静态库 `libutil.a`，再把 `main.o` 与 `libutil.a` 链接得到静态可执行；
* 或者编译 `util.o` 为 PIC 版本，生成 `libutil.so`，再与 `main.o` 动态链接并用 `rpath` 指定运行时查找路径。

---

## 13. 推荐阅读与参考

* ELF/Program Loading：ELF 格式与程序装载器的官方或社区文档
* GNU ld, gold, lld 链接器手册
* GCC 文档（编译器选项、内部实现等）
* 《Linkers and Loaders》（书）——深入讨论链接器和加载器的工作原理

---

## 附：常用命令

```text
gcc -E file.c      # 预处理
gcc -S file.c      # 生成汇编
gcc -c file.c      # 生成目标文件 .o
gcc file.o -o prog # 链接生成可执行
gcc -shared -fPIC -o libfoo.so foo.o  # 生成共享库
ar rcs libfoo.a foo.o  # 生成静态库
nm file.o            # 列出目标文件符号
readelf -h -S -s file # 查看 ELF 头、节、符号
objdump -d file.o     # 反汇编
ldd prog              # 列出动态依赖
```
