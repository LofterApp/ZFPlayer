//
//  ZFPlayerSimpleView.h
//  Player
//
//  Created by zmm on 26/2/2017.
//  Copyright © 2017 . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZFPlayer.h"
#import "ZFPlayerSimpleControlView.h"
#import "ZFPlayerModel.h"
#import "ZFPlayerControlViewDelegate.h"

@interface ZFPlayerSimpleView : UIView <ZFPlayerControlViewDelagate>

/** 视频model */
/** 设置playerLayer的填充模式 */
@property (nonatomic, assign) ZFPlayerLayerGravity    playerLayerGravity;
/** 设置代理 */
@property (nonatomic, weak) id<ZFPlayerDelegate>      delegate;
/** 是否被用户暂停 */
@property (nonatomic, assign, readonly) BOOL          isPauseByUser;
/** 播发器的几种状态 */
@property (nonatomic, assign, readonly) ZFPlayerState state;
/** 播放器当前播放的数据Model */
@property (nonatomic, strong, readonly) ZFPlayerModel *playerModel;

/** 静音（默认为NO）*/
@property (nonatomic, assign) BOOL                    mute;

@property (nonatomic, assign) BOOL    loop;    /**< 循环播放 */

@property (nonatomic, copy) void(^closeHandler)(void); /**< 关闭事件 */

/**
 *  单例，用于列表cell上多个视频
 *
 *  @return ZFPlayer
 */
+ (instancetype)sharedPlayerView;

/**
 取消显示 控制层
 */
- (void)enableControlView:(BOOL)enable;

/**
 *  自动播放，默认不自动播放
 */
- (void)autoPlayTheVideo;

/**
 *  重置player
 */
- (void)resetPlayer;

/**
 *  在当前页面，设置新的视频时候调用此方法
 */
- (void)resetToPlayNewVideo:(ZFPlayerModel *)playerModel;

/**
 *  播放
 */
- (void)play;

/**
 * 暂停
 */
- (void)pause;
/**
 * get current play time seconds
 */
- (NSUInteger)getCurrentPlayTime;
/**
 * get current buffer progress
 */
- (CGFloat)getCurrentBufferProgress;

@end
