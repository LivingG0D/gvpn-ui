import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const PowerRouteApp());
}

class PowerRouteApp extends StatelessWidget {
  const PowerRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Power Route',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.background,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.card,
          secondary: AppColors.accent,
        ),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _random = Random();
  final List<ServerLocation> _servers = const [
    ServerLocation(
      code: 'IR',
      name: 'Tehran Premium',
      location: 'Iran, Tehran',
      load: 0.23,
    ),
    ServerLocation(
      code: 'DE',
      name: 'Berlin Turbo',
      location: 'Germany, Berlin',
      load: 0.41,
    ),
    ServerLocation(
      code: 'US',
      name: 'Miami Edge',
      location: 'USA, Miami',
      load: 0.32,
    ),
    ServerLocation(
      code: 'SG',
      name: 'Singapore Pro',
      location: 'Singapore',
      load: 0.27,
    ),
  ];

  bool _isConnected = false;
  bool _isBusy = false;
  double _ping = 0;
  double _loss = 0;
  double _jitter = 0;
  late ServerLocation _selectedServer;
  Timer? _statTimer;

  @override
  void initState() {
    super.initState();
    _selectedServer = _servers.first;
    _startStatLoop();
  }

  @override
  void dispose() {
    _statTimer?.cancel();
    super.dispose();
  }

  void _startStatLoop() {
    _statTimer?.cancel();
    _statTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      if (!_isConnected) return;

      setState(() {
        _ping = 18 + _random.nextDouble() * 22; // 18 - 40ms
        _loss = _random.nextDouble() * 2; // 0 - 2%
        _jitter = 1 + _random.nextDouble() * 3; // 1 - 4ms
      });
    });
  }

  Future<void> _toggleConnection() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    await Future.delayed(const Duration(milliseconds: 650));

    setState(() {
      _isConnected = !_isConnected;
      if (!_isConnected) {
        _ping = 0;
        _loss = 0;
        _jitter = 0;
      } else {
        _ping = 22;
        _loss = 0.4;
        _jitter = 1.5;
      }
      _isBusy = false;
    });
  }

  Future<void> _changeServer() async {
    final ServerLocation? newServer =
        await showModalBottomSheet<ServerLocation>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Choose Server',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _servers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final server = _servers[index];
                        final bool isSelected = server == _selectedServer;
                        return ServerTile(
                          server: server,
                          isSelected: isSelected,
                          onTap: () => Navigator.of(context).pop(server),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );

    if (newServer != null && newServer != _selectedServer) {
      setState(() => _selectedServer = newServer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1220), Color(0xFF111D32)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeaderCard(),
                const SizedBox(height: 24),
                StatusCard(
                  isConnected: _isConnected,
                  isBusy: _isBusy,
                  onToggle: _toggleConnection,
                ),
                const SizedBox(height: 24),
                SectionTitle(title: 'Performance', textTheme: textTheme),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: PerformanceStatCard(
                        icon: Icons.show_chart_rounded,
                        label: 'Ping',
                        value: _ping,
                        unit: 'ms',
                        decimals: 0,
                        isActive: _isConnected,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PerformanceStatCard(
                        icon: Icons.wifi_tethering_rounded,
                        label: 'Loss',
                        value: _loss,
                        unit: '%',
                        decimals: 1,
                        isActive: _isConnected,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PerformanceStatCard(
                        icon: Icons.wifi_rounded,
                        label: 'Jitter',
                        value: _jitter,
                        unit: 'ms',
                        decimals: 1,
                        isActive: _isConnected,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SectionTitle(title: 'Connection', textTheme: textTheme),
                const SizedBox(height: 16),
                ConnectionCard(
                  server: _selectedServer,
                  isConnected: _isConnected,
                  onChange: _changeServer,
                ),
                const SizedBox(height: 16),
                FeatureHighlightCard(
                  isConnected: _isConnected,
                  serverName: _selectedServer.name,
                ),
                const SizedBox(height: 36),
                Center(
                  child: Text(
                    'Power Route v1.0 - Optimizing your gaming experience',
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color.fromRGBO(255, 255, 255, 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeaderCard extends StatelessWidget {
  const HeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66030812),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.accent, Color(0xFF4C83FF)],
              ),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Power Route',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gaming Network Optimizer',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color.fromRGBO(255, 255, 255, 0.7),
                ),
              ),
            ],
          ),
          const Spacer(),
          const HeaderIcon(icon: Icons.refresh_rounded),
          const SizedBox(width: 12),
          const HeaderIcon(icon: Icons.settings_rounded),
        ],
      ),
    );
  }
}

class HeaderIcon extends StatelessWidget {
  const HeaderIcon({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class StatusCard extends StatelessWidget {
  const StatusCard({
    required this.isConnected,
    required this.isBusy,
    required this.onToggle,
    super.key,
  });

  final bool isConnected;
  final bool isBusy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: isConnected
              ? const [Color(0xFF133A49), Color(0xFF14343A)]
              : const [Color(0xFF102136), Color(0xFF0C1A2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.05)),
      ),
      child: Column(
        children: [
          Text(
            'Status',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isConnected ? 'Connected' : 'Disconnected',
              key: ValueKey(isConnected),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: onToggle,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: isBusy ? 0.95 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  height: 170,
                  width: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isConnected
                          ? const [Color(0xFF38D39F), Color(0xFF23A78E)]
                          : const [Color(0xFF3869FF), Color(0xFF264BBF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isConnected
                            ? const Color.fromRGBO(35, 167, 142, 0.35)
                            : const Color.fromRGBO(56, 105, 255, 0.35),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(0, 0, 0, 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.power_settings_new_rounded,
                          size: 70,
                          color: Colors.white,
                        ),
                        if (isBusy)
                          const SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                Colors.white54,
                              ),
                              strokeWidth: 3,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isConnected ? 1 : 0.6,
            child: Text(
              isConnected
                  ? 'Optimized route active'
                  : 'Tap to enable optimized routing',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, required this.textTheme, super.key});

  final String title;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class PerformanceStatCard extends StatelessWidget {
  const PerformanceStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.decimals,
    required this.isActive,
    super.key,
  });

  final IconData icon;
  final String label;
  final double value;
  final String unit;
  final int decimals;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.card,
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color.fromRGBO(255, 255, 255, 0.8)),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: isActive
                ? TweenAnimationBuilder<double>(
                    key: ValueKey('value-$label'),
                    tween: Tween<double>(begin: 0, end: value),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, animatedValue, _) {
                      return Text(
                        '${animatedValue.toStringAsFixed(decimals)} $unit',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      );
                    },
                  )
                : Text(
                    '--',
                    key: ValueKey('placeholder-$label'),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class ConnectionCard extends StatelessWidget {
  const ConnectionCard({
    required this.server,
    required this.isConnected,
    required this.onChange,
    super.key,
  });

  final ServerLocation server;
  final bool isConnected;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: const [
                  Icon(Icons.storage_rounded, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    'Server',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onChange,
                icon: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.accent,
                ),
                label: const Text(
                  'Change',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.secondaryCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color.fromRGBO(255, 255, 255, 0.08),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    server.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        server.location,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isConnected ? 1 : 0.6,
                      child: Row(
                        children: [
                          Icon(
                            isConnected
                                ? Icons.signal_cellular_alt
                                : Icons.signal_cellular_off,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(1 - server.load) * 100 ~/ 1}%',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      isConnected ? 'Stable' : 'Standby',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
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

class FeatureHighlightCard extends StatelessWidget {
  const FeatureHighlightCard({
    required this.isConnected,
    required this.serverName,
    super.key,
  });

  final bool isConnected;
  final String serverName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.card,
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.04)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color.fromRGBO(255, 255, 255, 0.08),
            ),
            child: const Icon(Icons.bolt_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isConnected
                  ? _HighlightText(
                      key: const ValueKey('connected-highlight'),
                      title: 'Optimized for Gaming',
                      subtitle:
                          'Route locked via $serverName. Latency and packet loss actively monitored.',
                    )
                  : _HighlightText(
                      key: const ValueKey('disconnected-highlight'),
                      title: 'Power Route Ready',
                      subtitle:
                          'Enable the optimizer to select the best path for your next gaming session.',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightText extends StatelessWidget {
  const _HighlightText({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class ServerTile extends StatelessWidget {
  const ServerTile({
    required this.server,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final ServerLocation server;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.secondaryCard : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? AppColors.accent
              : const Color.fromRGBO(255, 255, 255, 0.03),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color.fromRGBO(255, 255, 255, 0.08),
            ),
            alignment: Alignment.center,
            child: Text(
              server.code,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  server.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  server.location,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Load ${(server.load * 100).toStringAsFixed(0)}%',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Container(
                width: 80,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: server.load.clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, Color(0xFF4C83FF)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onTap,
            icon: Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class ServerLocation {
  const ServerLocation({
    required this.code,
    required this.name,
    required this.location,
    required this.load,
  });

  final String code;
  final String name;
  final String location;
  final double load;
}

class AppColors {
  static const background = Color(0xFF0B1424);
  static const card = Color(0xFF111F36);
  static const secondaryCard = Color(0xFF132541);
  static const accent = Color(0xFF58A6FF);
}
