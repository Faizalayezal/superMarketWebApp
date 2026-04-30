import 'package:flutter/material.dart';
import 'package:shivam_super_market/core/config.dart';
import 'package:shivam_super_market/screens/menu/home.dart';
import 'package:shivam_super_market/screens/menu/pos_sale_screen.dart';
import 'package:shivam_super_market/screens/product/product.dart';
import 'package:shivam_super_market/screens/sales/earnings.dart';
import 'package:shivam_super_market/screens/settings/settings_screen.dart';

const double kMobileBreak = 600;
const double kTabletBreak = 900;

// ─────────────────────────────────────────────────────────────
// NavItem model
// ─────────────────────────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
  });
}

// ══════════════════════════════════════════════════════════════
// AppShell
// ══════════════════════════════════════════════════════════════
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // ✅ FIX: _navItems defined as late final inside State — created ONCE.
  // Previously it was a top-level list, so every build() call of LayoutBuilder
  // created fresh widget instances → IndexedStack saw new objects → screens
  // remounted → initState ran again → data reloaded.
  late final List<_NavItem> _navItems;

  @override
  void initState() {
    super.initState();
    _navItems = [
      const _NavItem(
        label: 'Dashboard',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        screen: HomeScreen(),
      ),
      const _NavItem(
        label: 'POS',
        icon: Icons.point_of_sale_outlined,
        activeIcon: Icons.point_of_sale_rounded,
        screen: POSSaleScreen(),
      ),
      const _NavItem(
        label: 'Products',
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
        screen: ProductView(),
      ),
      _NavItem(
        label: 'Sales',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        screen: PaginatedSalesScreen(),
      ),
      const _NavItem(
        label: 'Settings',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        screen: StoreSettingsScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < kMobileBreak;
        return isMobile
            ? _buildMobile()
            : _buildDesktop(constraints.maxWidth);
      },
    );
  }

  // ── MOBILE layout ────────────────────────────────────────────
  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: secondaryColor, width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                superMarketTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon:
            const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildPageContent(),
      bottomNavigationBar: _MobileBottomNav(
        items: _navItems,
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  // ── DESKTOP / TABLET layout ──────────────────────────────────
  Widget _buildDesktop(double totalWidth) {
    final isWide = totalWidth >= kTabletBreak;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          _DesktopRail(
            items: _navItems,
            selectedIndex: _selectedIndex,
            extended: isWide,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          ),
          const VerticalDivider(
              width: 1, thickness: 1, color: Color(0xFFE0E8F0)),
          Expanded(child: _buildPageContent()),
        ],
      ),
    );
  }

  // ✅ FIX: IndexedStack with the SAME widget instances every time.
  // Because _navItems is created once in initState, the same Widget objects
  // are passed to IndexedStack on every build → Flutter sees no change →
  // screens stay mounted → no data reload on resize or tab switch.
  Widget _buildPageContent() {
    return IndexedStack(
      index: _selectedIndex,
      children: _navItems.map((item) => item.screen).toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// _DesktopRail
// ══════════════════════════════════════════════════════════════
class _DesktopRail extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onDestinationSelected;

  const _DesktopRail({
    required this.items,
    required this.selectedIndex,
    required this.extended,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: extended ? 220 : 76,
      color: sidebarColor,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(
              vertical: 28,
              horizontal: extended ? 20 : 0,
            ),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: secondaryColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: secondaryColor.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                  ),
                ),
                if (extended) ...[
                  const SizedBox(height: 10),
                  const Text(
                    superMarketTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Divider(
                  color: Colors.white.withOpacity(0.1),
                  indent: extended ? 0 : 12,
                  endIndent: extended ? 0 : 12,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;
                return _RailItem(
                  item: item,
                  isSelected: isSelected,
                  extended: extended,
                  onTap: () => onDestinationSelected(index),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: extended
                ? Text(
              'v1.0.0',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.25), fontSize: 11),
            )
                : Icon(Icons.more_horiz,
                color: Colors.white.withOpacity(0.2), size: 18),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// _RailItem
// ══════════════════════════════════════════════════════════════
class _RailItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final bool extended;
  final VoidCallback onTap;

  const _RailItem({
    required this.item,
    required this.isSelected,
    required this.extended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      EdgeInsets.symmetric(horizontal: extended ? 12 : 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: extended ? 14 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? secondaryColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                  color: secondaryColor.withOpacity(0.3), width: 1)
                  : null,
            ),
            child: extended
                ? Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? secondaryColor : Colors.white54,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  item.label,
                  style: TextStyle(
                    color:
                    isSelected ? secondaryColor : Colors.white60,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ],
            )
                : Center(
              child: Tooltip(
                message: item.label,
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? secondaryColor : Colors.white54,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// _MobileBottomNav
// ══════════════════════════════════════════════════════════════
class _MobileBottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _MobileBottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: secondaryColor.withOpacity(0.15),
          selectedIndex: selectedIndex,
          onDestinationSelected: onTap,
          elevation: 0,
          height: 62,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: items.map((item) {
            final isSelected = items.indexOf(item) == selectedIndex;
            return NavigationDestination(
              icon: Icon(item.icon,
                  color: isSelected ? secondaryColor : Colors.grey),
              selectedIcon: Icon(item.activeIcon, color: secondaryColor),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}