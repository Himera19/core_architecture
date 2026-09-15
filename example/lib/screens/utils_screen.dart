import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import '../showcase/section.dart';

/// [DateHelper], [Validators] run live, [SpacingUtils] and [UrlLauncher].
class UtilsScreen extends StatefulWidget {
  const UtilsScreen({super.key});

  static const String path = '/utils';

  @override
  State<UtilsScreen> createState() => _UtilsScreenState();
}

class _UtilsScreenState extends State<UtilsScreen> {
  DateTime _picked = DateTime.now();
  String _probe = '';

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colorScheme;
    final DateTime now = DateTime.now();

    return ShowcasePage(
      title: 'Utils',
      sections: [
        Section(
          title: 'Formatting',
          api: 'DateHelper.formatDate / formatTime / formatDateTime',
          children: [
            Readout('formatDate', DateHelper.formatDate(now)),
            Readout('formatTime', DateHelper.formatTime(now)),
            Readout('formatDateTime', DateHelper.formatDateTime(now)),
            Readout(
              'formatMinutesFromInt(135)',
              DateHelper.formatMinutesFromInt(135),
            ),
            Readout(
              'getGreeting',
              DateHelper.getGreeting(
                morning: 'Good morning',
                afternoon: 'Good afternoon',
                evening: 'Good evening',
                night: 'Good night',
              ),
            ),
          ],
        ),

        Section(
          title: 'Relative dates, by calendar day',
          api: 'DateHelper.getRelativeDate',
          children: [
            // Anchored to midnight, which is exactly what the 4.0.0 fix
            // changed: these used to drift with the time of day.
            for (final offset in const [-3, -1, 0, 1, 3, 30])
              Readout(
                '${offset >= 0 ? '+' : ''}$offset days',
                DateHelper.getRelativeDate(
                  DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).add(Duration(days: offset)),
                  todayLabel: 'Today',
                  yesterdayLabel: 'Yesterday',
                  tomorrowLabel: 'Tomorrow',
                  daysAgoSuffix: 'days ago',
                  daysLaterSuffix: 'days later',
                ),
              ),
            Gap.hXs,
            Text(
              'Late last night still reads "Yesterday", however few hours ago '
              'it was.',
              style: AppTypography.bodySm.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),

        Section(
          title: 'Date questions',
          api: 'DateHelper — day checks, boundaries, names',
          children: [
            CustomButton(
              text: 'Pick a date: ${DateHelper.formatDate(_picked)}',
              type: ButtonType.outlined,
              size: ButtonSize.small,
              icon: Icons.calendar_today,
              onPressed: () async {
                final DateTime? chosen = await showDatePicker(
                  context: context,
                  initialDate: _picked,
                  firstDate: DateTime(now.year - 2),
                  lastDate: DateTime(now.year + 2),
                );
                if (chosen != null) setState(() => _picked = chosen);
              },
            ),
            Gap.hSm,
            Readout('isToday', '${DateHelper.isToday(_picked)}'),
            Readout('isYesterday', '${DateHelper.isYesterday(_picked)}'),
            Readout('isTomorrow', '${DateHelper.isTomorrow(_picked)}'),
            Readout(
              'isSameDay(now)',
              '${DateHelper.isSameDay(_picked, now)}',
            ),
            Readout(
              'getStartOfDay',
              DateHelper.formatDateTime(DateHelper.getStartOfDay(_picked)),
            ),
            Readout(
              'getEndOfDay',
              DateHelper.formatDateTime(DateHelper.getEndOfDay(_picked)),
            ),
            Gap.hSm,

            // A real month strip: getDaysInMonth supplies the days and
            // getDayName labels them, with the picked day filled in.
            Text(
              '${DateHelper.getMonthName(_picked.month)} ${_picked.year}',
              style: AppTypography.labelLg,
            ),
            Gap.hXs,
            Wrap(
              spacing: AppSpacings.wXxs,
              runSpacing: AppSpacings.hXxs,
              children: [
                for (final day in DateHelper.getDaysInMonth(_picked))
                  Tooltip(
                    message: DateHelper.getDayName(day.weekday),
                    child: Container(
                      width: AppSizes.avatarSm,
                      height: AppSizes.avatarSm,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: DateHelper.isSameDay(day, _picked)
                            ? colors.primary
                            : DateHelper.isToday(day)
                            ? colors.primaryContainer
                            : colors.surfaceContainerHighest,
                        borderRadius: RadiusUtils.all(AppRadius.sm),
                      ),
                      child: Text(
                        '${day.day}',
                        style: AppTypography.labelSm.copyWith(
                          color: DateHelper.isSameDay(day, _picked)
                              ? colors.onPrimary
                              : colors.onSurface,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Gap.hSm,

            // dayNames, used the way a week header uses them.
            Row(
              children: [
                for (int weekday = 1; weekday <= 7; weekday++)
                  Expanded(
                    child: Container(
                      padding: SpacingUtils.vertical(AppSpacings.hXxs),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: weekday == _picked.weekday
                            ? colors.primaryContainer
                            : null,
                        borderRadius: RadiusUtils.all(AppRadius.sm),
                      ),
                      child: Text(
                        // The names are Turkish in the package; three letters
                        // is what a week header has room for.
                        DateHelper.getDayName(weekday).substring(0, 3),
                        style: AppTypography.labelSm,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        Section(
          title: 'Every validator, against one input',
          api: 'Validators',
          children: [
            CustomTextField(
              label: 'Type anything',
              hint: 'e.g. a@b.com, 5551234567, https://x.dev, 12.5',
              onChanged: (value) => setState(() => _probe = value),
            ),
            Gap.hSm,
            for (final (name, result) in [
              ('required', Validators.required(_probe, errorMessage: 'empty')),
              ('email', Validators.email(_probe, errorMessage: 'not an email')),
              (
                'password (min 6)',
                Validators.password(_probe, errorMessage: 'too short'),
              ),
              ('number', Validators.number(_probe, errorMessage: 'not a number')),
              (
                'positiveNumber',
                Validators.positiveNumber(_probe, errorMessage: 'not positive'),
              ),
              ('amount', Validators.amount(_probe, errorMessage: 'not an amount')),
              (
                'minLength(3)',
                Validators.minLength(_probe, 3, errorMessage: 'under 3'),
              ),
              (
                'maxLength(10)',
                Validators.maxLength(_probe, 10, errorMessage: 'over 10'),
              ),
              (
                'lengthRange(3,10)',
                Validators.lengthRange(_probe, 3, 10, errorMessage: 'out of range'),
              ),
              ('phone', Validators.phone(_probe, errorMessage: 'not a phone')),
              ('url', Validators.url(_probe, errorMessage: 'not a url')),
              ('date', Validators.date(_probe, errorMessage: 'not a date')),
              (
                'futureDate',
                Validators.futureDate(_probe, errorMessage: 'not future'),
              ),
              (
                'pastDate',
                Validators.pastDate(_probe, errorMessage: 'not past'),
              ),
              (
                'custom (starts with a)',
                Validators.custom(
                  _probe,
                  (value) => value.startsWith('a'),
                  'does not start with a',
                ),
              ),
            ])
              Padding(
                padding: SpacingUtils.onlyBottom(AppSpacings.hXxs),
                child: Row(
                  children: [
                    Icon(
                      result == null ? Icons.check_circle : Icons.cancel,
                      size: AppSizes.iconSm,
                      color: result == null ? AppColors.success : colors.error,
                    ),
                    Gap.wXs,
                    SizedBox(
                      width: AppSizes.thumbnailMd + AppSpacings.wLg,
                      child: Text(name, style: AppTypography.bodySm),
                    ),
                    Expanded(
                      child: Text(
                        result ?? 'passes',
                        style: AppTypography.labelSm.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        Section(
          title: 'Padding helpers',
          api: 'SpacingUtils',
          children: [
            for (final (name, insets) in [
              ('all(rMd)', SpacingUtils.all(AppSpacings.rMd)),
              ('horizontal(wLg)', SpacingUtils.horizontal(AppSpacings.wLg)),
              ('vertical(hSm)', SpacingUtils.vertical(AppSpacings.hSm)),
              ('onlyLeft(wXl)', SpacingUtils.onlyLeft(AppSpacings.wXl)),
              ('onlyRight(wXl)', SpacingUtils.onlyRight(AppSpacings.wXl)),
              ('onlyTop(hLg)', SpacingUtils.onlyTop(AppSpacings.hLg)),
              ('onlyBottom(hLg)', SpacingUtils.onlyBottom(AppSpacings.hLg)),
              (
                'symmetric(...)',
                SpacingUtils.symmetric(
                  vertical: AppSpacings.hXs,
                  horizontal: AppSpacings.wLg,
                ),
              ),
              ('page', SpacingUtils.page),
              ('card', SpacingUtils.card),
              ('zero', SpacingUtils.zero),
            ])
              Padding(
                padding: SpacingUtils.onlyBottom(AppSpacings.hXxs),
                child: Container(
                  color: colors.primary.withAlpha(AppOpacities.extraLow),
                  child: Padding(
                    padding: insets,
                    child: Container(
                      color: colors.surface,
                      padding: SpacingUtils.all(AppSpacings.rXxs),
                      child: Text(name, style: AppTypography.labelSm),
                    ),
                  ),
                ),
              ),
          ],
        ),

        Section(
          title: 'Opening a link',
          api: 'UrlLauncher.goToUrl',
          children: [
            CustomButton(
              text: 'Open flutter.dev',
              icon: Icons.open_in_new,
              type: ButtonType.outlined,
              onPressed: () async {
                try {
                  await UrlLauncher.goToUrl('https://flutter.dev');
                } catch (e) {
                  if (context.mounted) context.showError('$e');
                }
              },
            ),
            Gap.hXs,
            Text(
              'Leaves the app: launches in the external browser.',
              style: AppTypography.bodySm.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
