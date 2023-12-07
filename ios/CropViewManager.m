//
//  CropViewManager.m
//  react-native-image-crop-tools
//
//  Created by Hunaid Hassan on 31/12/2019.
//

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
        } else {
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
        UIImage *rotatedImage = [self rotateImage:[cropView getCroppedImage] byDegrees:degrees];

        cropView.onImageSaved(@{
            @"uri": [self saveRotatedImage:rotatedImage],
            // ... other properties ...
        });
    }];
}

- (UIImage *)rotateImage:(UIImage *)image byDegrees:(CGFloat)degrees {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, image.size.width / 2.0, image.size.height / 2.0);
    CGContextRotateCTM(context, degrees * M_PI / 180.0);
    CGContextTranslateCTM(context, -image.size.width / 2.0, -image.size.height / 2.0);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return rotatedImage;
}

- (NSString *)saveRotatedImage:(UIImage *)image {
    NSString *extension = @"jpg"; // Default extension

    // Determine the image format based on the presence of alpha channel
    if ([[image valueForKey:@"hasAlpha"] boolValue]) {
        extension = @"png";
    }

    // Create a unique filename
    NSString *filename = [NSString stringWithFormat:@"%@.%@", [[NSUUID UUID] UUIDString], extension];

    // Create the file URL
    NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    NSURL *url = [[paths firstObject] URLByAppendingPathComponent:filename];

    // Save the rotated image to the file URL
    if ([extension isEqualToString:@"png"]) {
        [UIImagePNGRepresentation(image) writeToURL:url atomically:YES];
    } else {
        // You can adjust the compression quality as needed
        [UIImageJPEGRepresentation(image, 0.9) writeToURL:url atomically:YES];
    }

    // Return the absolute URL of the saved image
    return url.absoluteString;
}

@end
