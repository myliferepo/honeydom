//
//  HDNodeBlockVisitor.m
//  HoneyDom
//
//  Created by Arseni Buinitsky on 5/22/13.
//  Copyright (c) 2013 Home. All rights reserved.
//

#import "HDNodeBlockVisitor.h"
#import "HDNode.h"


@implementation HDNodeBlockVisitor

+ (HDNodeBlockVisitor *)withEnterBlock:(HDNodeVisitorBlock)enterBlock {
    HDNodeBlockVisitor *visitor = [[HDNodeBlockVisitor alloc] init];
    visitor.enterBlock = enterBlock;
    return visitor;
}

+ (HDNodeBlockVisitor *)withEnterBlock:(HDNodeVisitorBlock)enterBlock leaveBlock:(HDNodeVisitorBlock)leaveBlock {
    HDNodeBlockVisitor *visitor = [[HDNodeBlockVisitor alloc] init];
    visitor.enterBlock = enterBlock;
    visitor.leaveBlock = leaveBlock;
    return visitor;
}


- (void)enteredNode:(HDNode *)node finish:(BOOL *)finish descend:(BOOL *)descend {
    BOOL doDescend = YES;

    if (self.enterBlock) {
        doDescend = self.enterBlock(node);
    }

    *descend = doDescend;
}

- (void)leftNode:(HDNode *)node finish:(BOOL *)finish {
    BOOL doFinish = NO;

    if (self.leaveBlock) {
        doFinish = self.leaveBlock(node);
    }

    *finish = doFinish;
}

@end
