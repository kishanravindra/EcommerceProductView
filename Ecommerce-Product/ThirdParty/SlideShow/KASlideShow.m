//
//  KASlideShow.m
//
// Copyright 2013 Alexis Creuzot
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "KASlideShow.h"

#define kSwipeTransitionDuration 0.25

typedef NS_ENUM(NSInteger, KASlideShowSlideMode) {
    KASlideShowSlideModeForward,
    KASlideShowSlideModeBackward
};

@interface KASlideShow()
@property (atomic) BOOL doStop;
@property (atomic) BOOL isAnimating;
@property (strong,nonatomic) UIImageView * topImageView;
@property (strong,nonatomic) UIImageView * bottomImageView;
@end

@implementation KASlideShow

@synthesize delegate;
@synthesize delay;
@synthesize transitionDuration;
@synthesize transitionType;
@synthesize images;

- (void)awakeFromNib
{
    [self setDefaultValues];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setDefaultValues];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
	
	// Do not reposition the embedded imageViews.
	frame.origin.x = 0;
	frame.origin.y = 0;
	
    _topImageView.frame = frame;
    _bottomImageView.frame = frame;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(self.bounds, _topImageView.bounds)) {
        _topImageView.frame = self.bounds;
    }
    
    if (!CGRectEqualToRect(self.bounds, _bottomImageView.bounds)) {
        _bottomImageView.frame = self.bounds;
    }
}


- (void) setDefaultValues
{
    self.clipsToBounds = YES;
    self.images = [NSMutableArray array];
    _currentIndex = 0;
    delay = 1;
    
    transitionDuration = 0.5;
    transitionType = KASlideShowTransitionFade;
    _doStop = YES;
    _isAnimating = NO;
    _topImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _bottomImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _topImageView.autoresizingMask = _bottomImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _topImageView.clipsToBounds = YES;
    _bottomImageView.clipsToBounds = YES;
    [self setImagesContentMode:UIViewContentModeScaleAspectFit];
    
    [self addSubview:_bottomImageView];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:@{@"view":_bottomImageView}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:@{@"view":_bottomImageView}]];
    
    [self addSubview:_topImageView];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:@{@"view":_topImageView}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:@{@"view":_topImageView}]];

    _topImageView.backgroundColor = [UIColor whiteColor];
}


- (void) setImagesContentMode:(UIViewContentMode)mode
{
    _topImageView.contentMode = mode;
    _bottomImageView.contentMode = mode;
}

- (UIViewContentMode) imagesContentMode
{
    return _topImageView.contentMode;
}

- (void) addGesture:(KASlideShowGestureType)gestureType
{
    switch (gestureType)
    {
        case KASlideShowGestureTap:
            [self addGestureTap];
            break;
        case KASlideShowGestureSwipe:
            [self addGestureSwipe];
            break;
        case KASlideShowGestureAll:
            [self addGestureTap];
            [self addGestureSwipe];
            break;
        default:
            break;
    }
}

- (void) removeGestures
{
    self.gestureRecognizers = nil;
}

//  Should be a set (array) of three images
//  ^^ confirmed
- (void) addImagesFromResources:(NSArray *) names
{
    for(NSString * name in names){
        _topImageView.backgroundColor = [UIColor colorWithRed:0.08 green:0.11 blue:0.21 alpha:1];
        [self addImage:[UIImage imageNamed:name]];
    }
    if (names.count < 1) {
        /*  
            This will be called when there are no
            images to show. Allows display of default view config. 
        */
        _topImageView.backgroundColor = [UIColor clearColor];
    }
}


- (void) setImagesDataSource:(NSMutableArray *)array {
    self.images = array;
    
    _topImageView.image = [array firstObject];
}


- (void) addImage:(UIImage*) image
{
    //  Check for 'image'
    [self.images addObject:image];
    
    if([self.images count] == 1){
        _topImageView.image = image;
    }
    else if([self.images count] == 2){
        _bottomImageView.image = image;
    }
}


- (void) emptyAndAddImagesFromResources:(NSArray *)names
{
    [self.images removeAllObjects];
    _currentIndex = 0;
    [self addImagesFromResources:names];
}

- (void) emptyAllImages {
    _topImageView.image = nil;
    _bottomImageView.image = nil;
    [self.images removeAllObjects];
}
    
- (void) emptyAndAddImages:(NSArray *)imagesArray
{
    [self.images removeAllObjects];
    _currentIndex = 0;
    for (UIImage *image in imagesArray){
        [self addImage:image];
    }
}

- (void) start
{
    _doStop = NO;
    [self next];
}

- (void) next
{
    if (!self.window) return;

    if(! _isAnimating && ([self.images count] >1 || self.dataSource)) {
        
        if ([self.delegate respondsToSelector:@selector(kaSlideShowWillShowNext:)]) [self.delegate kaSlideShowWillShowNext:self];
        
        // Next Image
        if (self.dataSource) {
            _topImageView.image = [self.dataSource slideShow:self imageForPosition:KASlideShowPositionTop];
            _bottomImageView.image = [self.dataSource slideShow:self imageForPosition:KASlideShowPositionBottom];
        } else {
            @try {
                NSLog(@"%lu",(unsigned long)_currentIndex);
                NSUInteger nextIndex = (_currentIndex+1)%[self.images count];
                NSLog(@"%lu",(unsigned long)nextIndex);

                _topImageView.image = self.images[_currentIndex];
                _bottomImageView.image = self.images[nextIndex];
                _currentIndex = nextIndex;
            }
            @catch (NSException *exception) {
                NSLog(@"Exception occurred adding image to slide show: %@", exception.name);
            }
        }
        
        // Animate
        switch (transitionType) {
            case KASlideShowTransitionFade:
                [self animateFade];
                break;
                
            case KASlideShowTransitionSlideHorizontal:
                
                [self animateSlideHorizontal:KASlideShowSlideModeForward];
                break;
                
            case KASlideShowTransitionSlideVertical:
                [self animateSlideVertical:KASlideShowSlideModeForward];
                break;
                
        }
        
        // Call delegate
        if([delegate respondsToSelector:@selector(kaSlideShowDidShowNext:)]){
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, transitionDuration * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if (self.window){
                    [delegate kaSlideShowDidShowNext:self];
                }
            });
        }
    }
}

-(void) moveToIndex:(NSInteger) selectedIndex{
    if (!self.window) return;
    
    if(! _isAnimating && ([self.images count] >1 || self.dataSource)) {
        
        if ([self.delegate respondsToSelector:@selector(kaSlideShowWillShowNext:)]) [self.delegate kaSlideShowWillShowNext:self];
        
        // Next Image
        if (self.dataSource) {
            _topImageView.image = [self.dataSource slideShow:self imageForPosition:KASlideShowPositionTop];
            _bottomImageView.image = [self.dataSource slideShow:self imageForPosition:KASlideShowPositionBottom];
        } else {
            @try {
                NSLog(@"%lu",(unsigned long)_currentIndex);
                _topImageView.image = self.images[_currentIndex];
                _bottomImageView.image = self.images[selectedIndex];
                _currentIndex = selectedIndex;
            }
            @catch (NSException *exception) {
                NSLog(@"Exception occurred adding image to slide show: %@", exception.name);
            }
        }
        
        // Animate
        switch (transitionType) {
            case KASlideShowTransitionFade:
                [self animateFade];
                break;
                
            case KASlideShowTransitionSlideHorizontal:
                
                [self animateSlideHorizontal:KASlideShowSlideModeForward];
                break;
                
            case KASlideShowTransitionSlideVertical:
                [self animateSlideVertical:KASlideShowSlideModeForward];
                break;
                
        }
        
        // Call delegate
        if([delegate respondsToSelector:@selector(kaSlideShowDidShowNext:)]){
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, transitionDuration * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if (self.window){
                    [delegate kaSlideShowDidShowNext:self];
                }
            });
        }
    }
}

- (void) previous
{
    if (!self.window) return;

    if(! _isAnimating && ([self.images count] >1 || self.dataSource)){
        
        if ([self.delegate respondsToSelector:@selector(kaSlideShowWillShowPrevious:)]) [self.delegate kaSlideShowWillShowPrevious:self];
        
        // Previous image
        if (self.dataSource) {
            _topImageView.image = [self.dataSource slideShow:self imageForPosition:KASlideShowPositionTop];
            _bottomImageView.image = [self.dataSource slideShow:self imageForPosition:KASlideShowPositionBottom];
        } else {
            NSUInteger prevIndex;
            if(_currentIndex == 0){
                prevIndex = [self.images count] - 1;
            }else{
                prevIndex = (_currentIndex-1)%[self.images count];
            }
            _topImageView.image = self.images[_currentIndex];
            _bottomImageView.image = self.images[prevIndex];
            _currentIndex = prevIndex;
        }
        
        // Animate
        switch (transitionType) {
            case KASlideShowTransitionFade:
                [self animateFade];
                break;
                
            case KASlideShowTransitionSlideHorizontal:
                [self animateSlideHorizontal:KASlideShowSlideModeBackward];
                break;
                
            case KASlideShowTransitionSlideVertical:
                [self animateSlideVertical:KASlideShowSlideModeBackward];
                break;
        }
        
        // Call delegate
        if([delegate respondsToSelector:@selector(kaSlideShowDidShowPrevious:)]){
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, transitionDuration * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if (self.window){
                    [delegate kaSlideShowDidShowPrevious:self];
                }
            });
        }
    }
    
}

- (UIImage*) imageForPosition:(KASlideShowPosition)position {
    return (position == KASlideShowPositionTop) ? _topImageView.image : _bottomImageView.image;
}

- (void) animateFade
{
    _isAnimating = YES;
    
    [UIView animateWithDuration:transitionDuration
                     animations:^{
                         _topImageView.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         
                         _topImageView.image = _bottomImageView.image;
                         _topImageView.alpha = 1;
                         
                         _isAnimating = NO;
                         
//                         if(! _doStop){
//                             [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(next) object:nil];
//                             [self performSelector:@selector(next) withObject:nil afterDelay:delay];
//                         }
                     }];
}

- (void) animateSlideHorizontal:(KASlideShowSlideMode) mode
{
    _isAnimating = YES;
    
    if(mode == KASlideShowSlideModeBackward){
        _bottomImageView.transform = CGAffineTransformMakeTranslation(- _bottomImageView.frame.size.width, 0);
    }else if(mode == KASlideShowSlideModeForward){
        _bottomImageView.transform = CGAffineTransformMakeTranslation(_bottomImageView.frame.size.width, 0);
    }
    
    
    
    [UIView animateWithDuration:2.0 delay:0.1 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        
        if(mode == KASlideShowSlideModeBackward){
            _topImageView.transform = CGAffineTransformMakeTranslation( _topImageView.frame.size.width, 0);
            _topImageView.backgroundColor = [UIColor clearColor];
            _bottomImageView.transform = CGAffineTransformMakeTranslation(0, 0);
        }else if(mode == KASlideShowSlideModeForward){
            _topImageView.transform = CGAffineTransformMakeTranslation(- _topImageView.frame.size.width, 0);
            _topImageView.backgroundColor = [UIColor clearColor];
            _bottomImageView.transform = CGAffineTransformMakeTranslation(0, 0);
        }
        
    } completion:^(BOOL finished) {
        _topImageView.image = _bottomImageView.image;
        _topImageView.transform = CGAffineTransformMakeTranslation(0, 0);
        
        _isAnimating = NO;
        [self.delegate slideAnimationCompleted];
        
//        if(! _doStop){
//            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(next) object:nil];
//            [self performSelector:@selector(next) withObject:nil afterDelay:delay];
//        }
    }];
    
//    [UIView animateWithDuration:transitionDuration
//                     animations:^{
//                         
//                         if(mode == KASlideShowSlideModeBackward){
//                             _topImageView.transform = CGAffineTransformMakeTranslation( _topImageView.frame.size.width, 0);
//                             _bottomImageView.transform = CGAffineTransformMakeTranslation(0, 0);
//                         }else if(mode == KASlideShowSlideModeForward){
//                             _topImageView.transform = CGAffineTransformMakeTranslation(- _topImageView.frame.size.width, 0);
//                             _bottomImageView.transform = CGAffineTransformMakeTranslation(0, 0);
//                         }
//                     }
//                     completion:^(BOOL finished){
//                         
//                         _topImageView.image = _bottomImageView.image;
//                         _topImageView.transform = CGAffineTransformMakeTranslation(0, 0);
//                         
//                         _isAnimating = NO;
//                         
//                         if(! _doStop){
//                             [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(next) object:nil];
//                             [self performSelector:@selector(next) withObject:nil afterDelay:delay];
//                         }
//                     }];
}

- (void) animateSlideVertical:(KASlideShowSlideMode) mode
{
    _isAnimating = YES;
    
    if(mode == KASlideShowSlideModeBackward){
        _bottomImageView.transform = CGAffineTransformMakeTranslation(0,- _bottomImageView.frame.size.height);
    }else if(mode == KASlideShowSlideModeForward){
        _bottomImageView.transform = CGAffineTransformMakeTranslation(0,_bottomImageView.frame.size.height);
    }
    
    
    [UIView animateWithDuration:transitionDuration
                     animations:^{
                         
                         if(mode == KASlideShowSlideModeBackward){
                             _topImageView.transform = CGAffineTransformMakeTranslation(0, _topImageView.frame.size.height);
                             _bottomImageView.transform = CGAffineTransformMakeTranslation(0, 0);
                         }else if(mode == KASlideShowSlideModeForward){
                             _topImageView.transform = CGAffineTransformMakeTranslation(0, - _topImageView.frame.size.height);
                             _bottomImageView.transform = CGAffineTransformMakeTranslation(0, 0);
                         }
                     }
                     completion:^(BOOL finished){
                         
                         _topImageView.image = _bottomImageView.image;
                         _topImageView.transform = CGAffineTransformMakeTranslation(0, 0);
                         
                         _isAnimating = NO;
                         
                         if(! _doStop){
                             [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(next) object:nil];
                             [self performSelector:@selector(next) withObject:nil afterDelay:delay];
                         }
                     }];
}

- (void) stop
{
    _doStop = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(next) object:nil];
}

- (KASlideShowState)state
{
    return !_doStop;
}

#pragma mark - Gesture Recognizers initializers
- (void) addGestureTap
{
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    [self addGestureRecognizer:singleTapGestureRecognizer];
}

- (void) addGestureSwipe
{
    if(self.transitionType == KASlideShowTransitionSlideHorizontal){
        UISwipeGestureRecognizer* swipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        swipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        UISwipeGestureRecognizer* swipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        swipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        
        [self addGestureRecognizer:swipeLeftGestureRecognizer];
        [self addGestureRecognizer:swipeRightGestureRecognizer];
    }else{
        UISwipeGestureRecognizer* swipeUpGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        swipeUpGestureRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
        UISwipeGestureRecognizer* swipeDownGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        swipeDownGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
        
        [self addGestureRecognizer:swipeUpGestureRecognizer];
        [self addGestureRecognizer:swipeDownGestureRecognizer];
    }
    
}

#pragma mark - Gesture Recognizers handling
- (void)handleSingleTap:(id)sender
{
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
    CGPoint pointTouched = [gesture locationInView:self.topImageView];
    
    if (pointTouched.x <= self.topImageView.center.x){
        [self previous];
    }else {
        [self next];
    }
}

- (void) handleSwipe:(id)sender
{
    UISwipeGestureRecognizer *gesture = (UISwipeGestureRecognizer *)sender;
    
    float oldTransitionDuration = self.transitionDuration;
    
    self.transitionDuration = kSwipeTransitionDuration;
    if (gesture.direction == UISwipeGestureRecognizerDirectionLeft ||
        gesture.direction == UISwipeGestureRecognizerDirectionUp)
    {
        [self next];
        if ([self.delegate respondsToSelector:@selector(kaSlideShowDidSwipeLeft:)]) {
            [self.delegate kaSlideShowDidSwipeLeft:self];
        }
    }
    else if (gesture.direction == UISwipeGestureRecognizerDirectionRight ||
             gesture.direction == UISwipeGestureRecognizerDirectionDown)
    {
        [self previous];
        if ([self.delegate respondsToSelector:@selector(kaSlideShowDidSwipeRight:)]) {
            [self.delegate kaSlideShowDidSwipeRight:self];
        }
    }
    
    self.transitionDuration = oldTransitionDuration;
}

@end

