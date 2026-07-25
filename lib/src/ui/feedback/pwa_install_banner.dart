import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/flip10_colors.dart';
import 'pwa_install_stub.dart'
    if (dart.library.js_interop) 'pwa_install_web.dart';

/// Shows a small banner inviting the user to install the PWA. Web-only.
class PwaInstallBanner extends StatefulWidget {
  const PwaInstallBanner({super.key});

  @override
  State<PwaInstallBanner> createState() => _PwaInstallBannerState();
}

class _PwaInstallBannerState extends State<PwaInstallBanner> {
  bool _dismissed = true;
  bool _installed = false;
  bool _iOS = false;
  bool _promptReady = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      return;
    }
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final installed = PwaInstallSupport.isInstalled() ||
        await _wasPreviouslyInstalled();
    if (installed && mounted) {
      setState(() => _installed = true);
      return;
    }
    final dismissed = await PwaInstallSupport.wasDismissed();
    if (!mounted) {
      return;
    }
    setState(() {
      _dismissed = dismissed;
      _installed = false;
      _iOS = PwaInstallSupport.isIOS();
    });
    PwaInstallSupport.attachListeners(
      onPromptReady: () {
        if (mounted) {
          setState(() => _promptReady = true);
        }
      },
      onInstalled: () async {
        if (mounted) {
          setState(() {
            _installed = true;
            _dismissed = true;
          });
        }
      },
    );
  }

  Future<bool> _wasPreviouslyInstalled() async {
    return PwaInstallSupport.wasDismissed().then(
      (_) => false,
    );
  }

  Future<void> _dismiss() async {
    await PwaInstallSupport.markDismissed();
    if (mounted) {
      setState(() => _dismissed = true);
    }
  }

  Future<void> _install() async {
    final result = await PwaInstallSupport.promptInstall();
    await _dismiss();
    if (result == true && mounted) {
      setState(() => _installed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }
    if (_dismissed || _installed) {
      return const SizedBox.shrink();
    }
    if (!_promptReady && !_iOS) {
      return const SizedBox.shrink();
    }

    final isNarrow = MediaQuery.of(context).size.width < 520;
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.only(
          top: isNarrow ? 8 : 12,
          right: isNarrow ? 8 : 12,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Material(
            color: Flip10Colors.panel,
            elevation: 6,
            shadowColor: Colors.black,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.install_mobile_rounded,
                    color: Flip10Colors.brass,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Install Flip10',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: Flip10Colors.ivory,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Text(
                          _iOS
                              ? 'Tap Share, then Add to Home Screen.'
                              : 'Add to your home screen for offline play.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    Flip10Colors.ivory.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (_promptReady)
                    TextButton(
                      onPressed: _install,
                      child: const Text('Install'),
                    ),
                  IconButton(
                    tooltip: 'Dismiss',
                    onPressed: _dismiss,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
