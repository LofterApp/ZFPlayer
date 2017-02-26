//
//  ZFPlayerSimpleControlView.m
//  Player
//
//  Created by zmm on 26/2/2017.
//  Copyright © 2017 . All rights reserved.
//

#import "ZFPlayerSimpleControlView.h"
#import "UIView+CustomControlView.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"

static const CGFloat ZFPlayerAnimationTimeInterval             = 7.0f;
static const CGFloat ZFPlayerControlBarAutoFadeOutTimeInterval = 0.35f;

@interface ZFPlayerSimpleControlView ()  <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *topImageView;

/** 关闭按钮*/
@property (nonatomic, strong) UIButton                *closeBtn;

@property (nonatomic, strong) UIImageView *bottomImageView;

/** 开始播放按钮 */
@property (nonatomic, strong) UIButton                *startBtn;

/** 视频当前时长label */
@property (nonatomic, strong) UILabel                 *currentTimeLabel;

/** 视频总时长label */
@property (nonatomic, strong) UILabel                 *totalTimeLabel;

/** 静音按钮 */
@property (nonatomic, strong) UIButton                *muteBtn;

/** 缓冲进度条 */
@property (nonatomic, strong) UIProgressView          *progressView;

/** 滑杆 */
@property (nonatomic, strong) ASValueTrackingSlider   *videoSlider;

/** 系统菊花 */
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

/** 播放按钮 */
@property (nonatomic, strong) UIButton                *playeBtn;
/** 加载失败按钮 */
@property (nonatomic, strong) UIButton                *failBtn;

/** 播放模型 */
@property (nonatomic, strong) ZFPlayerModel           *playerModel;
/** 显示控制层 */
@property (nonatomic, assign, getter=isShowing) BOOL  showing;

/** 是否拖拽slider控制播放进度 */
@property (nonatomic, assign, getter=isDragged) BOOL  dragged;
/** 是否播放结束 */
@property (nonatomic, assign, getter=isPlayEnd) BOOL  playeEnd;

/** 是否全屏播放 */
@property (nonatomic, assign,getter=isFullScreen)BOOL fullScreen;

@end

@implementation ZFPlayerSimpleControlView

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self addSubview:self.topImageView];
        [self addSubview:self.bottomImageView];
        
        [self.topImageView addSubview:self.closeBtn];
        
        [self.bottomImageView addSubview:self.startBtn];
        [self.bottomImageView addSubview:self.videoSlider];
        [self.bottomImageView addSubview:self.progressView];
        [self.bottomImageView addSubview:self.currentTimeLabel];
        [self.bottomImageView addSubview:self.totalTimeLabel];
        [self.bottomImageView addSubview:self.activityIndicator];
        [self.bottomImageView addSubview:self.muteBtn];
        
        [self addSubview:self.playeBtn];
        [self addSubview:self.failBtn];
        
        // 添加子控件的约束
        [self makeSubViewsConstraints];
        
        // 初始化时重置controlView
        [self zf_playerResetControlView];
        // app退到后台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
        // app进入前台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayground) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [self listeningRotating];
        [self onDeviceOrientationChange];
    }
    return self;
}

- (void)makeSubViewsConstraints
{
    [self.topImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self);
        make.top.equalTo(self.mas_top).offset(20);
        make.height.mas_equalTo(50);
    }];
    
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.equalTo(self.topImageView);
        make.width.height.mas_equalTo(40);
    }];
    
    [self.bottomImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(self);
        make.height.mas_equalTo(50);
    }];
    
    [self.startBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.bottomImageView.mas_leading).offset(5);
        make.bottom.equalTo(self.bottomImageView.mas_bottom).offset(-5);
        make.width.height.mas_equalTo(30);
    }];
    
    [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.startBtn.mas_trailing).offset(-3);
        make.centerY.equalTo(self.startBtn.mas_centerY);
        make.width.mas_equalTo(43);
    }];
    
    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.muteBtn.mas_leading).offset(3);
        make.centerY.equalTo(self.startBtn.mas_centerY);
        make.width.mas_equalTo(43);
    }];
    
    [self.muteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(30);
        make.trailing.equalTo(self.bottomImageView.mas_trailing).offset(-5);
        make.centerY.equalTo(self.startBtn.mas_centerY);
    }];
    
    [self.videoSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.currentTimeLabel.mas_trailing).offset(4);
        make.trailing.equalTo(self.totalTimeLabel.mas_leading).offset(-4);
        make.centerY.equalTo(self.currentTimeLabel.mas_centerY).offset(-1);
        make.height.mas_equalTo(30);
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.videoSlider);
        make.centerY.equalTo(self.startBtn.mas_centerY);
    }];
    
    [self.activityIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.videoSlider.mas_leading);
        make.centerY.equalTo(self.videoSlider.mas_centerY);
        make.height.equalTo(self.videoSlider.mas_height);
        make.width.equalTo(self.activityIndicator.mas_height);
    }];
    
    [self.playeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(50);
        make.center.equalTo(self);
    }];
    
    [self.failBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(33);
    }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self layoutIfNeeded];
    [self zf_playerCancelAutoFadeOutControlView];
    if (!self.isPlayEnd) {
        // 只要屏幕旋转就显示控制层
        [self zf_playerShowControlView];
    }
    
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (currentOrientation == UIDeviceOrientationPortrait) {
        [self setOrientationPortraitConstraint];
    } else {
        [self setOrientationLandscapeConstraint];
    }
}

#pragma mark - Action

/**
 *  UISlider TapAction
 */
- (void)tapSliderAction:(UITapGestureRecognizer *)tap
{
    if ([tap.view isKindOfClass:[UISlider class]]) {
        UISlider *slider = (UISlider *)tap.view;
        CGPoint point = [tap locationInView:slider];
        CGFloat length = slider.frame.size.width;
        // 视频跳转的value
        CGFloat tapValue = point.x / length;
        if ([self.delegate respondsToSelector:@selector(zf_controlView:progressSliderTap:)]) {
            [self.delegate zf_controlView:self progressSliderTap:tapValue];
        }
    }
}
// 不做处理，只是为了滑动slider其他地方不响应其他手势
- (void)panRecognizer:(UIPanGestureRecognizer *)sender {}

- (void)playBtnClick:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if ([self.delegate respondsToSelector:@selector(zf_controlView:playAction:)]) {
        [self.delegate zf_controlView:self playAction:sender];
    }
}

- (void)closeBtnClick:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(zf_controlView:closeAction:)]) {
        [self.delegate zf_controlView:self closeAction:sender];
    }
}

- (void)failBtnClick:(UIButton *)sender
{
    self.failBtn.hidden = YES;
    if ([self.delegate respondsToSelector:@selector(zf_controlView:failAction:)]) {
        [self.delegate zf_controlView:self failAction:sender];
    }
}

- (void)centerPlayBtnClick:(UIButton *)sender
{
    [self.playeBtn setHidden:YES];
    if ([self.delegate respondsToSelector:@selector(zf_controlView:cneterPlayAction:)]) {
        [self.delegate zf_controlView:self cneterPlayAction:sender];
    }
}

- (void)muteBtnClick:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if ([self.delegate respondsToSelector:@selector(zf_controlView:muteAction:)]) {
        [self.delegate zf_controlView:self muteAction:sender];
    }
}

- (void)progressSliderTouchBegan:(ASValueTrackingSlider *)sender
{
    [self zf_playerCancelAutoFadeOutControlView];
    self.videoSlider.popUpView.hidden = YES;
    if ([self.delegate respondsToSelector:@selector(zf_controlView:progressSliderTouchBegan:)]) {
        [self.delegate zf_controlView:self progressSliderTouchBegan:sender];
    }
}

- (void)progressSliderValueChanged:(ASValueTrackingSlider *)sender
{
    if ([self.delegate respondsToSelector:@selector(zf_controlView:progressSliderValueChanged:)]) {
        [self.delegate zf_controlView:self progressSliderValueChanged:sender];
    }
}

- (void)progressSliderTouchEnded:(ASValueTrackingSlider *)sender
{
    self.showing = YES;
    if ([self.delegate respondsToSelector:@selector(zf_controlView:progressSliderTouchEnded:)]) {
        [self.delegate zf_controlView:self progressSliderTouchEnded:sender];
    }
}

/**
 *  应用退到后台
 */
- (void)appDidEnterBackground
{
    [self zf_playerCancelAutoFadeOutControlView];
}

/**
 *  应用进入前台
 */
- (void)appDidEnterPlayground
{
    [self zf_playerShowControlView];
}

- (void)playerPlayDidEnd
{
    self.backgroundColor  = RGBA(0, 0, 0, .6);
    self.playeBtn.hidden = NO;
    self.startBtn.selected = NO;
    // 初始化显示controlView为YES
    self.showing = NO;
    // 延迟隐藏controlView
    [self zf_playerShowControlView];
}

/**
 *  屏幕方向发生变化会调用这里
 */
- (void)onDeviceOrientationChange
{
    if (!self.fullScreen) {
        return;
    }
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown || orientation == UIDeviceOrientationPortraitUpsideDown) { return; }
    if (ZFPlayerOrientationIsLandscape) {
        [self setOrientationLandscapeConstraint];
    } else {
        [self setOrientationPortraitConstraint];
    }
    [self layoutIfNeeded];
}

- (void)setOrientationLandscapeConstraint
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}
/**
 *  设置竖屏的约束
 */
- (void)setOrientationPortraitConstraint
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

#pragma mark - Private Method

- (void)showControlView
{
    self.backgroundColor           = RGBA(0, 0, 0, 0.3);
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)hideControlView
{
    self.backgroundColor          = RGBA(0, 0, 0, 0);
    // 隐藏resolutionView
    if (self.isFullScreen && !self.playeEnd) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    }
}

/**
 *  监听设备旋转通知
 */
- (void)listeningRotating
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil
     ];
}

- (void)autoFadeOutControlView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(zf_playerHideControlView) object:nil];
    [self performSelector:@selector(zf_playerHideControlView) withObject:nil afterDelay:ZFPlayerAnimationTimeInterval];
}

/**
 slider滑块的bounds
 */
- (CGRect)thumbRect
{
    return [self.videoSlider thumbRectForBounds:self.videoSlider.bounds
                                      trackRect:[self.videoSlider trackRectForBounds:self.videoSlider.bounds]
                                          value:self.videoSlider.value];
}

#pragma mark - setter

#pragma mark - getter

- (UIImageView *)topImageView
{
    if (!_topImageView) {
        _topImageView                        = [[UIImageView alloc] init];
        _topImageView.userInteractionEnabled = YES;
        _topImageView.image                  = ZFPlayerImage(@"ZFPlayer_top_shadow");
    }
    return _topImageView;
}

- (UIImageView *)bottomImageView
{
    if (!_bottomImageView) {
        _bottomImageView                        = [[UIImageView alloc] init];
        _bottomImageView.userInteractionEnabled = YES;
        _bottomImageView.image                  = ZFPlayerImage(@"ZFPlayer_bottom_shadow");
    }
    return _bottomImageView;
}

- (UIButton *)startBtn
{
    if (!_startBtn) {
        _startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_startBtn setImage:ZFPlayerImage(@"ZFPlayer_play") forState:UIControlStateNormal];
        [_startBtn setImage:ZFPlayerImage(@"ZFPlayer_pause") forState:UIControlStateSelected];
        [_startBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startBtn;
}

- (UIButton *)closeBtn
{
    if (!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeBtn setImage:ZFPlayerImage(@"ZFPlayer_close") forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(closeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

- (UILabel *)currentTimeLabel
{
    if (!_currentTimeLabel) {
        _currentTimeLabel               = [[UILabel alloc] init];
        _currentTimeLabel.textColor     = [UIColor whiteColor];
        _currentTimeLabel.font          = [UIFont systemFontOfSize:12.0f];
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _currentTimeLabel;
}

- (ASValueTrackingSlider *)videoSlider
{
    if (!_videoSlider) {
        _videoSlider                       = [[ASValueTrackingSlider alloc] init];
        _videoSlider.popUpViewCornerRadius = 0.0;
        _videoSlider.popUpViewColor = RGBA(19, 19, 9, 1);
        _videoSlider.popUpViewArrowLength = 8;
        
        [_videoSlider setThumbImage:ZFPlayerImage(@"ZFPlayer_slider") forState:UIControlStateNormal];
        _videoSlider.maximumValue          = 1;
        _videoSlider.minimumTrackTintColor = [UIColor whiteColor];
        _videoSlider.maximumTrackTintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        
        // slider开始滑动事件
        [_videoSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
        // slider滑动中事件
        [_videoSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        // slider结束滑动事件
        [_videoSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
        
        UITapGestureRecognizer *sliderTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSliderAction:)];
        [_videoSlider addGestureRecognizer:sliderTap];
        
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panRecognizer:)];
        panRecognizer.delegate = self;
        [panRecognizer setMaximumNumberOfTouches:1];
        [panRecognizer setDelaysTouchesBegan:YES];
        [panRecognizer setDelaysTouchesEnded:YES];
        [panRecognizer setCancelsTouchesInView:YES];
        [_videoSlider addGestureRecognizer:panRecognizer];
    }
    return _videoSlider;
}

- (UIProgressView *)progressView
{
    if (!_progressView) {
        _progressView                   = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progressTintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
        _progressView.trackTintColor    = [UIColor clearColor];
    }
    return _progressView;
}

- (UILabel *)totalTimeLabel
{
    if (!_totalTimeLabel) {
        _totalTimeLabel               = [[UILabel alloc] init];
        _totalTimeLabel.textColor     = [UIColor whiteColor];
        _totalTimeLabel.font          = [UIFont systemFontOfSize:12.0f];
        _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _totalTimeLabel;
}

- (UIActivityIndicatorView *)activityIndicator
{
    if (!_activityIndicator) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_activityIndicator hidesWhenStopped];
    }
    return _activityIndicator;
}

- (UIButton *)playeBtn
{
    if (!_playeBtn) {
        _playeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playeBtn setImage:ZFPlayerImage(@"ZFPlayer_play_btn") forState:UIControlStateNormal];
        [_playeBtn addTarget:self action:@selector(centerPlayBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playeBtn;
}

- (UIButton *)failBtn
{
    if (!_failBtn) {
        _failBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_failBtn setTitle:@"加载失败,点击重试" forState:UIControlStateNormal];
        [_failBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _failBtn.titleLabel.font = [UIFont systemFontOfSize:14.0];
        _failBtn.backgroundColor = RGBA(0, 0, 0, 0.7);
        [_failBtn addTarget:self action:@selector(failBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _failBtn;
}

- (UIButton *)muteBtn
{
    if (!_muteBtn) {
        _muteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_muteBtn setImage:ZFPlayerImage(@"ZFPlayer_fullscreen") forState:UIControlStateNormal];
        [_muteBtn setImage:ZFPlayerImage(@"ZFPlayer_shrinkscreen") forState:UIControlStateSelected];
        [_muteBtn addTarget:self action:@selector(muteBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _muteBtn;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGRect rect = [self thumbRect];
    CGPoint point = [touch locationInView:self.videoSlider];
    if ([touch.view isKindOfClass:[UISlider class]]) { // 如果在滑块上点击就不响应pan手势
        if (point.x <= rect.origin.x + rect.size.width && point.x >= rect.origin.x) { return NO; }
    }
    return YES;
}

#pragma mark - Public method

/** 重置ControlView */
- (void)zf_playerResetControlView
{
    [self.activityIndicator stopAnimating];
    self.progressView.progress       = 0;
    self.videoSlider.value           = 0;
    self.currentTimeLabel.text       = @"00:00";
    self.totalTimeLabel.text         = @"00:00";
    self.playeBtn.hidden             = YES;
    self.failBtn.hidden              = YES;
    self.backgroundColor             = [UIColor clearColor];
    self.showing                     = NO;
    self.playeEnd                    = NO;
    self.failBtn.hidden              = YES;
}

/**
 *  取消延时隐藏controlView的方法
 */
- (void)zf_playerCancelAutoFadeOutControlView
{
    self.showing = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

/** 设置播放模型 */
- (void)zf_playerModel:(ZFPlayerModel *)playerModel
{
    _playerModel = playerModel;
}

/** 正在播放（隐藏placeholderImageView） */
- (void)zf_playerItemPlaying
{
}

/**
 *  显示控制层
 */
- (void)zf_playerShowControlView
{
    if (self.isShowing) {
        [self zf_playerHideControlView];
        return;
    }
    [self zf_playerCancelAutoFadeOutControlView];
    [UIView animateWithDuration:ZFPlayerControlBarAutoFadeOutTimeInterval animations:^{
        [self showControlView];
    } completion:^(BOOL finished) {
        self.showing = YES;
        [self autoFadeOutControlView];
    }];
}

/**
 *  隐藏控制层
 */
- (void)zf_playerHideControlView
{
    if (!self.isShowing) { return; }
    [self zf_playerCancelAutoFadeOutControlView];
    [UIView animateWithDuration:ZFPlayerControlBarAutoFadeOutTimeInterval animations:^{
        [self hideControlView];
    }completion:^(BOOL finished) {
        self.showing = NO;
    }];
}

- (void)zf_playerCurrentTime:(NSInteger)currentTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)value
{
    // 当前时长进度progress
    NSInteger proMin = currentTime / 60;//当前秒
    NSInteger proSec = currentTime % 60;//当前分钟
    // duration 总时长
    NSInteger durMin = totalTime / 60;//总秒
    NSInteger durSec = totalTime % 60;//总分钟
    if (!self.isDragged) {
        // 更新slider
        self.videoSlider.value           = value;
        // 更新当前播放时间
        self.currentTimeLabel.text       = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    }
    // 更新总时间
    self.totalTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
}

- (void)zf_playerDraggedTime:(NSInteger)draggedTime totalTime:(NSInteger)totalTime isForward:(BOOL)forawrd hasPreview:(BOOL)preview
{
    // 快进快退时候停止菊花
    [self.activityIndicator stopAnimating];
    // 拖拽的时长
    NSInteger proMin = draggedTime / 60;//当前秒
    NSInteger proSec = draggedTime % 60;//当前分钟
    
    //duration 总时长
    NSInteger durMin = totalTime / 60;//总秒
    NSInteger durSec = totalTime % 60;//总分钟
    
    NSString *currentTimeStr = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    NSString *totalTimeStr   = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
    CGFloat  draggedValue    = (CGFloat)draggedTime/(CGFloat)totalTime;
    NSString *timeStr        = [NSString stringWithFormat:@"%@ / %@", currentTimeStr, totalTimeStr];
    
    // 显示、隐藏预览窗
    self.videoSlider.popUpView.hidden = !preview;
    // 更新slider的值
    self.videoSlider.value            = draggedValue;
    // 更新当前时间
    self.currentTimeLabel.text        = currentTimeStr;
    // 正在拖动控制播放进度
    self.dragged = YES;
}

- (void)zf_playerDraggedEnd
{
    self.dragged = NO;
    // 结束滑动时候把开始播放按钮改为播放状态
    self.startBtn.selected = YES;
    // 滑动结束延时隐藏controlView
    [self autoFadeOutControlView];
}

- (void)zf_playerDraggedTime:(NSInteger)draggedTime sliderImage:(UIImage *)image;
{
    // 拖拽的时长
    NSInteger proMin = draggedTime / 60;//当前秒
    NSInteger proSec = draggedTime % 60;//当前分钟
    NSString *currentTimeStr = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    [self.videoSlider setImage:image];
    [self.videoSlider setText:currentTimeStr];
}

/** progress显示缓冲进度 */
- (void)zf_playerSetProgress:(CGFloat)progress
{
    [self.progressView setProgress:progress animated:NO];
}

/** 视频加载失败 */
- (void)zf_playerItemStatusFailed:(NSError *)error
{
    self.failBtn.hidden = NO;
}

/** 加载的菊花 */
- (void)zf_playerActivity:(BOOL)animated
{
    if (animated) {
        [self.activityIndicator mas_updateConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.videoSlider.mas_leading).offset(CGRectGetWidth(self.videoSlider.frame) * self.videoSlider.value);
        }];
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
}

/** 播放完了 */
- (void)zf_playerPlayEnd
{
    self.startBtn.selected = NO;
    self.playeBtn.hidden = NO;
    self.playeEnd         = YES;
    self.showing          = NO;
    // 隐藏controlView
    [self hideControlView];
    self.backgroundColor  = RGBA(0, 0, 0, .3);
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

/**
 * 是否静音
 */
- (void)zf_playerMute:(BOOL)isMute
{
    self.muteBtn.selected = isMute;
}
/** 播放按钮状态 */
- (void)zf_playerPlayBtnState:(BOOL)state
{
    self.startBtn.selected = state;
}

//写在这个中间的代码,都不会被编译器提示-Wdeprecated-declarations类型的警告
#pragma clang diagnostic pop
@end
