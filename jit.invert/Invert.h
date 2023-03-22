class Invert {
    
    private:
            
        bool _mode = true;
    
    public :
    
        Invert() {}
        ~Invert() {}
    
        void mode(bool mode) {
            this->_mode = mode;
        }
    
        void calc(long *dim, t_jit_matrix_info *in_minfo, unsigned char *bip, t_jit_matrix_info *out_minfo, unsigned char *bop) {
            
            long width  = dim[0];
            long height = dim[1];
            
            if(this->_mode) {
                
                for(long i=0;i<height;i++) {

                    unsigned char *src = bip+i*in_minfo->dimstride[1];
                    unsigned char *dst = bop+i*out_minfo->dimstride[1];
            
                    for(long j=0; j<width; j++) {
                        *dst++ = *src++;
                        *dst++ = ~*src++;
                        *dst++ = ~*src++;
                        *dst++ = ~*src++;
                    }
                }
            }
            else {
                
                for(long i=0;i<height;i++) {

                    unsigned char *src = bip+i*in_minfo->dimstride[1];
                    unsigned char *dst = bop+i*out_minfo->dimstride[1];
            
                    for(long j=0; j<width; j++) {
                        *dst++ = *src++;
                        *dst++ = *src++;
                        *dst++ = *src++;
                        *dst++ = *src++;
                    }
                }
            }
        }
};
