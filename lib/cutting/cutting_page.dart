import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sheet_data.dart';
import '../services/ranged_sheet_reader.dart';

class CuttingPage extends StatefulWidget {
  const CuttingPage({super.key});

  @override
  State<CuttingPage> createState() => _CuttingPageState();
}

class _CuttingPageState extends State<CuttingPage> {
  final _formKey = GlobalKey<FormState>();
  final _url = TextEditingController();
  final _sheet = TextEditingController();
  final _range = TextEditingController();
  final _header = TextEditingController();
  bool _loading = false;
  SheetData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _url.text = prefs.getString('cutting_url') ?? '';
    _sheet.text = prefs.getString('cutting_sheet') ?? '';
    _range.text = prefs.getString('cutting_range') ?? '';
    _header.text = prefs.getString('cutting_header') ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final source = SheetSource(
      spreadsheetId: SheetSource.extractId(_url.text),
      sheetName: _sheet.text.trim(),
      dataRange: _range.text.trim(),
      headerRange: _header.text.trim(),
    );
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
    });
    final client = http.Client();
    try {
      final data = await RangedSheetReader(client).read(source);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cutting_url', _url.text.trim());
      await prefs.setString('cutting_sheet', source.sheetName);
      await prefs.setString('cutting_range', source.dataRange);
      await prefs.setString('cutting_header', source.headerRange);
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      client.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _sheet.dispose();
    _range.dispose();
    _header.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cutting')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Cutting Sheet',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('The Google Sheet must be shared for public viewing.'),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(children: [
              _field(_url, 'Spreadsheet URL or ID',
                  'Paste the Google Sheets URL or ID'),
              _field(_sheet, 'Sheet name', 'Cutting'),
              _field(_range, 'Data range', 'A2:H'),
              _field(_header, 'Header range', 'A1:H1'),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _loading ? null : _submit,
                icon: const Icon(Icons.download),
                label: const Text('Read Cutting Data'),
              ),
            ]),
          ),
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SelectableText(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          if (_data != null) ...[
            const SizedBox(height: 24),
            Text('${_data!.rows.length} rows loaded',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_data!.rows.isEmpty) const Text('No data found in this range.'),
            if (_data!.rows.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    for (final heading in _data!.headers)
                      DataColumn(label: Text(heading)),
                  ],
                  rows: [
                    for (final row in _data!.rows)
                      DataRow(cells: [
                        for (final heading in _data!.headers)
                          DataCell(SelectableText(row.valueOf(heading) ?? '')),
                      ]),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, String hint) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? '$label is required'
              : null,
        ),
      );
}
