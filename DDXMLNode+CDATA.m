#import "DDXMLNode+CDATA.h"
#import "DDXMLElement.h"
#import "DDXMLDocument.h"

@implementation DDXMLNode (CDATA)

+ (DDXMLElement *)cdataElementWithName:(NSString *)tagName stringValue:(NSString *)htmlString
{
    NSString* taggedString = [NSString stringWithFormat:@"<%@><![CDATA[%@]]></%@>", tagName, htmlString, tagName];
    DDXMLElement* cdataElement = [[DDXMLDocument alloc] initWithXMLString:taggedString options:DDXMLDocumentXMLKind error:nil].rootElement;
    return [cdataElement copy];
}

@end
