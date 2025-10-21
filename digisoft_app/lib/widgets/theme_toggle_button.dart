import 'package:digisoft_app/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return IconButton(
      icon: Icon(
        Provider.of<ThemeProvider>(context).isDarkMode 
            ? Icons.light_mode 
            : Icons.dark_mode,
        color: theme.appBarTheme.foregroundColor,
      ),
      onPressed: () {
        Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
      },
      tooltip: 'Toggle Theme',
    );
  }
}