//
//  NSManagedObject+BSONCoding.m
//  ObjCMongoDB
//
//  Copyright 2012 Paul Melnikow and other contributors
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "NSManagedObject+BSONCoding.h"

NSString * const BSONCodingEntityVersionHashKey = @"@$versionHash";

@implementation NSManagedObject (BSONCoding)

#pragma mark - Encoding and decoding behavior method

- (BOOL) shouldAutomaticallyHandlePropertyName:(NSString *) propertyName { return YES; }

#pragma mark - Encoding methods

- (void) encodeWithBSONEncoder:(BSONEncoder *) encoder {
    if (BSONDoNothingOnNil != encoder.behaviorOnNil) {
        id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                         reason:@"Encoder's behaviorOnNil must be BSONDoNothingOnNil to encode NSManagedObject instances"
                                       userInfo:nil];
        @throw exc;
    }
    if (![self validateForUpdate:nil]) {
        NSString *reason = [NSString stringWithFormat:@"While trying to encode an object for entity %@, validateForUpdate: failed",
                            [[self entity] name]];
        id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                         reason:reason
                                       userInfo:nil];
        @throw exc;
    }
    for (NSPropertyDescription *property in [self entity]) {
        if ([property isTransient])
            continue;
        else if ([property isKindOfClass:[NSAttributeDescription class]])
            [self encodeAttribute:(NSAttributeDescription *)property withEncoder:encoder];
        else if ([property isKindOfClass:[NSRelationshipDescription class]])
            [self encodeRelationship:(NSRelationshipDescription *)property withEncoder:encoder];
        else if ([property isKindOfClass:[NSFetchedPropertyDescription class]])
            [self encodeFetchedProperty:(NSFetchedPropertyDescription *)property withEncoder:encoder];
    }
    if (encoder.managedObjectsShouldEncodeEntityVersionHash)
        [encoder encodeData:[[self entity] versionHash] forKey:BSONCodingEntityVersionHashKey];
}

- (void) encodeAttribute:(NSAttributeDescription *) attribute withEncoder:(BSONEncoder *) encoder {
    NSString *key = [attribute name];
    id value = [self valueForKey:key];
    if (!value) {
        // Let the encoder handle nil values directly
        [encoder encodeObject:nil forKey:key];
        return;
    }
    switch ([attribute attributeType]) {
        case NSUndefinedAttributeType:
            [NSException raise:NSInvalidArchiveOperationException format:@"Can't encode undefined type for attribute %@", key];
        case NSInteger16AttributeType:
            [encoder encodeInt:[(NSNumber *)value intValue] forKey:key]; break;
        case NSInteger32AttributeType:
        case NSInteger64AttributeType:
            [encoder encodeInt64:[(NSNumber *)value longLongValue] forKey:key]; break;
        case NSDecimalAttributeType:
        case NSDoubleAttributeType:
        case NSFloatAttributeType:
            [encoder encodeDouble:[(NSNumber *)value doubleValue] forKey:key]; break;
        case NSStringAttributeType:
            [encoder encodeString:value forKey:key]; break;
        case NSBooleanAttributeType:
            [encoder encodeBool:[(NSNumber *)value boolValue] forKey:key]; break;
        case NSDateAttributeType:
            [encoder encodeDate:value forKey:key]; break;
        case NSBinaryDataAttributeType:
        case NSTransformableAttributeType:
            [encoder encodeData:value forKey:key]; break;
        case NSObjectIDAttributeType:
            [NSException raise:NSInvalidArchiveOperationException format:@"Can't encode Core Data object ID type for attribute %@", key];                    
    }
}

- (void) encodeRelationship:(NSRelationshipDescription *) relationship withEncoder:(BSONEncoder *) encoder {
    NSString *key = [relationship name];
    id value = [self valueForKey:key];
    if ([relationship isToMany])
        [encoder encodeArray:[value allObjects] forKey:key];
    else
        [encoder encodeObject:value forKey:key];
}

- (void) encodeFetchedProperty:(NSFetchedPropertyDescription *) fetchedProperty withEncoder:(BSONEncoder *) encoder {
    [NSException raise:NSInvalidArchiveOperationException
                format:@"Implement -encodeFetchedProperty:withEncoder: in your subclass to encode fetched properties"];
}

#pragma mark - Decoding methods

- (id) initWithBSONDecoder:(BSONDecoder *) decoder {
    NSManagedObjectContext *moc = decoder.managedObjectContext;
    if (!moc) {
        id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                         reason:@"Decoder's managed object context is nil"
                                       userInfo:nil];
        @throw exc;
    }
    NSEntityDescription *edesc = [NSEntityDescription entityForName:[[self class] description]
                                             inManagedObjectContext:moc];    
    if (self = [self initWithEntity:edesc insertIntoManagedObjectContext:moc]) {
        for (NSPropertyDescription *property in [self entity]) {
            if ([property isTransient] || ![self shouldAutomaticallyHandlePropertyName:property.name])
                continue;
            else if ([property isKindOfClass:[NSAttributeDescription class]])
                [self initializeAttribute:(NSAttributeDescription *)property withDecoder:decoder];
            else if ([property isKindOfClass:[NSRelationshipDescription class]])
                [self initializeRelationship:(NSRelationshipDescription *)property withDecoder:decoder];
            else if ([property isKindOfClass:[NSFetchedPropertyDescription class]])
                [self initializeFetchedProperty:(NSFetchedPropertyDescription *)property withDecoder:decoder];
        }
    }
    return self;
}

- (void) initializeAttribute:(NSAttributeDescription *) attribute withDecoder:(BSONDecoder *) decoder {
    NSString *key = [attribute name];
    if ([decoder containsValueForKey:key]) {
        id value = [decoder decodeObjectForKey:key];
        [self setValue:value forKey:key];
    }
}

- (void) initializeRelationship:(NSRelationshipDescription *) relationship withDecoder:(BSONDecoder *) decoder {
    NSString *key = [relationship name];
    NSEntityDescription *destinationEntity = [relationship destinationEntity];
    Class destinationClass = NSClassFromString([destinationEntity managedObjectClassName]);

    if ([decoder valueIsArrayForKey:key]) {
        if (![relationship isToMany]) {
            NSString *reason = [NSString stringWithFormat:@"While initializing to-one entity relationship %@ on entity %@, expected an embedded document but got an array",
                                [relationship name], [[self entity] name]];
            id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                             reason:reason
                                           userInfo:nil];
            @throw exc;
        }
        NSArray *values = [decoder decodeArrayForKey:key withClass:destinationClass];
        
        // Use late binding so the package will work at runtime under 10.6 (which lacks NSOrderedSet) as well as 10.7
        Class class = NSClassFromString (@"NSMutableOrderedSet");
        if (class && [relationship isOrdered])
            [self setValue:[class orderedSetWithArray:values] forKey:key];            
        else
            [self setValue:[NSMutableSet setWithArray:values] forKey:key];
    } else if ([decoder valueIsEmbeddedDocumentForKey:key]) {
        if ([relationship isToMany]) {
            NSString *reason = [NSString stringWithFormat:@"While initializing to-many entity relationship %@ on entity %@, expected an array but got an embedded document",
                                [relationship name], [[self entity] name]];
            id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                             reason:reason
                                           userInfo:nil];
            @throw exc;
        }
        id value = [decoder decodeObjectForKey:key withClass:destinationClass];
        [self setValue:value forKey:key];
    } else if ([decoder containsValueForKey:key]) {
        NSString *type = NSStringFromBSONType([decoder nativeValueTypeForKey:key]);
        NSString *reason;
        if ([relationship isToMany])
            reason = [NSString stringWithFormat:@"While initializing to-many entity relationship %@ on entity %@, expected a BSON array but got type %@",
                      [relationship name], [[self entity] name], type];
        else
            reason = [NSString stringWithFormat:@"While initializing to-one entity relationship %@ on entity %@, expected an embedded document but got type %@",
                      [relationship name], [[self entity] name], type];
        id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                         reason:reason
                                       userInfo:nil];
        @throw exc;
    }
    // do nothing on nil
}

- (void) initializeFetchedProperty:(NSFetchedPropertyDescription *) fetchedProperty withDecoder:(BSONDecoder *) decoder {
    [NSException raise:NSInvalidArchiveOperationException
                format:@"Implement -encodeFetchedProperty:withEncoder: in your subclass to decode fetched properties"];

}

@end
