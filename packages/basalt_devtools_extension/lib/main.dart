import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'src/inspector_screen.dart';

void main() => runApp(const BasaltInspectorExtension());

/// Root of the basalt DevTools extension. [DevToolsExtension] supplies the app
/// shell (theme, connection state, VM service manager); we render the inspector
/// as its child.
class BasaltInspectorExtension extends StatelessWidget {
  const BasaltInspectorExtension({super.key});

  @override
  Widget build(BuildContext context) =>
      const DevToolsExtension(child: InspectorScreen());
}
