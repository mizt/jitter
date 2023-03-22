#include "jit.common.h"
#include "max.jit.mop.h"

typedef struct _max_jit_invert {
	t_object ob;
	void *obex;
} t_max_jit_invert;

t_jit_err jit_invert_init(void);

void *max_jit_invert_new(t_symbol *s, long argc, t_atom *argv);
void max_jit_invert_free(t_max_jit_invert *x);
t_messlist *max_jit_invert_class;

C74_EXPORT void ext_main(void *r) {
    
	jit_invert_init();
	setup(&max_jit_invert_class,(method)max_jit_invert_new,(method)max_jit_invert_free,(short)sizeof(t_max_jit_invert),
		  0L,A_GIMME,0);

    void *p = max_jit_classex_setup(calcoffset(t_max_jit_invert,obex));
    void *q = jit_class_findbyname(gensym("jit_invert"));
	max_jit_classex_mop_wrap(p,q,0);
	max_jit_classex_standard_wrap(p,q,0);
	addmess((method)max_jit_mop_assist,"assist",A_CANT,0);
}

void max_jit_invert_free(t_max_jit_invert *x) {
    
	max_jit_mop_free(x);
	jit_object_free(max_jit_obex_jitob_get(x));
	max_jit_obex_free(x);
}

void *max_jit_invert_new(t_symbol *s, long argc, t_atom *argv) {
    
    t_max_jit_invert *x = (t_max_jit_invert *)max_jit_obex_new(max_jit_invert_class,gensym("jit_invert"));
	if(x) {
        void *o = jit_object_new(gensym("jit_invert"));
		if(o) {
			max_jit_mop_setup_simple(x,o,argc,argv);
			max_jit_attr_args(x,argc,argv);
		}
        else {
			jit_object_error((t_object *)x,"jit.invert: could not allocate object");
			freeobject((t_object *) x);
			x = NULL;
		}
	}
	return x;
}
