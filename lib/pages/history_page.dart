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

  Future<void> deleteAbsen(int id) async {
    final token = await SharedPrefService.getToken();
    if (token == null) return;

    final url = '${Endpoint.baseUrl}/api/absen/$id';
    print('URL: $url');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      print('Response: ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          historyList.removeWhere((item) => item['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Berhasil menghapus absen'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Gagal menghapus absen')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus absen: $e')));
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Riwayat Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: pickDateRange,
          ),
        ],
      ),
      body:
          isLoading && historyList.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : historyList.isEmpty
              ? const Center(child: Text('Tidak ada data absensi.'))
              : ListView.builder(
                controller: scrollController,
                itemCount: historyList.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == historyList.length) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final item = historyList[index];
                  return Card(
                    color: AppColors.card,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        '${item['status'].toUpperCase()} - ${item['check_in_address']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item['check_in'] != null)
                            Text(
                              'Masuk: ${item['check_in']}',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          if (item['check_out'] != null)
                            Text(
                              'Keluar: ${item['check_out']}',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          if (item['alasan_izin'] != null)
                            Text(
                              'Alasan: ${item['alasan_izin']}',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Hapus Absen'),
                                  content: const Text(
                                    'Yakin ingin menghapus data ini?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                          );

                          if (confirm == true) {
                            deleteAbsen(item['id']);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
