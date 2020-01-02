import 'dart:convert';
import 'package:simple_smart_scraper/petitparser_2.4.0.dart';
import 'package:simple_smart_scraper/simple_smart_scraper.dart';
import 'package:http/http.dart' as http;

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

  // final url = 'http://localhost/dashboard/howto_shared_links.html';

  // Results results = await Results.fromUrl(url);

  // print(results.council);

  // print(results.title);

  // print(results.school);

  //print(results.candidateResults);
}
