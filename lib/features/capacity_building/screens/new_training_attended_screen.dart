// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:cohv/core/services/media_picker_service.dart';
// import 'package:cohv/core/storage/session_manager.dart';
// import 'package:cohv/core/widgets/authenticated_header.dart';
// import 'package:cohv/core/widgets/searchable_dropdown.dart';
//
// import '../domain/capacity_building_models.dart';
// import '../data/capacity_building_api_service.dart';
//
// const Color trainingGreen = Color(0xFF136B4F);
// const Color trainingBackground = Color(0xFFF9FAFB);
// const Color trainingBorder = Color(0xFFE2E8F0);
// const Color trainingMuted = Color(0xFF64748B);
// const Color trainingred = Color(0xFFF5092B);
// const Color trainingPhotoBackground = Color(0xFFEFF6FF); // Soft blue
// const Color trainingDocumentBackground = Color(0xFFFFF7ED); // Warm cream
// const Color trainingText = Color(0xFF1E293B);
//
// class NewTrainingAttendedScreen extends StatefulWidget {
//   final String? volunteerId;
//   final TrainingAttendedRecordModel? editRecord;
//
//   const NewTrainingAttendedScreen({
//     super.key,
//     this.volunteerId,
//     this.editRecord,
//   });
//
//   bool get isEditMode => editRecord != null;
//
//   @override
//   State<NewTrainingAttendedScreen> createState() =>
//       _NewTrainingAttendedScreenState();
// }
//
// class _NewTrainingAttendedScreenState extends State<NewTrainingAttendedScreen> {
//   final _formKey = GlobalKey<FormState>();
//
//   final _venueController = TextEditingController();
//   final _chairedByController = TextEditingController();
//   final _keyPointsController = TextEditingController();
//   final _captionController = TextEditingController();
//
//   final CapacityBuildingApiService _apiService = CapacityBuildingApiService();
//   List<TrainingMasterModel> _trainingMasters = [];
//   TrainingMasterModel? _selectedMaster;
//   bool _isLoadingMasters = true;
//
//   DateTime _selectedDate = DateTime.now();
//   bool _certificateIssued = false;
//   bool _isSaving = false;
//
//   final List<PlatformFile> _photographs = [];
//   final List<PlatformFile> _documents = [];
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.editRecord != null) {
//       final r = widget.editRecord!;
//       _selectedDate = DateTime.tryParse(r.trainingDate) ?? DateTime.now();
//       _venueController.text = r.venue ?? '';
//       _chairedByController.text = r.chairedBy ?? '';
//       _keyPointsController.text = r.keyPoints ?? '';
//       _certificateIssued = r.certificateIssued;
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
//     _venueController.dispose();
//     _chairedByController.dispose();
//     _keyPointsController.dispose();
//     _captionController.dispose();
//     super.dispose();
//   }
//
//   String _formatDate(DateTime date) {
//     return '${date.day.toString().padLeft(2, '0')}/'
//         '${date.month.toString().padLeft(2, '0')}/'
//         '${date.year}';
//   }
//
//   Future<void> _selectDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2100),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: trainingGreen,
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: trainingText,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (picked != null) {
//       setState(() => _selectedDate = picked);
//     }
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
//     final remaining = 5 - _photographs.length;
//
//     if (remaining <= 0) {
//       _showMessage('You can attach up to 5 photographs.');
//       return;
//     }
//
//     try {
//       final result = await MediaPickerService().pickImageFiles(
//         context,
//         allowMultiple: true,
//       );
//
//       if (result.isEmpty || !mounted) return;
//
//       final validFiles = <PlatformFile>[];
//       for (final file in result) {
//         final size = (await file.length()) ?? _getFileSize(file);
//         if (size <= 5 * 1024 * 1024) {
//           validFiles.add(file);
//           if (validFiles.length >= remaining) break;
//         }
//       }
//
//       if (!mounted) return;
//
//       setState(() {
//         _photographs.addAll(validFiles);
//       });
//
//       if (validFiles.length < result.length) {
//         _showMessage(
//           'Some files were skipped. Maximum 5 photographs, 5 MB each.',
//         );
//       }
//     } catch (e) {
//       _showMessage('Unable to select photographs.');
//     }
//   }
//
//   Future<void> _pickDocuments() async {
//     final remaining = 4 - _documents.length;
//
//     if (remaining <= 0) {
//       _showMessage('You can attach up to 4 documents.');
//       return;
//     }
//
//     try {
//       final result = await MediaPickerService().pickDocuments(
//         context,
//         allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
//         allowMultiple: true,
//       );
//
//       if (result.isEmpty || !mounted) return;
//
//       final validFiles = <PlatformFile>[];
//       for (final file in result) {
//         final size = (await file.length()) ?? _getFileSize(file);
//         if (size <= 10 * 1024 * 1024) {
//           validFiles.add(file);
//           if (validFiles.length >= remaining) break;
//         }
//       }
//
//       if (!mounted) return;
//
//       setState(() {
//         _documents.addAll(validFiles);
//       });
//
//       if (validFiles.length < result.length) {
//         _showMessage(
//           'Some files were skipped. Maximum 4 documents, 10 MB each.',
//         );
//       }
//     } catch (e) {
//       _showMessage('Unable to select documents.');
//     }
//   }
//
//   void _showMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
//     );
//   }
//
//   void _removePhotograph(int index) {
//     setState(() => _photographs.removeAt(index));
//   }
//
//   void _removeDocument(int index) {
//     setState(() => _documents.removeAt(index));
//   }
//
//   Future<void> _saveTraining() async {
//     FocusScope.of(context).unfocus();
//
//     if (!_formKey.currentState!.validate()) return;
//
//     if (_selectedMaster == null) {
//       _showMessage('Please select a training.');
//       return;
//     }
//
//     setState(() => _isSaving = true);
//
//     try {
//       final session = await SessionManager.getUserSession();
//       final dateStr =
//           '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
//
//       final request = TrainingAttendedCreateRequest(
//         trainingId: _selectedMaster!.trainingId,
//         trainingDate: dateStr,
//         venue: _venueController.text.trim(),
//         chairedBy: _chairedByController.text.trim(),
//         keyPoints: _keyPointsController.text.trim(),
//         caption: _captionController.text.trim().isEmpty
//             ? null
//             : _captionController.text.trim(),
//         certificateIssued: _certificateIssued,
//         clientRef: 'TRN-${DateTime.now().millisecondsSinceEpoch}',
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
//           ? await _apiService.updateTrainingAttended(
//               widget.editRecord!.trainingAttendedId,
//               request,
//             )
//           : await _apiService.submitTrainingAttended(request);
//
//       if (!mounted) return;
//
//       setState(() => _isSaving = false);
//
//       if (response.success) {
//         final code = response.record?.trainingAttendedCode ?? '';
//         final msg = widget.isEditMode
//             ? (code.isNotEmpty
//                 ? 'Training attended $code updated successfully.'
//                 : 'Training attended record updated successfully.')
//             : (code.isNotEmpty
//                 ? 'Training attended $code recorded successfully.'
//                 : response.message);
//         _showMessage(msg);
//         Navigator.pop(context, true);
//       } else {
//         _showMessage(response.message);
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _isSaving = false);
//       _showMessage('Unable to submit training attended: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: trainingBackground,
//       appBar: AuthenticatedAppBar(
//         title: widget.isEditMode
//             ? 'Edit Training Attended'
//             : 'New Training Attended',
//         backgroundColor: trainingGreen,
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
//               border: Border.all(color: trainingBorder),
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
//                   _label('Training *'),
//                   SearchableDropdownFormField<TrainingMasterModel>(
//                     key: ValueKey(
//                       'training_attended_${_selectedMaster?.trainingId ?? 'none'}_${_trainingMasters.length}',
//                     ),
//                     fieldId: 'training_attended',
//                     primaryColor: trainingGreen,
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
//                   _label('Date *'),
//                   InkWell(
//                     onTap: _selectDate,
//                     borderRadius: BorderRadius.circular(8),
//                     child: Container(
//                       height: 48,
//                       padding: const EdgeInsets.symmetric(horizontal: 14),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: trainingBorder),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             _formatDate(_selectedDate),
//                             style: const TextStyle(
//                               fontSize: 14,
//                               color: trainingText,
//                             ),
//                           ),
//                           const Icon(
//                             Icons.calendar_today_outlined,
//                             color: trainingText,
//                             size: 18,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   _label('Venue'),
//                   TextFormField(
//                     controller: _venueController,
//                     style: const TextStyle(fontSize: 14, color: trainingText),
//                     decoration: _inputDecoration(hint: 'e.g. Community Hall'),
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   _label('Chaired by'),
//                   TextFormField(
//                     controller: _chairedByController,
//                     style: const TextStyle(fontSize: 14, color: trainingText),
//                     decoration: _inputDecoration(hint: 'e.g. Dr. John Doe'),
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   _label('Key points / action agreed'),
//                   TextFormField(
//                     controller: _keyPointsController,
//                     maxLines: 4,
//                     style: const TextStyle(fontSize: 13.5, color: trainingText),
//                     decoration: InputDecoration(
//                       hintText: 'Enter key points or decisions',
//                       hintStyle: const TextStyle(
//                         fontSize: 13,
//                         color: Color(0xFF94A3B8),
//                       ),
//                       filled: true,
//                       fillColor: Colors.white,
//                       contentPadding: const EdgeInsets.all(12),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(color: trainingBorder),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(color: trainingBorder),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(
//                           color: trainingGreen,
//                           width: 1.5,
//                         ),
//                       ),
//                       errorBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(color: Colors.red),
//                       ),
//                       focusedErrorBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(color: Colors.red, width: 1.5),
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   _label('Certificate issued'),
//                   Row(
//                     children: [
//                       Radio<bool>(
//                         value: true,
//                         groupValue: _certificateIssued,
//                         activeColor: trainingGreen,
//                         onChanged: (value) {
//                           if (value != null) {
//                             setState(() => _certificateIssued = value);
//                           }
//                         },
//                       ),
//                       const Text(
//                         'Yes',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: trainingText,
//                         ),
//                       ),
//                       const SizedBox(width: 25),
//                       Radio<bool>(
//                         value: false,
//                         groupValue: _certificateIssued,
//                         activeColor: trainingGreen,
//                         onChanged: (value) {
//                           if (value != null) {
//                             setState(() => _certificateIssued = value);
//                           }
//                         },
//                       ),
//                       const Text(
//                         'No',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: trainingText,
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   _sectionTitle('PHOTO / DOCUMENTATION'),
//
//                   const SizedBox(height: 10),
//
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _uploadButton(
//                           label: 'Photograph',
//                           icon: Icons.camera_alt_outlined,
//                           backgroundColor: trainingPhotoBackground,
//                           onTap: _pickPhotographs,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: _uploadButton(
//                           label: 'Document',
//                           icon: Icons.description_outlined,
//                           backgroundColor: trainingDocumentBackground,
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
//                       color: trainingMuted,
//                     ),
//                   ),
//
//                   if (_photographs.isNotEmpty) ...[
//                     const SizedBox(height: 14),
//                     _label('Attached Photographs:'),
//                     ...List.generate(
//                       _photographs.length,
//                       (index) => _fileTile(
//                         _photographs[index].name,
//                         () => _removePhotograph(index),
//                       ),
//                     ),
//                   ],
//
//                   if (_documents.isNotEmpty) ...[
//                     const SizedBox(height: 14),
//                     _label('Attached Documents:'),
//                     ...List.generate(
//                       _documents.length,
//                       (index) => _fileTile(
//                         _documents[index].name,
//                         () => _removeDocument(index),
//                       ),
//                     ),
//                   ],
//
//                   const SizedBox(height: 16),
//
//                   _label('Description / caption'),
//                   TextFormField(
//                     controller: _captionController,
//                     maxLines: 2,
//                     style: const TextStyle(fontSize: 14, color: trainingText),
//                     decoration: _inputDecoration(
//                       hint: 'Add caption for uploaded files',
//                     ),
//                   ),
//
//                   const SizedBox(height: 10),
//
//                   const Text(
//                     'Date, time and GPS metadata are attached automatically. Personal identifiers should not be captured unnecessarily.',
//                     style: TextStyle(
//                       fontSize: 11.5,
//                       height: 1.35,
//                       color: trainingMuted,
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
//                                 backgroundColor: trainingGreen,
//                                 foregroundColor: Colors.white,
//                                 disabledBackgroundColor: trainingGreen.withValues(
//                                   alpha: 0.6,
//                                 ),
//                                 elevation: 0,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(24),
//                                 ),
//                               ),
//                               child: _isSaving
//                                   ? const SizedBox(
//                                       width: 22,
//                                       height: 22,
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
//                                 foregroundColor: trainingGreen,
//                                 backgroundColor: Colors.white,
//                                 side: const BorderSide(color: trainingBorder),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(24),
//                                 ),
//                               ),
//                               child: const Text(
//                                 'Cancel',
//                                 style: TextStyle(
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.w600,
//                                   color: trainingGreen,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     )
//                   else ...[
//                     SizedBox(
//                       width: double.infinity,
//                       height: 48,
//                       child: ElevatedButton(
//                         onPressed: _isSaving ? null : _saveTraining,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: trainingGreen,
//                           foregroundColor: Colors.white,
//                           disabledBackgroundColor: trainingGreen.withValues(
//                             alpha: 0.6,
//                           ),
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(24),
//                           ),
//                         ),
//                         child: _isSaving
//                             ? const SizedBox(
//                                 width: 22,
//                                 height: 22,
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
//                     SizedBox(
//                       width: double.infinity,
//                       height: 46,
//                       child: OutlinedButton(
//                         onPressed: () => Navigator.pop(context),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: trainingGreen,
//                           backgroundColor: Colors.white,
//                           side: const BorderSide(color: trainingBorder),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(24),
//                           ),
//                         ),
//                         child: const Text(
//                           'Cancel',
//                           style: TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w600,
//                             color: trainingGreen,
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
//       bottomNavigationBar: const _TrainingBottomNavigation(),
//     );
//   }
//
//   Widget _label(String text) {
//     if (text.contains('*')) {
//       final parts = text.split('*');
//       return Padding(
//         padding: const EdgeInsets.only(bottom: 6),
//         child: RichText(
//           text: TextSpan(
//             children: [
//               TextSpan(
//                 text: parts[0],
//                 style: const TextStyle(
//                   color: trainingText,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const TextSpan(
//                 text: '*',
//                 style: TextStyle(
//                   color: trainingred,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               if (parts.length > 1 && parts[1].isNotEmpty)
//                 TextSpan(
//                   text: parts[1],
//                   style: const TextStyle(
//                     color: trainingText,
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
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
//         text,
//         style: const TextStyle(
//           color: trainingText,
//           fontSize: 13,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
//
//   Widget _sectionTitle(String text) {
//     return Text(
//       text,
//       style: const TextStyle(
//         color: trainingMuted,
//         fontSize: 11.5,
//         fontWeight: FontWeight.w700,
//         letterSpacing: 0.5,
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
//         borderSide: const BorderSide(color: trainingBorder),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: trainingBorder),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: trainingGreen, width: 1.5),
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
//   Widget _uploadButton({
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
//           border: Border.all(
//             color: trainingBorder,
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: trainingGreen, size: 20),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//                 color: trainingText,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _fileTile(String fileName, VoidCallback onRemove) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF1F5F9),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: trainingBorder),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.attach_file, color: trainingGreen, size: 20),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               fileName,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(fontSize: 12.5, color: trainingText),
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.close, color: trainingMuted, size: 18),
//             padding: EdgeInsets.zero,
//             constraints: const BoxConstraints(),
//             onPressed: onRemove,
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _TrainingBottomNavigation extends StatelessWidget {
//   const _TrainingBottomNavigation();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         border: Border(top: BorderSide(color: trainingBorder, width: 1)),
//       ),
//       child: BottomNavigationBar(
//         currentIndex: 1, // Highlight 'Actions'
//         onTap: (index) => Navigator.pop(context, index),
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: Colors.white,
//         selectedItemColor: trainingGreen,
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
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cohv/core/services/media_picker_service.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/core/widgets/searchable_dropdown.dart';
import 'package:cohv/core/models/geo_location_data.dart';
import 'package:cohv/core/services/location_service.dart';
import 'package:cohv/core/services/media_geotag_service.dart';

import '../domain/capacity_building_models.dart';
import '../data/capacity_building_api_service.dart';

const Color trainingGreen = Color(0xFF136B4F);
const Color trainingBackground = Color(0xFFF9FAFB);
const Color trainingBorder = Color(0xFFE2E8F0);
const Color trainingMuted = Color(0xFF64748B);
const Color trainingred = Color(0xFFF5092B);
const Color trainingPhotoBackground = Color(0xFFEFF6FF); // Soft blue
const Color trainingDocumentBackground = Color(0xFFFFF7ED); // Warm cream
const Color trainingText = Color(0xFF1E293B);

class NewTrainingAttendedScreen extends StatefulWidget {
  final String? volunteerId;
  final TrainingAttendedRecordModel? editRecord;

  const NewTrainingAttendedScreen({
    super.key,
    this.volunteerId,
    this.editRecord,
  });

  bool get isEditMode => editRecord != null;

  @override
  State<NewTrainingAttendedScreen> createState() =>
      _NewTrainingAttendedScreenState();
}

class _NewTrainingAttendedScreenState extends State<NewTrainingAttendedScreen> {
  final _formKey = GlobalKey<FormState>();

  final _venueController = TextEditingController();
  final _chairedByController = TextEditingController();
  final _keyPointsController = TextEditingController();
  final _captionController = TextEditingController();

  final CapacityBuildingApiService _apiService = CapacityBuildingApiService();
  List<TrainingMasterModel> _trainingMasters = [];
  TrainingMasterModel? _selectedMaster;
  bool _isLoadingMasters = true;

  DateTime _selectedDate = DateTime.now();
  bool _certificateIssued = false;
  bool _isSaving = false;
  // Real GPS Location state
  double? _lat;
  double? _lng;
  int? _accuracy;
  DateTime _gpsTimestamp = DateTime.now();
  GeoLocationData? _locationData;
  bool _isFetchingLocation = false;

  final List<XFile> _photographs = [];
  final List<PlatformFile> _documents = [];
  final List<String> _existingPhotos = [];
  final List<String> _existingDocuments = [];

  @override
  void initState() {
    super.initState();
    if (widget.editRecord != null) {
      final r = widget.editRecord!;
      _selectedDate = DateTime.tryParse(r.trainingDate) ?? DateTime.now();
      _venueController.text = r.venue ?? '';
      _chairedByController.text = r.chairedBy ?? '';
      _keyPointsController.text = r.keyPoints ?? '';
      _certificateIssued = r.certificateIssued;
      _captionController.text = r.caption ?? '';

      for (final p in r.photos) {
        if (p.isNotEmpty && !_existingPhotos.contains(p)) _existingPhotos.add(p);
      }
      for (final d in r.documents) {
        if (d.isNotEmpty && !_existingDocuments.contains(d)) _existingDocuments.add(d);
      }
      for (final att in r.richAttachments) {
        final path = att.storagePath.isNotEmpty ? att.storagePath : (att.fileUrl ?? '');
        if (path.isNotEmpty) {
          final kind = att.fileKind.toUpperCase();
          if (kind == 'IMAGE' || kind == 'PHOTO') {
            if (!_existingPhotos.contains(path)) _existingPhotos.add(path);
          } else {
            if (!_existingDocuments.contains(path)) _existingDocuments.add(path);
          }
        }
      }
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
    _venueController.dispose();
    _chairedByController.dispose();
    _keyPointsController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: trainingGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: trainingText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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
  //     _showMessage('You can attach up to 5 photographs.');
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
      debugPrint('[TRAINING_ATTENDED] Error picking photo: $e');
      _showMessage('Unable to select photographs.');
    }
  }

  Future<void> _pickDocuments() async {
    final remaining = 4 - _documents.length;

    if (remaining <= 0) {
      _showMessage('You can attach up to 4 documents.');
      return;
    }

    try {
      final result = await MediaPickerService().pickDocuments(
        context,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
        allowMultiple: true,
      );

      if (result.isEmpty || !mounted) return;

      final validFiles = <PlatformFile>[];
      for (final file in result) {
        final size = (await file.length()) ?? _getFileSize(file);
        if (size <= 10 * 1024 * 1024) {
          validFiles.add(file);
          if (validFiles.length >= remaining) break;
        }
      }

      if (!mounted) return;

      setState(() {
        _documents.addAll(validFiles);
      });

      if (validFiles.length < result.length) {
        _showMessage(
          'Some files were skipped. Maximum 4 documents, 10 MB each.',
        );
      }
    } catch (e) {
      _showMessage('Unable to select documents.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  void _removePhotograph(int index) {
    setState(() => _photographs.removeAt(index));
  }

  void _removeDocument(int index) {
    setState(() => _documents.removeAt(index));
  }

  Future<void> _saveTraining() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedMaster == null) {
      _showMessage('Please select a training.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final session = await SessionManager.getUserSession();
      final dateStr =
          '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      // final request = TrainingAttendedCreateRequest(
      //   trainingId: _selectedMaster!.trainingId,
      //   trainingDate: dateStr,
      //   venue: _venueController.text.trim(),
      //   chairedBy: _chairedByController.text.trim(),
      //   keyPoints: _keyPointsController.text.trim(),
      //   caption: _captionController.text.trim().isEmpty
      //       ? null
      //       : _captionController.text.trim(),
      //   certificateIssued: _certificateIssued,
      //   clientRef: 'TRN-${DateTime.now().millisecondsSinceEpoch}',
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

            final request = TrainingAttendedCreateRequest(
        trainingId: _selectedMaster!.trainingId,
        trainingDate: dateStr,
        venue: _venueController.text.trim(),
        chairedBy: _chairedByController.text.trim(),
        keyPoints: _keyPointsController.text.trim(),
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        certificateIssued: _certificateIssued,
        clientRef: 'TRN-${DateTime.now().millisecondsSinceEpoch}',
        deviceId: session?.volunteerId,
        // 👇 ADD GPS TELEMETRY HERE:
        latitude: GeoLocationData.formatCoordinate(_lat),
        longitude: GeoLocationData.formatCoordinate(_lng),
        gpsAccuracyM: _accuracy,
        capturedAt: _gpsTimestamp.toUtc().toIso8601String(),
        photos: [
          ..._existingPhotos,
          ..._photographs
              .map((f) => f.path)
              .whereType<String>()
              .where((p) => p.isNotEmpty),
        ],
        documents: [
          ..._existingDocuments,
          ..._documents
              .map((f) => f.path)
              .whereType<String>()
              .where((p) => p.isNotEmpty),
        ],
      );

      final response = widget.isEditMode
          ? await _apiService.updateTrainingAttended(
              widget.editRecord!.trainingAttendedId,
              request,
            )
          : await _apiService.submitTrainingAttended(request);

      if (!mounted) return;

      setState(() => _isSaving = false);

      if (response.success) {
        final code = response.record?.trainingAttendedCode ?? '';
        final msg = widget.isEditMode
            ? (code.isNotEmpty
                  ? 'Training attended $code updated successfully.'
                  : 'Training attended record updated successfully.')
            : (code.isNotEmpty
                  ? 'Training attended $code recorded successfully.'
                  : response.message);
        _showMessage(msg);
        Navigator.pop(context, true);
      } else {
        _showMessage(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Unable to submit training attended: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: trainingBackground,
      appBar: AuthenticatedAppBar(
        title: widget.isEditMode
            ? 'Edit Training Attended'
            : 'New Training Attended',
        backgroundColor: trainingGreen,
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
              border: Border.all(color: trainingBorder),
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
                  _label('Training *'),
                  SearchableDropdownFormField<TrainingMasterModel>(
                    key: ValueKey(
                      'training_attended_${_selectedMaster?.trainingId ?? 'none'}_${_trainingMasters.length}',
                    ),
                    fieldId: 'training_attended',
                    primaryColor: trainingGreen,
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

                  _label('Date *'),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: trainingBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(_selectedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              color: trainingText,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: trainingText,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _label('Venue'),
                  TextFormField(
                    controller: _venueController,
                    style: const TextStyle(fontSize: 14, color: trainingText),
                    decoration: _inputDecoration(hint: 'e.g. Community Hall'),
                  ),

                  const SizedBox(height: 16),

                  _label('Chaired by'),
                  TextFormField(
                    controller: _chairedByController,
                    style: const TextStyle(fontSize: 14, color: trainingText),
                    decoration: _inputDecoration(hint: 'e.g. Dr. John Doe'),
                  ),

                  const SizedBox(height: 16),

                  _label('Key points / action agreed'),
                  TextFormField(
                    controller: _keyPointsController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13.5, color: trainingText),
                    decoration: InputDecoration(
                      hintText: 'Enter key points or decisions',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: trainingBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: trainingBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: trainingGreen,
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

                  const SizedBox(height: 16),

                  _label('Certificate issued'),
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _certificateIssued,
                        activeColor: trainingGreen,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _certificateIssued = value);
                          }
                        },
                      ),
                      const Text(
                        'Yes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: trainingText,
                        ),
                      ),
                      const SizedBox(width: 25),
                      Radio<bool>(
                        value: false,
                        groupValue: _certificateIssued,
                        activeColor: trainingGreen,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _certificateIssued = value);
                          }
                        },
                      ),
                      const Text(
                        'No',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: trainingText,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _sectionTitle('PHOTO / DOCUMENTATION'),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _uploadButton(
                          label: 'Photograph',
                          icon: Icons.camera_alt_outlined,
                          backgroundColor: trainingPhotoBackground,
                          onTap: _pickPhotographs,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _uploadButton(
                          label: 'Document',
                          icon: Icons.description_outlined,
                          backgroundColor: trainingDocumentBackground,
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
                      color: trainingMuted,
                    ),
                  ),

                  if (_photographs.isNotEmpty || _existingPhotos.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _label('Attached Photographs:'),
                    ...List.generate(
                      _existingPhotos.length,
                      (index) => _fileTile(
                        _existingPhotos[index].split(RegExp(r'[/\\]')).last.split('?').first,
                        () => setState(() => _existingPhotos.removeAt(index)),
                      ),
                    ),
                    ...List.generate(
                      _photographs.length,
                      (index) => _fileTile(
                        _photographs[index].name,
                        () => _removePhotograph(index),
                      ),
                    ),
                  ],

                  if (_documents.isNotEmpty || _existingDocuments.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _label('Attached Documents:'),
                    ...List.generate(
                      _existingDocuments.length,
                      (index) => _fileTile(
                        _existingDocuments[index].split(RegExp(r'[/\\]')).last.split('?').first,
                        () => setState(() => _existingDocuments.removeAt(index)),
                      ),
                    ),
                    ...List.generate(
                      _documents.length,
                      (index) => _fileTile(
                        _documents[index].name,
                        () => _removeDocument(index),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  _label('Description / caption'),
                  TextFormField(
                    controller: _captionController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14, color: trainingText),
                    decoration: _inputDecoration(
                      hint: 'Add caption for uploaded files',
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Date, time and GPS metadata are attached automatically. Personal identifiers should not be captured unnecessarily.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: trainingMuted,
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
                                backgroundColor: trainingGreen,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: trainingGreen
                                    .withValues(alpha: 0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
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
                                foregroundColor: trainingGreen,
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: trainingBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: trainingGreen,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveTraining,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: trainingGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: trainingGreen.withValues(
                            alpha: 0.6,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
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
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: trainingGreen,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: trainingBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: trainingGreen,
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
      bottomNavigationBar: const _TrainingBottomNavigation(),
    );
  }

  Widget _label(String text) {
    if (text.contains('*')) {
      final parts = text.split('*');
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: parts[0],
                style: const TextStyle(
                  color: trainingText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(
                text: '*',
                style: TextStyle(
                  color: trainingred,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (parts.length > 1 && parts[1].isNotEmpty)
                TextSpan(
                  text: parts[1],
                  style: const TextStyle(
                    color: trainingText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
        text,
        style: const TextStyle(
          color: trainingText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: trainingMuted,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
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
        borderSide: const BorderSide(color: trainingBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: trainingBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: trainingGreen, width: 1.5),
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

  Widget _uploadButton({
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
          border: Border.all(color: trainingBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: trainingGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: trainingText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fileTile(String fileName, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: trainingBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: trainingGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: trainingText),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: trainingMuted, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _TrainingBottomNavigation extends StatelessWidget {
  const _TrainingBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: trainingBorder, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: 1, // Highlight 'Actions'
        onTap: (index) => Navigator.pop(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: trainingGreen,
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
