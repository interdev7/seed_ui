import 'package:flutter/widgets.dart';
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class AvatarDemo extends StatelessWidget {
  const AvatarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Group(
          'Basic',
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Avatar(size: SoftSize.large, icon: UserIcon()),
              Avatar(icon: UserIcon()),
              Avatar(size: SoftSize.small, icon: UserIcon()),
            ],
          ),
        ),
        const Group(
          'Shape',
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Avatar(
                shape: AvatarShape.square,
                size: SoftSize.large,
                icon: UserIcon(),
              ),
              Avatar(shape: AvatarShape.square, icon: UserIcon()),
              Avatar(
                shape: AvatarShape.square,
                size: SoftSize.small,
                icon: UserIcon(),
              ),
            ],
          ),
        ),
        const Group(
          'Types',
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Avatar(icon: UserIcon()),
              Avatar(child: Text('U')),
              Avatar(child: Text('USER')),
              Avatar(
                image: NetworkImage(
                  'https://zos.alipayobjects.com/rmsportal/ODTLcjxAfvqbxHnVXCYX.png',
                ),
              ),
              Avatar(
                backgroundColor: Color(0xFFFDE3CF),
                foregroundColor: Color(0xFFF56A00),
                child: Text('U'),
              ),
              Avatar(backgroundColor: Color(0xFF87D068), icon: UserIcon()),
            ],
          ),
        ),
        Group(
          'Group',
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              const AvatarGroup(
                children: [
                  Avatar(
                    image: NetworkImage(
                      'https://zos.alipayobjects.com/rmsportal/ODTLcjxAfvqbxHnVXCYX.png',
                    ),
                  ),
                  Avatar(backgroundColor: Color(0xFFF56A00), child: Text('K')),
                  Avatar(backgroundColor: Color(0xFF87D068), icon: UserIcon()),
                  Avatar(backgroundColor: Color(0xFF1677FF), icon: UserIcon()),
                ],
              ),
              const AvatarGroup(
                maxCount: 2,
                children: [
                  Avatar(
                    image: NetworkImage(
                      'https://zos.alipayobjects.com/rmsportal/ODTLcjxAfvqbxHnVXCYX.png',
                    ),
                  ),
                  Avatar(backgroundColor: Color(0xFFF56A00), child: Text('K')),
                  Avatar(backgroundColor: Color(0xFF87D068), icon: UserIcon()),
                  Avatar(backgroundColor: Color(0xFF1677FF), icon: UserIcon()),
                ],
              ),
              AvatarGroup(
                maxCount: 2,
                maxPopoverPlacement: PopoverPlacement.bottom,
                maxStyle: (count) => Avatar(
                  backgroundColor: const Color(0xFFFDE3CF),
                  foregroundColor: const Color(0xFFF56A00),
                  child: Text('+$count'),
                ),
                children: const [
                  Avatar(backgroundColor: Color(0xFF87D068), icon: UserIcon()),
                  Avatar(backgroundColor: Color(0xFF1677FF), icon: UserIcon()),
                  Avatar(backgroundColor: Color(0xFFF56A00), child: Text('K')),
                  Avatar(icon: UserIcon()),
                ],
              ),
              const AvatarGroup(
                maxCount: 2,
                showPopover: false,
                children: [
                  Avatar(child: Text('A')),
                  Avatar(child: Text('B')),
                  Avatar(child: Text('C')),
                  Avatar(child: Text('D')),
                ],
              ),
              AvatarGroup(
                maxCount: 2,
                popupRender: (context, menu) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFF0000)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: menu,
                  );
                },
                children: const [
                  Avatar(child: Text('1')),
                  Avatar(child: Text('2')),
                  Avatar(child: Text('3')),
                ],
              ),
            ],
          ),
        ),
        Group(
          'Group Shape',
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              const AvatarGroup(
                shape: AvatarShape.square,
                children: [
                  Avatar(
                    image: NetworkImage(
                      'https://zos.alipayobjects.com/rmsportal/ODTLcjxAfvqbxHnVXCYX.png',
                    ),
                  ),
                  Avatar(backgroundColor: Color(0xFFF56A00), child: Text('K')),
                  Avatar(backgroundColor: Color(0xFF87D068), icon: UserIcon()),
                  Avatar(backgroundColor: Color(0xFF1677FF), icon: UserIcon()),
                ],
              ),
              const AvatarGroup(
                shape: AvatarShape.square,
                maxCount: 2,
                children: [
                  Avatar(
                    image: NetworkImage(
                      'https://zos.alipayobjects.com/rmsportal/ODTLcjxAfvqbxHnVXCYX.png',
                    ),
                  ),
                  Avatar(backgroundColor: Color(0xFFF56A00), child: Text('K')),
                  Avatar(backgroundColor: Color(0xFF87D068), icon: UserIcon()),
                  Avatar(backgroundColor: Color(0xFF1677FF), icon: UserIcon()),
                ],
              ),
              AvatarGroup(
                maxCount: 2,
                shape: AvatarShape.square,
                maxPopoverPlacement: PopoverPlacement.bottom,
                maxStyle: (count) => Avatar(
                  backgroundColor: const Color(0xFFFDE3CF),
                  foregroundColor: const Color(0xFFF56A00),
                  child: Text('+$count'),
                ),
                children: const [
                  Avatar(backgroundColor: Color(0xFF87D068), icon: UserIcon()),
                  Avatar(backgroundColor: Color(0xFF1677FF), icon: UserIcon()),
                  Avatar(backgroundColor: Color(0xFFF56A00), child: Text('K')),
                  Avatar(icon: UserIcon()),
                ],
              ),
              const AvatarGroup(
                shape: AvatarShape.square,
                maxCount: 2,
                showPopover: false,
                children: [
                  Avatar(child: Text('A')),
                  Avatar(child: Text('B')),
                  Avatar(child: Text('C')),
                  Avatar(child: Text('D')),
                ],
              ),
              AvatarGroup(
                shape: AvatarShape.square,
                maxCount: 2,
                popupRender: (context, menu) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFF0000)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: menu,
                  );
                },
                children: const [
                  Avatar(child: Text('1')),
                  Avatar(child: Text('2')),
                  Avatar(child: Text('3')),
                ],
              ),
            ],
          ),
        ),
        Group(
          'Error Fallback',
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Avatar(
                image: NetworkImage('https://invalid.url/broken.png'),
                child: Text('Fallback'),
              ),
              Avatar(
                image: const NetworkImage('https://invalid.url/broken.png'),
                errorBuilder: (context, token, error, stackTrace) => Avatar(
                  backgroundColor: token?.error.bg,
                  child: const UserIcon(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
