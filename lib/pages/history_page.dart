import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:attedance_app/services/endpoint.dart';
import 'package:attedance_app/services/shared_pref_service.dart';
import 'package:attedance_app/theme/app_colors.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> historyList = [];
  bool isLoading = true;
  bool hasMore = true;
  int currentPage = 1;
  final int pageSize = 10;
  final ScrollController scrollController = ScrollController();

  String startDate = DateFormat('yyyy-MM-01').format(DateTime.now());
  String endDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    fetchData();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          hasMore &&
          !isLoading) {
        currentPage++;
        fetchData();
      }
    });
  }

  Future<void> fetchData() async {
    try {
      final token = await SharedPrefService.getToken();
      if (token == null) throw Exception('Token tidak ditemukan.');

      final url =
          '${Endpoint.baseUrl}/api/absen/history?start=$startDate&end=$endDate&page=$currentPage';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      final List newItems = data['data'] ?? [];

      setState(() {
        isLoading = false;
        if (newItems.length < pageSize) hasMore = false;
        historyList.addAll(newItems);
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil data: $e')));
    }
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        historyList.clear();
        isLoading = true;
        hasMore = true;
        currentPage = 1;
        startDate = DateFormat('yyyy-MM-dd').format(picked.start);
        endDate = DateFormat('yyyy-MM-dd').format(picked.end);
      });
      fetchData();
    }
  }

  String formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('EEEE, dd MMMM yyyy').format(dt);
    } catch (_) {
      return '-';
    }
  }

  String formatTime(String? time) {
    try {
      if (time == null || time.isEmpty) return '-';
      return DateFormat('hh:mm:ss a').format(DateTime.parse(time));
    } catch (_) {
      return '-';
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Widget buildHistoryCard(Map item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            color: Color(0x11000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatDate(item['check_in'] ?? item['check_out'] ?? ''),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item['status'].toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color:
                  item['status'] == 'izin'
                      ? AppColors.warning
                      : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          if (item['check_in'] != null)
            Text("Clock In : ${formatTime(item['check_in'])}"),
          if (item['check_out'] != null)
            Text("Clock Out : ${formatTime(item['check_out'])}"),
          if (item['alasan_izin'] != null)
            Text("Reason : ${item['alasan_izin']}"),
          const SizedBox(height: 4),
          Text(
            item['check_in_address'] ?? 'No address available',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Attendance History"),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: pickDateRange,
            icon: const Icon(Icons.filter_alt_outlined),
          ),
        ],
      ),
      body:
          isLoading && historyList.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : historyList.isEmpty
              ? const Center(child: Text("No attendance records found."))
              : ListView.builder(
                controller: scrollController,
                itemCount: historyList.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == historyList.length) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final item = historyList[index];
                  return buildHistoryCard(item);
                },
              ),
    );
  }
}
