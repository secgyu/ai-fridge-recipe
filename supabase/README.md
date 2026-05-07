# Supabase

> Day 3에 `supabase init` 실행 후 본격 셋업.
> 자세한 가이드는 [`docs/API_INTEGRATION.md`](../docs/API_INTEGRATION.md) 참고.

## 폴더

```
supabase/
├── functions/
│   ├── _shared/             cors, rate_limit, recipes_top 공유 모듈
│   ├── generate-recipe/     OpenAI 프록시 (Day 7~8)
│   └── lookup-barcode/      식약처 API 프록시 (Day 6)
└── migrations/              Postgres 스키마 (Day 4)
```

## 자주 쓰는 명령

```bash
# 로컬 개발
supabase start                                    # 로컬 Docker 스택 기동
supabase functions serve generate-recipe          # Edge Function 로컬 테스트

# 배포
supabase db push                                  # 마이그레이션 원격 반영
supabase functions deploy generate-recipe
supabase secrets set OPENAI_API_KEY=...
```
