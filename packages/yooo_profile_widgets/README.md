# yooo_profile_widgets

Reusable Material Flutter widgets extracted from the Yooo.App client.

## Install

```sh
flutter pub add yooo_profile_widgets
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:yooo_profile_widgets/yooo_profile_widgets.dart';

class ProfileSummary extends StatelessWidget {
  const ProfileSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSection(
          title: 'Languages',
          icon: '🌐',
          child: TagWrap(
            tags: ['English', 'Hindi'],
            background: Color(0xFFD1FAE5),
            foreground: Color(0xFF065F46),
            showIcon: false,
          ),
        ),
        const SizedBox(height: 16),
        const StatTile(label: 'Height', value: '175 cm'),
        const SizedBox(height: 16),
        const PricingTable(
          rows: [PriceRow(duration: '1 Hour', rate: '100', unit: 'INR')],
        ),
      ],
    );
  }
}
```

The public library exports `ImageCarousel`, `InfoGrid`, `InfoTile`,
`PricingTable`, `PriceRow`, `ProfileSection`, `StarsLogo`, `StatTile`, and
`TagWrap`. Widgets use Material styling and can be composed with your own
application data and layout.

## Develop locally

From the package directory run `flutter pub get`. Before publishing, review
`dart pub publish --dry-run` and the list of included files.

## License

MIT. See the repository's `LICENSE` file.
