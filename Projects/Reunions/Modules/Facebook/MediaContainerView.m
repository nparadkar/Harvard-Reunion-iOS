#import "MediaContainerView.h"
#define MAXIMUM_IMAGE_HEIGHT 500

@interface MediaContainerView (Private) 

+ (CGFloat)deltaHeightForImageSize:(CGSize)size fitToWidth:(CGFloat)width oldHeight:(CGFloat)oldHeight;
- (void)setFrame:(CGRect)frame withImageHeight:(CGFloat)height;

@end

@implementation MediaContainerView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        _previewSize = CGSizeMake(0, 0);
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _previewSize = CGSizeMake(0, 0);
    }
    return self;
}

+ (CGFloat)heightForImageSize:(CGSize)size fitToWidth:(CGFloat)width {
    CGFloat newHeight = size.height *  (width / size.width);
    if (newHeight > MAXIMUM_IMAGE_HEIGHT) {
        newHeight = MAXIMUM_IMAGE_HEIGHT;
    }
    return  newHeight;
}

/*
 *  Only call this once this assumes the input view is already
 *  part of the view heirarchy, and has the correct
 *  frame and autoresizing property;
 */
- (void)initPreviewView:(UIView *)view {
    _previewView = view;
}

- (void)setPreviewView:(UIView *)view {
    CGRect frame = _previewView.frame;
    view.frame = frame;
    view.autoresizingMask = _previewView.autoresizingMask;
    UIView *previewSuperView = [_previewView superview];
    [_previewView removeFromSuperview];
    _previewView = view;
    [previewSuperView addSubview:_previewView];    
}

- (UIView *)previewView {
    return _previewView;
}

- (void)setPreviewSize:(CGSize)size {
    
    _previewSize = size;
    CGFloat newHeight = [MediaContainerView heightForImageSize:size 
                                                   fitToWidth:_previewView.frame.size.width];
    
    [self setFrame:self.frame withImageHeight:newHeight];
}

- (void)setFrame:(CGRect)frame withImageHeight:(CGFloat)height {
    CGFloat deltaHeight = height - _previewView.frame.size.height;
    frame.size.height = frame.size.height + deltaHeight;
    [super setFrame:frame];
}

- (void)setFrame:(CGRect)frame {
    if(_previewSize.width > 0) {
        CGFloat deltaWidth = frame.size.width - self.frame.size.width;
        CGFloat newWidth = _previewView.frame.size.width + deltaWidth;
        CGFloat newHeight = [MediaContainerView heightForImageSize:_previewSize fitToWidth:newWidth];
        [self setFrame:frame withImageHeight:newHeight];
    } else {
        [super setFrame:frame];
    }
}

@end
