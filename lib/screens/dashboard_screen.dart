import 'package:flutter/cupertino.dart';
import 'package:shivam_super_market/common_import.dart';
import 'package:shivam_super_market/screens/product/product.dart';
import 'package:shivam_super_market/screens/settings/settings_screen.dart';
import 'sales/earnings.dart';
import 'menu/home.dart';
import 'menu/pos_sale_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedMenu = "sales";
  bool isCompactSideMenu=false;
  void _onMenuSelected(String menu) {
    setState(() {
      selectedMenu = menu;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _Sidebar(
            selectedMenu: selectedMenu,
            sideMenuStyle: isCompactSideMenu,
            onSideMenuChange:(){
              setState(() {
                isCompactSideMenu=!isCompactSideMenu;
              });
            },
            onMenuSelected: _onMenuSelected,
          ),

          // Right Content
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (selectedMenu) {
      case "products":
        return const ProductView();
      case "settings":
        return StoreSettingsScreen();
      case "sales":
        return  POSSaleScreen();
        case "earnings":
        return  PaginatedSalesScreen();
        case "dashboard":
        return  HomeScreen();
      default:
        return const Center(child: Text("Select Menu"));
    }
  }
}

class _Sidebar extends StatelessWidget {
  final String selectedMenu;
  final Function(String) onMenuSelected;
  final Function() onSideMenuChange;
  final bool sideMenuStyle;

  const _Sidebar({
    required this.selectedMenu,
    required this.onMenuSelected, required this.onSideMenuChange, required this.sideMenuStyle,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_){
        onSideMenuChange();
      },
      onExit: (_) {
        onSideMenuChange();
      },
      child: Container(
        width:
        !sideMenuStyle?/*MediaQuery.sizeOf(context).width * 0.08*/80:
        MediaQuery.sizeOf(context).width * 0.20,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [

            Color(0xFF1E293B),
            Color(0xFF0F172A),

            // secondaryColor
          ],
          begin: AlignmentGeometry.topLeft,
            end: AlignmentGeometry.bottomRight,
          )
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            // if(sideMenuStyle)
            // _SidebarHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _SidebarItem(
                    icon: Icons.home_rounded,
                    label: sideMenuStyle?"Dashboard":"",
                    value: "dashboard",
                    selectedValue: selectedMenu,
                    onTap: onMenuSelected,
                  ),
                  _SidebarItem(
                    icon: Icons.monetization_on_outlined,
                    label: sideMenuStyle?"Sales":"",
                    value: "sales",
                    selectedValue: selectedMenu,
                    onTap: onMenuSelected,
                  ),
                  _SidebarItem(
                    icon: Icons.shopping_cart,
                    label: !sideMenuStyle?"":"Products",
                    value: "products",
                    selectedValue: selectedMenu,
                    onTap: onMenuSelected,
                  ),
                  _SidebarItem(
                    icon: Icons.fact_check_outlined,
                    label: !sideMenuStyle?"":"Earnings",
                    value: "earnings",
                    selectedValue: selectedMenu,
                    onTap: onMenuSelected,
                  ),
                  _SidebarItem(
                    icon: Icons.settings,
                    label: !sideMenuStyle?"":"Settings",
                    value: "settings",
                    selectedValue: selectedMenu,
                    onTap: onMenuSelected,
                  ),
                ],
              ),
            ),
            // const SizedBox(height: 20),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 24.0),
            //   child: IconButton(onPressed:onSideMenuChange, icon: Icon(
            //       sideMenuStyle?
            //       CupertinoIcons.left_chevron:CupertinoIcons.right_chevron,color: Colors.white,)),
            // ),
            // const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset("assets/logo.png", width: 140),
          ),
        ),
         SizedBox(height: 12,),
         Center(
           child: Text(
             superMarketTitle,
             style: TextStyle(color: Colors.white, fontSize: 18),
             overflow: TextOverflow.ellipsis,
           ),
         ),
        SizedBox(height: 32,),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String selectedValue;
  final Function(String) onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;
    return ListTile(
      leading: Icon(icon, color: isSelected?primaryColor:Colors.white,size: 34,),
      title: Text(
        label,
        style:  TextStyle(color: isSelected?primaryColor:Colors.white,fontWeight: FontWeight.bold),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blueGrey[800],
      onTap: () => onTap(value),
    );
  }
}
