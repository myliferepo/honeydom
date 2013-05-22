//
//  HoneyDomTests.m
//  HoneyDomTests
//
//  Created by Arseni Buinitsky on 5/22/13.
//  Copyright (c) 2013 Home. All rights reserved.
//

#import "HoneyDomTests.h"
#import "HDNode.h"
#import "HDNodeBlockVisitor.h"


@implementation HoneyDomTests

- (id<HDNodeVisitor>)printVisitorPretty:(BOOL)pretty {
    __block NSInteger level = 0;

    return [HDNodeBlockVisitor withEnterBlock:^ BOOL (HDNode *node) {
        NSString *pad = @"";
        for (NSUInteger i = 0; i < level; ++i) {
            pad = [pad stringByAppendingString:@"\t"];
        }

        ++level;
        
        NSString *desc;
        
        if (!pretty) {
            desc = [NSString stringWithFormat:@"<%@:\"%@\">", node.tagName, node.characters];
        } else if (node.isTextNode) {
            desc = [NSString stringWithFormat:@"%@\"%@\"", pad, node.characters];
        } else {
            desc = [NSString stringWithFormat:@"%@%@", pad, node.tagName];
        }

        NSLog(@"%10p | %@", node, desc);

        return YES;

    } leaveBlock:^ BOOL (HDNode *node) {
        --level;
        return NO;
    }];
}

// TODO: create tests

- (void)testBasicParsing {

}

@end