-- Copyright (c) 2017-2018 vislee

local ffi = require("ffi")
local cvCore, cvHighgui, cvImgproc, cvObjdetect = nil, nil, nil, nil

ffi.cdef([[
    typedef signed char schar;
    typedef void CvArr;

    typedef struct _IplROI {
        int  coi; /* 0 - no COI (all channels are selected), 1 - 0th channel is selected ...*/
        int  xOffset;
        int  yOffset;
        int  width;
        int  height;
    } IplROI;

    typedef struct _IplImage {
        int        nSize;                        /* sizeof(IplImage) */
        int        ID;                            /* version (=0)*/
        int        nChannels;                    /* Most of OpenCV functions support 1,2,3 or 4 channels */
        int        alphaChannel;                /* Ignored by OpenCV */
        int        depth;                        /* Pixel depth in bits: IPL_DEPTH_8U, IPL_DEPTH_8S, IPL_DEPTH_16S,
                                               IPL_DEPTH_32S, IPL_DEPTH_32F and IPL_DEPTH_64F are supported.  */
    
        char    colorModel[4];                /* Ignored by OpenCV */
        char    channelSeq[4];                /* ditto */
        int        dataOrder;                    /* 0 - interleaved color channels, 1 - separate color channels.
                                            cvCreateImage can only create interleaved images */
    
        int        origin;                        /* 0 - top-left origin,
                                            1 - bottom-left origin (Windows bitmaps style).  */
    
        int        align;                        /* Alignment of image rows (4 or 8).
                                            OpenCV ignores it and uses widthStep instead.    */
    
        int        width;                        /* Image width in pixels.                            */
        int        height;                        /* Image height in pixels.                           */
        struct    _IplROI *roi;                /* Image ROI. If NULL, the whole image is selected.  */
        struct    _IplImage *maskROI;            /* Must be NULL. */
        void*    imageId;                        /* "           " */
        struct    _IplTileInfo *tileInfo;        /* "           " */
        int        imageSize;                    /* Image data size in bytes
                                            (==image->height*image->widthStep
                                            in case of interleaved data)*/
    
        char*    imageData;                    /* Pointer to aligned image data.         */
        int        widthStep;                    /* Size of aligned image row in bytes.    */
        int        BorderMode[4];                /* Ignored by OpenCV.                     */
        int        BorderConst[4];                /* Ditto.                                 */
        char*    imageDataOrigin;            /* Pointer to very origin of image data
                                            (not necessarily aligned) -
                                            needed for correct deallocation */
    } IplImage;

    typedef struct CvSize {
        int width;
        int height;
    } CvSize;

    typedef struct CvMemBlock {
        struct CvMemBlock*  prev;
        struct CvMemBlock*  next;
    } CvMemBlock;

    typedef struct CvMemStorage {
        int signature;
        CvMemBlock* bottom;           /* First allocated block.                   */
        CvMemBlock* top;              /* Current memory block - top of the stack. */
        struct  CvMemStorage* parent; /* We get new blocks from parent as needed. */
        int block_size;               /* Block size.                              */
        int free_space;               /* Remaining free space in current block.   */
    } CvMemStorage;

    typedef struct CvSeqBlock {
        struct CvSeqBlock*  prev;     /* Previous sequence block.                   */
        struct CvSeqBlock*  next;     /* Next sequence block.                       */
        int start_index;              /* Index of the first element in the block +  */
                                      /* sequence->first->start_index.              */
        int count;                    /* Number of elements in the block.           */
        schar* data;                  /* Pointer to the first element of the block. */
    } CvSeqBlock;

    typedef struct CvSeq {
        int       flags;             /* Miscellaneous flags.     */      
        int       header_size;       /* Size of sequence header. */      
        struct    CvSeq* h_prev;         /* Previous sequence.       */      
        struct    CvSeq* h_next;         /* Next sequence.           */      
        struct    CvSeq* v_prev;         /* 2nd previous sequence.   */    
        struct    CvSeq* v_next;      /* 2nd next sequence.       */
                                                
        int       total;              /* Total number of elements.            */  
        int       elem_size;          /* Size of sequence element in bytes.   */  
        schar*    block_max;              /* Maximal bound of the last block.     */ 
        schar*    ptr;                    /* Current write pointer.               */  
        int       delta_elems;        /* Grow seq this many at a time.        */  
        CvMemStorage* storage;        /* Where the seq is stored.             */  
        CvSeqBlock* free_blocks;      /* Free blocks list.                    */  
        CvSeqBlock* first;            /* Pointer to the first sequence block. */
    } CvSeq;

    typedef struct _CvRect {
        int x;
        int y;
        int width;
        int height;
    } CvRect;


    IplImage* cvLoadImage( const char* filename, int iscolor);
    int cvSaveImage( const char* filename, const CvArr* image );
    void cvReleaseImage(IplImage** image);
    IplImage* cvCreateImage(CvSize size, int depth, int channels);
    void cvEqualizeHist( const CvArr* src, CvArr* dst );
    CvSeq* cvHaarDetectObjects(const CvArr* image,
                               void* cascade, 
                               CvMemStorage* storage,
                               double scale_factor,
                               int min_neighbors, 
                               int flags,
                               CvSize min_size, 
                               CvSize max_size);
    void cvCvtColor( const CvArr* src, CvArr* dst, int code );
    void* cvLoad( const char* filename,
                  CvMemStorage* memstorage,
                  const char* name,
                  const char** real_name );
    CvMemStorage* cvCreateMemStorage( int block_size );
    void cvReleaseMemStorage( CvMemStorage** storage );
    schar* cvGetSeqElem( const CvSeq* seq, int index );


]])


if ffi.os == 'Windows' then
    -- 暂不支持
    error("donot support")
elseif ffi.os == 'OSX' then
    cvCore      = ffi.load("opencv_core")
    cvHighgui   = ffi.load("opencv_highgui")
    cvImgproc   = ffi.load("opencv_imgproc")
    cvObjdetect = ffi.load("opencv_objdetect")
else
    cvCore      = ffi.load("cxcore")
    cvHighgui   = ffi.load("highgui")
    cvImgproc   = ffi.load("cv")
    cvObjdetect = ffi.load("cv")
end


local _M = {}
setmetatable(_M, {
    __call = function(self, ...)
        return self.New(...)
    end
})


function _M.cvSize(w, h)
    return ffi.new("CvSize", {
        width = w or 0,
        height = h or 0,
    })
end


function _M.cvSeq(seq, index)
    return cvCore.cvGetSeqElem(seq, index)
end


function _M.memStor(size)
    return cvCore.cvCreateMemStorage(size)
end

function _M.memStorRelease(stor)
    local pointer = ffi.new("CvMemStorage *[1]")
    pointer[0] = stor
    return cvCore.cvReleaseMemStorage(pointer);
end


function _M.cvLoad(filename, memstor, name, real_name)
    return cvCore.cvLoad(filename, memstor, name, real_name)
end

function _M.cvRelease(img)
    local pointer = ffi.new("IplImage *[1]")
    pointer[0] = img
    cvCore.cvReleaseImage(pointer)
end

function _M.haarDetect(image, cascade, storage, scale_factor, min_neighbors, flags, min_size, max_size)
    scale_factor = scale_factor or 1.1
    min_neighbors = min_neighbors or 3
    flags = flags or 0
    min_size = min_size or _M.cvSize(0, 0)
    max_size = max_size or _M.cvSize(0, 0)
    return cvObjdetect.cvHaarDetectObjects(image, cascade, storage, scale_factor, min_neighbors, flags, min_size, max_size)
end


function _M.New()
    local m = {}
    setmetatable(m, {__index = _M})
    return m
end

function _M:cvImgxs(w, h, blob, depth, nChannels)
    self:release()
    self.img = cvCore.cvCreateImage(_M.cvSize(w, h), depth, nChannels)
    if self.img == nil then
        return nil, "cvCreateImage error"
    end
    self.img.imageData = blob

    return self
end

function _M.createImage(w, h, depth, nChannels)
    return cvCore.cvCreateImage(_M.cvSize(w, h), depth, nChannels)
end

function _M:load(file)
    self:release()
    self.img = cvHighgui.cvLoadImage(file, 1)
    if self.img == nil then
        return nil, "error"
    end
    return self
end


function _M:save(file)
    local r = cvHighgui.cvSaveImage(file, self.img)
    if r ~= 1 then
        error("save " .. file .. " error")
    end
    return self
end

function _M:getSize()
    return self.img.width, self.img.height
end


function _M:imageData()
    return self.img.imageData, self.img.imageSize
end

function _M:release()
    if self.img ~= nil then
        self.cvRelease(self.img)
        self.img = nil
    end

    return self
end


function _M:cvObjectDetect(casc, bigger)
    -- ngx.log(ngx.INFO, "cvObjectDetect==== ", casc)
    local err = {x=0, y=0, w=self.img.width, h=self.img.height}
    if not casc or string.len(casc) < 3 then
        return err
    end
    local cascade = self.cvLoad(casc)
    if not cascade then
        return err
    end

    -- ngx.log(ngx.INFO, "cvObjectDetect==== createImage")
    -- 转成灰色图片
    local gray = self.createImage(self.img.width, self.img.height, 8, 1)
    if gray == nil then
        return err
    end
    -- ngx.log(ngx.INFO, "cvObjectDetect==== cvCvtColor")
    cvImgproc.cvCvtColor(self.img, gray, 6)
    cvImgproc.cvEqualizeHist(gray, gray)
    -- ngx.log(ngx.INFO, "cvObjectDetect==== haarDetect")

    local scale_factor = 1.1
    local flags        = 3
    if bigger then
        scale_factor   = 1.3
        flags          = 15
    end
    local ojbss = {}
    local storage = self.memStor(0)
    local objs = self.haarDetect(gray, cascade, storage, scale_factor, 3, flags, self.cvSize(self.img.width/100, self.img.height/100), self.cvSize(0, 0))
    local objx, objy, objw, objh = 0, 0, self.img.width, self.img.height
    if objs and objs.total > 0 then
        for i = 0,(objs.total-1) do
            local rect = self.cvSeq(objs, i)
            rect = ffi.cast("CvRect *", rect)
            table.insert(ojbss, {x=rect.x, y=rect.y, w=rect.width, h=rect.height})
            local w, h = rect.x + rect.width, rect.y + rect.height
            if objx == 0 or objx > rect.x then
                objx = rect.x
            end
            if objy == 0 or objy > rect.y then
                objy = rect.y
            end
            if objw == self.img.width or objw < w then
                objw = w
            end
            if objh == self.img.height or objh < h then
                objh = h
            end

            -- ngx.log(ngx.INFO, string.format("haarDetect res =%d==%d,%d,%d,%d", i, objx, objy, objw, objh))
        end
    end
    self.cvRelease(gray)
    self.memStorRelease(storage)
    return {x=objx, y=objy, w=objw-objx, h=objh-objy}, ojbss
end


-- Exports:
return _M