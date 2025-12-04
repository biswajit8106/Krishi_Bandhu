import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class TranslationText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const TranslationText(this.text, {Key? key, this.style, this.textAlign}) : super(key: key);

  @override
  State<TranslationText> createState() => _TranslationTextState();
}

class _TranslationTextState extends State<TranslationText> {
  String _display = '';
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      _translate();
    };
    TranslationService.instance.languageCode.addListener(_listener);
    _translate();
  }

  @override
  void dispose() {
    TranslationService.instance.languageCode.removeListener(_listener);
    super.dispose();
  }

  Future<void> _translate() async {
    final translated = await TranslationService.instance.translate(widget.text);
    if (mounted) {
      setState(() {
        _display = translated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_display.isEmpty) {
      // show original while loading
      return Text(widget.text, style: widget.style, textAlign: widget.textAlign);
    }
    return Text(_display, style: widget.style, textAlign: widget.textAlign);
  }
}
