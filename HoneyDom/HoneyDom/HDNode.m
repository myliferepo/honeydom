//
//  HDNode.m
//  honeydom
//
//  Created by Arseni Buinitsky on 12/17/11.
//  Copyright (c) 2011 HOME. All rights reserved.
//

#import "HDNode.h"

#import <libxml/HTMLparser.h>
#import <libxml/xpath.h>
#import <libxml/xpointer.h>
#import <libxml/tree.h>


#pragma mark Constant definitions

static BOOL xmlXPathIsInit = NO;


#ifndef kHDNodeHtmlOptions
#define kHDNodeHtmlOptions HTML_PARSE_RECOVER | HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING
#endif

#ifndef kHDNodeXmlOptions
#define kHDNodeXmlOptions 0
#endif


#pragma mark Node block visitor for query:visitWithBlock:


@interface _NodeVisitor : NSObject<HDNodeVisitor> {
@private
    HDVisitBlock block;
}

- (_NodeVisitor *)initWithBlock:(HDVisitBlock)_block;

- (void)enteredNode:(HDNode *)node finish:(BOOL *)finish descend:(BOOL *)descend;

@end


@implementation _NodeVisitor

- (_NodeVisitor *)initWithBlock:(HDVisitBlock)_block {
    self = [self init];
    if (self) {
        block = _block;
    }
    return self;
}

- (void)enteredNode:(HDNode *)node finish:(BOOL *)finish descend:(BOOL *)descend {
    block(node, finish, descend);
}

@end


#pragma mark HDNode implementation


@interface HDNode()

// transfers ownership of xmlNodePtr to this object
- (HDNode *)initWithOwner:(HDNode *)ownerNode xmlNodePtr:(xmlNodePtr)ptr;

- (void)acceptVisitor:(id<HDNodeVisitor>)visitor finish:(BOOL *)finish;

- (NSString *)constXmlString:(const xmlChar *)xmlString;
- (NSString *)useXmlString:(xmlChar *)xmlString;

- (xmlXPathContextPtr)createContext;
- (xmlXPathObjectPtr)executeQuery:(NSString *)query context:(xmlXPathContextPtr)context;

- (NSString *)description;

@property (nonatomic, strong) HDNode *ownerNode;
@property (nonatomic, assign) xmlDocPtr document;
@property (nonatomic, assign) xmlNodePtr nodePointer;

@end


@implementation HDNode
#pragma mark Util

- (NSString *)constXmlString:(const xmlChar *)xmlString {
    if (xmlString) {
        return @((const char*)xmlString);
    } else {
        return nil;
    }
}

- (NSString *)useXmlString:(xmlChar *)xmlString {
    if (xmlString) {
        NSString *s = @((char*)xmlString);
        xmlFree(xmlString);
        return s;
    } else {
        return nil;
    }
}

- (xmlXPathContextPtr)createContext {
    @synchronized([self class]) {
        if (!xmlXPathIsInit) {
            xmlXPathInit();
            xmlXPathIsInit = YES;
        }
    }
    xmlXPathContextPtr context = xmlXPtrNewContext(self.document, self.nodePointer, NULL);
    if (context == NULL) {
        HDLog(@"failed to initialize XPtr XPath context");
    }
    return context;
}

- (xmlXPathObjectPtr)executeQuery:(NSString *)query context:(xmlXPathContextPtr)context {
    xmlXPathObjectPtr object 
        = xmlXPathEvalExpression((xmlChar *)[query cStringUsingEncoding:NSUTF8StringEncoding], context);
    if (object == NULL) {
        HDLog(@"HoneyDom: error evaluating expression {%@}", query);
    }
    return object;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[%@:%d:%d]", self.tagName, [self.attributes count], [self.children count]];
}

#pragma mark Custom properties

- (xmlNodePtr)nodePointer {
    if (_nodePointer == NULL) {
        _nodePointer = xmlDocGetRootElement(self.document);
    }
    return _nodePointer;
}

#pragma mark Initialization and lifecycle

+ (HDNode *)nodeWithData:(NSData *)data encoding:(NSStringEncoding)encoding xml:(BOOL)xml {
    return [[HDNode alloc] initWithData:data encoding:encoding xml:xml];
}

+ (HDNode *)nodeWithString:(NSString *)string xml:(BOOL)isXml {
    return [[HDNode alloc] initWithString:string xml:isXml];
}

- (HDNode *)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding xml:(BOOL)xml {
    self = [super init];
    if (self) {
        char cEncoding[32];
        CFStringRef cfEncoding = 
            CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encoding));
        CFStringGetCString(cfEncoding, cEncoding,  32, kCFStringEncodingASCII);
        
        if (xml) {
            self.document = xmlReadMemory([data bytes], (int)[data length], "", cEncoding, kHDNodeXmlOptions);
        } else {
            self.document = htmlReadMemory([data bytes], (int)[data length], "", cEncoding, kHDNodeHtmlOptions);
        }
        
        if (self.document == NULL) {
            HDLog(@"HoneyDom: error parsing document");
            self = nil;
        }
    }
    return self;
}

- (HDNode *)initWithString:(NSString *)string xml:(BOOL)xml {
    return [self initWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
                     encoding:NSUTF8StringEncoding
                          xml:xml];
}

- (HDNode *)initWithOwner:(HDNode *)owner xmlNodePtr:(xmlNodePtr)ptr {
    self = [super init];
    if (self) {
        self.nodePointer = ptr;
        self.ownerNode = owner;
        self.document = owner.document;
    }
    return self;
}

- (void)dealloc {
    if (self.ownerNode == nil && self.document != NULL) {
        xmlFreeDoc(self.document);
    }
}

#pragma mark Properties extraction

- (NSString *)tagName {
    if (!self.nodePointer) return nil;

    if (self.nodePointer->name == NULL || strcmp("text", (char const *)self.nodePointer->name) == 0) {
        return nil;
    } else {
        return [self constXmlString:self.nodePointer->name];
    }
}

- (NSDictionary *)attributes {
    if (!self.nodePointer) return nil;

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:16];
    
    xmlAttrPtr attr = self.nodePointer->properties;
    while (attr != NULL) {
        NSString *name = [self constXmlString:attr->name];
        NSString *value = [self useXmlString:xmlNodeListGetString(self.document, attr->children, 1)];
        [dictionary setValue:value forKey:name];
        attr = attr->next;
    }
    
    return dictionary;
}

- (BOOL)isTextNode {
    return self.tagName == nil;
}

- (NSArray *)children {
    if (!self.nodePointer) return nil;

    NSMutableArray *array = [NSMutableArray arrayWithCapacity:32];
    
    xmlNodePtr childNode = self.nodePointer->children;
    while (childNode != NULL) {
        [array addObject:[[HDNode alloc] initWithOwner:self xmlNodePtr:childNode]];
        childNode = childNode->next;
    }
    
    return array;
}

- (NSString *)characters {
    if (!self.nodePointer) return nil;

    return [self constXmlString:self.nodePointer->content];
}

- (NSString *)allCharacters {
    return [self useXmlString:xmlNodeGetContent(self.nodePointer)];
}

#pragma mark Querying and visiting

- (HDNode *)queryFirst:(NSString *)xPathQuery {
    xmlXPathContextPtr context = [self createContext];
    xmlXPathObjectPtr object = [self executeQuery:xPathQuery context:context];
    HDNode *resultNode = nil;
    
    if (object) {   
        xmlNodeSetPtr resultNodeset = object->nodesetval;
        resultNode = 
            resultNodeset->nodeNr == 0
            ? nil
            : [[HDNode alloc] initWithOwner:self xmlNodePtr:resultNodeset->nodeTab[0]];
    
        xmlXPathFreeObject(object);
        xmlXPathFreeContext(context);
    }
    
    return resultNode;
}

- (NSArray *)query:(NSString *)xPathQuery {
    xmlXPathContextPtr context = [self createContext];
    xmlXPathObjectPtr object = [self executeQuery:xPathQuery context:context];
    NSMutableArray *array = nil;
    
    if (object) {    
        xmlNodeSetPtr resultNodeset = object->nodesetval;
        array = [NSMutableArray arrayWithCapacity:resultNodeset->nodeNr];
        for (int i = 0; i < resultNodeset->nodeNr; ++i) {
            [array addObject:[[HDNode alloc] initWithOwner:self xmlNodePtr:resultNodeset->nodeTab[i]]];
        }
    
        xmlXPathFreeObject(object);
        xmlXPathFreeContext(context);
    }
    
    return array;
}

- (void)acceptVisitor:(id<HDNodeVisitor>)visitor {
    BOOL finish = NO;
    
    if ([visitor respondsToSelector:@selector(startedVisiting:finish:)]) {
        [visitor startedVisiting:self finish:&finish];
    }
    
    if (!finish) {
        [self acceptVisitor:visitor finish:&finish];
    }
    
    if ([visitor respondsToSelector:@selector(finishedVisiting:)]) {
        [visitor finishedVisiting:self];
    }
}

- (void)acceptVisitor:(id<HDNodeVisitor>)visitor finish:(BOOL *)finish {
    BOOL descend = YES;
    
    if ([visitor respondsToSelector:@selector(enteredNode:finish:descend:)]) {
        [visitor enteredNode:self finish:finish descend:&descend];
    }
    
    if (descend && !(*finish)) {
        for (HDNode *node in [self children]) {
            [node acceptVisitor:visitor finish:finish];
            if (*finish) {
                return;
            }
        }
    }
    
    if ([visitor respondsToSelector:@selector(leftNode:finish:)]) {
        [visitor leftNode:self finish:finish];         
    }
}

- (void)query:(NSString *)xPathQuery iterateWithBlock:(HDIterateBlock)block {
    for (HDNode *node in [self query:xPathQuery]) {
        block(node);
    }
}

- (void)query:(NSString *)xPathQuery visitWithBlock:(HDVisitBlock)block {
    _NodeVisitor *visitor = [[_NodeVisitor alloc] initWithBlock:block];
    for (HDNode *node in [self query:xPathQuery]) {
        [node acceptVisitor:visitor];
    }
}

- (void)query:(NSString *)xPathQuery aggregate:(HDAggregateBlock)block init:(id)aggregator {
    for (HDNode *node in [self query:xPathQuery]) {
        block(node, aggregator);
    }
}

- (NSArray *)query:(NSString *)xPathQuery map:(HDMapBlock)block {
    NSArray *nodes = [self query:xPathQuery];
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[nodes count]];
    for (HDNode *node in nodes) {
        id blockResult = block(node);
        if (blockResult == nil) {
            blockResult = [NSNull null];
        }
        [result addObject:blockResult];
    }
    
    return result;
}


@end
