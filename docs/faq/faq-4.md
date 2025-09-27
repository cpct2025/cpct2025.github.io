# FAQ 4. 表达式求值

> 参考资料: [2025 年 LUG C 程序设计复习课](https://ftp.lug.ustc.edu.cn/%E6%B4%BB%E5%8A%A8/2025.01.01_C%E8%AF%AD%E8%A8%80/)

## 一些例子：

### 序列点之间，执行顺序不指定
```c
int readint()
{
  int result;
  scanf("%d", &result);
  return result;
}

int sub = readint() - readint(); // 两个 readint() 哪个先调用呢？不知道。这会导致计算结果不正确。

// 正确的做法
int a = readint();
int b = readint();
int sub = a - b; // 保证先读入的是被减数
```
