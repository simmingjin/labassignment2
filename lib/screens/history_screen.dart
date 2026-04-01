import 'package:flutter/material.dart';
import '/services/checkin_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  List<Map<String, dynamic>> history = [];

  Future<void> _loadHistory() async {
    final data = await CheckInService.getHistory();
    setState(() {
      history = data.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Check-In History'),
      ),
      body: history.isEmpty
          ? const Center(child: Text("No check-ins yet"))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];

                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text("${item["fairName"]} - ${item["location"]}"),
                  subtitle: Text("Points: ${item["points"]}\nChecked in at: ${item["time"]}")
                );
              },
            ),
    );
  }
}
 
