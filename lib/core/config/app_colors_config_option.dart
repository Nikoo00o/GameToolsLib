import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/gt_contrast.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/presentation/base/gt_app_theme.dart';
import 'package:game_tools_lib/presentation/base/gt_app_theme_extension.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_types.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_color_picker.dart';

/// This is an example on how to use the [CustomConfigOption] here with the [GTAppTheme] as a new class.
///
/// It also builds the ui to configure the data! And static callbacks are used for all available parameters.
final class AppColorsConfigOption extends CustomConfigOption<GTAppTheme> {
  /// The [defaultValue] is the only option that can use the [GTAppTheme.seed] constructor
  AppColorsConfigOption({
    super.defaultValue,
  }) : super(
         createNewInstance: _createNewInstance,
         convertInstanceToString: _convertInstanceToString,
         buildCustomContentWidget: _buildCustomContentWidget,
         containsSearchCallback: _containsSearchCallback,
         lazyLoaded: false,
         onInit: null,
         updateCallback: null,
         title: const TS("config.appColors"),
         description: const TS("config.appColors.description"),
       );

  static GTAppTheme? _createNewInstance(String? str) => str != null ? GTAppTheme.fromString(str) : null;

  static String? _convertInstanceToString(GTAppTheme? data) => data?.toString();

  static bool _containsSearchCallback(
    BuildContext context,
    ConfigOptionBuilderCustom<GTAppTheme> builder,
    String upperCaseSearchString,
  ) {
    if (builder.translate(builder.configOption.title, context).toUpperCase().contains(upperCaseSearchString)) {
      return true;
    } else if (builder
        .translate(const TS("config.appColors.contrast"), context)
        .toUpperCase()
        .contains(upperCaseSearchString)) {
      return true;
    }
    return "THEME".contains(upperCaseSearchString);
  }

  static Widget _buildCustomContentWidget(
    BuildContext context,
    GTAppTheme data,
    ConfigOptionBuilderCustom<GTAppTheme> builder, {
    required bool calledFromInnerGroup,
  }) {
    return ListView(
      children: <Widget>[
        builder.buildEnumSliderOption<GTContrast>(
          title: const TS("config.appColors.contrast"),
          availableOptions: GTContrast.values,
          initialValue: data.contrast,
          onValueChange: (GTContrast newContrast) => _option.setValue(_value.copyWith(newContrast: newContrast)),
          convertToTranslationKeys: (GTContrast contrast) => TS(switch (contrast) {
            GTContrast.DEFAULT => "input.default",
            GTContrast.MEDIUM => "input.medium",
            GTContrast.HIGH => "input.high",
          }),
        ),
        const SizedBox(height: 5),
        _buildInfo(context, builder),
        const SizedBox(height: 5),
        _buildColorOptions(context, builder),
        const SizedBox(height: 5),
        _buildShowcase(context, data, builder),
      ],
    );
  }

  static Widget _buildInfo(BuildContext context, ConfigOptionBuilderCustom<GTAppTheme> builder) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(builder.translate(const TS("config.appColors.info"), context)),
            FilledButton(
              onPressed: () => _option.deleteValue(),
              child: Text(builder.translate(const TS("input.reset.to.default"), context)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildColorOptions(BuildContext context, ConfigOptionBuilderCustom<GTAppTheme> builder) {
    final List<Color> additionalColors = List<Color>.of(_value.baseAdditionalColors);
    final List<Widget> additionalColorWidgets = <Widget>[];
    for (int i = 0; i < additionalColors.length; ++i) {
      additionalColorWidgets.add(
        SimpleColorPicker(
          colorToShow: additionalColors.elementAt(i),
          colorName: "Additional Color${i + 1}",
          onColorChange: (Color newColor) {
            additionalColors[i] = newColor;
            _option.setValue(_value.copyWith(baseAdditionalColors: additionalColors));
          },
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          spacing: 10.0,
          runSpacing: 10.0,
          children: <Widget>[
            SimpleColorPicker(
              colorToShow: _value.basePrimaryColor,
              colorName: "Primary Color",
              onColorChange: (Color newColor) => _option.setValue(_value.copyWith(basePrimaryColor: newColor)),
            ),
            SimpleColorPicker(
              colorToShow: _value.baseSecondaryColor ?? Colors.white,
              colorName: "Secondary Color",
              onColorChange: (Color newColor) => _option.setValue(_value.copyWith(baseSecondaryColor: newColor)),
            ),
            SimpleColorPicker(
              colorToShow: _value.baseTertiaryColor ?? Colors.white,
              colorName: "Tertiary Color",
              onColorChange: (Color newColor) => _option.setValue(_value.copyWith(baseTertiaryColor: newColor)),
            ),
            SimpleColorPicker(
              colorToShow: _value.baseNeutralColor ?? Colors.white,
              colorName: "Neutral Color",
              onColorChange: (Color newColor) => _option.setValue(_value.copyWith(baseNeutralColor: newColor)),
            ),
            SimpleColorPicker(
              colorToShow: _value.baseErrorColor ?? Colors.white,
              colorName: "Error Color",
              onColorChange: (Color newColor) => _option.setValue(_value.copyWith(baseErrorColor: newColor)),
            ),
            SimpleColorPicker(
              colorToShow: _value.baseSuccessColor,
              colorName: "Success Color",
              onColorChange: (Color newColor) => _option.setValue(_value.copyWith(baseSuccessColor: newColor)),
            ),
            ...additionalColorWidgets,
          ],
        ),
      ),
    );
  }

  static Widget _buildShowcase(BuildContext context, GTAppTheme data, ConfigOptionBuilderCustom<GTAppTheme> builder) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _themeContent(context, data, builder, isDark: true),
            _themeContent(context, data, builder, isDark: false),
          ],
        ),
      ),
    );
  }

  static Widget _themeContent(
    BuildContext context,
    GTAppTheme data,
    ConfigOptionBuilderCustom<GTAppTheme> builder, {
    required bool isDark,
  }) {
    return Theme(
      data: data.getTheme(darkTheme: isDark),
      child: Builder(
        builder: (BuildContext context) => Container(
          padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(12.0),
            ),
            color: builder.colorScaffoldBackground(context),
          ),
          child: Column(
            children: _groupedButtons(context, builder),
          ),
        ),
      ),
    );
  }

  static List<Widget> _groupedButtons(BuildContext context, ConfigOptionBuilderCustom<GTAppTheme> builder) {
    return <Widget>[
      Row(
        children: <Widget>[
          _button(
            "Primary(filled)",
            builder.colorPrimary(context),
            builder.colorOnPrimary(context),
          ),
          _button("Container", builder.colorPrimaryContainer(context), builder.colorOnPrimaryContainer(context)),
          _button("Fixed", builder.colorPrimaryFixed(context), builder.colorOnPrimaryFixed(context)),
          _button("FixedDim", builder.colorPrimaryFixedDim(context), builder.colorOnPrimaryFixedVariant(context)),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: <Widget>[
          _button(
            "Secondary",
            builder.colorSecondary(context),
            builder.colorOnSecondary(context),
          ),
          _button(
            "Container(tonal)",
            builder.colorSecondaryContainer(context),
            builder.colorOnSecondaryContainer(context),
          ),
          _button("Fixed", builder.colorSecondaryFixed(context), builder.colorOnSecondaryFixed(context)),
          _button("FixedDim", builder.colorSecondaryFixedDim(context), builder.colorOnSecondaryFixedVariant(context)),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: <Widget>[
          _button(
            "Tertiary ${builder.isDarkTheme(context) ? "dark" : "light"}",
            builder.colorTertiary(context),
            builder.colorOnTertiary(context),
          ),
          _button("Container", builder.colorTertiaryContainer(context), builder.colorOnTertiaryContainer(context)),
          _button("Fixed", builder.colorTertiaryFixed(context), builder.colorOnTertiaryFixed(context)),
          _button("FixedDim", builder.colorTertiaryFixedDim(context), builder.colorOnTertiaryFixedVariant(context)),
        ],
      ),
      const SizedBox(height: 4),
      _surfaceGroup(context, builder),
      const SizedBox(height: 4),
      Row(
        children: <Widget>[
          _button("Error", builder.colorError(context), builder.colorOnError(context)),
          _button("Container", builder.colorErrorContainer(context), builder.colorOnErrorContainer(context)),
          _button("Shadow", builder.colorShadow(context), Colors.white),
          _button("Disable1", builder.colorDisabled(context), builder.colorDisabled(context)),
          const FilledButton(onPressed: null, child: Text("Disable2")),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: <Widget>[
          _button("Success", builder.colorSuccess(context), builder.colorOnSuccess(context)),
          _button("Container", builder.colorSuccessContainer(context), builder.colorOnSuccessContainer(context)),
          _button("Fixed", builder.colorSuccessFixed(context), builder.colorOnSuccessFixed(context)),
          _button("FixedDim", builder.colorSuccessFixedDim(context), builder.colorOnSuccessFixedVariant(context)),
        ],
      ),
      const SizedBox(height: 8),
      ..._additionalColorsGroup(context, builder),
    ];
  }

  static Widget _surfaceGroup(BuildContext context, ConfigOptionBuilderCustom<GTAppTheme> builder) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(12.0),
        ),
        color: builder.colorPrimary(context),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              _sButton("Surface", builder.colorSurface(context), builder.colorOnSurface(context)),
              _sButton("Variant", builder.colorSurfaceVariant(context), builder.colorOnSurfaceVariant(context)),
              _sButton("Outline", builder.colorOutline(context), builder.colorOnSurface(context)),
              _sButton("Outline Variant", builder.colorOutlineVariant(context), builder.colorOnSurface(context)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              _sButton("Lowest", builder.colorSurfaceContainerLowest(context), builder.colorOnSurface(context)),
              _sButton("Low", builder.colorSurfaceContainerLow(context), builder.colorOnSurface(context)),
              _sButton("Surface Container", builder.colorSurfaceContainer(context), builder.colorOnSurface(context)),
              _sButton("High", builder.colorSurfaceContainerHigh(context), builder.colorOnSurface(context)),
              _sButton("Highest", builder.colorSurfaceContainerHighest(context), builder.colorOnSurface(context)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              _sButton("Surface tint", builder.colorSurfaceTint(context), builder.colorOnInverseSurface(context)),
              _sButton("Dim", builder.colorSurfaceDim(context), builder.colorOnSurface(context)),
              _sButton("Bright", builder.colorSurfaceBright(context), builder.colorOnSurface(context)),
              _sButton("Inverse", builder.colorInverseSurface(context), builder.colorOnInverseSurface(context)),
              _sButton("Inverse Prim", builder.colorInversePrimary(context), builder.colorOnSurface(context)),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static List<Widget> _additionalColorsGroup(BuildContext context, ConfigOptionBuilderCustom<GTAppTheme> builder) {
    final List<Widget> widgets = <Widget>[];
    final int amount = builder.colorAdditionalAmount(context);
    for (int i = 0; i < amount; ++i) {
      final ColorGroup colors = builder.colorAdditional(context, i);
      widgets.add(
        Row(
          children: <Widget>[
            _button("Additional${i + 1}", colors.normal, colors.onNormal),
            _button("Container", colors.container, colors.onContainer),
            _button("Fixed", colors.fixed, colors.onFixed),
            _button("FixedDim", colors.fixedDim, colors.onFixedVariant),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 8));
    }
    return widgets;
  }

  static Widget _sButton(String text, Color backgroundColor, Color foregroundColor) =>
      _button(text, backgroundColor, foregroundColor, surface: true);

  static Widget _button(String text, Color backgroundColor, Color foregroundColor, {bool surface = false}) => Padding(
    padding: EdgeInsetsGeometry.symmetric(horizontal: surface ? 0 : 5),
    child: FilledButton(
      onPressed: () {},
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(surface ? 0 : 20),
          //borderRadius: BorderRadius.zero, //Rectangular border
        ),
      ),
      child: Text(text),
    ),
  );

  static AppColorsConfigOption get _option => MutableConfig.mutableConfig.appColors;

  static GTAppTheme get _value => _option.cachedValueNotNull();
}
