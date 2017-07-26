//
//  ScannerOverlayView.m
//  EMCTest2
//
//  Created by Magnus on 2015-04-30.
//  Copyright (c) 2015 Ebuilder. All rights reserved.
//

#import "ScannerOverlayView.h"
#import <QuartzCore/QuartzCore.h>

@implementation ScannerOverlayView

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor*)color andTransparentRects:(NSArray*)rects
{
    backgroundColor = color;
    rectsArray = rects;
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = NO;
    }
    
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    [backgroundColor setFill];
    UIRectFill(rect);
    
    // clear the background in the given rectangles
    for (NSValue *holeRectValue in rectsArray) {
        CGRect holeRect = [holeRectValue CGRectValue];
        CGRect holeRectIntersection = CGRectIntersection( holeRect, rect );
        [[UIColor clearColor] setFill];
        UIRectFill(holeRectIntersection);
    }
    
}
 

-(void)addScannerLine {
    
    
    
    if (_scanOldBarcode)
    {
        float startScanner = (self.bounds.size.width/2.0) + 5.0;
        scannerLine = [[UIView alloc] initWithFrame:CGRectMake(startScanner, 15.0, 2.0,  self.bounds.size.height - 30.0)];
    } else {
        float startScanner = (self.bounds.size.height/2)*(1 - 0.7) + self.bounds.size.height/2 - 5.0;
        scannerLine = [[UIView alloc] initWithFrame:CGRectMake(15.0, startScanner, self.bounds.size.width - 30.0, 2.0)];
    }
   
    
    [scannerLine setBackgroundColor:[UIColor blueColor]];
    
    [self addSubview:scannerLine];
    
    
}

-(void)animateScannerLine {
    
    if (_scanOldBarcode) {
        float top = (self.bounds.size.width/2.0)*(1 + 0.5) - 5.0;
        
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:(UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat)
                         animations:^{
                             scannerLine.frame = CGRectMake(top, 15.0, 2.0, self.bounds.size.height - 30.0);
                             
                         }
                         completion:nil];
    } else {
        float top = (self.bounds.size.height/2)*(1 - 0.7) + 5.0;
        
        [UIView animateWithDuration:0.7
                              delay:0.0
                            options:(UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat)
                         animations:^{
                             scannerLine.frame = CGRectMake(15.0, top,self.bounds.size.width - 30.0, 2.0);
                             
                         }
                         completion:nil];
    }
    
}


@end
