import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantapp/core/theme/app_theme.dart';
import 'package:restaurantapp/main.dart';
import 'package:restaurantapp/models/order_model.dart';
import 'package:restaurantapp/screens/admin/admin_screen.dart';
import 'package:restaurantapp/screens/chef/chef_screen.dart';
import 'package:restaurantapp/screens/profile/profile_screen.dart';
import 'package:restaurantapp/screens/serveur/serveur_screen.dart';
import 'package:restaurantapp/screens/serveur/mes_commandes_screen.dart';
import 'package:restaurantapp/screens/settings/settings_screen.dart';
import 'package:restaurantapp/services/order_service.dart';
import 'package:restaurantapp/widgets/admin_drawer.dart';
import 'package:restaurantapp/widgets/chef_drawer.dart';
import 'package:restaurantapp/widgets/serveur_drawer.dart';

class MainScreen extends StatefulWidget {
  final String userRole;
  const MainScreen({super.key, required this.userRole});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _userName = '';
  String _userEmail = '';

  // Notifications
  final OrderService _orderService = OrderService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _notificationSubscription;

  // State for notifications - static to persist between rebuilds
  static final Set<String> _notifiedPendingOrderIds = {};
  static final Set<String> _notifiedReadyOrderIds = {};
  static bool _chefFirstLoad = true;
  static bool _serveurFirstLoad = true;

  // IDs of read notifications - static to persist
  static final Set<String> _readNotificationIds = {};

  // Unread notification counter
  int _unreadNotificationCount = 0;

  // Theme colors for admin and serveur
  static const Color _warmOrange = Color(0xFFE85D04);
  static const Color _deepBrown = Color(0xFF3D2914);
  static const Color _cream = Color(0xFFFFF8F0);

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _setupNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (widget.userRole == 'Chef') {
      // Listen for new pending orders
      _notificationSubscription = _orderService.getOrdersByStatus([OrderStatus.pending]).listen((orders) {
        if (_chefFirstLoad) {
          _notifiedPendingOrderIds.addAll(orders.map((o) => o.id));
          _chefFirstLoad = false;
          if (mounted) {
            final unreadCount = orders.where((o) => !_readNotificationIds.contains(o.id)).length;
            setState(() => _unreadNotificationCount = unreadCount);
          }
          return;
        }

        final newOrders = orders.where((o) => !_notifiedPendingOrderIds.contains(o.id)).toList();
        for (var order in newOrders) {
          _showNotification(
            title: 'Nouvelle commande !',
            body: order.type == OrderType.dineIn
                ? 'Table ${order.tableNumber ?? "N/A"} - ${order.serverName}'
                : 'À emporter - ${order.serverName}',
          );
          _notifiedPendingOrderIds.add(order.id);
        }
        if (mounted) {
          final unreadCount = orders.where((o) => !_readNotificationIds.contains(o.id)).length;
          setState(() => _unreadNotificationCount = unreadCount);
        }
      }, onError: (error) {
        debugPrint('Erreur notification Chef: $error');
      });
    } else if (widget.userRole == 'Serveur') {
       _notificationSubscription = _orderService.getActiveOrdersForServer(user.uid).listen((orders) {
           final readyOrders = orders.where((o) => o.status == OrderStatus.ready).toList();

           if (_serveurFirstLoad) {
              _notifiedReadyOrderIds.addAll(readyOrders.map((o) => o.id));
              _serveurFirstLoad = false;
              if (mounted) {
                final unreadCount = readyOrders.where((o) => !_readNotificationIds.contains(o.id)).length;
                setState(() => _unreadNotificationCount = unreadCount);
              }
              return;
           }

           final newReadyOrders = readyOrders.where((o) => !_notifiedReadyOrderIds.contains(o.id)).toList();
           for (var order in newReadyOrders) {
             _showNotification(
               title: 'Commande prête !',
               body: order.type == OrderType.dineIn
                 ? 'Table ${order.tableNumber ?? "N/A"} - ${order.items.length} article(s)'
                 : 'À emporter - ${order.items.length} article(s)',
               payload: 'mes_commandes',
             );
             _notifiedReadyOrderIds.add(order.id);
           }
           if (mounted) {
             final unreadCount = readyOrders.where((o) => !_readNotificationIds.contains(o.id)).length;
             setState(() => _unreadNotificationCount = unreadCount);
           }
       }, onError: (error) {
         debugPrint('Erreur notification Serveur: $error');
       });
    }
  }

  void _showNotification({
    required String title,
    required String body,
    String? payload,
  }) {
    _playNotificationSound();

    flutterLocalNotificationsPlugin.show(
      body.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Saveurs',
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      debugPrint('Erreur son notification: $e');
    }
  }

  void _showNotificationsPanel() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      color: _roleColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.userRole == 'Chef'
                            ? 'Commandes en attente'
                            : 'Commandes prêtes',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_unreadNotificationCount > 0)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _markAllAsRead();
                        },
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: const Text('Tout lu'),
                        style: TextButton.styleFrom(
                          foregroundColor: _roleColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Notification list
              Expanded(
                child: _buildNotificationsList(user.uid, scrollController),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(String userId, ScrollController scrollController) {
    if (widget.userRole == 'Chef') {
      return StreamBuilder<List<OrderModel>>(
        stream: _orderService.getOrdersByStatus([OrderStatus.pending]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyNotifications('Aucune commande en attente');
          }
          return ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) => _buildNotificationTile(
              snapshot.data![index],
              isChef: true,
            ),
          );
        },
      );
    } else {
      return StreamBuilder<List<OrderModel>>(
        stream: _orderService.getActiveOrdersForServer(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final readyOrders = snapshot.data?.where((o) => o.status == OrderStatus.ready).toList() ?? [];
          if (readyOrders.isEmpty) {
            return _buildEmptyNotifications('Aucune commande prête');
          }
          return ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: readyOrders.length,
            itemBuilder: (context, index) => _buildNotificationTile(
              readyOrders[index],
              isChef: false,
            ),
          );
        },
      );
    }
  }

  Widget _buildEmptyNotifications(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(OrderModel order, {required bool isChef}) {
    final timeAgo = _getTimeAgo(order.createdAt);
    final bool isRead = _readNotificationIds.contains(order.id);

    final Color accentColor = isRead
        ? AppColors.textTertiary
        : (isChef ? AppColors.warning : AppColors.success);
    final Color backgroundColor = isRead
        ? AppColors.background.withOpacity(0.5)
        : AppColors.background;
    final Color textColor = isRead ? AppColors.textTertiary : AppColors.textPrimary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(isRead ? 0.05 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isChef ? Icons.receipt_long_rounded : Icons.check_circle_rounded,
            color: accentColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                order.type == OrderType.dineIn
                    ? 'Table ${order.tableNumber ?? "N/A"}'
                    : 'À emporter',
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${order.items.length} article(s) • ${order.totalAmount.toStringAsFixed(2)} DH',
              style: TextStyle(
                color: isRead ? AppColors.textTertiary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isChef ? 'Par ${order.serverName}' : 'Il y a $timeAgo',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: isRead ? AppColors.textTertiary : AppColors.textSecondary,
        ),
        onTap: () => _onNotificationTap(order),
      ),
    );
  }

  void _onNotificationTap(OrderModel order) {
    _readNotificationIds.add(order.id);
    setState(() {
      if (_unreadNotificationCount > 0) {
        _unreadNotificationCount--;
      }
    });
    Navigator.pop(context);
    _openMesCommandes();
  }

  void _openMesCommandes() {
    if (!mounted) return;
    // Ensure home tab is selected first
    setState(() => _selectedIndex = 0);
    // Navigate to MesCommandesScreen after frame so the home screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.userRole == 'Serveur') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MesCommandesScreen()));
      }
    });
  }

  void _markAllAsRead() {
    _notifiedPendingOrderIds.forEach((id) => _readNotificationIds.add(id));
    _notifiedReadyOrderIds.forEach((id) => _readNotificationIds.add(id));

    setState(() {
      _unreadNotificationCount = 0;
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'à l\'instant';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}j';
    }
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _userName = doc.data()?['name'] ?? 'Utilisateur';
          _userEmail = user.email ?? '';
        });
      }
    }
  }

  String get _currentTitle {
    switch (_selectedIndex) {
      case 0:
        return _getRoleTitle();
      case 1:
        return 'Mon Profil';
      case 2:
        return 'Paramètres';
      default:
        return 'Restaurant App';
    }
  }

  String _getRoleTitle() {
    switch (widget.userRole) {
      case 'Admin':
        return 'Administration';
      case 'Chef':
        return 'Cuisine';
      case 'Serveur':
        return 'Service';
      default:
        return 'Accueil';
    }
  }

  Color get _roleColor {
    if (widget.userRole == 'Admin') {
      return _warmOrange;
    }
    switch (widget.userRole) {
      case 'Chef':
        return AppColors.chefAccent;
      case 'Serveur':
        return AppColors.serveurAccent;
      default:
        return AppColors.primary;
    }
  }

  List<Widget> _buildPages() {
    return [
      _getHomeScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];
  }

  Widget _getHomeScreen() {
    switch (widget.userRole) {
      case 'Admin':
        return const AdminScreen();
      case 'Chef':
        return const ChefScreen();
      case 'Serveur':
        return const ServeurScreen();
      default:
        return const Center(child: Text('Rôle non reconnu.'));
    }
  }

  Widget _buildDrawer() {
    if (widget.userRole == 'Admin') {
      return const AdminDrawer();
    } else if (widget.userRole == 'Serveur') {
      return const ServeurDrawer();
    } else if (widget.userRole == 'Chef') {
      return const ChefDrawer();
    } 
    // Default empty drawer for robustness, though this case should not be reached
    return const Drawer();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    final useAdminStyle = widget.userRole == 'Admin' || widget.userRole == 'Serveur' || widget.userRole == 'Chef';

    return Scaffold(
      backgroundColor: useAdminStyle ? _cream : AppColors.background,
      appBar: AppBar(
        title: Text(
          _currentTitle,
          style: useAdminStyle ? GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: _deepBrown,
          ) : null,
        ),
        centerTitle: useAdminStyle,
        elevation: 0,
        backgroundColor: useAdminStyle ? _cream : AppColors.surface,
        foregroundColor: useAdminStyle ? _warmOrange : null,
        surfaceTintColor: Colors.transparent,
        iconTheme: useAdminStyle ? const IconThemeData(color: _warmOrange) : null,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: useAdminStyle ? _warmOrange : null,
                onPressed: _showNotificationsPanel,
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadNotificationCount > 9 ? '9+' : '$_unreadNotificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: useAdminStyle ? _cream : AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: useAdminStyle ? _deepBrown.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Accueil', useAdminStyle),
                _buildNavItem(1, Icons.person_outline_rounded, Icons.person_rounded, 'Profil', useAdminStyle),
                _buildNavItem(2, Icons.settings_outlined, Icons.settings_rounded, 'Paramètres', useAdminStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, bool useAdminStyle) {
    final isSelected = _selectedIndex == index;
    final activeColor = useAdminStyle ? _warmOrange : _roleColor;
    final inactiveColor = useAdminStyle ? _deepBrown.withOpacity(0.5) : AppColors.textTertiary;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: useAdminStyle
                  ? GoogleFonts.inter(
                      color: activeColor,
                      fontWeight: FontWeight.w600,
                    )
                  : TextStyle(
                      color: activeColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
