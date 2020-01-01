A simple smart data scraping library.

## Usage

Import the package into your Dart code using:

```dart

import 'package:simple_smart_scraper/simple_smart_scraper.dart';

```
Below are step by step instructions of how to write your first data scraper using ``` simple_smart_scraper package ```.

Before starting our tutorials, let's first define Data Scraping.
According to www.wikipedia.com , Data scraping is a technique in which a computer program extract data from human-readable output coming from another program.

                Tutorials
                ---------

First locate your target data to scrape , Our target data is the html string below.

```text
final html_data =
```
```html
                     <h2>MagabeLab</h2>
                     <h1><i>Welcome</i></h1>
                     <tbody>
                     <td><a href="link1" color="black">Home</a></td>
                     <td><a href="link2" color="white">Info</a></td>
                     </tbody>
```

For remote data such as html pages that need to be cleaned first, use ```getCleanedHtml``` function
that download and provides options for cleaning the downloaded html data.

```dart

var cleanedHtm = await getCleanedHtml('data-url', keepTags: const <String>[
    'a',
    'td',
    'h1',
    'h2',
    'h3',
    'table',
    'body',
    'tr'
  ]);

```

                Tutorial 1: Parsers
                ------------------------

A parser class that provide the parsers to parse our data

```dart

class MyParser with ParserMixin {
  //A parser to parse h2 tag  //<h2>MagabeLab</h2>
  //Use element function and provide a tag name as follows
  Parser titleParser() => element('h2');

  //A parser to parse Welcome text //<h1><i>Welcome</i></h1>
  //Here i use parentElement function and pass h1 as a tag
  Parser welcomeParser() => parentElement('h1', element('i'));

  //A parser to parse <td><a href="xxx">xxx</a></td>
  Parser tdParser() => parentElement('td', element('a'));

  //A parser to parse a tbody tag from the data, tbody has 2 child element both td elements, so i use repeat
  Parser tbodyParser() => parentElement('tbody', repeat(tdParser(), 2));

  //Return MagabeLab text from h2 tags
  String getTitle(String input) {
    String h2 = getParserResult(parser: titleParser(), input: input);
    return getElementText(tag: 'h2', input: h2);
  }

  //Return Welcome text from i tags
  String getWelcomeText(String input) {
    String h1 = getParserResult(parser: welcomeParser(), input: input);
    String i = getParserResult(parser: element('i'), input: h1);
    return getElementText(tag: 'i', input: i);
  }

  String tbody(String input) =>
      getParserResult(parser: tbodyParser(), input: input);

  Map<String, String> getLinkAndName(String input) {
    Map<String, String> map = <String, String>{};
    var tdList = getParserResults(parser: tdParser(), input: tbody(input));
    for (var td in tdList) {
      var a = getParserResult(parser: element('a'), input: td);
      var name = getElementText(tag: 'a', input: a);
      var href = getAttributeValue(tag: 'a', attribute: 'href', input: a);
      if (name.isNotEmpty && href.isNotEmpty) {
        map[name] = href;
      }
    }
    return map;
  }

  //Just for fun ,using fast-lazy method
  String getLinkBasedColorAttribute(String color, String input) {
    var aList = getParserResults(parser: element('a'), input: input);
    for (var a in aList) {
      var c = getAttributeValue(tag: 'a', attribute: 'color', input: a);
      bool match = nonCaseSensitiveChars(c)
          .accept(color.trim()); //notice this match call
      if (match) {
        return getAttributeValue(tag: 'a', attribute: 'href', input: a);
      }
    }
    return '';
  }
}

```

Now we are ready to try our parsers

```dart

  MyParser _myParser = MyParser();

  print(_myParser.getTitle(html_data)); //MagabeLab

  print(_myParser.getWelcomeText(html_data)); //Welcome

  print(_myParser.tbody(html_data));       //<tbody>
                                           //<td><a href="link1">Home</a></td>
                                           //<td><a href="link3" color="white">Info</a></td>
                                           //</tbody>

  print(_myParser.getLinkAndName(html_data));    //{Home: link1, Info: link2}

  print(_myParser.getLinkBasedColorAttribute('black', html_data));    //link1
  print(_myParser.getLinkBasedColorAttribute('white', html_data));    //link2

  //Even these calls still return appropriate results because of our awesome match algorithm
  print(_myParser.getLinkBasedColorAttribute('WHITE', html_data));     //link2
  print(_myParser.getLinkBasedColorAttribute('whIte', html_data));     //link2
  print(_myParser.getLinkBasedColorAttribute('Black', html_data));     //link1

```


Is it possible to write some kind of a decoder that will decode html page data to dart object on the fly ?
The Answer is YES, let's see the following tutorial

                Tutorial 2: Decoder
                ----------------------
Again our data

```text
final html_data =
```
```html
                     <h2>MagabeLab</h2>
                     <h1><i>Welcome</i></h1>
                     <tbody>
                     <td><a href="link1" color="black">Home</a></td>
                     <td><a href="link2" color="white">Info</a></td>
                     </tbody>
```


A decoder that decode our data and return a ```Link``` model with data ```(href,color, name)```
The data is obtained from an ```'a'``` element that looks like 
```html
 <a href="link2" color="white">Info</a>
```

Introducing our model class

```dart

class Link {
  String href;
  String color;
  String name;

  Link(this.href, this.color, this.name);

  @override
  String toString() {
    return '{href:$href, color:$color name:$name}';
  }
}

```

The  decoder class

```dart

class MyDecoder extends Decoder<Link> {
  @override
  Link mapParserResult(String result) {
    var name = getElementText(tag: 'a', input: result);
    var href = getAttributeValue(tag: 'a', attribute: 'href', input: result);
    var color = getAttributeValue(tag: 'a', attribute: 'color', input: result);
    if (name.isNotEmpty && href.isNotEmpty && color.isNotEmpty) {
      return Link(href, color, name);
    }
    return null;
  }

  @override
  Parser get parser => element('a');
}

```

Now our decoder is ready to use and there are many ways to use it, here i only show two

```dart

  MyDecoder _mydecoder = MyDecoder();

  ```

                Method 1: calling the decoder's decode method
                ----------------------------------
```dart

  _mydecoder.decode(html_data).listen((link) {
    print(link);
  }, onDone: () {
    print('done! Method 1');
  });
```
```text
  The above call chain print the following

  {href:link1, color:black name:Home}
  {href:link2, color:white name:Info}
  done! Method 1
```


                Method 2: passing the decoder to a stream transform function
                ----------------------------------------------------------------

First our ```toStream``` function , you don't need to write your own, the library already provided  you with
 a nice ```stringToStream``` function that you can use.

```dart

  Stream<String> toStream(txt) async* {
    yield txt;
  }

```

Now we are ready for method 2.

```dart

  toStream(html_data).transform(_mydecoder).expand((i) => i).listen((link) {
    print(link);
  }, onDone: () {
    print('done! Method 2');
  });
```
```text
  The above call chain print the following

  {href:link1, color:black name:Home}
  {href:link2, color:white name:Info}
  done! Method 2
```


                Tutorial 3: DecoderBloc
                -----------------------------

```simple_smart_scraper``` comes with ```DecoderBloc```, a class that help you integrate your data scraping logic
into flutter applications, Bloc creation is simple let's see how.

A Bloc (Business Logic Component) is like a pipe, Events go in and States come out.

First, we create data structures to represent bloc events ,
here i am using an enum ,you can use a class to represent bloc events if you want to.

```dart

enum MyBlocEvent { title, welcome, link, done }

```

Second, we create data structures to represent bloc states.

```dart

class MyBlocState {}

//NOTE: Use libraries like equatable to avoid overriding  operator == and hashCode methods.

class TitleState extends MyBlocState {
  String title;
  TitleState(this.title);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TitleState &&
          runtimeType == other.runtimeType &&
          title == other.title;

  @override
  int get hashCode => title.hashCode;
}

class WelcomeState extends MyBlocState {
  String welcome;
  WelcomeState(this.welcome);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WelcomeState &&
          runtimeType == other.runtimeType &&
          welcome == other.welcome;

  @override
  int get hashCode => welcome.hashCode;
}

class LinkState extends MyBlocState {
  Link link;
  LinkState(this.link);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkState &&
          runtimeType == other.runtimeType &&
          link == other.link;

  @override
  int get hashCode => link.hashCode;
}

class CompletedState extends MyBlocState {}


```
Now we are ready to implement our bloc.

```dart

class MyBloc extends DecoderBloc<MyBlocEvent, MyBlocState> {
  MyDecoder _decoder = MyDecoder();
  MyParser _myParser = MyParser();
  String _welcome = '';
  String _title = '';
  List<Link> links = <Link>[];

  @override
  Future<void> load(String input, {String baseUrl}) {
    _welcome = '';
    _title = '';
    links.clear();
    return super.load(input, baseUrl: baseUrl);
  }

  @override
  void dispatchEvents(String input, {String baseUrl}) {
    _welcome = _myParser.getWelcomeText(input);
    if (_welcome.isNotEmpty) {
      dispatchEvent(MyBlocEvent.welcome);
    }
    _title = _myParser.getTitle(input);
    if (_title.isNotEmpty) {
      dispatchEvent(MyBlocEvent.title);
    }

    decode(
      input: input,
      decoder: _decoder,
      listener: links.add,
      onDone: () {
        dispatchEvent(MyBlocEvent.link);
        dispatchDelayedEvent(Duration(seconds: 1), MyBlocEvent.done);
      },
    );
  }

  @override
  Stream<MyBlocState> mapEventToState(MyBlocEvent event) async* {
    switch (event) {
      case MyBlocEvent.welcome:
        if (_welcome.isNotEmpty) {
          yield WelcomeState(_welcome);
        }
        break;
      case MyBlocEvent.title:
        if (_title.isNotEmpty) {
          yield TitleState(_title);
        }
        break;
      case MyBlocEvent.link:
        for (var link in links) {
          yield LinkState(link);
        }
        break;
      case MyBlocEvent.done:
        yield CompletedState();
        complete(); //must call complete() when done for the bloc to be able to reload or load new input
        break;
    }
  }
}

```
Now that our bloc is ready, let's use it.

```dart

  MyBloc mybloc = MyBloc();

  mybloc.listen((state){
    print('State = $state');
  });

  mybloc.load(html_data);
```
```text
    The above print the following

      State = Instance of 'WelcomeState'
      State = Instance of 'TitleState'
      State = Instance of 'LinkState'
      State = Instance of 'LinkState'
      State = Instance of 'CompletedState'
```

```dart

MyBloc()
    ..listen((state) {
      if (state is WelcomeState) {
        print(state.welcome);
      } else if (state is TitleState) {
        print(state.title);
      } else if (state is LinkState) {
        print(state.link);
      } else if (state is CompletedState) {
        print('MyBloc completed');
      }
    })
    ..load(html_data);

 ```
 ```text
      The above print the following

        Welcome
        MagabeLab
        {href:link1, color:black name:Home}
        {href:link2, color:white name:Info}
        MyBloc completed

```

                Recipes 101
                ---------------

```dart

  var p = MyParser();

  //get element text using getElementText
  print(p.getElementText(tag: 'b', input: '<b>Hello word</b>')); //Hello word


  //get element attributes values using getAttributeValue
  print(p.getAttributeValue(
      tag: 'A',
      attribute: 'HREF',
      input: '<div><a href="#link"></a></div>')); //#link

 
```
```text
final String html1 = 
```
```html
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
          <link href="/font-awesome.min.css" rel="stylesheet" type="text/css" />
          <script src="/dashboard/javascripts/modernizr.js" type="text/javascript"></script>
          <body<div><a href="#link"></a></div> <div><b>Nancy</b></div>
```
```dart

  //parse meta information from string html1
  //get meta tag
  Parser metaParser = p.elementStartTag(tag: 'meta');
  String meta = p.getParserResult(parser: metaParser, input: html1);
  print(meta); //<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">


  //get content attribute from meta tag
  String content = p.getAttributeValue(tag: 'meta', attribute: 'content', input: meta);
  print(content); // text/html; charset=UTF-8


  Parser linkParser = p.elementStartTag(tag: 'link', isClosed: true);
  String link = p.getParserResult(parser: linkParser, input: html1);
  print(link); //<link href="/font-awesome.min.css" rel="stylesheet" type="text/css" />


  print(p.getElementText(tag: 'b', input: html1)); //Nancy


  print(p.getAttributeValue(tag: 'script', attribute: 'type', input: html1)); //text/javascript

  //print all element tags
  print(p.getElementTags(html1)); // {meta, link, script, a, div, b}


  print(p.getElementAttributes(parser: metaParser, input: html1)['http-equiv']); // Content-Type


  print(p.hasAttribute(tag: 'meta', attribute: 'href', input: meta)); // false
  print(p.hasAttribute(tag: 'meta', attribute: 'http-equiv', input: meta)); // true


  //remove attributes
   print(p.removeAttributes(attributes:{'rel','href'}, input: '<link href="/font-awesome.min.css" rel="stylesheet" type="text/css" />')); // <link   type="text/css" />


  //keep attributes
  print(await p.keepAttributes(attributes:{'rel','href'}, input: '<link href="/font-awesome.min.css" rel="stylesheet" type="text/css" />')); // <link href="/font-awesome.min.css" rel="stylesheet"  />


  //remove using parsers
  print(p.remove(parsers: [p.parentElement('div', p.element('a'))], input: '<body http-equiv="Content-Type" href="er"><div><a href="#link"></a></div> <div><b>Nancy</b></div></body>')); // <body http-equiv="Content-Type" href="er"> <div><b>Nancy</b></div></body>


  var result;
  try {
    result = p.stripRepeat('<div><a>My Name is ...</a></div>', 1);
  } on StripException catch (e) {
    result = e.output;
  }finally{
    print('$result');  // <a>My Name is ...</a>
  }

  try {
    result = p.stripRepeat('<div><a>My Name is ...</a></div>', 2);
  } on StripException catch (e) {
    result = e.output;
  }finally{
    print('$result');  // My Name is ...
  }


    //remove tags

    var html = await p.removeTags(
      tags: {'body', 'div'},
      input: html1,
      finalizer: (output) {
        //remove the meta tag
        var meta = p.getParserResult(
            parser: p.elementStartTag(tag: 'meta'), input: output);
        return Future.value(output.replaceAll(meta, ''));
      });

    print(html);


    var html2 = await p.removeTags(
      tags: {'body', 'div'},
      input: html1,
      finalizer: (output) async {
        //remove the meta tag
        var meta = p.getParserResult(
            parser: p.elementStartTag(tag: 'meta'), input: output);

        output = output.replaceAll(meta, '');
        //only keep href attribute
        output = await p.keepAttributes(attributes: {'href'}, input: output);
        return Future.value(output);
      });

    print(html2);


    //Getting any element with anyElement function

    print(p.getParserResults(
      parser: p.anyElement(except: {'div'}),
      input: '<div><a href="#link">link</a></div>',       // [<a href="#link">link</a>]
    ));


    print(p.getParserResults(
      parser: p.anyElement(),
      input: '<div><a href="#link">link</a></div>',       // [<a href="#link">link</a>, <div><a href="#link">link</a></div>]
    ));

    //Data Cleaning
```

```text
 var input = 
```
 ```html
                <table>
                 <h1><p>NATIONAL EXAMINATIONS COUNCIL OF TANZANIA</p></h1>
                 <h2>CHURA SCHOOL - PS1907062</h2>
                 <tr><td >CAND. NO</td>
                 <td  >SEX</td>
                 <td  >CANDIDATE NAME</td>
                 <td  >SUBJECTS</td></tr>
                 <tr>
                 </table>
```
         

  

```dart
   print(p.cleanSync(
       keepTags: {'tr', 'td', 'h2', 'h1'},
       input: input,
       finalizer: (output) {   // hard remove the h1 tag
         return p.remove(parsers: [p.element('h1')], input: output);
       }));                                                //<h2>CHURA SCHOOL - PS1907062</h2>
                                                           //<tr><td >CAND. NO</td>
                                                           //<td  >SEX</td>
                                                           //<td  >CANDIDATE NAME</td>
                                                           //<td  >SUBJECTS</td></tr>

       print(await p.clean(
              keepTags: {'tr', 'td', 'h2'}, //notice h1 is not included
              input: input,
              ));                                                //<h2>CHURA SCHOOL - PS1907062</h2>
                                                                  //<tr><td >CAND. NO</td>
                                                                  //<td  >SEX</td>
                                                                  //<td  >CANDIDATE NAME</td>
                                                                  //<td  >SUBJECTS</td></tr>
                                                                  
 ```

```text
final data = 
```
```html
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
```
Removing Comments        
```dart

    var p = MyParser();

      //Using removeComments method
      print(p.removeComments(data));

      //Using anyElement(except) method by providing a "comment" or "comments" as exception ;eg;-
   final unQualifiedElements = ['h5','ul'];
   final qualifiedElements  =  getParserResults(
            parser: anyElement(except: {'comments',...unQualifiedElements}),  // notice another exception "comments"
            input: data,
          );
```
```text
    
    Note: anyElement returns overlapping elements, if you don't want that
    --------------------------------------------------------------------

    <i>  You can filter the results using

            List<String> filterOutRepeatedElements(List<String> elements);

    <ii> Or Use String getElements({
               Set<String> except = const <String>{},
               @required String input,
             });

    getElements uses filterOutRepeatedElements to filter, and return a String containing non-overlapping elements
  

```
```clean``` and ```cleanSync``` methods

```dart

      print(await p.clean(
        keepAttributes: {'href'},
          keepTags: {'li', 'a'},
          input: data));

      print( p.cleanSync(
          keepAttributes: {'href'},
          keepTags: {'li', 'a'},
          input: data));
```
```text
             All 2 calls ,print the following output
```
```html
        <li  chura><a href="/applications.html">Applications</a></li>
        <li ><a  href="/dashboard/phpinfo.php">PHPInfo</a></li>
        <li ><a href="/phpmyadmin/">phpMyAdmin</a></li>
        <a href="/dashboard/docs/reset-mysql-password.html">Reset the MySQL/MariaDB Root Password</a>
        <a href="/dashboard/docs/send-mail.html">Send Mail with PHP</a>
```
```text
    Note: clean/cleanSync also remove comments and filter-out overlapping elements.
```

                 Dictionary Based Parsing(DBP) Using SimpleSmartParser
                 -----------------------------------------------------
Use ```SimpleSmartParser``` and ```SimpleSmartParserResult``` to directly target any element using dictionary based access .

```dart

  SimpleSmartParserResult parserResult = SimpleSmartParser.parse(data);

  List<Element> liList = parserResult.getElements('li');
  print(liList.join('\n'));
  ```
```text
                print the following output
```
```html
  <li class="" chura><a href="/applications.html">Applications</a></li>
  <li class=""><a target="_blank" href="/dashboard/phpinfo.php">PHPInfo</a></li>
  <li class=""><a href="/phpmyadmin/">phpMyAdmin</a></li>
```

```dart
  //Getting the comments
  final firstComment = parserResult.getCommentAt(0);
  print(firstComment);     // <!-- this is a comment -->

  print(parserResult.getComments().join('\n'));

```
```text
                print all parsed comments

    <!-- this is a comment -->
    <!-- Right Nav Section -->
```
```dart
 //Other Elements
  print(parserResult.getOtherElements());    //[<br>]

```



                Exam Results Example
                -----------------------------
This example demonstrate how to combine two wonderful ```http``` and ```simple_smart_scraper``` packages to download, clean , parse and decode html into dart objects.
After our example is completed , invoking the following code


```dart

var client = http.Client();
  var res = await client.send(http.Request('get', Uri.parse(url)));
  res.stream
      .transform(Utf8Decoder())
      .transform(ResultsDecoder())
      .expand((i) => i)
      .listen((results) {

    print('**${results.school}***\n\n');

    results.candidateResults.forEach((candidateResult){
         print('${candidateResult.name} -  ${candidateResult.no}');
    });

  });

```

- Download html data from a website
```text
 var url = 'https://raw.githubusercontent.com/magabe26/mgb/master/exam_results.htm';
  ```
     With the following markup
 ```html


<html><head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
</head><body vlink="#800080" text="#000080" link="#0000ff" bgcolor="LIGHTBLUE">
<font color="#800080"><h2>NATIONAL EXAMINATIONS COUNCIL OF TANZANIA</h2>
<h1><p align="LEFT"> PSLE 2017 EXAMINATION RESULTS</p></h1>
<h3><p align="LEFT">NSIMBA PRIMARY SCHOOL - PS1907062
</p></h3>
<p align="LEFT">
CANDIDATES  : 24
<br>
SCHOOL Average   : 173.0417
<br>
<br>
<table width="80%" cellspacing="2" border="" bgcolor="LIGHTYELLOW" align="LEFT">
<tbody><tr><td width="10%">
<p align="CENTER">
<b><font size="2" face="Courier"></font></b></p><p align="CENTER"><b><font size="2" face="Courier">CAND. NO</font></b></p></td>
<td width="5%" valign="MIDDLE">
<b><font size="2" face="Courier"></font></b><font size="2" face="Courier"></font><p align="CENTER"><font size="2" face="Courier"><b>SEX</b></font></p></td>
<td width="30%" valign="MIDDLE">
<b><font size="2" face="Courier"></font></b><font size="2" face="Courier"></font><p align="CENTER"><font size="2" face="Courier"><b>CANDIDATE NAME
</b></font></p></td>
<td width="60%" valign="MIDDLE">
<b><font size="2" face="Courier"></font></b><font size="2" face="Courier"></font><p align="LEFT"><font size="2" face="Courier"><b>SUBJECTS
</b></font></p></td></tr>
<tr><td width="10%" valign="MIDDLE">
<font size="1" face="Arial"></font><p align="CENTER"><font size="1" face="Arial">PS1907062-001</font></p></td>
<td width="5%" valign="MIDDLE">
<font size="1" face="Arial"></font><p align="CENTER"><font size="1" face="Arial">M</font></p></td>
 <td width="30%" valign="LEFT">
<font size="1" face="Arial"></font><p><font size="1" face="Arial">WINONA DUSTIN</font></p></td>
<td width="58%" valign="MIDDLE">
<font size="1" face="Arial"></font><p align="LEFT"><font size="1" face="Arial">Kiswahili - B, English - B, Maarifa - C, Hisabati - B, Science - B, Average Grade - B</font></p></td></tr>
<tr><td width="10%" valign="MIDDLE">
<font size="1" face="Arial"></font><p align="CENTER"><font size="1" face="Arial">PS1907062-003</font></p></td>
<td width="5%" valign="MIDDLE">
<font size="1" face="Arial"></font><p align="CENTER"><font size="1" face="Arial">M</font></p></td>
 <td width="30%" valign="LEFT">
<font size="1" face="Arial"></font><p><font size="1" face="Arial">WALTER WHITE</font></p></td>
<td width="58%" valign="MIDDLE">
<font size="1" face="Arial"></font><p align="LEFT"><font size="1" face="Arial">Kiswahili - B, English - B, Maarifa - C, Hisabati - B, Science - B, Average Grade - B</font></p></td></tr>
<tr><td width="10%" valign="MIDDLE">
<font size="1" face="Arial"></font><p align="CENTER"><font size="1" face="Arial">PS1907062-024</font></p></td>
<td width="5%" valign="MIDDLE">
<font size="1" face="Arial"></font><p align="CENTER"><font size="1" face="Arial">M</font></p></td>
 <td width="30%" valign="LEFT">
<font size="1" face="Arial"></font><p><font size="1" face="Arial">MUFASSA SIMBA</font></p></td>
<td width="58%" valign="MIDDLE">
<font size="1" face="Arial"></font><p align="LEFT"><font size="1" face="Arial">Kiswahili - A, English - A, Maarifa - A, Hisabati - A, Science - A, Average Grade - A</font></p></td></tr>
</tbody></table>
</p></font></body></html>

```

- Invoke ``` String cleanResultsHtml(String html) ``` method , that will clean the above html and output the following cleaned html

```html

<h2>NATIONAL EXAMINATIONS COUNCIL OF TANZANIA</h2>
<h1>PSLE 2017 EXAMINATION RESULTS</h1>
<h3>NSIMBA PRIMARY SCHOOL - PS1907062</h3>
<tr><td >CAND. NO</td>
<td  >SEX</td>
<td  >CANDIDATE NAME</td>
<td  >SUBJECTS</td></tr>
<tr><td  >PS1907062-001</td>
<td  >M</td>
 <td  >WINONA DUSTIN</td>
<td  >Kiswahili - B, English - B, Maarifa - C, Hisabati - B, Science - B, Average Grade - B</td></tr>
<tr><td  >PS1907062-003</td>
<td  >M</td>
 <td  >WALTER WHITE</td>
<td  >Kiswahili - B, English - B, Maarifa - C, Hisabati - B, Science - B, Average Grade - B</td></tr>
<tr><td  >PS1907062-024</td>
<td  >M</td>
 <td  >MUFASSA SIMBA</td>
<td  >Kiswahili - A, English - A, Maarifa - A, Hisabati - A, Science - A, Average Grade - A</td></tr>

```

- Use the ``` ResultsParsers ```  and  ``` ResultsDecoder ```  to parse and decode the above  cleaned html
into a dart object  ``` Results ```
- And finally print following to the screen.

```text

**NSIMBA PRIMARY SCHOOL - PS1907062***


WINONA DUSTIN -  PS1907062-001
WALTER WHITE -  PS1907062-003
MUFASSA SIMBA -  PS1907062-024

```



Now let's study how the program is written.

```dart
import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:petitparser/petitparser.dart';
import 'package:simple_smart_scraper/simple_smart_scraper.dart';
import 'package:http/http.dart' as http;
```
```dart

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
   The tr element has 4 td element each containing  a text, the last td(index == 3 ) can be easy converted to a map

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
    toHtml(Parser parser) {
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

```

```dart

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

```

```dart

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

```

```ResultsDecoder``` can be implemented in two ways.

    Implementation 1: using  the forward() that return ForwardParser
    (forward() is preferred in situations where no data parsing/cleaning is needed)
    -------------------------------------------------------------

 ```dart

class ResultsDecoder extends Decoder<Results> {
  ResultsParsers _parsers = ResultsParsers();

  @override
  Results mapParserResult(String result) {
    return Results.fromHtml(_parsers.cleanResultsHtml(result));
  }

  ///Using forward() to forward the input to mapParserResult,
  ///In this case, mapParserResult is the one doing all the cleaning and parsing
  @override
  Parser get parser =>
      forward(); //forward return a parser that does'nt parse its input ,but only return the input as the result of the parse operation
}

```
```dart

Since our ResultsDecoder need to clean the html first using _parsers.cleanResultsHtml(...) before decoding it with
Results.fromHtml(...) , Implementation 2 is preferred in this situation.

```

     Implementation 2: using the intercepted method that return InterceptedParser ( preferred in this situation)
     -----------------------------------------------------------------------------------------------------------


```dart

class ResultsDecoder extends Decoder<Results> {
  ResultsParsers _parsers = ResultsParsers();

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

```

Running our program.

```dart


void main() async {

 var client = http.Client();
   var res = await client.send(http.Request('get', Uri.parse(url)));
   res.stream
       .transform(Utf8Decoder())
       .transform(ResultsDecoder())
       .expand((i) => i)
       .listen((results) {

     print('**${results.school}***\n\n');

     results.candidateResults.forEach((candidateResult){
          print('${candidateResult.name} -  ${candidateResult.no}');
     });

   });

}

```

    Alternative usage
```dart

  Results results = await Results.fromUrl(url);

  print(results.council);

  print(results.title);

  print(results.school);

  print(results.candidateResults);


```



