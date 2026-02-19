class DebtModel {
  int? id;
  String name;
  double amount;
  String date;
  String? note;
  String? dueDate;
  double? interestRate;
  String status;
  bool isLender;

  DebtModel({
    this.id,
    required this.name,
    required this.amount,
    required this.date,
    this.note,
    this.dueDate,
    this.interestRate,
    required this.status,
    required this.isLender,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'date': date,
      'note': note,
      'dueDate': dueDate,
      'interestRate': interestRate,
      'status': status,
      'isLender': isLender ? 1 : 0,
    };
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      date: map['date'],
      note: map['note'],
      dueDate: map['dueDate'],
      interestRate: map['interestRate'],
      status: map['status'],
      isLender: map['isLender'] == 1,
    );
  }

  @override
  String toString() {
    return 'DebtModel{id: $id, name: $name, amount: $amount, date: $date, note: $note, dueDate: $dueDate, interestRate: $interestRate, status: $status, isLender: $isLender}';
  }
}
