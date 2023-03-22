#### Setup

```
git clone https://github.com/Cycling74/max-sdk-base.git
```
Select Bundle to create a project in Xcode.    
Change the extension to mxo.

#### Color

```
#ifdef IS_JIT_LIBRARY_AVAILABLE
    #define BGRA
#endif
```

#### t_matrix_info

```
#define t_matrix_info t_jit_matrix_info
```

If only Invert.h is used, define t_matrix_info.
```
typedef struct _matrix_info {
    long dim[2];
    long dimstride[2];
} t_matrix_info;
```