//
//  ZFPlayerCell.m
//
// Copyright (c) 2016年 任子丰 ( http://github.com/renzifeng )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ZFPlayerCell.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImageView+WebCache.h"
#import <Masonry/Masonry.h>

@interface ZFPlayerCell ()

@end

@implementation ZFPlayerCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self layoutIfNeeded];
    [self cutRoundView:self.avatarImageView];
    
    // 设置imageView的tag，在PlayerView中取（建议设置100以上）
    self.picView.tag = 101;
    
    // 代码添加playerBtn到imageView上
    self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playBtn setImage:[UIImage imageNamed:@"video_list_cell_big_icon"] forState:UIControlStateNormal];
    [self.playBtn addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
    [self.picView addSubview:self.playBtn];
    [self.playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.picView);
        make.width.height.mas_equalTo(50);
    }];
}

// 切圆角
- (void)cutRoundView:(UIImageView *)imageView
{
    CGFloat corner = imageView.frame.size.width / 2;
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:imageView.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(corner, corner)];
    shapeLayer.path = path.CGPath;
    imageView.layer.mask = shapeLayer;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setModel:(ZFVideoModel *)model
{
    [self.picView sd_setImageWithURL:[NSURL URLWithString:model.coverForFeed] placeholderImage:[UIImage imageNamed:@"loading_bgView"]];
    self.titleLabel.text = model.title;
}

- (void)play:(UIButton *)sender {
    if (self.playBlock) {
        self.playBlock(sender);
    }
}

- (void)cellClicked
{
    [[ZFPlayerSimpleView sharedPlayerView] pause];
    // 当前正在播放 跳转进入 全屏页面
    CGRect originFrame = [self convertRect:self.frame toView:nil];
    ZFPlayerSimpleView *playerView = [ZFPlayerSimpleView sharedPlayerView];
    playerView.loop = NO;
    [[UIApplication sharedApplication].keyWindow addSubview:playerView];
    [playerView setFrame:originFrame];
    [UIView animateWithDuration:1.5 animations:^{
        [playerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@(ScreenWidth));
            make.height.equalTo(@(ScreenHeight));
            make.center.equalTo([UIApplication sharedApplication].keyWindow);
        }];
    } completion:^(BOOL finished) {
        [playerView enableControlView:YES];
        [playerView play];
    }];
    
    [playerView setCloseHandler:^{
        [UIView animateWithDuration:1.5 animations:^{
            [[ZFPlayerSimpleView sharedPlayerView] setFrame:originFrame];
        } completion:^(BOOL finished) {
            ZFPlayerSimpleView *playerView = [ZFPlayerSimpleView sharedPlayerView];
            playerView.loop = YES;
            [self.picView addSubview:playerView];
            [playerView setFrame:({
                CGRect frame = playerView.frame;
                frame.origin = CGPointZero;
                frame;
            })];
            [playerView enableControlView:NO];
            [playerView play];
        }];
    }];
}

@end
