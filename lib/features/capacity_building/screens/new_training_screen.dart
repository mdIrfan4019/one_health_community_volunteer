// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:cohv/core/services/media_picker_service.dart';
// import 'package:cohv/core/storage/session_manager.dart';
// import 'package:cohv/core/widgets/authenticated_header.dart';
// import 'package:cohv/core/widgets/searchable_dropdown.dart';
//
// import '../../../../core/theme/app_colors.dart';
//
// import '../domain/capacity_building_models.dart';
// import '../data/capacity_building_api_service.dart';
//
// const Color newTrainingGreen = Color(0xFF136B4F);
// const Color newTrainingBackground = Color(0xFFF9FAFB);
// const Color newTrainingBorder = Color(0xFFE2E8F0);
// const Color newTrainingMuted = Color(0xFF64748B);
// const Color newTrainingText = Color(0xFF1E293B);
// const Color newTrainingred = Color(0xFFF5092B);
// const Color newTrainingPhotoBackground = Color(0xFFEFF6FF); // Soft blue
// const Color newTrainingDocumentBackground = Color(0xFFFFF7ED); // Warm cream
//
// class NewTrainingScreen extends StatefulWidget {
//   final String? volunteerId;
//   final TrainingImpartedRecordModel? editRecord;
//
//   const NewTrainingScreen({super.key, this.volunteerId, this.editRecord});
//
//   bool get isEditMode => editRecord != null;
//
//   @override
//   State<NewTrainingScreen> createState() => _NewTrainingScreenState();
// }
//
// class _NewTrainingScreenState extends State<NewTrainingScreen> {
//   final _formKey = GlobalKey<FormState>();
//
//   final TextEditingController _organisedByController = TextEditingController();
//   final TextEditingController _durationController = TextEditingController();
//   final TextEditingController _remarksController = TextEditingController();
//   final TextEditingController _captionController = TextEditingController();
//
//   final CapacityBuildingApiService _apiService = CapacityBuildingApiService();
//   List<TrainingMasterModel> _trainingMasters = [];
//   TrainingMasterModel? _selectedMaster;
//   bool _isLoadingMasters = true;
//
//   DateTime _selectedDate = DateTime.now();
//
//   final List<PlatformFile> _photographs = [];
//   final List<PlatformFile> _documents = [];
//
//   bool _isSaving = false;
//
//   int get _wordCount {
//     final text = _remarksController.text.trim();
//     if (text.isEmpty) return 0;
//     return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.editRecord != null) {
//       final r = widget.editRecord!;
//       _selectedDate = DateTime.tryParse(r.trainingDate) ?? DateTime.now();
//       _organisedByController.text = r.organisedBy ?? '';
//       _durationController.text = r.duration ?? '';
//       _remarksController.text = r.remarks ?? '';
//       _captionController.text = r.caption ?? '';
//     }
//     _loadTrainingMasters();
//   }
//
//   Future<void> _loadTrainingMasters() async {
//     try {
//       final masters = await _apiService.fetchTrainingMasters();
//       if (!mounted) return;
//       setState(() {
//         _trainingMasters = masters;
//         _isLoadingMasters = false;
//         if (widget.editRecord != null) {
//           final matches = _trainingMasters.where(
//             (m) => m.trainingId == widget.editRecord!.trainingId,
//           );
//           if (matches.isNotEmpty) {
//             _selectedMaster = matches.first;
//           }
//         }
//       });
//     } catch (_) {
//       if (!mounted) return;
//       setState(() {
//         _trainingMasters = TrainingMasterModel.fallbackTypes();
//         _isLoadingMasters = false;
//         if (widget.editRecord != null) {
//           final matches = _trainingMasters.where(
//             (m) => m.trainingId == widget.editRecord!.trainingId,
//           );
//           if (matches.isNotEmpty) {
//             _selectedMaster = matches.first;
//           }
//         }
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     _organisedByController.dispose();
//     _durationController.dispose();
//     _remarksController.dispose();
//     _captionController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _selectDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: newTrainingGreen,
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: newTrainingText,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (picked != null && mounted) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }
//
//   String _formatDate(DateTime date) {
//     final day = date.day.toString().padLeft(2, '0');
//     final month = date.month.toString().padLeft(2, '0');
//     return '$day/$month/${date.year}';
//   }
//
//   int _getFileSize(PlatformFile file) {
//     final syncLength = file.lengthSync();
//     if (syncLength != null && syncLength > 0) {
//       return syncLength;
//     }
//     final path = file.path;
//     if (path != null && path.isNotEmpty) {
//       try {
//         final f = File(path);
//         if (f.existsSync()) {
//           return f.lengthSync();
//         }
//       } catch (_) {}
//     }
//     return 0;
//   }
//
//   Future<void> _pickPhotographs() async {
//     try {
//       final selectedFiles = await MediaPickerService().pickImageFiles(
//         context,
//         allowMultiple: true,
//       );
//
//       if (selectedFiles.isEmpty || !mounted) return;
//
//       if (_photographs.length + selectedFiles.length > 5) {
//         _showMessage('You can select up to 5 photographs.');
//         return;
//       }
//
//       bool hasOversized = false;
//       for (final file in selectedFiles) {
//         final size = (await file.length()) ?? _getFileSize(file);
//         if (size > 5 * 1024 * 1024) {
//           hasOversized = true;
//           break;
//         }
//       }
//
//       if (hasOversized) {
//         _showMessage('Each photograph must be 5 MB or smaller.');
//         return;
//       }
//
//       setState(() {
//         _photographs.addAll(selectedFiles);
//       });
//     } catch (e) {
//       _showMessage('Unable to select photographs.');
//     }
//   }
//
//   Future<void> _pickDocuments() async {
//     try {
//       final selectedFiles = await MediaPickerService().pickDocuments(
//         context,
//         allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
//         allowMultiple: true,
//       );
//
//       if (selectedFiles.isEmpty || !mounted) return;
//
//       if (_documents.length + selectedFiles.length > 4) {
//         _showMessage('You can select up to 4 documents.');
//         return;
//       }
//
//       bool hasOversized = false;
//       for (final file in selectedFiles) {
//         final size = (await file.length()) ?? _getFileSize(file);
//         if (size > 10 * 1024 * 1024) {
//           hasOversized = true;
//           break;
//         }
//       }
//
//       if (hasOversized) {
//         _showMessage('Each document must be 10 MB or smaller.');
//         return;
//       }
//
//       setState(() {
//         _documents.addAll(selectedFiles);
//       });
//     } catch (e) {
//       _showMessage('Unable to select documents.');
//     }
//   }
//
//   void _removePhotograph(int index) {
//     setState(() {
//       _photographs.removeAt(index);
//     });
//   }
//
//   void _removeDocument(int index) {
//     setState(() {
//       _documents.removeAt(index);
//     });
//   }
//
//   void _showMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
//     );
//   }
//
//   Future<void> _saveTraining() async {
//     FocusScope.of(context).unfocus();
//
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//
//     if (_selectedMaster == null) {
//       _showMessage('Please select a training.');
//       return;
//     }
//
//     setState(() {
//       _isSaving = true;
//     });
//
//     try {
//       final session = await SessionManager.getUserSession();
//       final dateStr =
//           '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
//
//       final request = TrainingImpartedCreateRequest(
//         trainingId: _selectedMaster!.trainingId,
//         trainingDate: dateStr,
//         organisedBy: _organisedByController.text.trim(),
//         duration: _durationController.text.trim(),
//         remarks: _remarksController.text.trim(),
//         caption: _captionController.text.trim().isEmpty
//             ? null
//             : _captionController.text.trim(),
//         clientRef: 'TRI-${DateTime.now().millisecondsSinceEpoch}',
//         deviceId: session?.volunteerId,
//         photos: _photographs
//             .map((f) => f.path)
//             .whereType<String>()
//             .where((p) => p.isNotEmpty)
//             .toList(),
//         documents: _documents
//             .map((f) => f.path)
//             .whereType<String>()
//             .where((p) => p.isNotEmpty)
//             .toList(),
//       );
//
//       final response = widget.isEditMode
//           ? await _apiService.updateTrainingImparted(
//               widget.editRecord!.trainingImpartedId,
//               request,
//             )
//           : await _apiService.submitTrainingImparted(request);
//
//       if (!mounted) return;
//
//       setState(() {
//         _isSaving = false;
//       });
//
//       if (response.success) {
//         final code = response.record?.trainingImpartedCode ?? '';
//         final msg = widget.isEditMode
//             ? (code.isNotEmpty
//                   ? 'Training imparted $code updated successfully.'
//                   : 'Training imparted record updated successfully.')
//             : (code.isNotEmpty
//                   ? 'Training imparted $code created successfully.'
//                   : response.message);
//         _showMessage(msg);
//         Navigator.pop(context, true);
//       } else {
//         _showMessage(response.message);
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _isSaving = false;
//       });
//       _showMessage('Unable to submit training: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: newTrainingBackground,
//       appBar: AuthenticatedAppBar(
//         title: widget.isEditMode
//             ? 'Edit Training Imparted'
//             : 'New Training Imparted',
//         backgroundColor: newTrainingGreen,
//         volunteerId: widget.volunteerId ?? '',
//         onBackPressed: () => Navigator.pop(context),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(18),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(color: newTrainingBorder),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.03),
//                   blurRadius: 10,
//                   offset: const Offset(0, 3),
//                 ),
//               ],
//             ),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Training dropdown
//                   _fieldLabel('Training *'),
//                   SearchableDropdownFormField<TrainingMasterModel>(
//                     key: ValueKey(
//                       'training_imparted_${_selectedMaster?.trainingId ?? 'none'}_${_trainingMasters.length}',
//                     ),
//                     fieldId: 'training_imparted',
//                     primaryColor: newTrainingGreen,
//                     items: _trainingMasters,
//                     value: _selectedMaster,
//                     itemLabel: (item) => item.trainingName,
//                     hintText: 'Select',
//                     isLoading: _isLoadingMasters,
//                     onChanged: (val) {
//                       setState(() => _selectedMaster = val);
//                     },
//                     validator: (val) =>
//                         val == null ? 'Please select a training' : null,
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   // Date
//                   _fieldLabel('Date *'),
//                   InkWell(
//                     onTap: _selectDate,
//                     borderRadius: BorderRadius.circular(8),
//                     child: Container(
//                       height: 48,
//                       padding: const EdgeInsets.symmetric(horizontal: 14),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: newTrainingBorder),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             _formatDate(_selectedDate),
//                             style: const TextStyle(
//                               fontSize: 14,
//                               color: newTrainingText,
//                             ),
//                           ),
//                           const Icon(
//                             Icons.calendar_today_outlined,
//                             color: newTrainingText,
//                             size: 18,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   // Organised by
//                   _fieldLabel('Organised by'),
//                   TextFormField(
//                     controller: _organisedByController,
//                     textCapitalization: TextCapitalization.words,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: newTrainingText,
//                     ),
//                     decoration: _inputDecoration(
//                       hint: 'e.g. District Health Department',
//                     ),
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   // Duration
//                   _fieldLabel('Duration'),
//                   TextFormField(
//                     controller: _durationController,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: newTrainingText,
//                     ),
//                     decoration: _inputDecoration(hint: 'e.g. 2 days'),
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   // Remarks
//                   _fieldLabel('Remarks'),
//                   TextFormField(
//                     controller: _remarksController,
//                     maxLines: 4,
//                     maxLength: 250,
//                     maxLengthEnforcement: MaxLengthEnforcement.enforced,
//                     style: const TextStyle(
//                       fontSize: 13.5,
//                       color: newTrainingText,
//                     ),
//                     onChanged: (_) {
//                       setState(() {});
//                     },
//                     decoration: InputDecoration(
//                       hintText: 'Enter remarks or key highlights',
//                       hintStyle: const TextStyle(
//                         fontSize: 13,
//                         color: Color(0xFF94A3B8),
//                       ),
//                       filled: true,
//                       fillColor: Colors.white,
//                       contentPadding: const EdgeInsets.all(12),
//                       counterText: '',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(color: newTrainingBorder),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(color: newTrainingBorder),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(
//                           color: newTrainingGreen,
//                           width: 1.5,
//                         ),
//                       ),
//                       errorBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(color: Colors.red),
//                       ),
//                       focusedErrorBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(
//                           color: Colors.red,
//                           width: 1.5,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: Text(
//                       '$_wordCount / 250 words',
//                       style: const TextStyle(
//                         fontSize: 11.5,
//                         color: newTrainingMuted,
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // Photo / documentation heading
//                   _buildSectionHeader('PHOTO / DOCUMENTATION'),
//
//                   const SizedBox(height: 10),
//
//                   // Attachment buttons
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _attachmentButton(
//                           label: 'Photograph',
//                           icon: Icons.camera_alt_outlined,
//                           backgroundColor: newTrainingPhotoBackground,
//                           onTap: _pickPhotographs,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: _attachmentButton(
//                           label: 'Document',
//                           icon: Icons.description_outlined,
//                           backgroundColor: newTrainingDocumentBackground,
//                           onTap: _pickDocuments,
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 10),
//
//                   const Text(
//                     'Up to 5 photographs (5 MB each) and 4 documents — PDF, Word or Excel (10 MB each).',
//                     style: TextStyle(
//                       fontSize: 11.5,
//                       height: 1.35,
//                       color: newTrainingMuted,
//                     ),
//                   ),
//
//                   // Selected photographs
//                   if (_photographs.isNotEmpty) ...[
//                     const SizedBox(height: 14),
//                     _fieldLabel('Selected photographs'),
//                     ...List.generate(
//                       _photographs.length,
//                       (index) => _selectedFileTile(
//                         name: _photographs[index].name,
//                         onRemove: () => _removePhotograph(index),
//                       ),
//                     ),
//                   ],
//
//                   // Selected documents
//                   if (_documents.isNotEmpty) ...[
//                     const SizedBox(height: 14),
//                     _fieldLabel('Selected documents'),
//                     ...List.generate(
//                       _documents.length,
//                       (index) => _selectedFileTile(
//                         name: _documents[index].name,
//                         onRemove: () => _removeDocument(index),
//                       ),
//                     ),
//                   ],
//
//                   const SizedBox(height: 16),
//
//                   // Description / caption
//                   _fieldLabel('Description / caption'),
//                   TextFormField(
//                     controller: _captionController,
//                     maxLines: 2,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: newTrainingText,
//                     ),
//                     decoration: _inputDecoration(
//                       hint: 'Add caption for uploaded files',
//                     ),
//                   ),
//
//                   const SizedBox(height: 10),
//
//                   // Metadata note
//                   const Text(
//                     'Date, time and GPS metadata are attached automatically. Personal identifiers should not be captured unnecessarily.',
//                     style: TextStyle(
//                       fontSize: 11.5,
//                       height: 1.35,
//                       color: newTrainingMuted,
//                     ),
//                   ),
//
//                   const SizedBox(height: 24),
//
//                   if (widget.isEditMode)
//                     Row(
//                       children: [
//                         Expanded(
//                           child: SizedBox(
//                             height: 48,
//                             child: ElevatedButton(
//                               onPressed: _isSaving ? null : _saveTraining,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: newTrainingGreen,
//                                 foregroundColor: Colors.white,
//                                 disabledBackgroundColor: newTrainingGreen
//                                     .withValues(alpha: 0.6),
//                                 elevation: 0,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(24),
//                                 ),
//                               ),
//                               child: _isSaving
//                                   ? const SizedBox(
//                                       height: 22,
//                                       width: 22,
//                                       child: CircularProgressIndicator(
//                                         color: Colors.white,
//                                         strokeWidth: 2,
//                                       ),
//                                     )
//                                   : const Text(
//                                       'Save',
//                                       style: TextStyle(
//                                         fontSize: 15,
//                                         fontWeight: FontWeight.w700,
//                                       ),
//                                     ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: SizedBox(
//                             height: 48,
//                             child: OutlinedButton(
//                               onPressed: () => Navigator.pop(context),
//                               style: OutlinedButton.styleFrom(
//                                 foregroundColor: newTrainingGreen,
//                                 backgroundColor: Colors.white,
//                                 side: const BorderSide(
//                                   color: newTrainingBorder,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(24),
//                                 ),
//                               ),
//                               child: const Text(
//                                 'Cancel',
//                                 style: TextStyle(
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.w600,
//                                   color: newTrainingGreen,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     )
//                   else ...[
//                     // Save button
//                     SizedBox(
//                       width: double.infinity,
//                       height: 48,
//                       child: ElevatedButton(
//                         onPressed: _isSaving ? null : _saveTraining,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: newTrainingGreen,
//                           foregroundColor: Colors.white,
//                           disabledBackgroundColor: newTrainingGreen.withValues(
//                             alpha: 0.6,
//                           ),
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(24),
//                           ),
//                         ),
//                         child: _isSaving
//                             ? const SizedBox(
//                                 height: 22,
//                                 width: 22,
//                                 child: CircularProgressIndicator(
//                                   color: Colors.white,
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                             : const Text(
//                                 'Save',
//                                 style: TextStyle(
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     // Cancel button
//                     SizedBox(
//                       width: double.infinity,
//                       height: 46,
//                       child: OutlinedButton(
//                         onPressed: () => Navigator.pop(context),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: newTrainingGreen,
//                           backgroundColor: Colors.white,
//                           side: const BorderSide(color: newTrainingBorder),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(24),
//                           ),
//                         ),
//                         child: const Text(
//                           'Cancel',
//                           style: TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w600,
//                             color: newTrainingGreen,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//
//       bottomNavigationBar: _buildBottomNavigation(),
//     );
//   }
//
//   Widget _buildSectionHeader(String text) {
//     return Text(
//       text,
//       style: const TextStyle(
//         fontSize: 11.5,
//         fontWeight: FontWeight.w700,
//         color: newTrainingMuted,
//         letterSpacing: 0.5,
//       ),
//     );
//   }
//
//   Widget _fieldLabel(String label) {
//     if (label.contains('*')) {
//       final parts = label.split('*');
//       return Padding(
//         padding: const EdgeInsets.only(bottom: 6),
//         child: RichText(
//           text: TextSpan(
//             children: [
//               TextSpan(
//                 text: parts[0],
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: newTrainingText,
//                 ),
//               ),
//               const TextSpan(
//                 text: '*',
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w700,
//                   color: newTrainingred,
//                 ),
//               ),
//               if (parts.length > 1 && parts[1].isNotEmpty)
//                 TextSpan(
//                   text: parts[1],
//                   style: const TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     color: newTrainingText,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       );
//     }
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Text(
//         label,
//         style: const TextStyle(
//           fontSize: 13,
//           fontWeight: FontWeight.w600,
//           color: newTrainingText,
//         ),
//       ),
//     );
//   }
//
//   InputDecoration _inputDecoration({String? hint, Widget? suffixIcon}) {
//     return InputDecoration(
//       hintText: hint,
//       hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
//       suffixIcon: suffixIcon,
//       filled: true,
//       fillColor: Colors.white,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: newTrainingBorder),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: newTrainingBorder),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: newTrainingGreen, width: 1.5),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: Colors.red),
//       ),
//       focusedErrorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: Colors.red, width: 1.5),
//       ),
//     );
//   }
//
//   Widget _attachmentButton({
//     required String label,
//     required IconData icon,
//     required Color backgroundColor,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(10),
//       child: Container(
//         height: 52,
//         decoration: BoxDecoration(
//           color: backgroundColor,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: newTrainingBorder),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: newTrainingGreen, size: 20),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//                 color: newTrainingText,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _selectedFileTile({
//     required String name,
//     required VoidCallback onRemove,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF1F5F9),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: newTrainingBorder),
//       ),
//       child: Row(
//         children: [
//           const Icon(
//             Icons.insert_drive_file_outlined,
//             color: newTrainingGreen,
//             size: 20,
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               name,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(fontSize: 12.5, color: newTrainingText),
//             ),
//           ),
//           IconButton(
//             onPressed: onRemove,
//             icon: const Icon(Icons.close, size: 18, color: newTrainingMuted),
//             padding: EdgeInsets.zero,
//             constraints: const BoxConstraints(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBottomNavigation() {
//     return Container(
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         border: Border(top: BorderSide(color: newTrainingBorder, width: 1)),
//       ),
//       child: BottomNavigationBar(
//         currentIndex: 1, // Highlight 'Actions'
//         onTap: (index) => Navigator.pop(context, index),
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: Colors.white,
//         selectedItemColor: newTrainingGreen,
//         unselectedItemColor: const Color(0xFF94A3B8),
//         selectedLabelStyle: const TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.w600,
//         ),
//         unselectedLabelStyle: const TextStyle(fontSize: 11),
//         elevation: 0,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home_rounded),
//             label: 'Dashboard',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.grid_view_rounded),
//             label: 'Actions',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.article_outlined),
//             label: 'Reports',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person_outline_rounded),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cohv/core/services/media_picker_service.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/core/widgets/searchable_dropdown.dart';
import 'package:cohv/core/models/geo_location_data.dart';
import 'package:cohv/core/services/location_service.dart';
import 'package:cohv/core/services/media_geotag_service.dart';
import '../../../../core/theme/app_colors.dart';

import '../domain/capacity_building_models.dart';
import '../data/capacity_building_api_service.dart';

const Color newTrainingGreen = Color(0xFF136B4F);
const Color newTrainingBackground = Color(0xFFF9FAFB);
const Color newTrainingBorder = Color(0xFFE2E8F0);
const Color newTrainingMuted = Color(0xFF64748B);
const Color newTrainingText = Color(0xFF1E293B);
const Color newTrainingred = Color(0xFFF5092B);
const Color newTrainingPhotoBackground = Color(0xFFEFF6FF); // Soft blue
const Color newTrainingDocumentBackground = Color(0xFFFFF7ED); // Warm cream

class NewTrainingScreen extends StatefulWidget {
  final String? volunteerId;
  final TrainingImpartedRecordModel? editRecord;

  const NewTrainingScreen({super.key, this.volunteerId, this.editRecord});

  bool get isEditMode => editRecord != null;

  @override
  State<NewTrainingScreen> createState() => _NewTrainingScreenState();
}

class _NewTrainingScreenState extends State<NewTrainingScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _organisedByController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();

  final CapacityBuildingApiService _apiService = CapacityBuildingApiService();
  List<TrainingMasterModel> _trainingMasters = [];
  TrainingMasterModel? _selectedMaster;
  bool _isLoadingMasters = true;

  DateTime _selectedDate = DateTime.now();

  // final List<PlatformFile> _photographs = [];
  final List<XFile> _photographs = [];
  final List<PlatformFile> _documents = [];

  bool _isSaving = false;
  // Real GPS Location state
  double? _lat;
  double? _lng;
  int? _accuracy;
  DateTime _gpsTimestamp = DateTime.now();
  GeoLocationData? _locationData;
  bool _isFetchingLocation = false;

  int get _wordCount {
    final text = _remarksController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  @override
  void initState() {
    super.initState();
    if (widget.editRecord != null) {
      final r = widget.editRecord!;
      _selectedDate = DateTime.tryParse(r.trainingDate) ?? DateTime.now();
      _organisedByController.text = r.organisedBy ?? '';
      _durationController.text = r.duration ?? '';
      _remarksController.text = r.remarks ?? '';
      _captionController.text = r.caption ?? '';
    }
    _loadTrainingMasters();
    _fetchDeviceLocation();
  }

  Future<void> _loadTrainingMasters() async {
    try {
      final masters = await _apiService.fetchTrainingMasters();
      if (!mounted) return;
      setState(() {
        _trainingMasters = masters;
        _isLoadingMasters = false;
        if (widget.editRecord != null) {
          final matches = _trainingMasters.where(
            (m) => m.trainingId == widget.editRecord!.trainingId,
          );
          if (matches.isNotEmpty) {
            _selectedMaster = matches.first;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _trainingMasters = TrainingMasterModel.fallbackTypes();
        _isLoadingMasters = false;
        if (widget.editRecord != null) {
          final matches = _trainingMasters.where(
            (m) => m.trainingId == widget.editRecord!.trainingId,
          );
          if (matches.isNotEmpty) {
            _selectedMaster = matches.first;
          }
        }
      });
    }
  }

  /// Acquires current hardware GPS fix
  Future<void> _fetchDeviceLocation({bool showDialogOnError = false}) async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);
    final loc = await LocationService().getCurrentLocation(forceFresh: true);
    if (!mounted) return;
    setState(() {
      _locationData = loc;
      _isFetchingLocation = false;
      if (loc.isAvailable) {
        _lat = loc.latitude;
        _lng = loc.longitude;
        _accuracy = loc.accuracyM;
        _gpsTimestamp = loc.timestamp ?? DateTime.now();
      }
    });
    if (!loc.isAvailable && showDialogOnError && mounted) {
      await LocationService().showLocationResolutionDialog(
        context,
        status: loc.status,
        onRetry: () => _fetchDeviceLocation(showDialogOnError: true),
      );
    }
  }

  Future<ImageSource?> _showMediaSourcePicker({
    required String title,
    required String cameraLabel,
    required String galleryLabel,
    required IconData cameraIcon,
    required IconData galleryIcon,
  }) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with title and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Side-by-side camera and gallery cards
                Row(
                  children: [
                    // Camera / Record Video Card
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx, ImageSource.camera),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF136B4F)
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  cameraIcon,
                                  color: const Color(0xFF19765E),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                cameraLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Gallery Card
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF136B4F)
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  galleryIcon,
                                  color: const Color(0xFF19765E),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                galleryLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _organisedByController.dispose();
    _durationController.dispose();
    _remarksController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: newTrainingGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: newTrainingText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  int _getFileSize(PlatformFile file) {
    final syncLength = file.lengthSync();
    if (syncLength != null && syncLength > 0) {
      return syncLength;
    }
    final path = file.path;
    if (path != null && path.isNotEmpty) {
      try {
        final f = File(path);
        if (f.existsSync()) {
          return f.lengthSync();
        }
      } catch (_) {}
    }
    return 0;
  }

  // Future<void> _pickPhotographs() async {
  //   final remaining = 5 - _photographs.length;
  //
  //   if (remaining <= 0) {
  //     _showMessage('You can select up to 5 photographs.');
  //     return;
  //   }
  //
  //   final source = await _showMediaSourcePicker(
  //     title: 'Select Photo Source',
  //     cameraLabel: 'Camera',
  //     galleryLabel: 'Gallery',
  //     cameraIcon: Icons.camera_alt_outlined,
  //     galleryIcon: Icons.photo_library_outlined,
  //   );
  //
  //   if (source == null) return;
  //
  //   try {
  //     final selectedFiles = <PlatformFile>[];
  //
  //     if (source == ImageSource.camera) {
  //       final photo = await MediaPickerService().capturePhoto(context);
  //       if (photo != null && mounted) {
  //         final file = File(photo.path);
  //         final len = await file.length();
  //         selectedFiles.add(
  //           PlatformFile(
  //             name: file.uri.pathSegments.last,
  //             path: photo.path,
  //             size: len,
  //           ),
  //         );
  //       }
  //     } else {
  //       final galleryPhotos = await MediaPickerService().pickImagesFromGallery(
  //         context,
  //         allowMultiple: true,
  //       );
  //       for (final photo in galleryPhotos) {
  //         final file = File(photo.path);
  //         final len = await file.length();
  //         selectedFiles.add(
  //           PlatformFile(
  //             name: file.uri.pathSegments.last,
  //             path: photo.path,
  //             size: len,
  //           ),
  //         );
  //       }
  //     }
  //
  //     if (selectedFiles.isEmpty || !mounted) return;
  //
  //     final validFiles = <PlatformFile>[];
  //     for (final file in selectedFiles) {
  //       final size = (await file.length()) ?? _getFileSize(file);
  //       if (size <= 5 * 1024 * 1024) {
  //         validFiles.add(file);
  //         if (validFiles.length >= remaining) break;
  //       }
  //     }
  //
  //     if (!mounted) return;
  //
  //     setState(() {
  //       _photographs.addAll(validFiles);
  //     });
  //
  //     if (validFiles.length < selectedFiles.length) {
  //       _showMessage(
  //         'Some files were skipped. Maximum 5 photographs, 5 MB each.',
  //       );
  //     }
  //   } catch (e) {
  //     _showMessage('Unable to select photographs.');
  //   }
  // }

  // Future<void> _pickPhotographs() async {
  //   final remaining = 5 - _photographs.length;

  //   if (remaining <= 0) {
  //     _showMessage('You can select up to 5 photographs.');
  //     return;
  //   }

  //   final source = await _showMediaSourcePicker(
  //     title: 'Select Photo Source',
  //     cameraLabel: 'Camera',
  //     galleryLabel: 'Gallery',
  //     cameraIcon: Icons.camera_alt_outlined,
  //     galleryIcon: Icons.photo_library_outlined,
  //   );

  //   if (source == null || !mounted) return;

  //   try {
  //     final List<XFile> selectedFiles = [];

  //     if (source == ImageSource.camera) {
  //       final photo = await MediaPickerService().capturePhoto(context);

  //       if (photo != null && mounted) {
  //         selectedFiles.add(photo);
  //       }
  //     } else {
  //       final galleryPhotos = await MediaPickerService().pickImagesFromGallery(
  //         context,
  //         allowMultiple: true,
  //       );

  //       selectedFiles.addAll(galleryPhotos);
  //     }

  //     if (selectedFiles.isEmpty || !mounted) return;

  //     final validFiles = <XFile>[];
  //     bool hasOversizedFile = false;
  //     bool hasExcessFiles = false;

  //     for (final photo in selectedFiles) {
  //       final size = await photo.length();

  //       if (size > 5 * 1024 * 1024) {
  //         hasOversizedFile = true;
  //         continue;
  //       }

  //       if (validFiles.length >= remaining) {
  //         hasExcessFiles = true;
  //         break;
  //       }

  //       validFiles.add(photo);
  //     }

  //     if (!mounted) return;

  //     setState(() {
  //       _photographs.addAll(validFiles);
  //     });

  //     if (hasOversizedFile || hasExcessFiles) {
  //       _showMessage(
  //         hasOversizedFile && hasExcessFiles
  //             ? 'Some photographs were skipped. Maximum 5 photographs, 5 MB each.'
  //             : hasOversizedFile
  //             ? 'Some photographs exceeded the 5 MB size limit.'
  //             : 'You can attach up to 5 photographs.',
  //       );
  //     }
  //   } catch (e) {
  //     if (!mounted) return;

  //     _showMessage('Unable to select photographs: $e');
  //   }
  // }

    Future<void> _pickPhotographs() async {
    final remaining = 5 - _photographs.length;

    if (remaining <= 0) {
      _showMessage('You can select up to 5 photographs.');
      return;
    }

    final source = await _showMediaSourcePicker(
      title: 'Select Photo Source',
      cameraLabel: 'Camera',
      galleryLabel: 'Gallery',
      cameraIcon: Icons.camera_alt_outlined,
      galleryIcon: Icons.photo_library_outlined,
    );

    if (source == null || !mounted) return;

    try {
      final List<XFile> selectedFiles = [];

      if (source == ImageSource.camera) {
        final photo = await MediaPickerService().capturePhoto(context);
        if (photo != null && mounted) {
          selectedFiles.add(photo);
        }
      } else {
        final galleryPhotos = await MediaPickerService().pickImagesFromGallery(
          context,
          allowMultiple: true,
        );
        selectedFiles.addAll(galleryPhotos);
      }

      if (selectedFiles.isEmpty || !mounted) return;

      final validFiles = <XFile>[];
      final isCamera = (source == ImageSource.camera);

      for (final photo in selectedFiles) {
        final size = await photo.length();

        if (size > 5 * 1024 * 1024) {
          continue;
        }

        if (validFiles.length >= remaining) {
          break;
        }

        // 🔥 Burn coordinates, timestamp and COHV tag directly onto image pixels
        final stampedPath = await MediaGeoTagService().processPhoto(
          filePath: photo.path,
          isFromCamera: isCamera,
          fallbackLocation: _locationData,
        );

        validFiles.add(XFile(stampedPath));
      }

      if (!mounted) return;

      setState(() {
        _photographs.addAll(validFiles);
      });
    } catch (e) {
      debugPrint('[TRAINING_IMPARTED] Error picking photo: $e');
      _showMessage('Unable to select photographs.');
    }
  }

  Future<void> _pickDocuments() async {
    try {
      final selectedFiles = await MediaPickerService().pickDocuments(
        context,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
        allowMultiple: true,
      );

      if (selectedFiles.isEmpty || !mounted) return;

      if (_documents.length + selectedFiles.length > 4) {
        _showMessage('You can select up to 4 documents.');
        return;
      }

      bool hasOversized = false;
      for (final file in selectedFiles) {
        final size = (await file.length()) ?? _getFileSize(file);
        if (size > 10 * 1024 * 1024) {
          hasOversized = true;
          break;
        }
      }

      if (hasOversized) {
        _showMessage('Each document must be 10 MB or smaller.');
        return;
      }

      setState(() {
        _documents.addAll(selectedFiles);
      });
    } catch (e) {
      _showMessage('Unable to select documents.');
    }
  }

  void _removePhotograph(int index) {
    setState(() {
      _photographs.removeAt(index);
    });
  }

  void _removeDocument(int index) {
    setState(() {
      _documents.removeAt(index);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _saveTraining() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMaster == null) {
      _showMessage('Please select a training.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final session = await SessionManager.getUserSession();
      final dateStr =
          '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      // final request = TrainingImpartedCreateRequest(
      //   trainingId: _selectedMaster!.trainingId,
      //   trainingDate: dateStr,
      //   organisedBy: _organisedByController.text.trim(),
      //   duration: _durationController.text.trim(),
      //   remarks: _remarksController.text.trim(),
      //   caption: _captionController.text.trim().isEmpty
      //       ? null
      //       : _captionController.text.trim(),
      //   clientRef: 'TRI-${DateTime.now().millisecondsSinceEpoch}',
      //   deviceId: session?.volunteerId,
      //   photos: _photographs
      //       .map((f) => f.path)
      //       .whereType<String>()
      //       .where((p) => p.isNotEmpty)
      //       .toList(),
      //   documents: _documents
      //       .map((f) => f.path)
      //       .whereType<String>()
      //       .where((p) => p.isNotEmpty)
      //       .toList(),
      // );

            final request = TrainingImpartedCreateRequest(
        trainingId: _selectedMaster!.trainingId,
        trainingDate: dateStr,
        organisedBy: _organisedByController.text.trim(),
        duration: _durationController.text.trim(),
        remarks: _remarksController.text.trim(),
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        clientRef: 'TRI-${DateTime.now().millisecondsSinceEpoch}',
        deviceId: session?.volunteerId,
        // 👇 ADD GPS TELEMETRY HERE:
        latitude: GeoLocationData.formatCoordinate(_lat),
        longitude: GeoLocationData.formatCoordinate(_lng),
        gpsAccuracyM: _accuracy,
        capturedAt: _gpsTimestamp.toUtc().toIso8601String(),
        photos: _photographs
            .map((f) => f.path)
            .whereType<String>()
            .where((p) => p.isNotEmpty)
            .toList(),
        documents: _documents
            .map((f) => f.path)
            .whereType<String>()
            .where((p) => p.isNotEmpty)
            .toList(),
      );

      final response = widget.isEditMode
          ? await _apiService.updateTrainingImparted(
              widget.editRecord!.trainingImpartedId,
              request,
            )
          : await _apiService.submitTrainingImparted(request);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      if (response.success) {
        final code = response.record?.trainingImpartedCode ?? '';
        final msg = widget.isEditMode
            ? (code.isNotEmpty
                  ? 'Training imparted $code updated successfully.'
                  : 'Training imparted record updated successfully.')
            : (code.isNotEmpty
                  ? 'Training imparted $code created successfully.'
                  : response.message);
        _showMessage(msg);
        Navigator.pop(context, true);
      } else {
        _showMessage(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      _showMessage('Unable to submit training: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: newTrainingBackground,
      appBar: AuthenticatedAppBar(
        title: widget.isEditMode
            ? 'Edit Training Imparted'
            : 'New Training Imparted',
        backgroundColor: newTrainingGreen,
        volunteerId: widget.volunteerId ?? '',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: newTrainingBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Training dropdown
                  _fieldLabel('Training *'),
                  SearchableDropdownFormField<TrainingMasterModel>(
                    key: ValueKey(
                      'training_imparted_${_selectedMaster?.trainingId ?? 'none'}_${_trainingMasters.length}',
                    ),
                    fieldId: 'training_imparted',
                    primaryColor: newTrainingGreen,
                    items: _trainingMasters,
                    value: _selectedMaster,
                    itemLabel: (item) => item.trainingName,
                    hintText: 'Select',
                    isLoading: _isLoadingMasters,
                    onChanged: (val) {
                      setState(() => _selectedMaster = val);
                    },
                    validator: (val) =>
                        val == null ? 'Please select a training' : null,
                  ),

                  const SizedBox(height: 16),

                  // Date
                  _fieldLabel('Date *'),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: newTrainingBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(_selectedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              color: newTrainingText,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: newTrainingText,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Organised by
                  _fieldLabel('Organised by'),
                  TextFormField(
                    controller: _organisedByController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontSize: 14,
                      color: newTrainingText,
                    ),
                    decoration: _inputDecoration(
                      hint: 'e.g. District Health Department',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Duration
                  _fieldLabel('Duration'),
                  TextFormField(
                    controller: _durationController,
                    style: const TextStyle(
                      fontSize: 14,
                      color: newTrainingText,
                    ),
                    decoration: _inputDecoration(hint: 'e.g. 2 days'),
                  ),

                  const SizedBox(height: 16),

                  // Remarks
                  _fieldLabel('Remarks'),
                  TextFormField(
                    controller: _remarksController,
                    maxLines: 4,
                    maxLength: 250,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: newTrainingText,
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter remarks or key highlights',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: newTrainingBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: newTrainingBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: newTrainingGreen,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$_wordCount / 250 words',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: newTrainingMuted,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Photo / documentation heading
                  _buildSectionHeader('PHOTO / DOCUMENTATION'),

                  const SizedBox(height: 10),

                  // Attachment buttons
                  Row(
                    children: [
                      Expanded(
                        child: _attachmentButton(
                          label: 'Photograph',
                          icon: Icons.camera_alt_outlined,
                          backgroundColor: newTrainingPhotoBackground,
                          onTap: _pickPhotographs,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _attachmentButton(
                          label: 'Document',
                          icon: Icons.description_outlined,
                          backgroundColor: newTrainingDocumentBackground,
                          onTap: _pickDocuments,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Up to 5 photographs (5 MB each) and 4 documents — PDF, Word or Excel (10 MB each).',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: newTrainingMuted,
                    ),
                  ),

                  // Selected photographs
                  if (_photographs.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _fieldLabel('Selected photographs'),
                    ...List.generate(
                      _photographs.length,
                      (index) => _selectedFileTile(
                        name: _photographs[index].name,
                        onRemove: () => _removePhotograph(index),
                      ),
                    ),
                  ],

                  // Selected documents
                  if (_documents.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _fieldLabel('Selected documents'),
                    ...List.generate(
                      _documents.length,
                      (index) => _selectedFileTile(
                        name: _documents[index].name,
                        onRemove: () => _removeDocument(index),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Description / caption
                  _fieldLabel('Description / caption'),
                  TextFormField(
                    controller: _captionController,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 14,
                      color: newTrainingText,
                    ),
                    decoration: _inputDecoration(
                      hint: 'Add caption for uploaded files',
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Metadata note
                  const Text(
                    'Date, time and GPS metadata are attached automatically. Personal identifiers should not be captured unnecessarily.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: newTrainingMuted,
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (widget.isEditMode)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveTraining,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: newTrainingGreen,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: newTrainingGreen
                                    .withValues(alpha: 0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Save',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: newTrainingGreen,
                                backgroundColor: Colors.white,
                                side: const BorderSide(
                                  color: newTrainingBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: newTrainingGreen,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveTraining,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: newTrainingGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: newTrainingGreen.withValues(
                            alpha: 0.6,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: newTrainingGreen,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: newTrainingBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: newTrainingGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: newTrainingMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _fieldLabel(String label) {
    if (label.contains('*')) {
      final parts = label.split('*');
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: parts[0],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: newTrainingText,
                ),
              ),
              const TextSpan(
                text: '*',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: newTrainingred,
                ),
              ),
              if (parts.length > 1 && parts[1].isNotEmpty)
                TextSpan(
                  text: parts[1],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: newTrainingText,
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: newTrainingText,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: newTrainingBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: newTrainingBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: newTrainingGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _attachmentButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: newTrainingBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: newTrainingGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: newTrainingText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedFileTile({
    required String name,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: newTrainingBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            color: newTrainingGreen,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: newTrainingText),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18, color: newTrainingMuted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: newTrainingBorder, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: 1, // Highlight 'Actions'
        onTap: (index) => Navigator.pop(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: newTrainingGreen,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Actions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
