README
======

This is a category on NSManagedObject that implements KissXML to generate a DDXMLElement object from an NSManagedObject, and to ingest a DDXMLElement object to populate an NSManagedObject and any sub entities (if configured to) to be created and/or sub entities to establish relationships to (either to reference entities/tables or relationship entities within a hierarchy).

HOW TO USE IT
-------------

This category uses the Google Tool Box class for base64 encoding/decoding at http://google-toolbox-for-mac.googlecode.com/svn/trunk, specifically GTMStringEncoding, which is included here. Also, a forked version of the KissXML project at https://github.com/robbiehanson/KissXML.git as a git submodule, so you will need to add /usr/include/libxml2 to your header search paths in the build settings. Apple's SecKeyWrapper sample code at http://developer.apple.com is also included here. A DataFormatter singleton which instantiates NSDateFormatter once and reuses it for performance reasons, instead of instantiating it for every use for date processing in this category, is provided as well.

Core Data UserInfo Keys
=======================

Use these keys in the user info section when configuring the core data model to enable the associated behavior.

Entity Description UserInfo keys
--------------------------------

'Overwrite' - when value is "yes" the attributes are overwritten, otherwise they are only written if the entity is new.

'XMLTagName' - value is used as the XML tagname instead of the entity name (optional - used to override the entity name)

'ReferenceKey' - value is the attribute name that is used as the reference table key

'SortedRelationships' - value is unused, it's presence identifies an entity that sorts relationships when ingesting XML. If this key is specified, then the 'SortOrder' below is required on ALL relationships for the entity. This may be required for relationship dependancies by ensuring created sub entities are ingested before relation sub entities (which are not created but instead a relationship is established to previously created sub entities).


Attribute Description UserInfo keys
-----------------------------------

'encrypted' - value is unused, it's presence identifies encrypted NSStrings (stored as NSData).

'base64' - value is unused, it's presence identifies binary data that is to be base64 encoded for XML.

'exclude' - value is unused, it's presence is used to exclude an attribute from XML expansion by default all attributes will get expanded.

'Format' - value is used as the format for NSDateFormatter, if present. Otherwise the global kDateFormat is used.


Relationship Description UserInfo keys
--------------------------------------

'Expand' - value is unused, it's presence identifies a relationship that will be XML expanded. By default no relationships will get expanded.

'CreateEntity' - value is unused, it's presence is used to create the relationship entity when ingesting XML.

'Reference' - UpdateEntity's value is unused, it's presence is used to update the relationship entity when ingesting XML.

'UpdateEntity' - UpdateEntity's value is unused, it's presence is used to update the relationship entity when ingesting XML.

'SortOrder' - value is a number that indicates the order to sort the relationships of the entity.


LICENSE
-------

Copyright (C) 2012-2019 by Montiel Mobile, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
