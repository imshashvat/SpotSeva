import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../bloc/report/report_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../../../core/constants/app_constants.dart';

class ReportScreen extends StatefulWidget {
  final String spotId;
  const ReportScreen({super.key, required this.spotId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _picker = ImagePicker();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = AppConstants.issueCategories.first;
  final List<File> _photos = [];
  final List<String> _uploadedUrls = [];
  Position? _position;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLocating = true);
    try {
      _position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {}
    setState(() => _isLocating = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_photos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 photos per report')),
      );
      return;
    }
    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (xFile == null) return;

    final file = File(xFile.path);

    // Compress image
    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.path,
      '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      quality: 75,
      minWidth: 800,
      minHeight: 800,
    );

    setState(() => _photos.add(File(compressed?.path ?? xFile.path)));

    // Upload immediately
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ReportBloc>().add(
            UploadPhoto(
              File(compressed?.path ?? xFile.path),
              authState.user.uid,
            ),
          );
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadedUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one photo'),
          backgroundColor: Color(AppConstants.colorRed),
        ),
      );
      return;
    }

    context.read<ReportBloc>().add(SubmitReport(
          spotId: widget.spotId,
          photoUrls: _uploadedUrls,
          issueType: _selectedCategory,
          description: _descController.text.trim(),
          lat: _position?.latitude ?? AppConstants.defaultLat,
          lng: _position?.longitude ?? AppConstants.defaultLng,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportBloc, ReportState>(
      listener: (ctx, state) {
        if (state is PhotoUploaded) {
          setState(() => _uploadedUrls.add(state.url));
        }
        if (state is ReportSuccess) {
          showDialog(
            context: ctx,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('🎉 Report Submitted!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+ ${state.pointsEarned} points earned',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold,
                        color: Color(AppConstants.colorTeal)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI classified as: ${state.aiLabel}\nSeverity: ${state.severity.toUpperCase()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/home');
                  },
                  child: const Text('Back to Map'),
                ),
              ],
            ),
          );
        }
        if (state is ReportError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(AppConstants.colorRed)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Report Issue'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          actions: [
            BlocBuilder<ReportBloc, ReportState>(
              builder: (_, state) {
                final isLoading = state is ReportSubmitting ||
                    state is ReportUploading;
                return TextButton(
                  onPressed: isLoading ? null : _submit,
                  child: const Text('Submit',
                      style: TextStyle(
                          color: Color(AppConstants.colorTeal),
                          fontWeight: FontWeight.bold)),
                );
              },
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Category chips ──────────────────────────────
              const Text('Issue Type',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: AppConstants.issueCategories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return FilterChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat),
                    selectedColor: const Color(AppConstants.colorTeal)
                        .withValues(alpha: 0.15),
                    checkmarkColor: const Color(AppConstants.colorTeal),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Photo picker ────────────────────────────────
              const Text('Photos (required)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._photos.asMap().entries.map((e) =>
                        _PhotoThumb(file: e.value, index: e.key,
                            onRemove: () =>
                                setState(() => _photos.removeAt(e.key)))),
                    if (_photos.length < 3)
                      _AddPhotoButton(onPick: _pickImage),
                  ],
                ),
              ),

              // Upload progress
              BlocBuilder<ReportBloc, ReportState>(
                builder: (_, state) {
                  if (state is ReportUploading) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(
                        value: state.progress,
                        backgroundColor: Colors.grey[200],
                        color: const Color(AppConstants.colorTeal),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 20),

              // ── Description ─────────────────────────────────
              const Text('Description',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText:
                      'Describe the issue briefly…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(AppConstants.colorTeal)),
                  ),
                ),
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Description required' : null,
              ),

              const SizedBox(height: 12),

              // ── GPS stamp ───────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isLocating
                          ? Icons.hourglass_empty
                          : Icons.gps_fixed,
                      size: 16,
                      color: _position != null
                          ? const Color(AppConstants.colorGreen)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isLocating
                          ? 'Getting GPS location…'
                          : _position != null
                              ? 'GPS: ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}'
                              : 'GPS unavailable — using spot location',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Reward info ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(AppConstants.colorTeal).withValues(alpha: 0.08),
                      const Color(AppConstants.colorBlue).withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Text('🎯', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('+25 Points on Submission',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        Text('+50 Bonus if resolved!',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final File file;
  final int index;
  final VoidCallback onRemove;
  const _PhotoThumb(
      {required this.file, required this.index, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(file, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final Future<void> Function(ImageSource) onPick;
  const _AddPhotoButton({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.grey[300]!, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[50],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: Colors.grey),
            SizedBox(height: 4),
            Text('Add photo',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                onPick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                onPick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
