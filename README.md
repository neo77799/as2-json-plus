# JSON.as - Advanced JSON Parser for ActionScript 2

A comprehensive JSON parsing and stringifying library for ActionScript 2 with support for both strict and lenient parsing modes.

## Features

### Core JSON Parsing
- **Dual Mode Support**: Both strict (RFC-compliant) and lenient parsing modes
- **Extended Syntax Support** (lenient mode):
  - JavaScript-style comments (`//` and `/* */`)
  - Trailing commas in objects and arrays
  - Single quotes for strings
  - Unquoted object keys (identifier-style)
- **Advanced Number Handling**:
  - Exponential notation support (1e-3, 1E+2)
  - Leading zero validation
  - Big integer preservation as strings
- **Unicode Support**:
  - Full Unicode character support including surrogate pairs
  - Proper handling of U+2028 and U+2029 characters

### Security Features
- **DoS Protection**: Configurable maximum depth and input length limits
- **Error Handling**: Detailed error messages with line/column information
- **Input Validation**: Comprehensive syntax validation

### Stringify Features
- **Replacer Support**: Both function and array-based property filtering
- **Formatting Options**: Customizable indentation with spaces
- **Custom Serialization**: Support for `toJSON()` methods on objects

## Installation

Place `JSON.as` in your classpath and import it:

```actionscript
#include "JSON.as"
```

## Usage

### Basic Parsing

```actionscript
// Strict mode (RFC compliant)
var data:Object = JSON.parse('{"name": "John", "age": 30}');

// Lenient mode with extended features
var data:Object = JSON.parse(
  '{name: "John", age: 30,}', 
  {
    mode: "lenient",
    allowUnquotedKeys: true,
    allowTrailingComma: true
  }
);
```

### Stringify

```actionscript
var obj:Object = {name: "John", age: 30, tags: ["a", "b"]};

// Basic stringify
var json:String = JSON.stringify(obj);

// With formatting
var formatted:String = JSON.stringify(obj, null, 2);

// With replacer
var filtered:String = JSON.stringify(obj, ["name", "age"], 0);
```

### Configuration Options

```actionscript
var options:Object = {
  mode: "lenient",           // or "strict"
  allowComments: true,       // Allow // and /* */ comments
  allowTrailingComma: true,  // Allow trailing commas
  allowSingleQuotes: true,   // Allow 'single quotes'
  allowUnquotedKeys: true,   // Allow unquoted object keys
  preserveBigIntAsString: true, // Preserve large integers as strings
  maxDepth: 512,             // Maximum nesting depth
  maxLength: 10485760        // Maximum input length (10MB)
};

var data:Object = JSON.parse(jsonString, options);
```

## Test Suite

The `TestJSON.as` file includes comprehensive test cases:

### Test Categories
1. **Strict Mode Tests**: RFC-compliant parsing
2. **Lenient Mode Tests**: Extended syntax features
3. **Error Handling**: Proper error detection and messaging
4. **Unicode Support**: Surrogate pair handling
5. **Number Validation**: Exponential notation and edge cases
6. **Stringify Tests**: Formatting and replacer functionality

### Running Tests

```actionscript
// In frame actions or button handler
TestJSON.run();
```

## UI Component - JSON Tree Viewer

The `LoadAction.AS` file provides a Flash UI component for visualizing JSON data:

### Features
- **URL-based JSON loading** from remote sources
- **Tree view display** with expand/collapse functionality
- **Automatic expansion** of all nodes
- **Error handling** with detailed error messages
- **Cross-domain support** (requires crossdomain.xml)

### Usage
1. Place UI components on stage:
   - `urlInput` (TextInput)
   - `loadBtn` (Button) 
   - `tree` (Tree component)
2. Set `LoadAction.AS` as frame actions
3. Load JSON from URL or local data

## Error Handling

The library provides detailed error information:

```actionscript
try {
  var data:Object = JSON.parse(invalidJson);
} catch (e:Object) {
  trace("Error: " + e.name);
  trace("Message: " + e.message);
  trace("Location: line " + e.line + ", column " + e.col);
  trace("Snippet: " + e.snippet);
}
```

## Compatibility

- **Flash Player**: 8+
- **ActionScript**: 2.0
- **File Size**: Compact implementation suitable for web deployment

## License

This library is provided as-is for use in ActionScript 2 projects.

## Contributing

To add tests or features:
1. Add test cases to `TestJSON.as`
2. Ensure all tests pass
3. Update documentation as needed

## Demo

Try the live demo at: https://neo77799.github.io/as2-json-plus/

The demo showcases JSON parsing capabilities in a web context using the HTML viewer.

## Development Status

⚠️ **Note**: This library is currently under development. There may be bugs or incomplete features. Please report any issues you encounter.

## See Also

- The companion HTML viewer demonstrates JSON parsing in web context
- Python server (`start.py`) for local testing (not covered in this documentation)
