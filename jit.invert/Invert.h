class Invert {
    
    private:
            
        long _mode = 0;
    
    public :
    
        Invert() {}
        ~Invert() {}
    
        void set(std::string key, void *value) {
            if(key=="mode") this->_mode = *((long *)value);
        }
    
        void calc(unsigned char *bop, unsigned char *bip, long width, long height, long rowBytes) {
            
            
            if(this->_mode) {
                
                for(long i=0;i<height;i++) {

                    unsigned char *src = bip+i*rowBytes;
                    unsigned char *dst = bop+i*rowBytes;
            
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

                    unsigned char *src = bip+i*rowBytes;
                    unsigned char *dst = bop+i*rowBytes;
            
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
