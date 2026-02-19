import 'package:flutter/material.dart';
import 'package:debt_tracker/screens/add_edit_debt_screen.dart';
import 'package:debt_tracker/screens/statistics_screen.dart';
import 'package:debt_tracker/screens/profile_screen.dart';
import 'package:debt_tracker/models/debt_model.dart';
import 'package:debt_tracker/database/database_helper.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;

  const HomeScreen({super.key, this.onThemeChanged});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<DebtModel> _debts = [];
  List<DebtModel> _filteredDebts = [];
  String _filter = '全部';
  String _sortBy = '时间';
  String _searchQuery = '';
  bool _isLoading = true;

  late List<Widget> _screens;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    try {
      _screens = [
        const HomeContent(),
        const StatisticsScreen(),
        ProfileScreen(
          onThemeChanged: widget.onThemeChanged,
          onDataUpdated: _loadDebts,
        ),
      ];
    } catch (e) {
      print('初始化页面失败: $e');
      _screens = [
        const HomeContent(),
        const HomeContent(),
        const HomeContent(),
      ];
    }
    _loadDebts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDebts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      List<DebtModel> debts = await DatabaseHelper.instance.getDebts();
      
      // 筛选
      if (_filter != '全部') {
        debts = debts.where((debt) => debt.status == _filter).toList();
      }
      
      // 搜索
      if (_searchQuery.isNotEmpty) {
        String query = _searchQuery.toLowerCase();
        debts = debts.where((debt) {
          // 搜索借款人姓名和备注
          bool nameMatch = debt.name.toLowerCase().contains(query);
          bool noteMatch = debt.note != null && debt.note!.toLowerCase().contains(query);
          return nameMatch || noteMatch;
        }).toList();
      }
      
      // 排序
      if (_sortBy == '时间') {
        debts.sort((a, b) => b.date.compareTo(a.date));
      } else if (_sortBy == '金额') {
        debts.sort((a, b) => b.amount.compareTo(a.amount));
      } else if (_sortBy == '状态') {
        Map<String, int> statusOrder = {'逾期': 0, '待还': 1, '已还': 2};
        debts.sort((a, b) => statusOrder[a.status]!.compareTo(statusOrder[b.status]!));
      }
      
      setState(() {
        _debts = debts;
        _isLoading = false;
      });
    } catch (e) {
      print('加载欠款记录失败: $e');
      setState(() {
        _isLoading = false;
        _debts = [];
      });
    }
  }

  void _onSearchTextChanged(String text) {
    setState(() {
      _searchQuery = text;
      _loadDebts();
    });
  }

  Future<void> _refreshDebts() async {
    await _loadDebts();
  }

  Future<void> _navigateToAddDebt() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const AddEditDebtScreen()),
    );
    if (result == true) {
      _loadDebts();
    }
  }

  Future<void> _navigateToEditDebt(DebtModel debt) async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => AddEditDebtScreen(debt: debt)),
    );
    if (result == true) {
      _loadDebts();
    }
  }

  Future<void> _markAsPaid(DebtModel debt) async {
    // 显示确认弹窗
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认标记'),
        content: const Text('确定要标记此记录为已还吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              // 标记为已还
              debt.status = '已还';
              await DatabaseHelper.instance.updateDebt(debt);
              _loadDebts();
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDebt(int id) async {
    await DatabaseHelper.instance.deleteDebt(id);
    _loadDebts();
  }

  Widget _buildDebtCard(DebtModel debt) {
    return Slidable(
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _navigateToEditDebt(debt),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '编辑',
          ),
          SlidableAction(
            onPressed: (context) => _markAsPaid(debt),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.check,
            label: '已还',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认删除'),
                  content: const Text('确定要删除这条记录吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        _deleteDebt(debt.id!);
                        Navigator.pop(context);
                      },
                      child: const Text('删除'),
                    ),
                  ],
                ),
              );
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
          ),
        ],
      ),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    debt.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    debt.isLender ? '出借' : '还款',
                    style: TextStyle(
                      color: debt.isLender ? Colors.blue : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '金额: ¥${debt.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text('日期: ${debt.date}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (debt.note != null) Text(debt.note!),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: debt.status == '待还' ? Colors.yellow[700] : Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      debt.status,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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

  // 计算指定借款人的剩余未还金额
  double _calculateRemainingAmount(String name) {
    // 获取该借款人的所有出借记录（待还状态）
    List<DebtModel> lendRecords = _debts.where((debt) => 
      debt.name == name && debt.isLender && debt.status == '待还'
    ).toList();
    
    // 获取该借款人的所有还款记录
    List<DebtModel> repayRecords = _debts.where((debt) => 
      debt.name == name && !debt.isLender
    ).toList();
    
    // 计算总出借金额
    double totalLent = lendRecords.fold(0.0, (sum, debt) => sum + debt.amount);
    
    // 计算总还款金额
    double totalRepaid = repayRecords.fold(0.0, (sum, debt) => sum + debt.amount);
    
    // 计算剩余未还金额
    return totalLent - totalRepaid;
  }

  // 构建剩余未还金额显示组件
  Widget _buildRemainingAmountWidget() {
    if (_searchQuery.isNotEmpty && _debts.isNotEmpty) {
      // 获取唯一的借款人列表
      List<String> uniqueNames = _debts.map((debt) => debt.name).toSet().toList();
      if (uniqueNames.length == 1) {
        String name = uniqueNames[0];
        double remaining = _calculateRemainingAmount(name);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 2,
            color: remaining > 0 ? Colors.yellow[50] : Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$name 的剩余未还金额',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '¥${remaining.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: remaining > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text('欠款记账'),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      _filter = value;
                      _loadDebts();
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: '全部', child: Text('全部')),
                    const PopupMenuItem(value: '待还', child: Text('待还')),
                    const PopupMenuItem(value: '已还', child: Text('已还')),
                    const PopupMenuItem(value: '逾期', child: Text('逾期')),
                  ],
                  icon: const Icon(Icons.filter_list),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      _sortBy = value;
                      _loadDebts();
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: '时间', child: Text('按时间')),
                    const PopupMenuItem(value: '金额', child: Text('按金额')),
                    const PopupMenuItem(value: '状态', child: Text('按状态')),
                  ],
                  icon: const Icon(Icons.sort),
                ),
              ],
            )
          : null,
      body: _currentIndex == 0
          ? _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // 顶部操作栏：搜索框和添加按钮
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // 搜索框
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchTextChanged,
                              decoration: InputDecoration(
                                hintText: '搜索借款人或备注',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          _onSearchTextChanged('');
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          ),
                          // 添加按钮
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _navigateToAddDebt,
                            icon: const Icon(Icons.add),
                            label: const Text('添加'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 显示剩余未还金额（如果有搜索结果）
                    _buildRemainingAmountWidget(),
                    // 欠款列表
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshDebts,
                        child: _debts.isEmpty
                            ? const Center(child: Text('暂无欠款记录'))
                            : ListView.builder(
                                itemCount: _debts.length,
                                itemBuilder: (context, index) => _buildDebtCard(_debts[index]),
                              ),
                      ),
                    ),
                  ],
                )
          : _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            // 当切换到首页时，重新加载数据
            if (index == 0) {
              _loadDebts();
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '统计',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('首页内容'),
    );
  }
}
