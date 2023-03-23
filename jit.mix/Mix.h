class Mix {
    
    private:
            
        int _wet = 0;
    
    public :
    
        Mix() {}
        ~Mix() {}
    
        void set(std::string key, void *value) {
            if(key=="wet") {
                this->_wet = 0x100*(*((float *)value));
                if(this->_wet<=0) this->_wet = 0;
                else if(this->_wet>=0x100) this->_wet = 0x100;
            }
        }
    
        void calc(unsigned int *bop, unsigned int *bip1, unsigned int *bip2, long width, long height, long rowBytes) {
            
            int wet = this->_wet;
            int dry = 0x100-wet;
            
            if(this->_wet&&bip2) {
                
                for(long i=0;i<height;i++) {

                    unsigned int *src[2] = {
                        bip1+i*rowBytes,
                        bip2+i*rowBytes
                    };
                    unsigned int *dst = bop+i*rowBytes;
                    
                    for(long j=0; j<width; j++) {
                        
                        unsigned int pixel[2] = {
                            *src[0]++,
                            *src[1]++
                        };
            
#ifdef BGRA
                        unsigned char b[2] = {(unsigned char)((pixel[0]>>24)&0xFF),(unsigned char)((pixel[1]>>24)&0xFF)};
                        unsigned char g[2] = {(unsigned char)((pixel[0]>>16)&0xFF),(unsigned char)((pixel[1]>>16)&0xFF)};
                        unsigned char r[2] = {(unsigned char)((pixel[0]>>8)&0xFF),(unsigned char)((pixel[1]>>8)&0xFF)};
                        unsigned char a[2] = {(unsigned char)((pixel[0])&0xFF),(unsigned char)((pixel[1])&0xFF)};
                                                

#else // ABGR
                    
                        unsigned char a[2] = {(unsigned char)((pixel[0]>>24)&0xFF),(unsigned char)((pixel[1]>>24)&0xFF)};
                        unsigned char b[2] = {(unsigned char)((pixel[0]>>16)&0xFF),(unsigned char)((pixel[1]>>16)&0xFF)};
                        unsigned char g[2] = {(unsigned char)((pixel[0]>>8)&0xFF),(unsigned char)((pixel[1]>>8)&0xFF)};
                        unsigned char r[2] = {(unsigned char)((pixel[0])&0xFF),(unsigned char)((pixel[1])&0xFF)};
                                 
#endif
                        
                        *dst++ = ((b[0]*dry+b[1]*wet)>>8)<<24|((g[0]*dry+g[1]*wet)>>8)<<16|((r[0]*dry+r[1]*wet)>>8)<<8|(a[0]*dry+a[1]*wet)>>8;

                    }
                    
                }
            }
            else {
                
                memcpy((void *)bop,(void *)bip1,rowBytes*height*sizeof(unsigned int));
            }
        }
};
