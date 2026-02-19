import 'package:flutter/material.dart';
import 'package:debt_tracker/models/debt_model.dart';
import 'package:debt_tracker/database/database_helper.dart';
import 'package:intl/intl.dart';

class AddEditDebtScreen extends StatefulWidget {
  final DebtModel? debt;

  const AddEditDebtScreen({super.key, this.debt});

  @override
  _AddEditDebtScreenState createState() => _AddEditDebtScreenState();
}

class _AddEditDebtScreenState extends State<AddEditDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _noteController;
  late TextEditingController _dueDateController;
  late TextEditingController _interestRateController;
  late bool _isLender; // true: 出借, false: 还款
  late String _status;

  @override
  void initState() {
    super.initState();
    if (widget.debt != null) {
      _nameController = TextEditingController(text: widget.debt!.name);
      _amountController = TextEditingController(text: widget.debt!.amount.toString());
      _dateController = TextEditingController(text: widget.debt!.date);
      _noteController = TextEditingController(text: widget.debt!.note ?? '');
      _isLender = widget.debt!.isLender;
      // 确保状态有效，如果不是有效的状态值，设置为待还
      if (widget.debt!.status != '待还' && widget.debt!.status != '已还') {
        _status = '待还';
      } else {
        _status = widget.debt!.status;
      }
    } else {
      _nameController = TextEditingController();
      _amountController = TextEditingController();
      _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
      _noteController = TextEditingController();
      _isLender = true;
      _status = '待还'; // 默认为出借，状态为待还
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // 当切换出借/还款时，更新状态
  void _onTypeChanged(bool? value) {
    if (value != null) {
      setState(() {
        _isLender = value;
        // 根据类型设置默认状态
        _status = value ? '待还' : '已还';
      });
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveDebt() async {
    if (_formKey.currentState!.validate()) {
      try {
        print('开始保存欠款记录');
        print('姓名: ${_nameController.text}');
        print('金额: ${_amountController.text}');
        print('日期: ${_dateController.text}');
        print('状态: $_status');
        print('类型: ${_isLender ? '出借' : '还款'}');
        
        final debt = DebtModel(
          id: widget.debt?.id,
          name: _nameController.text,
          amount: double.parse(_amountController.text),
          date: _dateController.text,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          dueDate: null, // 移除到期日
          interestRate: null, // 移除利率
          status: _status,
          isLender: _isLender,
        );

        print('创建DebtModel对象成功');

        if (widget.debt != null) {
          print('更新欠款记录');
          int result = await DatabaseHelper.instance.updateDebt(debt);
          print('更新结果: $result');
        } else {
          print('插入新欠款记录');
          int result = await DatabaseHelper.instance.insertDebt(debt);
          print('插入结果: $result');
        }

        print('保存成功，返回上一页');
        Navigator.pop(context, true);
      } catch (e) {
        print('保存欠款记录失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } else {
      print('表单验证失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.debt == null ? '新增记录' : '编辑记录'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 类型选择：出借或还款
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('出借'),
                      value: true,
                      groupValue: _isLender,
                      onChanged: _onTypeChanged,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('还款'),
                      value: false,
                      groupValue: _isLender,
                      onChanged: _onTypeChanged,
                    ),
                  ),
                ],
              ),
              
              // 对方姓名
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '对方姓名'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入对方姓名';
                  }
                  return null;
                },
              ),
              
              // 金额
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: '金额'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入金额';
                  }
                  if (double.tryParse(value) == null) {
                    return '请输入有效的金额';
                  }
                  return null;
                },
              ),
              
              // 日期
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: '日期',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, _dateController),
                  ),
                ),
                readOnly: true,
              ),
              
              // 备注
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: '备注'),
                maxLines: 3,
              ),
              
              const SizedBox(height: 20),
              
              // 状态（可修改）
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: '状态',
                  border: OutlineInputBorder(),
                ),
                items: ['待还', '已还'].map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              
              const SizedBox(height: 30),
              
              // 保存按钮
              ElevatedButton(
                onPressed: _saveDebt,
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
