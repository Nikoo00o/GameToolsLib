import 'package:collection/collection.dart';
import 'package:game_tools_lib/data/native/native_image.dart';

/// Contains the different types of pixel channel configurations for a [NativeImage].
/// You can only detect the type of default channels with [NativeImageType.fromChannels] and the additional special
/// types will just get converted to them.
/// Look at the comments at 1=[GRAY], 3=[RGB] and 4=[RGBA] to see how and when they should be used!
enum NativeImageType {
  /// Data is currently null, only used in error cases.
  NONE,

  /// 1 Channel, can't really be converted back to [RGB]. Internally pixels are stored as only one grayscale value.
  /// This has the best performance for comparing images, but of course you would loose the color info forever.
  /// (This would also be the type for an empty opencv mat)
  GRAY,

  /// Only used so that the different types have the same value as the channels they represent!
  _SKIP_2,

  /// 3 Channels, looses transparency value. Remember internally the pixel are stored as BGR instead!
  /// Better comparison performance than [RGBA], but still retains the color values!
  /// A good mix, because alpha is mostly not needed here!
  RGB,

  /// Default with 4 Channels, stores the most information. Remember internally the pixel are stored as BGRA instead!
  /// This has the best performance of getting native images (from screen/window), because no internal copies will be
  /// made in the related [NativeImage.nativeAsync] constructor (loaded native images always have an alpha channel)!
  RGBA,

  /// Only used so that the different types have the same value as the channels they represent!
  _SKIP_5,

  /// Special type that will not be automatically detected from [NativeImageType.fromChannels] and instead [RGB] will
  /// be returned, because it has the same amount of channels! This can also only be converted from and to [RGB]
  HSV;

  @override
  String toString() {
    return name;
  }

  /// Returns the amount of channels this has. this returns the channels directly of the default types (and the
  /// special types will return the same amount of channels as the matching default type)
  int get channels {
    if (index >= _SKIP_5.index) {
      return switch (this) {
        HSV => RGB.index,
        _ => NONE.index,
      };
    }
    return index;
  }

  /// Returns matching the default type, or [NONE] if [channels] is null, or invalid!
  /// Special types cannot be recognized and will be converted to default types like [HSV] to [RGB].
  factory NativeImageType.fromChannels(int? channels) {
    final NativeImageType img = values.firstWhereOrNull((NativeImageType element) => element.index == channels) ?? NONE;
    return (img != _SKIP_2 && img != _SKIP_5) ? img : NONE;
  }

  factory NativeImageType.fromString(String data) {
    return values.firstWhere((NativeImageType element) => element.name == data);
  }
}
