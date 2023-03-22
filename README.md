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