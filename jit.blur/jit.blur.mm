#import <Cocoa/Cocoa.h>

#include "jit.common.h"
#include "max.jit.mop.h"

#define t_matrix_info t_jit_matrix_info

#include <string>

#ifdef IS_JIT_LIBRARY_AVAILABLE
    #define BGRA
#endif

#include "Blur.h"

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

NSMutableString *jit_blur_mxo_name() {
    NSMutableArray *arr = [[[NSString stringWithFormat:@"%s",NAME] componentsSeparatedByString:@"_"] mutableCopy];
    NSMutableString *str = [NSMutableString stringWithString:arr[0]];
    for(int n=1; n<arr.count; n++) {
        [str appendString:@"."];
        [str appendString:arr[n]];
    }
    return str;
}

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
    long in_savelock,out_savelock;

    void *in_matrix = jit_object_method(inputs,_jit_sym_getindex,0);
    void *out_matrix = jit_object_method(outputs,_jit_sym_getindex,0);

    if(x&&in_matrix&&out_matrix) {
                
        in_savelock = (long)jit_object_method(in_matrix,_jit_sym_lock,1);
        out_savelock = (long)jit_object_method(out_matrix,_jit_sym_lock,1);

        t_jit_matrix_info in_minfo;
        unsigned char *in_bp;
        
        jit_object_method(in_matrix,_jit_sym_getinfo,&in_minfo);
        jit_object_method(in_matrix,_jit_sym_getdata,&in_bp);

        t_jit_matrix_info out_minfo;
        unsigned char *out_bp;
        
        jit_object_method(out_matrix,_jit_sym_getinfo,&out_minfo);
        jit_object_method(out_matrix,_jit_sym_getdata,&out_bp);

        if(!in_bp) {
            err=JIT_ERR_INVALID_INPUT;
            goto out;
        }
        if(!out_bp) {
            err=JIT_ERR_INVALID_OUTPUT;
            goto out;
        }

        if((in_minfo.type!=_jit_sym_char)||(in_minfo.type!=out_minfo.type)) {
            err=JIT_ERR_MISMATCH_TYPE;
            goto out;
        }

        if((in_minfo.planecount!=4)||(out_minfo.planecount!=4)) {
            err=JIT_ERR_MISMATCH_PLANE;
            goto out;
        }
        
        if((in_minfo.dimcount!=2)||(out_minfo.dimcount!=2)) {
            err=JIT_ERR_MISMATCH_DIM;
            goto out;
        }
        
        x->blur->calc((unsigned int *)out_bp,(unsigned int *)in_bp,in_minfo.dim[0],in_minfo.dim[1],in_minfo.dimstride[1]>>2);
    }
    else {
        return JIT_ERR_INVALID_PTR;
    }

out:
    
    jit_object_method(out_matrix,_jit_sym_lock,out_savelock);
    jit_object_method(in_matrix,_jit_sym_lock,in_savelock);
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
            
            NSMutableString *str = jit_blur_mxo_name();
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
    t_class *max_class = class_new([jit_blur_mxo_name() UTF8String],(method)max_jit_blur_new,(method)max_jit_blur_free,sizeof(t_max_jit_blur),NULL,A_GIMME,0);
    max_jit_class_obex_setup(max_class,calcoffset(t_max_jit_blur,obex));
    t_class *jit_class = (t_class *)jit_class_findbyname(gensym(NAME));
    max_jit_class_mop_wrap(max_class,jit_class,0);
    max_jit_class_wrap_standard(max_class,jit_class,0);
    class_addmethod(max_class,(method)max_jit_mop_assist,"assist",A_CANT,0);
    class_register(CLASS_BOX,max_class);
    max_jit_blur_class = max_class;
}
