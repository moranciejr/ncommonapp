import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_picker_service.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(File? file) onImagePicked;
  final String? initialImageUrl;
  final double size;
  final bool allowMultiple;

  const ImagePickerWidget({
    super.key,
    required this.onImagePicked,
    this.initialImageUrl,
    this.size = 100,
    this.allowMultiple = false,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _selectedImage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(widget.size / 2),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: Image.file(
          _selectedImage!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      );
    }

    if (widget.initialImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: Image.network(
          widget.initialImageUrl!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.add_a_photo,
        size: widget.size * 0.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final imagePicker = ImagePickerService();
      final file = await imagePicker.pickImage();
      
      if (file != null) {
        setState(() => _selectedImage = file);
        widget.onImagePicked(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 