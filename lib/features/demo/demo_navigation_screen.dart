import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/app_theme.dart';
/// Demo navigation screen with distinctive "Italian Brutalism" UI.
class DemoNavigationScreen extends StatefulWidget {
  const DemoNavigationScreen({super.key});

  @override
  State<DemoNavigationScreen> createState() => _DemoNavigationScreenState();
}

class _DemoNavigationScreenState extends State<DemoNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _DemoDashboard(),
    _DemoExpenseList(),
    _DemoScanner(),
    _DemoGroup(),
    _DemoProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cream,
          border: Border(
            top: BorderSide(
              color: AppColors.inkFaded.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Panorama',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Spese',
            ),
            NavigationDestination(
              icon: Icon(Icons.document_scanner_outlined),
              selectedIcon: Icon(Icons.document_scanner),
              label: 'Scansiona',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Famiglia',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle),
              label: 'Profilo',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAddExpenseSheet(context),
              icon: const Icon(Icons.add),
              label: Text('Aggiungi', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  void _showAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nuova Spesa',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'DEMO MODE',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.terracotta,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Funzionalità non disponibile in modalità demo',
              style: GoogleFonts.dmSans(color: AppColors.inkLight),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DemoDashboard extends StatelessWidget {
  const _DemoDashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      body: CustomScrollView(
        slivers: [
          // Dramatic header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.parchment,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.terracotta.withValues(alpha: 0.15),
                      AppColors.parchment,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Dicembre',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.inkLight,
                                letterSpacing: 2,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.copper.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '2024',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.copper,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Spese Totali',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.inkLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '€',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 28,
                                fontWeight: FontWeight.w400,
                                color: AppColors.terracotta,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '2.847',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                height: 1,
                              ),
                            ),
                            Text(
                              ',56',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 28,
                                fontWeight: FontWeight.w500,
                                color: AppColors.inkLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Period selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  _PeriodTab(label: 'Settimana', selected: false, onTap: () {}),
                  const SizedBox(width: 8),
                  _PeriodTab(label: 'Mese', selected: true, onTap: () {}),
                  const SizedBox(width: 8),
                  _PeriodTab(label: 'Anno', selected: false, onTap: () {}),
                ],
              ),
            ),
          ),

          // Category breakdown
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Per Categoria',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Vedi tutto',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _CategoryCard(
                    icon: Icons.shopping_basket,
                    color: AppColors.categoryGrocery,
                    name: 'Alimentari',
                    amount: 876.45,
                    percent: 31,
                  ),
                  _CategoryCard(
                    icon: Icons.home_outlined,
                    color: AppColors.categoryHome,
                    name: 'Casa & Utenze',
                    amount: 654.00,
                    percent: 23,
                  ),
                  _CategoryCard(
                    icon: Icons.directions_car_outlined,
                    color: AppColors.categoryTransport,
                    name: 'Trasporti',
                    amount: 432.50,
                    percent: 15,
                  ),
                  _CategoryCard(
                    icon: Icons.restaurant_outlined,
                    color: AppColors.categoryRestaurant,
                    name: 'Ristoranti',
                    amount: 398.00,
                    percent: 14,
                  ),
                  _CategoryCard(
                    icon: Icons.local_hospital_outlined,
                    color: AppColors.categoryHealth,
                    name: 'Salute',
                    amount: 289.61,
                    percent: 10,
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Members breakdown
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Per Membro',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.inkFaded.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        _MemberTile(
                          name: 'Marco',
                          initial: 'M',
                          color: AppColors.terracotta,
                          amount: 1234.56,
                          isFirst: true,
                        ),
                        Divider(height: 1, color: AppColors.inkFaded.withValues(alpha: 0.1)),
                        _MemberTile(
                          name: 'Laura',
                          initial: 'L',
                          color: AppColors.copper,
                          amount: 987.00,
                        ),
                        Divider(height: 1, color: AppColors.inkFaded.withValues(alpha: 0.1)),
                        _MemberTile(
                          name: 'Giovanni',
                          initial: 'G',
                          color: AppColors.gold,
                          amount: 626.00,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.terracotta : AppColors.cream,
          borderRadius: BorderRadius.circular(4),
          border: selected
              ? null
              : Border.all(color: AppColors.inkFaded.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.cream : AppColors.inkLight,
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final double amount;
  final int percent;

  const _CategoryCard({
    required this.icon,
    required this.color,
    required this.name,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.inkFaded.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '€ ${amount.toStringAsFixed(2)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          backgroundColor: AppColors.parchmentDark,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$percent%',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String name;
  final String initial;
  final Color color;
  final double amount;
  final bool isFirst;
  final bool isLast;

  const _MemberTile({
    required this.name,
    required this.initial,
    required this.color,
    required this.amount,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            '€ ${amount.toStringAsFixed(2)}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoExpenseList extends StatelessWidget {
  const _DemoExpenseList();

  @override
  Widget build(BuildContext context) {
    final expenses = [
      _ExpenseData('Esselunga', Icons.shopping_basket, AppColors.categoryGrocery, 78.45, DateTime.now(), 'Alimentari'),
      _ExpenseData('ENI Stazione', Icons.local_gas_station, AppColors.categoryTransport, 65.00, DateTime.now().subtract(const Duration(days: 1)), 'Trasporti'),
      _ExpenseData('Bolletta Enel', Icons.bolt, AppColors.categoryBills, 89.50, DateTime.now().subtract(const Duration(days: 2)), 'Utenze'),
      _ExpenseData('Trattoria Romana', Icons.restaurant, AppColors.categoryRestaurant, 45.00, DateTime.now().subtract(const Duration(days: 3)), 'Ristoranti'),
      _ExpenseData('Farmacia Centrale', Icons.medical_services, AppColors.categoryHealth, 23.80, DateTime.now().subtract(const Duration(days: 4)), 'Salute'),
      _ExpenseData('UCI Cinema', Icons.movie, AppColors.categoryEntertainment, 32.00, DateTime.now().subtract(const Duration(days: 5)), 'Svago'),
      _ExpenseData('Zara', Icons.checkroom, AppColors.categoryClothing, 89.99, DateTime.now().subtract(const Duration(days: 6)), 'Abbigliamento'),
    ];

    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        title: Text(
          'Spese',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return _ExpenseCard(expense: expense);
        },
      ),
    );
  }
}

class _ExpenseData {
  final String description;
  final IconData icon;
  final Color color;
  final double amount;
  final DateTime date;
  final String category;

  _ExpenseData(this.description, this.icon, this.color, this.amount, this.date, this.category);
}

class _ExpenseCard extends StatelessWidget {
  final _ExpenseData expense;

  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.inkFaded.withValues(alpha: 0.12)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Dettaglio: ${expense.description}'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: expense.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(expense.icon, color: expense.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            expense.category,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: expense.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.inkFaded,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Text(
                            _formatDate(expense.date),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.inkFaded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '€ ${expense.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Oggi';
    if (diff == 1) return 'Ieri';
    return '${date.day}/${date.month}';
  }
}

class _DemoScanner extends StatelessWidget {
  const _DemoScanner();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        title: Text(
          'Scansiona',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.terracotta.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.terracotta.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.document_scanner_outlined,
                  size: 80,
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Scansione Scontrino',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Inquadra lo scontrino per estrarre\nautomaticamente i dati della spesa',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: AppColors.inkLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Demo: Scansione non disponibile'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('SCATTA FOTO'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Scegli dalla galleria'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoGroup extends StatelessWidget {
  const _DemoGroup();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        title: Text(
          'Famiglia Rossi',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invite code card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.terracotta,
                    AppColors.terracottaDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  Text(
                    'CODICE INVITO',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cream.withValues(alpha: 0.8),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'FAM-XK9P2',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cream,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.copy, color: AppColors.cream.withValues(alpha: 0.8)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Codice copiato negli appunti'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Condividi questo codice per invitare nuovi membri',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.cream.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Members section
            Text(
              'Membri',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            _GroupMemberCard(
              name: 'Marco Rossi',
              email: 'marco@esempio.it',
              initial: 'M',
              color: AppColors.terracotta,
              isAdmin: true,
            ),
            _GroupMemberCard(
              name: 'Laura Rossi',
              email: 'laura@esempio.it',
              initial: 'L',
              color: AppColors.copper,
              isAdmin: false,
            ),
            _GroupMemberCard(
              name: 'Giovanni Rossi',
              email: 'giovanni@esempio.it',
              initial: 'G',
              color: AppColors.gold,
              isAdmin: false,
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('INVITA MEMBRO'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupMemberCard extends StatelessWidget {
  final String name;
  final String email;
  final String initial;
  final Color color;
  final bool isAdmin;

  const _GroupMemberCard({
    required this.name,
    required this.email,
    required this.initial,
    required this.color,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.inkFaded.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ],
              ),
            ),
            if (isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.terracotta.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ADMIN',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.terracotta,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DemoProfile extends StatelessWidget {
  const _DemoProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        title: Text(
          'Profilo',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.terracotta,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'M',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 44,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Marco Rossi',
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'marco.rossi@esempio.it',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.inkLight,
              ),
            ),
            const SizedBox(height: 32),

            // Settings sections
            Container(
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.inkFaded.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.edit_outlined,
                    title: 'Modifica Profilo',
                    onTap: () {},
                  ),
                  Divider(height: 1, color: AppColors.inkFaded.withValues(alpha: 0.1)),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifiche',
                    onTap: () {},
                  ),
                  Divider(height: 1, color: AppColors.inkFaded.withValues(alpha: 0.1)),
                  _SettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Tema',
                    trailing: Text(
                      'Sistema',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.inkFaded,
                      ),
                    ),
                    onTap: () {},
                  ),
                  Divider(height: 1, color: AppColors.inkFaded.withValues(alpha: 0.1)),
                  _SettingsTile(
                    icon: Icons.language_outlined,
                    title: 'Lingua',
                    trailing: Text(
                      'Italiano',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.inkFaded,
                      ),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: _SettingsTile(
                icon: Icons.logout,
                iconColor: AppColors.error,
                title: 'Esci',
                titleColor: AppColors.error,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demo: Logout non disponibile'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),
            // Demo mode badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.science_outlined, size: 18, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Text(
                    'MODALITÀ DEMO',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'UI Preview • Nessun database connesso',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.inkFaded,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.inkLight, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: titleColor ?? AppColors.ink,
                  ),
                ),
              ),
              trailing ?? Icon(Icons.chevron_right, color: AppColors.inkFaded, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
