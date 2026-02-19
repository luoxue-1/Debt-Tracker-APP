import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:debt_tracker/database/database_helper.dart';
import 'package:debt_tracker/models/debt_model.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

// 条件导入dart:html，仅在web平台可用
import 'dart:html' as html if (dart.library.io) 'dart:io';

class ProfileScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  final Function()? onDataUpdated;

  const ProfileScreen({super.key, this.onThemeChanged, this.onDataUpdated});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;

  Future<void> _exportData() async {
    try {
      // 获取所有数据
      List<DebtModel> debts = await DatabaseHelper.instance.getDebts();
      
      if (debts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有数据可导出')),
        );
        return;
      }
      
      // 转换为JSON
      List<Map<String, dynamic>> debtsMap = debts.map((debt) => debt.toMap()).toList();
      String jsonData = jsonEncode(debtsMap);
      
      // 生成文件名（使用当前日期）
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String fileName = 'debt_tracker_backup_$currentDate.json';
      
      // 在Web环境中使用下载
      if (kIsWeb) {
        // 对于Web平台，使用dart:html来实现文件下载
        try {
          // 创建Blob对象
          final blob = html.Blob([jsonData], 'application/json');
          // 创建下载链接
          final url = html.Url.createObjectUrlFromBlob(blob);
          // 创建<a>标签
          final anchor = html.document.createElement('a') as html.AnchorElement
            ..href = url
            ..download = fileName
            ..style.display = 'none';
          // 添加到文档并点击
          html.document.body?.append(anchor);
          anchor.click();
          // 清理
          anchor.remove();
          html.Url.revokeObjectUrl(url);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('数据已导出为: $fileName')),
          );
        } catch (webError) {
          print('Web平台导出失败: $webError');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Web平台导出失败，请重试')),
          );
        }
      } else {
        // 在移动设备上保存到文件系统
        String? selectedDirectory;
        try {
          // 尝试让用户选择文件夹
          selectedDirectory = await FilePicker.platform.getDirectoryPath(
            dialogTitle: '选择保存位置',
          );
        } catch (e) {
          print('选择文件夹失败: $e');
        }
        
        Directory directory;
        if (selectedDirectory != null) {
          // 用户选择了文件夹
          directory = Directory(selectedDirectory);
        } else {
          // 用户未选择文件夹，使用默认位置
          Directory? extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            directory = extDir;
          } else {
            directory = await getApplicationDocumentsDirectory();
          }
        }
        
        String filePath = '${directory.path}/$fileName';
        File file = File(filePath);
        await file.writeAsString(jsonData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('数据已导出到: $filePath')),
        );
      }
    } catch (e) {
      print('导出数据失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导出数据失败，请重试')),
      );
    }
  }

  Future<void> _importData() async {
    try {
      // 打开文件选择器
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择备份文件',
      );

      if (result == null) {
        // 用户取消选择
        return;
      }

      // 显示确认导入对话框
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认导入'),
          content: const Text('导入数据会覆盖现有数据，确定要继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // 读取文件
                  String jsonData;
                  if (kIsWeb) {
                    // 在Web平台上使用bytes属性
                    final bytes = result.files.single.bytes;
                    if (bytes != null) {
                      jsonData = String.fromCharCodes(bytes);
                    } else {
                      throw Exception('无法读取文件内容');
                    }
                  } else {
                    // 在其他平台上使用path属性
                    File file = File(result.files.single.path!);
                    jsonData = await file.readAsString();
                  }
                  
                  // 解析JSON
                  List<dynamic> debtsList = jsonDecode(jsonData);
                  List<DebtModel> debts = debtsList.map((item) {
                    DebtModel debt = DebtModel.fromMap(item);
                    // 处理逾期状态，转换为待还
                    if (debt.status == '逾期') {
                      debt.status = '待还';
                    }
                    // 确保状态有效，如果为空或不是有效的状态值，设置为待还
                    if (debt.status == null || debt.status.isEmpty || (debt.status != '待还' && debt.status != '已还')) {
                      debt.status = '待还';
                    }
                    return debt;
                  }).toList();
                  
                  // 清空现有数据
                  await DatabaseHelper.instance.clearAllDebts();
                  // 导入新数据
                  for (var debt in debts) {
                    await DatabaseHelper.instance.insertDebt(debt);
                  }
                  
                  Navigator.pop(context);
                  // 通知上一个页面数据已更新
                  if (widget.onDataUpdated != null) {
                    widget.onDataUpdated!();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('成功导入 ${debts.length} 条记录')),
                  );
                } catch (e) {
                  print('导入数据失败: $e');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('导入数据失败，请检查文件格式')),
                  );
                }
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('选择文件失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('选择文件失败，请重试')),
      );
    }
  }

  Future<void> _clearAllData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有数据吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              // 这里应该实现清空数据库的功能
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据已清空')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 初始化深色模式状态为false，在build方法中更新
    _isDarkMode = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在didChangeDependencies中获取MediaQuery
    var brightness = MediaQuery.of(context).platformBrightness;
    if (_isDarkMode != (brightness == Brightness.dark)) {
      setState(() {
        _isDarkMode = brightness == Brightness.dark;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text('用户', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('欠款记账App v1.0.0', style: TextStyle(color: Theme.of(context).hintColor)),
                  const SizedBox(height: 4),
                  Text('当前版本日期: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}', style: TextStyle(color: Theme.of(context).hintColor)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('深色模式'),
                  trailing: Switch(
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        _isDarkMode = value;
                        if (widget.onThemeChanged != null) {
                          widget.onThemeChanged!(value ? ThemeMode.dark : ThemeMode.light);
                        }
                      });
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('关于应用'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('关于欠款记账App'),
                        content: const Text('这是一个简单的欠款记账应用，帮助您管理个人借款和贷款记录。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('导出数据'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportData,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('导入数据'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _importData,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('清空数据'),
                  textColor: Colors.red,
                  onTap: _clearAllData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
