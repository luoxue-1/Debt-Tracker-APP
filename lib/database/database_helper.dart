import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/debt_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  
  // 使用内存Map模拟数据库
  List<DebtModel> _debts = [];
  int _nextId = 1;
  File? _dataFile;

  DatabaseHelper._privateConstructor() {
    print('初始化数据库');
    _initDatabase();
  }

  // 初始化数据库，加载数据文件
  Future<void> _initDatabase() async {
    try {
      _dataFile = await _getDataFile();
      if (_dataFile!.existsSync()) {
        String jsonData = await _dataFile!.readAsString();
        List<dynamic> debtsList = jsonDecode(jsonData);
        _debts = debtsList.map((item) => DebtModel.fromMap(item)).toList();
        // 计算下一个ID
        if (_debts.isNotEmpty) {
          _nextId = _debts.map((debt) => debt.id!).reduce((a, b) => a > b ? a : b) + 1;
        }
        print('数据加载成功，共 ${_debts.length} 条记录');
      } else {
        print('数据文件不存在，创建新的数据库');
        _debts = [];
        _nextId = 1;
        await _saveData();
      }
    } catch (e) {
      print('初始化数据库失败: $e');
      _debts = [];
      _nextId = 1;
    }
  }

  // 获取数据文件路径
  Future<File> _getDataFile() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/debt_tracker_data.json';
    return File(filePath);
  }

  // 保存数据到文件
  Future<void> _saveData() async {
    try {
      if (_dataFile == null) {
        _dataFile = await _getDataFile();
      }
      List<Map<String, dynamic>> debtsMap = _debts.map((debt) => debt.toMap()).toList();
      String jsonData = jsonEncode(debtsMap);
      await _dataFile!.writeAsString(jsonData);
      print('数据保存成功，共 ${_debts.length} 条记录');
    } catch (e) {
      print('保存数据失败: $e');
    }
  }

  Future<int> insertDebt(DebtModel debt) async {
    try {
      print('插入欠款记录');
      // 为新记录分配ID，如果已有ID则保留
      int id;
      if (debt.id != null) {
        // 保留原始ID
        id = debt.id!;
        // 确保_nextId大于所有现有ID
        if (id >= _nextId) {
          _nextId = id + 1;
        }
      } else {
        // 为新记录分配新ID
        id = _nextId++;
      }
      
      final newDebt = DebtModel(
        id: id,
        name: debt.name,
        amount: debt.amount,
        date: debt.date,
        note: debt.note,
        dueDate: debt.dueDate,
        interestRate: debt.interestRate,
        status: debt.status,
        isLender: debt.isLender,
      );
      _debts.add(newDebt);
      await _saveData();
      print('插入成功，ID: ${newDebt.id}');
      print('当前记录数: ${_debts.length}');
      return newDebt.id!;
    } catch (e) {
      print('插入欠款记录失败: $e');
      throw e;
    }
  }

  Future<List<DebtModel>> getDebts() async {
    print('获取所有欠款记录，共 ${_debts.length} 条');
    return List.from(_debts);
  }

  Future<int> updateDebt(DebtModel debt) async {
    try {
      print('更新欠款记录，ID: ${debt.id}');
      int index = _debts.indexWhere((d) => d.id == debt.id);
      if (index != -1) {
        _debts[index] = debt;
        await _saveData();
        print('更新成功');
        return 1;
      } else {
        print('更新失败：记录不存在');
        return 0;
      }
    } catch (e) {
      print('更新欠款记录失败: $e');
      throw e;
    }
  }

  Future<int> deleteDebt(int id) async {
    try {
      print('删除欠款记录，ID: $id');
      int initialLength = _debts.length;
      _debts.removeWhere((d) => d.id == id);
      await _saveData();
      int deletedCount = initialLength - _debts.length;
      print('删除成功，删除了 $deletedCount 条记录');
      return deletedCount;
    } catch (e) {
      print('删除欠款记录失败: $e');
      throw e;
    }
  }

  Future<List<DebtModel>> getDebtsByStatus(String status) async {
    print('按状态获取欠款记录: $status');
    return _debts.where((debt) => debt.status == status).toList();
  }

  Future<List<DebtModel>> getDebtsByType(bool isLender) async {
    print('按类型获取欠款记录，是否出借人: $isLender');
    return _debts.where((debt) => debt.isLender == isLender).toList();
  }

  Future<double> getTotalByType(bool isLender) async {
    print('按类型获取总金额，是否出借人: $isLender');
    double total = _debts
        .where((debt) => debt.isLender == isLender)
        .fold(0.0, (sum, debt) => sum + debt.amount);
    print('总金额: $total');
    return total;
  }

  Future<double> getTotalByStatus(String status) async {
    print('按状态获取总金额，状态: $status');
    double total = _debts
        .where((debt) => debt.status == status)
        .fold(0.0, (sum, debt) => sum + debt.amount);
    print('总金额: $total');
    return total;
  }

  Future<double> getTotalByTypeAndStatus(bool isLender, String status) async {
    print('按类型和状态获取总金额，是否出借人: $isLender, 状态: $status');
    double total = _debts
        .where((debt) => debt.isLender == isLender && debt.status == status)
        .fold(0.0, (sum, debt) => sum + debt.amount);
    print('总金额: $total');
    return total;
  }

  Future<List<Map<String, dynamic>>> getMonthlySummary() async {
    print('获取按月汇总数据');
    Map<String, Map<bool, double>> monthlyData = {};
    
    for (var debt in _debts) {
      String month = debt.date.substring(0, 7); // YYYY-MM
      if (!monthlyData.containsKey(month)) {
        monthlyData[month] = {true: 0.0, false: 0.0};
      }
      monthlyData[month]![debt.isLender] = monthlyData[month]![debt.isLender]! + debt.amount;
    }
    
    List<Map<String, dynamic>> result = [];
    monthlyData.forEach((month, data) {
      data.forEach((isLender, total) {
        result.add({
          'month': month,
          'isLender': isLender ? 1 : 0,
          'total': total
        });
      });
    });
    
    // 按月份排序
    result.sort((a, b) => b['month'].compareTo(a['month']));
    print('按月汇总数据: $result');
    return result;
  }

  Future<void> clearAllDebts() async {
    try {
      print('清空所有欠款记录');
      _debts.clear();
      _nextId = 1;
      await _saveData();
      print('清空成功，当前记录数: ${_debts.length}');
    } catch (e) {
      print('清空欠款记录失败: $e');
      throw e;
    }
  }
}
