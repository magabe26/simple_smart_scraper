/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:convert';
import 'downloader.dart' as html_downloader;

///A tag that contains non-results information
class DirtyTag extends Equatable {
  final String start;
  final String end;

  @override
  List<Object> get props => [start, end];

  const DirtyTag({@required this.start, @required this.end});

  @override
  String toString() {
    return 'DirtyTag${jsonEncode(<String, dynamic>{
      'start': start,
      'end': end
    })}';
  }
}

final _commonDirtTags = <DirtyTag>{
  const DirtyTag(start: '<meta', end: '>'),
  const DirtyTag(start: '<script', end: '</script>'),
  const DirtyTag(start: '<div', end: '</div>'),
  const DirtyTag(start: '<title>', end: '</title>'),
  const DirtyTag(start: '< rel', end: '>'),
  const DirtyTag(start: '<rel', end: '>'),
  const DirtyTag(start: '<style>', end: '</style>'),
  const DirtyTag(start: '<link', end: '>'),
  const DirtyTag(start: '<!', end: '->'),
};

class RemoveTagResult {
  final int tagRemoved;
  final String html;

  const RemoveTagResult(this.tagRemoved, this.html);
}

class RemoveTagFailed implements Exception {
  final String startTag;
  final String endTag;
  String _html;

  RemoveTagFailed({@required this.startTag, @required this.endTag});

  set html(String html) => _html = html;

  String get html => _html;

  @override
  String toString() {
    return 'RemoveTagFailed !, startTag: $startTag , endTag: $endTag';
  }
}

Future<RemoveTagResult> removeDirtyTag(String input, DirtyTag dirtyTag) {
  // ignore: omit_local_variable_types
  int startTagIndex = -1;
  // ignore: omit_local_variable_types
  bool error = false;
  // ignore: omit_local_variable_types
  int tagRemoved = 0;
  // ignore: omit_local_variable_types
  String sTag = dirtyTag.start;
  // ignore: omit_local_variable_types
  String eTag = dirtyTag.end;
  // ignore: omit_local_variable_types
  int nLoop = 1;
  // ignore: omit_local_variable_types
  String formattedHtml = input;
  // ignore: omit_local_variable_types
  final RemoveTagFailed exception =
      RemoveTagFailed(startTag: dirtyTag.start, endTag: dirtyTag.end);

  void remove() {
    while ((startTagIndex = formattedHtml.indexOf(sTag)) != -1) {
      // ignore: omit_local_variable_types
      int endTagIndex = formattedHtml.indexOf(eTag, startTagIndex);
      if (endTagIndex == -1) {
        error = true;
        break;
      } else {
        formattedHtml = formattedHtml.replaceRange(
            startTagIndex, (endTagIndex + eTag.length), '');
        tagRemoved++;
      }
    }
  }

  remove();

  if (nLoop < 2) {
    nLoop++;
    //look for upperCase ones
    sTag = dirtyTag.start.toUpperCase();
    eTag = dirtyTag.end.toUpperCase();
    remove();
  }

  if (error) {
    exception.html = formattedHtml;
    throw exception;
  } else {
    return Future<RemoveTagResult>.value(
        RemoveTagResult(tagRemoved, formattedHtml));
  }
}

Future<String> removeDirtyTags(String html, Set<DirtyTag> tags) async {
  if (tags != null && tags.isNotEmpty) {
    var tmp = html;
    // ignore: omit_local_variable_types
    for (DirtyTag tag in tags) {
      try {
        tmp = (await removeDirtyTag(tmp, tag)).html;
      } on RemoveTagFailed catch (e) {
        tmp = e.html;
      }
    }
    return tmp;
  } else {
    return html;
  }
}

String getTagFromAttributeMatch(String matchInput, int matchStartIndex) {
  final startIndex =
      matchInput.lastIndexOf(RegExp(r'(<[\w]*\d*)'), matchStartIndex);
  if (startIndex != -1) {
    final endIndex = matchInput.indexOf(RegExp(r'\s'), startIndex);
    if (endIndex != -1) {
      return matchInput.substring(startIndex, endIndex).replaceAll('<', '');
    }
  }
  return '';
}

Future<String> removeAttributes(String input,
    {List<String> keepAttributes = const <String>['href']}) {
  return removeAttributesImpl(input, keepAttributes: keepAttributes);
}

///////////////////////////////////////
Future<String> removeAttributesImpl(
  String input, {
  List<String> tags = const <String>[],
  List<String> keepAttributes = const <String>[],
}) {
  // ignore: omit_local_variable_types
  String formatted = input;

  var completer = Completer<String>();

  bool shouldKeepAttribute(Match match) {
    final tag = getTagFromAttributeMatch(match.input, match.start);
    if (tags.contains(tag)) {
      if (match.groupCount >= 1) {
        var arry = match[0].split('=');
        if (arry.length == 2) {
          var attr = arry[0];
          return keepAttributes.contains(attr) ||
              keepAttributes.contains(attr.toLowerCase()) ||
              keepAttributes.contains(attr.toUpperCase());
        } else {
          return false;
        }
      } else {
        return false;
      }
    }
    return false;
  }

  void removeSimpleAttributes() {
    formatted = formatted.replaceAllMapped(
        RegExp(r'(\w+=\s?\"?#?\w+%?\"?)', caseSensitive: false), (Match m) {
      return shouldKeepAttribute(m) ? m[0]?.trim() : '';
    });
  }

  void removeEmptyAttributes() {
    formatted = formatted.replaceAllMapped(
        RegExp(r'(\w+=\"\")', caseSensitive: false), (Match m) {
      return shouldKeepAttribute(m) ? m[0]?.trim() : '';
    });
  }

  void removeComplexAttributes() {
    formatted = formatted.replaceAllMapped(
        RegExp(r'(\w+=\s?\"?.+\"?)', caseSensitive: false), (Match m) {
      return shouldKeepAttribute(m) ? m[0]?.trim() : '';
    });

    completer.complete(formatted);
  }

  removeSimpleAttributes();
  removeEmptyAttributes();
  removeComplexAttributes();

  return completer.future;
}

////////////////////////////////////////////////////
Future<String> removeEmptyTags(String input,
    {List<String> keepTags = const <String>[
      'a',
      'td',
      'h1',
      'h2',
      'h3',
      'table',
      'body'
    ]}) {
  // ignore: omit_local_variable_types
  String formatted = input;

  var completer = Completer<String>();

  bool shouldKeep(Match match) {
    if (match.groupCount >= 1) {
      var tag = match[0]
          .replaceAll('<', '')
          .replaceAll('>', '')
          .replaceAll('\\', '')
          .replaceAll('/', '')
          .trim();

      return keepTags.contains(tag) ||
          keepTags.contains(tag.toLowerCase()) ||
          keepTags.contains(tag.toUpperCase());
    } else {
      return false;
    }
  }

  void removeStartWithEmptyTag() {
    formatted = formatted.replaceAllMapped(
        RegExp(r'(<\w+\s+>)', caseSensitive: false), (Match m) {
      return shouldKeep(m) ? m[0]?.trim() : '';
    });
  }

  void removeStartWithNoEmptyTag() {
    formatted = formatted
        .replaceAllMapped(RegExp(r'(<\w+>)', caseSensitive: false), (Match m) {
      return shouldKeep(m) ? m[0]?.trim() : '';
    });
  }

  void removeEndTag() {
    formatted = formatted
        .replaceAllMapped(RegExp(r'(</\w+>)', caseSensitive: false), (Match m) {
      return shouldKeep(m) ? m[0]?.trim() : '';
    });

    completer.complete(formatted);
  }

  removeStartWithEmptyTag();
  removeStartWithNoEmptyTag();
  removeEndTag();

  return completer.future;
}

class GetCleanedHtmlFailed implements Exception {
  String message;
  GetCleanedHtmlFailed(this.message);

  @override
  String toString() {
    return message;
  }
}

String _replaceTable(String html) {
  return html
      .replaceAll('TABLE BORDER ', 'TABLE')
      .replaceAll('table border', 'table');
}

///The returned html may be xml-compatible or not
///if you wish to keep one or more CommonDirtTags , set  removeCommonDirtTags = false
Future<String> getCleanedHtml(
  String url, {
  Set<DirtyTag> dirtyTags,
  List<String> keepTags = const <String>[
    'a',
    'td',
    'h1',
    'h2',
    'h3',
    'table',
    'body'
  ],
  List<String> keepAttributes = const <String>['href'],
  bool removeCommonDirtTags = true,
}) async {
  try {
    var html = await html_downloader.download(url);

    if ((dirtyTags != null) && removeCommonDirtTags) {
      dirtyTags.addAll(_commonDirtTags);
    }

    html = await removeDirtyTags(html,
        removeCommonDirtTags ? (dirtyTags ?? _commonDirtTags) : dirtyTags);

    html = await removeAttributesImpl(
      html,
      tags: keepTags,
      keepAttributes: keepAttributes,
    );
    html = await removeEmptyTags(html, keepTags: keepTags);
    html = _replaceTable(html);

    try {
      return xml.parse(html).toXmlString(pretty: true);
    } catch (_) {
      return html;
    }
  } on html_downloader.DownloadFailed catch (e) {
    throw GetCleanedHtmlFailed('GetCleanedHtmlFailed, ${e.toString()}');
  }
}
