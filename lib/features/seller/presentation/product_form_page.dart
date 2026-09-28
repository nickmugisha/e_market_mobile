import 'package:flutter/material.dart';
import '../../../core/services/native_image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/product_image.dart';
import '../../auth/domain/user_profile.dart';
import '../../catalogue/data/category_repository.dart';
import '../../catalogue/data/product_repository.dart';
import '../../catalogue/domain/market_category.dart';
import '../../catalogue/domain/product.dart';
import '../../catalogue/utils/product_image_codec.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({
    super.key,
    required this.profile,
    this.product,
  });

  final UserProfile profile;
  final Product? product;

  bool get isEditing => product != null;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _picker = NativeImagePicker();
  final _products = ProductRepository();
  final _categories = CategoryRepository();

  String? _categoryId;
  MarketCurrency _currency = MarketCurrency.bif;
  bool _active = true;
  bool _saving = false;
  bool _pickingImage = false;
  String _imageRef = '';

  @override
  void initState() {
    super.initState();

    final product = widget.product;
    if (product != null) {
      _name.text = product.name;
      _description.text = product.description;
      _price.text = _formatNumber(product.price);
      _stock.text = product.stock.toString();
      _categoryId = product.categoryId;
      _currency = product.currency;
      _active = product.active;
      _imageRef = product.imageRef;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  Future<void> _pickImage() async {
    if (_pickingImage) return;

    setState(() => _pickingImage = true);
    try {
      final bytes = await _picker.pickCompressedImage();
      if (bytes == null) return;

      if (!ProductImageCodec.fitsFirestoreBudget(bytes)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'That image is still too large after compression. Choose a smaller image.',
            ),
          ),
        );
        return;
      }

      setState(() => _imageRef = ProductImageCodec.encode(bytes));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read that image. Please try another one.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _save(List<MarketCategory> categories) async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final category = categories
        .where((item) => item.id == _categoryId)
        .firstOrNull;

    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a product category.')),
      );
      return;
    }

    final price = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    final stock = int.tryParse(_stock.text.trim());
    if (price == null || stock == null) return;

    setState(() => _saving = true);

    try {
      if (widget.product == null) {
        await _products.createProduct(
          sellerId: widget.profile.uid,
          name: _name.text,
          description: _description.text,
          categoryId: category.id,
          categoryName: category.name,
          price: price,
          currency: _currency,
          stock: stock,
          imageRef: _imageRef,
          active: _active,
        );
      } else {
        await _products.updateProduct(
          widget.product!.copyWith(
            name: _name.text.trim(),
            description: _description.text.trim(),
            categoryId: category.id,
            categoryName: category.name,
            price: price,
            currency: _currency,
            stock: stock,
            imageRef: _imageRef,
            active: _active,
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save the product. Check your connection and permissions.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit product' : 'New product'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: StreamBuilder<List<MarketCategory>>(
        stream: _categories.watchActiveCategories(),
        builder: (context, snapshot) {
          final categories = snapshot.data ?? const <MarketCategory>[];

          if (_categoryId == null && categories.isNotEmpty) {
            _categoryId = categories.first.id;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: ProductImage(
                    imageRef: _imageRef,
                    width: double.infinity,
                    height: 220,
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickingImage ? null : _pickImage,
                  icon: _pickingImage
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_library_outlined),
                  label: Text(
                    _imageRef.isEmpty ? 'Choose product image' : 'Change image',
                  ),
                ),
                if (_imageRef.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() => _imageRef = ''),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Remove image'),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Product name',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 2) return 'Enter a product name.';
                    if (text.length > 80) {
                      return 'Keep the name under 80 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 5) {
                      return 'Add a short product description.';
                    }
                    if (text.length > 500) {
                      return 'Keep the description under 500 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: categories.any((item) => item.id == _categoryId)
                      ? _categoryId
                      : null,
                  items: categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: categories.isEmpty
                      ? null
                      : (value) => setState(() => _categoryId = value),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category_outlined),
                    helperText: snapshot.hasError
                        ? 'Could not load categories.'
                        : categories.isEmpty
                            ? 'Categories are being prepared...'
                            : null,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (value) {
                          final parsed = double.tryParse(
                            (value ?? '').trim().replaceAll(',', '.'),
                          );
                          if (parsed == null || parsed < 0) {
                            return 'Enter a valid price.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<MarketCurrency>(
                        initialValue: _currency,
                        decoration: const InputDecoration(labelText: 'Currency'),
                        items: MarketCurrency.values
                            .map(
                              (currency) => DropdownMenuItem(
                                value: currency,
                                child: Text(currency.code),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _currency = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock quantity',
                    prefixIcon: Icon(Icons.numbers_rounded),
                  ),
                  validator: (value) {
                    final parsed = int.tryParse((value ?? '').trim());
                    if (parsed == null || parsed < 0) {
                      return 'Enter a valid stock quantity.';
                    }
                    if (parsed > 999999) return 'Stock value is too large.';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: const Text(
                    'Visible in the marketplace',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    _active
                        ? 'Clients can see this product.'
                        : 'Only you can see this product.',
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: StreamBuilder<List<MarketCategory>>(
          stream: _categories.watchActiveCategories(),
          builder: (context, snapshot) {
            final categories = snapshot.data ?? const <MarketCategory>[];
            return FilledButton.icon(
              onPressed: _saving || categories.isEmpty
                  ? null
                  : () => _save(categories),
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_saving ? 'Saving...' : 'Save product'),
            );
          },
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
