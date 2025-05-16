String normalize_to_latex(String input) {
  String output = input;

  // × や * を除去（LaTeXでは暗黙の掛け算）
  output = output.replaceAll(RegExp(r'×|\*'), '');

  // ^(数字) を ^{数字} に変換（例: x^(2) → x^{2}）
  output = output.replaceAllMapped(RegExp(r'\^\((\d+)\)'), (match) => '^{${match[1]}}');

  // ^数字 を ^{数字} に変換（例: x^2 → x^{2}）
  output = output.replaceAllMapped(RegExp(r'\^(\d+)'), (match) => '^{${match[1]}}');

  // スペースを除去（意図しない空白を削除）
  output = output.replaceAll(' ', '');

  return output;
}
