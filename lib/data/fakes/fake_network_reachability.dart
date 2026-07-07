import '../../core/network/network_reachability.dart';

/// Controle de conectividade para testes (ENI-84).
class FakeNetworkReachability implements NetworkReachability {
  FakeNetworkReachability({this.online = true});

  bool online;

  @override
  Future<bool> isOnline() async => online;
}
