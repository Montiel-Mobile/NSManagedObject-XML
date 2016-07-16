//
//  NSManagedObject+XML.m
//
//  Created by John Montiel on 5/16/12.
//  Copyright (c) 2012 Em Sevn, LLC. All rights reserved.
//

#import "NSManagedObject+XML.h"
#import "DateFormatter.h"
#import "EncryptionHelper.h"
#import "GTMStringEncoding.h"
#import "DDXMLElement+conv.h"

@implementation NSManagedObject (XML)

- (DDXMLElement *)xmlElement;
{
    NSString *entityTagName = [[self.entity userInfo] objectForKey:kXMLTagName];
    DDXMLElement *rootElement = nil;
    
    if (entityTagName.length > 0)
        rootElement = [DDXMLElement elementWithName:entityTagName];
    else
        rootElement = [DDXMLElement elementWithName:self.entity.name];
    
    // Entity attributes
    
    NSDictionary *attributes = self.entity.attributesByName;
    
    for (NSString *key in attributes)
    {
        NSAttributeDescription *attributeDesc = [attributes objectForKey:key];
        
        if (![attributeDesc.userInfo objectForKey:kExclude])
        {
            NSString *attrValue = nil;
            
            if (attributeDesc.attributeType == NSInteger16AttributeType ||
                attributeDesc.attributeType == NSInteger32AttributeType ||
                attributeDesc.attributeType == NSInteger64AttributeType ||
                attributeDesc.attributeType == NSDecimalAttributeType)
            {
                attrValue = [NSString stringWithFormat:@"%i", (int)[(NSNumber *)[self valueForKeyPath:key] integerValue]];
            }
            else if (attributeDesc.attributeType == NSDoubleAttributeType)
            {
                attrValue = [NSString stringWithFormat:@"%f", [(NSNumber *)[self valueForKeyPath:key] doubleValue]];
            }
            else if (attributeDesc.attributeType == NSFloatAttributeType)
            {
                attrValue = [NSString stringWithFormat:@"%f", [(NSNumber *)[self valueForKeyPath:key] floatValue]];
            }
            else if (attributeDesc.attributeType == NSStringAttributeType)
            {
                attrValue = [self valueForKeyPath:key];
            }
            else if (attributeDesc.attributeType == NSBooleanAttributeType)
            {
                attrValue = [NSString stringWithFormat:@"%i", (int)[(NSNumber *)[self valueForKeyPath:key] integerValue]];
            }
            else if (attributeDesc.attributeType == NSDateAttributeType)
            {
                NSDateFormatter *formatter = [[DateFormatter sharedHelper] dateFormatter];
                NSString *format = [attributeDesc.userInfo objectForKey:kDateTimeFormat];
                formatter.dateFormat = (format ? format : kDateFormat);
                
                attrValue = [formatter stringFromDate:(NSDate *)[self valueForKeyPath:key]];
            }
            else if (attributeDesc.attributeType == NSBinaryDataAttributeType)
            {
                if ([[attributeDesc userInfo] objectForKey:kEncrypted])
                {
                    attrValue = [[EncryptionHelper sharedHelper] decryptData:(NSData *)[self valueForKeyPath:key]];
                }
                else if ([[attributeDesc userInfo] objectForKey:kBase64])
                {
                    GTMStringEncoding *encoding = [GTMStringEncoding rfc4648Base64StringEncoding];
                    attrValue = [encoding encode:(NSData *)[self valueForKeyPath:key]];
                }
            }
            
            if (attrValue)
            {
                DDXMLElement *attrElement = [DDXMLElement elementWithName:key stringValue:attrValue];
                [rootElement addChild:attrElement];
            }
        }
    }
    
    // Entity relationships
    
    NSDictionary *relationships = self.entity.relationshipsByName;
    NSArray *sortedKeys = [self sortedEntityRelationships];
    for (NSString *key in sortedKeys)
    {
        NSRelationshipDescription *relationship = [relationships valueForKey:key];
        
        // Check for the Expand user info key to determine whether to expand the relationship
        if ([[relationship userInfo] objectForKey:kExpand])
        {
            if (relationship.isToMany)
            {
                NSSet *entities = [self valueForKeyPath:key];
                DDXMLElement *group = [DDXMLElement elementWithName:key];
                [rootElement addChild:group];
                for (NSManagedObject *entity in entities)
                {
                    [group addChild:[entity xmlElement]];
                }
            }
            else
            {
                NSManagedObject *entity = [self valueForKeyPath:key];
                if (entity)
                    [rootElement addChild:[entity xmlElement]];
                else
                    [rootElement addChild:[DDXMLElement elementWithName:key]];
            }
        }
    }
    
    return rootElement;
}

- (void)ingestXMLElement:(DDXMLElement *)xmlElement;
{
    // ATTRIBUTES
    
    NSDictionary *attributes = self.entity.attributesByName;
    NSString *overwrite = [[self.entity userInfo] objectForKey:kOverwrite];
    
    BOOL newEntity = YES;
    
    for (NSString *key in attributes)
    {
        NSAttributeDescription *attrDesc = [attributes objectForKey:key];
        id currentValue = [self valueForKey:key];

        if (currentValue && ![attrDesc.defaultValue isEqual:currentValue])
        {
            newEntity = NO;
            break;
        }
    }
    
    for (NSString *key in attributes)
    {
        if (newEntity || [[overwrite uppercaseString] isEqualToString:@"YES"])
        {
            NSString *stringValue = [xmlElement valueForTag:key];
            
            if (stringValue)
                [self setValue:stringValue forKeyPath:key];
        }
    }
    
    // RELATIONSHIPS
    
    NSDictionary *relationships = self.entity.relationshipsByName;
    NSArray *sortedKeys = [self sortedEntityRelationships];
    for (NSString *key in sortedKeys)
    {
        NSRelationshipDescription *relationship = [relationships valueForKey:key];
        NSString *relEntityName = relationship.name;
        
        NSString *relTagName = nil;
        if (!(relTagName = [[relationship.destinationEntity userInfo] objectForKey:kXMLTagName]))
            relTagName = relationship.destinationEntity.name;
        
        DDXMLElement *manyRelElement = nil;
        NSArray *manyRelElements = [xmlElement elementsForName:relEntityName];
        DDXMLElement *relationshipElement = nil;
        
        if (relationship.isToMany)
        {
            manyRelElement = [[xmlElement elementsForName:relEntityName] lastObject];
            manyRelElements = [manyRelElement elementsForName:relTagName];
        }
        else 
        {
            relationshipElement = [[xmlElement elementsForName:relTagName] lastObject];
        }
        
        // Check for the CreateEntity & Relation user info key to determine whether to update or create
        if ([[relationship userInfo] objectForKey:kCreateEntity] &&
            [[relationship userInfo] objectForKey:kUpdateEntity])
        {
            if (relationship.isToMany)
            {
                for (DDXMLElement *relationshipElement in manyRelElements)
                {
                    NSManagedObject *relObject = [self getObjectForRelationshipDesc:relationship andElement:relationshipElement];
                    if (relObject)
                    {
                        [relObject ingestXMLElement:relationshipElement];
                    }
                    else
                    {
                        relObject = [[NSManagedObject alloc] initWithEntity:relationship.destinationEntity insertIntoManagedObjectContext:self.managedObjectContext];
                        NSString *inverseRelName = relationship.inverseRelationship.name;
                        [relObject setValue:self forKey:inverseRelName];
                        [relObject ingestXMLElement:relationshipElement];
                    }
                }
            }
            else
            {
                if (relationshipElement)
                {
                    NSManagedObject *relObject = [self getObjectForRelationshipDesc:relationship andElement:relationshipElement];
                    if (relObject)
                    {
                        [relObject ingestXMLElement:relationshipElement];
                    }
                    else
                    {
                        relObject = [[NSManagedObject alloc] initWithEntity:relationship.destinationEntity insertIntoManagedObjectContext:self.managedObjectContext];
                        NSString *inverseRelName = relationship.inverseRelationship.name;
                        [relObject setValue:self forKey:inverseRelName];
                        [relObject ingestXMLElement:relationshipElement];
                    }
                }
            }
        }
        // Check for the CreateEntity user info key to determine whether to create the relationship entity
        else if ([[relationship userInfo] objectForKey:kCreateEntity])
        {
            if (relationship.isToMany)
            {
                for (DDXMLElement *relationshipElement in manyRelElements)
                {
                    NSManagedObject *relObject = [self getObjectForRelationshipDesc:relationship andElement:relationshipElement];
                    if (!relObject)
                    {
                        relObject = [[NSManagedObject alloc] initWithEntity:relationship.destinationEntity insertIntoManagedObjectContext:self.managedObjectContext];
                        NSString *inverseRelName = relationship.inverseRelationship.name;
                        [relObject setValue:self forKey:inverseRelName];
                        [relObject ingestXMLElement:relationshipElement];
                    }
                }
            }
            else 
            {
                if (relationshipElement)
                {
                    NSManagedObject *relObject = [self getObjectForRelationshipDesc:relationship andElement:relationshipElement];
                    if (!relObject)
                    {
                        relObject = [[NSManagedObject alloc] initWithEntity:relationship.destinationEntity insertIntoManagedObjectContext:self.managedObjectContext];
                        NSString *inverseRelName = relationship.inverseRelationship.name;
                        [relObject setValue:self forKey:inverseRelName];
                        [relObject ingestXMLElement:relationshipElement];
                    }
                }
            }
        }
        
        // Check for the Relation user info key to determine whether to establish a relationship
        // to a related entity
        else if ([[relationship userInfo] objectForKey:kUpdateEntity])
        {
            if (relationship.isToMany)
            {
                for (DDXMLElement *relationshipElement in manyRelElements)
                {
                    NSManagedObject *relObject = [self getObjectForRelationshipDesc:relationship andElement:relationshipElement];
                    if (relObject)
                    {
                        [relObject ingestXMLElement:relationshipElement];
                    }
                }
            }
            else
            {
                if (relationshipElement)
                {
                    NSManagedObject *relObject = [self getObjectForRelationshipDesc:relationship andElement:relationshipElement];
                    if (relObject)
                        [relObject ingestXMLElement:relationshipElement];
                }
            }
        }
        // Check for the Reference user info key to determine whether to establish a relationship
        // to a reference table entity
        else if ([[relationship userInfo] objectForKey:kReference])
        {
            if (relationship.isToMany)
            {
                for (DDXMLElement *relationshipElement in manyRelElements)
                {
                    NSString *attrKey = [relationship.destinationEntity.userInfo objectForKey:kReferenceKey];
                    NSString *attrValue = [relationshipElement valueForTag:attrKey];
                    NSManagedObject *relObject = [self getObjectForEntityDesc:relationship.destinationEntity forAttrKey:attrKey andAttrValue:attrValue];
                    if (relObject)
                    {
                        NSMutableSet *objects = [self valueForKey:relationship.name];
                        [objects addObject:relObject];
                        [self setValue:objects forKey:relationship.name];

                    }
                }
            }
            else
            {
                if (relationshipElement)
                {
                    NSString *attrKey = [relationship.destinationEntity.userInfo objectForKey:kReferenceKey];
                    NSString *attrValue = [relationshipElement valueForTag:attrKey];
                    NSManagedObject *relObject = [self getObjectForEntityDesc:relationship.destinationEntity forAttrKey:attrKey andAttrValue:attrValue];
                    if (relObject)
                        [self setValue:relObject forKey:relationship.name];
                }
            }
        }
    }
}

- (NSArray *)sortedEntityRelationships;
{
    NSDictionary *relationships = self.entity.relationshipsByName;
    
    if ([self.entity.userInfo objectForKey:kSortedRelationships])
    {
        NSArray *sortedArray = [relationships keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) 
            {
                NSRelationshipDescription *relDesc1 = obj1;
                NSRelationshipDescription *relDesc2 = obj2;
                
                NSInteger value1 = [[relDesc1.userInfo objectForKey:kSortOrder] integerValue];
                NSInteger value2 = [[relDesc2.userInfo objectForKey:kSortOrder] integerValue];
                
                if (value1 == value2)
                    return NSOrderedSame;
                else if (value1 < value2)
                    return NSOrderedAscending;
                else 
                    return NSOrderedDescending;
                
            }];
        return sortedArray;
    }
    else 
        return [relationships allKeys];
}

- (void) setValue:(id)value forKeyPath:(NSString *)keyPath
{
    if (value && [value isKindOfClass:[NSString class]])
    {
        NSAttributeDescription *attributeDesc = [self.entity.attributesByName objectForKey:keyPath];
        NSString *oldValue = value;
        id newValue = nil;
        
        if (attributeDesc.attributeType == NSInteger16AttributeType ||
            attributeDesc.attributeType == NSInteger32AttributeType ||
            attributeDesc.attributeType == NSInteger64AttributeType)
        {
            newValue = [NSNumber numberWithInteger:oldValue.integerValue];
        }
        else if (attributeDesc.attributeType == NSDecimalAttributeType)
        {
            newValue = [NSNumber numberWithInteger:oldValue.integerValue];
        }
        else if (attributeDesc.attributeType == NSDoubleAttributeType)
        {
            newValue = [NSNumber numberWithDouble:oldValue.doubleValue];
        }
        else if (attributeDesc.attributeType == NSFloatAttributeType)
        {
            newValue = [NSNumber numberWithFloat:oldValue.floatValue];
        }
        else if (attributeDesc.attributeType == NSStringAttributeType)
        {
            newValue = oldValue;
        }
        else if (attributeDesc.attributeType == NSBooleanAttributeType)
        {
            newValue = [NSNumber numberWithFloat:oldValue.floatValue];
        }
        else if (attributeDesc.attributeType == NSDateAttributeType)
        {
            NSDateFormatter *formatter = [[DateFormatter sharedHelper] dateFormatter];
            NSString *format = [attributeDesc.userInfo objectForKey:kDateTimeFormat];
            formatter.dateFormat = (format ? format : kDateFormat);
            newValue = [formatter dateFromString:oldValue];
        }
        else if (attributeDesc.attributeType == NSBinaryDataAttributeType)
        {
            if ([[attributeDesc userInfo] objectForKey:kEncrypted])
            {
                newValue = [[EncryptionHelper sharedHelper] encryptString:oldValue];
            }
            else if ([[attributeDesc userInfo] objectForKey:kBase64])
            {
                GTMStringEncoding *encoding = [GTMStringEncoding rfc4648Base64StringEncoding];
                newValue = [encoding decode:oldValue];
            }
        }
        [super setValue:newValue forKeyPath:keyPath];
    }
    else 
        [super setValue:value forKeyPath:keyPath];
}

- (NSManagedObject *)getObjectForRelationshipDesc:(NSRelationshipDescription *)inRelEntityDesc andElement:(DDXMLElement *)element;
{
    NSString *relKey = [inRelEntityDesc.destinationEntity.userInfo objectForKey:kReferenceKey];
    NSString *relKeyValue = [element valueForTag:relKey];

    
    id relatedEntities = [self valueForKeyPath:inRelEntityDesc.name];
    NSManagedObject *entity = nil;
    
    if ([relatedEntities isKindOfClass:[NSManagedObject class]])
    {
        NSString *thisValue = ([[(NSManagedObject *)relatedEntities valueForKeyPath:relKey] isKindOfClass:[NSString class]] ? [(NSManagedObject *)relatedEntities valueForKeyPath:relKey] : [[(NSManagedObject *)relatedEntities valueForKeyPath:relKey] stringValue]);
        if ([thisValue isEqualToString:relKeyValue])
            entity = relatedEntities;
    }
    else if ([relatedEntities isKindOfClass:[NSSet class]])
    {
        for (NSManagedObject *thisEntity in [(NSSet *)relatedEntities allObjects])
        {
            NSString *thisValue = ([[thisEntity valueForKeyPath:relKey] isKindOfClass:[NSString class]] ? [thisEntity valueForKeyPath:relKey] : [[thisEntity valueForKeyPath:relKey] stringValue]);
            if ([thisValue isEqualToString:relKeyValue])
            {
                entity = thisEntity;
                break;
            }
        }
    }
    else if ([relatedEntities isKindOfClass:[NSOrderedSet class]])
    {
        for (NSManagedObject *thisEntity in (NSOrderedSet *)relatedEntities)
        {
            NSString *thisValue = ([[thisEntity valueForKeyPath:relKey] isKindOfClass:[NSString class]] ? [thisEntity valueForKeyPath:relKey] : [[thisEntity valueForKeyPath:relKey] stringValue]);
            if ([thisValue isEqualToString:relKeyValue])
            {
                entity = thisEntity;
                break;
            }
        }
    }

    return entity;
}

- (NSManagedObject *)getObjectForEntityDesc:(NSEntityDescription *)inEntityDesc forAttrKey:(NSString *)inAttrKey andAttrValue:(NSString *)inAttrValue;
{
    NSFetchRequest *request = [self fetchRequestForEntityName:inEntityDesc.name];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ == '%@'", inAttrKey, inAttrValue];
    
    NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:inAttrKey ascending:YES];
    
    [request setPredicate:predicate];
    [request setIncludesSubentities:YES];
    [request setSortDescriptors:[NSArray arrayWithObjects:sortDesc, nil]];
    
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    NSManagedObject *result = nil;
    if ([results count] > 0)
        result = [results objectAtIndex:0];
    return result;
}


- (NSFetchRequest *)fetchRequestForEntityName:(NSString *)newEntityName
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:newEntityName inManagedObjectContext:self.managedObjectContext];
    
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entity];
	
	return request;
}


@end
