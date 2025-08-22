import 'package:flutter/material.dart';
import 'package:lae_app/main.dart'; // To access the global databaseHelper

class PlanningDataDisplayPage extends StatefulWidget {
  const PlanningDataDisplayPage({super.key});

  @override
  State<PlanningDataDisplayPage> createState() =>
      _PlanningDataDisplayPageState();
}

class _PlanningDataDisplayPageState extends State<PlanningDataDisplayPage> {
  late Future<List<Map<String, dynamic>>> _reminders;
  late Future<List<Map<String, dynamic>>> _schedules;
  late Future<List<Map<String, dynamic>>> _quests;
  late Future<List<Map<String, dynamic>>> _routinePlans;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _reminders = databaseHelper.getRecords('Reminders');
    _schedules = databaseHelper.getRecords('Schedules');
    _quests = databaseHelper.getRecords('Quests');
    _routinePlans = databaseHelper.getRecords('Routine_Plan');
    setState(() {}); // Refresh the UI after setting the futures
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synced Planning Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDataTable('Reminders', _reminders),
            const SizedBox(height: 24),
            _buildDataTable('Schedules', _schedules),
            const SizedBox(height: 24),
            _buildDataTable('Quests', _quests),
            const SizedBox(height: 24),
            _buildDataTable('Routine Plans', _routinePlans),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      String title, Future<List<Map<String, dynamic>>> futureData) {
    // Use an ExpansionTile to make the list collapsible
    return ExpansionTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      initiallyExpanded: true, // Start with the tile expanded
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return ListTile(title: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const ListTile(title: Text('No data found.'));
            }

            final records = snapshot.data!;
            // Use a LayoutBuilder to constrain the height of the ListView
            return LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxHeight: 400), // Max height for the list
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      // Use a more descriptive title if 'name' or 'title' exists
                      final recordTitle = record['name'] ??
                          record['title'] ??
                          record['activity_name'] ??
                          'No Title';
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(recordTitle),
                          subtitle: Text(
                            record.toString(),
                            maxLines: 2, // Show only 2 lines
                            overflow:
                                TextOverflow.ellipsis, // Add '...' for overflow
                          ),
                          dense: true,
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 0),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
