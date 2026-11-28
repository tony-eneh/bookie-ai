import 'package:bookie_ai/data/services/sms_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bank alerts are recognised', () {
    expect(looksLikeBankAlert('Debit Alert: NGN 4,500.00 spent at SHOPRITE'), isTrue);
    expect(looksLikeBankAlert('Acct 123***89 credited with ₦150,000.00 by EMEKA'), isTrue);
    expect(looksLikeBankAlert('[KB] 12,000 KRW POS purchase GS25'), isTrue);
    expect(looksLikeBankAlert('USD 10.00 payment to NETFLIX.COM'), isTrue);
  });

  test('OTPs, promos and chat are ignored', () {
    expect(looksLikeBankAlert('Your OTP is 482913. Do not share. NGN 0.00'), isFalse);
    expect(looksLikeBankAlert('Get 50% off this weekend at Shoprite!'), isFalse);
    expect(looksLikeBankAlert('See you at 7 tonight'), isFalse);
  });
}
