class Blur {
    
    private:
    
        const unsigned char thread = 4;
            
        bool _init = false;
        long _width = 0;
        long _height = 0;
    
        long _radius = 1;
    
        dispatch_group_t _group = dispatch_group_create();
        dispatch_queue_t _queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
            
        unsigned int *_xy = nullptr;
        unsigned int *_yx = nullptr;
    
        unsigned int **_rgb = new unsigned int *[thread];
        unsigned int **_buffer = new unsigned int *[thread];
    
        void reset() {
            
            if(this->_xy) delete[] this->_xy;
            this->_xy = new unsigned int[this->_width*this->_height];

            if(this->_yx) delete[] this->_yx;
            this->_yx = new unsigned int[this->_width*this->_height];

            for(int k=0; k<thread; k++) {
                if(this->_rgb[k]) delete[] this->_rgb[k];
                this->_rgb[k] = new unsigned int[(this->_width*this->_height)?this->_width*3:this->_height*3];
            }
                                        
            for(int k=0; k<thread; k++) {
                if(this->_buffer[k]) delete[] this->_buffer[k];
                this->_buffer[k] = new unsigned int[(int)(ceil((this->_width*this->_height)/(double)thread))];
            }
        }
    
        void blurX(unsigned int *dst, unsigned int *src, unsigned int *buffer, long w, long h, long begin, long end) {
            
            long radius = this->_radius;
            if(radius<=1) radius = 1;
            else if(radius>=(w>>2)) radius = w>>2;
            else if(radius>=(h>>2)) radius = h>>2;

            double weight = 1.0/(double)(radius*2+1);
            
            unsigned int sr = 0;
            unsigned int sg = 0;
            unsigned int sb = 0;
            
            unsigned int *buf = buffer;

            for(long i=begin; i<end; i++) {
                
                sr = sg = sb = 0;
                
                unsigned int *p = src+i*w;
                
                for(long k=-(radius+1); k<radius; k++) {
                    long j2 = 0+k;
                    if(j2<0) j2=0;
                    else if(j2>=w-1) j2=w-1;
                    unsigned int pixel = *(p+j2);
#ifdef BGRA
                    sb+=(pixel>>24)&0xFF;
                    sg+=(pixel>>16)&0xFF;
                    sr+=(pixel>>8)&0xFF;
#else
                    sb+=(pixel>>16)&0xFF;
                    sg+=(pixel>>8)&0xFF;
                    sr+=(pixel)&0xFF;
#endif
                    
                }
                        
                for(long j=0; j<w; j++) {
        // sub
                    long j2 = j-(radius+1);
                    if(j2<0) j2=0;
                    unsigned int pixel = *(p+j2);
#ifdef BGRA
                    sb-=(pixel>>24)&0xFF;
                    sg-=(pixel>>16)&0xFF;
                    sr-=(pixel>>8)&0xFF;
#else
                    sb-=(pixel>>16)&0xFF;
                    sg-=(pixel>>8)&0xFF;
                    sr-=(pixel)&0xFF;
#endif
                    
        // add
                    j2 = j+radius;
                    if(j2>=w-1) j2=w-1;
                    pixel = *(p+j2);
#ifdef BGRA
                    sb+=(pixel>>24)&0xFF;
                    sg+=(pixel>>16)&0xFF;
                    sr+=(pixel>>8)&0xFF;
#else
                    sb+=(pixel>>16)&0xFF;
                    sg+=(pixel>>8)&0xFF;
                    sr+=(pixel)&0xFF;
#endif

                    unsigned char r = sr*weight;
                    unsigned char g = sg*weight;
                    unsigned char b = sb*weight;

#ifdef BGRA
                    *buf++ = b<<24|g<<16|r<<8|0xFF;
#else
                    *buf++ = 0xFF000000|b<<16|g<<8|r;
#endif
                }
            }
            
            for(long i=begin; i<end; i++) {
                
                unsigned int *p = buffer+(i-begin)*w;
                    
                sr = sg = sb = 0;
                
                for(long k=-(radius+1); k<radius; k++) {
                    long j2 = 0+k;
                    if(j2<0) j2=0;
                    else if(j2>=w-1) j2=w-1;
                    unsigned int pixel = *(p+j2);
#ifdef BGRA
                    sb+=(pixel>>24)&0xFF;
                    sg+=(pixel>>16)&0xFF;
                    sr+=(pixel>>8)&0xFF;
#else
                    sb+=(pixel>>16)&0xFF;
                    sg+=(pixel>>8)&0xFF;
                    sr+=(pixel)&0xFF;
#endif
                }
                
                unsigned int *q = dst+i;
                
                for(long j=0; j<w; j++) {
                    // sub
                    long j2 = j-(radius+1);
                    if(j2<0) j2=0;
                    unsigned int pixel = *(p+j2);
#ifdef BGRA
                    sb-=(pixel>>24)&0xFF;
                    sg-=(pixel>>16)&0xFF;
                    sr-=(pixel>>8)&0xFF;
#else
                    sb-=(pixel>>16)&0xFF;
                    sg-=(pixel>>8)&0xFF;
                    sr-=(pixel)&0xFF;
#endif
                    // add
                    j2 = j+radius;
                    if(j2>=w-1) j2=w-1;
                    pixel = *(p+j2);
#ifdef BGRA
                    sb+=(pixel>>24)&0xFF;
                    sg+=(pixel>>16)&0xFF;
                    sr+=(pixel>>8)&0xFF;
#else
                    sb+=(pixel>>16)&0xFF;
                    sg+=(pixel>>8)&0xFF;
                    sr+=(pixel)&0xFF;
#endif

                    unsigned char r = sr*weight;
                    unsigned char g = sg*weight;
                    unsigned char b = sb*weight;
                                        
#ifdef BGRA
                    *q = b<<24|g<<16|r<<8|0xFF;
#else
                    *q = 0xFF000000|b<<16|g<<8|r;
#endif
                    q+=h;
                }
            }
        }

        void blurY(unsigned int *dst, unsigned int *src, unsigned int *buffer, long w, long h, long begin, long end) {
            
            long radius = this->_radius;
            if(radius<=1) radius = 1;
            else if(radius>=(w>>2)) radius = w>>2;
            else if(radius>=(h>>2)) radius = h>>2;
                
            double weight = 1.0/(double)(radius*2+1);
                
            unsigned int sr = 0;
            unsigned int sg = 0;
            unsigned int sb = 0;
            
            unsigned int *buf = buffer;

            for(long j=begin; j<end; j++) {
                
                sr = sg = sb = 0;
                
                unsigned int *p = src+j*h;
                
                for(long k=-(radius+1); k<radius; k++) {
                    long i2 = 0+k;
                    if(i2<0) i2 = 0;
                    else if(i2>=h-1) i2=h-1;
                    unsigned int pixel = *(p+i2);
#ifdef BGRA
                    sb+=(pixel>>24)&0xFF;
                    sg+=(pixel>>16)&0xFF;
                    sr+=(pixel>>8)&0xFF;
#else
                    sb+=(pixel>>16)&0xFF;
                    sg+=(pixel>>8)&0xFF;
                    sr+=(pixel)&0xFF;
#endif
                }
                
                for(long i=0; i<h; i++) {
                    // sub
                    long i2 = i-(radius+1);
                    if(i2<0) i2 = 0;
                    unsigned int pixel = *(p+i2);
#ifdef BGRA
                    sb-=(pixel>>24)&0xFF;
                    sg-=(pixel>>16)&0xFF;
                    sr-=(pixel>>8)&0xFF;
#else
                    sb-=(pixel>>16)&0xFF;
                    sg-=(pixel>>8)&0xFF;
                    sr-=(pixel)&0xFF;
#endif
                    // add
                    i2 = i+radius;
                    if(i2>=h) i2 = h-1;
                    pixel = *(p+i2);
#ifdef BGRA
                    sb+=(pixel>>24)&0xFF;
                    sg+=(pixel>>16)&0xFF;
                    sr+=(pixel>>8)&0xFF;
#else
                    sb+=(pixel>>16)&0xFF;
                    sg+=(pixel>>8)&0xFF;
                    sr+=(pixel)&0xFF;
#endif
                                
                    unsigned char r = sr*weight;
                    unsigned char g = sg*weight;
                    unsigned char b = sb*weight;
#ifdef BGRA
                    *buf++ = b<<24|g<<16|r<<8|0xFF;
#else
                    *buf++ = 0xFF000000|b<<16|g<<8|r;
#endif
                }
            }
            
            for(long j=begin; j<end; j++) {
                    
                sr = sg = sb = 0;
                
                unsigned int *p = buffer+(j-begin)*h;
                
                for(long k=-(radius+1); k<radius; k++) {
                    long i2 = 0+k;
                    if(i2<0) i2 = 0;
                    else if(i2>=h-1) i2=h-1;
                    unsigned int pixel = *(p+i2);
#ifdef BGRA
                    sb+=(pixel>>24)&0xFF;
                    sg+=(pixel>>16)&0xFF;
                    sr+=(pixel>>8)&0xFF;
#else
                    sb+=(pixel>>16)&0xFF;
                    sg+=(pixel>>8)&0xFF;
                    sr+=(pixel)&0xFF;
#endif
                }
                
                unsigned int *q = dst+j;
                
                for(long i=0; i<h; i++) {
                    // sub
                    long i2 = i-(radius+1);
                    if(i2<0) i2 = 0;
                    unsigned int pixel = *(p+i2);
#ifdef BGRA
                    sb-=(pixel>>24)&0xFF;
                    sg-=(pixel>>16)&0xFF;
                    sr-=(pixel>>8)&0xFF;
#else
                    sb-=(pixel>>16)&0xFF;
                    sg-=(pixel>>8)&0xFF;
                    sr-=(pixel)&0xFF;
#endif
                    // add
                    i2 = i+radius;
                    if(i2>=h) i2 = h-1;
                    pixel = *(p+i2);
#ifdef BGRA
                    sb+=(pixel>>24)&0xFF;
                    sg+=(pixel>>16)&0xFF;
                    sr+=(pixel>>8)&0xFF;
#else
                    sb+=(pixel>>16)&0xFF;
                    sg+=(pixel>>8)&0xFF;
                    sr+=(pixel)&0xFF;
#endif

                    unsigned char r = sr*weight;
                    unsigned char g = sg*weight;
                    unsigned char b = sb*weight;
#ifdef BGRA
                    *q = b<<24|g<<16|r<<8|0xFF;
#else
                    *q = 0xFF000000|b<<16|g<<8|r;
#endif
                    q+=w;
                }
            }
        }
        
    
    public :
    
        Blur() {
            
        }
        
        ~Blur() {
            
            if(this->_xy) delete[] this->_xy;
            if(this->_yx) delete[] this->_yx;
            
            for(int k=0; k<thread; k++) {
                if(this->_rgb[k]) delete[] this->_rgb[k];
            }
                                        
            for(int k=0; k<thread; k++) {
                if(this->_buffer[k]) delete[] this->_buffer[k];
            }
        }
    
        void set(std::string key, void *value) {
            if(key=="radius") this->_radius = *((long *)value);
        }
    
        void calc(unsigned int *bop, unsigned int *bip, long width, long height, long rowBytes) {
            
            if(this->_radius>=1) {
                
                if(!this->_init) {
                    this->_init = true;
                    
                    this->_width  = width;
                    this->_height = height;
                    
                    this->reset();
                }
                
                if(!(this->_width==width&&this->_height==height)) {
                    
                    this->_width  = width;
                    this->_height = height;
                    
                    this->reset();
                }
                
                for(long i=0; i<height; i++) {
                    memcpy((void *)(this->_xy+i*width),(void *)(bip+i*rowBytes),width*sizeof(unsigned int));
                }
                
                long col = height/this->thread;
                
                for(int k=0; k<this->thread; k++) {
                                
                    if(k==this->thread-1) {
                        dispatch_group_async(_group,_queue,^{
                            this->blurX(this->_yx,this->_xy,this->_buffer[k],width,height,col*k,height);
                        });
                    }
                    else {
                        dispatch_group_async(_group,_queue,^{
                            this->blurX(this->_yx,this->_xy,this->_buffer[k],width,height,col*k,col*(k+1));
                        });
                    }
                }
                
                dispatch_group_wait(_group,DISPATCH_TIME_FOREVER);
                
                long row = width/this->thread;

                for(int k=0; k<this->thread; k++) {
                                
                    if(k==this->thread-1) {
                        dispatch_group_async(_group,_queue,^{
                            this->blurY(this->_xy,this->_yx,this->_buffer[k],width,height,row*k,width);
                        });
                    }
                    else {
                        dispatch_group_async(_group,_queue,^{
                            this->blurY(this->_xy,this->_yx,this->_buffer[k],width,height,row*k,row*(k+1));
                        });
                    }
                    
                }
                dispatch_group_wait(_group,DISPATCH_TIME_FOREVER);
                
                for(long i=0; i<height; i++) {
            
                    memcpy((void *)(bop+i*rowBytes),(void *)(this->_xy+i*width),width*sizeof(unsigned int));
                }
            }
            else {
                
                memcpy((void *)bop,(void *)bip,rowBytes*height*sizeof(unsigned int));

            }
        }
};
