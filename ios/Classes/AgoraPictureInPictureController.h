//
//  AgoraPictureInPictureController.h
//  flutter_float_window
//
//  Created by Kevin Jing on 2023/7/19.
//

#import <Foundation/Foundation.h>
#import "AgoraSampleBufferRender.h"
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol AgoraPictureInPictureControllerDelegate <NSObject>

@optional

@end

//仅支持IOS15以后
@interface AgoraPictureInPictureController : NSObject

@property (nonatomic, weak) id <AgoraPictureInPictureControllerDelegate>delegate;

@property (nonatomic, strong, readonly) AVPictureInPictureController *pipController;

@property (nonatomic, strong, readonly) AgoraSampleBufferRender *displayView;

- (instancetype)initWithDisplayView:(AgoraSampleBufferRender *)displayView;

- (void)releasePIP;
    
@end

NS_ASSUME_NONNULL_END
