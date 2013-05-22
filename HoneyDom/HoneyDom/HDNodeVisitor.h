//
//  HDNodeVisitorDelegate.h
//  honeydom
//
//  Created by Arseni Buinitsky on 12/17/11.
//  Copyright (c) 2011 HOME. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HDNode;

@protocol HDNodeVisitor <NSObject>
@optional

- (void)startedVisiting:(HDNode *)rootNode finish:(BOOL *)finish;

- (void)enteredNode:(HDNode *)node finish:(BOOL *)finish descend:(BOOL *)descend;

- (void)leftNode:(HDNode *)node finish:(BOOL *)finish;

- (void)finishedVisiting:(HDNode *)rootNode;

@end
