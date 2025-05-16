import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

Future<String> recognizeMathpix(Uint8List imageBytes) async {
    const String appId = 'help_for_study_app_e73a81_b89836';
    const String appKey = '998594fedcbb7d5d46b898e4ab3ed5d9fdbf07019e28b9e3be76b98010e31548';

    final String base64Image = base64Encode(imageBytes);

    try {
        final response = await http.post(
            Uri.parse('https://api.mathpix.com/v3/text'),
            headers: {
                'app_id': appId,
                'app_key': appKey,
                'Content-Type': 'application/json',
            },
            body: jsonEncode({
                'src': 'data:image/png;base64,$base64Image',
                'formats': ['latex_simplified', 'latex'],
                'ocr': ['math', 'text'],
                'math_inline_delimiters': ['\$', '\$'],
                'math_display_delimiters': ['\$\$', '\$\$'],
                'math_confidence_threshold': 0.8,
                'text_confidence_threshold': 0.8,
                'image_processing': {
                    'contrast': 1.5,
                    'brightness': 1.0,
                    'sharpen': 2.0
                }
            }),
        );

        if (response.statusCode == 200) {
            final decoded = utf8.decode(response.bodyBytes);
            final data = json.decode(decoded);
            print('Mathpixレスポンス: ' + decoded);
            if (data['latex_simplified'] != null) {
                return data['latex_simplified'];
            } else if (data['latex_styled'] != null) {
                return data['latex_styled'];
            } else if (data['text'] != null) {
                return data['text'];
            } else if (data['error'] != null) {
                return '認識エラー: ${data['error']}';
            } else {
                return '数式が見つかりませんでした';
            }
        } else if (response.statusCode == 429) {
            return 'APIの制限に達しました。しばらく待ってから再試行してください。';
        } else {
            return 'エラーが発生しました: ${response.statusCode}';
        }
    } catch (e) {
        return '通信エラーが発生しました: $e';
    }
}

Future<Map<String, String>> recognizeMathpixWithRaw(Uint8List imageBytes) async {
    const String appId = 'help_for_study_app_e73a81_b89836';
    const String appKey = '998594fedcbb7d5d46b898e4ab3ed5d9fdbf07019e28b9e3be76b98010e31548';

    final String base64Image = base64Encode(imageBytes);

    try {
        final response = await http.post(
            Uri.parse('https://api.mathpix.com/v3/text'),
            headers: {
                'app_id': appId,
                'app_key': appKey,
                'Content-Type': 'application/json',
            },
            body: jsonEncode({
                'src': 'data:image/png;base64,$base64Image',
                'formats': ['latex_simplified', 'latex'],
                'ocr': ['math', 'text'],
                'math_inline_delimiters': ['\$', '\$'],
                'math_display_delimiters': ['\$\$', '\$\$'],
                'math_confidence_threshold': 0.8,
                'text_confidence_threshold': 0.8,
                'image_processing': {
                    'contrast': 1.5,
                    'brightness': 1.0,
                    'sharpen': 2.0
                }
            }),
        );

        String result = '';
        if (response.statusCode == 200) {
            final decoded = utf8.decode(response.bodyBytes);
            final data = json.decode(decoded);
            if (data['latex_simplified'] != null) {
                result = data['latex_simplified'];
            } else if (data['latex_styled'] != null) {
                result = data['latex_styled'];
            } else if (data['text'] != null) {
                result = data['text'];
            } else if (data['error'] != null) {
                result = '認識エラー: ${data['error']}';
            } else {
                result = '数式が見つかりませんでした';
            }
        } else if (response.statusCode == 429) {
            result = 'APIの制限に達しました。しばらく待ってから再試行してください。';
        } else {
            result = 'エラーが発生しました: ${response.statusCode}';
        }
        return {
            'result': result,
            'raw': response.body
        };
    } catch (e) {
        return {
            'result': '通信エラーが発生しました: $e',
            'raw': ''
        };
    }
}
