#import <algorithm>

NSMutableString *mxo_name(const char *name) {
    NSMutableArray *arr = [[[NSString stringWithFormat:@"%s",name] componentsSeparatedByString:@"_"] mutableCopy];
    NSMutableString *str = [NSMutableString stringWithString:arr[0]];
    for(int n=1; n<arr.count; n++) {
        [str appendString:@"."];
        [str appendString:arr[n]];
    }
    return str;
}

bool isEqualWidth(t_jit_matrix_info *a, t_jit_matrix_info *b) {
    return a->dim[0]==b->dim[0];
}

bool isEqualWidth(t_jit_matrix_info *a, t_jit_matrix_info *b, t_jit_matrix_info *c) {
    return isEqualWidth(a,b)&&isEqualWidth(a,c);
}

bool isEqualHeight(t_jit_matrix_info *a, t_jit_matrix_info *b) {
    return a->dim[1]==b->dim[1];
}

bool isEqualHeight(t_jit_matrix_info *a, t_jit_matrix_info *b, t_jit_matrix_info *c) {
    return isEqualHeight(a,b)&&isEqualHeight(a,c);
}

bool isEqualRowBytes(t_jit_matrix_info *a, t_jit_matrix_info *b) {
    return a->dimstride[1]==b->dimstride[1];
}

bool isEqualRowBytes(t_jit_matrix_info *a, t_jit_matrix_info *b, t_jit_matrix_info *c) {
    return isEqualRowBytes(a,b)&&isEqualRowBytes(a,c);
}

long toU64(void *v) {
    return *((long *)v);
}

float toF32(void *v) {
    return *((float *)v);
}
