# FAQ 5: %f 与 %lf 的使用规范

## scanf 函数

C 语言中，scanf 函数读取浮点数时应遵循严格的位宽关系，%f 为 4 字节，%lf 为 8 字节，因此应有如下格式：

```c
float a;
double b;

scanf("%f %lf", a, b);
```

## printf 函数

C 语言的 float 类型在运算时往往会被隐式提升为 double 类型变量，printf 函数中的 %f 也是如此，因此在打印浮点数类型（long double 除外）时，统一使用 %f：

```c
float a = 114.514;
double b = 1919.810;

printf("%f\12%f\12", a, b);
```
