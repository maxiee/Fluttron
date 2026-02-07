bool get isFluttronHtmlViewSupported => false;

String ensureFluttronHtmlViewRegistered({
  required String type,
  List<dynamic>? args,
}) {
  throw UnsupportedError('FluttronHtmlView is only supported on Flutter Web.');
}
