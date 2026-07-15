import 'package:flutter_test/flutter_test.dart';
import 'package:eventapp/core/crypto/qr_decryptor.dart';

void main() {
  test('decrypts Node.js ES1 payload', () async {
    const key =
        'b845e171de37b039624b2304ce3de93b59944aa587ab21c98348bbd2e7d7b958';
    const enc =
        'ES1:UBjydZNE89bGibVZ14OARhzFBiFC_cpbpNu4k2S8lvnefbH34x3ND7zVaQnppiU35ZEP_e9ofbSqDCjNZhnF1h2tBK3B8JPoe5dihoXCzG7DqksTRzqZQVi9SwrQQ_F59iKYQ4YQdmB5G75YPQCOUQ8bjQRf_6qYkGgMYa2GDH5SyRsQUzCYLe459BmrwUKB7_rJjAVd';

    final guest = await QrDecryptor.decrypt(enc, key);

    expect(guest, isNotNull);
    expect(guest!.name, 'Jane Doe');
    expect(guest.phone, '+255712345678');
  });
}
