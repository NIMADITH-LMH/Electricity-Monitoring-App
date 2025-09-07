# Background Image Implementation Guide

This document explains how to apply the background image to all screens in the Electricity Monitoring App.

## Background Image

The background image for all screens should be:
`assets/images/background for other pages.jpg`

## How to Apply the Background Image

1. Import the BackgroundContainer widget:
```dart
import '../../widgets/background_container.dart';
```

2. Wrap your screen's body content with the BackgroundContainer:
```dart
Scaffold(
  appBar: AppBar(
    title: Text('Screen Title'),
  ),
  body: BackgroundContainer(
    child: YourScreenContent(),
  ),
)
```

3. Make text readable against the background:
   - For headings that are directly on the background, use:
   ```dart
   Text(
     'Your Heading',
     style: TextStyle(
       fontSize: 18,
       fontWeight: FontWeight.bold,
       color: Colors.white,
       shadows: [
         Shadow(
           blurRadius: 4.0,
           color: Colors.black.withOpacity(0.5),
           offset: const Offset(1, 1),
         ),
       ],
     ),
   )
   ```

   - Or use the CardThemeHelper utility class:
   ```dart
   import '../../utils/card_theme_helper.dart';
   
   Text(
     'Your Heading',
     style: CardThemeHelper.getHeadingStyle(),
   )
   ```

4. Make cards more readable by increasing opacity:
```dart
Card(
  elevation: 4,
  color: Colors.white.withOpacity(0.85),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: YourCardContent(),
)
```

5. For empty states or important messages, wrap them in semi-transparent cards:
```dart
Center(
  child: Card(
    color: Colors.white.withOpacity(0.85),
    elevation: 4,
    margin: EdgeInsets.all(16),
    child: Padding(
      padding: EdgeInsets.all(24.0),
      child: EmptyState(
        icon: Icons.info,
        message: 'Your message here',
      ),
    ),
  ),
)
```

## CardThemeHelper

The `CardThemeHelper` class provides consistent styling methods:

- `getHeadingStyle()`: For large titles (18pt, bold, with shadow)
- `getSubheadingStyle()`: For subtitles (16pt, medium weight, with shadow)
- `getBodyTextStyle()`: For regular text (14pt, regular weight)

## Screens Updated So Far

- ApplianceListScreen
- BudgetScreen
- SettingsScreen

## Remaining Screens to Update

Update all other screens following the pattern above.
