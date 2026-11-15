import 'package:flutter/material.dart';
import 'package:flutter_expandable_table/flutter_expandable_table.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:time/time.dart';

import '../l10n/app_strings.dart';
import '../pages_registry.dart';
import '../services/db_service.dart';
import '../widgets/page_shell.dart';
import '../widgets/textured_button.dart';
import '../widgets/time_spinner_block.dart';

const kServices = ['React Native', 'Android', 'iOS', 'SwiftUI', 'Flutter', '.NET'];
const _icons = [
  TablerIcons.brand_react_native, TablerIcons.brand_android, TablerIcons.brand_apple,
  TablerIcons.brand_swift, TablerIcons.brand_flutter, TablerIcons.brand_c_sharp, 
];
const _availability = [70.0, 85.0, 80.0, 65.0, 95.0, 75.0];

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      slug: 'app-dev-services',
      title: context.tr('services'),
      crumbs: [context.tr('services')],
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [

        SizedBox(
          height: 6 * 96.0 + 70,
          child: ExpandableTable(
            firstHeaderCell: ExpandableTableCell(child: const Center(child: Text('Service'))),
            headerHeight: 50,
            firstColumnWidth: 170,
            defaultsColumnWidth: 140,
            defaultsRowHeight: 96,
            expanded: true,
            headers: [ExpandableTableHeader(cell: ExpandableTableCell(child: const Center(child: Text('Availability'))))],
            rows: [
              for (int i = 0; i < kServices.length; i++)
                ExpandableTableRow(
                  height: 96,
                  firstCell: ExpandableTableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(children: [Icon(_icons[i]), const SizedBox(width: 8), Flexible(child: Text(kServices[i]))]),
                    ),
                  ),
                  cells: [
                    ExpandableTableCell(
                      child: Center(
                        child: SleekCircularSlider(
                          min: 0,
                          max: 100,
                          initialValue: _availability[i],
                          appearance: CircularSliderAppearance(
                            size: 76,
                            customWidths: CustomSliderWidths(progressBarWidth: 8, trackWidth: 3),
                            infoProperties: InfoProperties(
                              mainLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              modifier: (v) => '${v.ceil()} %',
                            ),
                          ),

                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Choose a time', style: Theme.of(context).textTheme.titleMedium),
        TimeSpinnerBlock(onTime: (_) {}),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: TexturedButton(label: context.tr('agenda'), icon: Icons.event, onPressed: () => openPage(context, 'coding-agenda'))),
      ]),
    );
  }
}


class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});
  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  DateTime _time = DateTime.now() + 1.hours;
  CalendarFormat _format = CalendarFormat.month;
  String? _service;
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _build() async {
    if (_service == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('service'))));
      return;
    }
    setState(() => _busy = true);
    final when = DateTime(_selected.year, _selected.month, _selected.day, _time.hour, _time.minute);
    await Db.addBooking(_service!, when, _note.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    openPage(context, 'chart'); 
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      slug: 'coding-agenda',
      title: context.tr('agenda'),
      crumbs: [context.tr('services'), context.tr('agenda')],
      busy: _busy,
      child: ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 100), children: [
        TableCalendar(
          locale: Localizations.localeOf(context).toLanguageTag(),
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: _focused,
          calendarFormat: _format,
          selectedDayPredicate: (d) => isSameDay(_selected, d),
          onDaySelected: (s, f) => setState(() {
            _selected = s;
            _focused = f;
          }),
          onFormatChanged: (f) => setState(() => _format = f),
          onPageChanged: (f) => _focused = f,
        ),
        const Divider(),
        TimeSpinnerBlock(onTime: (t) => _time = t),
        const SizedBox(height: 8),
 
        PopupMenuButton<String>(
          position: PopupMenuPosition.over,
          offset: Offset(0, -(kServices.length * 48.0 + 8)),
          onSelected: (v) => setState(() => _service = v),
          itemBuilder: (_) => [for (final s in kServices) PopupMenuItem(value: s, child: Text(s))],
          child: InputDecorator(
            decoration: InputDecoration(border: const OutlineInputBorder(), labelText: context.tr('service')),
            child: Row(children: [Expanded(child: Text(_service ?? '—')), const Icon(Icons.arrow_drop_up)]),
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: _note, minLines: 3, maxLines: 6, decoration: InputDecoration(border: const OutlineInputBorder(), hintText: context.tr('notesHint'))),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: TexturedButton(label: context.tr('buildChart'), icon: Icons.bar_chart, onPressed: _build)),
      ]),
    );
  }
}
