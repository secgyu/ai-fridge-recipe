import 'package:json_annotation/json_annotation.dart';

/// 레시피 난이도.
@JsonEnum(valueField: 'value')
enum RecipeDifficulty {
  easy('easy', '쉬움'),
  medium('medium', '보통'),
  hard('hard', '어려움');

  const RecipeDifficulty(this.value, this.label);

  final String value;
  final String label;
}
