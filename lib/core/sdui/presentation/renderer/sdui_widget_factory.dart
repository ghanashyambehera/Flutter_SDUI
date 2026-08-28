import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_node.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_screen.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_action_runner.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_condition_evaluator.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_controller.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_string_resolver.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_token_resolver.dart';

class SduiBuildContext {
  SduiBuildContext({
    required this.context,
    required this.screen,
    required this.controller,
    required this.runner,
  });

  final BuildContext context;
  final SduiScreen screen;
  final SduiController controller;
  final SduiActionRunner runner;
}

class SduiWidgetFactory {
  SduiWidgetFactory();

  final _conditions = SduiConditionEvaluator();
  final _strings = SduiStringResolver();

  Widget build(SduiNode node, SduiBuildContext ctx) {
    if (!_conditions.eval(node.visibleWhen, ctx.controller)) {
      return const SizedBox.shrink();
    }
    return switch (node.type) {
      'scaffold' => _scaffold(node, ctx),
      'appBar' => const SizedBox.shrink(),
      'scroll' => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _children(node, ctx),
          ),
        ),
      'column' => _column(node, ctx),
      'row' => _row(node, ctx),
      'text' => _text(node, ctx),
      'image' => _image(node),
      'textField' => _textField(node, ctx),
      'otpField' => _otpField(node, ctx),
      'button' => _button(node, ctx),
      'textButton' => _textButton(node, ctx),
      'checkbox' => _checkbox(node, ctx),
      'banner' => _banner(node, ctx),
      'spacer' => SizedBox(
          height: SduiTokenResolver.spacing(node.props['height']),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  List<Widget> _children(SduiNode node, SduiBuildContext ctx) =>
      node.children.map((c) => build(c, ctx)).toList();

  Widget _scaffold(SduiNode node, SduiBuildContext ctx) {
    PreferredSizeWidget? bar;
    final bodyChildren = <Widget>[];
    for (final child in node.children) {
      if (child.type == 'appBar') {
        bar = _appBar(child, ctx);
      } else {
        bodyChildren.add(build(child, ctx));
      }
    }
    return Scaffold(
      backgroundColor: SduiTokenResolver.color(
        node.props['backgroundColor'] as String? ??
            ctx.screen.theme['backgroundColor'] as String?,
      ),
      appBar: bar,
      body: SafeArea(
        child: bodyChildren.length == 1
            ? bodyChildren.first
            : Column(
                children: bodyChildren.map((w) => Expanded(child: w)).toList(),
              ),
      ),
    );
  }

  PreferredSizeWidget _appBar(SduiNode node, SduiBuildContext ctx) {
    final showBack = node.props['showBack'] == true;
    return AppBar(
      title: Text('${node.props['title'] ?? ''}'),
      automaticallyImplyLeading: showBack,
    );
  }

  Widget _column(SduiNode node, SduiBuildContext ctx) {
    final gap = SduiTokenResolver.spacing(node.props['gap']);
    final pad = SduiTokenResolver.padding(node.props['padding']);
    final kids = _children(node, ctx);
    final spaced = <Widget>[];
    for (var i = 0; i < kids.length; i++) {
      spaced.add(kids[i]);
      if (i != kids.length - 1 && gap > 0) {
        spaced.add(SizedBox(height: gap));
      }
    }
    return Padding(
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: spaced,
      ),
    );
  }

  Widget _row(SduiNode node, SduiBuildContext ctx) {
    final gap = SduiTokenResolver.spacing(node.props['gap']);
    final kids = _children(node, ctx);
    final spaced = <Widget>[];
    for (var i = 0; i < kids.length; i++) {
      spaced.add(kids[i]);
      if (i != kids.length - 1 && gap > 0) {
        spaced.add(SizedBox(width: gap));
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: spaced,
    );
  }

  Widget _text(SduiNode node, SduiBuildContext ctx) {
    final raw = '${node.props['value'] ?? ''}';
    final text = _strings.resolve(raw, ctx.controller);
    final align = node.props['alignment'] == 'center'
        ? TextAlign.center
        : TextAlign.start;
    return Text(
      text,
      textAlign: align,
      style: SduiTokenResolver.textStyle(
        node.props['style'] as String?,
        ctx.context,
      ),
    );
  }

  Widget _image(SduiNode node) {
    return Icon(
      Icons.lock_outline,
      size: (node.props['height'] as num?)?.toDouble() ?? 56,
      color: SduiTokenResolver.primary,
    );
  }

  Widget _textField(SduiNode node, SduiBuildContext ctx) {
    final bind = node.bind ?? node.id;
    final obscure = node.props['obscure'] == true;
    final error = ctx.controller.errors[bind];
    return TextField(
      controller: ctx.controller.textController(bind),
      obscureText: obscure,
      keyboardType: _keyboard(node.props['keyboard'] as String?),
      textInputAction: _inputAction(node.props['textInputAction'] as String?),
      autofillHints: _autofill(node.props['autofill'] as String?),
      decoration: InputDecoration(
        labelText: node.props['label'] as String?,
        hintText: node.props['placeholder'] as String?,
        errorText: error,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (v) {
        ctx.controller.setValue(bind, v);
        ctx.runner.onChanged();
      },
      onSubmitted: (_) {
        final action = node.actions['onSubmitted'];
        if (action != null) {
          ctx.runner.dispatch(ctx.context, action);
        }
      },
    );
  }

  Widget _otpField(SduiNode node, SduiBuildContext ctx) {
    final bind = node.bind ?? 'otp';
    final length = node.props['length'] as int? ?? 6;
    final error = ctx.controller.errors[bind];
    return TextField(
      controller: ctx.controller.textController(bind),
      keyboardType: TextInputType.number,
      maxLength: length,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: const TextStyle(letterSpacing: 8, fontSize: 24),
      decoration: InputDecoration(
        counterText: '',
        errorText: error,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (v) {
        ctx.controller.setValue(bind, v);
        ctx.runner.onChanged();
        if (v.length == length) {
          final action = node.actions['onCompleted'];
          if (action != null) {
            ctx.runner.dispatch(ctx.context, action);
          }
        }
      },
    );
  }

  Widget _button(SduiNode node, SduiBuildContext ctx) {
    final loading = node.props['loadingWhen'] == 'submitting' &&
        ctx.controller.submitting;
    return SizedBox(
      width: node.props['fullWidth'] == true ? double.infinity : null,
      height: 48,
      child: FilledButton(
        onPressed: loading
            ? null
            : () {
                final action = node.actions['onTap'];
                if (action != null) {
                  ctx.runner.dispatch(ctx.context, action);
                }
              },
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text('${node.props['label'] ?? ''}'),
      ),
    );
  }

  Widget _textButton(SduiNode node, SduiBuildContext ctx) {
    final alignment = node.props['alignment'];
    final button = TextButton(
      onPressed: () {
        final action = node.actions['onTap'];
        if (action?.screenId == 'forgot_password') {
          ScaffoldMessenger.of(ctx.context).showSnackBar(
            const SnackBar(content: Text('Forgot password is not in this demo')),
          );
          return;
        }
        if (action != null) {
          ctx.runner.dispatch(ctx.context, action);
        }
      },
      child: Text('${node.props['label'] ?? ''}'),
    );
    if (alignment == 'end') {
      return Align(alignment: Alignment.centerRight, child: button);
    }
    if (alignment == 'center') {
      return Center(child: button);
    }
    return button;
  }

  Widget _checkbox(SduiNode node, SduiBuildContext ctx) {
    final bind = node.bind ?? node.id;
    final checked = ctx.controller.value(bind) == true;
    final error = ctx.controller.errors[bind];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: checked,
          onChanged: (v) {
            ctx.controller.setValue(bind, v ?? false);
            ctx.runner.onChanged();
          },
          title: Text('${node.props['label'] ?? ''}'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _banner(SduiNode node, SduiBuildContext ctx) {
    final from = node.props['messageFrom'] as String?;
    var message = '${node.props['message'] ?? ''}';
    if (from != null) {
      message = _strings.resolve('{{$from}}', ctx.controller);
    }
    if (message.isEmpty) return const SizedBox.shrink();
    return Material(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message, style: TextStyle(color: Colors.red.shade800)),
      ),
    );
  }

  TextInputType _keyboard(String? name) {
    return switch (name) {
      'email' => TextInputType.emailAddress,
      'number' => TextInputType.number,
      'name' => TextInputType.name,
      _ => TextInputType.text,
    };
  }

  TextInputAction _inputAction(String? name) {
    return switch (name) {
      'next' => TextInputAction.next,
      'done' => TextInputAction.done,
      _ => TextInputAction.done,
    };
  }

  Iterable<String>? _autofill(String? name) {
    return switch (name) {
      'email' => const [AutofillHints.email],
      'password' => const [AutofillHints.password],
      'newPassword' => const [AutofillHints.newPassword],
      'name' => const [AutofillHints.name],
      'oneTimeCode' => const [AutofillHints.oneTimeCode],
      _ => null,
    };
  }
}
