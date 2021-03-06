//
//  NVTableRowView.m
//  Anvil
//
//  Created by Elliott Kember on 16/09/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "NVTableRowView.h"
#import "NSImage+Additions.h"

@interface NVTableRowView ()

@property (assign) BOOL highlighted;
@property (assign) BOOL mouseIsDown;
@property (strong, nonatomic) NSEvent *clickEvent;

@end


@implementation NVTableRowView
//
//- (NSGradient *)backgroundGradient {
//    
//    NSColor *highlightBackgroundColor = [NSColor colorWithDeviceRed:244.0/255.0 green:244.0/255.0 blue:244.0/255.0 alpha:1];
//    
//    NSColor *middleColor = nil;
//    NSGradient *gradient;
//    
//    if (!self.mouseIsDown) {
//        middleColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.7];
//        gradient = [[NSGradient alloc] initWithColorsAndLocations:highlightBackgroundColor, 0.0, middleColor, 0.5, highlightBackgroundColor, 1.0, nil];
//    } else {
//        middleColor = [NSColor colorWithCalibratedWhite:0.9 alpha:0.8];
//        gradient = [[NSGradient alloc] initWithColorsAndLocations:highlightBackgroundColor, 0.0, middleColor, 0.3, middleColor, 0.7, highlightBackgroundColor, 1.0, nil];
//    }
//    
//    return gradient;
//}

- (void)highlight {
    
    self.highlighted = YES;
    self.needsDisplay = YES;
    self.mouseIsDown = NO;
}

- (void)unhighlight {

    self.highlighted = NO;
    self.needsDisplay = YES;
    self.mouseIsDown = NO;
}

- (void)setBackgroundColor:(NSColor *)backgroundColor {
    
    return;
}

//- (void)mouseDown:(NSEvent *)theEvent {
//    
//    self.clickEvent = theEvent;
//    self.mouseIsDown = YES;
//    self.needsDisplay = YES;
//    [super mouseDown:theEvent];
//    self.mouseIsDown = NO;
//}
//
//- (void)mouseUp:(NSEvent *)theEvent {
//
//    self.mouseIsDown = NO;
//    self.needsDisplay = YES;
//    
//    if (theEvent == self.clickEvent) {
//        
//        [super mouseUp:theEvent];
//    }
//}

//- (void)setSelected:(BOOL)selected {
//    
//    [super setSelected:selected];
//    self.needsDisplay = YES;
//}
//
//- (void)drawRect:(NSRect)dirtyRect {
////    
////    self.backgroundColor = nil;
//    [super drawRect:dirtyRect];
////
//    if (self.selected) {
//        
//        [[NSColor colorWithDeviceRed:253.0/255.0 green:253.0/255.0 blue:253.0/255.0 alpha:1.0] set];
//        NSRectFill(self.bounds);"
//    }
////
////    // Top and bottom borders for rows
//    NSTableView *tableView = (NSTableView*)[self superview]; // The table view the row is part of
////
//    if (![[self superview] isKindOfClass: [NSTableView class]]) {
//        return;
//    }
////
////    if (self.mouseIsDown) {
////        
//////            [titleBarImage drawInRect:dirtyRect withLeftCapWidth:1.0 topCapHeight:1.0];
//////        [[NSImage imageNamed:@"RowBackgroundPushed.png"] drawInRect:dirtyRect withLeftCapWidth:1.0 topCapHeight:1.0];
////        [[NSColor colorWithDeviceRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0] set];
////        NSRectFill(self.bounds);
////        
////        NSShadow *topShadow = [[NSShadow alloc] init];
////        [topShadow ]
////        return;
////    }
//    
////    NSInteger ownRowNumber = [tableView rowForView:self];
////    NSInteger numberOfRows = [tableView numberOfRows];
////    
////    if (ownRowNumber < numberOfRows-1 && !self.hideBottomBorder) {
////        
////        NSRect bottomDrawingRect = [self frame];
////        bottomDrawingRect.origin.y = bottomDrawingRect.size.height - 1.0;
////        bottomDrawingRect.size.height = 1.0;
////        [[NSColor colorWithDeviceRed:219.0/255.0 green:219.0/255.0 blue:219.0/255.0 alpha:0.5] set];
////        NSRectFill(bottomDrawingRect);
////    }
////    
////    if (ownRowNumber > 0 && !self.hideTopBorder && !self.isSelected) {
////        
////        NSRect topDrawingRect = [self frame];
////        topDrawingRect.origin.y = 0;
////        topDrawingRect.size.height = 1;
////        
////        if (self.darkTopBorder) {
////        [[NSColor colorWithDeviceRed:219.0/255.0 green:219.0/255.0 blue:219.0/255.0 alpha:0.5] set];
////        } else {
////            [[NSColor colorWithDeviceRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.4] set];
////        }
////        NSRectFill (topDrawingRect);
////    }
////        if (self.darkTopBorder) {
////        [[NSColor colorWithDeviceRed:219.0/255.0 green:219.0/255.0 blue:219.0/255.0 alpha:0.5] set];
////        } else {
////            [[NSColor colorWithDeviceRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.4] set];
////        }
//
//}

@end
