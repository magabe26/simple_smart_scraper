import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:simple_smart_scraper/petitparser_2.4.0.dart';
import 'package:simple_smart_scraper/simple_smart_scraper.dart';
import 'package:http/http.dart' as http;
import 'package:simple_smart_scraper/src/element.dart';
import 'package:simple_smart_scraper/src/parsers/element_start_tag_parser.dart';
import 'package:simple_smart_scraper/src/parsers/simple_smart_parser.dart';
import 'dart:isolate';

class ResultsParsers with ParserMixin {
  static final String councilTag = 'h2';
  static final String titleTag = 'h1';
  static final String schoolTag = 'h3';

  String cleanResultsHtml(String html) {
    return cleanSync(
      keepTags: {'tr', 'td', 'h2', 'h1', 'h3'},
      input: html,
    );
  }

  Parser councilParser() => element(councilTag);
  Parser titleParser() => element(titleTag);
  Parser schoolParser() => element(schoolTag);
  Parser candidateResultParser() =>
      parentElement('tr', repeat(element('td'), 4));

/*
  <tr><td  >PS1907062-024</td>
  <td  >M</td>
   <td  >MUFASSA SIMBA</td>
  <td  >Kiswahili - A, English - A, Maarifa - A, Hisabati - A, Science - A, Average Grade - A</td></tr>
  */
  CandidateResult parseCandidateResult(String tr) {
    final tds = getParserResults(parser: element('td'), input: tr);
    dynamic value(int index) {
      if (tds.length == 4 && (index < 4)) {
        return (index < 3)
            ? getElementText(tag: 'td', input: tds[index])
            : convertToMap(getElementText(tag: 'td', input: tds[index]),
                first: ',', second: '-');
      } else {
        return (index < 3) ? '' : {};
      }
    }

    return CandidateResult(
      name: value(2),
      sex: value(1),
      no: value(0),
      subjects: value(3),
    );
  }

  Results parseResults(String html) {
    String toHtml(Parser parser) {
      return getParserResult(parser: parser, input: html);
    }

    final _council = getElementText(
        tag: ResultsParsers.councilTag, input: toHtml(councilParser()));

    final _title = getElementText(
        tag: ResultsParsers.titleTag, input: toHtml(titleParser()));

    final _school = getElementText(
        tag: ResultsParsers.schoolTag, input: toHtml(schoolParser()));

    var _candidateResults = <CandidateResult>[];
    for (var tr
        in getParserResults(parser: candidateResultParser(), input: html)) {
      _candidateResults.add(parseCandidateResult(tr));
    }

    if (_candidateResults.isNotEmpty) {
      //removing the first element, because it contain no useful information but data that represent html table headers
      _candidateResults.removeAt(0);
    }

    return Results(
        council: _council,
        title: _title,
        school: _school,
        candidateResults: _candidateResults);
  }
}

class CandidateResult {
  final String name;
  final String sex;
  final String no;
  final Map<String, String> subjects;

  CandidateResult({this.name, this.sex, this.no, this.subjects});

  factory CandidateResult.fromHtml(String html) {
    return ResultsParsers().parseCandidateResult(html);
  }

  Map<String, String> toJson() {
    return <String, String>{
      'name': name,
      'sex': sex,
      'no': no,
      'subjects': subjects.toString()
    };
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}

class Results {
  final String council;
  final String title;
  final String school;
  final List<CandidateResult> candidateResults;

  Results({this.council, this.title, this.school, this.candidateResults});

  factory Results.fromHtml(String html) {
    return ResultsParsers().parseResults(html);
  }

  static Future<Results> fromUrl(String url) async {
    var data = '';
    try {
      data = ResultsParsers().cleanResultsHtml(await download(url));
    } catch (_) {} finally {
      return Results.fromHtml(data);
    }
  }

  Map<String, String> toJson() {
    return <String, String>{
      'council': council,
      'title': title,
      'school': school,
      'candidateResults': candidateResults.toString()
    };
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}

//ResultsDecoder can be implemented in two ways.

/*
Implementation 1: using  the forward() that return ForwardParser
-------------------------------------------------------------
*/
/*
class ResultsDecoder extends Decoder<Results> {
  ResultsParsers _parsers = ResultsParsers();

  @override
  Results mapParserResult(String result) {
    return Results.fromHtml(_parsers.cleanResultsHtml(result));
  }

  ///Using forward() to forward the input to mapParserResult,
  ///in this case, mapParserResult is the one doing the parsing
  @override
  Parser get parser =>
      forward(); //forward return a parser that does'nt parse its input ,but only return the input as the result of the parse operation
}
*/

/*
Implementation 2: using the intercepted method that return InterceptedParser
--------------------------------------------------------------------------
*/

class ResultsDecoder extends Decoder<Results> {
 final ResultsParsers _parsers = ResultsParsers();

  @override
  Results mapParserResult(String result) {
    //The parse result is the cleaned html returned by the interceptor method
    return Results.fromHtml(result);
  }

  ///Using intercepted method to clean the html before mapParserResult is called
  @override
  Parser get parser => intercepted(interceptor: (input) {
        return _parsers.cleanResultsHtml(input);
      });
}

void main() async {
  final url = 'http://localhost/primary/2017/psle/results/exam_results2.htm';
  // final url = 'http://localhost/dashboard/howto_shared_links.html';

  // Results results = await Results.fromUrl(url);

  // print(results.council);

  // print(results.title);

  // print(results.school);

  //print(results.candidateResults);

  var client = http.Client();
  var res = await client.send(http.Request('get', Uri.parse(url)));
  res.stream
      .transform(Utf8Decoder())
      .transform(ResultsDecoder())
      .expand((i) => i)
      .listen((results) {
    print('**${results.school}***\n\n');
    results.candidateResults.forEach((candidateResult) {
      print('${candidateResult.name} -  ${candidateResult.no}');
    });
  });

  var p = ResultsParsers();
/*
  final String html1 = '''
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
  <link href="/font-awesome.min.css" rel="stylesheet" type="text/css" />
  <script src="/dashboard/javascripts/modernizr.js" type="text/javascript"></script>
  <body<div><a href="#link"></a></div> <div><b>Nancy</b></div>''';

  //parse meta information from string html1
  //get meta tag
  Parser metaParser = p.elementStartTag(tag: 'meta');
  String meta = p.getParserResult(parser: metaParser, input: html1);

  print(p.remove(parsers: [p.parentElement('div', p.element('a'))], input: '<body http-equiv="Content-Type" href="er"><div><a href="#link"></a></div> <div><b>Nancy</b></div></body>')); // <body http-equiv="Content-Type" href="er"> <div><b>Nancy</b></div></body>
*/
/*
  var input = await download(url);
  print(p.cleanSync(
      keepTags: {'tr', 'td', 'h2', 'h1', 'h3'},
      keepAttributes: {'size'},
      input: input,
     ));*/

  //var data = await download(url);
  // print(data);
  // print(p.cleanResultsHtml(data));
  // data = p.remove(parsers: [p.script(), p.htmlComment()], input: data);
  // print(p.removeComments(data));
// print(p.getParserResults(parser: p.element('div'), input: data).map((str)=>str.trim()).join(' <<<<\n'));
/*
  print(p.cleanSync(
      keepAttributes: {'href'},
      keepTags: {'li', 'a', 'div'},
      input: data,
      finalizer: p.removeComments));*/
//print(p.getParserResults(parser: AnyWord(except: {'chura'},caseSensitive: false), input: 'CHURA chura mkia the greate wrty'));
//print(AnyWord(except: {'chura'},caseSensitive: false).parse('CHURA chura mkia the greate wrty').value);

  //print(await p.keepAttributes(attributes: null, input: '<a href="qwee" >qwee</a>'));
  //print(p.getParserResults(parser: p.attribute('href'), input: '<a h="qwed rrgg" href="qwee qwery 12" we><i>Hellow word</i></a>'));

  //print( p.attribute('we',false).matchesSkipping('<a h="qwed rrgg" href="qwee qwery 12" we><i>Hellow word</i></a>'));
/*
  print(p.getAttributeValue(
      tag: 'a',
      attribute: 'href',
      input: '<a href="http://localhost:80">Home</a>'));*/

  // print(await p.keepAttributes(attributes: {'content'}, input: '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'));
//  print(p.getAttributeValue(tag: 'meta',attribute: 'content',input: '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'));

/*
  print(p.removeAttributesImpl(
    attributes: {'href'},
    input: '<a href="localhost:80" >Home</a>',
  ));
*/
  /*
 var attribute = RegExp(r'''([A-Za-z]+[0-9]*={1}['"]?.*['"]?){1}''');
 attribute.allMatches('<a wer=7 href="localhost:80" href=\'http://localhost:80/452\'>Home</a>').toList().forEach((e){
   print('${e.group(0)}\n');
 });*/
//print(data);
  // print(SSmartScraperRegEx.elementRegExp('li').firstMatch(data).group(0));
//print(data);
/*
  SSmartScraperRegEx.elementRegExp('tr').allMatches(data).toList().forEach((e) {
    print(
        '${e.input.substring(e.start, e.end)}---${e.end}--${e.input.length}---<<<<<');
  });
*/
/*
  final data = '''
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
<br>
<meta>
''';*/
/*
  SimpleSmartParserResult parserResult = SimpleSmartParser.parse(data);
  List<Element> liList = parserResult.getElements('li');
  print(liList.join('\n'));

  final firstComment =parserResult.getCommentAt(0);
  print(firstComment);

 print(parserResult.getComments().join('\n'));*/

  // SimpleSmartParserResult parserResult = SimpleSmartParser.parse(data);
  // List<Element> list = parserResult.getElements('li');
  //var toClean = list.map((element)=> element.toString()).toList().join('\n');
//print(toClean);
  /* print(await p.clean(
      keepAttributes: {'href'},
      keepTags: {'li', 'a'},
      input: data));*/

  //
  //
  // print(p.getParserResults(parser: p.anyElement(except: {'section','a','h5','ul'}), input: data));

  //print(p.getParserResults(parser: p.attribute('class'), input: '<li class="" chura><a href="/applications.html">Applications</a></li>'));

  // print(p.removeAttributes(input: '<li class="" ><a href="/applications.html">Applications</a></li>',attributes: {'class'}));

  // print(await p.keepAttributes(attributes:{'rel'}, input: '<link href="/font-awesome.min.css" rel="stylesheet" type="text/css" />')); // <link href="/font-awesome.min.css" rel="stylesheet"  />
/*  SimpleSmartParserResult parserResult = SimpleSmartParser.parse(p.cleanSync(
      keepTags: {'tr', 'td'},
      input: await download(
          'http://localhost/primary/2019/shl_ps0101008-UPPER.htm')));
  List<Element> trs = parserResult.getElements('tr');
  print(trs.join('\n'));
*/
/*
  var parserResult = SimpleSmartParser.parse(await getCleanedHtml(
      'http://localhost/primary/2019/shl_ps0101008-UPPER.htm',
      keepTags: ['tr', 'td']));
  var trs = p.cleanSync(
      keepTags: {'tr', 'td'}, input: parserResult.getElements('tr').join('\n'));
  print(trs);
*/
  //print(p.hasAttributes('<a href="qwerty">'));

  /*
  print(p.getParserResults(
      parser: ElementStartTagParser(
          tags: {"h5"}, attributes: {}, isClosed: false, limit: 1),
      input: await download(
          'http://localhost/dashboard/howto_shared_links.html')));*/
  // print(await p.keepAttributes(attributes:{'src'}, input:await download('http://localhost/dashboard/howto_shared_links.html')));
}

//((<($tag)[^<>]*>).*(<[^<>]*/($tag)>))
class SSmartScraperRegEx {
  static RegExp elementRegExp(String tag) {
    return RegExp(r'(</[^<>]*>)'); //RegExp('''(<[^<>]*>)''');
  }
}
