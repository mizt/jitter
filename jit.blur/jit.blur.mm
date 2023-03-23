#import <Cocoa/Cocoa.h>

#include "jit.common.h"
#include "max.jit.mop.h"

#define t_matrix_info t_jit_matrix_info

#include <string>

#ifdef IS_JIT_LIBRARY_AVAILABLE
    #define BGRA
#endif

#import "Utils.h"
#import "Blur.h"

#define NAME "jit_blur"

typedef struct _jit_blur {
    t_object ob;
    Blur *blur;
    long radius;
} t_jit_blur;

typedef struct _max_jit_blur {
    t_object ob;
    void *obex;
} t_max_jit_blur;

static t_class *_jit_blur_class = nullptr;
static t_class *max_jit_blur_class = nullptr;

t_jit_blur *jit_blur_new(void) {
    
    t_jit_blur *x = (t_jit_blur *)jit_object_alloc(_jit_blur_class);
    if(x) {
        x->blur = new Blur();
        x->radius = 1;
    }
    return x;
}

void jit_blur_free(t_jit_blur *x) {
    if(x&&x->blur) {
        delete x->blur;
        x->blur = nullptr;
    }
}

t_jit_err jit_blur_matrix_calc(t_jit_blur *x, void *inputs, void *outputs) {
    
    t_jit_err err=JIT_ERR_NONE;
 
    const unsigned int IN = 0;
    const unsigned int OUT = 1;
    const unsigned int NUM = 2;

    long savelock[NUM] = {0,0};

    void *matrix[NUM] = {
        jit_object_method(inputs,_jit_sym_getindex,0),
        jit_object_method(outputs,_jit_sym_getindex,0)
    };

    if(x&&matrix[IN]&&matrix[OUT]) {
                
        savelock[IN] = (long)jit_object_method(matrix[IN],_jit_sym_lock,1);
        savelock[OUT] = (long)jit_object_method(matrix[OUT],_jit_sym_lock,1);

        t_jit_matrix_info minfo[NUM];
        unsigned char *bp[NUM];
        
        for(int n=0; n<NUM; n++) {
                
            jit_object_method(matrix[n],_jit_sym_getinfo,&minfo[n]);
            jit_object_method(matrix[n],_jit_sym_getdata,&bp[n]);
            
            if(!bp[n]) {
                err=(n==OUT)?JIT_ERR_INVALID_OUTPUT:JIT_ERR_INVALID_INPUT;
                goto out;
            }
            
            if((minfo[n].type!=_jit_sym_char)) {
                err=JIT_ERR_MISMATCH_TYPE;
                goto out;
            }
            
            if((minfo[n].planecount!=4)) {
                err=JIT_ERR_MISMATCH_PLANE;
                goto out;
            }
            
            if((minfo[n].dimcount!=2)) {
                err=JIT_ERR_MISMATCH_DIM;
                goto out;
            }
        }
        
        if(!isEqualWidth(&minfo[IN],&minfo[OUT])) {
            err=JIT_ERR_MISMATCH_DIM;
            goto out;
        }
        
        if(!isEqualHeight(&minfo[IN],&minfo[OUT])) {
            err=JIT_ERR_MISMATCH_DIM;
            goto out;
        }
        
        if(!isEqualRowBytes(&minfo[IN],&minfo[OUT])) {
            err=JIT_ERR_MISMATCH_DIM;
            goto out;
        }
        
        x->blur->calc((unsigned int *)bp[OUT],(unsigned int *)bp[IN],minfo[IN].dim[0],minfo[IN].dim[1],minfo[IN].dimstride[1]>>2);
    }
    else {
        return JIT_ERR_INVALID_PTR;
    }

out:
    
    jit_object_method(matrix[OUT],_jit_sym_lock,savelock[OUT]);
    jit_object_method(matrix[IN],_jit_sym_lock,savelock[IN]);
    return err;
}

void jit_blur_radius(t_jit_blur *x, t_symbol *s, long argc, t_atom *argv) {
    if(x->blur) {
        long value = jit_atom_getlong(argv);
        x->blur->set("radius",(void *)(&value));
    }
}

t_jit_err jit_blur_init() {
    
    _jit_blur_class = (t_class *)jit_class_new(NAME,(method)jit_blur_new,(method)jit_blur_free, sizeof(t_jit_blur),0);

    t_jit_object *mop = (t_jit_object *)jit_object_new(_jit_sym_jit_mop,1,1);
    jit_mop_single_type(mop,_jit_sym_char);
    jit_mop_single_planecount(mop,4);
    jit_class_addadornment(_jit_blur_class,mop);
    jit_class_addmethod(_jit_blur_class,(method)jit_blur_matrix_calc,"matrix_calc",A_CANT,0);
        
    long attrflags = JIT_ATTR_GET_OPAQUE_USER|JIT_ATTR_SET_USURP_LOW;
    t_jit_object *attr = (t_jit_object *)jit_object_new(_jit_sym_jit_attr_offset,"radius",_jit_sym_long,attrflags,
                              (method)0L,(method)jit_blur_radius,calcoffset(t_jit_blur,radius));
    jit_class_addattr(_jit_blur_class,attr);
    object_addattr_parse(attr,"label",_jit_sym_symbol,0,"Radius");
    
    
    jit_class_register(_jit_blur_class);

    return JIT_ERR_NONE;
}

void *max_jit_blur_new(t_symbol *s, long argc, t_atom *argv) {
    
    t_max_jit_blur *x = (t_max_jit_blur *)max_jit_object_alloc(max_jit_blur_class,gensym(NAME));

    if(x) {
        void *o = jit_object_new(gensym(NAME));
        if(o) {
            max_jit_mop_setup_simple(x,o,argc,argv);
            max_jit_attr_args(x,argc,argv);
        }
        else {
            
            NSMutableString *str = mxo_name(NAME);
            [str appendString:@": could not allocate object"];
            
            jit_object_error((t_object *)x,(char *)[str UTF8String]);
            freeobject((t_object *) x);
            x = NULL;
        }
    }
    return x;
}

void max_jit_blur_free(t_max_jit_blur *x) {
    
    max_jit_mop_free(x);
    jit_object_free(max_jit_obex_jitob_get(x));
    max_jit_object_free(x);
}

C74_EXPORT void ext_main(void *r) {
    
    jit_blur_init();
    t_class *max_class = class_new([mxo_name(NAME) UTF8String],(method)max_jit_blur_new,(method)max_jit_blur_free,sizeof(t_max_jit_blur),NULL,A_GIMME,0);
    max_jit_class_obex_setup(max_class,calcoffset(t_max_jit_blur,obex));
    t_class *jit_class = (t_class *)jit_class_findbyname(gensym(NAME));
    max_jit_class_mop_wrap(max_class,jit_class,0);
    max_jit_class_wrap_standard(max_class,jit_class,0);
    class_addmethod(max_class,(method)max_jit_mop_assist,"assist",A_CANT,0);
    class_register(CLASS_BOX,max_class);
    max_jit_blur_class = max_class;
}
