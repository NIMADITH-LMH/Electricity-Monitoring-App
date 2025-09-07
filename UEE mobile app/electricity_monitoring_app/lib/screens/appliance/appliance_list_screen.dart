import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/appliance_model.dart';
import '../../services/appliance_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/background_container.dart';
import 'add_appliance_screen.dart';
import 'edit_appliance_screen.dart';

class ApplianceListScreen extends StatefulWidget {
  static const routeName = '/appliances';

  const ApplianceListScreen({super.key});

  @override
  State<ApplianceListScreen> createState() => _ApplianceListScreenState();
}

class _ApplianceListScreenState extends State<ApplianceListScreen> {
  bool _isLoading = false;
  List<ApplianceModel> _appliances = [];

  @override
  void initState() {
    super.initState();
    _loadAppliances();
  }

  Future<void> _loadAppliances() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final applianceService = Provider.of<ApplianceService>(
        context,
        listen: false,
      );
      await applianceService.fetchAppliances();
      setState(() {
        _appliances = applianceService.appliances;
      });
    } catch (e) {
      debugPrint('Error loading appliances: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'My Appliances'),
      body: BackgroundContainer(
        child: _isLoading
            ? const LoadingIndicator(message: 'Loading appliances...')
            : _buildAppliancesList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddApplianceScreen()),
          ).then(
            (_) => _loadAppliances(),
          ); // Refresh list when returning from add screen
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppliancesList() {
    if (_appliances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Card(
            color: Colors.white.withOpacity(0.85),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: EmptyState(
                icon: Icons.device_hub,
                message:
                    'You haven\'t added any appliances yet. Tap the + button to add your first appliance.',
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appliances.length,
      itemBuilder: (context, index) {
        final appliance = _appliances[index];

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.device_hub,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              appliance.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Power: ${appliance.wattage} W',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.lightTextColor,
                  ),
                ),
                Text(
                  'Usage: ${appliance.dailyUsageHrs} hrs/day',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.lightTextColor,
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditApplianceScreen(appliance: appliance),
                ),
              ).then((updated) {
                if (updated == true) {
                  _loadAppliances();
                }
              });
            },
          ),
        );
      },
    );
  }
}
