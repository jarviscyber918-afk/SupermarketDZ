import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/hive_database.dart';
import '../../../../core/data/models/sale_transaction.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/printer_helper.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/billing_bloc.dart';

class CheckoutModal extends StatefulWidget {
  const CheckoutModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CheckoutModal(),
    );
  }

  @override
  State<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<CheckoutModal> {
  final TextEditingController _cashController = TextEditingController();
  double _cashReceived = 0.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cashController.addListener(() {
      final val = double.tryParse(_cashController.text.trim()) ?? 0.0;
      setState(() {
        _cashReceived = val;
      });
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _setExactAmount(double total) {
    _cashController.text = total.toStringAsFixed(2);
  }

  void _addCash(double amount) {
    final current = double.tryParse(_cashController.text.trim()) ?? 0.0;
    _cashController.text = (current + amount).toStringAsFixed(0);
  }

  Future<void> _processSale({required bool andPrint}) async {
    final billingBloc = context.read<BillingBloc>();
    final cartItems = billingBloc.state.cartItems;
    final totalAmount = billingBloc.state.totalAmount;

    if (cartItems.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final receiptNum = HiveDatabase.getNextReceiptNumber();
    final receiptId = 'REC-${receiptNum.toString().padLeft(4, '0')}';
    final now = DateTime.now();

    final shopState = context.read<ShopBloc>().state;
    String shopName = 'Supermarket DZ';
    String address1 = 'Didouche Mourad, Alger';
    String address2 = '';
    String phone = '+213 555 123 456';
    String footer = 'شكراً لزيارتكم / Merci pour votre visite';

    if (shopState is ShopLoaded) {
      shopName = shopState.shop.name;
      address1 = shopState.shop.addressLine1;
      address2 = shopState.shop.addressLine2;
      phone = shopState.shop.phoneNumber;
      footer = shopState.shop.footerText;
    }

    final saleItems = cartItems
        .map((it) => SaleItem(
              productId: it.product.id,
              name: it.product.name,
              barcode: it.product.barcode,
              quantity: it.quantity,
              price: it.product.price,
              total: it.total,
            ))
        .toList();

    final changeDue =
        _cashReceived >= totalAmount ? _cashReceived - totalAmount : 0.0;

    final transaction = SaleTransaction(
      id: receiptId,
      receiptNumber: receiptNum,
      timestamp: now,
      items: saleItems,
      totalAmount: totalAmount,
      cashReceived: _cashReceived > 0 ? _cashReceived : totalAmount,
      changeDue: changeDue,
      shopName: shopName,
    );

    // 1. Save transaction in Hive salesBox
    await HiveDatabase.recordSale(transaction.toMap());

    // 2. Print receipt if requested
    if (andPrint) {
      final printer = PrinterHelper();
      final itemsMap = saleItems
          .map((it) => {
                'name': it.name,
                'qty': it.quantity,
                'price': it.price,
                'total': it.total,
              })
          .toList();

      await printer.printReceipt(
        shopName: shopName,
        address1: address1,
        address2: address2,
        phone: phone,
        items: itemsMap,
        total: totalAmount,
        cashReceived: _cashReceived > 0 ? _cashReceived : totalAmount,
        changeDue: changeDue,
        receiptId: receiptId,
        footer: footer,
      );
    }

    // 3. Clear cart
    billingBloc.add(ClearCartEvent());

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Vente $receiptId validée avec succès ! (${totalAmount.toStringAsFixed(2)} DA)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillingBloc, BillingState>(
      builder: (context, state) {
        final total = state.totalAmount;
        final changeDue = _cashReceived - total;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            top: 16,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top drag bar
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Checkout / إتمام البيع',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Vérification de la commande et paiement',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Itemized List Summary
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.cartItems.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey[100]),
                    itemBuilder: (context, index) {
                      final item = state.cartItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.quantity}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.product.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${item.total.toStringAsFixed(2)} DA',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Grand Total Banner
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL À PAYER / الإجمالي',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        '${total.toStringAsFixed(2)} DA',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cash Input & Calculation Section
                const Text(
                  'Cash Received / المبلغ المستلم',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cashController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter received cash (e.g. 1000)',
                    prefixIcon: const Icon(Icons.payments_outlined,
                        color: AppTheme.primaryColor),
                    suffixText: 'DA',
                    suffixStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Cash Shortcuts
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickCashChip('Exact / تماماً',
                          () => _setExactAmount(total),
                          isExact: true),
                      const SizedBox(width: 8),
                      _buildQuickCashChip('+200 DA', () => _addCash(200)),
                      const SizedBox(width: 8),
                      _buildQuickCashChip('+500 DA', () => _addCash(500)),
                      const SizedBox(width: 8),
                      _buildQuickCashChip('+1000 DA', () => _addCash(1000)),
                      const SizedBox(width: 8),
                      _buildQuickCashChip('+2000 DA', () => _addCash(2000)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Change Calculation Card
                if (_cashReceived > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: changeDue >= 0
                          ? Colors.green[50]
                          : Colors.amber[50],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: changeDue >= 0
                            ? Colors.green[300]!
                            : Colors.amber[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              changeDue >= 0
                                  ? Icons.change_circle_outlined
                                  : Icons.info_outline,
                              color: changeDue >= 0
                                  ? Colors.green[800]
                                  : Colors.amber[900],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              changeDue >= 0
                                  ? 'MONNAIE À RENDRE / الباقي :'
                                  : 'MANQUE / المتبقي :',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: changeDue >= 0
                                    ? Colors.green[900]
                                    : Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${(changeDue >= 0 ? changeDue : -changeDue).toStringAsFixed(2)} DA',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: changeDue >= 0
                                ? Colors.green[900]
                                : Colors.amber[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    // Valider la vente
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(
                              color: AppTheme.primaryColor, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isProcessing
                            ? null
                            : () => _processSale(andPrint: false),
                        child: const Text(
                          'Valider / تأكيد',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Valider & Imprimer
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                          shadowColor:
                              AppTheme.primaryColor.withValues(alpha: 0.4),
                        ),
                        onPressed: _isProcessing
                            ? null
                            : () => _processSale(andPrint: true),
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.print, size: 20),
                        label: const Text(
                          'Valider & Imprimer / تأكيد وطباعة',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickCashChip(String label, VoidCallback onTap,
      {bool isExact = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isExact
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isExact ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isExact ? Colors.white : AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
