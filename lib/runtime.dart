import 'dart:io';
import 'dart:math' as Math;
import 'dart:json' as JSON;

var interp;
List<Debug> debug;

class Debug {
  String filename;
  int lineno;
  Debug({this.lineno, this.filename});
}

nulls(val) => val != null && val != '';

joinClasses(val) =>
  val is List ? val.map(joinClasses).where(nulls).join(' ') : val;

merge(Map a, Map b) {
  var ac = a['class'];
  var bc = b['class'];

  if (ac != null || bc != null) {
    if (ac == null) ac = [];
    if (bc == null) bc = [];
    if (ac is! List) ac = [ac];
    if (bc is! List) bc = [bc];
    a['class'] = (ac..addAll(bc)).where(nulls).toList();
  }

  for (var key in b.keys) {
    if (key != 'class') {
      a[key] = b[key];
    }
  }

  return a;
}  
  
String attrs(Map obj, [Map escaped]){
  var buf = [];
  bool terse = obj['terse'];

  obj.remove('terse');
  List<String> keys = obj.keys.toList();
  int len = keys.length;

  if (len > 0) {
    buf.add('');
    for (var i = 0; i < len; ++i) {
      String key = keys[i];
      var val = obj[key];

      if (val is bool || null == val) {
        if (val != null && val) {
          if (terse != null && terse)
            buf.add(key);
          else
            buf.add('$key="$key"');
        }
      } else if (0 == key.indexOf('data') && val is! String) {
        buf.add("$key='${JSON.stringify(val)}'");
      } else if ('class' == key) {
        if ((val = escape(joinClasses(val))) != null) {
          buf.add('$key="$val"');
        }
      } else if (escaped != null && escaped[key] != null) {
        buf.add('$key="${escape(val)}"');
      } else {
        buf.add('$key=$val"');
      }
    }
  }

  return buf.join(' ');
}

escape(html) => "$html"
  .replaceAll("&", '&amp;')
  .replaceAll("<", '&lt;')
  .replaceAll(">", '&gt;')
  .replaceAll('"', '&quot;');

rethrows(err, filename, lineno){
//  print("filename: $filename, lineno: $lineno, err: $err");
  if (filename == null || filename == "undefined") throw err;
//  if (typeof window != 'undefined') throw err;

  var context = 3;
  String str = new File(filename).readAsStringSync();
  List<String> lines = str.split('\n');
  int start = Math.max(lineno - context, 0);
  int end = Math.min(lines.length, lineno + context);

  // Error context
  int i = 0;
  context = lines.sublist(start, end).map((String line){
    var curr = i++ + start + 1;
    return (curr == lineno ? '  > ' : '    ')
      + curr
      + '| '
      + line;
  }).join('\n');

  // Alter exception message
  err.path = filename;
  err.message = (filename != null ? filename : 'Jade') + ':' + lineno
    + '\n' + context + '\n\n' + err.message;
  throw err;
}

