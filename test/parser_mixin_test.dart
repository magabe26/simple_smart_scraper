/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'package:simple_smart_scraper/simple_smart_scraper.dart';
import 'package:simple_smart_scraper/src/element.dart';
import 'package:simple_smart_scraper/src/parsers/any_word_parser.dart';
import 'package:test/test.dart';

String description(int no, String des) {
  return no < 0 ? 'ParserMixinTests' : 'group#$no: $des';
}

class Parsers with ParserMixin {}

void main() {
  group(description(-1, ''), () {
    Parsers parsers;
    String text;
    setUp(() {
      parsers = Parsers();
      text = '<td>text1</td><td>text2</td><td>text3</td><a/>';
    });

/*----------------------------*/
    group(
        description(
            0, 'text = <td>text1</td><td>text2</td><td>text3</td><a/> ,'), () {
      String resultExpected;

      setUp(() {
        resultExpected = '<td>text1</td>';
      });

      test(
          'A call to spaceOptional().seq(element("td")).flatten().parse(text) should return "<td>text1</td>".',
          () {
        expect(
            resultExpected,
            parsers
                .spaceOptional()
                .seq(parsers.element('td'))
                .flatten()
                .parse(text)
                .value);
      });

      test(
          'A call to element("td").flatten().parse(text) should return "<td>text1</td>".',
          () {
        expect(
            resultExpected, parsers.element('td').flatten().parse(text).value);
      });

      test(
          'A call to anyElement().flatten().parse(text) should return "<td>text1</td>".',
          () {
        expect(
            resultExpected, parsers.anyElement().flatten().parse(text).value);
      });
    });

/*----------------------------*/
    group(
        description(
            1, 'text = <td>text1</td><td>text2</td><td>text3</td><a/> ,'), () {
      List<String> resultExpected;

      setUp(() {
        resultExpected = ['<td>text1</td>', '<td>text2</td>', '<td>text3</td>'];
      });

      test(
          'A call to  spaceOptional().seq(element("td")).flatten().matchesSkipping(text) should return [\'<td>text1</td>\', \'<td>text2</td>\', \'<td>text3</td>\']',
          () {
        expect(
            resultExpected,
            parsers
                .spaceOptional()
                .seq(parsers.element('td'))
                .flatten()
                .matchesSkipping(text));
      });

      test(
          'A call to element("td").flatten().matchesSkipping(text) should return [\'<td>text1</td>\', \'<td>text2</td>\', \'<td>text3</td>\'].',
          () {
        expect(resultExpected,
            parsers.element('td').flatten().matchesSkipping(text));
      });

      test(
          'A call to anyElement().flatten().matchesSkipping(text) should return [\'<td>text1</td>\', \'<td>text2</td>\', \'<td>text3</td>\', \'<a/>\'].',
          () {
        expect([...resultExpected, '<a/>'],
            parsers.anyElement().flatten().matchesSkipping(text));
      });
    });

/*---------------elementText-------------*/
    group(description(2, 'elementText tests;-'), () {
      test(
          "A call to elementText('div').parse('<div>hello 42</div>').value should retutn 'hello 42'",
          () {
        expect(parsers.elementText('div').parse('<div>hello 42</div>').value,
            'hello 42');
      });

      test(
          "A call to elementText('DIV').parse('<div>hello 42</div>').value should retutn 'hello 42'",
          () {
        expect(parsers.elementText('DIV').parse('<div>hello 42</div>').value,
            'hello 42');
      });

      test(
          "A call to elementText('div').parse('<DIV>hello 42</DIV>').value should retutn 'hello 42'",
          () {
        expect(parsers.elementText('div').parse('<DIV>hello 42</DIV>').value,
            'hello 42');
      });

      test(
          "A call to elementText('DIV').parse('<DIV>hello 42</DIV>').value should retutn 'hello 42'",
          () {
        expect(parsers.elementText('DIV').parse('<DIV>hello 42</DIV>').value,
            'hello 42');
      });

      test(
          "A call to elementText('dIV').parse('<DiV>hello 42</DiV>').value should retutn 'hello 42'",
          () {
        expect(parsers.elementText('dIV').parse('<DiV>hello 42</DiV>').value,
            'hello 42');
      });

      test(
          "A call to elementText('div').parse('<div><i>hello 42</i></div>').value should retutn a Failure",
          () {
        expect(parsers.elementText('div').parse('<div><i>hello 42</i></div>'),
            isA<Failure>());
      });

      test(
          "A call to getElementText(tag: 'i', input: '<div><i>42</i></div>') should retutn '42'",
          () {
        expect(parsers.getElementText(tag: 'i', input: '<div><i>42</i></div>'),
            '42');
      });
    });

    /*---------------attributeValue-------------*/
    group(description(3, 'attributeValue tests;-'), () {
      test(
          "A call to getAttributeValue(tag: 'a',attribute: 'href', input: '<a href=\"http://localhost:80'>Home</a>\") should retutn 'http://localhost:80'",
          () {
        expect(
            parsers.getAttributeValue(
                tag: 'a',
                attribute: 'href',
                input: '<a href="http://localhost:80">Home</a>'),
            'http://localhost:80');
      });

      test(
          "A call to getAttributeValue(tag: 'a',attribute: 'href', input: \"<A HREF='http://localhost:80'>HOME</A>\") should retutn 'http://localhost:80'",
          () {
        expect(
            parsers.getAttributeValue(
                tag: 'a',
                attribute: 'href',
                input: "<A HREF='http://localhost:80'>HOME</A>"),
            'http://localhost:80');
      });

      test(
          "NOT- A BUG; A call to getAttributeValue(tag: 'a',attribute: 'hrefXXX', input: \"<A HREF='http://localhost:80'>HOME</A>\") should retutn 'http://localhost:80' this is due to the use of nonCaseSensitiveChars() ",
          () {
        expect(
            parsers.getAttributeValue(
                tag: 'a',
                attribute: 'hrefXXX',
                input: "<A HREF='http://localhost:80'>HOME</A>"),
            'http://localhost:80');
      });

      test(
          "A call to getAttributeValue(tag: 'meta',attribute: 'content',input: '<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">') should retutn 'text/html; charset=UTF-8'",
          () {
        expect(
            parsers.getAttributeValue(
                tag: 'meta',
                attribute: 'content',
                input:
                    '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'),
            'text/html; charset=UTF-8');
      });

      test(
          "A call to getElementAttributes(parser: parsers.elementStartTag(tag:'meta'),input:'<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">')['http-equiv'] should retutn 'Content-Type'",
          () {
        expect(
            parsers.getElementAttributes(
                    parser: parsers.elementStartTag(tag: 'meta'),
                    input:
                        '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">')[
                'http-equiv'],
            'Content-Type');
      });

      test(
          "A call to hasAttribute(tag:'a', attribute: 'href', input: '<a href=\"link\"></a>') should retutn true",
          () {
        expect(
            parsers.hasAttribute(
                tag: 'a', attribute: 'href', input: '<a href="link"></a>'),
            true);
      });

      test(
          "A call to hasAttribute(tag:'a', attribute: 'class', input: '<a href=\"link\"></a>') should retutn false",
          () {
        expect(
            parsers.hasAttribute(
                tag: 'a', attribute: 'class', input: '<a href="link"></a>'),
            false);
      });

      test(
          "A call to removeAttributes(attributes:{'rel','href'}, input: '<link href=\"/font-awesome.min.css\" rel=\"stylesheet\" type=\"text/css\" />') should retutn '<link   type=\"text/css\" />'",
          () {
        expect(
            parsers.removeAttributes(
                attributes: {'rel', 'href'},
                input:
                    '<link href="/font-awesome.min.css" rel="stylesheet" type="text/css" />'),
            '<link   type="text/css" />');
      });

      test(
          "A call to keepAttributes(attributes:{'rel','href'}, input: '<link href=\"/font-awesome.min.css\" rel=\"stylesheet\" type=\"text/css\" />') should retutn '<link href=\"/font-awesome.min.css\" rel=\"stylesheet\"  />'",
          () async {
        expect(
            await parsers.keepAttributes(
                attributes: {'rel', 'href'},
                input:
                    '<link href="/font-awesome.min.css" rel="stylesheet" type="text/css" />'),
            '<link href="/font-awesome.min.css" rel="stylesheet"  />');
      });
    });

    /*---------------ElementTags-------------*/
    group(description(4, 'elementTags tests;-'), () {
      test(
          "A call to getElementTags('<div class=\"chura\"><a href=\"link\"><i>42</i></a></div>') should an array that contains ['div', 'a', 'i']",
          () {
        final tags = parsers.getElementTags(
            '<div class="chura"><a href="link"><i>42</i></a></div>');

        expect(
            (tags.length == 3) &&
                (tags.contains('div')) &&
                (tags.contains('a')) &&
                (tags.contains('i')),
            true);
      });
    });

    group(description(5, 'removing elements tests;-'), () {
      test(
          "A call to remove(parsers: [parentElement('div', element('a'))], input: '<body http-equiv=\"Content-Type\" href=\"er\"><div><a href=\"#link\"></a></div> <div><b>Nancy</b></div></body>') should retutn '<body http-equiv=\"Content-Type\" href=\"er\"> <div><b>Nancy</b></div></body>'",
          () {
        expect(
            parsers.remove(
                parsers: [parsers.parentElement('div', parsers.element('a'))],
                input:
                    '<body http-equiv="Content-Type" href="er"><div><a href="#link"></a></div> <div><b>Nancy</b></div></body>'),
            '<body http-equiv="Content-Type" href="er"> <div><b>Nancy</b></div></body>');
      });
    });

    group(description(5, 'AnyWord parser tests;-'), () {
      test(
          "A call to getParserResults(parser: AnyWord(except: {'Edwin','Magabe'},caseSensitive: false), input: 'Edwin Magabe the great, EDWIN MAGABE THE GREAT') should retutn '['the', 'great', 'THE', 'GREAT']'",
          () {
        expect(
            parsers.getParserResults(
                parser: AnyWordParser(
                    except: {'Edwin', 'Magabe'}, caseSensitive: false),
                input: 'Edwin Magabe the great, EDWIN MAGABE THE GREAT'),
            ['the', 'great', 'THE', 'GREAT']);
      });
      test(
          "A call to getParserResults(parser: AnyWord(except: {'Edwin','Magabe'},caseSensitive: true), input: 'Edwin Magabe the great, EDWIN MAGABE THE GREAT') should retutn '['the', 'great', 'EDWIN', 'MAGABE', 'THE', 'GREAT']'",
          () {
        expect(
            parsers.getParserResults(
                parser: AnyWordParser(
                    except: {'Edwin', 'Magabe'}, caseSensitive: true),
                input: 'Edwin Magabe the great, EDWIN MAGABE THE GREAT'),
            ['the', 'great', 'EDWIN', 'MAGABE', 'THE', 'GREAT']);
      });
    });

    /////////////////////////
    group(
        description(
            6, 'SimpleSmartParser tests;- |SimpleSmartParser.parse(data) | '),
        () {
      String data;
      SimpleSmartParserResult parserResult;
      setUp(() {
        data = '''
 <section class="top-bar-section">
           <!-- this is a comment -->
           <!-- Right Nav Section -->
           <ul class="right">
               <li class="" chura><a href="/applications.html">Applications</a></li>
               <li class=""><a target="_blank" href="/dashboard/phpinfo.php">PHPInfo</a></li>
               <li class=""><a href="/phpmyadmin/">phpMyAdmin</a></li>
           </ul>
 </section>
<h5><a href="/dashboard/docs/reset-mysql-password.html">Reset the MySQL/MariaDB Root Password</a></h5>
<h5><a href="/dashboard/docs/send-mail.html">Send Mail with PHP</a></h5><div>php</div>

''';
        parserResult = SimpleSmartParser.parse(data);
      });

      test(
          "After a call to parserResult.getElements('li') should return a list of li elements of length == 3",
          () {
        // ignore: omit_local_variable_types
        List<Element> list = parserResult.getElements('li');

        expect(list.length, 3);
      });

      test(
          "After a call to parserResult.getElements('h5') should return a list of li elements of length == 2",
          () {
        // ignore: omit_local_variable_types
        List<Element> list = parserResult.getElements('h5');

        expect(list.length, 2);
      });

      test(
          'After a call to parserResult.getCommentAt(0).toString() should return <!-- this is a comment -->',
          () {
        expect(parserResult.getCommentAt(0).toString(),
            '<!-- this is a comment -->');
      });
    });

    /////////////////////
  });
}
