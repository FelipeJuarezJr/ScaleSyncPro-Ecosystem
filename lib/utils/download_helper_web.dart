import 'dart:html' as html;

void downloadHtmlFile(String content, String fileName) {
  final bytes = html.Blob([content], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(bytes);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
