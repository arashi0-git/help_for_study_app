import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

Future<String> recognizeMathpix(Uint8List imageBytes) async {
    const String appId = 'help_for_study_app_e73a81_b89836';
    const String appKey = '998594fedcbb7d5d46b898e4ab3ed5d9fdbf07019e28b9e3be76b98010e31548';

    final String base64Image = base64Encode(imageBytes);

    final response = await http.post(
        Uri.parse('https://api.mathpix.com/v3/text'),
        headers: {
            'app_id': appId,
            'app_key': appKey,
            'Content-Type': 'application/json',
        },
        body: jsonEncode({
            'src': 'data:image/png;base64,$base64Image',
            'formats': ['latex_simplified'],
            'ocr': ['math', 'text'],
        }),
    );

    if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['latex_simplified'] ?? '数式が見つかりませんでした';
    }
    return 'エラーが発生しました: ${response.statusCode}';
}
