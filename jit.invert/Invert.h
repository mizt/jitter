class Invert {
    
    private:
            
        bool _mode = true;
    
    public :
    
        Invert() {}
        ~Invert() {}
    
        void mode(bool mode) {
            this->_mode = mode;
        }
    
        void calc(long *dim, t_jit_matrix_info *src_minfo, unsigned char *bip, t_jit_matrix_info *dst_minfo, unsigned char *bop) {
            
            long width  = dim[0];
            long height = dim[1];
            
            if(this->_mode) {
                
                for(long i=0;i<height;i++) {

                    unsigned char *src = bip+i*src_minfo->dimstride[1];
                    unsigned char *dst = bop+i*dst_minfo->dimstride[1];
            
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

                    unsigned char *src = bip+i*src_minfo->dimstride[1];
                    unsigned char *dst = bop+i*dst_minfo->dimstride[1];
            
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
