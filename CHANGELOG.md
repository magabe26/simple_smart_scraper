##1.0.18
##1.0.17
       -petitparser versions above 2.4.0, don't work well with this library
##1.0.16
##1.0.15
      -Minor bug fixes
      
##1.0.14
##1.0.13
 -Updated
        
        environment:
          sdk: '>=2.7.0 <3.0.0'
##1.0.11
      -Minor bug fixes
##1.0.10
- Added 

        -ParserUtilMixin
##1.0.9
- Added 

        -Examples
##1.0.8 
- Added
        
        - ElementStartTagParser , hasAttributesParser(tag) and hasAttributes(element)
        
            Parser hasAttributesParser(tag) => (ElementStartTagParser(
                         tags: {tag}, attributes: {}, isClosed: false, limit: 1)
                     .or(ElementStartTagParser(
                         tags: {tag}, attributes: {}, isClosed: true, limit: 1)))
                 .not('hasAttributesParser: false');
           
             ///Return true if the element has one or more attributes  otherwise return false
             bool hasAttributes(String element) {
               String tag = getTagFromElementStartTag(element);
               if (tag == null || element == null) {
                 return false;
               }
               return hasAttributesParser(tag).accept(element);
             }
        
##1.0.6
## 1.0.2 
- Added

       - keepAttributesSync(...), keepTagsSync(...) and removeTagsSync(...)
       - forward() which return a [ForwardParser], a ]ForwardParser] does not parse its input but only return the input as the result of the parse operation
       - intercepted({Interceptor interceptor}) which return an [InterceptedParser] that allow the parser's parsing process to be intercepted by the [Interceptor]
       - cleanSync(...), clean(...) Easy to use methods for cleaning the Html or Xml input
            Both methods return the output with selected tag(  keepTag ) and attribute ( keepAttributes )
       - [AttributeParser]  Attribute parsing made easier and effective.
       - [AnyWordParser]  Parses any word except the provided exceptionalWords with caseSensitivity capabilities
       - [SimpleSmartParser] Parses an html or xml string and execute a callback on each element found
       - [SimpleSmartParser] & [SimpleSmartParserResult] , directly target any element using dictionary based access
       - New advanced implementation of [AnyElementParser]
       - New advanced implementation of  getElementTags(...) method

- BugFixes

       -  removeAttributes(...) method now works perfectly.

## 1.0.1

      - Updated README.md

## 1.0.0

        - Initial version.
