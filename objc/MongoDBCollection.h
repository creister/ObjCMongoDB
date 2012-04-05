//
//  MongoDBCollection.h
//  ObjCMongoDB
//
//  Created by Paul Melnikow on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MongoPredicate.h"
#import "MongoCursor.h"
#import "MongoFetchRequest.h"
#import "MongoUpdateRequest.h"

@class MongoConnection;

@interface MongoDBCollection : NSObject {
    const char * _utf8Name;
    const char * _utf8DatabaseName;
    const char * _utf8NamespaceName;
}

- (BOOL) insert:(BSONDocument *) document error:(NSError **) error;
- (BOOL) insertDictionary:(NSDictionary *) dictionary error:(NSError **) error;
- (BOOL) insertObject:(id) object error:(NSError **) error;
- (BOOL) insertBatch:(NSArray *) documentArray error:(NSError **) error;

- (BOOL) update:(MongoUpdateRequest *) updateRequest error:(NSError **) error;

- (NSArray *) find:(MongoFetchRequest *) fetchRequest error:(NSError **) error;
- (NSArray *) findWithPredicate:(MongoPredicate *) predicate error:(NSError **) error;
- (NSArray *) findAllWithError:(NSError **) error;

- (MongoCursor *) cursorForFind:(MongoFetchRequest *) fetchRequest error:(NSError **) error;
- (MongoCursor *) cursorForFindWithPredicate:(MongoPredicate *) predicate error:(NSError **) error;
- (MongoCursor *) cursorForFindAllWithError:(NSError **) error;

- (BSONDocument *) findOne:(MongoFetchRequest *) fetchRequest error:(NSError **) error;
- (BSONDocument *) findOneWithPredicate:(MongoPredicate *) predicate error:(NSError **) error;
- (BSONDocument *) findOneWithError:(NSError **) error;

- (NSUInteger) countWithPredicate:(MongoPredicate *) predicate error:(NSError **) error;

- (BOOL) remove:(MongoPredicate *) predicate error:(NSError **) error;
- (BOOL) removeAllWithError:(NSError **) error;

- (BOOL) serverStatusForLastOperation:(NSError **) error;
- (NSError *) error;
- (NSError *) serverError;

@property (retain) MongoConnection * connection;
@property (copy, nonatomic) NSString * name;

@end
