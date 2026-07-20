import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';

/// A successful tool result carrying a single [text] block.
CallToolResult textResult(String text) =>
    CallToolResult(content: [TextContent(text: text)]);

/// A successful tool result carrying [value] pretty-printed as JSON.
CallToolResult jsonResult(Object? value) =>
    textResult(const JsonEncoder.withIndent('  ').convert(value));
