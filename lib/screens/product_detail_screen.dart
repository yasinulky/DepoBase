import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../theme/theme.dart';
import '../models/models.dart';
import 'add_product_screen.dart';

/// Product Detail Screen - Ürün Detay Ekranı
class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => AddProductScreen(editProduct: product))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: 24),
          _buildStockCard(context, isDark),
          const SizedBox(height: 24),
          _buildInfoSection(context, isDark),
          const SizedBox(height: 24),
          _buildMovementsSection(context, isDark),
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'out',
            backgroundColor: AppTheme.dangerColor,
            onPressed: () => _showMovementDialog(context, MovementType.stockOut),
            icon: const Icon(Icons.remove_rounded),
            label: const Text('Çıkış'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'in',
            backgroundColor: AppTheme.secondaryColor,
            onPressed: () => _showMovementDialog(context, MovementType.stockIn),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Giriş'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted;
    
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(product.name[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: textColor)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.qr_code, size: 16, color: mutedColor),
                const SizedBox(width: 4),
                Text(product.sku, style: TextStyle(color: mutedColor)),
              ]),
              if (product.isLowStock)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('⚠️ Düşük Stok',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.dangerColor, fontWeight: FontWeight.w500)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockCard(BuildContext context, bool isDark) {
    final percentage = (product.quantity / product.minStock * 100).clamp(0, 100);
    final mutedColor = isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStockInfo('Mevcut', '${product.quantity}', AppTheme.primaryColor, mutedColor),
              Container(width: 1, height: 40, color: borderColor),
              _buildStockInfo('Minimum', '${product.minStock}', AppTheme.warningColor, mutedColor),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                  product.isLowStock ? AppTheme.dangerColor : AppTheme.secondaryColor),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockInfo(String label, String value, Color color, Color mutedColor) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: mutedColor)),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, bool isDark) {
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bilgiler', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.category_outlined, 'Kategori', product.category, textColor, mutedColor),
          _buildInfoRow(Icons.location_on_outlined, 'Konum', product.location, textColor, mutedColor),
          _buildInfoRow(Icons.calendar_today_outlined, 'Eklenme',
              DateFormat('dd MMM yyyy', 'tr_TR').format(product.createdAt), textColor, mutedColor),
          if (product.description != null)
            _buildInfoRow(Icons.notes_outlined, 'Açıklama', product.description!, textColor, mutedColor),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color textColor, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: mutedColor)),
                Text(
                  value, 
                  style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsSection(BuildContext context, bool isDark) {
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;
    
    return FutureBuilder<List<StockMovement>>(
      future: context.read<ProductProvider>().getProductMovements(product.id!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final movements = snapshot.data!.take(5).toList();
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Son Hareketler',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
              const SizedBox(height: 16),
              ...movements.map((m) => _MovementItem(movement: m, isDark: isDark)),
            ],
          ),
        );
      },
    );
  }

  void _showMovementDialog(BuildContext context, MovementType type) {
    final controller = TextEditingController();
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == MovementType.stockIn ? 'Stok Girişi' : 'Stok Çıkışı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Miktar'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Not (Opsiyonel)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    type == MovementType.stockIn ? AppTheme.secondaryColor : AppTheme.dangerColor),
            onPressed: () async {
              final qty = int.tryParse(controller.text);
              if (qty != null && qty > 0) {
                final movement = StockMovement(
                  productId: product.id!,
                  type: type,
                  quantity: qty,
                  note: noteController.text.isEmpty ? null : noteController.text,
                );
                await ctx.read<ProductProvider>().addStockMovement(movement);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(ctx);
                }
              }
            },
            child: Text(type == MovementType.stockIn ? 'Giriş Yap' : 'Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

class _MovementItem extends StatelessWidget {
  final StockMovement movement;
  final bool isDark;
  
  const _MovementItem({required this.movement, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isIn = movement.type == MovementType.stockIn;
    final mutedColor = isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isIn
            ? AppTheme.secondaryColor.withValues(alpha: 0.05)
            : AppTheme.dangerColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isIn ? AppTheme.secondaryColor : AppTheme.dangerColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isIn ? 'Stok Girişi' : 'Stok Çıkışı',
                    style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                Text(DateFormat('dd/MM/yyyy HH:mm').format(movement.createdAt),
                    style: TextStyle(fontSize: 12, color: mutedColor)),
              ],
            ),
          ),
          Text('${isIn ? '+' : '-'}${movement.quantity}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isIn ? AppTheme.secondaryColor : AppTheme.dangerColor)),
        ],
      ),
    );
  }
}
