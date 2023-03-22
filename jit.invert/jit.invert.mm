#include "jit.common.h"

typedef struct _jit_invert {
	t_object ob;
	long mode;
} t_jit_invert;

void *_jit_invert_class;

t_jit_err jit_invert_init(void);
t_jit_invert *jit_invert_new(void);
void jit_invert_free(t_jit_invert *x);
t_jit_err jit_invert_matrix_calc(t_jit_invert *x, void *inputs, void *outputs);
void jit_invert_calculate_ndim(t_jit_invert *x, long dimcount, long *dim, long planecount,t_jit_matrix_info *in_minfo, char *bip, t_jit_matrix_info *out_minfo, char *bop);

t_jit_err jit_invert_init(void) {
    
	_jit_invert_class = jit_class_new("jit_invert",(method)jit_invert_new,(method)jit_invert_free,sizeof(t_jit_invert),0L);

    t_jit_object *mop = (t_jit_object *)jit_object_new(_jit_sym_jit_mop,1,1);
	jit_mop_single_type(mop,_jit_sym_char);
	jit_mop_single_planecount(mop,4);
	jit_class_addadornment(_jit_invert_class,mop);
	jit_class_addmethod(_jit_invert_class,(method)jit_invert_matrix_calc,"matrix_calc",A_CANT,0L);
    
    long attrflags = JIT_ATTR_GET_DEFER_LOW | JIT_ATTR_SET_USURP_LOW;
    t_jit_object *attr = (t_jit_object *)jit_object_new(_jit_sym_jit_attr_offset,"mode",_jit_sym_long,attrflags,(method)0L,(method)0L,calcoffset(t_jit_invert,mode));
	jit_attr_addfilterset_clip(attr,0,1,TRUE,TRUE);
	jit_class_addattr(_jit_invert_class,attr);
	object_addattr_parse(attr,"label",_jit_sym_symbol,0,"Mode");
    
	jit_class_register(_jit_invert_class);

	return JIT_ERR_NONE;
}

t_jit_err jit_invert_matrix_calc(t_jit_invert *x, void *inputs, void *outputs) {
    
	t_jit_err err=JIT_ERR_NONE;
	long in_savelock,out_savelock;
	t_jit_matrix_info in_minfo,out_minfo;
	char *in_bp,*out_bp;
	long i,dimcount,planecount,dim[JIT_MATRIX_MAX_DIMCOUNT];
	void *in_matrix,*out_matrix;

	in_matrix 	= jit_object_method(inputs,_jit_sym_getindex,0);
	out_matrix 	= jit_object_method(outputs,_jit_sym_getindex,0);

	if (x&&in_matrix&&out_matrix) {
        
		in_savelock = (long) jit_object_method(in_matrix,_jit_sym_lock,1);
		out_savelock = (long) jit_object_method(out_matrix,_jit_sym_lock,1);

		jit_object_method(in_matrix,_jit_sym_getinfo,&in_minfo);
		jit_object_method(out_matrix,_jit_sym_getinfo,&out_minfo);

		jit_object_method(in_matrix,_jit_sym_getdata,&in_bp);
		jit_object_method(out_matrix,_jit_sym_getdata,&out_bp);

		if (!in_bp) { err=JIT_ERR_INVALID_INPUT; goto out;}
		if (!out_bp) { err=JIT_ERR_INVALID_OUTPUT; goto out;}

		if((in_minfo.type!=_jit_sym_char)||(in_minfo.type!=out_minfo.type)) {
			err=JIT_ERR_MISMATCH_TYPE;
			goto out;
		}

		if((in_minfo.planecount!=4)||(out_minfo.planecount!=4)) {
			err=JIT_ERR_MISMATCH_PLANE;
			goto out;
		}

		dimcount = out_minfo.dimcount;
		planecount = out_minfo.planecount;
        for (i=0; i<dimcount; i++) {
			dim[i] = MIN(in_minfo.dim[i],out_minfo.dim[i]);
		}

		jit_parallel_ndim_simplecalc2((method)jit_invert_calculate_ndim,x,dimcount,dim,planecount,&in_minfo,in_bp,&out_minfo,out_bp,0,0);

	} else {
		return JIT_ERR_INVALID_PTR;
	}

out:
    
	jit_object_method(out_matrix,_jit_sym_lock,out_savelock);
	jit_object_method(in_matrix,_jit_sym_lock,in_savelock);
	return err;
}

void jit_invert_calculate_ndim(t_jit_invert *x, long dimcount, long *dim, long planecount, t_jit_matrix_info *in_minfo, char *bip, t_jit_matrix_info *out_minfo, char *bop) {
    
	if(dimcount<1) return;
    
    if(dimcount==1) {
        dim[1]=1;
    }
    else if(dimcount==2) {
        
        long width  = dim[0];
        long height = dim[1];

        for(long i=0; i<height; i++) {
            
            unsigned char *ip = (unsigned char *)(bip+i*in_minfo->dimstride[1]);
            unsigned char *op = (unsigned char *)(bop+i*out_minfo->dimstride[1]);

            if(x->mode) {
                for(long j=0; j<width; j++) {
                    *op++ = *ip++;
                    *op++ = ~(*ip++);
                    *op++ = ~(*ip++);
                    *op++ = ~(*ip++);
                }
            }
            else {
                for(long j=0; j<width; j++) {
                    *op++ = *ip++;
                    *op++ = *ip++;
                    *op++ = *ip++;
                    *op++ = *ip++;
                }
            }
        }
    }
    else {
        for(long i=0; i<dim[dimcount-1]; i++) {
            unsigned char *ip = (unsigned char *)(bip+i*in_minfo->dimstride[dimcount-1]);
            unsigned char *op = (unsigned char *)(bop+i*out_minfo->dimstride[dimcount-1]);
            jit_invert_calculate_ndim(x,dimcount-1,dim,planecount,in_minfo,(char *)ip,out_minfo,(char *)op);
        }
    }
}

t_jit_invert *jit_invert_new(void) {
    
    t_jit_invert *x = (t_jit_invert *)jit_object_alloc(_jit_invert_class);
	if(x) {
		x->mode = 1;
	}
	return x;
}

void jit_invert_free(t_jit_invert *x) {
	//nada
}
