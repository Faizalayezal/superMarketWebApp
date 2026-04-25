import 'package:shivam_super_market/common_import.dart';

Widget customTextField(
  String label,
  String hint, {
  required TextEditingController controller,
  double width = 200,
  bool isDropdown = false,
  IconData? suffix,
  String? suffixText,
  VoidCallback? onTap,
  bool readOnly = false,
  var onChange,
}) {
  return SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          onChanged: onChange,
          controller: controller,
          readOnly: readOnly || isDropdown,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix != null
                ? Icon(suffix)
                : isDropdown
                ? const Icon(Icons.arrow_drop_down)
                : null,
            suffixText: suffixText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    ),
  );
}

String printDate({required String date, String? format}) {
  return DateFormat(format ?? 'dd MMM yy').format(DateTime.parse(date));
}

Radius radiusCircular([double? radius]) {
  return Radius.circular(radius ?? 12.0);
}

BorderRadius radius([double? radius]) {
  return BorderRadius.all(radiusCircular(radius ?? 12.0));
}

InputDecoration defaultInputDecoration(
  BuildContext context, {
  String? hint,
  String? label,
  TextStyle? textStyle,
  bool? isFocusTExtField = false,
  Widget? mPrefix,
}) {
  return InputDecoration(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    floatingLabelBehavior: FloatingLabelBehavior.never,
    prefixIcon: mPrefix ?? null,
    border: OutlineInputBorder(
      borderRadius: radius(),
      borderSide: BorderSide(
        color: isFocusTExtField == true
            ? context.dividerColor.withValues(alpha: 0.7)
            : context.dividerColor.withValues(alpha: 0.7),
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius(),
      borderSide: BorderSide(
        color: isFocusTExtField == true
            ? context.dividerColor.withValues(alpha: 0.7)
            : primaryColor,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: radius(),
      borderSide: BorderSide(
        color: isFocusTExtField == true
            ? context.dividerColor.withValues(alpha: 0.7)
            : context.dividerColor.withValues(alpha: 0.7),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius(),
      borderSide: BorderSide(
        color: isFocusTExtField == true
            ? context.dividerColor.withValues(alpha: 0.7)
            : primaryColor,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius(),
      borderSide: BorderSide(
        color: isFocusTExtField == true
            ? context.dividerColor.withValues(alpha: 0.7)
            : context.dividerColor.withValues(alpha: 0.7),
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius(),
      borderSide: BorderSide(
        color: isFocusTExtField == true
            ? context.dividerColor.withValues(alpha: 0.7)
            : Colors.red,
      ),
    ),
    alignLabelWithHint: true,
    // filled: true,
    isDense: true,
    labelText: label ?? "Sample Text",
    labelStyle: secondaryTextStyle(),
  );
}

TextStyle primaryTextStyle({
  int? size,
  Color? color,
  FontWeight? weight,
  String? fontFamily,
  double? letterSpacing,
  FontStyle? fontStyle,
  double? wordSpacing,
  TextDecoration? decoration,
  TextDecorationStyle? textDecorationStyle,
  TextBaseline? textBaseline,
  Color? decorationColor,
  Color? backgroundColor,
  double? height,
}) {
  return TextStyle(
    fontSize: size != null ? size.toDouble() : 16,
    color: color ?? Colors.black,
    fontWeight: weight ?? FontWeight.normal,
    fontFamily: fontFamily ?? '',
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    decoration: decoration,
    decorationStyle: textDecorationStyle,
    decorationColor: decorationColor,
    wordSpacing: wordSpacing,
    textBaseline: textBaseline,
    backgroundColor: backgroundColor,
    height: height,
  );
}

// Secondary Text Style
TextStyle secondaryTextStyle({
  int? size,
  Color? color,
  FontWeight? weight,
  String? fontFamily,
  double? letterSpacing,
  FontStyle? fontStyle,
  double? wordSpacing,
  TextDecoration? decoration,
  TextDecorationStyle? textDecorationStyle,
  TextBaseline? textBaseline,
  Color? decorationColor,
  Color? backgroundColor,
  double? height,
}) {
  return TextStyle(
    fontSize: size != null ? size.toDouble() : 14,
    color: color,
    fontWeight: weight ?? FontWeight.normal,
    fontFamily: fontFamily ?? '',
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    decoration: decoration,
    decorationStyle: textDecorationStyle,
    decorationColor: decorationColor,
    wordSpacing: wordSpacing,
    textBaseline: textBaseline,
    backgroundColor: backgroundColor,
    height: height,
  );
}

extension ContextExtensions on BuildContext {
  /// return screen size
  Size size() => MediaQuery.of(this).size;

  /// return screen width
  double width() => MediaQuery.of(this).size.width;

  /// return screen height
  double height() => MediaQuery.of(this).size.height;

  /// return screen devicePixelRatio
  double pixelRatio() => MediaQuery.of(this).devicePixelRatio;

  /// Returns dividerColor Color
  Color get dividerColor => theme.dividerColor;

  /// returns brightness
  Brightness platformBrightness() => MediaQuery.of(this).platformBrightness;

  /// Return the height of status bar
  double get statusBarHeight => MediaQuery.of(this).padding.top;

  /// Return the height of navigation bar
  double get navigationBarHeight => MediaQuery.of(this).padding.bottom;

  /// Returns Theme.of(context)
  ThemeData get theme => Theme.of(this);

  /// Returns Theme.of(context).textTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Returns DefaultTextStyle.of(context)
  DefaultTextStyle get defaultTextStyle => DefaultTextStyle.of(this);

  /// Returns Form.of(context)
  FormState? get formState => Form.of(this);

  /// Returns Scaffold.of(context)
  ScaffoldState get scaffoldState => Scaffold.of(this);

  /// Returns Overlay.of(context)
  OverlayState? get overlayState => Overlay.of(this);

  /// Returns primaryColor Color
  Color get primaryColor => theme.primaryColor;
}
