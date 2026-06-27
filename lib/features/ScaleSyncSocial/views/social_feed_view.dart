import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:scalesync_pro_ecosystem/services/auth_service.dart';
import 'package:scalesync_pro_ecosystem/services/theme_service.dart';
import 'package:scalesync_pro_ecosystem/utils/theme.dart';
import 'package:scalesync_pro_ecosystem/features/ScaleSyncSocial/views/social_login_view.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scalesync_pro_ecosystem/widgets/download_app_dialog.dart';

class SocialFeedView extends StatefulWidget {
  const SocialFeedView({super.key});

  @override
  State<SocialFeedView> createState() => _SocialFeedViewState();
}

class _SocialFeedViewState extends State<SocialFeedView> {
  String _feedFilter = 'All'; // 'All' | 'Media' | 'Text'
  final TextEditingController _broadcastController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final List<_MorphUpdatePost> _myPosts = [];

  // Desktop Composer Media and Stats Attachment State
  String? _attachedMediaUrl;
  bool _isAttachedVideo = false;
  Map<String, String>? _attachedStats;
  List<String> _attachedTags = [];

  // Likes state tracking
  final Set<int> _likedPostIndices = {};

  // Mobile navigation active tab index
  int _activeBottomTab = 0; // 0: Home/Feed, 1: Discover, 2: Broadcast/Post, 3: Messages, 4: Profile

  // Messages State
  int? _selectedChatIndex;
  final TextEditingController _messageComposerController = TextEditingController();
  final ScrollController _messageScrollController = ScrollController();
  final TextEditingController _searchChatsController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _chatsData = [];
  Map<int, List<Map<String, dynamic>>> _messagesHistory = {};

  // Advanced Messaging Features State
  bool _isChatSearching = false;
  String _chatSearchQuery = '';
  final TextEditingController _chatSearchController = TextEditingController();
  final Map<int, bool> _typingStates = {};

  // Firestore Sync State
  StreamSubscription<QuerySnapshot>? _chatsSubscription;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  String? _currentSubscriptionUserId;
  String? _currentSubscriptionChatId;

  @override
  void initState() {
    super.initState();
    _composerFocusNode.addListener(() {
      if (_composerFocusNode.hasFocus) {
        final authService = legacy_provider.Provider.of<AuthService>(context, listen: false);
        if (!authService.isAuthenticated) {
          _composerFocusNode.unfocus();
          _showGuestAuthSheet(
            customTitle: 'BROADCAST UPDATE',
            customMessage: 'A ScaleSyncPro ecosystem account is required to post specimen updates.',
          );
        }
      }
    });
    _searchChatsController.addListener(() {
      setState(() {
        _searchQuery = _searchChatsController.text;
      });
    });
    _chatsData = [
      {
        'name': 'ArborealMaster',
        'message': 'The Biak locality python looks amazing! Is it available?',
        'time': '2m ago',
        'unread': 1,
        'online': true,
        'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAH2HlNAj5IGHCTDASrsdxHflXVOQn36zgtJXeig9PJ7hFs0jsBuoSA0Gan2kpxC5_xkDRVzI1zRrbUhMpFniUudiFgRHBLlymJ-SJ-MDW5Ip7Y5SPWbGL6BBsaydw2BUMerLD7J7pjXULIwWAm6VvSk6dl7N83aQbMZ-F0Ui_D0CZt8i7MqFSD5aqRLpQ16WejYNagGPlDJ-s-oDLa5TnzUgk7ZrI2E7qivZ_gLDl1xni4zA-VPjqQrkPNYiRpAQ7Rb2nhkJ9wXMM',
        'specialty': 'Green Tree Pythons & Boas',
        'location': 'Oregon, USA',
        'memberSince': '2023',
      },
      {
        'name': 'DesertDragon92',
        'message': 'Sure, I can share my humidity settings. I keep it at...',
        'time': '1h ago',
        'unread': 0,
        'online': true,
        'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHXU_6BWFTCLD97Cl1Gf2cp9lSUcuTHwz5KwH6wkunSPpHQ712LU6UPFZQHlXJ8HhSadCsIxLCBXtMFss6__YFtcPVH6eFAs7DedjretZe_zibjEHpIGh4MQHL57VelVYxCowhR4yRksRxzKyoeoMnoeL_neeoxHk7wp1FwWe4AYV7F0_jrkDWaZt2oBPE6IjY1IlYfjwFAVMXsUoKBlOs2lZjNdGEVCMwKzRfz34btJtxgqU2t0UQoseCtX7XXcYaz3ZZNUSftOk',
        'specialty': 'Bearded Dragons & Uromastyx',
        'location': 'Arizona, USA',
        'memberSince': '2022',
      },
      {
        'name': 'ReptileRanch',
        'message': 'Do you have any Pastel Clown offspring available this season?',
        'time': '3h ago',
        'unread': 0,
        'online': false,
        'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAH2HlNAj5IGHCTDASrsdxHflXVOQn36zgtJXeig9PJ7hFs0jsBuoSA0Gan2kpxC5_xkDRVzI1zRrbUhMpFniUudiFgRHBLlymJ-SJ-MDW5Ip7Y5SPWbGL6BBsaydw2BUMerLD7J7pjXULIwWAm6VvSk6dl7N83aQbMZ-F0Ui_D0CZt8i7MqFSD5aqRLpQ16WejYNagGPlDJ-s-oDLa5TnzUgk7ZrI2E7qivZ_gLDl1xni4zA-VPjqQrkPNYiRpAQ7Rb2nhkJ9wXMM',
        'specialty': 'Ball Pythons & Colubrids',
        'location': 'Texas, USA',
        'memberSince': '2021',
      },
      {
        'name': 'GeckoGuild',
        'message': 'Sent you the pedigree snapshot from ScaleSync Pro.',
        'time': '1d ago',
        'unread': 0,
        'online': false,
        'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDvfta9v30KVAVz2SlBVXmJPSQ_8oU-K-vzRn58YYbuuLeywC-MDkfuoh4M23GoYae2UukM2_M3ht8-lSHWBf4CwCEIyIRS2Nns8-LuqClcmmzU8FZ_x0LJxzvK_jv3Hzoq5wT73s2Eed8KWeZ-wpTXyTnpQd2anMmRS71HAyXAQy7Ezk8ph4QkYog5xlWJSaAyG8GCXpvWSv-FWarDXpUNVg0iMMwDTWYNaHLVCNfHcYOJ_-mtUl9bUb80xxSVQixen1dKjUCmYBQ',
        'specialty': 'Crested & Leopard Geckos',
        'location': 'California, USA',
        'memberSince': '2020',
      },
    ];

    _messagesHistory = {
      0: [
        {
          'sender': 'other',
          'text': 'Hi there! I noticed you were looking at my high-expression Biak Green Tree Pythons.',
          'time': '10:15 AM',
          'type': 'text',
        },
        {
          'sender': 'user',
          'text': 'Hello! Yes, they are absolutely gorgeous. Can you tell me more about the male Biak you posted yesterday?',
          'time': '10:18 AM',
          'type': 'text',
        },
        {
          'sender': 'other',
          'text': 'Sure! He is a 2024 captive-bred male. Already showing intense yellow patches with classic green speckling. He is feeding consistently on frozen-thawed fuzzy mice.',
          'time': '10:20 AM',
          'type': 'text',
        },
        {
          'sender': 'other',
          'text': 'Here is his pedigree snapshot from my ScaleSync Pro account:',
          'time': '10:21 AM',
          'type': 'text',
        },
        {
          'sender': 'other',
          'text': '',
          'time': '10:21 AM',
          'type': 'pedigree',
          'attachment': {
            'specimenName': 'Biak GTP Male (GTP-2022-B9)',
            'morphs': 'Local-Form Biak (High Expression)',
            'sire': 'Neon Biak Outcross (GTP-Sire-02)',
            'dam': 'Classic Emerald Biak (GTP-Dam-05)',
            'hatchDate': '06/12/2024',
            'weight': '125g',
          }
        },
        {
          'sender': 'user',
          'text': 'Wow, the lineage looks very solid. What is his feeding frequency like? Any specific humidity requirements?',
          'time': '10:25 AM',
          'type': 'text',
        },
        {
          'sender': 'other',
          'text': 'I feed him every 7 days. I keep him in a moderate humidity setup: 80% spike in the evening, drying out to 50-60% during the day. He sheds perfectly every time.',
          'time': '10:28 AM',
          'type': 'text',
        },
        {
          'sender': 'other',
          'text': 'The Biak locality python looks amazing! Is it available?',
          'time': '10:30 AM',
          'type': 'text',
        },
      ],
      1: [
        {
          'sender': 'user',
          'text': 'Hey DesertDragon! I saw your video of the bearded dragon spike feeding. What enclosure size are you using?',
          'time': 'Yesterday',
          'type': 'text',
        },
        {
          'sender': 'other',
          'text': 'Hey! Thanks! That is a 4ft x 2ft x 2ft PVC enclosure from ScaleSync Marketplace. Highly recommend it for heat retention.',
          'time': 'Yesterday',
          'type': 'text',
        },
        {
          'sender': 'user',
          'text': 'Nice! Do you use custom lighting or pre-built bars?',
          'time': 'Yesterday',
          'type': 'text',
        },
        {
          'sender': 'other',
          'text': 'Sure, I can share my humidity settings. I keep it at...',
          'time': 'Yesterday',
          'type': 'text',
        },
      ],
      2: [
        {
          'sender': 'other',
          'text': 'Hello! I saw your post looking for a Pastel Clown Ball Python breeder.',
          'time': '2 days ago',
          'type': 'text',
        },
        {
          'sender': 'user',
          'text': 'Hi! Yes, I am looking to add one to my upcoming breeding project.',
          'time': '2 days ago',
          'type': 'text',
        },
        {
          'sender': 'other',
          'text': 'Do you have any Pastel Clown offspring available this season?',
          'time': '2 days ago',
          'type': 'text',
        },
      ],
      3: [
        {
          'sender': 'other',
          'text': 'Let me send you the official lineage record for the Crested Gecko you purchased.',
          'time': '3 days ago',
          'type': 'text',
        },
        {
          'sender': 'other',
          'text': 'Sent you the pedigree snapshot from ScaleSync Pro.',
          'time': '3 days ago',
          'type': 'text',
        },
      ]
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = legacy_provider.Provider.of<AuthService>(context);
    if (authService.isAuthenticated) {
      final uid = authService.currentUser!.uid;
      _setupFirestoreSync(uid);
    } else {
      if (_currentSubscriptionUserId != null) {
        _chatsSubscription?.cancel();
        _messagesSubscription?.cancel();
        _chatsSubscription = null;
        _messagesSubscription = null;
        _currentSubscriptionUserId = null;
        _currentSubscriptionChatId = null;
        _resetLocalMockData();
      }
    }
  }

  void _resetLocalMockData() {
    setState(() {
      _chatsData = [
        {
          'name': 'ArborealMaster',
          'message': 'The Biak locality python looks amazing! Is it available?',
          'time': '2m ago',
          'unread': 1,
          'online': true,
          'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAH2HlNAj5IGHCTDASrsdxHflXVOQn36zgtJXeig9PJ7hFs0jsBuoSA0Gan2kpxC5_xkDRVzI1zRrbUhMpFniUudiFgRHBLlymJ-SJ-MDW5Ip7Y5SPWbGL6BBsaydw2BUMerLD7J7pjXULIwWAm6VvSk6dl7N83aQbMZ-F0Ui_D0CZt8i7MqFSD5aqRLpQ16WejYNagGPlDJ-s-oDLa5TnzUgk7ZrI2E7qivZ_gLDl1xni4zA-VPjqQrkPNYiRpAQ7Rb2nhkJ9wXMM',
          'specialty': 'Green Tree Pythons & Boas',
          'location': 'Oregon, USA',
          'memberSince': '2023',
        },
        {
          'name': 'DesertDragon92',
          'message': 'Sure, I can share my humidity settings. I keep it at...',
          'time': '1h ago',
          'unread': 0,
          'online': true,
          'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHXU_6BWFTCLD97Cl1Gf2cp9lSUcuTHwz5KwH6wkunSPpHQ712LU6UPFZQHlXJ8HhSadCsIxLCBXtMFss6__YFtcPVH6eFAs7DedjretZe_zibjEHpIGh4MQHL57VelVYxCowhR4yRksRxzKyoeoMnoeL_neeoxHk7wp1FwWe4AYV7F0_jrkDWaZt2oBPE6IjY1IlYfjwFAVMXsUoKBlOs2lZjNdGEVCMwKzRfz34btJtxgqU2t0UQoseCtX7XXcYaz3ZZNUSftOk',
          'specialty': 'Bearded Dragons & Uromastyx',
          'location': 'Arizona, USA',
          'memberSince': '2022',
        },
        {
          'name': 'ReptileRanch',
          'message': 'Do you have any Pastel Clown offspring available this season?',
          'time': '3h ago',
          'unread': 0,
          'online': false,
          'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAH2HlNAj5IGHCTDASrsdxHflXVOQn36zgtJXeig9PJ7hFs0jsBuoSA0Gan2kpxC5_xkDRVzI1zRrbUhMpFniUudiFgRHBLlymJ-SJ-MDW5Ip7Y5SPWbGL6BBsaydw2BUMerLD7J7pjXULIwWAm6VvSk6dl7N83aQbMZ-F0Ui_D0CZt8i7MqFSD5aqRLpQ16WejYNagGPlDJ-s-oDLa5TnzUgk7ZrI2E7qivZ_gLDl1xni4zA-VPjqQrkPNYiRpAQ7Rb2nhkJ9wXMM',
          'specialty': 'Ball Pythons & Colubrids',
          'location': 'Texas, USA',
          'memberSince': '2021',
        },
        {
          'name': 'GeckoGuild',
          'message': 'Sent you the pedigree snapshot from ScaleSync Pro.',
          'time': '1d ago',
          'unread': 0,
          'online': false,
          'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDvfta9v30KVAVz2SlBVXmJPSQ_8oU-K-vzRn58YYbuuLeywC-MDkfuoh4M23GoYae2UukM2_M3ht8-lSHWBf4CwCEIyIRS2Nns8-LuqClcmmzU8FZ_x0LJxzvK_jv3Hzoq5wT73s2Eed8KWeZ-wpTXyTnpQd2anMmRS71HAyXAQy7Ezk8ph4QkYog5xlWJSaAyG8GCXpvWSv-FWarDXpUNVg0iMMwDTWYNaHLVCNfHcYOJ_-mtUl9bUb80xxSVQixen1dKjUCmYBQ',
          'specialty': 'Crested & Leopard Geckos',
          'location': 'California, USA',
          'memberSince': '2020',
        },
      ];
      _messagesHistory = {
        0: [
          {
            'sender': 'other',
            'text': 'Hi there! I noticed you were looking at my high-expression Biak Green Tree Pythons.',
            'time': '10:15 AM',
            'type': 'text',
          },
          {
            'sender': 'user',
            'text': 'Hello! Yes, they are absolutely gorgeous. Can you tell me more about the male Biak you posted yesterday?',
            'time': '10:18 AM',
            'type': 'text',
          },
          {
            'sender': 'other',
            'text': 'Sure! He is a 2024 captive-bred male. Already showing intense yellow patches with classic green speckling. He is feeding consistently on frozen-thawed fuzzy mice.',
            'time': '10:20 AM',
            'type': 'text',
          },
          {
            'sender': 'other',
            'text': 'Here is his pedigree snapshot from my ScaleSync Pro account:',
            'time': '10:21 AM',
            'type': 'text',
          },
          {
            'sender': 'other',
            'text': '',
            'time': '10:21 AM',
            'type': 'pedigree',
            'attachment': {
              'specimenName': 'Biak GTP Male (GTP-2022-B9)',
              'morphs': 'Local-Form Biak (High Expression)',
              'sire': 'Neon Biak Outcross (GTP-Sire-02)',
              'dam': 'Classic Emerald Biak (GTP-Dam-05)',
              'hatchDate': '06/12/2024',
              'weight': '125g',
            }
          },
          {
            'sender': 'user',
            'text': 'Wow, the lineage looks very solid. What is his feeding frequency like? Any specific humidity requirements?',
            'time': '10:25 AM',
            'type': 'text',
          },
          {
            'sender': 'other',
            'text': 'I feed him every 7 days. I keep him in a moderate humidity setup: 80% spike in the evening, drying out to 50-60% during the day. He sheds perfectly every time.',
            'time': '10:28 AM',
            'type': 'text',
          },
        ],
        1: [
          {
            'sender': 'user',
            'text': 'Hey! What kind of basking temperatures do you target for your adult Uromastyx setup?',
            'time': 'Yesterday',
            'type': 'text',
          },
          {
            'sender': 'other',
            'text': 'Sure, I can share my humidity settings. I keep it at around 10-15% during the day, with basking temps pushing 120-130°F. They love it dry and hot!',
            'time': '1h ago',
            'type': 'text',
          }
        ],
        2: [
          {
            'sender': 'other',
            'text': 'Do you have any Pastel Clown offspring available this season? I have a few projects I want to introduce that trait into.',
            'time': '3h ago',
            'type': 'text',
          }
        ],
        3: [
          {
            'sender': 'other',
            'text': 'Let me send you the official lineage record for the Crested Gecko you purchased.',
            'time': '3 days ago',
            'type': 'text',
          },
          {
            'sender': 'other',
            'text': 'Sent you the pedigree snapshot from ScaleSync Pro.',
            'time': '3 days ago',
            'type': 'text',
          },
        ]
      };
    });
  }
  bool _initializationInProgress = false;

  void _setupFirestoreSync(String userId) {
    if (_currentSubscriptionUserId == userId) return;
    _currentSubscriptionUserId = userId;

    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _currentSubscriptionChatId = null;

    final FirebaseFirestore db;
    try {
      db = FirebaseFirestore.instance;
    } catch (e) {
      if (kDebugMode) print('⚠️ Firestore not available (likely in widget test): $e');
      return;
    }
    final chatsQuery = db.collection('chats').where('participants', arrayContains: userId);

    _chatsSubscription = chatsQuery.snapshots().listen((snapshot) async {
      if (snapshot.docs.isEmpty) {
        // Guard against concurrent initialization calls (which would spam batch writes)
        if (_initializationInProgress) return;
        _initializationInProgress = true;
        try {
          await _initializeMockChatsInFirestore(userId);
        } catch (e) {
          if (kDebugMode) print('⚠️ Chat init error (using local data): $e');
          // Permission denied on init — keep local mock data, don't retry
          _currentSubscriptionUserId = null;
          _chatsSubscription?.cancel();
          _chatsSubscription = null;
        } finally {
          _initializationInProgress = false;
        }
        return;
      }

      final List<Map<String, dynamic>> chatsList = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final peerId = participants.firstWhere((id) => id != userId, orElse: () => 'unknown');
        
        final unreadMap = Map<String, dynamic>.from(data['unreadCount'] ?? {});
        final pinnedMap = Map<String, dynamic>.from(data['pinned'] ?? {});
        final mutedMap = Map<String, dynamic>.from(data['muted'] ?? {});
        final onlineMap = Map<String, dynamic>.from(data['onlineStatus'] ?? {});
        final typingMap = Map<String, dynamic>.from(data['typing'] ?? {});

        chatsList.add({
          'id': doc.id,
          'name': data['name'] ?? peerId,
          'message': data['lastMessage'] ?? '',
          'time': data['lastMessageTime'] ?? '',
          'unread': unreadMap[userId] ?? 0,
          'online': onlineMap[peerId] ?? false,
          'avatar': data['avatar'] ?? 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHXU_6BWFTCLD97Cl1Gf2cp9lSUcuTHwz5KwH6wkunSPpHQ712LU6UPFZQHlXJ8HhSadCsIxLCBXtMFss6__YFtcPVH6eFAs7DedjretZe_zibjEHpIGh4MQHL57VelVYxCowhR4yRksRxzKyoeoMnoeL_neeoxHk7wp1FwWe4AYV7F0_jrkDWaZt2oBPE6IjY1IlYfjwFAVMXsUoKBlOs2lZjNdGEVCMwKzRfz34btJtxgqU2t0UQoseCtX7XXcYaz3ZZNUSftOk',
          'specialty': data['specialty'] ?? 'Reptile Breeder',
          'location': data['location'] ?? 'Unknown',
          'memberSince': data['memberSince'] ?? '2024',
          'pinned': pinnedMap[userId] ?? false,
          'muted': mutedMap[userId] ?? false,
          'typing': typingMap[peerId] ?? false,
          'peerId': peerId,
          'participants': participants,
        });
      }

      if (mounted) {
        setState(() {
          _chatsData = chatsList;
          for (int i = 0; i < _chatsData.length; i++) {
            _typingStates[i] = _chatsData[i]['typing'] as bool? ?? false;
          }
        });
      }

      if (_selectedChatIndex != null && _selectedChatIndex! < _chatsData.length) {
        final activeChatId = _chatsData[_selectedChatIndex!]['id'] as String;
        _setupMessagesSync(activeChatId, _selectedChatIndex!);
      }
    }, onError: (error) {
      // Permission denied or network error — keep showing local mock data
      if (kDebugMode) print('⚠️ Firestore chats stream error (using local data): $error');
      _currentSubscriptionUserId = null;
    });
  }

  void _setupMessagesSync(String chatId, int index) {
    if (_currentSubscriptionChatId == chatId) return;
    _currentSubscriptionChatId = chatId;

    _messagesSubscription?.cancel();
    final db = FirebaseFirestore.instance;
    final messagesQuery = db.collection('chats').doc(chatId).collection('messages').orderBy('createdAt', descending: false);

    _messagesSubscription = messagesQuery.snapshots().listen((snapshot) {
      final List<Map<String, dynamic>> messagesList = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        messagesList.add({
          'id': doc.id,
          'sender': data['senderId'] == _currentSubscriptionUserId ? 'user' : 'other',
          'text': data['text'] ?? '',
          'time': data['time'] ?? 'Just now',
          'type': data['type'] ?? 'text',
          'status': data['status'] ?? 'sent',
          'reactions': List<String>.from(data['reactions'] ?? []),
          'uploading': data['uploading'] ?? false,
          'progress': (data['progress'] as num?)?.toDouble() ?? 0.0,
          'attachment': data['attachment'] != null ? Map<String, dynamic>.from(data['attachment']) : null,
        });
      }

      if (mounted) {
        setState(() {
          _messagesHistory[index] = messagesList;
        });
      }
    });
  }

  void _resetUnreadCountInFirestore(String chatId) {
    if (_currentSubscriptionUserId == null) return;
    FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'unreadCount.$_currentSubscriptionUserId': 0,
    });
  }

  Future<void> _initializeMockChatsInFirestore(String userId) async {
    final db = FirebaseFirestore.instance;

    final List<Map<String, dynamic>> initialChats = [
      {
        'peerId': 'arboreal_master',
        'name': 'ArborealMaster',
        'lastMessage': 'The Biak locality python looks amazing! Is it available?',
        'lastMessageTime': '2m ago',
        'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAH2HlNAj5IGHCTDASrsdxHflXVOQn36zgtJXeig9PJ7hFs0jsBuoSA0Gan2kpxC5_xkDRVzI1zRrbUhMpFniUudiFgRHBLlymJ-SJ-MDW5Ip7Y5SPWbGL6BBsaydw2BUMerLD7J7pjXULIwWAm6VvSk6dl7N83aQbMZ-F0Ui_D0CZt8i7MqFSD5aqRLpQ16WejYNagGPlDJ-s-oDLa5TnzUgk7ZrI2E7qivZ_gLDl1xni4zA-VPjqQrkPNYiRpAQ7Rb2nhkJ9wXMM',
        'specialty': 'Green Tree Pythons & Boas',
        'location': 'Oregon, USA',
        'memberSince': '2023',
        'initialMessages': [
          {'senderId': 'arboreal_master', 'text': 'Hi there! I noticed you were looking at my high-expression Biak Green Tree Pythons.', 'time': '10:15 AM', 'type': 'text'},
          {'senderId': userId, 'text': 'Hello! Yes, they are absolutely gorgeous. Can you tell me more about the male Biak you posted yesterday?', 'time': '10:18 AM', 'type': 'text'},
          {'senderId': 'arboreal_master', 'text': 'Sure! He is a 2024 captive-bred male. Already showing intense yellow patches with classic green speckling. He is feeding consistently on frozen-thawed fuzzy mice.', 'time': '10:20 AM', 'type': 'text'},
          {'senderId': 'arboreal_master', 'text': 'Here is his pedigree snapshot from my ScaleSync Pro account:', 'time': '10:21 AM', 'type': 'text'},
          {
            'senderId': 'arboreal_master', 'text': '', 'time': '10:21 AM', 'type': 'pedigree',
            'attachment': {'specimenName': 'Biak GTP Male (GTP-2022-B9)', 'morphs': 'Local-Form Biak (High Expression)', 'sire': 'Neon Biak Outcross (GTP-Sire-02)', 'dam': 'Classic Emerald Biak (GTP-Dam-05)', 'hatchDate': '06/12/2024', 'weight': '125g'},
          },
          {'senderId': userId, 'text': 'Wow, the lineage looks very solid. What is his feeding frequency like? Any specific humidity requirements?', 'time': '10:25 AM', 'type': 'text'},
          {'senderId': 'arboreal_master', 'text': 'I feed him every 7 days. I keep him in a moderate humidity setup: 80% spike in the evening, drying out to 50-60% during the day. He sheds perfectly every time.', 'time': '10:28 AM', 'type': 'text'},
        ]
      },
      {
        'peerId': 'desert_dragon_92',
        'name': 'DesertDragon92',
        'lastMessage': 'Sure, I can share my humidity settings. I keep it at...',
        'lastMessageTime': '1h ago',
        'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHXU_6BWFTCLD97Cl1Gf2cp9lSUcuTHwz5KwH6wkunSPpHQ712LU6UPFZQHlXJ8HhSadCsIxLCBXtMFss6__YFtcPVH6eFAs7DedjretZe_zibjEHpIGh4MQHL57VelVYxCowhR4yRksRxzKyoeoMnoeL_neeoxHk7wp1FwWe4AYV7F0_jrkDWaZt2oBPE6IjY1IlYfjwFAVMXsUoKBlOs2lZjNdGEVCMwKzRfz34btJtxgqU2t0UQoseCtX7XXcYaz3ZZNUSftOk',
        'specialty': 'Bearded Dragons & Uromastyx',
        'location': 'Arizona, USA',
        'memberSince': '2022',
        'initialMessages': [
          {'senderId': userId, 'text': 'Hey! What kind of basking temperatures do you target for your adult Uromastyx setup?', 'time': 'Yesterday', 'type': 'text'},
          {'senderId': 'desert_dragon_92', 'text': 'Sure, I can share my humidity settings. I keep it at around 10-15% during the day, with basking temps pushing 120-130°F. They love it dry and hot!', 'time': '1h ago', 'type': 'text'},
        ]
      },
      {
        'peerId': 'reptile_ranch',
        'name': 'ReptileRanch',
        'lastMessage': 'Do you have any Pastel Clown offspring available this season?',
        'lastMessageTime': '3h ago',
        'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAH2HlNAj5IGHCTDASrsdxHflXVOQn36zgtJXeig9PJ7hFs0jsBuoSA0Gan2kpxC5_xkDRVzI1zRrbUhMpFniUudiFgRHBLlymJ-SJ-MDW5Ip7Y5SPWbGL6BBsaydw2BUMerLD7J7pjXULIwWAm6VvSk6dl7N83aQbMZ-F0Ui_D0CZt8i7MqFSD5aqRLpQ16WejYNagGPlDJ-s-oDLa5TnzUgk7ZrI2E7qivZ_gLDl1xni4zA-VPjqQrkPNYiRpAQ7Rb2nhkJ9wXMM',
        'specialty': 'Ball Pythons & Colubrids',
        'location': 'Texas, USA',
        'memberSince': '2021',
        'initialMessages': [
          {'senderId': 'reptile_ranch', 'text': 'Do you have any Pastel Clown offspring available this season? I have a few projects I want to introduce that trait into.', 'time': '3h ago', 'type': 'text'},
        ]
      },
      {
        'peerId': 'gecko_guild',
        'name': 'GeckoGuild',
        'lastMessage': 'Sent you the pedigree snapshot from ScaleSync Pro.',
        'lastMessageTime': '1d ago',
        'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDvfta9v30KVAVz2SlBVXmJPSQ_8oU-K-vzRn58YYbuuLeywC-MDkfuoh4M23GoYae2UukM2_M3ht8-LuqClcmmzU8FZ_x0LJxzvK_jv3Hzoq5wT73s2Eed8KWeZ-wpTXyTnpQd2anMmRS71HAyXAQy7Ezk8ph4QkYog5xlWJSaAyG8GCXpvWSv-FWarDXpUNVg0iMMwDTWYNaHLVCNfHcYOJ_-mtUl9bUb80xxSVQixen1dKjUCmYBQ',
        'specialty': 'Crested & Gargoyle Geckos',
        'location': 'Washington, USA',
        'memberSince': '2020',
        'initialMessages': [
          {'senderId': 'gecko_guild', 'text': 'Sent you the pedigree snapshot from ScaleSync Pro. The dam is from our original high-contrast line.', 'time': '1d ago', 'type': 'text'},
        ]
      }
    ];

    // ── Phase 1: commit chat documents only ──────────────────────────────────
    // Messages cannot be committed in the same batch because the security rule
    // uses get(parent_chat) to verify participation — and that get() returns
    // null if the parent is being created in the same batch commit.
    final chatBatch = db.batch();
    for (var initChat in initialChats) {
      final chatId = 'chat_${userId}_${initChat['peerId']}';
      final chatRef = db.collection('chats').doc(chatId);
      chatBatch.set(chatRef, {
        'participants': [userId, initChat['peerId']],
        'name': initChat['name'],
        'avatar': initChat['avatar'],
        'specialty': initChat['specialty'],
        'location': initChat['location'],
        'memberSince': initChat['memberSince'],
        'lastMessage': initChat['lastMessage'],
        'lastMessageTime': initChat['lastMessageTime'],
        'unreadCount': {userId: 0, initChat['peerId']: 0},
        'pinned': {userId: false, initChat['peerId']: false},
        'muted': {userId: false, initChat['peerId']: false},
        'onlineStatus': {initChat['peerId']: true},
        'typing': {userId: false, initChat['peerId']: false},
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await chatBatch.commit(); // ← parent docs now exist in Firestore

    // ── Phase 2: commit messages (parent docs are committed, get() will succeed) ─
    final msgBatch = db.batch();
    for (var initChat in initialChats) {
      final chatId = 'chat_${userId}_${initChat['peerId']}';
      final chatRef = db.collection('chats').doc(chatId);
      final msgs = initChat['initialMessages'] as List<Map<String, dynamic>>;
      for (int i = 0; i < msgs.length; i++) {
        final msgRef = chatRef.collection('messages').doc('msg_$i');
        msgBatch.set(msgRef, {
          'senderId': msgs[i]['senderId'],
          'text': msgs[i]['text'],
          'time': msgs[i]['time'],
          'type': msgs[i]['type'],
          'status': 'read',
          'reactions': <String>[],
          if (msgs[i]['attachment'] != null) 'attachment': msgs[i]['attachment'],
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: (msgs.length - i) * 5))),
        });
      }
    }
    await msgBatch.commit();
  }

  void _triggerPeerReplySequence(String chatId, String peerId, String text) {
    final mockPeerIds = ['arboreal_master', 'desert_dragon_92', 'reptile_ranch', 'gecko_guild'];
    if (!mockPeerIds.contains(peerId)) return;

    final db = FirebaseFirestore.instance;

    Future.delayed(const Duration(milliseconds: 600), () async {
      if (_currentSubscriptionUserId == null) return;
      final messagesSnap = await db.collection('chats').doc(chatId).collection('messages')
          .where('senderId', isEqualTo: _currentSubscriptionUserId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (messagesSnap.docs.isNotEmpty) {
        await messagesSnap.docs.first.reference.update({'status': 'delivered'});
      }

      Future.delayed(const Duration(milliseconds: 600), () async {
        if (_currentSubscriptionUserId == null) return;
        if (messagesSnap.docs.isNotEmpty) {
          await messagesSnap.docs.first.reference.update({'status': 'read'});
        }

        await db.collection('chats').doc(chatId).update({
          'typing.$peerId': true,
        });

        Future.delayed(const Duration(seconds: 2), () async {
          if (_currentSubscriptionUserId == null) return;
          String replyText = '';
          if (text.toLowerCase().contains('price') || text.toLowerCase().contains('cost') || text.toLowerCase().contains('how much')) {
            replyText = "I'm offering this specimen for \$650 plus shipping. Let me know if you want me to send a formal purchase request via ScaleSync Marketplace!";
          } else if (text.toLowerCase().contains('available') || text.toLowerCase().contains('still have')) {
            replyText = "Yes, he's still available! I've had a few inquiries this morning, but no deposits placed yet.";
          } else if (text.toLowerCase().contains('ship') || text.toLowerCase().contains('shipping')) {
            replyText = "I ship via FedEx Priority Overnight through ShipYourReptiles. Shipping is usually a flat \$55, weather permitting.";
          } else {
            replyText = "Thanks for the message! Let me check the records in my herpetarium dashboard and get back to you shortly. 🦎";
          }

          await db.collection('chats').doc(chatId).collection('messages').add({
            'senderId': peerId,
            'text': replyText,
            'time': TimeOfDay.now().format(context),
            'type': 'text',
            'status': 'read',
            'reactions': <String>[],
            'createdAt': FieldValue.serverTimestamp(),
          });

          await db.collection('chats').doc(chatId).update({
            'lastMessage': replyText,
            'lastMessageTime': 'Just now',
            'typing.$peerId': false,
            'unreadCount.$_currentSubscriptionUserId': FieldValue.increment(1),
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _broadcastController.dispose();
    _composerFocusNode.dispose();
    _messageComposerController.dispose();
    _messageScrollController.dispose();
    _searchChatsController.dispose();
    _chatSearchController.dispose();
    super.dispose();
  }

  void _focusPostComposer() {
    final authService = legacy_provider.Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) {
      _showGuestAuthSheet(
        customTitle: 'BROADCAST UPDATE',
        customMessage: 'A ScaleSyncPro ecosystem account is required to post specimen updates.',
      );
      return;
    }
    _composerFocusNode.requestFocus();
  }

  void _showMobilePostSheet(BuildContext context) {
    String? localMediaUrl;
    bool localIsVideo = false;
    Map<String, String>? localStats;
    List<String> localTags = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Create Broadcast',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _broadcastController,
                      maxLines: 4,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "What's happening in your herpetarium?",
                        hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 14),
                        fillColor: Colors.transparent,
                        filled: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    
                    // Attachment preview inside mobile sheet
                    _ComposerAttachmentPreview(
                      mediaUrl: localMediaUrl,
                      isVideo: localIsVideo,
                      stats: localStats,
                      tags: localTags,
                      onRemoveMedia: () {
                        setModalState(() {
                          localMediaUrl = null;
                          localIsVideo = false;
                        });
                      },
                      onRemoveStats: () {
                        setModalState(() {
                          localStats = null;
                        });
                      },
                      onRemoveTag: (tag) {
                        setModalState(() {
                          localTags.remove(tag);
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF333333), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildComposerAction(Icons.image_outlined, 'Photo', () {
                                  _showAddPhotoDialog(context, (url) {
                                    setModalState(() {
                                      localMediaUrl = url;
                                      localIsVideo = false;
                                    });
                                  });
                                }),
                                const SizedBox(width: 12),
                                _buildComposerAction(Icons.videocam_outlined, 'Video', () {
                                  _showAddVideoDialog(context, (url) {
                                    setModalState(() {
                                      localMediaUrl = url;
                                      localIsVideo = true;
                                    });
                                  });
                                }),
                                const SizedBox(width: 12),
                                _buildComposerAction(Icons.thermostat_outlined, 'Stats', () {
                                  _showAddStatsDialog(context, (statsMap) {
                                    setModalState(() {
                                      localStats = statsMap;
                                    });
                                  });
                                }),
                                const SizedBox(width: 12),
                                _buildComposerAction(Icons.local_offer_outlined, 'Tags', () {
                                  _showAddTagDialog(context, (tag) {
                                    if (!localTags.contains(tag)) {
                                      setModalState(() {
                                        localTags.add(tag);
                                      });
                                    }
                                  });
                                }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (_broadcastController.text.trim().isEmpty) return;
                            
                            final authService = legacy_provider.Provider.of<AuthService>(context, listen: false);
                            final userName = authService.currentUser?.email?.split('@').first ?? 'You';
                            
                            final newPost = _MorphUpdatePost(
                              breederName: userName,
                              avatarText: userName.substring(0, 1).toUpperCase(),
                              timeAgo: 'Just now',
                              subtitle: 'Broadcast Node',
                              morphTitle: 'Broadcast Update',
                              morphContent: _broadcastController.text.trim(),
                              morphTags: localTags.isNotEmpty ? localTags : ['Broadcast', 'LiveFeed'],
                              likes: 0,
                              comments: 0,
                              shares: 0,
                              hasMedia: localMediaUrl != null,
                              mediaUrl: localMediaUrl,
                              isVideo: localIsVideo,
                              stats: localStats,
                            );

                            setState(() {
                              _myPosts.insert(0, newPost);
                              _broadcastController.clear();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Publish'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showGuestAuthSheet({required String customTitle, required String customMessage}) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool isPasswordVisible = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                decoration: const BoxDecoration(
                  color: Color(0xFF0B0D09),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(color: Color(0xFF1E2619), width: 1),
                    left: BorderSide(color: Color(0xFF1E2619), width: 1),
                    right: BorderSide(color: Color(0xFF1E2619), width: 1),
                  ),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E3229),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header badge + label
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFA5E644).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: const Color(0xFFA5E644)
                                      .withOpacity(0.4)),
                            ),
                            child: const Text(
                              'AUTH REQUIRED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.6,
                                color: Color(0xFFA5E644),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Sign in to continue',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A9A80),
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        customTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customMessage,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5A6A52),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // EMAIL label
                      const Text(
                        'EMAIL_ADDRESS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Color(0xFF5A6A52),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 6),

                      // EMAIL field
                      TextFormField(
                        controller: emailController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter account email...',
                          hintStyle: const TextStyle(
                              color: Color(0xFF2E3229), fontSize: 13),
                          fillColor: const Color(0xFF070806),
                          filled: true,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide:
                                const BorderSide(color: Color(0xFF1E2619)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide:
                                const BorderSide(color: Color(0xFFA5E644)),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide:
                                const BorderSide(color: Color(0xFFD32F2F)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide:
                                const BorderSide(color: Color(0xFFD32F2F)),
                          ),
                          errorStyle: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'REQUIRED_FIELD';
                          if (!v.contains('@')) return 'INVALID_EMAIL_FORMAT';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // PASSWORD label
                      const Text(
                        'MASTER_KEY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Color(0xFF5A6A52),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 6),

                      // PASSWORD field
                      TextFormField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter password...',
                          hintStyle: const TextStyle(
                              color: Color(0xFF2E3229), fontSize: 13),
                          fillColor: const Color(0xFF070806),
                          filled: true,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF5A6A52),
                              size: 16,
                            ),
                            onPressed: () {
                              setSheetState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide:
                                const BorderSide(color: Color(0xFF1E2619)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide:
                                const BorderSide(color: Color(0xFFA5E644)),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide:
                                const BorderSide(color: Color(0xFFD32F2F)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide:
                                const BorderSide(color: Color(0xFFD32F2F)),
                          ),
                          errorStyle: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'REQUIRED_FIELD';
                          if (v.length < 6) return 'MIN_LENGTH_6_CHAR';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Sign In Button
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    setSheetState(() {
                                      isLoading = true;
                                    });
                                    try {
                                      final authService =
                                          legacy_provider.Provider.of<AuthService>(
                                              context,
                                              listen: false);
                                      await authService
                                          .signInWithEmailAndPassword(
                                        emailController.text.trim(),
                                        passwordController.text,
                                      );
                                      if (sheetCtx.mounted) {
                                        Navigator.of(sheetCtx).pop();
                                      }
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Authentication successful. Ecosystem state synced.'),
                                            backgroundColor: Color(0xFFA5E644),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setSheetState(() {
                                        isLoading = false;
                                      });
                                      if (sheetCtx.mounted) {
                                        ScaffoldMessenger.of(sheetCtx)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'AUTH_FAILURE: ${e.toString()}'),
                                            backgroundColor:
                                                const Color(0xFFD32F2F),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA5E644),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black),
                                  ),
                                )
                              : const Text(
                                  '[ AUTHENTICATE ]',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'CONTINUE AS GUEST  ↗',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            color: Color(0xFF5A6A52),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = legacy_provider.Provider.of<AuthService>(context);
    final isLoggedIn = authService.isAuthenticated;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;
    final isMobile = screenWidth <= 768;

    final mockUpdates = [
      _MorphUpdatePost(
        breederName: 'ArborealMaster',
        avatarText: 'AM',
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAH2HlNAj5IGHCTDASrsdxHflXVOQn36zgtJXeig9PJ7hFs0jsBuoSA0Gan2kpxC5_xkDRVzI1zRrbUhMpFniUudiFgRHBLlymJ-SJ-MDW5Ip7Y5SPWbGL6BBsaydw2BUMerLD7J7pjXULIwWAm6VvSk6dl7N83aQbMZ-F0Ui_D0CZt8i7MqFSD5aqRLpQ16WejYNagGPlDJ-s-oDLa5TnzUgk7ZrI2E7qivZ_gLDl1xni4zA-VPjqQrkPNYiRpAQ7Rb2nhkJ9wXMM',
        timeAgo: '2h ago',
        subtitle: 'Morelia viridis',
        morphTitle: 'Morning glow on the Biak.',
        morphContent: 'Just look at that contrast! This Biak locality is finally starting to show those deep yellows and high-contrast greens after its last shed. Maintaining 82% humidity and a steady 84°F hotspot.',
        morphTags: ['GreenTreePython', 'BiakLocality'],
        likes: 1200,
        comments: 84,
        shares: 5,
        hasMedia: true,
        mediaUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC8A00HI6-gr9_6JK-4AXyAgsjZLGk6BgG2WZm-UFT4R4LsDMFaMTfFpBxaVPLHuIauRfPI4Wizx6QzPTg7KfpopNS_bR9JdoVHCIAchR2Ra5mX5ESL7FLTFTZ3-MWW90vr8T9dgNQVyI_0rXkXIWttjhVu1o_KfrQ8V7gfsc2wmjnJBL-4YHiXkuIEWOPdUglpaQf22uAtB0y29wZmlESMND9SffvtUmNpGDRez0SA0UsVTqCeW72YPtFl43zYxEi9nFSITM-ZsRk',
      ),
      _MorphUpdatePost(
        breederName: 'DesertDragon92',
        avatarText: 'DD',
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHXU_6BWFTCLD97Cl1Gf2cp9lSUcuTHwz5KwH6wkunSPpHQ712LU6UPFZQHlXJ8HhSadCsIxLCBXtMFss6__YFtcPVH6eFAs7DedjretZe_zibjEHpIGh4MQHL57VelVYxCowhR4yRksRxzKyoeoMnoeL_neeoxHk7wp1FwWe4AYV7F0_jrkDWaZt2oBPE6IjY1IlYfjwFAVMXsUoKBlOs2lZjNdGEVCMwKzRfz34btJtxgqU2t0UQoseCtX7XXcYaz3ZZNUSftOk',
        timeAgo: '5h ago',
        subtitle: 'Feeding Time',
        morphTitle: 'Lunch time for Spike!',
        morphContent: "Lunch time for Spike! Watching the hunt drive in these animals never gets old. He's up to 450g now and looking healthy.",
        morphTags: ['BeardedDragon', 'Feeding'],
        likes: 345,
        comments: 28,
        shares: 2,
        hasMedia: true,
        mediaUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAs3nf7fxWMGVUs0HwBaCyRiyQzgQcQ8CUXfl0m4_rSJH4fjPpX0wMf-8C04Tf4ouMa8unIcCYSb5FK6MOtXL9ZP1O0Rp903RKoUHUeeQ0aDTMoEp_0pHE204uJ9poibAJVcNqbhqfIHeDv-C9vG5-ACRRhnMRFursKDc30yXDI9MR4F-h4JuaAQwoj4Xe80niwm8vbjWxr5YtawpqsErSmfF59m6O2IQ7xs0KHsNMXOJk22TNEbbHZUCOelqJdO-9N_uB3x60cXyg',
        isVideo: true,
        stats: {
          'Temperature': '105°F',
          'Humidity': '15%',
          'Supplement': 'Ca + D3',
        },
      ),
      _MorphUpdatePost(
        breederName: 'NewKeeper_Leo',
        avatarText: 'NL',
        avatarIcon: Icons.help_outline,
        timeAgo: '8h ago',
        subtitle: 'Husbandry Question',
        morphTitle: 'Struggling with night-time temp drops for my Ball Python...',
        morphContent: "I'm using a 100W CHE on a thermostat, but the ambient temps in the cool side are dropping to 72°F at night. My house is drafty. Is a secondary under-tank heater necessary, or should I insulate the enclosure better?",
        morphTags: ['BallPython', 'EnclosureDesign', 'HusbandryHelp'],
        likes: 18,
        comments: 12,
        shares: 1,
        hasMedia: false,
      ),
    ];

    // Combine local user custom broadcasts into the feed list
    final List<_MorphUpdatePost> allPosts = [];
    
    // Add user's custom posts first
    allPosts.addAll(_myPosts);
    
    allPosts.addAll(mockUpdates);

    // Apply Filter
    final filteredPosts = allPosts.where((post) {
      if (_feedFilter == 'Media') return post.hasMedia;
      if (_feedFilter == 'Text') return !post.hasMedia;
      return true;
    }).toList();

    final themeService = legacy_provider.Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
      bottomNavigationBar: isMobile && !(_activeBottomTab == 3 && _selectedChatIndex != null) ? _buildBottomNavigationBar(context, isDark) : null,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Brand Header
            if (!(isMobile && _activeBottomTab == 3 && _selectedChatIndex != null))
              _buildHeader(context, authService, isLoggedIn, isMobile),

            // Main Columns Section
            Expanded(
              child: Builder(
                builder: (context) {
                  final activeView = Builder(
                    builder: (context) {
                      switch (_activeBottomTab) {
                        case 1:
                          return _buildDiscoverMobileView(isDark);
                        case 2:
                          return _buildNotificationsView(isDark);
                        case 3:
                          return _buildMessagesView(isDark, isMobile: isMobile);
                        case 4:
                          return _buildProfileMobileView(isDark);
                        case 5:
                          return _buildSettingsView(isDark);
                        case 0:
                        default:
                          return _buildFeedColumn(filteredPosts, !isMobile);
                      }
                    },
                  );

                  if (isDesktop) {
                    final showRightSidebar = _activeBottomTab != 3 && _activeBottomTab != 5;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SidebarNavigation(
                          isTablet: false,
                          onPostPressed: _focusPostComposer,
                          activeTab: _activeBottomTab,
                          onTabSelected: (tab) {
                            if (tab == 3 || tab == 4 || tab == 5) {
                              if (!authService.isAuthenticated) {
                                _showGuestAuthSheet(
                                  customTitle: tab == 3 ? 'MESSAGING CENTER' : (tab == 4 ? 'PROFILE ACCESS' : 'SETTINGS ACCESS'),
                                  customMessage: 'A ScaleSyncPro ecosystem account is required to access this feature.',
                                );
                                return;
                              }
                            }
                            setState(() {
                              _activeBottomTab = tab;
                            });
                          },
                        ),
                        Expanded(
                          child: activeView,
                        ),
                        if (showRightSidebar) const _RightSidebar(),
                      ],
                    );
                  } else if (isTablet) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SidebarNavigation(
                          isTablet: true,
                          onPostPressed: _focusPostComposer,
                          activeTab: _activeBottomTab,
                          onTabSelected: (tab) {
                            if (tab == 3 || tab == 4 || tab == 5) {
                              if (!authService.isAuthenticated) {
                                _showGuestAuthSheet(
                                  customTitle: tab == 3 ? 'MESSAGING CENTER' : (tab == 4 ? 'PROFILE ACCESS' : 'SETTINGS ACCESS'),
                                  customMessage: 'A ScaleSyncPro ecosystem account is required to access this feature.',
                                );
                                return;
                              }
                            }
                            setState(() {
                              _activeBottomTab = tab;
                            });
                          },
                        ),
                        Expanded(
                          child: activeView,
                        ),
                      ],
                    );
                  } else {
                    // Mobile: reuse the same activeView — covers all tabs including
                    // Notifications (2), Messages (3), Profile (4), Settings (5)
                    return activeView;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(BuildContext context, AuthService authService, bool isLoggedIn, bool isMobile) {
    final themeService = legacy_provider.Provider.of<ThemeService>(context);
    final userData = authService.userData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(
          bottom: BorderSide(color: Color(0xFF222222), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Left: icon + brand name (flexible, takes remaining space)
          const Icon(
            Icons.drag_indicator,
            size: 28,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ScaleSync Social',
              style: TextStyle(
                fontSize: isMobile ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Right: Pro badge + username + menu (fixed width section)
          // LOCKED DESIGN DECISION: DO NOT MODIFY OR REMOVE. The username must always be displayed
          // between the Pro Badge and the menu button in the header across all devices, matching
          // ScaleSync Pro and Marketplace. This setup is locked and must never be changed.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
            ),
            child: const Text(
              'Pro',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              isLoggedIn
                  ? (userData?['name'] ?? authService.currentUser?.displayName ?? authService.currentUser?.email?.split('@')[0] ?? 'User')
                  : 'Guest',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _SocialUserMenuButton(
            userData: userData,
            themeService: themeService,
            authService: authService,
            onAuthRequired: () {
              _showGuestAuthSheet(
                customTitle: 'PROFILE ACCESS',
                customMessage: 'A ScaleSyncPro ecosystem account is required to view profile options.',
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Column 2: Feed Column ---
  Widget _buildFeedColumn(List<_MorphUpdatePost> posts, bool isMobile) {
    final authService = legacy_provider.Provider.of<AuthService>(context);
    final themeService = legacy_provider.Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Title & Filter Row
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Herpetarium Feed',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: ['All', 'Media', 'Text'].map((filter) {
                          final isSelected = _feedFilter == filter;
                          return InkWell(
                            onTap: () => setState(() => _feedFilter = filter),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? (isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary) 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected 
                                      ? (isDark ? Colors.white : AppTheme.lightTextPrimary) 
                                      : (isDark ? AppTheme.textLight : AppTheme.lightTextLight),
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Herpetarium Feed',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ),
                    const SizedBox(width: 8),
                    // Segmented Filter Control
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor,
                        ),
                      ),
                      child: Row(
                        children: ['All', 'Media', 'Text'].map((filter) {
                          final isSelected = _feedFilter == filter;
                          return InkWell(
                            onTap: () => setState(() => _feedFilter = filter),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? (isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary) 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected 
                                      ? (isDark ? Colors.white : AppTheme.lightTextPrimary) 
                                      : (isDark ? AppTheme.textLight : AppTheme.lightTextLight),
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 16),
          // Scrollable List
          Expanded(
            child: ListView.builder(
              itemCount: posts.length + (isMobile ? 0 : 1),
              itemBuilder: (context, index) {
                if (!isMobile) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: _PostComposerCard(
                        controller: _broadcastController,
                        focusNode: _composerFocusNode,
                        mediaUrl: _attachedMediaUrl,
                        isVideo: _isAttachedVideo,
                        stats: _attachedStats,
                        tags: _attachedTags,
                        onAddPhoto: () {
                          if (!authService.isAuthenticated) {
                            _showGuestAuthSheet(
                              customTitle: 'BROADCAST UPDATE',
                              customMessage: 'A ScaleSyncPro ecosystem account is required to attach media.',
                            );
                            return;
                          }
                          _showAddPhotoDialog(context, (url) {
                            setState(() {
                              _attachedMediaUrl = url;
                              _isAttachedVideo = false;
                            });
                          });
                        },
                        onAddVideo: () {
                          if (!authService.isAuthenticated) {
                            _showGuestAuthSheet(
                              customTitle: 'BROADCAST UPDATE',
                              customMessage: 'A ScaleSyncPro ecosystem account is required to attach media.',
                            );
                            return;
                          }
                          _showAddVideoDialog(context, (url) {
                            setState(() {
                              _attachedMediaUrl = url;
                              _isAttachedVideo = true;
                            });
                          });
                        },
                        onAddStats: () {
                          if (!authService.isAuthenticated) {
                            _showGuestAuthSheet(
                              customTitle: 'BROADCAST UPDATE',
                              customMessage: 'A ScaleSyncPro ecosystem account is required to add pedigree statistics.',
                            );
                            return;
                          }
                          _showAddStatsDialog(context, (statsMap) {
                            setState(() {
                              _attachedStats = statsMap;
                            });
                          });
                        },
                        onAddTag: () {
                          if (!authService.isAuthenticated) {
                            _showGuestAuthSheet(
                              customTitle: 'BROADCAST UPDATE',
                              customMessage: 'A ScaleSyncPro ecosystem account is required to add tags.',
                            );
                            return;
                          }
                          _showAddTagDialog(context, (tag) {
                            if (!_attachedTags.contains(tag)) {
                              setState(() {
                                _attachedTags.add(tag);
                              });
                            }
                          });
                        },
                        onRemoveMedia: () {
                          setState(() {
                            _attachedMediaUrl = null;
                            _isAttachedVideo = false;
                          });
                        },
                        onRemoveStats: () {
                          setState(() {
                            _attachedStats = null;
                          });
                        },
                        onRemoveTag: (tag) {
                          setState(() {
                            _attachedTags.remove(tag);
                          });
                        },
                        onPublish: () {
                          if (!authService.isAuthenticated) {
                            _showGuestAuthSheet(
                              customTitle: 'BROADCAST UPDATE',
                              customMessage: 'A ScaleSyncPro ecosystem account is required to post specimen updates.',
                            );
                            return;
                          }
                          if (_broadcastController.text.trim().isEmpty) return;
                          final userName = authService.currentUser?.email?.split('@').first ?? 'You';
                          final newPost = _MorphUpdatePost(
                            breederName: userName,
                            avatarText: userName.substring(0, 1).toUpperCase(),
                            timeAgo: 'Just now',
                            subtitle: 'Broadcast Node',
                            morphTitle: 'Broadcast Update',
                            morphContent: _broadcastController.text.trim(),
                            morphTags: _attachedTags.isNotEmpty ? List.from(_attachedTags) : ['Broadcast', 'LiveFeed'],
                            likes: 0,
                            comments: 0,
                            shares: 0,
                            hasMedia: _attachedMediaUrl != null,
                            mediaUrl: _attachedMediaUrl,
                            isVideo: _isAttachedVideo,
                            stats: _attachedStats != null ? Map.from(_attachedStats!) : null,
                          );
                          setState(() {
                            _myPosts.insert(0, newPost);
                            _broadcastController.clear();
                            _attachedMediaUrl = null;
                            _isAttachedVideo = false;
                            _attachedStats = null;
                            _attachedTags = [];
                          });
                        },
                        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDvfta9v30KVAVz2SlBVXmJPSQ_8oU-K-vzRn58YYbuuLeywC-MDkfuoh4M23GoYae2UukM2_M3ht8-lSHWBf4CwCEIyIRS2Nns8-LuqClcmmzU8FZ_x0LJxzvK_jv3Hzoq5wT73s2Eed8KWeZ-wpTXyTnpQd2anMmRS71HAyXAQy7Ezk8ph4QkYog5xlWJSaAyG8GCXpvWSv-FWarDXpUNVg0iMMwDTWYNaHLVCNfHcYOJ_-mtUl9bUb80xxSVQixen1dKjUCmYBQ',
                      ),
                    );
                  }
                  final post = posts[index - 1];
                  final liked = _likedPostIndices.contains(index - 1);
                  return _SocialPostCard(
                    post: post,
                    isLiked: liked,
                    onLikeToggle: () {
                      if (!authService.isAuthenticated) {
                        _showGuestAuthSheet(
                          customTitle: 'LIKE POST',
                          customMessage: 'A ScaleSyncPro ecosystem account is required to like posts.',
                        );
                        return;
                      }
                      setState(() {
                        if (liked) {
                          _likedPostIndices.remove(index - 1);
                        } else {
                          _likedPostIndices.add(index - 1);
                        }
                      });
                    },
                  );
                } else {
                  final post = posts[index];
                  final liked = _likedPostIndices.contains(index);
                  return _SocialPostCard(
                    post: post,
                    isLiked: liked,
                    onLikeToggle: () {
                      if (!authService.isAuthenticated) {
                        _showGuestAuthSheet(
                          customTitle: 'LIKE POST',
                          customMessage: 'A ScaleSyncPro ecosystem account is required to like posts.',
                        );
                        return;
                      }
                      setState(() {
                        if (liked) {
                          _likedPostIndices.remove(index);
                        } else {
                          _likedPostIndices.add(index);
                        }
                      });
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Bottom Navigation Bar & Mobile Tabs
  // ==========================================

  Widget _buildBottomNavigationBar(BuildContext context, bool isDark) {
    final tabs = [
      {'label': 'Home', 'icon': Icons.home_outlined, 'activeIcon': Icons.home},
      {'label': 'Discover', 'icon': Icons.explore_outlined, 'activeIcon': Icons.explore},
      {'label': 'Broadcast', 'icon': Icons.add_circle_outline, 'activeIcon': Icons.add_circle},
      {'label': 'Messages', 'icon': Icons.chat_bubble_outline, 'activeIcon': Icons.chat_bubble},
      {'label': 'Profile', 'icon': Icons.person_outline, 'activeIcon': Icons.person},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgPrimary.withOpacity(0.95) : AppTheme.lightBgPrimary.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isMiddle = index == 2;
              final isActive = _activeBottomTab == index;
              
              return GestureDetector(
                onTap: () {
                  final authService = legacy_provider.Provider.of<AuthService>(context, listen: false);
                  if (index == 2) {
                    // Broadcast
                    if (!authService.isAuthenticated) {
                      _showGuestAuthSheet(
                        customTitle: 'BROADCAST UPDATE',
                        customMessage: 'A ScaleSyncPro ecosystem account is required to post specimen updates.',
                      );
                      return;
                    }
                    _showMobilePostSheet(context);
                  } else if (index == 3) {
                    // Messages
                    if (!authService.isAuthenticated) {
                      _showGuestAuthSheet(
                        customTitle: 'MESSAGING CENTER',
                        customMessage: 'A ScaleSyncPro ecosystem account is required to access private messages.',
                      );
                      return;
                    }
                    setState(() {
                      _activeBottomTab = index;
                    });
                  } else if (index == 4) {
                    // Profile
                    if (!authService.isAuthenticated) {
                      _showGuestAuthSheet(
                        customTitle: 'PROFILE ACCESS',
                        customMessage: 'A ScaleSyncPro ecosystem account is required to view profiles.',
                      );
                      return;
                    }
                    setState(() {
                      _activeBottomTab = index;
                    });
                  } else {
                    setState(() {
                      _activeBottomTab = index;
                    });
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (isActive ? tab['activeIcon'] : tab['icon']) as IconData,
                      size: isMiddle ? 26 : 22,
                      color: isMiddle
                          ? AppTheme.accentColor
                          : (isActive
                              ? (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor)
                              : (isDark ? AppTheme.textLight : AppTheme.lightTextLight)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive
                            ? (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor)
                            : (isDark ? AppTheme.textLight : AppTheme.lightTextLight),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverMobileView(bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final secondaryTextColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final mutedTextColor = isDark ? AppTheme.textLight : AppTheme.lightTextLight;
    final cardBg = isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary;
    final borderColor = isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor;

    final trendingTags = ['#BallPython', '#CrestedGecko', '#HerpHusbandry', '#MorphMarket', '#BreedingLog'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161810) : AppTheme.lightBgPrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search breeders, mutations, tags...',
                hintStyle: TextStyle(color: mutedTextColor, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: mutedTextColor, size: 20),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Trending Tags Header
          Text(
            'Trending Tags',
            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: trendingTags.map((tag) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tag, color: AppTheme.accentColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        tag,
                        style: TextStyle(color: secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Breeder Spotlights
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Breeder Spotlights',
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'See all',
                style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSpotlightCard('ReptileRanch', '15.4k followers', 'https://lh3.googleusercontent.com/aida-public/AB6AXuAH2HlNAj5IGHCTDASrsdxHflXVOQn36zgtJXeig9PJ7hFs0jsBuoSA0Gan2kpxC5_xkDRVzI1zRrbUhMpFniUudiFgRHBLlymJ-SJ-MDW5Ip7Y5SPWbGL6BBsaydw2BUMerLD7J7pjXULIwWAm6VvSk6dl7N83aQbMZ-F0Ui_D0CZt8i7MqFSD5aqRLpQ16WejYNagGPlDJ-s-oDLa5TnzUgk7ZrI2E7qivZ_gLDl1xni4zA-VPjqQrkPNYiRpAQ7Rb2nhkJ9wXMM', isDark),
                _buildSpotlightCard('GeckoGuild', '8.9k followers', 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHXU_6BWFTCLD97Cl1Gf2cp9lSUcuTHwz5KwH6wkunSPpHQ712LU6UPFZQHlXJ8HhSadCsIxLCBXtMFss6__YFtcPVH6eFAs7DedjretZe_zibjEHpIGh4MQHL57VelVYxCowhR4yRksRxzKyoeoMnoeL_neeoxHk7wp1FwWe4AYV7F0_jrkDWaZt2oBPE6IjY1IlYfjwFAVMXsUoKBlOs2lZjNdGEVCMwKzRfz34btJtxgqU2t0UQoseCtX7XXcYaz3ZZNUSftOk', isDark),
                _buildSpotlightCard('ArborealMaster', '12.2k followers', 'https://lh3.googleusercontent.com/aida-public/AB6AXuDvfta9v30KVAVz2SlBVXmJPSQ_8oU-K-vzRn58YYbuuLeywC-MDkfuoh4M23GoYae2UukM2_M3ht8-lSHWBf4CwCEIyIRS2Nns8-LuqClcmmzU8FZ_x0LJxzvK_jv3Hzoq5wT73s2Eed8KWeZ-wpTXyTnpQd2anMmRS71HAyXAQy7Ezk8ph4QkYog5xlWJSaAyG8GCXpvWSv-FWarDXpUNVg0iMMwDTWYNaHLVCNfHcYOJ_-mtUl9bUb80xxSVQixen1dKjUCmYBQ', isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Trending Broadcasts Grid
          Text(
            'Trending Broadcasts',
            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
            children: [
              _buildDiscoverGridItem(
                'Biak GTP',
                'ArborealMaster',
                'https://lh3.googleusercontent.com/aida-public/AB6AXuC8A00HI6-gr9_6JK-4AXyAgsjZLGk6BgG2WZm-UFT4R4LsDMFaMTfFpBxaVPLHuIauRfPI4Wizx6QzPTg7KfpopNS_bR9JdoVHCIAchR2Ra5mX5ESL7FLTFTZ3-MWW90vr8T9dgNQVyI_0rXkXIWttjhVu1o_KfrQ8V7gfsc2wmjnJBL-4YHiXkuIEWOPdUglpaQf22uAtB0y29wZmlESMND9SffvtUmNpGDRez0SA0UsVTqCeW72YPtFl43zYxEi9nFSITM-ZsRk',
                '1.2k likes',
                isDark,
              ),
              _buildDiscoverGridItem(
                'Spike Feeding',
                'DesertDragon92',
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAs3nf7fxWMGVUs0HwBaCyRiyQzgQcQ8CUXfl0m4_rSJH4fjPpX0wMf-8C04Tf4ouMa8unIcCYSb5FK6MOtXL9ZP1O0Rp903RKoUHUeeQ0aDTMoEp_0pHE204uJ9poibAJVcNqbhqfIHeDv-C9vG5-ACRRhnMRFursKDc30yXDI9MR4F-h4JuaAQwoj4Xe80niwm8vbjWxr5YtawpqsErSmfF59m6O2IQ7xs0KHsNMXOJk22TNEbbHZUCOelqJdO-9N_uB3x60cXyg',
                '842 likes',
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpotlightCard(String name, String followers, String avatarUrl, bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final mutedTextColor = isDark ? AppTheme.textLight : AppTheme.lightTextLight;
    final cardBg = isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary;
    final borderColor = isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _SafeCircleAvatar(
            imageUrl: avatarUrl,
            fallbackText: name,
            radius: 26,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            followers,
            style: TextStyle(color: mutedTextColor, fontSize: 10),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              minimumSize: const Size(0, 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Follow', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverGridItem(String title, String author, String imageUrl, String stats, bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final mutedTextColor = isDark ? AppTheme.textLight : AppTheme.lightTextLight;
    final borderColor = isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor;
    final cardBg = isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppTheme.bgTertiary,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, color: AppTheme.textLight, size: 28),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '@$author',
                        style: TextStyle(color: AppTheme.primaryColor, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      stats,
                      style: TextStyle(color: mutedTextColor, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesMobileView(bool isDark) {
    return _buildMessagesView(isDark, isMobile: true);
  }

  Widget _buildMessagesView(bool isDark, {required bool isMobile}) {
    if (isMobile) {
      if (_selectedChatIndex != null) {
        return _buildConversationPane(isDark, isMobile: true);
      } else {
        return _buildChatListPane(isDark);
      }
    } else {
      final borderColor = isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 320,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: borderColor),
              ),
            ),
            child: _buildChatListPane(isDark),
          ),
          Expanded(
            child: _selectedChatIndex != null
                ? Row(
                    children: [
                      Expanded(
                        child: _buildConversationPane(isDark, isMobile: false),
                      ),
                      Container(
                        width: 260,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: borderColor),
                          ),
                        ),
                        child: _buildBreederDetailPane(isDark),
                      ),
                    ],
                  )
                : _buildEmptyConversationPlaceholder(isDark),
          ),
        ],
      );
    }
  }

  Widget _buildChatListPane(bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final secondaryTextColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final mutedTextColor = isDark ? AppTheme.textLight : AppTheme.lightTextLight;
    final borderColor = isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor;

    final filteredChats = _chatsData.where((chat) {
      final name = (chat['name'] as String).toLowerCase();
      final lastMsg = (chat['message'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || lastMsg.contains(query);
    }).toList();

    // Sort: pinned first, then by normal order
    filteredChats.sort((a, b) {
      final aPinned = a['pinned'] as bool? ?? false;
      final bPinned = b['pinned'] as bool? ?? false;
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Breeder Messages',
                    style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: AppTheme.primaryColor),
                    tooltip: 'New Message',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select a breeder from discover or profiles to message directly!')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161810) : AppTheme.lightBgPrimary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: _searchChatsController,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: TextStyle(color: mutedTextColor, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: mutedTextColor, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchChatsController.clear();
                            },
                            child: Icon(Icons.clear, color: mutedTextColor, size: 16),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredChats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, color: mutedTextColor, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'No conversations found',
                        style: TextStyle(color: secondaryTextColor, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredChats.length,
                  separatorBuilder: (context, index) => Divider(color: borderColor, height: 1),
                  itemBuilder: (context, index) {
                    final chat = filteredChats[index];
                    final originalIndex = _chatsData.indexOf(chat);
                    final isSelected = _selectedChatIndex == originalIndex;
                    final isUnread = (chat['unread'] as int) > 0;
                    final isOnline = chat['online'] as bool;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedChatIndex = originalIndex;
                          _chatsData[originalIndex]['unread'] = 0;
                        });
                        final chatId = chat['id'] as String?;
                        if (_currentSubscriptionUserId != null && chatId != null) {
                          _resetUnreadCountInFirestore(chatId);
                          _setupMessagesSync(chatId, originalIndex);
                        }
                        _scrollToBottom();
                      },
                      onLongPress: () {
                        _showChatOptionsSheet(context, chat, originalIndex, isDark);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppTheme.primaryColor.withOpacity(0.08) : AppTheme.lightPrimaryColor.withOpacity(0.08))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                _SafeCircleAvatar(
                                  imageUrl: chat['avatar'] as String?,
                                  fallbackText: chat['name'] as String? ?? '',
                                  radius: 24,
                                ),
                                if (isOnline)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        chat['name'] as String,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          fontWeight: isUnread || isSelected ? FontWeight.bold : FontWeight.w600,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (chat['pinned'] as bool? ?? false)
                                            const Padding(
                                              padding: EdgeInsets.only(right: 4.0),
                                              child: Icon(Icons.push_pin, size: 10, color: AppTheme.primaryColor),
                                            ),
                                          if (chat['muted'] as bool? ?? false)
                                            const Padding(
                                              padding: EdgeInsets.only(right: 4.0),
                                              child: Icon(Icons.volume_off, size: 10, color: Colors.grey),
                                            ),
                                          Text(
                                            chat['time'] as String,
                                            style: TextStyle(
                                              color: isUnread ? AppTheme.accentColor : mutedTextColor,
                                              fontSize: 10,
                                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    chat['message'] as String,
                                    style: TextStyle(
                                      color: isUnread ? textColor : secondaryTextColor,
                                      fontSize: 12,
                                      fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  chat['unread'].toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildConversationPane(bool isDark, {required bool isMobile}) {
    if (_selectedChatIndex == null) return const SizedBox.shrink();
    final chatIndex = _selectedChatIndex!;
    final chat = _chatsData[chatIndex];
    final history = _messagesHistory[chatIndex] ?? [];
    
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final secondaryTextColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final mutedTextColor = isDark ? AppTheme.textLight : AppTheme.lightTextLight;
    final borderColor = isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor;
    final isOnline = chat['online'] as bool;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0F0F) : AppTheme.lightBgPrimary,
            border: Border(
              bottom: BorderSide(color: borderColor),
            ),
          ),
          child: Row(
            children: [
              if (isMobile) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: textColor,
                  onPressed: () {
                    setState(() {
                      _selectedChatIndex = null;
                    });
                  },
                ),
                const SizedBox(width: 4),
              ],
              Stack(
                children: [
                  _SafeCircleAvatar(
                    imageUrl: chat['avatar'] as String?,
                    fallbackText: chat['name'] as String? ?? '',
                    radius: 20,
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF0F0F0F) : AppTheme.lightBgPrimary, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat['name'] as String,
                      style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline ? AppTheme.primaryColor : mutedTextColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_isChatSearching ? Icons.search_off : Icons.search),
                color: secondaryTextColor,
                onPressed: () {
                  setState(() {
                    _isChatSearching = !_isChatSearching;
                    if (!_isChatSearching) {
                      _chatSearchQuery = '';
                      _chatSearchController.clear();
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.videocam_outlined),
                color: secondaryTextColor,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video calling is currently a simulator feature.')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.phone_outlined),
                color: secondaryTextColor,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Audio calling is currently a simulator feature.')),
                  );
                },
              ),
              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  color: secondaryTextColor,
                  onPressed: () {
                    _showMobileBreederInfo(context, chat);
                  },
                ),
            ],
          ),
        ),
        if (_isChatSearching)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161810) : AppTheme.lightBgPrimary,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: TextField(
              controller: _chatSearchController,
              style: TextStyle(color: textColor, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search messages in this chat...',
                hintStyle: TextStyle(color: mutedTextColor, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: mutedTextColor, size: 18),
                suffixIcon: GestureDetector(
                  onTap: () {
                    _chatSearchController.clear();
                    setState(() {
                      _chatSearchQuery = '';
                    });
                  },
                  child: Icon(Icons.clear, color: mutedTextColor, size: 14),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) {
                setState(() {
                  _chatSearchQuery = val;
                });
              },
            ),
          ),
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF131313) : AppTheme.lightBgSecondary,
            child: ListView.builder(
              controller: _messageScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              itemCount: history.length + ((_typingStates[chatIndex] ?? false) ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == history.length) {
                  return _buildTypingBubble(chat['name'] as String, isDark);
                }
                final message = history[index];
                final isUser = message['sender'] == 'user';
                return _buildMessageBubble(message, isUser, isDark);
              },
            ),
          ),
        ),
        _buildQuickReplies(isDark),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0F0F) : AppTheme.lightBgPrimary,
            border: Border(
              top: BorderSide(color: borderColor),
            ),
          ),
          child: Row(
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                onSelected: (value) {
                  if (value == 'pedigree') {
                    _attachPedigreeMock();
                  } else if (value == 'listing') {
                    _attachListingMock();
                  } else if (value == 'photo') {
                    _attachPhotoMock();
                  } else if (value == 'offer') {
                    _attachOfferMock();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'pedigree',
                    child: Row(
                      children: [
                        Icon(Icons.account_tree_outlined, color: AppTheme.primaryColor, size: 18),
                        SizedBox(width: 8),
                        Text('Share Pedigree Snap'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'listing',
                    child: Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, color: AppTheme.accentColor, size: 18),
                        SizedBox(width: 8),
                        Text('Link Reptile Listing'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'photo',
                    child: Row(
                      children: [
                        Icon(Icons.photo_outlined, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Text('Share Photo'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'offer',
                    child: Row(
                      children: [
                        Icon(Icons.local_offer_outlined, color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Text('Send Custom Offer'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1B1B) : AppTheme.lightBgSecondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _messageComposerController,
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: mutedTextColor, fontSize: 14),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.black, size: 16),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickReplies(bool isDark) {
    if (_selectedChatIndex == null) return const SizedBox.shrink();
    final chatIndex = _selectedChatIndex!;
    final replies = [
      'Is he still available?',
      'Can you ship to California?',
      'What are the parent genetics?',
    ];

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF131313) : AppTheme.lightBgSecondary,
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: replies.map((reply) {
            return GestureDetector(
              onTap: () {
                _messageComposerController.text = reply;
                _sendMessage();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.borderColor.withOpacity(0.5) : AppTheme.lightBorderColor,
                  ),
                ),
                child: Text(
                  reply,
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isUser, bool isDark) {
    final bubbleType = message['type'] as String;
    Widget bubbleChild;

    if (bubbleType == 'pedigree') {
      bubbleChild = _buildPedigreeBubble(message['attachment'] as Map<String, dynamic>, isUser, isDark);
    } else if (bubbleType == 'listing') {
      bubbleChild = _buildListingBubble(message['attachment'] as Map<String, dynamic>, isUser, isDark);
    } else if (bubbleType == 'offer') {
      bubbleChild = _buildOfferBubble(message['attachment'] as Map<String, dynamic>, isUser, isDark);
    } else if (bubbleType == 'photo') {
      bubbleChild = _buildPhotoBubble(message, isUser, isDark);
    } else {
      bubbleChild = _buildTextBubble(message, isUser, isDark);
    }

    final reactions = List<String>.from(message['reactions'] ?? []);
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bool matchesSearch = _chatSearchQuery.isEmpty ||
        (message['text'] as String? ?? '').toLowerCase().contains(_chatSearchQuery.toLowerCase()) ||
        (bubbleType == 'pedigree' && ((message['attachment']?['specimenName'] as String? ?? '').toLowerCase().contains(_chatSearchQuery.toLowerCase()) || (message['attachment']?['morphs'] as String? ?? '').toLowerCase().contains(_chatSearchQuery.toLowerCase()))) ||
        (bubbleType == 'listing' && (message['attachment']?['title'] as String? ?? '').toLowerCase().contains(_chatSearchQuery.toLowerCase()));

    return Opacity(
      opacity: matchesSearch ? 1.0 : 0.15,
      child: Align(
        alignment: align,
        child: GestureDetector(
          onDoubleTap: () {
            final reactionsList = List<String>.from(message['reactions'] ?? []);
            if (reactionsList.contains('❤️')) {
              reactionsList.remove('❤️');
            } else {
              reactionsList.add('❤️');
            }
            _updateMessageReactions(message, reactionsList);
          },
          onLongPress: () {
            _showReactionSheet(context, message, isDark);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              bubbleChild,
              if (reactions.isNotEmpty)
                Positioned(
                  bottom: -6,
                  right: isUser ? null : 12,
                  left: isUser ? 12 : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.borderColor.withOpacity(0.5) : AppTheme.lightBorderColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: reactions.map((emoji) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.0),
                          child: Text(emoji, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextBubble(Map<String, dynamic> message, bool isUser, bool isDark) {
    final textColor = isUser
        ? Colors.black
        : (isDark ? Colors.white : AppTheme.lightTextPrimary);
    final bgBubbleColor = isUser
        ? AppTheme.primaryColor
        : (isDark ? AppTheme.bgSecondary : AppTheme.lightBgPrimary);
    final radius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        color: bgBubbleColor,
        borderRadius: radius,
        border: isUser
            ? null
            : Border.all(
                color: isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor,
              ),
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message['text'] as String,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message['time'] as String,
                style: TextStyle(
                  color: isUser
                      ? Colors.black.withOpacity(0.5)
                      : (isDark ? AppTheme.textLight : AppTheme.lightTextLight),
                  fontSize: 9,
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 4),
                _buildDeliveryStatusIcon(message['status'] as String?, isDark),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBubble(Map<String, dynamic> message, bool isUser, bool isDark) {
    final isUploading = message['uploading'] as bool? ?? false;
    final progress = message['progress'] as double? ?? 1.0;
    final attachment = message['attachment'] as Map<String, dynamic>;
    final imageUrl = attachment['imageUrl'] as String;

    final radius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.network(
            imageUrl,
            width: 240,
            height: 240,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 240,
              height: 240,
              color: AppTheme.bgTertiary,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image, color: AppTheme.textLight, size: 28),
            ),
          ),
          if (isUploading) ...[
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading ${(progress * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!isUploading)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message['time'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 4),
                      _buildDeliveryStatusIcon(message['status'] as String?, isDark),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingBubble(String peerName, bool isDark) {
    final bgBubbleColor = isDark ? AppTheme.bgSecondary : AppTheme.lightBgPrimary;
    final borderColor = isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: bgBubbleColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BouncingDots(isDark: isDark),
            const SizedBox(width: 8),
            Text(
              'typing...',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStatusIcon(String? status, bool isDark) {
    if (status == 'read') {
      return Icon(
        Icons.done_all,
        size: 12,
        color: isDark ? AppTheme.primaryColor : const Color(0xFF1B5E20),
      );
    } else if (status == 'delivered') {
      return const Icon(
        Icons.done_all,
        size: 12,
        color: Colors.grey,
      );
    } else {
      return const Icon(
        Icons.done,
        size: 12,
        color: Colors.grey,
      );
    }
  }

  void _updateMessageReactions(Map<String, dynamic> message, List<String> reactionsList) {
    setState(() {
      message['reactions'] = reactionsList;
    });

    final messageId = message['id'] as String?;
    if (_currentSubscriptionChatId != null && messageId != null) {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(_currentSubscriptionChatId)
          .collection('messages')
          .doc(messageId)
          .update({'reactions': reactionsList});
    }
  }

  void _showReactionSheet(BuildContext context, Map<String, dynamic> message, bool isDark) {
    final cardBg = isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary;
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'React to message',
                  style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        final reactionsList = List<String>.from(message['reactions'] ?? []);
                        if (reactionsList.contains(emoji)) {
                          reactionsList.remove(emoji);
                        } else {
                          reactionsList.add(emoji);
                        }
                        _updateMessageReactions(message, reactionsList);
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChatOptionsSheet(BuildContext context, Map<String, dynamic> chat, int index, bool isDark) {
    final isPinned = chat['pinned'] as bool? ?? false;
    final isMuted = chat['muted'] as bool? ?? false;
    final themeColor = AppTheme.primaryColor;
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  chat['name'] as String? ?? 'Conversation Options',
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: isPinned ? themeColor : Colors.grey,
                ),
                title: Text(
                  isPinned ? 'Unpin Conversation' : 'Pin Conversation',
                  style: TextStyle(color: textColor),
                ),
                onTap: () async {
                  setState(() {
                    chat['pinned'] = !isPinned;
                  });
                  Navigator.pop(context);

                  final chatId = chat['id'] as String?;
                  if (_currentSubscriptionUserId != null && chatId != null) {
                    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
                      'pinned.$_currentSubscriptionUserId': !isPinned,
                    });
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isPinned ? 'Conversation unpinned' : 'Conversation pinned')),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  isMuted ? Icons.volume_up : Icons.volume_off,
                  color: isMuted ? Colors.grey : AppTheme.accentColor,
                ),
                title: Text(
                  isMuted ? 'Unmute Conversation' : 'Mute Conversation',
                  style: TextStyle(color: textColor),
                ),
                onTap: () async {
                  setState(() {
                    chat['muted'] = !isMuted;
                  });
                  Navigator.pop(context);

                  final chatId = chat['id'] as String?;
                  if (_currentSubscriptionUserId != null && chatId != null) {
                    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
                      'muted.$_currentSubscriptionUserId': !isMuted,
                    });
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isMuted ? 'Conversation unmuted' : 'Conversation muted')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.dangerColor),
                title: const Text('Delete Conversation', style: TextStyle(color: AppTheme.dangerColor)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteConversation(context, index, isDark);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteConversation(BuildContext context, int index, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
          title: const Text('Delete Conversation?'),
          content: const Text('This will delete your copy of the message history. This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final chat = _chatsData[index];
                final chatId = chat['id'] as String?;

                setState(() {
                  _chatsData.removeAt(index);
                  if (_selectedChatIndex == index) {
                    _selectedChatIndex = null;
                  } else if (_selectedChatIndex != null && _selectedChatIndex! > index) {
                    _selectedChatIndex = _selectedChatIndex! - 1;
                  }
                });
                Navigator.pop(context);

                if (_currentSubscriptionUserId != null && chatId != null) {
                  final db = FirebaseFirestore.instance;
                  final participants = List<String>.from(chat['participants'] ?? []);
                  final hasRealOtherUser = participants.any((p) => p != _currentSubscriptionUserId && !p.contains('master') && !p.contains('dragon') && !p.contains('ranch') && !p.contains('guild'));
                  if (hasRealOtherUser) {
                    await db.collection('chats').doc(chatId).update({
                      'participants': FieldValue.arrayRemove([_currentSubscriptionUserId]),
                    });
                  } else {
                    await db.collection('chats').doc(chatId).delete();
                  }
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Conversation deleted')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: AppTheme.dangerColor)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPedigreeBubble(Map<String, dynamic> attachment, bool isUser, bool isDark) {
    final themeColor = AppTheme.primaryColor;
    final cardBg = isDark ? const Color(0xFF1A261A) : const Color(0xFFE8F5E9);
    final textThemeColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subtextColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      width: 300,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: const Row(
              children: [
                Icon(Icons.account_tree_outlined, color: Colors.black, size: 16),
                SizedBox(width: 8),
                Text(
                  'ScaleSync Pro Pedigree',
                  style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment['specimenName'] as String,
                  style: TextStyle(color: textThemeColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    attachment['morphs'] as String,
                    style: TextStyle(color: isDark ? themeColor : AppTheme.lightPrimaryColor, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.male, color: Colors.blue, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Sire: ${attachment['sire']}',
                        style: TextStyle(color: subtextColor, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.female, color: Colors.pink, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Dam: ${attachment['dam']}',
                        style: TextStyle(color: subtextColor, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hatched: ${attachment['hatchDate']}',
                      style: TextStyle(color: subtextColor, fontSize: 10),
                    ),
                    Text(
                      'Weight: ${attachment['weight']}',
                      style: TextStyle(color: subtextColor, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening detailed pedigree chart in ScaleSync Pro...')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: const BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Pedigree Tree',
                    style: TextStyle(color: isDark ? themeColor : AppTheme.lightPrimaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new, color: isDark ? themeColor : AppTheme.lightPrimaryColor, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingBubble(Map<String, dynamic> attachment, bool isUser, bool isDark) {
    final themeColor = AppTheme.accentColor;
    final cardBg = isDark ? const Color(0xFF26201A) : const Color(0xFFFFF3E0);
    final textThemeColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subtextColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      width: 300,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withOpacity(0.5), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: themeColor,
            child: const Row(
              children: [
                Icon(Icons.shopping_bag, color: Colors.white, size: 14),
                SizedBox(width: 8),
                Text(
                  'ScaleSync Marketplace Listing',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          Image.network(
            attachment['imageUrl'] as String,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 120,
              width: double.infinity,
              color: AppTheme.bgTertiary,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image, color: AppTheme.textLight, size: 28),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        attachment['title'] as String,
                        style: TextStyle(color: textThemeColor, fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      attachment['price'] as String,
                      style: TextStyle(color: themeColor, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Genetics: ${attachment['genetics']}',
                  style: TextStyle(color: subtextColor, fontSize: 11),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigating to listing in ScaleSync Marketplace...')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              color: Colors.black12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Marketplace Listing',
                    style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, color: themeColor, size: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferBubble(Map<String, dynamic> attachment, bool isUser, bool isDark) {
    final cardBg = isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary;
    final textThemeColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subtextColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final status = attachment['status'] as String;

    Color statusColor;
    if (status == 'Accepted') {
      statusColor = AppTheme.successColor;
    } else if (status == 'Declined') {
      statusColor = AppTheme.dangerColor;
    } else {
      statusColor = AppTheme.accentColor;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      width: 300,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222222) : AppTheme.lightBgTertiary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_offer, color: AppTheme.accentColor, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Direct Marketplace Offer',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment['title'] as String,
                  style: TextStyle(color: textThemeColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Listing Price', style: TextStyle(color: subtextColor, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(
                          attachment['originalPrice'] as String,
                          style: TextStyle(
                            color: textThemeColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Offer Amount', style: TextStyle(color: subtextColor, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(
                          attachment['offerPrice'] as String,
                          style: const TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (status == 'Pending') ...[
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        attachment['status'] = 'Declined';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Offer declined.')),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.dangerColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Decline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        attachment['status'] = 'Accepted';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Offer accepted! Invoice generated.')),
                      );
                      Future.delayed(const Duration(seconds: 1), () {
                        if (!mounted || _selectedChatIndex == null) return;
                        final chatIndex = _selectedChatIndex!;
                        setState(() {
                          _messagesHistory[chatIndex]!.add({
                            'sender': 'other',
                            'text': "Incredible! I've accepted your \$600 offer. Checkout invoice has been generated in your ScaleSync Marketplace portal. 🦎🛒",
                            'time': TimeOfDay.now().format(context),
                            'reactions': <String>[],
                            'type': 'text',
                          });
                        });
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Accept', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreederDetailPane(bool isDark) {
    if (_selectedChatIndex == null) return const SizedBox.shrink();
    final chatIndex = _selectedChatIndex!;
    final chat = _chatsData[chatIndex];
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final borderColor = isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SafeCircleAvatar(
            imageUrl: chat['avatar'] as String?,
            fallbackText: chat['name'] as String? ?? '',
            radius: 36,
          ),
          const SizedBox(height: 12),
          Text(
            chat['name'] as String,
            style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '@${chat['name'].toString().toLowerCase()}',
            style: TextStyle(color: AppTheme.primaryColor, fontSize: 11),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.category_outlined, chat['specialty'] as String, isDark),
          _buildDetailRow(Icons.location_on_outlined, chat['location'] as String, isDark),
          _buildDetailRow(Icons.calendar_today_outlined, 'Member since ${chat['memberSince']}', isDark),
          const SizedBox(height: 20),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening ${chat['name']}\'s Marketplace storefront...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Visit Marketplace Store', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Navigating to ${chat['name']}\'s social profile...')),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor),
              minimumSize: const Size(double.infinity, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('View Social Profile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, bool isDark) {
    final subtextColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: subtextColor, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileBreederInfo(BuildContext context, Map<String, dynamic> chat) {
    final isDark = legacy_provider.Provider.of<ThemeService>(context, listen: false).isDarkMode;
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final secondaryTextColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SafeCircleAvatar(
                imageUrl: chat['avatar'] as String?,
                fallbackText: chat['name'] as String? ?? '',
                radius: 36,
              ),
              const SizedBox(height: 12),
              Text(
                chat['name'] as String,
                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                chat['specialty'] as String,
                style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                chat['location'] as String,
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening ${chat['name']}\'s Marketplace storefront...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: const Text('Visit Marketplace Store'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Navigating to ${chat['name']}\'s social profile...')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: const Text('View Social Profile'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyConversationPlaceholder(bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final secondaryTextColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgSecondary : AppTheme.lightBgTertiary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppTheme.primaryColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a Breeder',
              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a breeder from the list to start direct messaging.\nYou can negotiate prices, send offers, and share pedigree records directly.',
              style: TextStyle(color: secondaryTextColor, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsView(bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final secondaryTextColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor;

    final notifications = [
      {
        'title': 'New Inquiry on Marketplace',
        'body': 'ReptileRanch made a \$600 offer on your Pastel Clown Ball Python.',
        'time': '10m ago',
        'icon': Icons.local_offer,
        'color': AppTheme.accentColor,
        'unread': true,
      },
      {
        'title': 'System Notification',
        'body': 'Your ScaleSync Pro task "Clean incubators & log temperature" is due in 1 hour.',
        'time': '1h ago',
        'icon': Icons.notifications_active,
        'color': AppTheme.primaryColor,
        'unread': true,
      },
      {
        'title': 'New Follower',
        'body': 'ArborealMaster started following your herpetarium updates.',
        'time': '3h ago',
        'icon': Icons.person_add,
        'color': AppTheme.primaryLight,
        'unread': false,
      },
      {
        'title': 'Liked Broadcast',
        'body': 'DesertDragon92 liked your post about humidity cycling in python racks.',
        'time': '5h ago',
        'icon': Icons.favorite,
        'color': Colors.red,
        'unread': false,
      },
      {
        'title': 'Data Synced',
        'body': 'ScaleSync Pro successfully synced 4 new feeding logs with Firestore.',
        'time': 'Yesterday',
        'icon': Icons.sync,
        'color': Colors.blue,
        'unread': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Notifications',
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => Divider(color: borderColor, height: 1),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isUnread = notif['unread'] as bool;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                decoration: BoxDecoration(
                  color: isUnread ? (isDark ? AppTheme.primaryColor.withOpacity(0.05) : AppTheme.lightPrimaryColor.withOpacity(0.05)) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: (notif['color'] as Color).withOpacity(0.15),
                      child: Icon(notif['icon'] as IconData, color: notif['color'] as Color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                notif['title'] as String,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                ),
                              ),
                              Text(
                                notif['time'] as String,
                                style: TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notif['body'] as String,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsView(bool isDark) {
    final themeService = legacy_provider.Provider.of<ThemeService>(context);
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildSettingsSectionHeader('Appearance', textColor),
          _buildSettingsTile(
            title: 'Dark Mode (Nocturnal Mode)',
            subtitle: 'Toggle dark and light visual themes',
            icon: Icons.dark_mode_outlined,
            trailing: Switch(
              value: themeService.isDarkMode,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) {
                themeService.toggleTheme();
              },
            ),
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildSettingsSectionHeader('Ecosystem Sync', textColor),
          _buildSettingsTile(
            title: 'Auto-Sync Pro Pedigrees',
            subtitle: 'Automatically sync lineage tree records into chats',
            icon: Icons.sync,
            trailing: Switch(
              value: true,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) {},
            ),
            isDark: isDark,
          ),
          _buildSettingsTile(
            title: 'Marketplace Checkout Integration',
            subtitle: 'Enable direct purchase invoices inside DMs',
            icon: Icons.shopping_bag_outlined,
            trailing: Switch(
              value: true,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) {},
            ),
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildSettingsSectionHeader('Privacy & Security', textColor),
          _buildSettingsTile(
            title: 'Filter Breeder Inquiries',
            subtitle: 'Only allow verified ScaleSync Pro accounts to DM',
            icon: Icons.verified_user_outlined,
            trailing: Switch(
              value: false,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) {},
            ),
            isDark: isDark,
          ),
          _buildSettingsTile(
            title: 'Husbandry Log Visibility',
            subtitle: 'Let other breeders view selected feeding statistics',
            icon: Icons.visibility_outlined,
            trailing: Switch(
              value: true,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) {},
            ),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final secondaryTextColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: secondaryTextColor, fontSize: 11),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageComposerController.text.trim();
    if (text.isEmpty || _selectedChatIndex == null) return;
    final chatIndex = _selectedChatIndex!;
    final timestamp = TimeOfDay.now().format(context);

    if (_currentSubscriptionUserId != null) {
      final chat = _chatsData[chatIndex];
      final chatId = chat['id'] as String;
      final peerId = chat['peerId'] as String;
      final db = FirebaseFirestore.instance;

      _messageComposerController.clear();
      _scrollToBottom();

      final messageDoc = db.collection('chats').doc(chatId).collection('messages').doc();
      await messageDoc.set({
        'senderId': _currentSubscriptionUserId,
        'text': text,
        'time': timestamp,
        'type': 'text',
        'status': 'sent',
        'reactions': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await db.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': 'Just now',
        'unreadCount.$peerId': FieldValue.increment(1),
      });

      _triggerPeerReplySequence(chatId, peerId, text);
      return;
    }

    final newMessage = {
      'sender': 'user',
      'text': text,
      'time': timestamp,
      'type': 'text',
      'reactions': <String>[],
      'status': 'sent',
    };

    setState(() {
      _messagesHistory[chatIndex]!.add(newMessage);
      _chatsData[chatIndex]['message'] = text;
      _chatsData[chatIndex]['time'] = 'Just now';
      _chatsData[chatIndex]['unread'] = 0;
      _messageComposerController.clear();
    });
    _scrollToBottom();

    // Transition delivery status
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _selectedChatIndex != chatIndex) return;
      setState(() {
        newMessage['status'] = 'delivered';
      });

      // Peer starts typing a reply after another 600ms
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || _selectedChatIndex != chatIndex) return;
        setState(() {
          newMessage['status'] = 'read';
          _typingStates[chatIndex] = true;
        });
        _scrollToBottom();

        // Send reply after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted || _selectedChatIndex != chatIndex) return;
          String replyText = '';
          if (text.toLowerCase().contains('price') || text.toLowerCase().contains('cost') || text.toLowerCase().contains('how much')) {
            replyText = "I'm offering this specimen for \$650 plus shipping. Let me know if you want me to send a formal purchase request via ScaleSync Marketplace!";
          } else if (text.toLowerCase().contains('available') || text.toLowerCase().contains('still have')) {
            replyText = "Yes, he's still available! I've had a few inquiries this morning, but no deposits placed yet.";
          } else if (text.toLowerCase().contains('ship') || text.toLowerCase().contains('shipping')) {
            replyText = "I ship via FedEx Priority Overnight through ShipYourReptiles. Shipping is usually a flat \$55, weather permitting.";
          } else {
            replyText = "Thanks for the message! Let me check the records in my herpetarium dashboard and get back to you shortly. 🦎";
          }

          setState(() {
            _typingStates[chatIndex] = false;
            _messagesHistory[chatIndex]!.add({
              'sender': 'other',
              'text': replyText,
              'time': TimeOfDay.now().format(context),
              'reactions': <String>[],
              'type': 'text',
            });
            _chatsData[chatIndex]['message'] = replyText;
            _chatsData[chatIndex]['time'] = 'Just now';
          });
          _scrollToBottom();
        });
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messageScrollController.hasClients) {
        _messageScrollController.animateTo(
          _messageScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _addAttachmentMessageToFirestore(String type, Map<String, dynamic> attachment, String text, String peerReplyText) async {
    if (_selectedChatIndex == null || _currentSubscriptionUserId == null) return;
    final chatIndex = _selectedChatIndex!;
    final chatId = _chatsData[chatIndex]['id'] as String;
    final peerId = _chatsData[chatIndex]['peerId'] as String;
    final db = FirebaseFirestore.instance;

    final docRef = db.collection('chats').doc(chatId).collection('messages').doc();
    await docRef.set({
      'senderId': _currentSubscriptionUserId,
      'text': text,
      'time': TimeOfDay.now().format(context),
      'type': type,
      'status': 'sent',
      'reactions': <String>[],
      'attachment': attachment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await db.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': 'Just now',
      'unreadCount.$peerId': FieldValue.increment(1),
    });

    // Custom peer reply sequence for this attachment
    Future.delayed(const Duration(milliseconds: 600), () async {
      if (_currentSubscriptionUserId == null) return;
      await docRef.update({'status': 'delivered'});

      Future.delayed(const Duration(milliseconds: 600), () async {
        if (_currentSubscriptionUserId == null) return;
        await docRef.update({'status': 'read'});
        await db.collection('chats').doc(chatId).update({
          'typing.$peerId': true,
        });

        Future.delayed(const Duration(seconds: 2), () async {
          if (_currentSubscriptionUserId == null) return;

          if (type == 'offer') {
            await docRef.update({'attachment.status': 'Accepted'});
          }

          await db.collection('chats').doc(chatId).collection('messages').add({
            'senderId': peerId,
            'text': peerReplyText,
            'time': TimeOfDay.now().format(context),
            'type': 'text',
            'status': 'read',
            'reactions': <String>[],
            'createdAt': FieldValue.serverTimestamp(),
          });

          await db.collection('chats').doc(chatId).update({
            'lastMessage': peerReplyText.substring(0, (peerReplyText.length > 30 ? 30 : peerReplyText.length)) + '...',
            'lastMessageTime': 'Just now',
            'typing.$peerId': false,
            'unreadCount.$_currentSubscriptionUserId': FieldValue.increment(1),
          });
        });
      });
    });
  }

  Future<void> _attachPhotoFirestore() async {
    if (_selectedChatIndex == null || _currentSubscriptionUserId == null) return;
    final chatIndex = _selectedChatIndex!;
    final chatId = _chatsData[chatIndex]['id'] as String;
    final peerId = _chatsData[chatIndex]['peerId'] as String;
    final db = FirebaseFirestore.instance;

    final docRef = db.collection('chats').doc(chatId).collection('messages').doc();
    await docRef.set({
      'senderId': _currentSubscriptionUserId,
      'text': 'Shared a photo.',
      'time': TimeOfDay.now().format(context),
      'type': 'photo',
      'status': 'sent',
      'reactions': <String>[],
      'uploading': true,
      'progress': 0.0,
      'attachment': {
        'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHXU_6BWFTCLD97Cl1Gf2cp9lSUcuTHwz5KwH6wkunSPpHQ712LU6UPFZQHlXJ8HhSadCsIxLCBXtMFss6__YFtcPVH6eFAs7DedjretZe_zibjEHpIGh4MQHL57VelVYxCowhR4yRksRxzKyoeoMnoeL_neeoxHk7wp1FwWe4AYV7F0_jrkDWaZt2oBPE6IjY1IlYfjwFAVMXsUoKBlOs2lZjNdGEVCMwKzRfz34btJtxgqU2t0UQoseCtX7XXcYaz3ZZNUSftOk',
      },
      'createdAt': FieldValue.serverTimestamp(),
    });

    await db.collection('chats').doc(chatId).update({
      'lastMessage': 'Uploading photo...',
      'lastMessageTime': 'Just now',
    });

    // Simulate progress upload on Firestore doc
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_currentSubscriptionUserId == null) return;
      await docRef.update({'progress': 0.35});

      Future.delayed(const Duration(milliseconds: 500), () async {
        if (_currentSubscriptionUserId == null) return;
        await docRef.update({'progress': 0.75});

        Future.delayed(const Duration(milliseconds: 500), () async {
          if (_currentSubscriptionUserId == null) return;
          await docRef.update({
            'uploading': false,
            'progress': 1.0,
            'status': 'read',
          });

          await db.collection('chats').doc(chatId).update({
            'lastMessage': 'Sent a photo.',
            'unreadCount.$peerId': FieldValue.increment(1),
          });

          // Peer typing status
          Future.delayed(const Duration(seconds: 1), () async {
            if (_currentSubscriptionUserId == null) return;
            await db.collection('chats').doc(chatId).update({
              'typing.$peerId': true,
            });

            Future.delayed(const Duration(seconds: 2), () async {
              if (_currentSubscriptionUserId == null) return;
              final peerReplyText = "Wow, the color and clarity on this one are stunning! Is this animal currently ready to breed, or still sub-adult?";

              await db.collection('chats').doc(chatId).collection('messages').add({
                'senderId': peerId,
                'text': peerReplyText,
                'time': TimeOfDay.now().format(context),
                'type': 'text',
                'status': 'read',
                'reactions': <String>[],
                'createdAt': FieldValue.serverTimestamp(),
              });

              await db.collection('chats').doc(chatId).update({
                'lastMessage': peerReplyText.substring(0, (peerReplyText.length > 30 ? 30 : peerReplyText.length)) + '...',
                'lastMessageTime': 'Just now',
                'typing.$peerId': false,
                'unreadCount.$_currentSubscriptionUserId': FieldValue.increment(1),
              });
            });
          });
        });
      });
    });
  }

  void _attachPhotoMock() {
    if (_selectedChatIndex == null) return;
    if (_currentSubscriptionUserId != null) {
      _attachPhotoFirestore();
      _scrollToBottom();
      return;
    }
    final chatIndex = _selectedChatIndex!;
    final timestamp = TimeOfDay.now().format(context);
    final photoMessage = {
      'sender': 'user',
      'text': 'Shared a photo.',
      'time': timestamp,
      'type': 'photo',
      'reactions': <String>[],
      'status': 'sent',
      'uploading': true,
      'progress': 0.0,
      'attachment': {
        'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHXU_6BWFTCLD97Cl1Gf2cp9lSUcuTHwz5KwH6wkunSPpHQ712LU6UPFZQHlXJ8HhSadCsIxLCBXtMFss6__YFtcPVH6eFAs7DedjretZe_zibjEHpIGh4MQHL57VelVYxCowhR4yRksRxzKyoeoMnoeL_neeoxHk7wp1FwWe4AYV7F0_jrkDWaZt2oBPE6IjY1IlYfjwFAVMXsUoKBlOs2lZjNdGEVCMwKzRfz34btJtxgqU2t0UQoseCtX7XXcYaz3ZZNUSftOk',
      }
    };

    setState(() {
      _messagesHistory[chatIndex]!.add(photoMessage);
      _chatsData[chatIndex]['message'] = 'Uploading photo...';
      _chatsData[chatIndex]['time'] = 'Just now';
    });
    _scrollToBottom();

    // Simulate progress upload
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _selectedChatIndex != chatIndex) return;
      setState(() {
        photoMessage['progress'] = 0.35;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted || _selectedChatIndex != chatIndex) return;
        setState(() {
          photoMessage['progress'] = 0.75;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted || _selectedChatIndex != chatIndex) return;
          setState(() {
            photoMessage['uploading'] = false;
            photoMessage['progress'] = 1.0;
            photoMessage['status'] = 'read';
            _chatsData[chatIndex]['message'] = 'Sent a photo.';
          });
          _scrollToBottom();

          // Peer starts typing response
          Future.delayed(const Duration(seconds: 1), () {
            if (!mounted || _selectedChatIndex != chatIndex) return;
            setState(() {
              _typingStates[chatIndex] = true;
            });
            _scrollToBottom();

            Future.delayed(const Duration(seconds: 2), () {
              if (!mounted || _selectedChatIndex != chatIndex) return;
              setState(() {
                _typingStates[chatIndex] = false;
                _messagesHistory[chatIndex]!.add({
                  'sender': 'other',
                  'text': "Wow, the color and clarity on this one are stunning! Is this animal currently ready to breed, or still sub-adult?",
                  'time': TimeOfDay.now().format(context),
                  'reactions': <String>[],
                  'type': 'text',
                });
                _chatsData[chatIndex]['message'] = "Wow, the color and clarity...";
                _chatsData[chatIndex]['time'] = 'Just now';
              });
              _scrollToBottom();
            });
          });
        });
      });
    });
  }

  void _attachPedigreeMock() {
    if (_selectedChatIndex == null) return;
    if (_currentSubscriptionUserId != null) {
      _addAttachmentMessageToFirestore(
        'pedigree',
        {
          'specimenName': 'Hypo Tangerine Leopard Gecko (LG-2023-H2)',
          'morphs': 'Hypo Tangerine Carrot Tail',
          'sire': 'Tangerine Dream (LG-Sire-04)',
          'dam': 'Super Hypo Baldy (LG-Dam-12)',
          'hatchDate': '08/22/2023',
          'weight': '68g',
        },
        'Shared a pedigree snapshot.',
        "Wow, the carrot tail expression on the dam side is incredible. I'd definitely be interested in adding this line to my project!",
      );
      _scrollToBottom();
      return;
    }
    final chatIndex = _selectedChatIndex!;
    final timestamp = TimeOfDay.now().format(context);

    final newPedigreeMessage = {
      'sender': 'user',
      'text': 'Shared a pedigree snapshot.',
      'time': timestamp,
      'type': 'pedigree',
      'reactions': <String>[],
      'status': 'sent',
      'attachment': {
        'specimenName': 'Hypo Tangerine Leopard Gecko (LG-2023-H2)',
        'morphs': 'Hypo Tangerine Carrot Tail',
        'sire': 'Tangerine Dream (LG-Sire-04)',
        'dam': 'Super Hypo Baldy (LG-Dam-12)',
        'hatchDate': '08/22/2023',
        'weight': '68g',
      }
    };

    setState(() {
      _messagesHistory[chatIndex]!.add(newPedigreeMessage);
      _chatsData[chatIndex]['message'] = 'Shared a pedigree snapshot.';
      _chatsData[chatIndex]['time'] = 'Just now';
    });
    _scrollToBottom();

    // Transition delivery status
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _selectedChatIndex != chatIndex) return;
      setState(() {
        newPedigreeMessage['status'] = 'delivered';
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || _selectedChatIndex != chatIndex) return;
        setState(() {
          newPedigreeMessage['status'] = 'read';
          _typingStates[chatIndex] = true;
        });
        _scrollToBottom();

        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted || _selectedChatIndex != chatIndex) return;
          setState(() {
            _typingStates[chatIndex] = false;
            _messagesHistory[chatIndex]!.add({
              'sender': 'other',
              'text': "Wow, the carrot tail expression on the dam side is incredible. I'd definitely be interested in adding this line to my project!",
              'time': TimeOfDay.now().format(context),
              'reactions': <String>[],
              'type': 'text',
            });
            _chatsData[chatIndex]['message'] = "Wow, the carrot tail expression...";
            _chatsData[chatIndex]['time'] = 'Just now';
          });
          _scrollToBottom();
        });
      });
    });
  }

  void _attachListingMock() {
    if (_selectedChatIndex == null) return;
    if (_currentSubscriptionUserId != null) {
      _addAttachmentMessageToFirestore(
        'listing',
        {
          'title': 'High-Orange Crested Gecko Juvenile',
          'price': '\$275',
          'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHXU_6BWFTCLD97Cl1Gf2cp9lSUcuTHwz5KwH6wkunSPpHQ712LU6UPFZQHlXJ8HhSadCsIxLCBXtMFss6__YFtcPVH6eFAs7DedjretZe_zibjEHpIGh4MQHL57VelVYxCowhR4yRksRxzKyoeoMnoeL_neeoxHk7wp1FwWe4AYV7F0_jrkDWaZt2oBPE6IjY1IlYfjwFAVMXsUoKBlOs2lZjNdGEVCMwKzRfz34btJtxgqU2t0UQoseCtX7XXcYaz3ZZNUSftOk',
          'genetics': 'Quadstripe, high contrast orange flame',
        },
        'Sent an inquiry about a listing.',
        "Yes, that juvenile is currently available! He's eating repashy crested gecko diet and active. Let me know if you want more photos.",
      );
      _scrollToBottom();
      return;
    }
    final chatIndex = _selectedChatIndex!;
    final timestamp = TimeOfDay.now().format(context);

    final newListingMessage = {
      'sender': 'user',
      'text': 'Sent an inquiry about a listing.',
      'time': timestamp,
      'type': 'listing',
      'reactions': <String>[],
      'status': 'sent',
      'attachment': {
        'title': 'High-Orange Crested Gecko Juvenile',
        'price': '\$275',
        'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHXU_6BWFTCLD97Cl1Gf2cp9lSUcuTHwz5KwH6wkunSPpHQ712LU6UPFZQHlXJ8HhSadCsIxLCBXtMFss6__YFtcPVH6eFAs7DedjretZe_zibjEHpIGh4MQHL57VelVYxCowhR4yRksRxzKyoeoMnoeL_neeoxHk7wp1FwWe4AYV7F0_jrkDWaZt2oBPE6IjY1IlYfjwFAVMXsUoKBlOs2lZjNdGEVCMwKzRfz34btJtxgqU2t0UQoseCtX7XXcYaz3ZZNUSftOk',
        'genetics': 'Quadstripe, high contrast orange flame',
      }
    };

    setState(() {
      _messagesHistory[chatIndex]!.add(newListingMessage);
      _chatsData[chatIndex]['message'] = 'Sent an inquiry about a listing.';
      _chatsData[chatIndex]['time'] = 'Just now';
    });
    _scrollToBottom();

    // Transition delivery status
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _selectedChatIndex != chatIndex) return;
      setState(() {
        newListingMessage['status'] = 'delivered';
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || _selectedChatIndex != chatIndex) return;
        setState(() {
          newListingMessage['status'] = 'read';
          _typingStates[chatIndex] = true;
        });
        _scrollToBottom();

        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted || _selectedChatIndex != chatIndex) return;
          setState(() {
            _typingStates[chatIndex] = false;
            _messagesHistory[chatIndex]!.add({
              'sender': 'other',
              'text': "Yes, that juvenile is currently available! He's eating repashy crested gecko diet and active. Let me know if you want more photos.",
              'time': TimeOfDay.now().format(context),
              'reactions': <String>[],
              'type': 'text',
            });
            _chatsData[chatIndex]['message'] = "Yes, that juvenile is currently...";
            _chatsData[chatIndex]['time'] = 'Just now';
          });
          _scrollToBottom();
        });
      });
    });
  }

  void _attachOfferMock() {
    if (_selectedChatIndex == null) return;
    if (_currentSubscriptionUserId != null) {
      _addAttachmentMessageToFirestore(
        'offer',
        {
          'title': 'Biak GTP Male (GTP-2022-B9)',
          'offerPrice': '\$600',
          'originalPrice': '\$650',
          'status': 'Pending',
        },
        'Made an offer of \$600.',
        "I accept your offer of \$600! I've updated the invoice. You can pay using the checkout link in ScaleSync Marketplace. 🤝",
      );
      _scrollToBottom();
      return;
    }
    final chatIndex = _selectedChatIndex!;
    final timestamp = TimeOfDay.now().format(context);

    final newOfferMessage = {
      'sender': 'user',
      'text': 'Made an offer of \$600.',
      'time': timestamp,
      'type': 'offer',
      'reactions': <String>[],
      'status': 'sent',
      'attachment': {
        'title': 'Biak GTP Male (GTP-2022-B9)',
        'offerPrice': '\$600',
        'originalPrice': '\$650',
        'status': 'Pending',
      }
    };

    setState(() {
      _messagesHistory[chatIndex]!.add(newOfferMessage);
      _chatsData[chatIndex]['message'] = 'Made an offer of \$600.';
      _chatsData[chatIndex]['time'] = 'Just now';
    });
    _scrollToBottom();

    // Transition delivery status
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _selectedChatIndex != chatIndex) return;
      setState(() {
        newOfferMessage['status'] = 'delivered';
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || _selectedChatIndex != chatIndex) return;
        setState(() {
          newOfferMessage['status'] = 'read';
          _typingStates[chatIndex] = true;
        });
        _scrollToBottom();

        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted || _selectedChatIndex != chatIndex) return;
          final list = _messagesHistory[chatIndex]!;
          for (var i = list.length - 1; i >= 0; i--) {
            if (list[i]['type'] == 'offer') {
              setState(() {
                list[i]['attachment']['status'] = 'Accepted';
              });
              break;
            }
          }

          setState(() {
            _typingStates[chatIndex] = false;
            _messagesHistory[chatIndex]!.add({
              'sender': 'other',
              'text': "I accept your offer of \$600! I've updated the invoice. You can pay using the checkout link in ScaleSync Marketplace. 🤝",
              'time': TimeOfDay.now().format(context),
              'reactions': <String>[],
              'type': 'text',
            });
            _chatsData[chatIndex]['message'] = "I accept your offer of \$600...";
            _chatsData[chatIndex]['time'] = 'Just now';
          });
          _scrollToBottom();
        });
      });
    });
  }

  Widget _buildProfileMobileView(bool isDark) {
    final authService = legacy_provider.Provider.of<AuthService>(context);
    final userData = authService.userData;
    final userName = userData?['name'] ?? authService.currentUser?.displayName ?? authService.currentUser?.email?.split('@')[0] ?? 'Gecko1';
    
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final secondaryTextColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final mutedTextColor = isDark ? AppTheme.textLight : AppTheme.lightTextLight;
    final borderColor = isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient Profile Header Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.15),
                  AppTheme.primaryLight.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                  child: Text(
                    userName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppTheme.accentColor, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        userName,
                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: AppTheme.primaryColor, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '@$userName',
                  style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  'Captive-bred reptile enthusiast. Specialized in high-end gecko morphs and herpetology husbandry.',
                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Statistics Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Collection', '24', textColor, mutedTextColor),
                _buildStatColumn('Followers', '1.2k', textColor, mutedTextColor),
                _buildStatColumn('Following', '340', textColor, mutedTextColor),
              ],
            ),
          ),

          Divider(color: borderColor, height: 1),

          // Profile Tabs Indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'My Collection Log & Broadcasts',
              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),

          // Collection Images Grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildProfileGridItem('https://images.unsplash.com/photo-1531386151447-fd76ad50012f?auto=format&fit=crop&q=80&w=300'),
              _buildProfileGridItem('https://images.unsplash.com/photo-1504450758481-7338ecc7524a?auto=format&fit=crop&q=80&w=300'),
              _buildProfileGridItem('https://images.unsplash.com/photo-1629157257475-2735b48e4c56?auto=format&fit=crop&q=80&w=300'),
              _buildProfileGridItem('https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?auto=format&fit=crop&q=80&w=300'),
              _buildProfileGridItem('https://images.unsplash.com/photo-1508817628294-5a453fa0b8fb?auto=format&fit=crop&q=80&w=300'),
              _buildProfileGridItem('https://images.unsplash.com/photo-1551085254-e96b210db58a?auto=format&fit=crop&q=80&w=300'),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String count, Color textColor, Color mutedTextColor) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: mutedTextColor, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildProfileGridItem(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppTheme.bgTertiary,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: AppTheme.textLight, size: 20),
        ),
      ),
    );
  }
}

// --- Left Navigation Sidebar ---
// --- Left Navigation Sidebar ---
class _SidebarNavigation extends StatelessWidget {
  final bool isTablet;
  final VoidCallback onPostPressed;
  final int activeTab;
  final ValueChanged<int> onTabSelected;

  const _SidebarNavigation({
    required this.isTablet,
    required this.onPostPressed,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isTablet ? 200 : 250,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(
          right: BorderSide(color: Color(0xFF222222), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildNavItem('Home', Icons.home, activeTab == 0, 0),
          _buildNavItem('Discover', Icons.explore, activeTab == 1, 1),
          _buildNavItem('Notifications', Icons.notifications_none, activeTab == 2, 2, badgeCount: 2),
          _buildNavItem('Messages', Icons.chat_bubble_outline, activeTab == 3, 3),
          _buildNavItem('Profile', Icons.person_outline, activeTab == 4, 4),
          _buildNavItem('Settings', Icons.settings_outlined, activeTab == 5, 5),
          const Spacer(),
          ElevatedButton(
            onPressed: onPostPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline, size: 18),
                if (!isTablet) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'Post Specimen',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, IconData icon, bool isActive, int tabIndex, {int badgeCount = 0}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: InkWell(
        onTap: () => onTabSelected(tabIndex),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              if (!isTablet)
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (badgeCount > 0 && !isTablet)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Right Sidebar ---
class _RightSidebar extends StatefulWidget {
  const _RightSidebar();

  @override
  State<_RightSidebar> createState() => _RightSidebarState();
}

class _RightSidebarState extends State<_RightSidebar> {
  final Set<String> _followedBreeders = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trending Section
            _buildTrendingSection(),
            const SizedBox(height: 20),
            // Top Tier Breeders
            _buildBreedersSection(),
            const SizedBox(height: 20),
            // Activity Heatmap
            _buildActivitySection(),
            const SizedBox(height: 20),
            // Footer
            _buildFooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Trending Herps',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTrendingItem('Species Spotlight', '#LeopardGeckoCare', '2.4k posts this week'),
          _buildTrendingItem('Genetics', '#BallPythonMorphs', '1.8k posts this week'),
          _buildTrendingItem('Bioactive', '#HerpetariumDesign', '940 posts this week'),
          _buildTrendingItem('Conservation', '#AustralianAgamids', '520 posts this week'),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Show more',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingItem(String category, String hashtag, String stats) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              hashtag,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stats,
              style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreedersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Tier Breeders',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _buildBreederRow(
            'Apex Herpetics',
            'Specializing in Boas',
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAaK-o3mJDY-DkX-foC9845d-SnkR4GwfEA5ode1xOA-dDnFURa5UM1gHzk5JVh-1S80WiJf4R3yu1qKtBZL-U_dbe-i8CgSRpyVtWY2rY6Aazq25i4372bcMzJfZsRj8SmgdKr69A2GuIUNpKkdfQe-KGiEv-UVCwIMMJ-znr5L3iSpguskbXW-eyzpKmm1jZrr2E2lJ66OxNqLhCRwwrphrzVZh0kU4hFJnpMCBcUncXM_OA3aL30UYB2mdZrM_nbc2IBqUinH2U',
          ),
          const SizedBox(height: 12),
          _buildBreederRow(
            'Jewel Geckos',
            'Rare Phelsuma lines',
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDMnO5al9AKLtljtP7de1KIzJvmDyGPcbOJqy8sQjVHcYNnhs2mg_rJvfuOGP-VYQPe0E6OWh2M8hWp1YBhpLuLZsdkseGpxqXZnCGIfuTE6SE-Hz5PmsTQM9F8aTvAmsNPNvyB6CTHk-LcuaqJ9nDiga4Q5ZRhf1W0Mh165akm2k4zUDIW9kiCQSae2GEYU6lzv5A2l2tx_UAXuiszkeZoYNMVe0ljn6EBpT0Vlhucbagot33Cv9kJLt0fdIK3MkJT8pwnHAIdYJM',
          ),
        ],
      ),
    );
  }

  Widget _buildBreederRow(String name, String specialty, String imageUrl) {
    final isFollowing = _followedBreeders.contains(name);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppTheme.bgTertiary,
              child: const Icon(Icons.business, color: Colors.white, size: 16),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                specialty,
                style: const TextStyle(color: AppTheme.textLight, fontSize: 10),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              if (isFollowing) {
                _followedBreeders.remove(name);
              } else {
                _followedBreeders.add(name);
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? AppTheme.bgTertiary : Colors.white,
            foregroundColor: isFollowing ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Community Activity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Bar Chart simulated
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActivityBar(0.3),
                _buildActivityBar(0.6),
                _buildActivityBar(0.45),
                _buildActivityBar(0.9),
                _buildActivityBar(1.0),
                _buildActivityBar(0.7),
                _buildActivityBar(0.55),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Community growth is up 12% this week. Keep sharing your setups!',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBar(double fraction) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: FractionallySizedBox(
          heightFactor: fraction,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(fraction == 1.0 ? 1.0 : (fraction * 0.8)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildFooterLink('Terms'),
              _buildFooterLink('Privacy'),
              _buildFooterLink('Ethics Guide'),
              _buildFooterLink('Breeder Standards'),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '© 2026 ScaleSync Social',
            style: TextStyle(color: AppTheme.textLight, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String label) {
    return InkWell(
      onTap: () {},
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textLight,
          fontSize: 10,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

// --- Post Composer Card ---
class _PostComposerCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onPublish;
  final String? avatarUrl;

  // Attachment states
  final String? mediaUrl;
  final bool isVideo;
  final Map<String, String>? stats;
  final List<String> tags;
  final VoidCallback onAddPhoto;
  final VoidCallback onAddVideo;
  final VoidCallback onAddStats;
  final VoidCallback onAddTag;
  final VoidCallback onRemoveMedia;
  final VoidCallback onRemoveStats;
  final Function(String) onRemoveTag;

  const _PostComposerCard({
    required this.controller,
    required this.focusNode,
    required this.onPublish,
    this.avatarUrl,
    this.mediaUrl,
    required this.isVideo,
    this.stats,
    required this.tags,
    required this.onAddPhoto,
    required this.onAddVideo,
    required this.onAddStats,
    required this.onAddTag,
    required this.onRemoveMedia,
    required this.onRemoveStats,
    required this.onRemoveTag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_circle,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                  )
                : const Icon(
                    Icons.account_circle,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null,
                  minLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: "What's happening in your herpetarium?",
                    hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 13),
                    fillColor: Colors.transparent,
                    filled: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                // Attachment preview inside desktop composer
                _ComposerAttachmentPreview(
                  mediaUrl: mediaUrl,
                  isVideo: isVideo,
                  stats: stats,
                  tags: tags,
                  onRemoveMedia: onRemoveMedia,
                  onRemoveStats: onRemoveStats,
                  onRemoveTag: onRemoveTag,
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF333333), height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildComposerAction(Icons.image_outlined, 'Photo', onAddPhoto),
                            const SizedBox(width: 16),
                            _buildComposerAction(Icons.videocam_outlined, 'Video', onAddVideo),
                            const SizedBox(width: 16),
                            _buildComposerAction(Icons.thermostat_outlined, 'Stats', onAddStats),
                            const SizedBox(width: 16),
                            _buildComposerAction(Icons.local_offer_outlined, 'Tags', onAddTag),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: onPublish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Publish',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposerAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textLight, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Social Post Card ---
class _SocialPostCard extends StatefulWidget {
  final _MorphUpdatePost post;
  final bool isLiked;
  final VoidCallback onLikeToggle;

  const _SocialPostCard({
    required this.post,
    required this.isLiked,
    required this.onLikeToggle,
  });

  @override
  State<_SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<_SocialPostCard> {
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.breederName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (post.avatarIcon == null) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: AppTheme.primaryColor,
                              size: 13,
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${post.timeAgo} • ${post.subtitle}',
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppTheme.textLight),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Media Section
          if (post.hasMedia && post.mediaUrl != null) _buildMediaSection(),

          // Post Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.morphTitle.isNotEmpty && post.morphTitle != 'Broadcast Update') ...[
                  Text(
                    post.morphTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontStyle: post.avatarIcon != null ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  post.morphContent,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                // Stats Section
                if (post.stats != null && post.stats!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildStatsRow(),
                ],

                // Tags Section
                if (post.morphTags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: post.morphTags.map((tag) => _buildTag(tag)).toList(),
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(color: Color(0xFF333333), height: 1),
                const SizedBox(height: 10),

                // Actions Footer
                _buildActionsFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final post = widget.post;
    if (post.avatarIcon != null) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(post.avatarIcon, color: AppTheme.accentColor, size: 18),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: post.isVideo ? AppTheme.accentColor : AppTheme.primaryColor,
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: post.avatarUrl != null
          ? Image.network(
              post.avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallbackAvatarText(),
            )
          : _buildFallbackAvatarText(),
    );
  }

  Widget _buildFallbackAvatarText() {
    return Container(
      color: AppTheme.bgTertiary,
      alignment: Alignment.center,
      child: Text(
        widget.post.avatarText,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    final post = widget.post;
    return AspectRatio(
      aspectRatio: post.isVideo ? 16 / 9 : 1.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _PostMediaWidget(
            mediaUrl: post.mediaUrl!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          if (post.isVideo) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Simulating video playback...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '4K VIDEO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
          if (!post.isVideo && post.morphTags.isNotEmpty) ...[
            Positioned(
              bottom: 12,
              left: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      post.morphTags.first,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (post.morphTags.length > 1) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        post.morphTags[1],
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = widget.post.stats!;
    return Row(
      children: stats.entries.map((entry) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.bgPrimary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(color: AppTheme.textLight, fontSize: 9),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.value,
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.bgTertiary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildActionsFooter() {
    final post = widget.post;
    final isLiked = widget.isLiked;
    
    if (post.avatarIcon != null) {
      return Row(
        children: [
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening replies stream...'),
                  duration: Duration(milliseconds: 1500),
                ),
              );
            },
            child: const Row(
              children: [
                Icon(Icons.forum_outlined, color: AppTheme.primaryColor, size: 18),
                SizedBox(width: 6),
                Text(
                  '12 Expert Replies',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Like Button
        InkWell(
          onTap: widget.onLikeToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            child: Row(
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppTheme.primaryColor : AppTheme.textLight,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.likes + (isLiked ? 1 : 0)}',
                  style: TextStyle(
                    color: isLiked ? AppTheme.primaryColor : AppTheme.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        
        // Comment Button
        InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.textLight,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.comments}',
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        
        // Share Button
        IconButton(
          icon: const Icon(Icons.share_outlined, color: AppTheme.textLight, size: 18),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Link copied to clipboard!'),
                duration: Duration(milliseconds: 1500),
              ),
            );
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

// --- Post Model Class ---
class _MorphUpdatePost {
  final String breederName;
  final String avatarText;
  final String? avatarUrl;
  final IconData? avatarIcon;
  final String timeAgo;
  final String subtitle;
  final String morphTitle;
  final String morphContent;
  final List<String> morphTags;
  final int likes;
  final int comments;
  final int shares;
  final bool hasMedia;
  final String? mediaUrl;
  final bool isVideo;
  final Map<String, String>? stats;

  _MorphUpdatePost({
    required this.breederName,
    required this.avatarText,
    this.avatarUrl,
    this.avatarIcon,
    required this.timeAgo,
    required this.subtitle,
    required this.morphTitle,
    required this.morphContent,
    required this.morphTags,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.hasMedia,
    this.mediaUrl,
    this.isVideo = false,
    this.stats,
  });
}

// --- User Menu Button ---
class _SocialUserMenuButton extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final ThemeService themeService;
  final AuthService authService;
  final VoidCallback onAuthRequired;

  const _SocialUserMenuButton({
    required this.userData,
    required this.themeService,
    required this.authService,
    required this.onAuthRequired,
  });

  @override
  State<_SocialUserMenuButton> createState() => _SocialUserMenuButtonState();
}

class _SocialUserMenuButtonState extends State<_SocialUserMenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;
    final showHovered = isMobile || _isHovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: PopupMenuButton<String>(
        offset: const Offset(0, 36),
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(showHovered ? 1.15 : 1.0),
          child: const Icon(
            Icons.account_circle,
            size: 24,
            color: AppTheme.primaryColor,
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.authService.isAuthenticated
                      ? (widget.userData?['name'] ?? widget.authService.currentUser?.displayName ?? widget.authService.currentUser?.email?.split('@')[0] ?? 'User')
                      : 'Guest',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  widget.authService.isAuthenticated
                      ? (widget.userData?['email'] ?? widget.authService.currentUser?.email ?? '')
                      : '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person, size: 16),
                SizedBox(width: 8),
                Text('Profile'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings, size: 16),
                SizedBox(width: 8),
                Text('Settings'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'help',
            child: Row(
              children: [
                Icon(Icons.help, size: 16),
                SizedBox(width: 8),
                Text('Help'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'theme',
            child: Row(
              children: [
                Icon(
                  widget.themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(widget.themeService.isDarkMode ? 'Switch to Light' : 'Switch to Dark'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'download',
            child: Row(
              children: [
                Icon(Icons.download, size: 16),
                SizedBox(width: 8),
                Text('Download App'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          if (widget.authService.isAuthenticated)
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 16),
                  SizedBox(width: 8),
                  Text('Sign Out'),
                ],
              ),
            )
          else
            const PopupMenuItem(
              value: 'login',
              child: Row(
                children: [
                  Icon(Icons.login, size: 16),
                  SizedBox(width: 8),
                  Text('Sign In'),
                ],
              ),
            ),
        ],
        onSelected: (value) async {
          switch (value) {
            case 'download':
              if (context.mounted) {
                DownloadAppDialog.show(context);
              }
              break;
            case 'theme':
              widget.themeService.toggleTheme();
              break;
            case 'logout':
              await widget.authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SocialLoginView()),
                  (route) => false,
                );
              }
              break;
            case 'login':
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SocialLoginView()),
                );
              }
              break;
            case 'profile':
            case 'settings':
            case 'help':
              if (!widget.authService.isAuthenticated) {
                widget.onAuthRequired();
              }
              break;
          }
        },
      ),
    );
  }
}

Widget _buildComposerAction(IconData icon, String label, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textLight, size: 18),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textLight, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

// --- Attachment Preview inside Composer ---
class _ComposerAttachmentPreview extends StatelessWidget {
  final String? mediaUrl;
  final bool isVideo;
  final Map<String, String>? stats;
  final List<String> tags;
  final VoidCallback onRemoveMedia;
  final VoidCallback onRemoveStats;
  final Function(String) onRemoveTag;

  const _ComposerAttachmentPreview({
    this.mediaUrl,
    required this.isVideo,
    this.stats,
    required this.tags,
    required this.onRemoveMedia,
    required this.onRemoveStats,
    required this.onRemoveTag,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Media Preview
        if (mediaUrl != null) ...[
          const SizedBox(height: 12),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: isVideo ? 16 / 9 : 1.0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _PostMediaWidget(
                        mediaUrl: mediaUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.black26,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image, color: Colors.white),
                        ),
                      ),
                      if (isVideo)
                        const CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: Icon(Icons.play_arrow, color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black.withValues(alpha: 0.8),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, color: Colors.white, size: 14),
                    onPressed: onRemoveMedia,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Stats Preview
        if (stats != null && stats!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.bgPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: stats!.entries.map((entry) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key, style: const TextStyle(color: AppTheme.textLight, fontSize: 8)),
                              const SizedBox(height: 2),
                              Text(entry.value, style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                  onPressed: onRemoveStats,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],

        // Tags Preview
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((tag) {
              return Chip(
                label: Text('#$tag', style: const TextStyle(fontSize: 10, color: Colors.white)),
                backgroundColor: AppTheme.bgPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.3)),
                ),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                deleteIcon: const Icon(Icons.close, size: 10, color: Colors.white70),
                onDeleted: () => onRemoveTag(tag),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// --- Attachment Selection Dialogs ---
void _showAddPhotoDialog(BuildContext context, Function(String) onAdded) {
  final TextEditingController urlController = TextEditingController();
  final List<Map<String, String>> presets = [
    {
      'title': 'Green Tree Python',
      'url': 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=600&auto=format&fit=crop&q=60'
    },
    {
      'title': 'Leopard Gecko',
      'url': 'https://images.unsplash.com/photo-1504450758481-7338ecc7524a?w=600&auto=format&fit=crop&q=60'
    },
    {
      'title': 'Bioactive Enclosure',
      'url': 'https://images.unsplash.com/photo-1545239351-ef35f43d514b?w=600&auto=format&fit=crop&q=60'
    },
    {
      'title': 'Ball Python',
      'url': 'https://images.unsplash.com/photo-16008688847ee80e7176a992?w=600&auto=format&fit=crop&q=60'
    }
  ];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.3)),
      ),
      title: const Text('Add Photo to Broadcast', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null && context.mounted) {
                  onAdded(image.path);
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Choose Image from Device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.bgPrimary,
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Or Enter Image URL:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://...',
                hintStyle: const TextStyle(color: AppTheme.textLight),
                fillColor: AppTheme.bgPrimary,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Or Select from Presets:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((preset) {
                return InkWell(
                  onTap: () {
                    onAdded(preset['url']!);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.bgPrimary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(preset['title']!, style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            if (urlController.text.trim().isNotEmpty) {
              onAdded(urlController.text.trim());
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          child: const Text('Add', style: TextStyle(color: Colors.black)),
        ),
      ],
    ),
  );
}

void _showAddVideoDialog(BuildContext context, Function(String) onAdded) {
  final TextEditingController urlController = TextEditingController();
  final List<Map<String, String>> presets = [
    {
      'title': 'Feeding Feed Log',
      'url': 'https://images.unsplash.com/photo-1563206767-5b18f218e8de?w=600&auto=format&fit=crop&q=60'
    },
    {
      'title': 'Mist Cycle Tour',
      'url': 'https://images.unsplash.com/photo-1534710961226-85da9da8703b?w=600&auto=format&fit=crop&q=60'
    }
  ];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.3)),
      ),
      title: const Text('Add Video to Broadcast', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
                if (video != null && context.mounted) {
                  onAdded(video.path);
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Choose Video from Device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.bgPrimary,
                foregroundColor: AppTheme.accentColor,
                side: const BorderSide(color: AppTheme.accentColor, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Or Enter Video URL:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://...',
                hintStyle: const TextStyle(color: AppTheme.textLight),
                fillColor: AppTheme.bgPrimary,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Or Select from Presets:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((preset) {
                return InkWell(
                  onTap: () {
                    onAdded(preset['url']!);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.bgPrimary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(preset['title']!, style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            if (urlController.text.trim().isNotEmpty) {
              onAdded(urlController.text.trim());
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          child: const Text('Add', style: TextStyle(color: Colors.black)),
        ),
      ],
    ),
  );
}

void _showAddStatsDialog(BuildContext context, Function(Map<String, String>) onAdded) {
  final TextEditingController tempController = TextEditingController(text: '88°F');
  final TextEditingController humidityController = TextEditingController(text: '65%');
  final TextEditingController weightController = TextEditingController(text: '120g');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.3)),
      ),
      title: const Text('Add Herpetarium Stats', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Temperature', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: tempController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '88°F',
                          hintStyle: const TextStyle(color: AppTheme.textLight),
                          fillColor: AppTheme.bgPrimary,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Humidity', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: humidityController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '65%',
                          hintStyle: const TextStyle(color: AppTheme.textLight),
                          fillColor: AppTheme.bgPrimary,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Animal Weight', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                const SizedBox(height: 6),
                TextField(
                  controller: weightController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '120g',
                    hintStyle: const TextStyle(color: AppTheme.textLight),
                    fillColor: AppTheme.bgPrimary,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            onAdded({
              'Temp': tempController.text.trim(),
              'Humidity': humidityController.text.trim(),
              'Weight': weightController.text.trim(),
            });
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          child: const Text('Add Stats', style: TextStyle(color: Colors.black)),
        ),
      ],
    ),
  );
}

void _showAddTagDialog(BuildContext context, Function(String) onAdded) {
  final TextEditingController tagController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.3)),
      ),
      title: const Text('Add Tag', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter tag name (without #):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: tagController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'BallPython',
              hintStyle: const TextStyle(color: AppTheme.textLight),
              fillColor: AppTheme.bgPrimary,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            if (tagController.text.trim().isNotEmpty) {
              onAdded(tagController.text.trim());
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          child: const Text('Add Tag', style: TextStyle(color: Colors.black)),
        ),
      ],
    ),
  );
}

class _PostMediaWidget extends StatelessWidget {
  final String mediaUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const _PostMediaWidget({
    required this.mediaUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final isWebUrl = kIsWeb ||
        mediaUrl.startsWith('http://') ||
        mediaUrl.startsWith('https://') ||
        mediaUrl.startsWith('blob:') ||
        mediaUrl.startsWith('data:');

    if (isWebUrl) {
      return Image.network(
        mediaUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder ?? (context, error, stackTrace) => Container(
          color: Colors.black26,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: AppTheme.textLight, size: 32),
        ),
      );
    } else {
      return Image.file(
        io.File(mediaUrl),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder ?? (context, error, stackTrace) => Container(
          color: Colors.black26,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: AppTheme.textLight, size: 32),
        ),
      );
    }
  }
}

class _BouncingDots extends StatefulWidget {
  final bool isDark;

  const _BouncingDots({required this.isDark});

  @override
  _BouncingDotsState createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    final double delay = index * 0.2;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = (_controller.value - delay) % 1.0;
        final double bounce = (t < 0.5) ? (t * 2) : ((1.0 - t) * 2);
        final double transformY = -bounce * 6.0;

        return Transform.translate(
          offset: Offset(0, transformY),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildDot(0),
          const SizedBox(width: 4),
          _buildDot(1),
          const SizedBox(width: 4),
          _buildDot(2),
        ],
      ),
    );
  }
}

class _SafeCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double radius;
  final IconData fallbackIcon;

  const _SafeCircleAvatar({
    Key? key,
    required this.imageUrl,
    required this.fallbackText,
    this.radius = 20,
    this.fallbackIcon = Icons.person,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final initials = fallbackText.trim().isNotEmpty
        ? (fallbackText.trim().length >= 2
            ? fallbackText.trim().substring(0, 2).toUpperCase()
            : fallbackText.trim().substring(0, 1).toUpperCase())
        : '';

    final fallbackWidget = CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.7,
              ),
            )
          : Icon(
              fallbackIcon,
              color: AppTheme.primaryColor,
              size: radius,
            ),
    );

    if (imageUrl == null || imageUrl!.isEmpty || !imageUrl!.startsWith('http')) {
      return fallbackWidget;
    }

    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return fallbackWidget;
        },
      ),
    );
  }
}
