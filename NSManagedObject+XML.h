//
//  NSManagedObject+XML.h
//
//  Created by John Montiel on 5/16/12.
//  Copyright (c) 2012 Em Sevn, LLC. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "DDXML.h"

#define kDateFormat @"yyyy-MM-dd'T'HH:mm:ss"

// This category uses the Google Tool Box class for base64 encoding / decoding
// at http://google-toolbox-for-mac.googlecode.com/svn/trunk
//
// the KissXML project at https://github.com/robbiehanson/KissXML.git
//
// And Apple's SecKeyWrapper sample code at http://developer.apple.com
//
// It also uses a DataFormatter singleton which instantiates NSDateFormatter once
// and reuses it for performance reasons, instead of instantiating it for every use
// for date processing in this category

// UserInfo keys for entities, attributes and relationships in the data model

//ENTITY USERINFO KEYS

//      XMLTagName's value is used as the XML tagname instead of the entity name (optional - used to override)
#define kXMLTagName @"XMLTagName"

//      ReferenceKey's value is the attribute name that is used as the reference table key
#define kReferenceKey @"ReferenceKey"

//      SortedRelationships value is unused, it's presence identifies an entity that sorts relationships when
//      ingesting XML. If this key is specified, then the 'SortOrder' below is required on ALL relationships
//      for the entity. This may be required for relationship dependancies by ensuring created sub entities
//      are ingested before reference and relation sub entities (which are not created but instead a
//      relationship is established to the previously created sub entities).
#define kSortedRelationships @"SortedRelationships"

//      RootHierarchyAttrKey identifies the path of the unique id of the entity at the top of the hierarchy
//      relative to the given entity
#define kRootHierarchyAttrKey @"RootHierarchyAttrKey"


//ATTRIBUTE USERINFO KEYS

//      encrypted's value is unused, it's presence identifies encrypted NSStrings (stored as NSData)
#define kEncrypted @"encrypted"

//      base64 value is unused, it's presence identifies binary data that is to be base64 encoded for XML
#define kBase64 @"base64"

//      exclude's value is unused, it's presence is used to exclude an attribute from XML
//      expansion by default all attributes will get expanded
#define kExclude @"Exclude"

//      Format's value is used as the format for NSDateFormatter, if present. Otherwise the global
//      kDateFormat is used
#define kDateTimeFormat @"Format"

//Relationship userInfo keys

//      Expand's value is unused, it's presence identifies a relationship that will be XML expanded.
//      By default no relationships will get expanded
#define kExpand @"Expand"

//      CreateEntity's value is unused, it's presence is used to create the relationship entity when
//      ingesting XML
#define kCreateEntity @"CreateEntity"

//      Reference's value is unused, it's presence is used to identify the relationship to a reference
//      table (does not create the relationship entity)
#define kReference @"Reference"

//      Relation's value is unused, it's presence is used to identify the relationship to an entity within
//      the root entity's hierarchy structure (does not create the relationship entity)
#define kRelation @"Relation"

//      SortOrder's value is a number that indicates the order to sort the relationships
#define kSortOrder @"SortOrder"


//      relationship entity will require an attribute, 'id', that is unique at it's level in the root
//      hierarchy, to establish a connection using the 'Relation' user info key above
#define kRelationID @"id"



@interface NSManagedObject (XML)

//      Returns a KissXML DDXMLElement representation of the NSManagedObject
//      See the user info keys for the core data model configuration above
- (DDXMLElement *)xmlElement;

//      populates the attributes and relationships of an NSManagedObject with the KissXML DDXMLElement object
- (void)ingestXMLElement:(DDXMLElement *)xmlElement;

//      Override(s)
- (void) setValue:(id)value forKeyPath:(NSString *)keyPath;

@end