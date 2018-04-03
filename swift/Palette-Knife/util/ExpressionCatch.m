//
//  ExpressionCatch.m
//  DynamicBrushes
//
//  Created by JENNIFER  JACOBS on 4/2/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

#import "ExpressionCatch.h"

@implementation ExpressionCatch

+ (void)tryBlock:(void (^)())try catchBlock:(void (^)(NSException *))catch finallyBlock:(void (^)())finally {
    @try {
        try ? try() : nil;
    }
    @catch (NSException *e) {
        catch ? catch(e) : nil;
    }
    @finally {
        finally ? finally() : nil;
    }
}

@end
