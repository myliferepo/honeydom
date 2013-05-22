//
//  HDNodeBlockVisitor.h
//  HoneyDom
//
//  Created by Arseni Buinitsky on 5/22/13.
//  Copyright (c) 2013 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HDNodeVisitor.h"


typedef BOOL (^HDNodeVisitorBlock)(HDNode *node);


@interface HDNodeBlockVisitor : NSObject<HDNodeVisitor>

+ (HDNodeBlockVisitor *)withEnterBlock:(HDNodeVisitorBlock)enterBlock;

+ (HDNodeBlockVisitor *)withEnterBlock:(HDNodeVisitorBlock)enterBlock leaveBlock:(HDNodeVisitorBlock)leaveBlock;

@property (copy) HDNodeVisitorBlock enterBlock;
@property (copy) HDNodeVisitorBlock leaveBlock;

@end
