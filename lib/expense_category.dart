class ExpenseCategory {
  final String name;

  const ExpenseCategory(this.name);

  // Список категорий расходов
  static const List<ExpenseCategory> expenseCategories = [
    ExpenseCategory('Food'),
    ExpenseCategory('Transport'),
    ExpenseCategory('Entertainment'),
    ExpenseCategory('Utilities'),
  ];

  // Метод для получения имени категории по индексу
  static String getCategoryName(int index) {
    if (index >= 0 && index < expenseCategories.length) {
      return expenseCategories[index].name;
    } else {
      return '';
    }
  }
}