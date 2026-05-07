# API_INTEGRATION: API 연동 가이드 (Supabase Edge Function 프록시)

## 핵심 원칙

> **외부 API 키는 클라이언트에 절대 두지 않는다.**
> 모든 외부 호출은 Supabase Edge Function을 거친다.

```
[Flutter] ──supabase_flutter SDK──▶ [Edge Function] ──▶ [OpenAI / 식약처 API]
                                        │
                                        ├─ Rate Limit 검사
                                        ├─ Postgres 캐시 조회/저장
                                        └─ 키는 Edge Function 시크릿에만
```

---

## 호출 매트릭스

| Edge Function | 호출하는 외부 API | 호출 주기 | 캐시 |
|---|---|---|---|
| `generate-recipe` | OpenAI GPT-4o-mini | 사용자 [요리시작] 클릭 시 | 7일, 전역 공유 |
| `lookup-barcode` | 식품안전나라 C005 | 바코드 스캔 1회당 1번 | 영구, 전역 공유 |

---

## Edge Function 1: `generate-recipe`

### 책임
1. 호출 유저 인증 확인 (Supabase JWT 검증은 SDK가 자동)
2. 일일 호출 한도 검사 (`api_usage` 테이블)
3. 캐시 조회 (`recipe_cache` 테이블) — 동일 재료 셋이면 GPT 호출 생략
4. 캐시 미스 시 OpenAI 호출 → 결과 캐시 저장
5. 결과 반환

### 코드: `supabase/functions/generate-recipe/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { recipes50 } from "../_shared/recipes_top.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const DAILY_LIMIT = 10;
const CACHE_TTL_DAYS = 7;

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  // 1) 유저 인증
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return jsonError(401, "Missing auth");

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return jsonError(401, "Invalid token");

  // 2) 입력 검증
  const { ingredients, servings = 2, max_time_minutes, dietary_restrictions = [] } =
    await req.json();
  if (!Array.isArray(ingredients) || ingredients.length < 2) {
    return jsonError(400, "Need at least 2 ingredients");
  }

  // 3) Rate Limit
  const limit = await checkRateLimit(supabase, user.id, "generate-recipe", DAILY_LIMIT);
  if (!limit.allowed) {
    return jsonError(429, `Daily limit ${DAILY_LIMIT} exceeded. Resets ${limit.resetsAt}`);
  }

  // 4) 캐시 조회 (재료 정렬 후 해시)
  const cacheKey = await hashIngredients([...ingredients].sort());
  const { data: cached } = await supabase
    .from("recipe_cache")
    .select("recipes, created_at")
    .eq("cache_key", cacheKey)
    .gt("created_at", new Date(Date.now() - CACHE_TTL_DAYS * 86400_000).toISOString())
    .maybeSingle();

  if (cached) {
    await supabase.from("recipe_cache").update({
      hit_count: supabase.rpc("increment", { x: 1 }),
    }).eq("cache_key", cacheKey);

    return jsonOk({ recipes: cached.recipes, source: "cache" });
  }

  // 5) OpenAI 호출
  const recipes = await callOpenAI(ingredients, servings, max_time_minutes, dietary_restrictions);

  // 6) 캐시 저장
  await supabase.from("recipe_cache").insert({
    cache_key: cacheKey,
    ingredients_sorted: [...ingredients].sort(),
    recipes,
  });

  // 7) 사용량 기록
  await supabase.from("api_usage").insert({
    user_id: user.id,
    function_name: "generate-recipe",
    cost_estimate_usd: 0.002,
  });

  return jsonOk({ recipes, source: "openai" });
});

async function callOpenAI(
  ingredients: string[],
  servings: number,
  maxTime: number | undefined,
  restrictions: string[],
): Promise<unknown[]> {
  const systemPrompt = buildSystemPrompt(restrictions);
  const userPrompt = buildUserPrompt(ingredients, servings, maxTime);

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
      response_format: { type: "json_object" },
      temperature: 0.7,
      max_tokens: 2000,
    }),
  });

  if (!res.ok) throw new Error(`OpenAI ${res.status}: ${await res.text()}`);

  const json = await res.json();
  const content = JSON.parse(json.choices[0].message.content);
  return content.recipes;
}

function buildSystemPrompt(restrictions: string[]): string {
  return `당신은 한국 가정식 전문 셰프입니다.
사용자가 제공한 재료로 만들 수 있는 레시피 3개를 추천하세요.

규칙:
1. 반드시 아래 요리 목록에서만 추천하세요 (이미지 매핑 보장).
2. 사용자 재료만으로 만들 수 있는 요리를 우선 추천하세요.
3. 기본 양념(소금, 설탕, 간장, 식용유, 참기름, 후추)은 있다고 가정하세요.
4. 추가 재료가 1~2개 필요한 요리도 포함 가능 (in_fridge: false).
5. 3개 레시피는 서로 다른 카테고리에서 추천하세요.
${restrictions.length > 0 ? `\n식이 제한: ${restrictions.join(", ")}` : ""}

응답 형식 (JSON):
{
  "recipes": [
    {
      "id": "potato_stir_fry",
      "name": "감자채 볶음",
      "category": "stir_fry",
      "difficulty": "easy",
      "time_minutes": 15,
      "servings": 2,
      "match_rate": 100,
      "ingredients": [{"name": "감자", "amount": "2개", "in_fridge": true}],
      "steps": [{"step": 1, "instruction": "...", "timer_seconds": 300}],
      "tips": "..."
    }
  ]
}

요리 목록 (${recipes50.length}개):
${recipes50.join(", ")}`;
}

function buildUserPrompt(ingredients: string[], servings: number, maxTime?: number): string {
  let p = `재료: ${ingredients.join(", ")}\n인분: ${servings}인분`;
  if (maxTime) p += `\n시간: ${maxTime}분 이내`;
  return p;
}

async function hashIngredients(arr: string[]): Promise<string> {
  const data = new TextEncoder().encode(arr.join("|"));
  const hash = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function jsonOk(body: unknown) {
  return new Response(JSON.stringify(body), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
function jsonError(status: number, message: string) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
```

---

## Edge Function 2: `lookup-barcode`

### 책임
1. `barcode_cache` 테이블에서 먼저 조회 (영구 캐시 — 바코드는 변하지 않음)
2. 캐시 미스 시 식약처 API 호출 (HTTP → Edge Function이 HTTPS로 중계)
3. 결과 정규화 후 캐시 저장 + 반환

### 코드: `supabase/functions/lookup-barcode/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const FOOD_SAFETY_KEY = Deno.env.get("FOOD_SAFETY_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return jsonError(401, "Missing auth");

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return jsonError(401, "Invalid token");

  const { barcode } = await req.json();
  if (!/^\d{8,14}$/.test(barcode)) return jsonError(400, "Invalid barcode");

  // 캐시 조회
  const { data: cached } = await supabase
    .from("barcode_cache")
    .select("*")
    .eq("barcode", barcode)
    .maybeSingle();
  if (cached) return jsonOk({ ...cached, source: "cache" });

  // 식약처 API 호출 (HTTP)
  const url = `http://openapi.foodsafetykorea.go.kr/api/${FOOD_SAFETY_KEY}/C005/json/1/5/BAR_CD=${barcode}`;
  const res = await fetch(url);
  const json = await res.json();
  const rows = json?.C005?.row;

  if (!rows || rows.length === 0) return jsonOk({ found: false });

  const product = rows[0];
  const normalized = {
    barcode,
    name: product.PRDLST_NM,
    food_type: product.PRDLST_DCNM ?? "",
    manufacturer: product.BSSH_NM ?? "",
    expiry_days_from_manufacture: parseInt(product.POG_DAYCNT ?? "0", 10) || null,
    category: classifyCategory(product.PRDLST_NM, product.PRDLST_DCNM ?? ""),
    found: true,
  };

  await supabase.from("barcode_cache").upsert(normalized);
  return jsonOk({ ...normalized, source: "food_safety_api" });
});

function classifyCategory(name: string, foodType: string): string {
  const text = `${name} ${foodType}`.toLowerCase();
  const map: Record<string, string> = {
    "두부": "vegetable", "우유": "dairy", "요구르트": "dairy", "치즈": "dairy",
    "돼지": "meat", "소고기": "meat", "닭": "meat",
    "생선": "seafood", "새우": "seafood",
    "간장": "seasoning", "고추장": "seasoning",
    "라면": "grain",
  };
  for (const [k, v] of Object.entries(map)) {
    if (text.includes(k)) return v;
  }
  return "other";
}

function jsonOk(b: unknown) {
  return new Response(JSON.stringify(b), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
function jsonError(s: number, m: string) {
  return new Response(JSON.stringify({ error: m }), {
    status: s,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
```

> **`POG_DAYCNT`(제조일로부터의 소비기한)는 캐시에는 저장하되 사용자 화면에서는 "참고용"으로만 표시한다.** 실제 D-day는 사용자가 직접 입력한 유통기한을 우선한다.

---

## 공유 모듈

### `supabase/functions/_shared/cors.ts`

```typescript
export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};
```

### `supabase/functions/_shared/rate_limit.ts`

```typescript
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export async function checkRateLimit(
  supabase: SupabaseClient,
  userId: string,
  functionName: string,
  dailyLimit: number,
): Promise<{ allowed: boolean; resetsAt: string; used: number }> {
  const startOfDay = new Date();
  startOfDay.setUTCHours(0, 0, 0, 0);

  const { count } = await supabase
    .from("api_usage")
    .select("*", { count: "exact", head: true })
    .eq("user_id", userId)
    .eq("function_name", functionName)
    .gte("created_at", startOfDay.toISOString());

  const tomorrow = new Date(startOfDay.getTime() + 86400_000);
  return {
    allowed: (count ?? 0) < dailyLimit,
    used: count ?? 0,
    resetsAt: tomorrow.toISOString(),
  };
}
```

---

## Flutter 측 호출 코드

### `lib/features/recipe/data/services/recipe_proxy_service.dart`

```dart
class RecipeProxyService {
  final SupabaseClient _supabase;
  RecipeProxyService(this._supabase);

  Future<List<Recipe>> generate({
    required List<String> ingredients,
    required int servings,
    int? maxTimeMinutes,
    List<String>? dietaryRestrictions,
  }) async {
    final response = await _supabase.functions.invoke(
      'generate-recipe',
      body: {
        'ingredients': ingredients,
        'servings': servings,
        if (maxTimeMinutes != null) 'max_time_minutes': maxTimeMinutes,
        if (dietaryRestrictions != null) 'dietary_restrictions': dietaryRestrictions,
      },
    );

    if (response.status == 429) {
      throw RateLimitException(response.data['error'] as String);
    }
    if (response.status != 200) {
      throw RecipeGenerationException(response.data['error'] as String? ?? 'Unknown');
    }

    final list = response.data['recipes'] as List;
    return list.map((j) => Recipe.fromJson(j as Map<String, dynamic>)).toList();
  }
}
```

### `lib/features/scan/data/services/barcode_proxy_service.dart`

```dart
class BarcodeProxyService {
  final SupabaseClient _supabase;
  BarcodeProxyService(this._supabase);

  Future<BarcodeLookupResult?> lookup(String barcode) async {
    final response = await _supabase.functions.invoke(
      'lookup-barcode',
      body: {'barcode': barcode},
    );
    if (response.status != 200) return null;
    final data = response.data as Map<String, dynamic>;
    if (data['found'] != true) return null;
    return BarcodeLookupResult.fromJson(data);
  }
}
```

---

## 에러 처리 정책

| HTTP | 의미 | Flutter 측 처리 |
|---|---|---|
| 200 | 성공 | 결과 사용 |
| 401 | 토큰 만료/무효 | 자동 갱신 → 재시도 1회 → 실패 시 로그인 화면 |
| 429 | 일일 호출 한도 초과 | 다이얼로그: "오늘은 다 썼어요. 내일 다시!" + 캐시된 즐겨찾기 안내 |
| 4xx | 입력 오류 | 사용자 메시지 표시 |
| 5xx | 서버 오류 | "잠시 후 다시" 토스트 + 1회 재시도 |
| 네트워크 오류 | 오프라인 | 캐시된 즐겨찾기 안내 |

---

## 발급 체크리스트

- [ ] Supabase 프로젝트 생성 → URL, anon key, service_role key 확보
- [ ] data.go.kr 회원가입 + 식약처 바코드 API 활용 신청
- [ ] OpenAI API 키 발급
- [ ] `supabase secrets set` 으로 OPENAI_API_KEY, FOOD_SAFETY_API_KEY 등록
- [ ] `supabase functions deploy generate-recipe`
- [ ] `supabase functions deploy lookup-barcode`
- [ ] 빌드 시 `--dart-define`으로 SUPABASE_URL, SUPABASE_ANON_KEY 주입
- [ ] Edge Function 호출 테스트 (Postman 또는 앱 내)
