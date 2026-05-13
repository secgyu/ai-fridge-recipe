import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fridge_meal/core/router/app_routes.dart';
import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/features/fridge/data/models/ingredient.dart';
import 'package:fridge_meal/features/recipe/data/models/recipe.dart';
import 'package:fridge_meal/features/recipe/presentation/providers/recipe_provider.dart';
import 'package:fridge_meal/features/recipe/presentation/widgets/recipe_card.dart';

/// F-03 결과 화면.
///
/// 진입 시 [seedIngredients]로 추천 API 호출 → 로딩 → 결과 카드 리스트.
/// 카드 탭 → 상세(F-05) push.
class RecipeResultsScreen extends ConsumerStatefulWidget {
  const RecipeResultsScreen({super.key, required this.seedIngredients});

  final List<Ingredient> seedIngredients;

  @override
  ConsumerState<RecipeResultsScreen> createState() =>
      _RecipeResultsScreenState();
}

class _RecipeResultsScreenState extends ConsumerState<RecipeResultsScreen> {
  @override
  void initState() {
    super.initState();
    // build 이후 즉시 호출. notifier는 keepAlive지만 명시적 generate로 갱신.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(recipeResultsProvider.notifier)
          .generate(widget.seedIngredients);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Recipe>> results = ref.watch(recipeResultsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: results.when(
          loading: () => const _LoadingView(),
          error: (Object e, _) => _ErrorView(
            onRetry: () => ref
                .read(recipeResultsProvider.notifier)
                .generate(widget.seedIngredients),
          ),
          data: (List<Recipe> list) {
            if (list.isEmpty) {
              return const _LoadingView();
            }
            return _ResultsView(
              recipes: list,
              ingredientCount: widget.seedIngredients.length,
              onRegenerate: () {
                unawaited(HapticFeedback.selectionClick());
                ref
                    .read(recipeResultsProvider.notifier)
                    .generate(widget.seedIngredients);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.recipes,
    required this.ingredientCount,
    required this.onRegenerate,
  });

  final List<Recipe> recipes;
  final int ingredientCount;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: <Widget>[
          _Header(
            ingredientCount: ingredientCount,
            recipeCount: recipes.length,
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.md,
                AppSpacing.xxl,
                AppSpacing.xxxl,
              ),
              itemCount: recipes.length + 1, // 마지막에 "다시 추천받기" CTA
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int index) {
                if (index == recipes.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: _RegenerateButton(onPressed: onRegenerate),
                  );
                }
                final Recipe recipe = recipes[index];
                return RecipeCard(
                  recipe: recipe,
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    context.push(AppRoutes.recipeDetail, extra: recipe);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.ingredientCount, required this.recipeCount});

  final int ingredientCount;
  final int recipeCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textPrimary,
            iconSize: 22,
            onPressed: () => Navigator.of(context).pop(),
            tooltip: '뒤로',
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'AI가 추천한 레시피',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '재료 $ingredientCount개로 $recipeCount개 추천',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegenerateButton extends StatelessWidget {
  const _RegenerateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Material(
        color: AppColors.surfaceSubtle,
        borderRadius: AppRadius.rLg,
        child: InkWell(
          borderRadius: AppRadius.rLg,
          onTap: onPressed,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                '다시 추천받기',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatefulWidget {
  const _LoadingView();

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with TickerProviderStateMixin {
  late final AnimationController _bob;
  late final AnimationController _messageCycle;
  static const List<String> _messages = <String>[
    '재료를 살펴보고 있어요',
    'AI 셰프가 고민 중이에요',
    '맛있는 조합을 찾는 중...',
    '거의 완성! 마지막 손질 중',
  ];
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _messageCycle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addStatusListener((AnimationStatus s) {
        if (s == AnimationStatus.completed) {
          if (!mounted) return;
          setState(() {
            _messageIndex = (_messageIndex + 1) % _messages.length;
          });
          _messageCycle.forward(from: 0);
        }
      });
    _messageCycle.forward();
  }

  @override
  void dispose() {
    _bob.dispose();
    _messageCycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedBuilder(
              animation: _bob,
              builder: (BuildContext context, Widget? child) {
                final double dy = math.sin(_bob.value * math.pi) * -8;
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: child,
                );
              },
              child: SizedBox(
                width: 140,
                height: 140,
                child: Image.asset(
                  'assets/images/pot/pot_excited.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: Text(
                _messages[_messageIndex],
                key: ValueKey<int>(_messageIndex),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '최대 30초 정도 걸려요',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Spacer(),
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '레시피를 가져오지 못했어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              '잠시 후 다시 시도해주세요',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 48,
              child: Material(
                color: AppColors.primary,
                borderRadius: AppRadius.rLg,
                child: InkWell(
                  borderRadius: AppRadius.rLg,
                  onTap: onRetry,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                    ),
                    child: Center(
                      child: Text(
                        '다시 시도',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
