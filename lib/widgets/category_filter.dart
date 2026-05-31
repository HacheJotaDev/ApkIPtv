import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryFilter extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const CategoryFilter({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: const Text('Todos'),
                selected: selectedCategoryId == null,
                onSelected: (_) => onCategorySelected(null),
                selectedColor: const Color(0xFF00BCD4),
                backgroundColor: const Color(0xFF1A1D30),
                side: BorderSide(
                  color: selectedCategoryId == null ? const Color(0xFF00BCD4) : const Color(0xFF2A2D4A),
                ),
                labelStyle: TextStyle(
                  color: selectedCategoryId == null ? const Color(0xFF1A1D30) : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          final category = categories[index - 1];
          final isSelected = selectedCategoryId == category.id;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(isSelected ? null : category.id),
              selectedColor: const Color(0xFF00BCD4),
              backgroundColor: const Color(0xFF1A1D30),
              side: BorderSide(
                color: isSelected ? const Color(0xFF00BCD4) : const Color(0xFF2A2D4A),
              ),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF1A1D30) : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}
