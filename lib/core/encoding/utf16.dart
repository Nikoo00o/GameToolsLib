import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

/// Source code from old charset package from pub.dev modified only to match the newest flutter/dart version

// ignore_for_file: avoid_positional_boolean_parameters

/// Invalid codepoints or encodings may be substituted with the value U+fffd.
const int unicodeReplacementCharacterCodepoint = 0xfffd;

/// unicode BOM
const int unicodeBom = 0xfeff;

/// unicode BOM Low
const int unicodeUtfBomLo = 0xff;

/// unicode BOM High
const int unicodeUtfBomHi = 0xfe;

/// unicodeByteZeroMask
const int unicodeByteZeroMask = 0xff;

/// unicodeByteOneMask
const int unicodeByteOneMask = 0xff00;

/// unicodeValidRangeMax
const int unicodeValidRangeMax = 0x10ffff;

/// unicodePlaneOneMax
const int unicodePlaneOneMax = 0xffff;

/// unicodeUtf16ReservedLo
const int unicodeUtf16ReservedLo = 0xd800;

/// unicodeUtf16ReservedHi
const int unicodeUtf16ReservedHi = 0xdfff;

/// unicodeUtf16Offset
const int unicodeUtf16Offset = 0x10000;

/// unicodeUtf16SurrogateUnit0Base
const int unicodeUtf16SurrogateUnit0Base = 0xd800;

/// unicodeUtf16SurrogateUnit1Base
const int unicodeUtf16SurrogateUnit1Base = 0xdc00;

/// unicodeUtf16HiMask
const int unicodeUtf16HiMask = 0xffc00;

/// unicodeUtf16LoMask
const int unicodeUtf16LoMask = 0x3ff;

/// Utf16 Codec
class Utf16Codec extends Encoding {
  /// Utf16 Codec
  const Utf16Codec();

  @override
  Converter<List<int>, String> get decoder => const Utf16Decoder();

  @override
  Converter<String, List<int>> get encoder => const Utf16Encoder();

  @override
  String get name => 'utf-16';
}

/// Utf16 Encoder
class Utf16Encoder extends Converter<String, List<int>> {
  /// Utf16 Encoder
  const Utf16Encoder();

  @override
  List<int> convert(String input) => encodeUtf16Be(input, true);

  /// encode utf-16 BE format
  Uint8List encodeUtf16Be(String str, [bool writeBOM = false]) {
    final List<int> utf16CodeUnits = codepointsToUtf16CodeUnits(str.codeUnits);
    final Uint8List encoding = Uint8List(2 * utf16CodeUnits.length + (writeBOM ? 2 : 0));
    int i = 0;
    if (writeBOM) {
      encoding[i++] = unicodeUtfBomHi;
      encoding[i++] = unicodeUtfBomLo;
    }
    for (final int unit in utf16CodeUnits) {
      encoding[i++] = (unit & unicodeByteOneMask) >> 8;
      encoding[i++] = unit & unicodeByteZeroMask;
    }
    return encoding;
  }

  /// encode utf-16 LE format
  Uint8List encodeUtf16Le(String str, [bool writeBOM = false]) {
    final List<int> utf16CodeUnits = codepointsToUtf16CodeUnits(str.codeUnits);
    final Uint8List encoding = Uint8List(2 * utf16CodeUnits.length + (writeBOM ? 2 : 0));
    int i = 0;
    if (writeBOM) {
      encoding[i++] = unicodeUtfBomLo;
      encoding[i++] = unicodeUtfBomHi;
    }
    for (final int unit in utf16CodeUnits) {
      encoding[i++] = unit & unicodeByteZeroMask;
      encoding[i++] = (unit & unicodeByteOneMask) >> 8;
    }
    return encoding;
  }
}

/// Utf16Decoder
class Utf16Decoder extends Converter<List<int>, String> {
  /// Utf16Decoder
  const Utf16Decoder();

  /// Produce a String from a sequence of UTF-16 encoded bytes. This method always
  /// strips a leading BOM. Set the [replacementCodepoint] to null to throw  an
  /// ArgumentError rather than replace the bad value. The default
  /// value for the [replacementCodepoint] is U+FFFD.
  @override
  String convert(
    List<int> input, [
    int start = 0,
    int? end,
    int replacementCodepoint = unicodeReplacementCharacterCodepoint,
  ]) {
    final List<int> codeunits = Utf16BytesToCodeUnitsDecoder(
      input,
      start,
      end == null ? input.length : end - start,
      replacementCodepoint,
    ).decodeRest();
    return String.fromCharCodes(utf16CodeUnitsToCodepoints(codeunits, 0, null, replacementCodepoint).whereType<int>());
  }

  /// Produce a String from a sequence of UTF-16BE encoded bytes. This method
  /// strips a leading BOM by default, but can be overridden by setting the
  /// optional parameter [stripBom] to false. Set the [replacementCodepoint] to
  /// null to throw an ArgumentError rather than replace the bad value.
  /// The default value for the [replacementCodepoint] is U+FFFD.
  String decodeUtf16Be(
    List<int> input, [
    int start = 0,
    int? end,
    bool stripBom = true,
    int replacementCodepoint = unicodeReplacementCharacterCodepoint,
  ]) {
    final List<int> codeunits = Utf16beBytesToCodeUnitsDecoder(
      input,
      start,
      end == null ? input.length : end - start,
      stripBom,
      replacementCodepoint,
    ).decodeRest();
    return String.fromCharCodes(utf16CodeUnitsToCodepoints(codeunits, 0, null, replacementCodepoint).whereType<int>());
  }

  /// Produce a String from a sequence of UTF-16LE encoded bytes. This method
  /// strips a leading BOM by default, but can be overridden by setting the
  /// optional parameter [stripBom] to false. Set the [replacementCodepoint] to
  /// null to throw an ArgumentError rather than replace the bad value.
  /// The default value for the [replacementCodepoint] is U+FFFD.
  String decodeUtf16Le(
    List<int> bytes, [
    int offset = 0,
    int? length,
    bool stripBom = true,
    int replacementCodepoint = unicodeReplacementCharacterCodepoint,
  ]) {
    final List<int> codeunits = Utf16leBytesToCodeUnitsDecoder(
      bytes,
      offset,
      length,
      stripBom,
      replacementCodepoint,
    ).decodeRest();
    return String.fromCharCodes(utf16CodeUnitsToCodepoints(codeunits, 0, null, replacementCodepoint).whereType<int>());
  }
}

/// instance of utf16 codec
const Utf16Codec utf16 = Utf16Codec();

/// Identifies whether a List of bytes starts (based on offset) with a
/// byte-order marker (BOM).
bool hasUtf16Bom(List<int> utf32EncodedBytes, [int offset = 0, int? length]) {
  return hasUtf16BeBom(utf32EncodedBytes, offset, length) || hasUtf16LeBom(utf32EncodedBytes, offset, length);
}

/// Identifies whether a List of bytes starts (based on offset) with a
/// big-endian byte-order marker (BOM).
bool hasUtf16BeBom(List<int> utf16EncodedBytes, [int offset = 0, int? length]) {
  final int end = length != null ? offset + length : utf16EncodedBytes.length;
  return (offset + 2) <= end &&
      utf16EncodedBytes[offset] == unicodeUtfBomHi &&
      utf16EncodedBytes[offset + 1] == unicodeUtfBomLo;
}

/// Identifies whether a List of bytes starts (based on offset) with a
/// little-endian byte-order marker (BOM).
bool hasUtf16LeBom(List<int> utf16EncodedBytes, [int offset = 0, int? length]) {
  final int end = length != null ? offset + length : utf16EncodedBytes.length;
  return (offset + 2) <= end &&
      utf16EncodedBytes[offset] == unicodeUtfBomLo &&
      utf16EncodedBytes[offset + 1] == unicodeUtfBomHi;
}

/// Convert UTF-16 encoded bytes to UTF-16 code units by grouping 1-2 bytes
/// to produce the code unit (0-(2^16)-1). Relies on BOM to determine
/// endian-ness, and defaults to BE.
abstract class Utf16BytesToCodeUnitsDecoder implements ListRangeIterator {
  final ListRangeIterator utf16EncodedBytesIterator;

  /// replacement of invalid character
  final int? replacementCodepoint;
  late int _current;

  /// create Utf16BytesToCodeUnitsDecoder
  factory Utf16BytesToCodeUnitsDecoder(
    List<int> utf16EncodedBytes, [
    int offset = 0,
    int? length,
    int replacementCodepoint = unicodeReplacementCharacterCodepoint,
  ]) {
    length ??= utf16EncodedBytes.length - offset;
    if (hasUtf16BeBom(utf16EncodedBytes, offset, length)) {
      return Utf16beBytesToCodeUnitsDecoder(utf16EncodedBytes, offset + 2, length - 2, false, replacementCodepoint);
    } else if (hasUtf16LeBom(utf16EncodedBytes, offset, length)) {
      return Utf16leBytesToCodeUnitsDecoder(utf16EncodedBytes, offset + 2, length - 2, false, replacementCodepoint);
    } else {
      return Utf16beBytesToCodeUnitsDecoder(utf16EncodedBytes, offset, length, false, replacementCodepoint);
    }
  }

  Utf16BytesToCodeUnitsDecoder._fromListRangeIterator(
    this.utf16EncodedBytesIterator,
    this.replacementCodepoint,
  );

  /// Provides a fast way to decode the rest of the source bytes in a single
  /// call. This method trades memory for improved speed in that it potentially
  /// over-allocates the List containing results.
  List<int> decodeRest() {
    final List<int> codeunits = List<int>.filled(remaining, 0);
    int i = 0;
    while (moveNext()) {
      codeunits[i++] = current;
    }
    if (i == codeunits.length) {
      return codeunits;
    } else {
      return codeunits.sublist(0, i);
    }
  }

  @override
  int get current => _current;

  @override
  bool moveNext() {
    final int remaining = utf16EncodedBytesIterator.remaining;
    if (remaining == 0) {
      return false;
    }
    if (remaining == 1) {
      utf16EncodedBytesIterator.moveNext();
      if (replacementCodepoint != null) {
        _current = replacementCodepoint!;
        return true;
      } else {
        throw ArgumentError(
          'Invalid UTF16 at ${utf16EncodedBytesIterator.position}',
        );
      }
    }
    _current = decode();
    return true;
  }

  @override
  int get position => utf16EncodedBytesIterator.position ~/ 2;

  @override
  void backup([int by = 1]) {
    utf16EncodedBytesIterator.backup(2 * by);
  }

  @override
  int get remaining => (utf16EncodedBytesIterator.remaining + 1) ~/ 2;

  @override
  void skip([int count = 1]) {
    utf16EncodedBytesIterator.skip(2 * count);
  }

  /// decode current character
  int decode();
}

/// Convert UTF-16BE encoded bytes to utf16 code units by grouping 1-2 bytes
/// to produce the code unit (0-(2^16)-1).
class Utf16beBytesToCodeUnitsDecoder extends Utf16BytesToCodeUnitsDecoder {
  ///Utf16beBytesToCodeUnitsDecoder
  Utf16beBytesToCodeUnitsDecoder(
    List<int> utf16EncodedBytes, [
    int offset = 0,
    int? length,
    bool stripBom = true,
    int replacementCodepoint = unicodeReplacementCharacterCodepoint,
  ]) : super._fromListRangeIterator(ListRange(utf16EncodedBytes, offset, length).iterator, replacementCodepoint) {
    if (stripBom && hasUtf16BeBom(utf16EncodedBytes, offset, length)) {
      skip();
    }
  }

  @override
  int decode() {
    utf16EncodedBytesIterator.moveNext();
    final int hi = utf16EncodedBytesIterator.current;
    utf16EncodedBytesIterator.moveNext();
    final int lo = utf16EncodedBytesIterator.current;
    return (hi << 8) + lo;
  }
}

/// Convert UTF-16LE encoded bytes to utf16 code units by grouping 1-2 bytes
/// to produce the code unit (0-(2^16)-1).
class Utf16leBytesToCodeUnitsDecoder extends Utf16BytesToCodeUnitsDecoder {
  /// Utf16beBytesToCodeUnitsDecoder
  Utf16leBytesToCodeUnitsDecoder(
    List<int> utf16EncodedBytes, [
    int offset = 0,
    int? length,
    bool stripBom = true,
    int replacementCodepoint = unicodeReplacementCharacterCodepoint,
  ]) : super._fromListRangeIterator(ListRange(utf16EncodedBytes, offset, length).iterator, replacementCodepoint) {
    if (stripBom && hasUtf16LeBom(utf16EncodedBytes, offset, length)) {
      skip();
    }
  }

  @override
  int decode() {
    utf16EncodedBytesIterator.moveNext();
    final int lo = utf16EncodedBytesIterator.current;
    utf16EncodedBytesIterator.moveNext();
    final int hi = utf16EncodedBytesIterator.current;
    return (hi << 8) + lo;
  }
}

/// An `Iterator<int>` of codepoints built on an Iterator of UTF-16 code units.
/// The parameters can override the default Unicode replacement character. Set
/// the replacementCharacter to null to throw an ArgumentError
/// rather than replace the bad value.
class Utf16CodeUnitDecoder implements Iterator<int> {
  final ListRangeIterator utf16CodeUnitIterator;

  /// replacement of invalid charactor
  final int? replacementCodepoint;
  int _current = 0;

  /// Utf16CodeUnitDecoder
  Utf16CodeUnitDecoder(
    Iterable<int> utf16CodeUnits, [
    int offset = 0,
    int? length,
    this.replacementCodepoint = unicodeReplacementCharacterCodepoint,
  ]) : utf16CodeUnitIterator = ListRange(
         utf16CodeUnits,
         offset,
         length,
       ).iterator;

  /// Utf16CodeUnitDecoder from [RangeIterator]
  Utf16CodeUnitDecoder.fromListRangeIterator(
    this.utf16CodeUnitIterator,
    this.replacementCodepoint,
  );

  /// iterator of this
  Iterator<int> get iterator => this;

  @override
  int get current => _current;

  @override
  bool moveNext() {
    if (!utf16CodeUnitIterator.moveNext()) return false;

    int value = utf16CodeUnitIterator.current;
    if (value < 0) {
      if (replacementCodepoint != null) {
        _current = replacementCodepoint!;
      } else {
        throw ArgumentError('Invalid UTF16 at ${utf16CodeUnitIterator.position}');
      }
    } else if (value < unicodeUtf16ReservedLo || (value > unicodeUtf16ReservedHi && value <= unicodePlaneOneMax)) {
      // transfer directly
      _current = value;
    } else if (value < unicodeUtf16SurrogateUnit1Base && utf16CodeUnitIterator.moveNext()) {
      // merge surrogate pair
      final int nextValue = utf16CodeUnitIterator.current;
      if (nextValue >= unicodeUtf16SurrogateUnit1Base && nextValue <= unicodeUtf16ReservedHi) {
        value = (value - unicodeUtf16SurrogateUnit0Base) << 10;
        value += unicodeUtf16Offset + (nextValue - unicodeUtf16SurrogateUnit1Base);
        _current = value;
      } else {
        if (nextValue >= unicodeUtf16SurrogateUnit0Base && nextValue < unicodeUtf16SurrogateUnit1Base) {
          utf16CodeUnitIterator.backup();
        }
        if (replacementCodepoint != null) {
          _current = replacementCodepoint!;
        } else {
          throw ArgumentError(
            'Invalid UTF16 at ${utf16CodeUnitIterator.position}',
          );
        }
      }
    } else if (replacementCodepoint != null) {
      _current = replacementCodepoint!;
    } else {
      throw ArgumentError('Invalid UTF16 at ${utf16CodeUnitIterator.position}');
    }
    return true;
  }
}

/// _ListRange in an internal type used to create a lightweight Interable on a
/// range within a source list. DO NOT MODIFY the underlying list while
/// iterating over it. The results of doing so are undefined.
class ListRange extends IterableBase<int> {
  final Iterable<int> _source;
  final int _offset;
  final int _length;

  /// ListRange
  ListRange(Iterable<int> source, [int offset = 0, int? length])
    : _source = source,
      _offset = offset,
      _length = length ?? source.length - offset {
    if (_offset < 0 || _offset > _source.length) {
      throw RangeError.value(_offset);
    }
    if (_length < 0) {
      throw RangeError.value(_length);
    }
    if (_length + _offset > _source.length) {
      throw RangeError.value(_length + _offset);
    }
  }

  @override
  ListRangeIterator get iterator => _ListRangeIteratorImpl(
    _source is List ? _source as List<int> : _source.toList(),
    _offset,
    _offset + _length,
  );

  @override
  int get length => _length;
}

/// The ListRangeIterator provides more capabilities than a standard iterator,
/// including the ability to get the current position, count remaining items,
/// and move forward/backward within the iterator.
abstract class ListRangeIterator implements Iterator<int> {
  @override
  bool moveNext();

  @override
  int get current;

  /// cuttent position
  int get position;

  /// backup
  void backup([int by]);

  /// remaining of the iterator
  int get remaining;

  /// skip count
  void skip([int count]);
}

class _ListRangeIteratorImpl implements ListRangeIterator {
  final List<int> _source;
  int _offset;
  final int _end;

  _ListRangeIteratorImpl(this._source, int offset, this._end) : _offset = offset - 1;

  @override
  int get current => _source[_offset];

  @override
  bool moveNext() => ++_offset < _end;

  @override
  int get position => _offset;

  @override
  void backup([int by = 1]) {
    _offset -= by;
  }

  @override
  int get remaining => _end - _offset - 1;

  @override
  void skip([int count = 1]) {
    _offset += count;
  }
}

/// Provide a list of Unicode codepoints for a given string.
List<int> stringToCodepoints(String str) {
  // Note: str.codeUnits gives us 16-bit code units on all Dart implementations.
  // So we need to convert.
  return utf16CodeUnitsToCodepoints(str.codeUnits);
}

/// Decodes the utf16 codeunits to codepoints.
List<int> utf16CodeUnitsToCodepoints(
  List<int> utf16CodeUnits, [
  int offset = 0,
  int? length,
  int replacementCodepoint = unicodeReplacementCharacterCodepoint,
]) {
  final ListRangeIterator source = ListRange(utf16CodeUnits, offset, length).iterator;
  final Utf16CodeUnitDecoder decoder = Utf16CodeUnitDecoder.fromListRangeIterator(
    source,
    replacementCodepoint,
  );

  final List<int> lists = List<int>.filled(source.remaining, 0);
  int index = 0;
  while (decoder.moveNext()) {
    lists[index++] = decoder.current;
  }
  return lists.sublist(0, index);
}

/// Encode code points as UTF16 code units.
List<int> codepointsToUtf16CodeUnits(
  List<int> codepoints, [
  int offset = 0,
  int? length,
  int? replacementCodepoint = unicodeReplacementCharacterCodepoint,
]) {
  final int encodedLength = codepoints.fold<int>(0, (int previousValue, int value) {
    if ((value >= 0 && value < unicodeUtf16ReservedLo) ||
        (value > unicodeUtf16ReservedHi && value <= unicodePlaneOneMax)) {
      return previousValue + 1;
    } else if (value > unicodePlaneOneMax && value <= unicodeValidRangeMax) {
      return previousValue + 2;
    }
    return previousValue + 1;
  });

  final Iterator<int> listRange = codepoints.iterator;

  int? last;
  return List<int>.generate(encodedLength, (int index) {
    if (last != null) {
      final int lastValue = unicodeUtf16SurrogateUnit1Base + (last! & unicodeUtf16LoMask);
      last = null;
      return lastValue;
    }
    if (listRange.moveNext()) {
      final int value = listRange.current;
      if ((value >= 0 && value < unicodeUtf16ReservedLo) ||
          (value > unicodeUtf16ReservedHi && value <= unicodePlaneOneMax)) {
        return value;
      } else if (value > unicodePlaneOneMax && value <= unicodeValidRangeMax) {
        last = value - unicodeUtf16Offset;
        return unicodeUtf16SurrogateUnit0Base + ((last! & unicodeUtf16HiMask) >> 10);
      } else if (replacementCodepoint != null) {
        return replacementCodepoint;
      } else {
        throw ArgumentError('Invalid encoding');
      }
    }
    return 0;
  });
}
