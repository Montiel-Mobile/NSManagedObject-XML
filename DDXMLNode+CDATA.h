@import Foundation;
#import "DDXMLNode.h"

@class DDXMLElement;

@interface DDXMLNode (CDATA)

+ (DDXMLElement *)cdataElementWithName:(NSString *)tagName stringValue:(NSString *)htmlString;

@end
