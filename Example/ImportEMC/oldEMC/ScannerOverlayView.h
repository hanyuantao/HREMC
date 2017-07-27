//
//  ScannerOverlayView.h
//  EMCTest2
//
//  Created by Magnus on 2015-04-30.
//  Copyright (c) 2015 Ebuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScannerOverlayView : UIView {
    NSArray *rectsArray;
    UIColor *backgroundColor;
    UIView *scannerLine;
}

@property (nonatomic) CGRect *cutOut;
@property (nonatomic) BOOL scanOldBarcode;

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor*)color andTransparentRects:(NSArray*)rects;

-(void)addScannerLine;
-(void)animateScannerLine;

@end
