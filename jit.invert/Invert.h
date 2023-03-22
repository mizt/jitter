class Invert {
    
    private:
            
        bool _mode = true;
    
    public :
    
        Invert() {}
        ~Invert() {}
    
        void mode(bool mode) {
            this->_mode = mode;
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
