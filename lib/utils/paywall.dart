import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:rizz_mobile/constant.dart';

Future<PaywallResult> presentPaywall() async {
  final paywallResult = await RevenueCatUI.presentPaywall();
  debugPrint('Paywall result: $paywallResult');
  return paywallResult;
}

Future<PaywallResult> presentPaywallIfNeeded() async {
  final PaywallResult paywallResult = await RevenueCatUI.presentPaywallIfNeeded(
    entitlementID,
  );
  debugPrint('Paywall result: $paywallResult');
  return paywallResult;
}
