//  Copyright (c) 2019 Aleksander Woźniak
//  Licensed under Apache License v2.0

library table_calendar;

import 'package:flutter/material.dart';

import 'src/logic/calendar_logic.dart';
import 'src/styles/styles.dart';
import 'src/widgets/widgets.dart';

export 'src/styles/styles.dart';

typedef void _OnDaySelected(DateTime day);
typedef void _OnFormatChanged(CalendarFormat format);

/// Format to display the `TableCalendar` with.
enum CalendarFormat { month, twoWeeks, week }

/// Available animations to update the `CalendarFormat` with.
enum FormatAnimation { slide, scale }

/// Highly customizable Calendar widget organized neatly into a `Table`.
/// Autosizes vertically, saving space for other widgets.
class TableCalendar extends StatefulWidget {
  /// Contains a `List` of objects (eg. events) assigned to particular `DateTime`s.
  /// Each `DateTime` inside this `Map` should get its own `List` of above mentioned objects.
  final Map<DateTime, List> events;

  /// Called whenever any day gets tapped.
  final _OnDaySelected onDaySelected;

  /// Called whenever `CalendarFormat` changes.
  final _OnFormatChanged onFormatChanged;

  /// Initially selected DateTime. Usually it will be `DateTime.now()`.
  final DateTime initialDate;

  /// `CalendarFormat` which will be displayed first.
  final CalendarFormat initialCalendarFormat;

  /// `CalendarFormat` which overrides any internal logic.
  /// Use if you need total programmatic control over `TableCalendar`'s format.
  ///
  /// Makes `initialCalendarFormat` and `availableCalendarFormats` obsolete.
  final CalendarFormat forcedCalendarFormat;

  /// `List` of `CalendarFormat`s which internal logic can use to manage `TableCalendar`'s format.
  /// Order of items will reflect order of format changes when FormatButton is pressed.
  final List<CalendarFormat> availableCalendarFormats;

  /// Used to show/hide Header.
  final bool headerVisible;

  /// Animation to run when `CalendarFormat` gets changed.
  final FormatAnimation formatAnimation;

  /// Style for `TableCalendar`'s content.
  final CalendarStyle calendarStyle;

  /// Style for DaysOfWeek displayed between `TableCalendar`'s Header and content.
  final DaysOfWeekStyle daysOfWeekStyle;

  /// Style for `TableCalendar`'s Header.
  final HeaderStyle headerStyle;

  TableCalendar({
    Key key,
    this.events = const {},
    this.onDaySelected,
    this.onFormatChanged,
    this.initialDate,
    this.initialCalendarFormat = CalendarFormat.month,
    this.forcedCalendarFormat,
    this.availableCalendarFormats = const [CalendarFormat.month, CalendarFormat.twoWeeks, CalendarFormat.week],
    this.headerVisible = true,
    this.formatAnimation = FormatAnimation.slide,
    this.calendarStyle = const CalendarStyle(),
    this.daysOfWeekStyle = const DaysOfWeekStyle(),
    this.headerStyle = const HeaderStyle(),
  })  : assert(availableCalendarFormats.contains(initialCalendarFormat)),
        assert(availableCalendarFormats.length <= CalendarFormat.values.length),
        super(key: key);

  @override
  _TableCalendarState createState() {
    return new _TableCalendarState();
  }
}

class _TableCalendarState extends State<TableCalendar> with SingleTickerProviderStateMixin {
  CalendarLogic _calendarLogic;
  double _dx;

  @override
  void initState() {
    super.initState();
    _calendarLogic = CalendarLogic(
      widget.initialCalendarFormat,
      widget.availableCalendarFormats,
      initialDate: widget.initialDate,
    );
    _dx = 0;
  }

  void _selectPrevious() {
    setState(() {
      _calendarLogic.selectPrevious();
    });

    _dx = -1.2;
  }

  void _selectNext() {
    setState(() {
      _calendarLogic.selectNext();
    });

    _dx = 1.2;
  }

  void _selectDate(DateTime date) {
    setState(() {
      _calendarLogic.selectedDate = date;
    });

    if (widget.onDaySelected != null) {
      widget.onDaySelected(date);
    }
  }

  void _toggleCalendarFormat() {
    setState(() {
      _calendarLogic.toggleCalendarFormat();
    });

    if (widget.onFormatChanged != null) {
      widget.onFormatChanged(_calendarLogic.calendarFormat);
    }
  }

  void _onSwipe(DismissDirection direction) {
    if (direction == DismissDirection.startToEnd) {
      // Swipe right
      _selectPrevious();
    } else {
      // Swipe left
      _selectNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (widget.headerVisible) {
      children.addAll([
        const SizedBox(height: 6.0),
        _buildHeader(),
      ]);
    }

    children.addAll([
      const SizedBox(height: 10.0),
      _buildCalendarContent(),
      const SizedBox(height: 4.0),
    ]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildHeader() {
    final children = [
      CustomIconButton(
        icon: Icon(Icons.chevron_left, color: widget.headerStyle.iconColor),
        onTap: _selectPrevious,
        margin: widget.headerStyle.leftChevronMargin,
        padding: widget.headerStyle.leftChevronPadding,
      ),
      Expanded(
        child: Text(
          _calendarLogic.headerText,
          style: widget.headerStyle.titleTextStyle,
          textAlign: widget.headerStyle.centerHeaderTitle ? TextAlign.center : TextAlign.start,
        ),
      ),
      CustomIconButton(
        icon: Icon(Icons.chevron_right, color: widget.headerStyle.iconColor),
        onTap: _selectNext,
        margin: widget.headerStyle.rightChevronMargin,
        padding: widget.headerStyle.rightChevronPadding,
      ),
    ];

    if (widget.headerStyle.formatButtonVisible && widget.availableCalendarFormats.length > 1 && widget.forcedCalendarFormat == null) {
      children.insert(2, const SizedBox(width: 8.0));
      children.insert(3, _buildFormatButton());
    }

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: children,
    );
  }

  Widget _buildFormatButton() {
    return GestureDetector(
      onTap: _toggleCalendarFormat,
      child: Container(
        decoration: widget.headerStyle.formatButtonDecoration,
        padding: widget.headerStyle.formatButtonPadding,
        child: Text(
          _calendarLogic.headerToggleText,
          style: widget.headerStyle.formatButtonTextStyle,
        ),
      ),
    );
  }

  Widget _buildCalendarContent() {
    if (widget.formatAnimation == FormatAnimation.slide) {
      return AnimatedSize(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
        alignment: Alignment(0, -1),
        vsync: this,
        child: _buildTable(),
      );
    } else {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) {
          return SizeTransition(
            sizeFactor: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          );
        },
        child: _buildTable(
          key: ValueKey(_calendarLogic.calendarFormat),
        ),
      );
    }
  }

  Widget _buildTable({Key key}) {
    final children = <TableRow>[];
    final daysInWeek = 7;
    final calendarFormat = widget.forcedCalendarFormat != null ? widget.forcedCalendarFormat : _calendarLogic.calendarFormat;

    children.add(_buildDaysOfWeek());

    if (calendarFormat == CalendarFormat.week) {
      children.add(_buildTableRow(_calendarLogic.visibleWeek.toList()));
    } else if (calendarFormat == CalendarFormat.twoWeeks) {
      children.add(_buildTableRow(_calendarLogic.visibleTwoWeeks.take(daysInWeek).toList()));
      children.add(_buildTableRow(_calendarLogic.visibleTwoWeeks.skip(daysInWeek).toList()));
    } else {
      int x = 0;
      while (x < _calendarLogic.visibleMonth.length) {
        children.add(_buildTableRow(_calendarLogic.visibleMonth.skip(x).take(daysInWeek).toList()));
        x += daysInWeek;
      }
    }

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.decelerate,
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(begin: Offset(_dx, 0), end: Offset(0, 0)).animate(animation),
            child: child,
          );
        },
        layoutBuilder: (currentChild, _) => currentChild,
        child: Dismissible(
          key: ValueKey(_calendarLogic.pageId),
          resizeDuration: null,
          onDismissed: _onSwipe,
          direction: DismissDirection.horizontal,
          child: Table(
            // Makes this Table fill its parent horizontally
            defaultColumnWidth: FractionColumnWidth(1.0 / daysInWeek),
            children: children,
          ),
        ),
      ),
    );
  }

  TableRow _buildDaysOfWeek() {
    final daysOfWeek = _calendarLogic.daysOfWeek;
    final children = <Widget>[];

    children.add(Center(child: Text(daysOfWeek.first, style: widget.daysOfWeekStyle.weekendStyle)));
    children.addAll(
      daysOfWeek.sublist(1, daysOfWeek.length - 1).map(
            (text) => Center(
                  child: Text(text, style: widget.daysOfWeekStyle.weekdayStyle),
                ),
          ),
    );
    children.add(Center(child: Text(daysOfWeek.last, style: widget.daysOfWeekStyle.weekendStyle)));

    return TableRow(children: children);
  }

  TableRow _buildTableRow(List<DateTime> days) {
    return TableRow(children: days.map((date) => _buildTableCell(date)).toList());
  }

  // TableCell will have equal width and height
  Widget _buildTableCell(DateTime date) {
    return LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: constraints.maxWidth,
              minHeight: constraints.maxWidth,
            ),
            child: _buildCellContent(date),
          ),
    );
  }

  Widget _buildCellContent(DateTime date) {
    Widget content = CellWidget(
      text: '${date.day}',
      isSelected: _calendarLogic.isSelected(date),
      isToday: _calendarLogic.isToday(date),
      isWeekend: _calendarLogic.isWeekend(date),
      isOutsideMonth: _calendarLogic.isExtraDay(date),
      calendarStyle: widget.calendarStyle,
    );

    if (widget.events.containsKey(date) && widget.events[date].isNotEmpty) {
      final children = <Widget>[content];
      final maxMarkers = 4;

      children.add(
        Positioned(
          bottom: 5.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: widget.events[date].take(maxMarkers).map((_) => _buildMarker()).toList(),
          ),
        ),
      );

      content = Stack(
        alignment: Alignment.bottomCenter,
        children: children,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectDate(date),
      child: content,
    );
  }

  Widget _buildMarker() {
    return Container(
      width: 8.0,
      height: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 0.3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.calendarStyle.eventMarkerColor,
      ),
    );
  }
}
