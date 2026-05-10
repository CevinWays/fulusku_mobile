import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/enums.dart';
import '../../../core/models/category_model.dart';
import '../../categories/cubit/category_cubit.dart';

/// Grid 4-kolom untuk pilih kategori.
class CategorySelector extends StatelessWidget {
  final CategoryType filterType;
  final int? selectedId;
  final ValueChanged<CategoryModel> onSelected;

  const CategorySelector({
    super.key,
    required this.filterType,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading || state is CategoryInitial) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (state is CategoryError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(state.message, style: AppTypography.bodySmall),
          );
        }
        if (state is CategoryLoaded) {
          final cats = state.ofType(filterType);
          if (cats.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Belum ada kategori untuk ${filterType.label}.',
                style: AppTypography.bodySmall,
              ),
            );
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: cats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (_, i) {
              final c = cats[i];
              final selected = c.id == selectedId;
              final color = AppColors.fromHex(c.color);
              return GestureDetector(
                onTap: () => onSelected(c),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.18)
                            : AppColors.background,
                        border: Border.all(
                          color: selected ? color : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(c.icon ?? '📦', style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: selected ? AppColors.textPrimary : AppColors.textMuted,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
