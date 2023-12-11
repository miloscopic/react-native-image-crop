#import "CropViewManager.h"
#import "RCTCropView.h"
#import <React/RCTUIManager.h>

@implementation CropViewManager

RCT_EXPORT_MODULE()

-(UIView *)view {
    return [[RCTCropView alloc] init];
}

RCT_EXPORT_VIEW_PROPERTY(sourceUrl, NSString)
RCT_EXPORT_VIEW_PROPERTY(onImageSaved, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(keepAspectRatio, BOOL)
RCT_EXPORT_VIEW_PROPERTY(cropAspectRatio, CGSize)
RCT_EXPORT_VIEW_PROPERTY(iosDimensionSwapEnabled, BOOL)


RCT_EXPORT_METHOD(saveImage:(nonnull NSNumber*) reactTag
                  preserveTransparency:(BOOL) preserveTransparency
                  quality:(nonnull NSNumber *) quality) {
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
        RCTCropView *cropView = (RCTCropView *)viewRegistry[reactTag];
        CGRect cropFrame = [cropView getCropFrame];
        UIImage *image = [cropView getCroppedImage];

        NSString *extension = @"jpg";
        if ([[image valueForKey:@"hasAlpha"] boolValue] && preserveTransparency) {
            extension = @"png";
        }

        NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
        NSURL *url = [[paths firstObject] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", [[NSUUID UUID] UUIDString], extension]];

        if ([[image valueForKey:@"hasAlpha"] boolValue] && preserveTransparency) {
            [UIImagePNGRepresentation(image) writeToURL:url atomically:YES];
        }else {
            [UIImageJPEGRepresentation(image, [quality floatValue] / 100.0f) writeToURL:url atomically:YES];
        }

        cropView.onImageSaved(@{
            @"uri": url.absoluteString,
            @"width": [NSNumber numberWithDouble:cropFrame.size.width],
            @"height": [NSNumber numberWithDouble:cropFrame.size.height],
            @"x": [NSNumber numberWithDouble:cropFrame.origin.x],
            @"y": [NSNumber numberWithDouble:cropFrame.origin.y]
        });
    }];
}

RCT_EXPORT_METHOD(rotateImage:(nonnull NSNumber*) reactTag degrees:(CGFloat) degrees) {
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
        RCTCropView *cropView = (RCTCropView *)viewRegistry[reactTag];

        // Convert degrees to radians
        CGFloat radians = degrees * M_PI / 180.0;

        // Apply a CGAffineTransform to rotate only the image within the cropView
        cropView.transform = CGAffineTransformRotate(cropView.transform, radians);

        // Notify the view that it needs to redraw
        [cropView setNeedsDisplay];
    }];
}

@end
