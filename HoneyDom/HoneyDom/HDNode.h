//
//  HDNode.h
//  honeydom
//
//  Created by Arseni Buinitsky on 12/17/11.
//  Copyright (c) 2011 HOME. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HDNodeVisitor.h"


typedef void (^HDIterateBlock)(HDNode *node);
typedef void (^HDVisitBlock)(HDNode *node, BOOL *finish, BOOL *descend);

typedef void (^HDAggregateBlock)(HDNode *node, id aggregator);

typedef id (^HDMapBlock)(HDNode *node);


@interface HDNode : NSObject 

@property (nonatomic, readonly) NSString *tagName;
@property (nonatomic, readonly) NSDictionary *attributes;

@property (nonatomic, readonly) BOOL isTextNode;

@property (nonatomic, readonly) NSArray *children;
@property (nonatomic, readonly) NSString *characters;
@property (nonatomic, readonly) NSString *allCharacters;

+ (HDNode *)nodeWithData:(NSData *)data encoding:(NSStringEncoding)encoding xml:(BOOL)xml;
+ (HDNode *)nodeWithString:(NSString *)string xml:(BOOL)isXml;

- (HDNode *)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding xml:(BOOL)xml;
- (HDNode *)initWithString:(NSString *)string xml:(BOOL)xml;

- (void)acceptVisitor:(id<HDNodeVisitor>)visitor;

- (HDNode *)queryFirst:(NSString *)xPathQuery;
- (NSArray *)query:(NSString *)xPathQuery;

- (void)query:(NSString *)xPathQuery iterateWithBlock:(HDIterateBlock)block;
- (void)query:(NSString *)xPathQuery visitWithBlock:(HDVisitBlock)block;
- (void)query:(NSString *)xPathQuery aggregate:(HDAggregateBlock)block init:(id)aggregator;
- (NSArray *)query:(NSString *)xPathQuery map:(HDMapBlock)block;

@end
