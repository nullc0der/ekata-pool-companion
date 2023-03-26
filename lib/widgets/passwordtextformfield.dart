import 'package:flutter/material.dart';

class PasswordTextFormField extends StatefulWidget {
  const PasswordTextFormField(
      {Key? key,
      this.controller,
      this.onSaved,
      this.validator,
      this.labelText,
      this.hintText,
      this.autovalidateMode})
      : super(key: key);

  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;

  @override
  State<PasswordTextFormField> createState() => _PasswordTextFormFieldState();
}

class _PasswordTextFormFieldState extends State<PasswordTextFormField> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: !_showPassword,
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(
          suffixIcon: GestureDetector(
            child:
                Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
            onTap: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
          ),
          border: const OutlineInputBorder(),
          labelText: widget.labelText,
          hintText: widget.hintText),
      autovalidateMode: widget.autovalidateMode,
      validator: widget.validator,
      onSaved: widget.onSaved,
    );
  }
}
