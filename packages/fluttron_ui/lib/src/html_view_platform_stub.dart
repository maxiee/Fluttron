bool get isFluttronHtmlViewSupported => false;

void ensureFluttronHtmlViewRegistered({
  required String viewType,
  required String jsFactoryName,
  List<dynamic>? jsFactoryArgs,
}) {
  throw UnsupportedError('FluttronHtmlView is only supported on Flutter Web.');
}
