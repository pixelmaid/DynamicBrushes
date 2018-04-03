//
//  ExpressionCatch.h
//  DynamicBrushes
//
//  Created by JENNIFER  JACOBS on 4/2/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ExpressionCatch : NSObject

+ (void)tryBlock:(void (^)())try catchBlock:(void (^)(NSException *))catch finallyBlock:(void (^)())finally;

@end
