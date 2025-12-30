---
doc_id: meta/1_scheduling/index
chunk_id: meta/1_scheduling/index#chunk-2
heading_path: ["Schedules", "Cron syntax"]
chunk_type: prose
tokens: 1085
summary: "Cron syntax"
---

## Cron syntax

Windmill uses [hexagons's croner expression parser](https://github.com/hexagon/croner-rust). This library supports the Unix cron syntax as well as extensions allowing for more complex scheduling.

Although the syntaxes are similar, there are some notable differences:

| Feature                   | Unix cron               | hexagon's `croner` library                 |
|---------------------------|-------------------------|--------------------------------------------|
| **Seconds Field**         | Not included            | Included as the first field (optional)     |
| **Day of Week Index**     | Sunday = 0 through Saturday = 6 | Sunday = 0 through Saturday = 6, or SUN through SAT |
| **Month Representation**  | Numeric and short names | Numeric, short names, and name ranges      |
| **List and Range in Fields** | Supports lists and ranges | Supports lists, ranges, and combinations |
| **Step Values**           | Supported (e.g., `*/2`) | Supported, including additional complex patterns like `4#2` etc. |

Hexagon's croner expressions have the following additional modifiers:
  - _?_: In croner a questionmark behaves just as *, to allow for legacy cron
	patterns to be used.
  - _L_: The letter 'L' can be used in the day of the month field to indicate
    the last day of the month. When used in the day of the week field in
    conjunction with the # character, it denotes the last specific weekday of
    the month. For example, `5#L` represents the last Friday of the month.
  - _#_: The # character specifies the "nth" occurrence of a particular day
    within a month. For example, supplying `5#2` in the day of week field
    signifies the second Friday of the month. This can be combined with ranges
    and supports day names. For instance, MON-FRI#2 would match the Monday
    through Friday of the second week of the month.
  - _W_: The character 'W' is used to specify the closest weekday to a given day
    in the day of the month field. For example, 15W will match the closest
    weekday to the 15th of the month. If the specified day falls on a weekend
    (Saturday or Sunday), the pattern will match the closest weekday before or
    after that date. For instance, if the 15th is a Saturday, 15W will match the
    14th (Friday), and if the 15th is a Sunday, it will match the 16th (Monday).

| Field        | Required | Allowed values  | Allowed special characters | Remarks                                                                                                         |
| ------------ | -------- | --------------- | -------------------------- | --------------------------------------------------------------------------------------------------------------- |
| Seconds      | Optional | 0-59            | * , - / ?                  |                                                                                                                 |
| Minutes      | Yes      | 0-59            | * , - / ?                  |                                                                                                                 |
| Hours        | Yes      | 0-23            | * , - / ?                  |                                                                                                                 |
| Day of Month | Yes      | 1-31            | * , - / ? L W              |                                                                                                                 |
| Month        | Yes      | 1-12 or JAN-DEC | * , - / ?                  |                                                                                                                 |
| Day of Week  | Yes      | 0-7 or SUN-SAT  | * , - / ? # L              | 0 to 6 are Sunday to Saturday<br /># is used to specify nth occurrence of a weekday |

Some complex examples supported by the new syntax:

| Schedule String | Meaning |
| --------------- | ------- |
| `0 0 */3 ? * *` | Every three hours |
| `0 0 12 * * ?`  | Every day at noon (12 PM) |
| `0 0 12 * * MON-FRI` | Every weekday at noon (12 PM) |
| `0 0 12 15 * ?` | Every month on the 15th at noon (12 PM) |
| `0 0 12 15W * ?` | Every month on the closest weekday to the 15th at noon (12 PM) |
| `0 0 12 ? * 5#3` | Every third Friday of the month at noon (12 PM) |
| `0 0 12 ? * 5L` | Every last Friday of the month at noon (12 PM) |
| `0 0 12 ? JAN,JUL,AUG *` | Every January, July, and August at noon (12 PM) |
| `0 0 12 ? FEB-DEC/2 *` | Every other month from February to December at noon (12 PM) |
| `0 0 12 1-15/2 * ?` | Every odd day from the 1st to the 15th of every month at noon (12 PM) |

Anyway, the simplified builder and [Windmill AI](./meta-22_ai_generation-index.md) will help you to create the cron expression.

:::warning Migrating from legacy cron syntax
New schedules created in Windmill will use the new cron syntax.

If you have existing schedules using the legacy cron syntax, you can migrate them to the new syntax by following these steps:

1. Go to the `Schedules` menu and select the schedule you want to edit.
2. Toggle the `enable latest Cron syntax`
3. Double check the preview for upcoming events and make sure it matches your expectations.
3. Click on the `Save` button.

This will update the schedule to use the new cron syntax. Note, you will not be able to revert to the legacy syntax.
<br />

![Migrate to croner](./17_migrate_to_croner.png 'Migrate to croner')
:::
