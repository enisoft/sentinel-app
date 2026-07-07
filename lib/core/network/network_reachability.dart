import 'dart:async';
import 'dart:io';

/// Indica se há conectividade de rede (ENI-84).
abstract class NetworkReachability {
  Future<bool> isOnline();
}

/// Verifica conectividade via resolução DNS — sem deps extras.
class DnsNetworkReachability implements NetworkReachability {
  DnsNetworkReachability({
    this.lookupHost = 'one.one.one.one',
    this.timeout = const Duration(seconds: 3),
  });

  final String lookupHost;
  final Duration timeout;

  @override
  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup(lookupHost).timeout(timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on Object {
      return false;
    }
  }
}
