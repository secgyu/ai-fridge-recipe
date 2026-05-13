import 'package:fridge_meal/core/constants/ingredient_category.dart';

/// 바코드 조회 결과 한 건.
///
/// 실제 환경에서는 `lookup-barcode` Edge Function이 식약처 API를 호출해
/// 반환하는 응답을 매핑한다. MVP 단계에서는 [kBarcodeMocks]에서 즉시 응답.
class BarcodeProduct {
  const BarcodeProduct({
    required this.barcode,
    required this.name,
    required this.category,
    this.defaultExpiryDays,
  });

  final String barcode;
  final String name;
  final IngredientCategory category;
  final int? defaultExpiryDays;
}

/// 시연용 mock 바코드 → 제품 매핑.
///
/// 실제 바코드를 비추든, 임의의 13자리를 스캔하든 매핑되지 않으면
/// "찾지 못함" 다이얼로그로 안내한다 (UI 흐름 검증).
const Map<String, BarcodeProduct> kBarcodeMocks = <String, BarcodeProduct>{
  '8801062123456': BarcodeProduct(
    barcode: '8801062123456',
    name: '신라면',
    category: IngredientCategory.grain,
    defaultExpiryDays: 180,
  ),
  '8801043038011': BarcodeProduct(
    barcode: '8801043038011',
    name: '농심 새우깡',
    category: IngredientCategory.other,
    defaultExpiryDays: 120,
  ),
  '8801052734415': BarcodeProduct(
    barcode: '8801052734415',
    name: '오뚜기 진라면 매운맛',
    category: IngredientCategory.grain,
    defaultExpiryDays: 180,
  ),
  '8809238070080': BarcodeProduct(
    barcode: '8809238070080',
    name: '서울우유 1L',
    category: IngredientCategory.dairy,
    defaultExpiryDays: 7,
  ),
};

BarcodeProduct? lookupBarcode(String barcode) => kBarcodeMocks[barcode];
