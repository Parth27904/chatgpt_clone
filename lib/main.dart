import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- NEW IMPORT
import 'package:uuid/uuid.dart'; // <--- NEW IMPORT

import 'package:chatgpt_clone/api/openai_api_client.dart';
import 'package:chatgpt_clone/repositories/chat_repository.dart';
import 'package:chatgpt_clone/repositories/model_repository.dart';
import 'package:chatgpt_clone/services/cloudinary_service.dart';
import 'package:chatgpt_clone/services/mongodb_direct_service.dart'; // Assuming direct service
import 'package:chatgpt_clone/bloc/chat/chat_bloc.dart';
import 'package:chatgpt_clone/bloc/chat_history/chat_history_bloc.dart';
import 'package:chatgpt_clone/bloc/model_selection/model_selection_bloc.dart';
import 'package:chatgpt_clone/ui/screens/home_screen.dart';

const _uuid = Uuid(); // For generating device ID

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  await dotenv.load(fileName: ".env");

  // --- NEW: Generate and store a unique device ID ---
  final prefs = await SharedPreferences.getInstance();
  String? deviceId = prefs.getString('deviceId');
  if (deviceId == null) {
    deviceId = _uuid.v4();
    await prefs.setString('deviceId', deviceId);
    print('Generated new deviceId: $deviceId');
  } else {
    print('Using existing deviceId: $deviceId');
  }
  // --- END NEW ---

  final openAIClient = OpenAIApiClient(apiKey: dotenv.env['OPENAI_API_KEY']!);
  final cloudinaryService = CloudinaryService();
  final mongoService = MongoDBDirectService(); // Use correct service type

  await mongoService.initialize();

  final chatRepository = ChatRepository(
    openAIClient: openAIClient,
    cloudinaryService: cloudinaryService,
    mongoService: mongoService,
    currentDeviceId: deviceId, // <--- PASS THE GENERATED DEVICE ID
  );
  final modelRepository = ModelRepository();

  runApp(MyApp(
    chatRepository: chatRepository,
    modelRepository: modelRepository,
    deviceId: deviceId, // <--- Pass deviceId to MyApp
  ));

  WidgetsBinding.instance.addObserver(_LifecycleEventHandler(
    resumeCallBack: () async {},
    suspendingCallBack: () async {
      await mongoService.close();
    },
  ));
}

class MyApp extends StatelessWidget {
  final ChatRepository chatRepository;
  final ModelRepository modelRepository;
  final String deviceId; // <--- Accept deviceId

  const MyApp({
    Key? key,
    required this.chatRepository,
    required this.modelRepository,
    required this.deviceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: chatRepository),
        RepositoryProvider.value(value: modelRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          // ChatHistoryBloc must be created before ChatBloc if ChatBloc depends on it
          BlocProvider(
            create: (context) => ChatHistoryBloc(
              chatRepository: context.read<ChatRepository>(),
              deviceId: deviceId, // <--- Pass deviceId
            )..add(const LoadChatHistory()),
          ),
          BlocProvider(
            create: (context) => ChatBloc(
              chatRepository: context.read<ChatRepository>(),
              modelRepository: context.read<ModelRepository>(),
              chatHistoryBloc: context.read<ChatHistoryBloc>(),
              deviceId: deviceId, // <--- Pass deviceId
            )..add(const ChatStarted()),
          ),
          BlocProvider(
            create: (context) => ModelSelectionBloc(
              modelRepository: context.read<ModelRepository>(),
            )..add(const LoadSelectedModel()),
          ),
        ],
        child: MaterialApp(
          title: 'ChatGPT Clone',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blueGrey,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF000000),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF000000),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardColor: const Color(0xFF303030),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF343541),
              titleTextStyle: TextStyle(color: Colors.white),
              contentTextStyle: TextStyle(color: Colors.white70),
            ),
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Colors.white,
              selectionColor: Colors.grey,
              selectionHandleColor: Colors.white,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white),
              bodySmall: TextStyle(color: Colors.white70),
              labelLarge: TextStyle(color: Colors.white),
              titleMedium: TextStyle(color: Colors.white),
              titleSmall: TextStyle(color: Colors.white70),
            ),
            iconTheme: const IconThemeData(
              color: Colors.white70,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF10A37F),
              foregroundColor: Colors.white,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFF505050),
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}

class _LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback resumeCallBack;
  final AsyncCallback suspendingCallBack;

  _LifecycleEventHandler({
    required this.resumeCallBack,
    required this.suspendingCallBack,
  });

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        await resumeCallBack();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        await suspendingCallBack();
        break;
    }
  }
}