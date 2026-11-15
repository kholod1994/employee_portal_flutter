import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/consumable.dart';

class ConsumablesScreen extends StatefulWidget {
  const ConsumablesScreen({super.key});

  @override
  State<ConsumablesScreen> createState() => _ConsumablesScreenState();
}

class _ConsumablesScreenState extends State<ConsumablesScreen> {
  final List<DraftItem> _draftItems = [DraftItem(id: 1, name: '', quantity: '1')];
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _showSuccess = false;
  String? _formError;

  int _nextDraftId = 2;

  // Mock data for demonstration
  final List<ConsumableRequest> _myRequests = [
    ConsumableRequest(
      id: '1',
      employeeName: 'أحمد محمد',
      employeeNumber: 'EMP001',
      items: [
        ConsumableItem(name: 'أقلام', quantity: 10),
        ConsumableItem(name: 'دفاتر', quantity: 5),
      ],
      notes: 'أحتاجها للعمل اليومي',
      submittedAt: BigInt.from(DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch),
      decidedAt: null,
      status: ConsumableStatus.pending,
      stage: ApprovalStage.directManager,
      currentApproverName: 'المدير المباشر',
    ),
  ];

  final List<ConsumableRequest> _pendingApprovals = [
    ConsumableRequest(
      id: '2',
      employeeName: 'سارة علي',
      employeeNumber: 'EMP002',
      items: [
        ConsumableItem(name: 'ورق A4', quantity: 20),
      ],
      notes: 'للطباعة',
      submittedAt: BigInt.from(DateTime.now().subtract(const Duration(hours: 5)).millisecondsSinceEpoch),
      decidedAt: null,
      status: ConsumableStatus.pending,
      stage: ApprovalStage.directManager,
    ),
  ];

  final List<ConsumableRequest> _processedApprovals = [
    ConsumableRequest(
      id: '3',
      employeeName: 'خالد عمر',
      employeeNumber: 'EMP003',
      items: [
        ConsumableItem(name: 'مكبر صوت', quantity: 1),
      ],
      notes: 'للاجتماعات',
      submittedAt: BigInt.from(DateTime.now().subtract(const Duration(days: 5)).millisecondsSinceEpoch),
      decidedAt: BigInt.from(DateTime.now().subtract(const Duration(days: 4)).millisecondsSinceEpoch),
      status: ConsumableStatus.approved,
      stage: ApprovalStage.completed,
    ),
  ];

  bool get _isManager => true; // Mock: determine if user is manager

  List<ConsumableItem> get _validItems {
    return _draftItems
        .map((item) => ConsumableItem(
              name: item.name.trim(),
              quantity: int.tryParse(item.quantity) ?? 0,
            ))
        .where((item) => item.name.isNotEmpty && item.quantity > 0)
        .toList();
  }

  bool get _hasInvalidRow {
    return _draftItems.any((item) =>
        item.name.trim().isEmpty ||
        int.tryParse(item.quantity) == null ||
        int.tryParse(item.quantity)! <= 0);
  }

  bool get _isBlocked => _validItems.isEmpty || _hasInvalidRow;

  void _updateItem(int id, {String? name, String? quantity}) {
    setState(() {
      final index = _draftItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        if (name != null) _draftItems[index].name = name;
        if (quantity != null) _draftItems[index].quantity = quantity;
      }
    });
  }

  void _addItem() {
    setState(() {
      _draftItems.add(DraftItem(id: _nextDraftId++, name: '', quantity: '1'));
    });
  }

  void _removeItem(int id) {
    setState(() {
      if (_draftItems.length > 1) {
        _draftItems.removeWhere((item) => item.id == id);
      }
    });
  }

  void _handleSubmit() {
    setState(() {
      _formError = null;
      _showSuccess = false;
    });

    if (_isBlocked) {
      setState(() {
        _formError = 'يرجى ملء جميع الحقول المطلوبة';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
        _draftItems.clear();
        _draftItems.add(DraftItem(id: _nextDraftId++, name: '', quantity: '1'));
        _notesController.clear();
      });

      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _showSuccess = false;
        });
      });
    });
  }

  String _formatDateTime(BigInt timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
      return DateFormat('MMM d, yyyy, h:mm a').format(date);
    } catch (e) {
      return '';
    }
  }

  String _getStatusText(ConsumableStatus status) {
    switch (status) {
      case ConsumableStatus.pending:
        return 'قيد المعالجة';
      case ConsumableStatus.approved:
        return 'موافق عليه';
      case ConsumableStatus.rejected:
        return 'مرفوض';
    }
  }

  Color _getStatusColor(ConsumableStatus status) {
    switch (status) {
      case ConsumableStatus.pending:
        return const Color(0xFFF59E0B); // warning
      case ConsumableStatus.approved:
        return const Color(0xFF10B981); // success
      case ConsumableStatus.rejected:
        return const Color(0xFFEF4444); // danger
    }
  }

  String _getStageText(ApprovalStage stage) {
    switch (stage) {
      case ApprovalStage.directManager:
        return 'المدير المباشر';
      case ApprovalStage.upperManager:
        return 'المدير الأعلى';
      case ApprovalStage.completed:
        return 'مكتمل';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5F4E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('المستهلكات'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Section
            _buildFormSection(),
            const SizedBox(height: 24),

            // My Requests Section
            _buildMyRequestsSection(),
            const SizedBox(height: 24),

            // Approvals Section (Manager only)
            if (_isManager) _buildApprovalsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A5F4E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Color(0xFF1A5F4E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'طلب مستهلكات جديد',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A5F4E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items List
          Column(
            children: _draftItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildItemRow(item, index);
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Add Item Button
          OutlinedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('إضافة عنصر'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: BorderSide(color: Colors.grey.shade300, style: BorderStyle.solid),
              foregroundColor: Colors.grey.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notes Field
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'ملاحظات',
              hintText: 'أضف ملاحظات إضافية...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              errorText: _formError,
            ),
          ),

          const SizedBox(height: 16),

          // Success Message
          if (_showSuccess)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'تم إرسال الطلب بنجاح',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, size: 20),
              label: Text(_isSubmitting ? 'جاري الإرسال...' : 'إرسال الطلب'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A5F4E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(DraftItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'اسم العنصر',
                hintText: 'مثال: أقلام',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) => _updateItem(item.id, name: value),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الكمية',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) => _updateItem(item.id, quantity: value),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _draftItems.length > 1 ? () => _removeItem(item.id) : null,
            icon: const Icon(Icons.delete_outline),
            color: Colors.grey.shade600,
            disabledColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildMyRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'طلباتي السابقة',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        if (_myRequests.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'لا توجد طلبات سابقة',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: _myRequests.asMap().entries.map((entry) {
              return _buildHistoryRow(entry.value, entry.key);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildHistoryRow(ConsumableRequest request, int index) {
    final submitted = _formatDateTime(request.submittedAt);
    final decided = request.decidedAt != null ? _formatDateTime(request.decidedAt!) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${request.items.length} عنصر',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _getStatusColor(request.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusText(request.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(request.status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: request.items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '×${item.quantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow('المرحلة', _getStageText(request.stage)),
                _buildDetailRow('تاريخ التقديم', submitted),
                if (decided != null) _buildDetailRow('تاريخ القرار', decided),
                if (request.status == ConsumableStatus.pending &&
                    request.currentApproverName != null)
                  _buildDetailRow(
                    'الموافق الحالي',
                    request.currentApproverName!,
                  ),
              ],
            ),
          ),
          if (request.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request.notes,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApprovalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الموافقات المعلقة',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'راجع ووافق على طلبات المستهلكات من فريقك',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),

        // Pending Approvals
        Row(
          children: [
            const Text(
              'قيد المعالجة',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_pendingApprovals.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_pendingApprovals.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                'لا توجد موافقات معلقة',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Column(
            children: _pendingApprovals.asMap().entries.map((entry) {
              return _buildApprovalCard(entry.value, entry.key, isPending: true);
            }).toList(),
          ),

        const SizedBox(height: 24),

        // Processed Approvals
        Row(
          children: [
            const Text(
              'تمت المعالجة',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_processedApprovals.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_processedApprovals.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                'لا توجد موافقات معالجة',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Column(
            children: _processedApprovals.asMap().entries.map((entry) {
              return _buildApprovalCard(entry.value, entry.key, isPending: false);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildApprovalCard(ConsumableRequest item, int index, {required bool isPending}) {
    final submitted = _formatDateTime(item.submittedAt);
    final decided = item.decidedAt != null ? _formatDateTime(item.decidedAt!) : null;
    final forwarded = !isPending && item.status == ConsumableStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A5F4E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Color(0xFF1A5F4E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.employeeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: forwarded
                                ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                                : _getStatusColor(item.status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: forwarded
                                      ? const Color(0xFF3B82F6)
                                      : _getStatusColor(item.status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                forwarded ? 'تم التحويل' : _getStatusText(item.status),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: forwarded
                                      ? const Color(0xFF3B82F6)
                                      : _getStatusColor(item.status),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.employeeNumber,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('•'),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStageText(item.stage),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'العناصر المطلوبة',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: item.items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '×${item.quantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow('تاريخ التقديم', submitted),
                if (decided != null) _buildDetailRow('تاريخ القرار', decided),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ملاحظات',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.notes.trim().isEmpty ? 'لا توجد ملاحظات' : item.notes,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
            ),
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A5F4E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text('موافقة'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text('رفض'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class DraftItem {
  final int id;
  String name;
  String quantity;

  DraftItem({
    required this.id,
    required this.name,
    required this.quantity,
  });
}
