#import <Cocoa/Cocoa.h>

#include "jit.common.h"
#include "max.jit.mop.h"

#include <string>

#ifdef IS_JIT_LIBRARY_AVAILABLE
    #define BGRA
#endif

#include "Mix.h"

#define NAME "jit_mix"

typedef struct _jit_mix {
    t_object ob;
    Mix *mix;
    float wet;
} t_jit_mix;

typedef struct _max_jit_mix {
    t_object ob;
    void *obex;
} t_max_jit_mix;

static t_class *_jit_mix_class = nullptr;
static t_class *max_jit_mix_class = nullptr;

NSMutableString *jit_mix_mxo_name() {
    NSMutableArray *arr = [[[NSString stringWithFormat:@"%s",NAME] componentsSeparatedByString:@"_"] mutableCopy];
    NSMutableString *str = [NSMutableString stringWithString:arr[0]];
    for(int n=1; n<arr.count; n++) {
        [str appendString:@"."];
        [str appendString:arr[n]];
    }
    return str;
}

t_jit_mix *jit_mix_new(void) {
    
    t_jit_mix *x = (t_jit_mix *)jit_object_alloc(_jit_mix_class);
    if(x) {
        x->mix = new Mix();
        x->wet = 0;
    }
    return x;
}

void jit_mix_free(t_jit_mix *x) {
    if(x&&x->mix) {
        delete x->mix;
        x->mix = nullptr;
    }
}

t_jit_err jit_mix_matrix_calc(t_jit_mix *x, void *inputs, void *outputs) {
    
    t_jit_err err=JIT_ERR_NONE;
    
    int IN1 = 0;
    int IN2 = 1;
    int OUT = 2;
    
    long savelock[3] = {0,0,0};

    void *matrix[3] = {
        jit_object_method(inputs,_jit_sym_getindex,0),
        jit_object_method(inputs,_jit_sym_getindex,1),
        jit_object_method(outputs,_jit_sym_getindex,0)
    };
    
    if(x&&matrix[IN1]&&matrix[IN2]&&matrix[OUT]) {
                
        savelock[IN1] = (long)jit_object_method(matrix[IN1],_jit_sym_lock,1);
        savelock[IN2] = (long)jit_object_method(matrix[IN2],_jit_sym_lock,1);
        savelock[OUT] = (long)jit_object_method(matrix[OUT],_jit_sym_lock,1);

        t_jit_matrix_info minfo[3];
        unsigned char *bp[3];
        
        for(int n=0; n<3; n++) {
            
            jit_object_method(matrix[n],_jit_sym_getinfo,&minfo[n]);
            jit_object_method(matrix[n],_jit_sym_getdata,&bp[n]);

            if(!bp[n]) {
                err=(n==OUT)?JIT_ERR_INVALID_OUTPUT:JIT_ERR_INVALID_INPUT;
                goto out;
            }
            
            if(minfo[n].type!=_jit_sym_char) {
                err=JIT_ERR_MISMATCH_TYPE;
                goto out;
            }
            
            if(minfo[n].planecount!=4) {
                err=JIT_ERR_MISMATCH_PLANE;
                goto out;
            }
            
            if(minfo[n].dimcount!=2) {
                err=JIT_ERR_MISMATCH_DIM;
                goto out;
            }
        }
        
        if((minfo[IN1].dim[0]!=minfo[OUT].dim[0])||(minfo[IN1].dim[0]!=minfo[IN2].dim[0])) {
            err=JIT_ERR_MISMATCH_DIM;
            goto out;
        }
        
        if((minfo[IN1].dim[1]!=minfo[OUT].dim[1])||(minfo[IN1].dim[1]!=minfo[IN2].dim[1])) {
            err=JIT_ERR_MISMATCH_DIM;
            goto out;
        }
        
        if((minfo[IN1].dimstride[1]!=minfo[OUT].dimstride[1])||(minfo[IN1].dimstride[1]!=minfo[IN2].dimstride[1])) {
            err=JIT_ERR_MISMATCH_DIM;
            goto out;
        }
        
        x->mix->calc((unsigned int *)bp[OUT],(unsigned int *)bp[IN1],(unsigned int *)bp[IN2],minfo[IN1].dim[0],minfo[IN1].dim[1],minfo[IN1].dimstride[1]>>2);
    }
    else {
        return JIT_ERR_INVALID_PTR;
    }

out:
    
    jit_object_method(matrix[2],_jit_sym_lock,savelock[2]);
    jit_object_method(matrix[1],_jit_sym_lock,savelock[1]);
    jit_object_method(matrix[0],_jit_sym_lock,savelock[0]);
    return err;
}

void jit_mix_wet(t_jit_mix *x, t_symbol *s, long argc, t_atom *argv) {
    if(x->mix) {
        float value = jit_atom_getfloat(argv);
        x->mix->set("wet",(void *)(&value));
    }
}

t_jit_err jit_mix_init() {
    
    _jit_mix_class = (t_class *)jit_class_new(NAME,(method)jit_mix_new,(method)jit_mix_free, sizeof(t_jit_mix),0);

    t_jit_object *mop = (t_jit_object *)jit_object_new(_jit_sym_jit_mop,2,1);
    jit_mop_single_type(mop,_jit_sym_char);
    jit_mop_single_planecount(mop,4);
    jit_mop_input_nolink(mop,1);
    jit_class_addadornment(_jit_mix_class,mop);
    jit_class_addmethod(_jit_mix_class,(method)jit_mix_matrix_calc,"matrix_calc",A_CANT,0);
    
    long attrflags = JIT_ATTR_GET_OPAQUE_USER|JIT_ATTR_SET_USURP_LOW;
    t_jit_object *attr = (t_jit_object *)jit_object_new(_jit_sym_jit_attr_offset,"wet",_jit_sym_float32,attrflags,
                              (method)0L,(method)jit_mix_wet,calcoffset(t_jit_mix,wet));
    jit_class_addattr(_jit_mix_class,attr);
    object_addattr_parse(attr,"label",_jit_sym_symbol,0,"Wet");
    
    jit_class_register(_jit_mix_class);

    return JIT_ERR_NONE;
}

void *max_jit_mix_new(t_symbol *s, long argc, t_atom *argv) {
    
    t_max_jit_mix *x = (t_max_jit_mix *)max_jit_object_alloc(max_jit_mix_class,gensym(NAME));

    if(x) {
        void *o = jit_object_new(gensym(NAME));
        if(o) {
            max_jit_mop_setup_simple(x,o,argc,argv);
            max_jit_attr_args(x,argc,argv);
        }
        else {
            
            NSMutableString *str = jit_mix_mxo_name();
            [str appendString:@": could not allocate object"];
            
            jit_object_error((t_object *)x,(char *)[str UTF8String]);
            freeobject((t_object *) x);
            x = NULL;
        }
    }
    return x;
}

void max_jit_mix_free(t_max_jit_mix *x) {
    
    max_jit_mop_free(x);
    jit_object_free(max_jit_obex_jitob_get(x));
    max_jit_object_free(x);
}

C74_EXPORT void ext_main(void *r) {
    
    jit_mix_init();
    t_class *max_class = class_new([jit_mix_mxo_name() UTF8String],(method)max_jit_mix_new,(method)max_jit_mix_free,sizeof(t_max_jit_mix),NULL,A_GIMME,0);
    max_jit_class_obex_setup(max_class,calcoffset(t_max_jit_mix,obex));
    t_class *jit_class = (t_class *)jit_class_findbyname(gensym(NAME));
    max_jit_class_mop_wrap(max_class,jit_class,0);
    max_jit_class_wrap_standard(max_class,jit_class,0);
    class_addmethod(max_class,(method)max_jit_mop_assist,"assist",A_CANT,0);
    class_register(CLASS_BOX,max_class);
    max_jit_mix_class = max_class;
}
