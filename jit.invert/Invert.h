class Invert {
    
    private:
            
        long _mode = 0;
    
    public :
    
        Invert() {}
        ~Invert() {}
    
        void set(std::string key, void *value) {
            if(key=="mode") this->_mode = *((long *)value);
        }
    
        void calc(unsigned int *bop, unsigned int *bip, long width, long height, long rowBytes) {
            
            if(this->_mode) {
                
                for(long i=0;i<height;i++) {

                    unsigned int *src = bip+i*rowBytes;
                    unsigned int *dst = bop+i*rowBytes;
            
#ifdef BGRA
                    for(long j=0; j<width; j++) {
                        *dst++ = (*src&0xFF)|((~(*src))&0xFFFFFF00);
                        src++;
                    }
#else // ABGR
                    
                    for(long j=0; j<width; j++) {
                        *dst++ = (*src&0xFF000000)|((~(*src))&0xFFFFFF);
                        src++;
                    }
#endif
                    
                }
            }
            else {
                
                memcpy((void *)bop,(void *)bip,width*rowBytes*sizeof(unsigned int));
            }
        }
};
