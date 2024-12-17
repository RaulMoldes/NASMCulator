## INSTRUCCIONES DE COMPILACIÓN

1. Compilar
```bash
nasm  -f elf64 -o calculator.o calculator.asm
```
```bash
ld -o calculator calculator.o
```
2. Ejecutar

```bash
./calculator
```

3. Depuración con gdb.
```bash
gdb ./calculator
```

