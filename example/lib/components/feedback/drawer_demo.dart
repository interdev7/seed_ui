// Material also exports a `Drawer`; hide it so the kit's getter wins.
import 'package:flutter/material.dart' hide Drawer;
import 'package:seed_ui/seed_ui.dart';

class DrawerDemo extends StatelessWidget {
  const DrawerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final placement in DrawerPlacement.values)
          Button(
            onPressed: () => Drawer.open(
              DrawerConfig(
                title: 'Drawer — ${placement.name}',
                placement: placement,
                child: const Text(
                  'Panels slide in from any edge and trap focus until dismissed.',
                ),
              ),
            ),
            child: Text(placement.name),
          ),
        Button(
          onPressed: () => Drawer.open(
            const DrawerConfig(
              title: 'Drawer with Custom Barrier',
              barrierColor: Color(0x991890FF), // Custom blue tint barrier
              child: Text(
                'This drawer uses a custom translucent blue barrierColor.',
              ),
            ),
          ),
          child: const Text('Custom barrierColor'),
        ),
      ],
    );
  }
}
