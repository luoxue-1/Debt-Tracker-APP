import 'package:flutter/material.dart';
import 'package:debt_tracker/database/database_helper.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  double _totalLent = 0.0;
  double _totalBorrowed = 0.0;
  double _totalToReceive = 0.0;
  double _totalToPay = 0.0;
  double _totalOverdue = 0.0;
  List<Map<String, dynamic>> _monthlySummary = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  String _selectedMonth = 'recent'; // 默认选择最近三个月

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取总借出（所有用户的借出之和）
      _totalLent = await DatabaseHelper.instance.getTotalByType(true);
      
      // 获取总还款（所有用户的还款之和）
      _totalBorrowed = await DatabaseHelper.instance.getTotalByType(false);
      
      // 待收款 = 总借出 - 总还款
      _totalToReceive = _totalLent - _totalBorrowed;

      // 获取按月汇总数据
      _monthlySummary = await DatabaseHelper.instance.getMonthlySummary();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('加载统计数据失败: $e');
      setState(() {
        _isLoading = false;
        _totalLent = 0.0;
        _totalBorrowed = 0.0;
        _totalToReceive = 0.0;
        _monthlySummary = [];
      });
    }
  }

  // 获取指定月份的汇总数据
  List<Map<String, dynamic>> _getMonthlyDataForSelectedMonth() {
    if (_selectedMonth == 'recent') {
      // 显示最近三个月的数据
      return _getRecentThreeMonthsData();
    } else if (_selectedMonth.isEmpty) {
      return _monthlySummary;
    }
    return _monthlySummary.where((item) => item['month'] == _selectedMonth).toList();
  }

  // 获取最近三个月的数据
  List<Map<String, dynamic>> _getRecentThreeMonthsData() {
    // 获取当前日期
    DateTime now = DateTime.now();
    List<String> recentMonths = [];
    
    // 生成最近三个月的月份字符串（YYYY-MM格式）
    for (int i = 0; i < 3; i++) {
      DateTime month = DateTime(now.year, now.month - i, 1);
      String monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      recentMonths.add(monthStr);
    }
    
    // 筛选出最近三个月的数据
    return _monthlySummary.where((item) => recentMonths.contains(item['month'].toString())).toList();
  }

  // 获取所有月份列表
  List<String> _getAllMonths() {
    Set<String> months = {};
    for (var item in _monthlySummary) {
      months.add(item['month'].toString());
    }
    return months.toList()..sort((a, b) => b.compareTo(a));
  }

  // 临时替换图表为文本列表，避免fl_chart版本冲突
  Widget _buildMonthlySummary() {
    List<Map<String, dynamic>> monthlyData = _getMonthlyDataForSelectedMonth();
    
    if (monthlyData.isEmpty) {
      return const Center(child: Text('暂无月度数据'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: monthlyData.length,
      itemBuilder: (context, index) {
        var item = monthlyData[index];
        String type = item['isLender'] == 1 ? '借出' : '还款'; // 将"借入"修改为"还款"
        String month = item['month'].toString();
        double amount = double.tryParse(item['total'].toString()) ?? 0.0;

        return ListTile(
          title: Text('$month - $type'),
          trailing: Text('¥${amount.toStringAsFixed(2)}', style: TextStyle(
              color: item['isLender'] == 1 ? Colors.blue : Colors.green, // 还款使用绿色
              fontWeight: FontWeight.bold
          )),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadStatistics,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 按月汇总（添加月份选择器）
              const Text('按月汇总', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // 月份选择器
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedMonth,
                  items: [
                    const DropdownMenuItem(value: 'recent', child: Text('最近三个月')),
                    const DropdownMenuItem(value: '', child: Text('全部月份')),
                    ..._getAllMonths().map((month) {
                      return DropdownMenuItem(value: month, child: Text(month));
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value ?? 'recent';
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '月份',
                  ),
                ),
              ),
              
              _buildMonthlySummary(),
              
              // 总览卡片（以待收款、总欠款、总收款的顺序排列）
              const SizedBox(height: 24),
              const Text('总览', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('待收款', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('¥${_totalToReceive.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _totalToReceive > 0 ? Colors.red : Colors.green)),
                          const SizedBox(height: 2),
                          const Text('总借出与总还款之差', style: TextStyle(fontSize: 8, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('总欠款', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('¥${_totalLent.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                          const SizedBox(height: 2),
                          const Text('所有用户的借出之和', style: TextStyle(fontSize: 8, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('总收款', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('¥${_totalBorrowed.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 2),
                          const Text('所有用户的还款之和', style: TextStyle(fontSize: 8, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 保留原有MonthlyData模型，避免其他代码依赖报错
class MonthlyData {
  final String month;
  final double amount;

  MonthlyData(this.month, this.amount);
}